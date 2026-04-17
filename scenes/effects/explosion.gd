extends Node2D
## Explosion effect — procedural particles that expand, fade, and die.

var particles: Array[Dictionary] = []
var shockwave_radius: float = 0.0
var shockwave_max: float = 100.0
var shockwave_speed: float = 400.0
var shockwave_alpha: float = 1.0
var lifetime: float = 0.0
var max_lifetime: float = 1.0
var base_color: Color = Color(0.8, 0.8, 0.8)
var debris_lines: Array[Dictionary] = []

func setup(asteroid_size: int, color: Color, radius: float) -> void:
	base_color = color
	
	# Particle count based on size
	var count := 8
	match asteroid_size:
		0:  # HUGE
			count = 40
			shockwave_max = 150.0
			max_lifetime = 1.5
		1:  # LARGE
			count = 28
			shockwave_max = 100.0
			max_lifetime = 1.2
		2:  # MEDIUM
			count = 18
			shockwave_max = 70.0
			max_lifetime = 0.8
		3:  # SMALL
			count = 10
			shockwave_max = 40.0
			max_lifetime = 0.5
	
	# Generate particles — fragments, sparks, glow dots
	for i in count:
		var angle := randf() * TAU
		var speed := randf_range(50, 300)
		var type := randi() % 3  # 0=fragment, 1=spark, 2=glow
		
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.RIGHT.rotated(angle) * speed,
			"size": randf_range(1.0, 4.0 if type != 0 else 8.0),
			"life": randf_range(max_lifetime * 0.5, max_lifetime),
			"max_life": max_lifetime,
			"type": type,
			"angle": randf() * TAU,
			"spin": randf_range(-5, 5),
			"color_shift": randf()
		})
	
	# Generate debris lines (small wireframe fragments)
	var debris_count := count / 4
	for i in debris_count:
		var angle := randf() * TAU
		var speed := randf_range(30, 200)
		var frag_size := randf_range(3.0, radius * 0.3)
		debris_lines.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.RIGHT.rotated(angle) * speed,
			"size": frag_size,
			"life": randf_range(max_lifetime * 0.6, max_lifetime),
			"angle": randf() * TAU,
			"spin": randf_range(-8, 8),
			"vertices": randi_range(3, 5)
		})

func _process(delta: float) -> void:
	lifetime += delta
	
	# Update shockwave
	shockwave_radius += shockwave_speed * delta
	shockwave_alpha = maxf(0, 1.0 - shockwave_radius / shockwave_max)
	
	# Update particles
	var alive := false
	for p in particles:
		p["life"] -= delta
		if p["life"] > 0:
			alive = true
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.97  # Slow down
			p["angle"] += p["spin"] * delta
	
	# Update debris
	for d in debris_lines:
		d["life"] -= delta
		if d["life"] > 0:
			alive = true
			d["pos"] += d["vel"] * delta
			d["vel"] *= 0.96
			d["angle"] += d["spin"] * delta
	
	if not alive and shockwave_alpha <= 0:
		queue_free()
		return
	
	queue_redraw()

func _draw() -> void:
	# === Shockwave ring ===
	if shockwave_alpha > 0.05:
		var ring_color := Color(base_color, shockwave_alpha * 0.5)
		var ring_glow := Color(base_color, shockwave_alpha * 0.15)
		draw_arc(Vector2.ZERO, shockwave_radius, 0, TAU, 32, ring_color, 2.0, true)
		draw_arc(Vector2.ZERO, shockwave_radius, 0, TAU, 32, ring_glow, 6.0, true)
		# Inner bright flash (only early)
		if shockwave_radius < shockwave_max * 0.3:
			var flash_alpha := (1.0 - shockwave_radius / (shockwave_max * 0.3)) * 0.3
			draw_circle(Vector2.ZERO, shockwave_radius * 0.5, Color(1, 1, 1, flash_alpha))
	
	# === Particles ===
	for p in particles:
		if p["life"] <= 0:
			continue
		var life_ratio: float = p["life"] / p["max_life"]
		var alpha := life_ratio
		var type: int = p["type"]
		var pos: Vector2 = p["pos"]
		var size: float = p["size"] * life_ratio
		
		match type:
			0:  # Fragment — small polygon
				var frag_color := Color(base_color, alpha * 0.8)
				var points := PackedVector2Array()
				for v in 3:
					var a: float = float(p["angle"]) + float(v) / 3.0 * TAU
					points.append(pos + Vector2(cos(a) * size, sin(a) * size))
				points.append(points[0])
				draw_polyline(points, frag_color, 1.0, true)
			
			1:  # Spark — bright point
				var spark_color := Color(1.0, 0.8, 0.3, alpha)
				draw_circle(pos, size * 0.5, spark_color)
				# Streak
				var p_vel: Vector2 = p["vel"]
				var streak_len: float = p_vel.length() * 0.03
				if streak_len > 1:
					var streak_dir: Vector2 = p_vel.normalized()
					draw_line(pos, pos - streak_dir * streak_len, Color(1, 0.6, 0.1, alpha * 0.5), 1.0)
			
			2:  # Glow dot
				var glow_color: Color
				if p["color_shift"] < 0.5:
					glow_color = Color(base_color, alpha * 0.6)
				else:
					glow_color = Color(1.0, 0.5, 0.2, alpha * 0.4)
				draw_circle(pos, size, glow_color)
				draw_circle(pos, size * 2.0, Color(glow_color, alpha * 0.1))
	
	# === Debris lines (wireframe fragments) ===
	for d in debris_lines:
		if d["life"] <= 0:
			continue
		var life_ratio: float = d["life"] / max_lifetime
		var debris_color := Color(base_color, life_ratio * 0.7)
		var pos: Vector2 = d["pos"]
		var size: float = d["size"]
		var verts: int = d["vertices"]
		
		var points := PackedVector2Array()
		for v in verts:
			var a: float = d["angle"] + float(v) / float(verts) * TAU
			points.append(pos + Vector2(cos(a) * size, sin(a) * size))
		points.append(points[0])
		draw_polyline(points, debris_color, 1.0, true)
