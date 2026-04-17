extends Area2D
## Power-up collectible — floats, glows, auto-collects near player.

@export var powerup_type: String = "shield"

var lifetime: float = 8.0
var collect_radius: float = 30.0
var rotation_speed: float = 2.0
var bob_speed: float = 3.0
var bob_amount: float = 4.0
var base_y: float = 0.0
var color: Color = Color(0.2, 0.6, 1.0)
var icon_points: PackedVector2Array = []
var is_collected: bool = false

const BLINK_START := 3.0  # Start blinking at 3s remaining

# Visual config per type
const TYPE_VISUALS := {
	"shield": { "color": Color(0.2, 0.6, 1.0), "icon": "shield" },
	"multi_shot": { "color": Color(0.2, 1.0, 0.4), "icon": "triple" },
	"rapid_fire": { "color": Color(1.0, 1.0, 0.2), "icon": "lightning" },
	"piercing": { "color": Color(1.0, 0.3, 0.2), "icon": "arrow" },
	"slow_mo": { "color": Color(0.4, 0.2, 1.0), "icon": "clock" },
	"score_x2": { "color": Color(1.0, 0.85, 0.0), "icon": "star" },
	"extra_life": { "color": Color(1.0, 0.4, 0.6), "icon": "heart" },
	"bomb_pickup": { "color": Color(1.0, 0.6, 0.0), "icon": "bomb" },
}

func _ready() -> void:
	add_to_group("powerups")
	base_y = position.y
	
	if powerup_type in TYPE_VISUALS:
		color = TYPE_VISUALS[powerup_type]["color"]
	
	_generate_icon()
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 15.0
	collision.shape = shape
	add_child(collision)
	
	collision_layer = 8  # Power-up layer
	collision_mask = 1   # Player layer
	body_entered.connect(_on_body_entered)

func _generate_icon() -> void:
	var icon_type: String = TYPE_VISUALS.get(powerup_type, {}).get("icon", "shield")
	var s := 10.0
	
	match icon_type:
		"shield":
			icon_points = PackedVector2Array([
				Vector2(0, -s), Vector2(-s, -s * 0.3), Vector2(-s, s * 0.5),
				Vector2(0, s), Vector2(s, s * 0.5), Vector2(s, -s * 0.3), Vector2(0, -s)
			])
		"triple":
			icon_points = PackedVector2Array([
				Vector2(-s, -s * 0.5), Vector2(-s, s * 0.5),
			])
		"lightning":
			icon_points = PackedVector2Array([
				Vector2(s * 0.2, -s), Vector2(-s * 0.3, 0),
				Vector2(s * 0.1, 0), Vector2(-s * 0.2, s),
			])
		"arrow":
			icon_points = PackedVector2Array([
				Vector2(0, -s), Vector2(-s * 0.6, s * 0.3),
				Vector2(0, 0), Vector2(s * 0.6, s * 0.3), Vector2(0, -s)
			])
		"heart":
			icon_points = PackedVector2Array([
				Vector2(0, s * 0.8), Vector2(-s, -s * 0.2),
				Vector2(-s * 0.5, -s), Vector2(0, -s * 0.4),
				Vector2(s * 0.5, -s), Vector2(s, -s * 0.2), Vector2(0, s * 0.8)
			])
		"bomb":
			# Circle approximation
			icon_points = PackedVector2Array()
			for i in 8:
				var angle := float(i) / 8.0 * TAU
				icon_points.append(Vector2(cos(angle) * s * 0.7, sin(angle) * s * 0.7))
			icon_points.append(icon_points[0])
		"clock":
			# Circle with hour/minute hands
			icon_points = PackedVector2Array()
			for i in 8:
				var angle := float(i) / 8.0 * TAU
				icon_points.append(Vector2(cos(angle) * s * 0.7, sin(angle) * s * 0.7))
			icon_points.append(icon_points[0])
		"star":
			icon_points = PackedVector2Array()
			for i in 5:
				var outer_angle := float(i) * TAU / 5.0 - PI / 2
				var inner_angle := outer_angle + TAU / 10.0
				icon_points.append(Vector2(cos(outer_angle) * s, sin(outer_angle) * s))
				icon_points.append(Vector2(cos(inner_angle) * s * 0.4, sin(inner_angle) * s * 0.4))
			icon_points.append(icon_points[0])

func _process(delta: float) -> void:
	if is_collected:
		return
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	# Bob up and down
	position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_amount
	rotation += rotation_speed * delta
	
	# Magnet: pull toward player if close
	var magnet_range := 200.0 if PowerupManager.is_active("magnet") else collect_radius
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist < magnet_range and dist > 5:
			var dir: Vector2 = (player.global_position - global_position).normalized()
			var pull_speed := 300.0 if dist < collect_radius * 2 else 150.0
			position += dir * pull_speed * delta
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_collected:
		_collect()

func _collect() -> void:
	is_collected = true
	PowerupManager.activate(powerup_type)
	AudioManager.play_sfx("powerup")
	queue_free()

func _draw() -> void:
	if is_collected:
		return
	
	# Blink when about to expire
	var alpha := 1.0
	if lifetime < BLINK_START:
		alpha = 0.3 + 0.7 * abs(sin(Time.get_ticks_msec() * 0.008))
	
	# Outer glow circle
	draw_circle(Vector2.ZERO, 18.0, Color(color, alpha * 0.1))
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 16, Color(color, alpha * 0.3), 1.5, true)
	
	# Icon
	if icon_points.size() >= 2:
		var icon_color := Color(color, alpha)
		var glow := Color(color, alpha * 0.3)
		
		if powerup_type == "triple":
			# Draw 3 lines for multi-shot
			for i in 3:
				var angle := (float(i) - 1) * deg_to_rad(20)
				var start := Vector2(0, 8).rotated(angle)
				var end := Vector2(0, -8).rotated(angle)
				draw_line(start, end, icon_color, 1.5)
		else:
			draw_polyline(icon_points, glow, 4.0, true)
			draw_polyline(icon_points, icon_color, 1.5, true)
