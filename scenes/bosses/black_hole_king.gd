extends Area2D
## Boss 5: Black Hole King — Final boss, gravity mechanics. Wave 25.

enum Phase { ONE, TWO, THREE }

var hp: int = 100
var max_hp: int = 100
var boss_size: float = 150.0
var color: Color = Color(1.0, 0.6, 0.2)
var current_phase: Phase = Phase.ONE
var damage_flash: float = 0.0
var is_dead: bool = false
var time_alive: float = 0.0

# Gravity
var gravity_strength: float = 80.0
var gravity_pulse_timer: float = 8.0

# Attacks
var asteroid_summon_timer: float = 6.0
var orbit_nodes: Array[float] = [0.0, TAU / 3, TAU * 2 / 3]  # 3 weak points

# Phase 2
var event_horizon_radius: float = 400.0
var event_horizon_shrink: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_setup_collision()
	position = Vector2(960, 400)

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = boss_size * 0.3
	collision.shape = shape
	add_child.call_deferred(collision)
	collision_layer = 32
	collision_mask = 2

func _process(delta: float) -> void:
	if is_dead:
		return
	time_alive += delta
	
	var hp_ratio := float(hp) / float(max_hp)
	if hp_ratio <= 0.4 and current_phase != Phase.THREE:
		current_phase = Phase.THREE
		gravity_strength = -120.0  # Reverse!
	elif hp_ratio <= 0.7 and current_phase == Phase.ONE:
		current_phase = Phase.TWO
		gravity_strength = 160.0
	
	_apply_gravity(delta)
	_process_attacks(delta)
	
	# Orbit weak points
	var orbit_speed := 1.0 + float(current_phase) * 0.5
	for i in orbit_nodes.size():
		orbit_nodes[i] += orbit_speed * delta
	
	if damage_flash > 0:
		damage_flash -= delta
	queue_redraw()

func _apply_gravity(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var dir: Vector2 = (global_position - player.global_position)
	var dist := dir.length()
	if dist < 20:
		return
	var force := gravity_strength / maxf(dist * 0.01, 1.0)
	if player is CharacterBody2D:
		player.velocity += dir.normalized() * force * delta

func _process_attacks(delta: float) -> void:
	asteroid_summon_timer -= delta
	if asteroid_summon_timer <= 0:
		var interval := 6.0 if current_phase == Phase.ONE else (4.0 if current_phase == Phase.TWO else 3.0)
		asteroid_summon_timer = interval
		_summon_asteroids()
	
	gravity_pulse_timer -= delta
	if gravity_pulse_timer <= 0:
		gravity_pulse_timer = 8.0
		_gravity_pulse()
	
	if current_phase == Phase.TWO:
		event_horizon_radius = maxf(event_horizon_radius - delta * 10, 150)
	
	if current_phase == Phase.THREE:
		# Asteroid rain
		if randi() % 60 == 0:
			_rain_asteroid()

func _summon_asteroids() -> void:
	var container := get_tree().get_first_node_in_group("asteroids_container")
	if container == null:
		return
	var count := 3 + int(current_phase) * 2
	for i in count:
		var angle := randf() * TAU
		var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		asteroid.asteroid_size = randi() % 2
		asteroid.position = global_position + Vector2(cos(angle), sin(angle)) * boss_size
		asteroid.move_velocity = Vector2(cos(angle), sin(angle)) * randf_range(80, 200)
		container.add_child(asteroid)

func _gravity_pulse() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_heavy"):
		cam.shake_heavy()

func _rain_asteroid() -> void:
	var container := get_tree().get_first_node_in_group("asteroids_container")
	if container == null:
		return
	var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
	asteroid.asteroid_size = 0
	asteroid.position = Vector2(randf() * 1920, -30)
	asteroid.move_velocity = Vector2(randf_range(-50, 50), randf_range(100, 250))
	container.add_child(asteroid)

func take_damage(amount: int, _bullet_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	damage_flash = 0.12
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_light"):
		cam.shake_light()
	EventBus.boss_damaged.emit("black_hole_king", hp)
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	GameData.add_score(25000)
	EventBus.boss_defeated.emit("black_hole_king")
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	if cam and cam.has_method("slow_motion"):
		cam.slow_motion(0.1, 3.0)
	
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		for i in 5:
			var exp: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
			exp.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			exp.setup(i % 3, color, boss_size * (0.3 + float(i) * 0.2))
			effects.add_child(exp)
		for i in 40:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 2 if i < 15 else (1 if i < 30 else 0)
			coin.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
		for i in 5:
			var powerup: Area2D = load("res://scenes/powerups/powerup.tscn").instantiate()
			var types := ["shield", "multi_shot", "rapid_fire", "slow_mo", "score_x2"]
			powerup.powerup_type = types[i]
			powerup.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			effects.add_child(powerup)
	queue_free()

func _draw() -> void:
	if is_dead:
		return
	var dc := color
	if damage_flash > 0:
		dc = dc.lerp(Color.WHITE, damage_flash / 0.12 * 0.8)
	
	# Accretion disk rings
	for i in 5:
		var r := boss_size * 0.25 + float(i) * 15
		var ring_col := Color.from_hsv(0.08 - float(i) * 0.02, 0.8, 1.0 - float(i) * 0.15, 0.2 + float(i) * 0.05)
		draw_arc(Vector2.ZERO, r, 0, TAU, 16, ring_col, 2.0, true)
	
	# Center dark
	draw_circle(Vector2.ZERO, boss_size * 0.15, Color(0, 0, 0, 0.9))
	draw_arc(Vector2.ZERO, boss_size * 0.15, 0, TAU, 12, Color(dc, 0.5), 1.5, true)
	
	# Orbit weak-point nodes
	for i in orbit_nodes.size():
		var angle: float = orbit_nodes[i]
		var node_pos := Vector2(cos(angle), sin(angle)) * boss_size * 0.35
		draw_circle(node_pos, 6, Color(1, 1, 1, 0.2))
		draw_arc(node_pos, 6, 0, TAU, 6, Color(1, 1, 1, 0.6), 1.0, true)
	
	# Event horizon (Phase 2)
	if current_phase == Phase.TWO:
		draw_arc(Vector2.ZERO, event_horizon_radius, 0, TAU, 20, Color(1, 0, 0, 0.15 + 0.1 * sin(time_alive * 3)), 2.0, true)
	
	# Gravity direction indicator
	var grav_col := Color(0, 0.5, 1, 0.3) if gravity_strength > 0 else Color(1, 0.3, 0, 0.3)
	for i in 4:
		var angle := float(i) / 4.0 * TAU + time_alive
		var inner_r := boss_size * 0.4
		var outer_r := boss_size * 0.55
		if gravity_strength < 0:
			# Reverse arrows (push out)
			var tmp := inner_r
			inner_r = outer_r
			outer_r = tmp
		var start := Vector2(cos(angle), sin(angle)) * inner_r
		var end := Vector2(cos(angle), sin(angle)) * outer_r
		draw_line(start, end, grav_col, 1.5)
	
	# HP bar
	var hp_ratio := float(hp) / float(max_hp)
	var bar_w := boss_size * 0.6
	draw_rect(Rect2(-bar_w / 2, -boss_size * 0.35 - 20, bar_w, 5), Color(0.2, 0.2, 0.2, 0.5))
	draw_rect(Rect2(-bar_w / 2, -boss_size * 0.35 - 20, bar_w * hp_ratio, 5), Color(dc, 0.8))
	var font := ScreenWrap.neon_font
	draw_string(font, Vector2(-50, -boss_size * 0.35 - 25), "BLACK HOLE KING", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(dc, 0.6))
