extends Control
## Local Leaderboard — top 10 scores saved.

var entries: Array = []

func _ready() -> void:
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

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		pass  # No interactive elements
	elif event is InputEventMouseButton and event.pressed:
		pass

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	
	# Header
	draw_string(font, Vector2(40, 85), "🏆 TOP 10 SCORES", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0.2))
	
	if entries.is_empty():
		draw_string(font, Vector2(vp.x / 2 - 60, vp.y / 2), "No scores yet!", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5))
		return
	
	# Table header
	var y: float = 110.0
	var x: float = 40.0
	draw_string(font, Vector2(x, y), "#", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(x + 30, y), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(x + 150, y), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(x + 220, y), "SHIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.4))
	draw_string(font, Vector2(x + 330, y), "DATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.4))
	
	y += 5
	draw_line(Vector2(x, y), Vector2(vp.x - 40, y), Color(0.2, 0.2, 0.2, 0.3), 1.0)
	
	# Entries
	for i in entries.size():
		y = 130 + float(i) * 35
		var entry: Dictionary = entries[i]
		var rank_color := Color(1, 0.85, 0.2) if i == 0 else (Color(0.7, 0.7, 0.8) if i == 1 else (Color(0.7, 0.5, 0.3) if i == 2 else Color(0.5, 0.5, 0.5)))
		var entry_score: int = entry["score"]
		var is_highlight: bool = (entry_score == GameData.high_score)
		
		# Background for highlight
		if is_highlight:
			draw_rect(Rect2(x - 5, y - 15, vp.x - 70, 30), Color(0, 0.2, 0.15, 0.2))
		
		draw_string(font, Vector2(x, y), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, rank_color)
		
		var score_str: String = _format_number(entry["score"])
		draw_string(font, Vector2(x + 30, y), score_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.8))
		
		var wave_val: int = entry["wave"]
		draw_string(font, Vector2(x + 150, y), "W" + str(wave_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 1, 0.6))
		
		var ship_name: String = entry["ship"]
		var ship_display := ship_name.capitalize()
		draw_string(font, Vector2(x + 220, y), ship_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
		
		var date_str: String = entry["date"]
		draw_string(font, Vector2(x + 330, y), date_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.4, 0.4))

func _format_number(n: int) -> String:
	if n >= 1000000:
		return str(n / 1000000) + "." + str((n / 100000) % 10) + "M"
	if n >= 1000:
		return str(n / 1000) + "," + str(n % 1000).pad_zeros(3)
	return str(n)
