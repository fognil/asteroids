extends Node2D
## Background starfield — dynamic parallax stars + nebula colors for gameplay.

var stars: Array[Dictionary] = []
var nebula_color_1: Color = Color(0.1, 0, 0.2, 0.15)
var nebula_color_2: Color = Color(0, 0.05, 0.15, 0.1)

func _ready() -> void:
	add_to_group("background")
	z_index = -100
	_generate_stars()

func _generate_stars() -> void:
	for i in 150:
		stars.append({
			"pos": Vector2(randf() * 1920, randf() * 1080),
			"size": randf_range(0.3, 2.0),
			"brightness": randf_range(0.05, 0.35),
			"speed": randf_range(0.3, 3.0),
			"offset": randf() * TAU,
			"parallax": randf_range(0.02, 0.15),  # Slow drift
			"hue": randf_range(0.5, 0.7),  # Blue-cyan shift
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var vp := Vector2(1920, 1080)
	var time := Time.get_ticks_msec() / 1000.0
	
	# Background gradient
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.01, 0.01, 0.03))
	
	# Subtle nebula blobs
	for i in 3:
		var nx := sin(time * 0.05 + float(i) * 2.0) * 200 + vp.x * (0.3 + float(i) * 0.2)
		var ny := cos(time * 0.03 + float(i) * 1.5) * 150 + vp.y * 0.5
		var nr := 250.0 + sin(time * 0.1 + float(i)) * 50.0
		var ncol := nebula_color_1 if i % 2 == 0 else nebula_color_2
		draw_circle(Vector2(nx, ny), nr, ncol)
	
	# Stars
	for star in stars:
		var spos: Vector2 = star["pos"]
		var s_parallax: float = star["parallax"]
		var s_speed: float = star["speed"]
		var s_offset: float = star["offset"]
		var s_brightness: float = star["brightness"]
		var s_hue: float = star["hue"]
		var s_size: float = star["size"]
		
		# Parallax drift
		var drift_x: float = sin(time * s_parallax) * 15.0
		var drift_y: float = cos(time * s_parallax * 0.7) * 10.0
		spos += Vector2(drift_x, drift_y)
		
		# Twinkle
		var twinkle: float = 0.3 + 0.7 * abs(sin(time * s_speed + s_offset))
		var alpha: float = s_brightness * twinkle
		var star_color := Color.from_hsv(s_hue, 0.15, 1.0, alpha)
		
		draw_circle(spos, s_size, star_color)
		
		# Bright stars get a cross glint
		if s_size > 1.5 and alpha > 0.2:
			var glint: float = alpha * 0.3
			draw_line(spos + Vector2(-3, 0), spos + Vector2(3, 0), Color(1, 1, 1, glint), 0.5)
			draw_line(spos + Vector2(0, -3), spos + Vector2(0, 3), Color(1, 1, 1, glint), 0.5)
