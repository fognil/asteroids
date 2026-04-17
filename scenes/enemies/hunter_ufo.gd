extends Area2D
## Hunter UFO — zigzag movement, aimed shots at player. Wave 6+.

var speed: float = 70.0
var hp: int = 5
var max_hp: int = 5
var points: int = 500
var coin_value: int = 10
var color: Color = Color(1.0, 0.4, 0.0)  # Orange
var ufo_size: float = 40.0
var fire_timer: float = 1.5
var fire_interval: float = 1.5
var damage_flash: float = 0.0
var is_dead: bool = false

# Zigzag movement
var move_direction: Vector2 = Vector2.RIGHT
var zigzag_timer: float = 0.0
var zigzag_interval: float = 2.0
var vertical_dir: float = 1.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = ufo_size * 0.6
	collision.shape = shape
	add_child(collision)
	
	collision_layer = 32
	collision_mask = 2
	area_entered.connect(_on_area_entered)

func setup(from_left: bool) -> void:
	var vp_size := Vector2(1920, 1080)
	if from_left:
		position = Vector2(-ufo_size, randf_range(150, vp_size.y - 150))
		move_direction = Vector2(1, 0)
	else:
		position = Vector2(vp_size.x + ufo_size, randf_range(150, vp_size.y - 150))
		move_direction = Vector2(-1, 0)

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Zigzag
	zigzag_timer -= delta
	if zigzag_timer <= 0:
		zigzag_timer = zigzag_interval
		vertical_dir *= -1
	
	var move := Vector2(move_direction.x, vertical_dir * 0.5).normalized()
	position += move * speed * delta
	
	# Keep in vertical bounds
	position.y = clampf(position.y, 80, 1000)
	
	# Shoot aimed at player
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = fire_interval
		_shoot_aimed()
	
	# Despawn
	var vp_size := Vector2(1920, 1080)
	if position.x < -80 or position.x > vp_size.x + 80:
		queue_free()
		return
	
	if damage_flash > 0:
		damage_flash -= delta
	
	queue_redraw()

func _shoot_aimed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	
	var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
	bullet.position = global_position
	var dir: Vector2 = (player.global_position - global_position).normalized()
	bullet.direction = dir
	bullet.speed = 250.0
	bullet.color = Color(1.0, 0.5, 0.0)
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
	EventBus.enemy_destroyed.emit("hunter", global_position)
	
	# Coins
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		for i in 4:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 1  # Silver
			coin.global_position = global_position
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
		# One gold
		var gold: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
		gold.tier = 2
		gold.global_position = global_position
		gold.setup_velocity(Vector2.UP * 0.5)
		effects.add_child(gold)
	
	# Explosion
	if effects:
		var explosion: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.setup(1, color, ufo_size)  # Large explosion
		effects.add_child(explosion)
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_heavy"):
		cam.shake_heavy()
	
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _draw() -> void:
	if is_dead:
		return
	
	var draw_color := color
	if damage_flash > 0:
		draw_color = draw_color.lerp(Color.WHITE, damage_flash / 0.15 * 0.8)
	
	var s := ufo_size
	
	# Octagon
	var points := PackedVector2Array()
	for i in 8:
		var angle := float(i) / 8.0 * TAU - PI / 8
		points.append(Vector2(cos(angle) * s * 0.5, sin(angle) * s * 0.5))
	points.append(points[0])
	
	# Outer glow
	draw_polyline(points, Color(draw_color, 0.15), 6.0, true)
	# Inner ring
	var inner := PackedVector2Array()
	for i in 8:
		var angle := float(i) / 8.0 * TAU
		inner.append(Vector2(cos(angle) * s * 0.25, sin(angle) * s * 0.25))
	inner.append(inner[0])
	draw_polyline(inner, Color(draw_color, 0.3), 1.0, true)
	# Core
	draw_polyline(points, Color(draw_color, 1.0), 1.5, true)
	
	# HP indicator
	var hp_ratio := float(hp) / float(max_hp)
	if hp_ratio < 1.0:
		var bar_w := s * 0.8
		var bar_h := 3.0
		var bar_pos := Vector2(-bar_w / 2, -s * 0.5 - 8)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.3, 0.3, 0.3, 0.5))
		draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, bar_h)), Color(draw_color, 0.8))
