extends Area2D
## Mine — dropped by Bomber UFO, explodes after 5s or when shot. Damages player in radius.

var lifetime: float = 5.0
var explosion_radius: float = 80.0
var hp: int = 1
var points: int = 50
var color: Color = Color(1, 0.3, 0.3)
var mine_size: float = 8.0
var is_dead: bool = false
var pulse: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = mine_size
	collision.shape = shape
	add_child(collision)
	collision_layer = 32
	collision_mask = 2
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Pulse faster as lifetime decreases
	var blink_speed := 4.0 + (5.0 - lifetime) * 3.0
	pulse += delta * blink_speed
	lifetime -= delta
	
	# Blink faster as lifetime decreases
	if lifetime <= 0:
		_explode()
		return
	
	queue_redraw()

func take_damage(amount: int, _bullet_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	if hp <= 0:
		GameData.add_score(points)
		_explode()

func _explode() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Check if player is in explosion radius
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist < explosion_radius:
			if player.has_method("take_hit"):
				player.take_hit()
	
	# Explosion visual
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var explosion: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.setup(3, color, explosion_radius * 0.5)
		effects.add_child(explosion)
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_light"):
		cam.shake_light()
	
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _draw() -> void:
	if is_dead:
		return
	
	var blink_speed := 4.0 + (5.0 - lifetime) * 3.0  # Blinks faster near end
	var alpha := 0.4 + 0.6 * abs(sin(pulse))
	
	# Outer ring
	draw_arc(Vector2.ZERO, mine_size, 0, TAU, 8, Color(color, alpha * 0.3), 3.0, true)
	# Inner diamond
	var s := mine_size * 0.6
	var pts := PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0), Vector2(0, -s)
	])
	draw_polyline(pts, Color(color, alpha), 1.5, true)
	# Center
	draw_circle(Vector2.ZERO, 2, Color(color, alpha))
