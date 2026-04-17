extends Area2D
## Boss 4: Void Sentinel — Diamond shape, 4 turrets + core. Wave 20.

enum Phase { TURRETS, CORE_EXPOSED, DESPERATE }

var hp: int = 60
var max_hp: int = 60
var boss_size: float = 100.0
var color: Color = Color(0.2, 0.5, 1.0)
var current_phase: Phase = Phase.TURRETS
var damage_flash: float = 0.0
var is_dead: bool = false
var time_alive: float = 0.0
var rotation_speed: float = 0.3

# Turrets
var turret_hp: Array[int] = [10, 10, 10, 10]
var turret_angles: Array[float] = [0, PI / 2, PI, PI * 1.5]
var turret_timers: Array[float] = [2.0, 2.5, 3.0, 3.5]
var turrets_alive: int = 4

# Phase 2
var laser_sweep: bool = false
var laser_angle: float = 0.0
var laser_timer: float = 15.0
var emp_timer: float = 10.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = boss_size * 0.35
	collision.shape = shape
	add_child(collision)
	collision_layer = 32
	collision_mask = 2

func _process(delta: float) -> void:
	if is_dead:
		return
	time_alive += delta
	
	# Count alive turrets
	turrets_alive = 0
	for t_hp in turret_hp:
		if t_hp > 0:
			turrets_alive += 1
	
	if turrets_alive == 0 and current_phase == Phase.TURRETS:
		current_phase = Phase.CORE_EXPOSED
	if hp <= 15 and current_phase == Phase.CORE_EXPOSED:
		current_phase = Phase.DESPERATE
		# Regen 1 turret
		turret_hp[0] = 10
	
	# Rotation
	for i in 4:
		turret_angles[i] += rotation_speed * delta
	
	match current_phase:
		Phase.TURRETS:
			_process_turrets(delta)
		Phase.CORE_EXPOSED:
			_process_core(delta)
		Phase.DESPERATE:
			_process_turrets(delta)
			_process_core(delta)
	
	# Movement (phase 2+)
	if current_phase != Phase.TURRETS:
		var t := time_alive * 0.5
		var target := Vector2(960 + sin(t) * 300, 400 + cos(t * 0.7) * 200)
		position = position.lerp(target, delta * 0.5)
	
	if damage_flash > 0:
		damage_flash -= delta
	queue_redraw()

func _process_turrets(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	
	var speed_mult := 1.5 if current_phase == Phase.DESPERATE else 1.0
	for i in 4:
		if turret_hp[i] <= 0:
			continue
		turret_timers[i] -= delta
		if turret_timers[i] <= 0:
			turret_timers[i] = 2.0 / speed_mult
			var turret_pos := _get_turret_pos(i)
			var dir: Vector2 = (player.global_position - turret_pos).normalized()
			var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
			bullet.position = turret_pos
			bullet.direction = dir
			bullet.speed = 180.0
			bullet.color = color
			bullets_node.add_child(bullet)

func _process_core(delta: float) -> void:
	# Laser sweep
	laser_timer -= delta
	if laser_timer <= 0:
		laser_timer = 12.0
		laser_sweep = true
		laser_angle = 0.0
	
	if laser_sweep:
		laser_angle += delta * 2.0
		if laser_angle > TAU:
			laser_sweep = false
		# Check player in laser
		var player := get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var to_player: Vector2 = player.global_position - global_position
			var angle_diff := absf(wrapf(to_player.angle() - laser_angle, -PI, PI))
			if angle_diff < 0.15 and to_player.length() < 500:
				if player.has_method("take_hit"):
					player.take_hit()

func _get_turret_pos(idx: int) -> Vector2:
	var angle: float = turret_angles[idx]
	return global_position + Vector2(cos(angle), sin(angle)) * boss_size * 0.5

func take_damage(amount: int, bullet_pos: Vector2 = Vector2.ZERO) -> void:
	if current_phase == Phase.TURRETS:
		# Check if bullet hit a turret
		var hit_turret := false
		for i in 4:
			if turret_hp[i] <= 0:
				continue
			var t_pos := _get_turret_pos(i)
			if bullet_pos.distance_to(t_pos) < 25 or bullet_pos == Vector2.ZERO:
				turret_hp[i] -= amount
				hit_turret = true
				break
		if not hit_turret:
			return  # Core invincible during turret phase
	else:
		hp -= amount
	
	damage_flash = 0.12
	EventBus.boss_damaged.emit("void_sentinel", hp)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_light"):
		cam.shake_light()
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	GameData.add_score(20000)
	EventBus.boss_defeated.emit("void_sentinel")
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var exp: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		exp.global_position = global_position
		exp.setup(0, color, boss_size * 1.5)
		effects.add_child(exp)
		for i in 30:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 2 if i < 12 else (1 if i < 25 else 0)
			coin.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
	queue_free()

func _draw() -> void:
	if is_dead:
		return
	var dc := color
	if damage_flash > 0:
		dc = dc.lerp(Color.WHITE, damage_flash / 0.12 * 0.8)
	
	# Diamond body
	var s := boss_size * 0.4
	var diamond := PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0), Vector2(0, -s)
	])
	draw_polyline(diamond, Color(dc, 0.15), 6.0, true)
	draw_polyline(diamond, Color(dc, 0.9), 2.0, true)
	
	# Turrets
	for i in 4:
		var t_pos := _get_turret_pos(i) - global_position
		var t_alive := turret_hp[i] > 0
		var t_col := Color(dc, 0.8) if t_alive else Color(0.3, 0.3, 0.3, 0.3)
		draw_circle(t_pos, 10, Color(t_col, 0.2))
		draw_arc(t_pos, 10, 0, TAU, 6, t_col, 1.5, true)
		if t_alive:
			draw_line(Vector2.ZERO, t_pos, Color(dc, 0.2), 1.0)
	
	# Laser sweep
	if laser_sweep:
		var end := Vector2(cos(laser_angle), sin(laser_angle)) * 500
		draw_line(Vector2.ZERO, end, Color(1, 0.3, 0, 0.6), 2.0)
		draw_line(Vector2.ZERO, end, Color(1, 0.5, 0, 0.2), 6.0)
	
	# HP bar
	var hp_ratio := float(hp) / float(max_hp)
	var bar_w := boss_size * 0.8
	draw_rect(Rect2(-bar_w / 2, -boss_size * 0.45 - 20, bar_w, 5), Color(0.2, 0.2, 0.2, 0.5))
	draw_rect(Rect2(-bar_w / 2, -boss_size * 0.45 - 20, bar_w * hp_ratio, 5), Color(dc, 0.8))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-40, -boss_size * 0.45 - 25), "VOID SENTINEL", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(dc, 0.6))
