extends Node2D
## Star background with animated nebula clouds — creates depth and atmosphere.

var stars: Array[Dictionary] = []
var nebula_clouds: Array[Dictionary] = []
const STAR_COUNT := 200
const NEBULA_COUNT := 8

func _ready() -> void:
	_generate_stars()
	_generate_nebula()

func _generate_stars() -> void:
	var vp := Vector2(1920, 1080)
	for i in STAR_COUNT:
		stars.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"size": randf_range(0.3, 2.0),
			"brightness": randf_range(0.08, 0.4),
			"twinkle_speed": randf_range(0.5, 3.0),
			"twinkle_offset": randf() * TAU,
			"color_shift": randf()  # 0=white, 0.5=blue, 1.0=warm
		})

func _generate_nebula() -> void:
	var vp := Vector2(1920, 1080)
	# Predefined nebula color palette — deep space feel
	var nebula_colors := [
		Color(0.1, 0.02, 0.2, 0.04),   # Deep purple
		Color(0.02, 0.05, 0.15, 0.03),  # Deep blue
		Color(0.15, 0.02, 0.05, 0.03),  # Deep red
		Color(0.0, 0.08, 0.12, 0.04),   # Teal
		Color(0.05, 0.0, 0.15, 0.03),   # Violet
	]
	
	for i in NEBULA_COUNT:
		nebula_clouds.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"radius": randf_range(150, 400),
			"color": nebula_colors[i % nebula_colors.size()],
			"drift_speed": Vector2(randf_range(-3, 3), randf_range(-2, 2)),
			"pulse_speed": randf_range(0.2, 0.8),
			"pulse_offset": randf() * TAU,
			"layers": randi_range(3, 6)  # Multi-layer for depth
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var time := Time.get_ticks_msec() / 1000.0
	
	# === Draw Nebula Clouds (behind stars) ===
	for cloud in nebula_clouds:
		var pulse := 0.7 + 0.3 * sin(time * cloud["pulse_speed"] + cloud["pulse_offset"])
		var base_pos: Vector2 = cloud["pos"]
		# Gentle drift
		base_pos += cloud["drift_speed"] * time
		# Wrap
		base_pos.x = fmod(base_pos.x + 1920.0, 1920.0)
		base_pos.y = fmod(base_pos.y + 1080.0, 1080.0)
		
		var base_color: Color = cloud["color"]
		var base_radius: float = cloud["radius"]
		var layers: int = cloud["layers"]
		
		# Draw multiple concentric circles with decreasing opacity for soft glow
		for layer in layers:
			var t := float(layer) / float(layers)
			var r: float = base_radius * (1.0 - t * 0.6) * pulse
			var alpha: float = base_color.a * (1.0 - t * 0.7)
			var c := Color(base_color.r, base_color.g, base_color.b, alpha)
			draw_circle(base_pos, r, c)
	
	# === Draw Stars ===
	for star in stars:
		var twinkle := 0.4 + 0.6 * sin(time * star["twinkle_speed"] + star["twinkle_offset"])
		var alpha: float = star["brightness"] * twinkle
		
		# Slight color variation
		var shift: float = star["color_shift"]
		var r := 1.0
		var g := 1.0
		var b := 1.0
		if shift < 0.3:
			# Cool blue-white
			r = 0.8
			b = 1.0
		elif shift > 0.7:
			# Warm yellow-white
			r = 1.0
			g = 0.9
			b = 0.7
		
		var color := Color(r, g, b, alpha)
		var size: float = star["size"]
		draw_circle(star["pos"], size, color)
		
		# Bright stars get a subtle cross/spike
		if star["brightness"] > 0.3 and twinkle > 0.7:
			var spike_len: float = size * 3.0
			var spike_color := Color(r, g, b, alpha * 0.3)
			draw_line(star["pos"] - Vector2(spike_len, 0), star["pos"] + Vector2(spike_len, 0), spike_color, 0.5)
			draw_line(star["pos"] - Vector2(0, spike_len), star["pos"] + Vector2(0, spike_len), spike_color, 0.5)
