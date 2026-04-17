extends Area2D
## Bomber UFO — flies slowly, drops mines. Wave 10+.

var move_direction: Vector2 = Vector2.RIGHT
var speed: float = 50.0
var hp: int = 3
var max_hp: int = 3
var points: int = 350
var color: Color = Color(1.0, 0.27, 0.27)  # Red
var ufo_size: float = 35.0
var mine_timer: float = 3.0
var mine_interval: float = 3.0
var damage_flash: float = 0.0
var is_dead: bool = false
var pulse: float = 0.0

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

func setup(from_left: bool) -> void:
	var vp_size := ScreenWrap.get_viewport_size()
	if from_left:
		position = Vector2(-ufo_size, randf_range(100, vp_size.y - 100))
		move_direction = Vector2.RIGHT
	else:
		position = Vector2(vp_size.x + ufo_size, randf_range(100, vp_size.y - 100))
		move_direction = Vector2.LEFT

func _process(delta: float) -> void:
	if is_dead:
		return
	
	pulse += delta * 4.0
	position += move_direction * speed * delta
	
	# Drop mines
	mine_timer -= delta
	if mine_timer <= 0:
		mine_timer = mine_interval
		_drop_mine()
	
	# Despawn
	var vp := ScreenWrap.get_viewport_size()
	if position.x < -80 or position.x > vp.x + 80:
		queue_free()
		return
	
	if damage_flash > 0:
		damage_flash -= delta
	queue_redraw()

func _drop_mine() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects == null:
		return
	var mine: Area2D = load("res://scenes/enemies/mine.tscn").instantiate()
	mine.global_position = global_position
	effects.add_child(mine)

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
	EventBus.enemy_destroyed.emit("bomber", global_position)
	
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var explosion: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.setup(2, color, ufo_size)
		effects.add_child(explosion)
		for i in 3:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 1
			coin.global_position = global_position
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_medium"):
		cam.shake_medium()
	queue_free()

func _draw() -> void:
	if is_dead:
		return
	var draw_color := color
	if damage_flash > 0:
		draw_color = draw_color.lerp(Color.WHITE, damage_flash / 0.15 * 0.8)
	
	var s := ufo_size
	var pulse_alpha := 0.3 + 0.3 * sin(pulse)
	
	# Inverted triangle
	var pts := PackedVector2Array([
		Vector2(-s * 0.5, -s * 0.4),
		Vector2(s * 0.5, -s * 0.4),
		Vector2(0, s * 0.5),
		Vector2(-s * 0.5, -s * 0.4)
	])
	draw_polyline(pts, Color(draw_color, pulse_alpha), 5.0, true)
	draw_polyline(pts, Color(draw_color, 0.9), 1.5, true)
	
	# Mine indicator dot
	draw_circle(Vector2(0, s * 0.1), 3.0, Color(draw_color, 0.5 + 0.3 * sin(pulse * 2)))
	
	# HP bar
	var hp_ratio := float(hp) / float(max_hp)
	if hp_ratio < 1.0:
		var bar_w := s * 0.6
		draw_rect(Rect2(-bar_w / 2, -s * 0.4 - 8, bar_w, 3), Color(0.3, 0.3, 0.3, 0.5))
		draw_rect(Rect2(-bar_w / 2, -s * 0.4 - 8, bar_w * hp_ratio, 3), Color(draw_color, 0.8))
