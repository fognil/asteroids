extends CharacterBody2D
## Player ship — handles movement (thrust/inertia), shooting, heat, trail, shield visuals.

# === Movement ===
@export var rotation_speed: float = 4.5
@export var thrust_force: float = 600.0
@export var max_speed: float = 450.0
@export var drag: float = 0.997

# === Shooting ===
@export var fire_rate: float = 0.15
@export var bullet_speed: float = 800.0
@export var max_bullets: int = 8

# === Heat ===
@export var heat_per_shot: float = 6.0
@export var heat_cooldown_rate: float = 20.0
@export var overheat_lockout: float = 1.5

# === Ship Visual ===
@export var ship_color: Color = Color(0, 1, 1)
@export var ship_size: float = 20.0

# === State ===
var ship_velocity: Vector2 = Vector2.ZERO
var heat: float = 0.0
var is_overheated: bool = false
var overheat_timer: float = 0.0
var fire_timer: float = 0.0
var is_invincible: bool = false
var invincible_timer: float = 0.0
var is_thrusting: bool = false
var is_dead: bool = false
var has_shield: bool = false

# Joystick input
var move_input: Vector2 = Vector2.ZERO

# Engine trail particles
var trail_points: Array[Dictionary] = []
const MAX_TRAIL_POINTS := 25
const TRAIL_SPAWN_INTERVAL := 0.02
var trail_timer: float = 0.0

# Shield visual
var shield_angle: float = 0.0
var shield_pulse: float = 0.0

const INVINCIBLE_DURATION: float = 3.0
const BulletScene = preload("res://scenes/player/bullet.tscn")

func _ready() -> void:
	add_to_group("player")
	var vp := get_viewport_rect().size
	position = vp / 2.0
	
	# Add collision shape so physics (Area2D body_entered) works
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = ship_size * 0.5
	collision.shape = shape
	add_child.call_deferred(collision)
	
	# Set collision layer so coins/powerups/enemy bullets can detect us
	collision_layer = 1   # Player layer
	collision_mask = 0    # We don't detect collisions ourselves (game_manager does)

func _process(delta: float) -> void:
	if is_dead:
		return

	_handle_heat(delta)
	_handle_shooting(delta)
	_handle_invincibility(delta)
	_update_trail(delta)
	_update_shield(delta)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_input(delta)
	_handle_movement(delta)
	_apply_screen_wrap()

# === Input ===
func _handle_input(delta: float) -> void:
	if move_input == Vector2.ZERO:
		var input_dir := Vector2.ZERO
		if Input.is_action_pressed("rotate_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("rotate_right"):
			input_dir.x += 1
		if Input.is_action_pressed("thrust"):
			input_dir.y -= 1

		if input_dir != Vector2.ZERO:
			var target_angle := input_dir.angle() + PI / 2.0
			rotation = lerp_angle(rotation, target_angle, 0.15)
			is_thrusting = true
			ship_velocity += Vector2.UP.rotated(rotation) * thrust_force * delta
		else:
			is_thrusting = false
	else:
		if move_input.length() > 0.1:
			var target_angle := move_input.angle() + PI / 2.0
			rotation = lerp_angle(rotation, target_angle, 0.15)
			is_thrusting = true
			ship_velocity += Vector2.UP.rotated(rotation) * thrust_force * delta * move_input.length()
		else:
			is_thrusting = false

# === Movement ===
func _handle_movement(_delta: float) -> void:
	ship_velocity = ship_velocity.limit_length(max_speed)
	ship_velocity *= drag
	if ship_velocity.length() < 1.0:
		ship_velocity = Vector2.ZERO
	velocity = ship_velocity
	move_and_slide()

func _apply_screen_wrap() -> void:
	position = ScreenWrap.wrap_position(position, ship_size)

# === Heat System ===
func _handle_heat(delta: float) -> void:
	if is_overheated:
		overheat_timer -= delta
		if overheat_timer <= 0:
			is_overheated = false
			heat = 50.0
	else:
		heat = maxf(0.0, heat - heat_cooldown_rate * delta)
	EventBus.heat_changed.emit(heat)

# === Shooting ===
func _handle_shooting(delta: float) -> void:
	fire_timer -= delta
	if Input.is_action_pressed("fire") and fire_timer <= 0 and not is_overheated and not is_dead:
		_fire_bullet()
		fire_timer = fire_rate

func _fire_bullet() -> void:
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	if bullets_node.get_child_count() >= max_bullets:
		return

	var base_dir := Vector2.UP.rotated(rotation)
	var spawn_pos := position + base_dir * (ship_size + 5)
	
	# Multi-shot: fire 3 bullets in spread
	var shot_angles: Array[float] = [0.0]
	if PowerupManager.is_active("multi_shot"):
		shot_angles = [-deg_to_rad(20), 0.0, deg_to_rad(20)]
	
	for angle_offset in shot_angles:
		if bullets_node.get_child_count() >= max_bullets + 4:  # Allow a few extra for multi-shot
			break
		var bullet := BulletScene.instantiate()
		bullet.position = spawn_pos
		bullet.rotation = rotation + angle_offset
		bullet.direction = base_dir.rotated(angle_offset)
		bullet.speed = bullet_speed
		bullet.color = ship_color
		bullets_node.add_child(bullet)
	
	AudioManager.play_sfx("shoot")

	heat += heat_per_shot
	if heat >= 100.0:
		heat = 100.0
		is_overheated = true
		overheat_timer = overheat_lockout
		AudioManager.play_sfx("overheat")
	
	# Slight recoil screen shake
	var cam := _get_camera()
	if cam:
		cam.shake(1.0, 0.05)

# === Engine Trail ===
func _update_trail(delta: float) -> void:
	trail_timer -= delta
	
	if is_thrusting and trail_timer <= 0:
		trail_timer = TRAIL_SPAWN_INTERVAL
		var engine_pos := global_position + Vector2.DOWN.rotated(rotation) * ship_size * 0.5
		trail_points.append({
			"pos": engine_pos,
			"life": 0.5,  # seconds to live
			"max_life": 0.5,
			"size": randf_range(2.0, 4.0),
			"color_shift": randf()  # For color variation
		})
	
	# Update existing trail points
	var i := trail_points.size() - 1
	while i >= 0:
		trail_points[i]["life"] -= delta
		if trail_points[i]["life"] <= 0:
			trail_points.remove_at(i)
		i -= 1
	
	# Keep max count
	while trail_points.size() > MAX_TRAIL_POINTS:
		trail_points.remove_at(0)

# === Shield ===
func _update_shield(delta: float) -> void:
	shield_angle += delta * 2.0
	shield_pulse += delta * 4.0

# === Invincibility ===
func _handle_invincibility(delta: float) -> void:
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false

func take_hit() -> void:
	if is_invincible or is_dead:
		return
	
	if has_shield:
		has_shield = false
		EventBus.powerup_expired.emit("shield")
		AudioManager.play_sfx("shield_break")
		# Shield break effect
		var cam := _get_camera()
		if cam:
			cam.shake(5.0, 0.15)
		return
	
	GameData.lose_life()
	
	# Screen shake on hit
	var cam2 := _get_camera()
	if cam2:
		cam2.shake_heavy()
		if GameData.lives <= 1:
			cam2.slow_motion(0.3, 0.8)  # Dramatic slow-mo on last life
	
	if GameData.lives <= 0:
		die()
	else:
		is_invincible = true
		invincible_timer = INVINCIBLE_DURATION

func die() -> void:
	is_dead = true
	visible = false
	# Death slow-mo
	var cam := _get_camera()
	if cam:
		cam.shake_extreme()
		cam.slow_motion(0.15, 1.5)
	EventBus.player_died.emit()

func respawn() -> void:
	is_dead = false
	visible = true
	var vp := get_viewport_rect().size
	position = vp / 2.0
	ship_velocity = Vector2.ZERO
	rotation = 0
	heat = 0
	is_overheated = false
	is_invincible = true
	invincible_timer = INVINCIBLE_DURATION
	trail_points.clear()
	has_shield = false

func _get_camera() -> Node:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		return cam
	return null

# === Drawing (Neon Wireframe + Trail + Shield) ===
func _draw() -> void:
	if is_dead:
		return

	var alpha := 1.0
	if is_invincible:
		alpha = 0.3 + 0.7 * abs(sin(Time.get_ticks_msec() * 0.01))

	_draw_trail()
	_draw_ship(alpha)
	if has_shield:
		_draw_shield(alpha)

func _draw_trail() -> void:
	for point in trail_points:
		var life_ratio: float = point["life"] / point["max_life"]
		var size: float = point["size"] * life_ratio
		var shift: float = point["color_shift"]
		
		# Color fades from cyan → orange → transparent
		var r := lerpf(0.0, 1.0, 1.0 - life_ratio)
		var g := lerpf(1.0, 0.4, 1.0 - life_ratio)
		var b := lerpf(1.0, 0.1, 1.0 - life_ratio)
		var a := life_ratio * 0.7
		
		var trail_color := Color(r, g, b, a)
		var local_pos: Vector2 = Vector2(point["pos"]) - global_position
		# Rotate to local space
		local_pos = local_pos.rotated(-rotation)
		
		draw_circle(local_pos, size, trail_color)
		# Glow
		if size > 1.5:
			draw_circle(local_pos, size * 2.0, Color(r, g, b, a * 0.2))

func _draw_ship(alpha: float) -> void:
	var draw_color := Color(ship_color, alpha)
	var glow_color := Color(ship_color, alpha * 0.3)
	var s := ship_size

	# Ship outline points
	var points := PackedVector2Array([
		Vector2(0, -s),
		Vector2(-s * 0.6, s * 0.7),
		Vector2(-s * 0.15, s * 0.4),
		Vector2(0, s * 0.55),
		Vector2(s * 0.15, s * 0.4),
		Vector2(s * 0.6, s * 0.7),
		Vector2(0, -s),
	])

	# Outer glow
	draw_polyline(points, glow_color, 8.0, true)
	# Inner glow
	draw_polyline(points, Color(ship_color, alpha * 0.5), 4.0, true)
	# Core line
	draw_polyline(points, draw_color, 2.0, true)

	# Engine flame when thrusting
	if is_thrusting:
		var t := Time.get_ticks_msec() / 50.0
		var flame_alpha := 0.5 + 0.5 * sin(t)
		var flame_len := s * (0.5 + randf() * 0.4)

		# Inner flame (white-cyan)
		var inner_points := PackedVector2Array([
			Vector2(-s * 0.15, s * 0.45),
			Vector2(0, s * 0.45 + flame_len * 0.6),
			Vector2(s * 0.15, s * 0.45),
		])
		draw_polyline(inner_points, Color(1, 1, 1, flame_alpha * 0.8), 2.0, true)

		# Outer flame (orange-red glow)
		var outer_points := PackedVector2Array([
			Vector2(-s * 0.25, s * 0.5),
			Vector2(0, s * 0.5 + flame_len),
			Vector2(s * 0.25, s * 0.5),
		])
		draw_polyline(outer_points, Color(1, 0.5, 0.1, flame_alpha * 0.6), 3.0, true)
		# Flame glow
		draw_polyline(outer_points, Color(1, 0.3, 0.0, flame_alpha * 0.2), 8.0, true)

	# Heat warning glow
	if heat > 50:
		var heat_ratio := (heat - 50.0) / 50.0
		var heat_color := Color(1.0, 1.0 - heat_ratio, 0.0, heat_ratio * 0.3)
		draw_polyline(points, heat_color, 6.0, true)

func _draw_shield(alpha: float) -> void:
	var s := ship_size * 1.8
	var segments := 24
	var gap_angle := PI / 6  # Gap in shield circle for visual interest

	# Rotating hex pattern shield
	var shield_color := Color(0.2, 0.6, 1.0, alpha * (0.3 + 0.15 * sin(shield_pulse)))
	var shield_glow := Color(0.2, 0.6, 1.0, alpha * 0.1)

	# Main shield arc
	draw_arc(Vector2.ZERO, s, shield_angle, shield_angle + TAU - gap_angle, segments, shield_color, 2.0, true)
	# Glow
	draw_arc(Vector2.ZERO, s, shield_angle, shield_angle + TAU - gap_angle, segments, shield_glow, 6.0, true)
	# Inner ring
	draw_arc(Vector2.ZERO, s * 0.85, shield_angle + 0.3, shield_angle + TAU - gap_angle - 0.3, segments, Color(0.2, 0.6, 1.0, alpha * 0.15), 1.0, true)

	# Small hex markers on shield
	for i in 6:
		var angle := shield_angle + (float(i) / 6.0) * (TAU - gap_angle)
		var pos := Vector2(cos(angle) * s, sin(angle) * s)
		draw_circle(pos, 2.0, Color(0.4, 0.8, 1.0, alpha * 0.5))
