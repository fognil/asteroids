extends Area2D
## Boss 1: Rock Titan — Giant asteroid, wave 5 boss. 2 phases.

enum Phase { ONE, TWO }

var hp: int = 30
var max_hp: int = 30
var boss_size: float = 120.0
var speed: float = 40.0
var move_dir: Vector2 = Vector2(1, 0.6).normalized()
var color: Color = Color(1.0, 0.85, 0.2)  # Gold
var current_phase: Phase = Phase.ONE
var damage_flash: float = 0.0
var is_dead: bool = false

# Attack timers
var fragment_timer: float = 4.0
var ring_timer: float = 8.0
var charge_timer: float = 0.0
var is_charging: bool = false
var charge_target: Vector2 = Vector2.ZERO
var charge_telegraph: float = 0.0
var charge_speed: float = 400.0

# Visuals
var crack_lines: Array[PackedVector2Array] = []
var polygon_points: PackedVector2Array = PackedVector2Array()
var glow_pulse: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_generate_polygon()
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = boss_size * 0.6
	collision.shape = shape
	add_child.call_deferred(collision)
	collision_layer = 32
	collision_mask = 2
	area_entered.connect(_on_area_entered)

func _generate_polygon() -> void:
	polygon_points = PackedVector2Array()
	var num_verts := 12
	for i in num_verts:
		var angle := float(i) / float(num_verts) * TAU
		var r := boss_size * 0.5 * randf_range(0.85, 1.15)
		polygon_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	polygon_points.append(polygon_points[0])

func _process(delta: float) -> void:
	if is_dead:
		return
	
	glow_pulse += delta * 3.0
	
	# Phase check
	var hp_ratio := float(hp) / float(max_hp)
	if hp_ratio <= 0.5 and current_phase == Phase.ONE:
		current_phase = Phase.TWO
		speed *= 1.5
		_add_cracks()
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("shake_heavy"):
			cam.shake_heavy()
	
	# Movement
	if is_charging:
		_process_charge(delta)
	else:
		_process_movement(delta)
		_process_attacks(delta)
	
	if damage_flash > 0:
		damage_flash -= delta
	
	queue_redraw()

func _process_movement(delta: float) -> void:
	position += move_dir * speed * delta
	
	# Bounce off edges
	var vp := Vector2(1920, 1080)
	if position.x < boss_size or position.x > vp.x - boss_size:
		move_dir.x *= -1
		position.x = clampf(position.x, boss_size, vp.x - boss_size)
	if position.y < boss_size or position.y > vp.y - boss_size:
		move_dir.y *= -1
		position.y = clampf(position.y, boss_size, vp.y - boss_size)

func _process_attacks(delta: float) -> void:
	var interval_mult := 1.0 if current_phase == Phase.ONE else 0.7
	
	# Fragment shots
	fragment_timer -= delta
	if fragment_timer <= 0:
		fragment_timer = 4.0 * interval_mult
		_shoot_fragments()
	
	# Ring attack
	ring_timer -= delta
	if ring_timer <= 0:
		ring_timer = 8.0 * interval_mult
		_spawn_ring()
	
	# Charge dash (Phase 2 only)
	if current_phase == Phase.TWO:
		charge_timer -= delta
		if charge_timer <= 0:
			charge_timer = 6.0
			_start_charge()

func _shoot_fragments() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	
	var base_dir: Vector2 = (player.global_position - global_position).normalized()
	for i in 3:
		var offset := (float(i) - 1.0) * deg_to_rad(15)
		var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
		bullet.position = global_position + base_dir * boss_size * 0.5
		bullet.direction = base_dir.rotated(offset)
		bullet.speed = 180.0
		bullet.color = Color(1, 0.8, 0.2)
		bullets_node.add_child(bullet)

func _spawn_ring() -> void:
	var asteroids_container := get_tree().get_first_node_in_group("asteroids_container")
	if asteroids_container == null:
		return
	
	for i in 8:
		var angle := float(i) / 8.0 * TAU
		var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		asteroid.asteroid_size = 0  # Small
		asteroid.position = global_position + Vector2(cos(angle), sin(angle)) * boss_size * 0.6
		asteroid.move_velocity = Vector2(cos(angle), sin(angle)) * 120.0
		asteroids_container.add_child(asteroid)
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_medium"):
		cam.shake_medium()

func _start_charge() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	charge_target = player.global_position
	charge_telegraph = 1.5
	is_charging = true

func _process_charge(delta: float) -> void:
	if charge_telegraph > 0:
		charge_telegraph -= delta
		# Telegraph: glow intensifies
		if charge_telegraph <= 0:
			# Execute charge
			var dir: Vector2 = (charge_target - global_position).normalized()
			move_dir = dir
			speed = charge_speed
		return
	
	# Charging forward
	position += move_dir * speed * delta
	
	# Check if past target or hit edge
	var vp := Vector2(1920, 1080)
	if position.x < -20 or position.x > vp.x + 20 or position.y < -20 or position.y > vp.y + 20:
		# Wrap back
		position.x = clampf(position.x, boss_size, vp.x - boss_size)
		position.y = clampf(position.y, boss_size, vp.y - boss_size)
		is_charging = false
		speed = 40.0 * 1.5  # Phase 2 speed
		move_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("shake_heavy"):
			cam.shake_heavy()

func take_damage(amount: int, _bullet_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	damage_flash = 0.12
	
	if randf() < 0.3:
		_add_cracks()
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_light"):
		cam.shake_light()
	
	EventBus.boss_damaged.emit("rock_titan", hp)
	
	if hp <= 0:
		_die()

func _add_cracks() -> void:
	var crack := PackedVector2Array()
	var start := Vector2(randf_range(-boss_size * 0.3, boss_size * 0.3), randf_range(-boss_size * 0.3, boss_size * 0.3))
	crack.append(start)
	for _j in randi_range(2, 4):
		start += Vector2(randf_range(-15, 15), randf_range(-15, 15))
		crack.append(start)
	crack_lines.append(crack)

func _die() -> void:
	is_dead = true
	GameData.add_score(5000)
	EventBus.boss_defeated.emit("rock_titan")
	
	# Slow-mo + explosion
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	if cam and cam.has_method("slow_motion"):
		cam.slow_motion(0.15, 2.0)
	
	# Spawn explosion
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var explosion: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.setup(0, color, boss_size * 1.5)
		effects.add_child(explosion)
		
		# Rain of coins
		for i in 15:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 2 if i < 5 else (1 if i < 10 else 0)  # 5 gold, 5 silver, 5 bronze
			coin.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
		
		# Rare power-up
		var powerup: Area2D = load("res://scenes/powerups/powerup.tscn").instantiate()
		powerup.powerup_type = "shield"
		powerup.global_position = global_position
		effects.add_child(powerup)
	
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _draw() -> void:
	if is_dead:
		return
	
	var draw_color := color
	if damage_flash > 0:
		draw_color = draw_color.lerp(Color.WHITE, damage_flash / 0.12 * 0.8)
	
	var hp_ratio := float(hp) / float(max_hp)
	
	# Phase 2: red tint
	if current_phase == Phase.TWO:
		draw_color = draw_color.lerp(Color(1, 0.2, 0.1), 0.3 + 0.2 * sin(glow_pulse))
	
	# Outer glow
	draw_polyline(polygon_points, Color(draw_color, 0.1), 12.0, true)
	draw_polyline(polygon_points, Color(draw_color, 0.25), 6.0, true)
	# Core outline
	draw_polyline(polygon_points, Color(draw_color, 0.9), 2.5, true)
	
	# Cracks (glow)
	for crack in crack_lines:
		if crack.size() >= 2:
			var crack_color := Color(1, 0.5, 0, 0.6) if current_phase == Phase.ONE else Color(1, 0.2, 0, 0.8)
			draw_polyline(crack, crack_color, 1.5)
	
	# Charge telegraph
	if is_charging and charge_telegraph > 0:
		var t := 1.0 - charge_telegraph / 1.5
		draw_circle(Vector2.ZERO, boss_size * 0.6 * (1.0 + t * 0.3), Color(1, 0.3, 0, t * 0.3))
		# Direction line
		var dir_to_target: Vector2 = (charge_target - global_position).normalized()
		draw_line(Vector2.ZERO, dir_to_target * boss_size * t, Color(1, 0.3, 0, t * 0.5), 2.0)
	
	# HP bar (top of boss)
	var bar_w := boss_size * 0.8
	var bar_h := 5.0
	var bar_pos := Vector2(-bar_w / 2, -boss_size * 0.55 - 15)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.2, 0.2, 0.2, 0.5))
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, bar_h)), Color(draw_color, 0.8))
	
	# Boss name
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-30, -boss_size * 0.55 - 22), "ROCK TITAN", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(draw_color, 0.6))
