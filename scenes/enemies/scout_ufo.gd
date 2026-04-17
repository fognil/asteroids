extends Area2D
## Scout UFO — flies across screen, shoots randomly. Wave 3+.

var move_direction: Vector2 = Vector2.RIGHT
var speed: float = 100.0
var hp: int = 2
var max_hp: int = 2
var points: int = 200
var coin_value: int = 5
var color: Color = Color(0.67, 1.0, 0.0)  # Yellow-Green
var ufo_size: float = 25.0
var fire_timer: float = 2.0
var fire_interval: float = 2.0
var damage_flash: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = ufo_size * 0.7
	collision.shape = shape
	add_child(collision)
	
	collision_layer = 32  # Enemy layer
	collision_mask = 2    # Bullet layer
	area_entered.connect(_on_area_entered)

func setup(from_left: bool) -> void:
	var vp_size: Vector2 = Vector2(1920, 1080)
	if from_left:
		position = Vector2(-ufo_size, randf_range(100, vp_size.y - 100))
		move_direction = Vector2.RIGHT
	else:
		position = Vector2(vp_size.x + ufo_size, randf_range(100, vp_size.y - 100))
		move_direction = Vector2.LEFT
	# Slight vertical drift
	move_direction.y = randf_range(-0.2, 0.2)
	move_direction = move_direction.normalized()

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Move
	position += move_direction * speed * delta
	
	# Shoot randomly
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = fire_interval + randf_range(-0.5, 0.5)
		_shoot()
	
	# Despawn when off screen
	var vp_size := Vector2(1920, 1080)
	if position.x < -50 or position.x > vp_size.x + 50 or position.y < -50 or position.y > vp_size.y + 50:
		queue_free()
		return
	
	if damage_flash > 0:
		damage_flash -= delta
	
	queue_redraw()

func _shoot() -> void:
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	
	var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
	bullet.position = global_position
	# Random direction (not aimed)
	var angle := randf() * TAU
	bullet.direction = Vector2.RIGHT.rotated(angle)
	bullet.speed = 200.0
	bullets_node.add_child(bullet)

func take_damage(amount: int, _bullet_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	damage_flash = 0.15
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_light"):
		cam.shake_light()
	
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	GameData.add_score(points)
	GameData.add_combo()
	EventBus.enemy_destroyed.emit("scout", global_position)
	
	# Spawn coins
	_spawn_coins()
	
	# Spawn explosion
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var explosion: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.setup(2, color, ufo_size)  # Medium-size explosion
		effects.add_child(explosion)
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_medium"):
		cam.shake_medium()
	
	queue_free()

func _spawn_coins() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects == null:
		return
	for i in 3:
		var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
		coin.tier = 1 if randf() < 0.5 else 0  # Silver or Bronze
		coin.global_position = global_position
		coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
		effects.add_child(coin)

func _on_area_entered(area: Area2D) -> void:
	# Hit by player bullet
	if area.is_in_group("player_bullets") or not area.is_in_group("enemy_bullets"):
		pass  # Handled by bullet.gd calling take_damage

func _draw() -> void:
	if is_dead:
		return
	
	var alpha := 1.0
	var draw_color := color
	if damage_flash > 0:
		draw_color = draw_color.lerp(Color.WHITE, damage_flash / 0.15 * 0.8)
	
	# Semi-circle (dome shape)
	var s := ufo_size
	var points := PackedVector2Array()
	# Bottom line
	points.append(Vector2(-s, 0))
	# Arc top
	for i in 9:
		var angle := PI + float(i) / 8.0 * PI
		points.append(Vector2(cos(angle) * s, sin(angle) * s * 0.6))
	points.append(Vector2(s, 0))
	points.append(Vector2(-s, 0))
	
	# Glow
	draw_polyline(points, Color(draw_color, 0.2), 5.0, true)
	# Core
	draw_polyline(points, Color(draw_color, alpha), 1.5, true)
	
	# Center dot
	draw_circle(Vector2(0, -s * 0.15), 3.0, Color(draw_color, alpha * 0.6))
