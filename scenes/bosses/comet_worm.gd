extends Area2D
## Boss 3: Comet Worm — Snake boss, 8 segments, only head takes damage. Wave 15.

enum Phase { ONE, TWO, THREE }

var hp: int = 40
var max_hp: int = 40
var head_size: float = 30.0
var seg_size: float = 25.0
var speed: float = 100.0
var color: Color = Color(1.0, 0.6, 0.1)
var head_color: Color = Color(1.0, 0.3, 0.1)
var current_phase: Phase = Phase.ONE
var damage_flash: float = 0.0
var is_dead: bool = false
var time_alive: float = 0.0

# Segments
var segments: Array[Vector2] = []
var segment_count: int = 8
var segment_spacing: float = 35.0

# Attacks
var fireball_timer: float = 3.0
var spin_timer: float = 20.0
var detach_timer: float = 5.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_setup_collision()
	# Init segments behind head
	for i in segment_count:
		segments.append(position + Vector2(0, float(i + 1) * segment_spacing))

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = head_size * 0.7
	collision.shape = shape
	add_child.call_deferred(collision)
	collision_layer = 32
	collision_mask = 2

func _process(delta: float) -> void:
	if is_dead:
		return
	time_alive += delta
	
	var hp_ratio := float(hp) / float(max_hp)
	if hp_ratio <= 0.3 and current_phase != Phase.THREE:
		current_phase = Phase.THREE
		speed *= 2.0
	elif hp_ratio <= 0.6 and current_phase == Phase.ONE:
		current_phase = Phase.TWO
		speed *= 1.5
	
	_process_movement(delta)
	_process_attacks(delta)
	_update_segments()
	
	if damage_flash > 0:
		damage_flash -= delta
	queue_redraw()

func _process_movement(delta: float) -> void:
	# Sine wave movement
	var t := time_alive * 1.5
	var vp := Vector2(1920, 1080)
	var target_x := 960 + sin(t * 0.7) * 600
	var target_y := 300 + sin(t) * 200
	var target := Vector2(target_x, target_y)
	var dir: Vector2 = (target - position).normalized()
	position += dir * speed * delta
	position.x = clampf(position.x, 50, vp.x - 50)
	position.y = clampf(position.y, 50, vp.y - 50)

func _update_segments() -> void:
	if segments.is_empty():
		return
	# Follow head
	segments[0] = segments[0].lerp(position - (position - segments[0]).normalized() * segment_spacing, 0.1)
	for i in range(1, segments.size()):
		var prev := segments[i - 1]
		var dir: Vector2 = (segments[i] - prev).normalized()
		segments[i] = prev + dir * segment_spacing

func _process_attacks(delta: float) -> void:
	var interval := 3.0 if current_phase == Phase.ONE else (2.0 if current_phase == Phase.TWO else 1.5)
	fireball_timer -= delta
	if fireball_timer <= 0:
		fireball_timer = interval
		_shoot_fireball()
	
	if current_phase == Phase.TWO:
		spin_timer -= delta
		if spin_timer <= 0:
			spin_timer = 15.0
			_spawn_asteroid_ring()
	
	if current_phase == Phase.THREE:
		detach_timer -= delta
		if detach_timer <= 0:
			detach_timer = 5.0
			_detach_segment()

func _shoot_fireball() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	
	var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
	bullet.position = global_position
	bullet.direction = (player.global_position - global_position).normalized()
	bullet.speed = 220.0
	bullet.color = Color(1, 0.5, 0)
	bullets_node.add_child(bullet)

func _spawn_asteroid_ring() -> void:
	var container := get_tree().get_first_node_in_group("asteroids_container")
	if container == null:
		return
	for i in 6:
		var angle := float(i) / 6.0 * TAU
		var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		asteroid.asteroid_size = 0
		asteroid.position = global_position + Vector2(cos(angle), sin(angle)) * 80
		asteroid.move_velocity = Vector2(cos(angle), sin(angle)) * 100
		container.add_child(asteroid)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_medium"):
		cam.shake_medium()

func _detach_segment() -> void:
	if segments.size() <= 1:
		return
	var seg_pos: Vector2 = segments.pop_back()
	var container := get_tree().get_first_node_in_group("asteroids_container")
	if container:
		var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		asteroid.asteroid_size = 1
		asteroid.position = seg_pos
		asteroid.move_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 80
		container.add_child(asteroid)

func take_damage(amount: int, _bullet_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	damage_flash = 0.12
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_light"):
		cam.shake_light()
	EventBus.boss_damaged.emit("comet_worm", hp)
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	GameData.add_score(15000)
	EventBus.boss_defeated.emit("comet_worm")
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		# Chain explosion from tail to head
		for i in segments.size():
			var exp: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
			exp.global_position = segments[segments.size() - 1 - i]
			exp.setup(1, color, seg_size)
			effects.add_child(exp)
		var head_exp: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		head_exp.global_position = global_position
		head_exp.setup(0, head_color, head_size * 2)
		effects.add_child(head_exp)
		
		for i in 25:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 2 if i < 10 else (1 if i < 20 else 0)
			coin.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
	queue_free()

func _draw() -> void:
	if is_dead:
		return
	
	# Draw segments (back to front)
	for i in range(segments.size() - 1, -1, -1):
		var seg_local: Vector2 = segments[i] - global_position
		var seg_alpha := 0.4 + 0.4 * (1.0 - float(i) / float(segments.size()))
		var seg_r := seg_size * (0.7 + 0.3 * (1.0 - float(i) / float(segments.size())))
		draw_circle(seg_local, seg_r, Color(color, 0.08))
		draw_arc(seg_local, seg_r, 0, TAU, 8, Color(color, seg_alpha), 1.5, true)
	
	# Head
	var hc := head_color
	if damage_flash > 0:
		hc = hc.lerp(Color.WHITE, damage_flash / 0.12 * 0.8)
	draw_circle(Vector2.ZERO, head_size, Color(hc, 0.1))
	draw_arc(Vector2.ZERO, head_size, 0, TAU, 10, Color(hc, 0.9), 2.5, true)
	# Eyes
	draw_circle(Vector2(-8, -8), 3, Color(1, 1, 0, 0.8))
	draw_circle(Vector2(8, -8), 3, Color(1, 1, 0, 0.8))
	
	# HP bar
	var hp_ratio := float(hp) / float(max_hp)
	var bar_w := head_size * 2
	draw_rect(Rect2(-bar_w / 2, -head_size - 20, bar_w, 5), Color(0.2, 0.2, 0.2, 0.5))
	draw_rect(Rect2(-bar_w / 2, -head_size - 20, bar_w * hp_ratio, 5), Color(hc, 0.8))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-35, -head_size - 25), "COMET WORM", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(hc, 0.6))
