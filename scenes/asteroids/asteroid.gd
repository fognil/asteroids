extends Area2D
## Asteroid — moves, wraps, splits. Now with damage cracks and explosion particles.

enum Size { HUGE, LARGE, MEDIUM, SMALL }

@export var asteroid_size: Size = Size.LARGE

var move_velocity: Vector2 = Vector2.ZERO
var spin_speed: float = 0.0
var hp: int = 2
var max_hp: int = 2
var points: int = 50
var coin_value: int = 2
var asteroid_radius: float = 45.0
var color: Color = Color(0.8, 0.8, 0.8)

# Random polygon vertices
var vertices: PackedFloat32Array = []
var vertex_count: int = 7

# Damage visual
var damage_flash_timer: float = 0.0
var crack_lines: Array[Dictionary] = []  # Generated when hit

# Explosion particles (spawned on destroy)
var explosion_particles: Array[Dictionary] = []
var is_exploding: bool = false
var explosion_timer: float = 0.0

const SIZE_CONFIG := {
	Size.HUGE: {
		"hp": 3, "points": 20, "coins": 3,
		"radius_min": 60.0, "radius_max": 80.0,
		"speed_min": 30.0, "speed_max": 60.0,
		"splits_into": Size.LARGE, "split_count": 2
	},
	Size.LARGE: {
		"hp": 2, "points": 50, "coins": 2,
		"radius_min": 40.0, "radius_max": 55.0,
		"speed_min": 40.0, "speed_max": 80.0,
		"splits_into": Size.MEDIUM, "split_count": 2
	},
	Size.MEDIUM: {
		"hp": 1, "points": 100, "coins": 1,
		"radius_min": 25.0, "radius_max": 35.0,
		"speed_min": 60.0, "speed_max": 120.0,
		"splits_into": Size.SMALL, "split_count": 2
	},
	Size.SMALL: {
		"hp": 1, "points": 150, "coins": 1,
		"radius_min": 12.0, "radius_max": 18.0,
		"speed_min": 80.0, "speed_max": 150.0,
		"splits_into": -1, "split_count": 0
	},
}

func _ready() -> void:
	add_to_group("asteroids")
	_setup_size()
	_generate_polygon()
	_setup_collision()

func _setup_size() -> void:
	var config: Dictionary = SIZE_CONFIG[asteroid_size]
	hp = config["hp"]
	max_hp = hp
	points = config["points"]
	coin_value = config["coins"]
	asteroid_radius = randf_range(config["radius_min"], config["radius_max"])
	spin_speed = randf_range(-2.0, 2.0)
	
	if move_velocity == Vector2.ZERO:
		var speed := randf_range(config["speed_min"], config["speed_max"])
		var angle := randf() * TAU
		move_velocity = Vector2.RIGHT.rotated(angle) * speed

func _generate_polygon() -> void:
	vertex_count = randi_range(5, 8)
	vertices = PackedFloat32Array()
	for i in vertex_count:
		vertices.append(randf_range(0.7, 1.3))

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = asteroid_radius * 0.8
	collision.shape = shape
	add_child.call_deferred(collision)

func _process(delta: float) -> void:
	position += move_velocity * delta
	rotation += spin_speed * delta
	position = ScreenWrap.wrap_position(position, asteroid_radius)
	
	# Damage flash countdown
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
	
	queue_redraw()

func take_damage(amount: int, bullet_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	damage_flash_timer = 0.15  # White flash
	
	# Generate crack lines on damage (if still alive)
	if hp > 0:
		_generate_cracks(bullet_dir)
		# Screen shake - small
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("shake_light"):
			cam.shake_light()
	
	if hp <= 0:
		_destroy(bullet_dir)

func _generate_cracks(bullet_dir: Vector2) -> void:
	var local_dir := bullet_dir.rotated(-rotation) if bullet_dir != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU)
	
	# Add 2-4 crack lines from impact point
	var impact := local_dir.normalized() * asteroid_radius * 0.5
	var crack_count := randi_range(2, 4)
	for i in crack_count:
		var angle := local_dir.angle() + randf_range(-PI / 3, PI / 3)
		var length := randf_range(asteroid_radius * 0.3, asteroid_radius * 0.7)
		crack_lines.append({
			"start": impact + Vector2(randf_range(-5, 5), randf_range(-5, 5)),
			"end": impact + Vector2.RIGHT.rotated(angle) * length,
			"thickness": randf_range(0.5, 1.5)
		})

func _destroy(bullet_dir: Vector2) -> void:
	GameData.add_score(points)
	GameData.add_combo()
	
	var size_name: String = str(Size.keys()[asteroid_size])
	EventBus.asteroid_destroyed.emit(global_position, size_name, "normal")
	
	# Screen shake based on size
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		match asteroid_size:
			Size.HUGE:
				cam.shake(8.0, 0.2)
				cam.slow_motion(0.4, 0.3) if cam.has_method("slow_motion") else null
			Size.LARGE:
				cam.shake(5.0, 0.15)
			Size.MEDIUM:
				cam.shake(3.0, 0.1)
			Size.SMALL:
				cam.shake(1.5, 0.08)
	
	# Spawn explosion particles (in Effects container)
	_spawn_explosion()
	
	# Split
	_split(bullet_dir)
	
	queue_free()

func _spawn_explosion() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects == null:
		return
	
	var explosion := preload("res://scenes/effects/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.setup(asteroid_size, color, asteroid_radius)
	effects.add_child(explosion)

func _split(bullet_dir: Vector2) -> void:
	var config: Dictionary = SIZE_CONFIG[asteroid_size]
	var next_size: int = config["splits_into"]
	var count: int = config["split_count"]
	
	if next_size < 0:
		return
	
	var asteroids_node := get_tree().get_first_node_in_group("asteroids_container")
	if asteroids_node == null:
		return
	
	var base_angle := bullet_dir.angle() if bullet_dir != Vector2.ZERO else randf() * TAU
	
	for i in count:
		var new_asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		new_asteroid.asteroid_size = next_size as Size
		
		var spread := deg_to_rad(randf_range(30, 60))
		var dir_angle: float
		if i == 0:
			dir_angle = base_angle + spread + PI
		else:
			dir_angle = base_angle - spread + PI
		
		var next_config: Dictionary = SIZE_CONFIG[next_size]
		var speed := randf_range(next_config["speed_min"], next_config["speed_max"])
		new_asteroid.move_velocity = Vector2.RIGHT.rotated(dir_angle) * speed
		new_asteroid.position = global_position + Vector2.RIGHT.rotated(dir_angle) * 10.0
		
		asteroids_node.add_child(new_asteroid)

# === Drawing ===
func _draw() -> void:
	if vertices.is_empty():
		return
	
	# Build polygon points
	var draw_points := PackedVector2Array()
	for i in vertex_count:
		var angle := (float(i) / vertex_count) * TAU
		var r := asteroid_radius * vertices[i]
		draw_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	draw_points.append(draw_points[0])
	
	# Determine colors
	var base_color := color
	var damage_ratio := 1.0 - (float(hp) / float(max_hp)) if max_hp > 0 else 0.0
	
	# Damage flash (white)
	if damage_flash_timer > 0:
		var flash := damage_flash_timer / 0.15
		base_color = base_color.lerp(Color.WHITE, flash * 0.8)
	
	# Shift color toward warm as damaged
	if damage_ratio > 0:
		base_color = base_color.lerp(Color(1.0, 0.6, 0.2), damage_ratio * 0.4)
	
	# Glow layer (wider when damaged = looking unstable)
	var glow_width := 5.0 + damage_ratio * 4.0
	var glow_color := Color(base_color, 0.15 + damage_ratio * 0.1)
	draw_polyline(draw_points, glow_color, glow_width, true)
	
	# Core layer
	var core_width := 1.5 + damage_ratio * 0.5
	draw_polyline(draw_points, base_color, core_width, true)
	
	# === Crack lines (damage indicator) ===
	for crack in crack_lines:
		var crack_color := Color(1.0, 0.5, 0.2, 0.6 + damage_ratio * 0.3)
		draw_line(crack["start"], crack["end"], crack_color, crack["thickness"], true)
		# Glow on cracks
		draw_line(crack["start"], crack["end"], Color(1.0, 0.3, 0.0, 0.15), crack["thickness"] + 3.0, true)
	
	# Inner stress lines when heavily damaged
	if damage_ratio > 0.3:
		var stress_alpha := (damage_ratio - 0.3) * 0.5
		for i in range(0, vertex_count - 1, 2):
			var p1 := draw_points[i] * 0.3
			var p2 := draw_points[i + 1] * 0.3
			draw_line(p1, p2, Color(1, 0.4, 0.1, stress_alpha), 0.5, true)
