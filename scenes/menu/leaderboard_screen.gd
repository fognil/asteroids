extends Control
## Local Leaderboard — top 10 scores in a popup overlay.

var entries: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_entries()

func _load_entries() -> void:
	entries = GameData.settings.get("leaderboard", [])

func add_entry(score_val: int, wave_val: int, ship: String) -> void:
	var dt := Time.get_datetime_dict_from_system(true)
	var date_str := str(dt["year"]) + "-" + str(dt["month"]).pad_zeros(2) + "-" + str(dt["day"]).pad_zeros(2)
	entries.append({
		"score": score_val,
		"wave": wave_val,
		"ship": ship,
		"date": date_str,
	})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	if entries.size() > 10:
		entries.resize(10)
	GameData.settings["leaderboard"] = entries
	SaveManager.save_game()

func show_popup() -> void:
	_load_entries()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func hide_popup() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return
	
	var vp := get_viewport_rect().size
	var sc := ScreenWrap.get_ui_scale()
	var panel := _get_panel_rect(vp, sc)
	
	# Close button (top-right of panel)
	var close_rect := Rect2(panel.position.x + panel.size.x - 50 * sc, panel.position.y + 10 * sc, 40 * sc, 40 * sc)
	if close_rect.has_point(pos):
		hide_popup()
		get_viewport().set_input_as_handled()
		return
	
	# Tap outside panel → close
	if not panel.has_point(pos):
		hide_popup()
		get_viewport().set_input_as_handled()
		return
	
	# Consume taps inside panel
	get_viewport().set_input_as_handled()

func _get_panel_rect(vp: Vector2, sc: float) -> Rect2:
	var pw := minf(800 * sc, vp.x * 0.85)
	var ph := minf(600 * sc, vp.y * 0.8)
	var px := (vp.x - pw) / 2
	var py := (vp.y - ph) / 2
	return Rect2(px, py, pw, ph)

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var sc := ScreenWrap.get_ui_scale()
	var font := ScreenWrap.neon_font
	
	# Dark overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.7))
	
	# Panel
	var panel := _get_panel_rect(vp, sc)
	draw_rect(panel, Color(0.03, 0.04, 0.08, 0.95))
	draw_rect(panel, Color(0, 1, 1, 0.3), false, 2.0 * sc)
	
	var px := panel.position.x
	var py := panel.position.y
	var pw := panel.size.x
	
	# Close button X (top-right)
	var cx := px + pw - 35 * sc
	var cy := py + 30 * sc
	var xs := 12.0 * sc
	draw_line(Vector2(cx - xs, cy - xs), Vector2(cx + xs, cy + xs), Color(1, 0.3, 0.3, 0.8), 3.0 * sc)
	draw_line(Vector2(cx + xs, cy - xs), Vector2(cx - xs, cy + xs), Color(1, 0.3, 0.3, 0.8), 3.0 * sc)
	
	# Title
	var title_fs := int(22 * sc)
	NeonIcons.draw_trophy(self, Vector2(px + 25 * sc, py + 35 * sc), 10.0 * sc, Color(1, 0.85, 0.2))
	draw_string(font, Vector2(px + 50 * sc, py + 42 * sc), "TOP 10 SCORES", HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, Color(1, 0.85, 0.2))
	
	# Separator
	draw_line(Vector2(px + 15 * sc, py + 58 * sc), Vector2(px + pw - 15 * sc, py + 58 * sc), Color(0, 1, 1, 0.15), 1.0)
	
	if entries.is_empty():
		var empty_fs := int(16 * sc)
		draw_string(font, Vector2(px + pw / 2 - 80 * sc, py + panel.size.y / 2), "No scores yet!", HORIZONTAL_ALIGNMENT_CENTER, -1, empty_fs, Color(0.5, 0.5, 0.5))
		return
	
	# Table header
	var header_y := py + 80 * sc
	var hfs := int(12 * sc)
	var col_rank := px + 20 * sc
	var col_score := px + 55 * sc
	var col_wave := px + pw * 0.4
	var col_ship := px + pw * 0.55
	var col_date := px + pw * 0.75
	draw_string(font, Vector2(col_rank, header_y), "#", HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(col_score, header_y), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(col_wave, header_y), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(col_ship, header_y), "SHIP", HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(col_date, header_y), "DATE", HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(0.4, 0.4, 0.4))
	
	# Entries
	var row_h := 38.0 * sc
	var fs := int(14 * sc)
	var fs_sm := int(12 * sc)
	for i in entries.size():
		var ey := header_y + 20 * sc + float(i) * row_h
		var entry: Dictionary = entries[i]
		var rank_color := Color(1, 0.85, 0.2) if i == 0 else (Color(0.7, 0.7, 0.8) if i == 1 else (Color(0.7, 0.5, 0.3) if i == 2 else Color(0.5, 0.5, 0.5)))
		var entry_score: int = entry["score"]
		var is_highlight: bool = (entry_score == GameData.high_score)
		
		if is_highlight:
			draw_rect(Rect2(px + 10 * sc, ey - 14 * sc, pw - 20 * sc, row_h - 4 * sc), Color(0, 0.3, 0.2, 0.2))
		
		draw_string(font, Vector2(col_rank, ey), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, rank_color)
		draw_string(font, Vector2(col_score, ey), _format_number(entry_score), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.8))
		
		var wave_val: int = entry["wave"]
		draw_string(font, Vector2(col_wave, ey), "W" + str(wave_val), HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0, 1, 1, 0.6))
		
		var ship_name: String = entry["ship"]
		draw_string(font, Vector2(col_ship, ey), ship_name.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0.6, 0.6, 0.6))
		
		var date_str: String = entry["date"]
		draw_string(font, Vector2(col_date, ey), date_str, HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * sc), Color(0.4, 0.4, 0.4))

func _format_number(n: int) -> String:
	if n >= 1000000:
		return str(n / 1000000) + "." + str((n / 100000) % 10) + "M"
	if n >= 1000:
		return str(n / 1000) + "," + str(n % 1000).pad_zeros(3)
	return str(n)
