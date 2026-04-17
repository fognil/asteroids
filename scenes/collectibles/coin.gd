extends Area2D
## Coin collectible — flies out, slows down, floats, auto-collects.

enum Tier { BRONZE, SILVER, GOLD }

@export var tier: Tier = Tier.BRONZE

var coin_velocity: Vector2 = Vector2.ZERO
var lifetime: float = 5.0
var coin_value: int = 1
var coin_radius: float = 6.0
var rotation_speed: float = 3.0
var is_collected: bool = false

const TIER_CONFIG := {
	Tier.BRONZE: { "value": 1, "color": Color(0.8, 0.5, 0.2), "radius": 5.0 },
	Tier.SILVER: { "value": 3, "color": Color(0.7, 0.8, 0.9), "radius": 6.0 },
	Tier.GOLD: { "value": 5, "color": Color(1.0, 0.85, 0.2), "radius": 7.0 },
}

func _ready() -> void:
	add_to_group("coins")
	var config: Dictionary = TIER_CONFIG[tier]
	coin_value = config["value"]
	coin_radius = config["radius"]
	
	_setup_collision()
	
	collision_layer = 16  # Coins layer
	collision_mask = 1    # Player layer
	body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)

func setup_velocity(dir: Vector2) -> void:
	coin_velocity = dir * randf_range(80, 180)

func _process(delta: float) -> void:
	if is_collected:
		return
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	# Physics: slow down over time
	coin_velocity *= 0.95
	if coin_velocity.length() < 2:
		coin_velocity = Vector2.ZERO
	position += coin_velocity * delta
	
	rotation += rotation_speed * delta
	
	# Auto-collect range
	var collect_range := 200.0 if PowerupManager.is_active("magnet") else 50.0
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist < collect_range and dist > 3:
			var dir: Vector2 = (player.global_position - global_position).normalized()
			var speed := 400.0 if dist < 30 else 200.0
			position += dir * speed * delta
	
	# Screen wrap
	position = ScreenWrap.wrap_position(position, coin_radius)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_collected:
		_collect()

func _collect() -> void:
	is_collected = true
	GameData.coins += coin_value
	EventBus.coin_collected.emit(coin_value)
	AudioManager.play_sfx("coin_collect")
	queue_free()

func _draw() -> void:
	if is_collected:
		return
	
	var config: Dictionary = TIER_CONFIG[tier]
	var color: Color = config["color"]
	
	# Blink near end
	var alpha := 1.0
	if lifetime < 1.5:
		alpha = 0.3 + 0.7 * abs(sin(Time.get_ticks_msec() * 0.01))
	
	var draw_color := Color(color, alpha)
	var glow := Color(color, alpha * 0.2)
	
	# Hexagon shape
	var points := PackedVector2Array()
	for i in 6:
		var angle := float(i) / 6.0 * TAU - PI / 6
		points.append(Vector2(cos(angle) * coin_radius, sin(angle) * coin_radius))
	points.append(points[0])
	
	draw_polyline(points, glow, 4.0, true)
	draw_polyline(points, draw_color, 1.5, true)
	
	# Center dot
	draw_circle(Vector2.ZERO, coin_radius * 0.3, Color(color, alpha * 0.5))
