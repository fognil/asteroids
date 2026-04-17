extends Area2D
## Boss 2: Nebula Queen — Octagonal UFO with shield, Wave 10.

enum Phase { SHIELDED, EXPOSED }

var hp: int = 50
var max_hp: int = 50
var shield_hp: int = 15
var max_shield_hp: int = 15
var boss_size: float = 80.0
var speed: float = 60.0
var color: Color = Color(0.6, 0.2, 1.0)
var current_phase: Phase = Phase.SHIELDED
var damage_flash: float = 0.0
var is_dead: bool = false
var time_alive: float = 0.0

# Movement — figure-8
var fig8_speed: float = 0.4
var center: Vector2 = Vector2(960, 400)

# Attacks
var spread_timer: float = 5.0
var spawn_ufo_timer: float = 10.0
var shield_flicker: bool = false
var flicker_timer: float = 6.0
var flicker_window: float = 0.0

# Phase 2
var teleport_timer: float = 8.0
var mine_ring_timer: float = 12.0
var aimed_timer: float = 1.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = boss_size * 0.5
	collision.shape = shape
	add_child(collision)
	collision_layer = 32
	collision_mask = 2

func _process(delta: float) -> void:
	if is_dead:
		return
	time_alive += delta
	_process_movement(delta)
	
	match current_phase:
		Phase.SHIELDED:
			_process_shielded(delta)
		Phase.EXPOSED:
			_process_exposed(delta)
	
	if damage_flash > 0:
		damage_flash -= delta
	queue_redraw()

func _process_movement(delta: float) -> void:
	var t := time_alive * fig8_speed
	var spd := speed if current_phase == Phase.SHIELDED else speed * 2.0
	var target := center + Vector2(sin(t) * 300, sin(t * 2) * 150)
	var dir: Vector2 = (target - position).normalized()
	position += dir * spd * delta
	
	var vp := Vector2(1920, 1080)
	position.x = clampf(position.x, boss_size, vp.x - boss_size)
	position.y = clampf(position.y, boss_size, vp.y - boss_size)

func _process_shielded(delta: float) -> void:
	# Spread shot
	spread_timer -= delta
	if spread_timer <= 0:
		spread_timer = 5.0
		_shoot_spread(5)
	
	# Spawn scouts
	spawn_ufo_timer -= delta
	if spawn_ufo_timer <= 0:
		spawn_ufo_timer = 10.0
		_spawn_scouts()
	
	# Shield flicker (weak point window)
	if not shield_flicker:
		flicker_timer -= delta
		if flicker_timer <= 0:
			shield_flicker = true
			flicker_window = 1.5
	else:
		flicker_window -= delta
		if flicker_window <= 0:
			shield_flicker = false
			flicker_timer = 6.0

func _process_exposed(delta: float) -> void:
	aimed_timer -= delta
	if aimed_timer <= 0:
		aimed_timer = 1.0
		_shoot_aimed()
	
	teleport_timer -= delta
	if teleport_timer <= 0:
		teleport_timer = 8.0
		_teleport()
	
	mine_ring_timer -= delta
	if mine_ring_timer <= 0:
		mine_ring_timer = 12.0
		_spawn_mine_ring()

func _shoot_spread(count: int) -> void:
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var base_dir: Vector2 = (player.global_position - global_position).normalized()
	for i in count:
		var offset := (float(i) - float(count - 1) / 2.0) * deg_to_rad(12)
		var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
		bullet.position = global_position + base_dir * boss_size * 0.5
		bullet.direction = base_dir.rotated(offset)
		bullet.speed = 200.0
		bullet.color = color
		bullets_node.add_child(bullet)

func _shoot_aimed() -> void:
	_shoot_spread(1)

func _spawn_scouts() -> void:
	var enemies := get_tree().get_first_node_in_group("enemies_container")
	if enemies == null:
		return
	for i in 2:
		var ufo: Area2D = load("res://scenes/enemies/scout_ufo.tscn").instantiate()
		ufo.setup(i == 0)
		enemies.add_child(ufo)

func _teleport() -> void:
	var vp := Vector2(1920, 1080)
	# Explosion at old pos
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var exp: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		exp.global_position = global_position
		exp.setup(2, color, boss_size * 0.5)
		effects.add_child(exp)
	
	position = Vector2(randf_range(150, vp.x - 150), randf_range(150, vp.y - 150))
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_medium"):
		cam.shake_medium()

func _spawn_mine_ring() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects == null:
		return
	for i in 8:
		var angle := float(i) / 8.0 * TAU
		var mine: Area2D = load("res://scenes/enemies/mine.tscn").instantiate()
		mine.global_position = global_position + Vector2(cos(angle), sin(angle)) * boss_size * 0.8
		effects.add_child(mine)

func take_damage(amount: int, _bullet_dir: Vector2 = Vector2.ZERO) -> void:
	if current_phase == Phase.SHIELDED:
		if shield_flicker:
			shield_hp -= amount * 2  # ×2 during flicker
		else:
			shield_hp -= amount
		
		if shield_hp <= 0:
			shield_hp = 0
			current_phase = Phase.EXPOSED
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("shake_heavy"):
				cam.shake_heavy()
	else:
		hp -= amount
	
	damage_flash = 0.12
	EventBus.boss_damaged.emit("nebula_queen", hp)
	
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	GameData.add_score(10000)
	EventBus.boss_defeated.emit("nebula_queen")
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		for i in 3:
			var exp: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
			exp.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			exp.setup(i, color, boss_size * (0.5 + float(i) * 0.3))
			effects.add_child(exp)
		for i in 20:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 2 if i < 8 else (1 if i < 15 else 0)
			coin.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
	queue_free()

func _draw() -> void:
	if is_dead:
		return
	var draw_color := color
	if damage_flash > 0:
		draw_color = draw_color.lerp(Color.WHITE, damage_flash / 0.12 * 0.8)
	if current_phase == Phase.EXPOSED:
		draw_color = draw_color.lerp(Color(1, 0.2, 0.1), 0.3 + 0.2 * sin(time_alive * 4))
	
	# Octagon body
	var pts := PackedVector2Array()
	for i in 8:
		var angle := float(i) / 8.0 * TAU
		pts.append(Vector2(cos(angle) * boss_size * 0.5, sin(angle) * boss_size * 0.5))
	pts.append(pts[0])
	draw_polyline(pts, Color(draw_color, 0.15), 8.0, true)
	draw_polyline(pts, Color(draw_color, 0.9), 2.0, true)
	
	# Shield
	if current_phase == Phase.SHIELDED:
		var shield_alpha := 0.3
		if shield_flicker:
			shield_alpha = 0.1 + 0.4 * abs(sin(time_alive * 15))
		var shield_r := boss_size * 0.65
		draw_arc(Vector2.ZERO, shield_r, 0, TAU, 12, Color(0.3, 0.6, 1, shield_alpha), 2.0, true)
		# Shield HP
		var sratio := float(shield_hp) / float(max_shield_hp)
		draw_arc(Vector2.ZERO, shield_r + 3, -PI / 2, -PI / 2 + TAU * sratio, 12, Color(0.3, 0.6, 1, 0.5), 3.0, true)
	
	# HP bar
	var hp_ratio := float(hp) / float(max_hp)
	var bar_w := boss_size * 0.8
	var bar_pos := Vector2(-bar_w / 2, -boss_size * 0.5 - 20)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, 5)), Color(0.2, 0.2, 0.2, 0.5))
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, 5)), Color(draw_color, 0.8))
	
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-40, -boss_size * 0.5 - 25), "NEBULA QUEEN", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(draw_color, 0.6))
