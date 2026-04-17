class_name NeonIcons
## Procedural neon wireframe icons — consistent with game's visual style.
## All draw functions take (canvas: CanvasItem, pos: Vector2, size: float, color: Color)

# === Currency Icons ===

static func draw_coin(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(1, 0.85, 0.2)) -> void:
	## Hexagonal coin shape
	var pts := PackedVector2Array()
	for i in 6:
		var angle := float(i) / 6.0 * TAU - PI / 6
		pts.append(pos + Vector2(cos(angle) * size, sin(angle) * size))
	pts.append(pts[0])
	canvas.draw_polyline(pts, Color(color, 0.3), size * 0.6, true)
	canvas.draw_polyline(pts, color, 1.0, true)
	canvas.draw_circle(pos, size * 0.3, Color(color, 0.5))

static func draw_gem(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0.4, 0.8, 1)) -> void:
	## Diamond/gem shape
	var s := size
	var pts := PackedVector2Array([
		pos + Vector2(0, -s),
		pos + Vector2(-s * 0.7, -s * 0.2),
		pos + Vector2(-s * 0.4, s),
		pos + Vector2(s * 0.4, s),
		pos + Vector2(s * 0.7, -s * 0.2),
		pos + Vector2(0, -s),
	])
	canvas.draw_polyline(pts, Color(color, 0.3), size * 0.5, true)
	canvas.draw_polyline(pts, color, 1.0, true)
	# Inner facet line
	canvas.draw_line(pos + Vector2(-s * 0.7, -s * 0.2), pos + Vector2(s * 0.7, -s * 0.2), Color(color, 0.4), 0.5)

# === Navigation Icons ===

static func draw_trophy(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(1, 0.85, 0.2)) -> void:
	## Trophy/cup shape
	var s := size
	# Cup body
	var cup := PackedVector2Array([
		pos + Vector2(-s * 0.6, -s * 0.7),
		pos + Vector2(-s * 0.7, -s * 0.3),
		pos + Vector2(-s * 0.4, s * 0.3),
		pos + Vector2(-s * 0.15, s * 0.5),
		pos + Vector2(s * 0.15, s * 0.5),
		pos + Vector2(s * 0.4, s * 0.3),
		pos + Vector2(s * 0.7, -s * 0.3),
		pos + Vector2(s * 0.6, -s * 0.7),
		pos + Vector2(-s * 0.6, -s * 0.7),
	])
	canvas.draw_polyline(cup, Color(color, 0.3), size * 0.4, true)
	canvas.draw_polyline(cup, color, 1.0, true)
	# Base
	canvas.draw_line(pos + Vector2(-s * 0.3, s * 0.7), pos + Vector2(s * 0.3, s * 0.7), color, 1.0)
	canvas.draw_line(pos + Vector2(0, s * 0.5), pos + Vector2(0, s * 0.7), Color(color, 0.6), 1.0)

static func draw_medal(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0.6, 0.3, 1)) -> void:
	## Medal/badge shape
	var s := size
	# Ribbon V
	canvas.draw_line(pos + Vector2(-s * 0.3, -s * 0.8), pos + Vector2(0, -s * 0.2), Color(color, 0.5), 1.5)
	canvas.draw_line(pos + Vector2(s * 0.3, -s * 0.8), pos + Vector2(0, -s * 0.2), Color(color, 0.5), 1.5)
	# Circle medal
	canvas.draw_arc(pos + Vector2(0, s * 0.2), s * 0.5, 0, TAU, 12, color, 1.0, true)
	canvas.draw_arc(pos + Vector2(0, s * 0.2), s * 0.5, 0, TAU, 12, Color(color, 0.15), s * 0.4, true)
	# Star inside
	draw_star(canvas, pos + Vector2(0, s * 0.2), s * 0.25, Color(color, 0.7))

static func draw_star(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(1, 0.85, 0)) -> void:
	## 5-pointed star
	var pts := PackedVector2Array()
	for i in 5:
		var outer_angle := float(i) * TAU / 5.0 - PI / 2
		var inner_angle := outer_angle + TAU / 10.0
		pts.append(pos + Vector2(cos(outer_angle) * size, sin(outer_angle) * size))
		pts.append(pos + Vector2(cos(inner_angle) * size * 0.4, sin(inner_angle) * size * 0.4))
	pts.append(pts[0])
	canvas.draw_polyline(pts, color, 1.0, true)

static func draw_gear(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0.6, 0.6, 0.6)) -> void:
	## Gear/settings icon
	var s := size
	var teeth := 6
	var pts := PackedVector2Array()
	for i in teeth:
		var angle := float(i) / float(teeth) * TAU
		var next_angle := float(i + 0.5) / float(teeth) * TAU
		# Outer tooth
		pts.append(pos + Vector2(cos(angle - 0.15) * s, sin(angle - 0.15) * s))
		pts.append(pos + Vector2(cos(angle + 0.15) * s, sin(angle + 0.15) * s))
		# Inner gap
		pts.append(pos + Vector2(cos(next_angle - 0.15) * s * 0.65, sin(next_angle - 0.15) * s * 0.65))
		pts.append(pos + Vector2(cos(next_angle + 0.15) * s * 0.65, sin(next_angle + 0.15) * s * 0.65))
	pts.append(pts[0])
	canvas.draw_polyline(pts, color, 1.0, true)
	canvas.draw_arc(pos, s * 0.3, 0, TAU, 8, color, 1.0, true)

static func draw_play(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0, 1, 1)) -> void:
	## Play triangle
	var s := size
	var pts := PackedVector2Array([
		pos + Vector2(-s * 0.4, -s * 0.6),
		pos + Vector2(s * 0.6, 0),
		pos + Vector2(-s * 0.4, s * 0.6),
		pos + Vector2(-s * 0.4, -s * 0.6),
	])
	canvas.draw_polyline(pts, Color(color, 0.3), size * 0.4, true)
	canvas.draw_polyline(pts, color, 1.5, true)

static func draw_ship_icon(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0, 1, 1)) -> void:
	## Small ship silhouette
	var s := size
	var pts := PackedVector2Array([
		pos + Vector2(0, -s),
		pos + Vector2(-s * 0.5, s * 0.6),
		pos + Vector2(-s * 0.15, s * 0.35),
		pos + Vector2(s * 0.15, s * 0.35),
		pos + Vector2(s * 0.5, s * 0.6),
		pos + Vector2(0, -s),
	])
	canvas.draw_polyline(pts, Color(color, 0.3), size * 0.3, true)
	canvas.draw_polyline(pts, color, 1.0, true)

static func draw_upgrade_arrow(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0, 1, 1)) -> void:
	## Up arrow icon
	var s := size
	# Arrow head
	canvas.draw_line(pos + Vector2(0, -s), pos + Vector2(-s * 0.5, -s * 0.2), color, 1.5)
	canvas.draw_line(pos + Vector2(0, -s), pos + Vector2(s * 0.5, -s * 0.2), color, 1.5)
	# Arrow shaft
	canvas.draw_line(pos + Vector2(0, -s * 0.8), pos + Vector2(0, s * 0.6), color, 1.5)
	# Glow
	canvas.draw_line(pos + Vector2(0, -s), pos + Vector2(-s * 0.5, -s * 0.2), Color(color, 0.2), 4.0)
	canvas.draw_line(pos + Vector2(0, -s), pos + Vector2(s * 0.5, -s * 0.2), Color(color, 0.2), 4.0)

static func draw_ticket(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0.6, 0.3, 1)) -> void:
	## Ticket/pass shape
	var s := size
	var pts := PackedVector2Array([
		pos + Vector2(-s * 0.7, -s * 0.4),
		pos + Vector2(s * 0.7, -s * 0.4),
		pos + Vector2(s * 0.7, s * 0.4),
		pos + Vector2(-s * 0.7, s * 0.4),
		pos + Vector2(-s * 0.7, -s * 0.4),
	])
	canvas.draw_polyline(pts, color, 1.0, true)
	# Perforation
	canvas.draw_line(pos + Vector2(s * 0.2, -s * 0.4), pos + Vector2(s * 0.2, s * 0.4), Color(color, 0.3), 0.5)
	# Star on left side
	draw_star(canvas, pos + Vector2(-s * 0.2, 0), s * 0.2, Color(color, 0.6))

static func draw_crosshair(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(1, 0.8, 0)) -> void:
	## Target/mission crosshair
	var s := size
	canvas.draw_arc(pos, s * 0.6, 0, TAU, 12, color, 1.0, true)
	canvas.draw_arc(pos, s * 0.3, 0, TAU, 8, Color(color, 0.5), 0.5, true)
	# Crosshairs
	canvas.draw_line(pos + Vector2(0, -s), pos + Vector2(0, -s * 0.4), color, 1.0)
	canvas.draw_line(pos + Vector2(0, s), pos + Vector2(0, s * 0.4), color, 1.0)
	canvas.draw_line(pos + Vector2(-s, 0), pos + Vector2(-s * 0.4, 0), color, 1.0)
	canvas.draw_line(pos + Vector2(s, 0), pos + Vector2(s * 0.4, 0), color, 1.0)

static func draw_cart(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0, 1, 0.5)) -> void:
	## Shopping cart
	var s := size
	# Cart body
	var body := PackedVector2Array([
		pos + Vector2(-s * 0.6, -s * 0.3),
		pos + Vector2(-s * 0.4, s * 0.3),
		pos + Vector2(s * 0.4, s * 0.3),
		pos + Vector2(s * 0.6, -s * 0.5),
	])
	canvas.draw_polyline(body, color, 1.0)
	# Handle
	canvas.draw_line(pos + Vector2(-s * 0.6, -s * 0.3), pos + Vector2(-s * 0.8, -s * 0.5), color, 1.0)
	# Wheels
	canvas.draw_arc(pos + Vector2(-s * 0.25, s * 0.5), s * 0.12, 0, TAU, 6, color, 1.0, true)
	canvas.draw_arc(pos + Vector2(s * 0.25, s * 0.5), s * 0.12, 0, TAU, 6, color, 1.0, true)

static func draw_lock(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0.5, 0.5, 0.5)) -> void:
	## Lock icon
	var s := size
	# Body
	var body := PackedVector2Array([
		pos + Vector2(-s * 0.35, 0),
		pos + Vector2(s * 0.35, 0),
		pos + Vector2(s * 0.35, s * 0.6),
		pos + Vector2(-s * 0.35, s * 0.6),
		pos + Vector2(-s * 0.35, 0),
	])
	canvas.draw_polyline(body, color, 1.0, true)
	# Shackle
	canvas.draw_arc(pos + Vector2(0, 0), s * 0.3, PI, TAU, 8, color, 1.0, true)

static func draw_checkmark(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0, 1, 0.5)) -> void:
	## Checkmark icon
	var s := size
	canvas.draw_line(pos + Vector2(-s * 0.4, 0), pos + Vector2(-s * 0.1, s * 0.4), color, 2.0)
	canvas.draw_line(pos + Vector2(-s * 0.1, s * 0.4), pos + Vector2(s * 0.5, -s * 0.4), color, 2.0)

static func draw_pause(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0.8, 0.8, 0.8)) -> void:
	## Pause bars
	var s := size
	canvas.draw_rect(Rect2(pos.x - s * 0.35, pos.y - s * 0.5, s * 0.25, s), color)
	canvas.draw_rect(Rect2(pos.x + s * 0.1, pos.y - s * 0.5, s * 0.25, s), color)

static func draw_tv(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(0, 1, 0.5)) -> void:
	## TV/ad icon (for rewarded ads)
	var s := size
	# Screen
	var screen := PackedVector2Array([
		pos + Vector2(-s * 0.6, -s * 0.4),
		pos + Vector2(s * 0.6, -s * 0.4),
		pos + Vector2(s * 0.6, s * 0.3),
		pos + Vector2(-s * 0.6, s * 0.3),
		pos + Vector2(-s * 0.6, -s * 0.4),
	])
	canvas.draw_polyline(screen, color, 1.0, true)
	# Stand
	canvas.draw_line(pos + Vector2(-s * 0.2, s * 0.3), pos + Vector2(-s * 0.3, s * 0.6), color, 1.0)
	canvas.draw_line(pos + Vector2(s * 0.2, s * 0.3), pos + Vector2(s * 0.3, s * 0.6), color, 1.0)
	# Play triangle inside
	draw_play(canvas, pos + Vector2(0, -s * 0.05), s * 0.25, Color(color, 0.6))

static func draw_heart(canvas: CanvasItem, pos: Vector2, size: float, color: Color = Color(1, 0.3, 0.3), filled: bool = true) -> void:
	## Heart shape
	var s := size
	var pts := PackedVector2Array([
		pos + Vector2(0, s * 0.6),
		pos + Vector2(-s * 0.7, -s * 0.1),
		pos + Vector2(-s * 0.4, -s * 0.6),
		pos + Vector2(0, -s * 0.2),
		pos + Vector2(s * 0.4, -s * 0.6),
		pos + Vector2(s * 0.7, -s * 0.1),
		pos + Vector2(0, s * 0.6),
	])
	if filled:
		canvas.draw_polyline(pts, color, 1.5, true)
	else:
		canvas.draw_polyline(pts, Color(color, 0.3), 1.0, true)
