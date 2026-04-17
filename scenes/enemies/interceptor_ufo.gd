extends Area2D
## Interceptor UFO — aggressive chaser, burst fire. Wave 15+. Most dangerous UFO.

enum AIState { CHASE, FIRE, RETREAT }

var speed_chase: float = 120.0
var speed_retreat: float = 60.0
var hp: int = 4
var max_hp: int = 4
var points: int = 600
var color: Color = Color(0, 0.87, 1)  # Cyan
var ufo_size: float = 30.0
var damage_flash: float = 0.0
var is_dead: bool = false

# AI
var ai_state: AIState = AIState.CHASE
var chase_timer: float = 3.0
var fire_burst_count: int = 0
var burst_timer: float = 0.0
var retreat_timer: float = 2.0
var trail_positions: Array[Vector2] = []

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = ufo_size * 0.6
	collision.shape = shape
	add_child.call_deferred(collision)
	collision_layer = 32
	collision_mask = 2

func setup(from_left: bool) -> void:
	var vp := ScreenWrap.get_viewport_size()
	if from_left:
		position = Vector2(-ufo_size, randf_range(100, vp.y - 100))
	else:
		position = Vector2(vp.x + ufo_size, randf_range(100, vp.y - 100))

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Store trail
	trail_positions.push_front(global_position)
	if trail_positions.size() > 8:
		trail_positions.pop_back()
	
	match ai_state:
		AIState.CHASE:
			_process_chase(delta)
		AIState.FIRE:
			_process_fire(delta)
		AIState.RETREAT:
			_process_retreat(delta)
	
	# Keep on screen
	var vp := ScreenWrap.get_viewport_size()
	position.x = clampf(position.x, 20, vp.x - 20)
	position.y = clampf(position.y, 20, vp.y - 20)
	
	if damage_flash > 0:
		damage_flash -= delta
	queue_redraw()

func _process_chase(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dir: Vector2 = (player.global_position - global_position).normalized()
		position += dir * speed_chase * delta
		rotation = dir.angle() + PI / 2
		
		# Close enough? Fire!
		var dist := global_position.distance_to(player.global_position)
		if dist < 250:
			ai_state = AIState.FIRE
			fire_burst_count = 3
			burst_timer = 0.3
	else:
		chase_timer -= delta
		if chase_timer <= 0:
			queue_free()

func _process_fire(delta: float) -> void:
	burst_timer -= delta
	if burst_timer <= 0 and fire_burst_count > 0:
		burst_timer = 0.2
		fire_burst_count -= 1
		_shoot()
	
	if fire_burst_count <= 0 and burst_timer <= 0:
		ai_state = AIState.RETREAT
		retreat_timer = 2.0

func _process_retreat(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var away: Vector2 = (global_position - player.global_position).normalized()
		position += away * speed_retreat * delta
		rotation = (-away).angle() + PI / 2
	
	retreat_timer -= delta
	if retreat_timer <= 0:
		ai_state = AIState.CHASE
		chase_timer = 3.0

func _shoot() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	var bullets_node := get_tree().get_first_node_in_group("bullets")
	if bullets_node == null:
		return
	
	var bullet: Area2D = load("res://scenes/enemies/enemy_bullet.tscn").instantiate()
	bullet.position = global_position
	bullet.direction = (player.global_position - global_position).normalized()
	bullet.speed = 300.0
	bullet.color = Color(0, 0.8, 1)
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
	EventBus.enemy_destroyed.emit("interceptor", global_position)
	
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var explosion: Node2D = load("res://scenes/effects/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.setup(2, color, ufo_size * 1.2)
		effects.add_child(explosion)
		for i in 5:
			var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
			coin.tier = 1 if i < 3 else 2
			coin.global_position = global_position
			coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
			effects.add_child(coin)
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_heavy"):
		cam.shake_heavy()
	queue_free()

func _draw() -> void:
	if is_dead:
		return
	var draw_color := color
	if damage_flash > 0:
		draw_color = draw_color.lerp(Color.WHITE, damage_flash / 0.15 * 0.8)
	
	var s := ufo_size
	# Arrow shape
	var pts := PackedVector2Array([
		Vector2(0, -s * 0.6), Vector2(-s * 0.4, s * 0.4),
		Vector2(0, s * 0.2), Vector2(s * 0.4, s * 0.4), Vector2(0, -s * 0.6)
	])
	draw_polyline(pts, Color(draw_color, 0.2), 5.0, true)
	draw_polyline(pts, Color(draw_color, 0.9), 1.5, true)
	
	# Lightning trail (draw in local space)
	if trail_positions.size() > 1:
		for i in range(1, mini(trail_positions.size(), 6)):
			var from_local: Vector2 = (trail_positions[i - 1] - global_position).rotated(-rotation)
			var to_local: Vector2 = (trail_positions[i] - global_position).rotated(-rotation)
			var alpha_t := 1.0 - float(i) / 6.0
			draw_line(from_local, to_local, Color(draw_color, alpha_t * 0.4), 1.0)
	
	# HP bar
	var hp_ratio := float(hp) / float(max_hp)
	if hp_ratio < 1.0:
		var bar_w := s * 0.6
		draw_rect(Rect2(-bar_w / 2, -s * 0.6 - 10, bar_w, 3), Color(0.3, 0.3, 0.3, 0.5))
		draw_rect(Rect2(-bar_w / 2, -s * 0.6 - 10, bar_w * hp_ratio, 3), Color(draw_color, 0.8))
