extends Control
## Daily Reward popup — 7-day cycle with streak tracking.

const REWARDS := [
	{"day": 1, "coins": 100, "gems": 0},
	{"day": 2, "coins": 150, "gems": 0},
	{"day": 3, "coins": 200, "gems": 0},
	{"day": 4, "coins": 300, "gems": 0},
	{"day": 5, "coins": 0, "gems": 5},
	{"day": 6, "coins": 500, "gems": 0},
	{"day": 7, "coins": 0, "gems": 15},
]

var is_showing: bool = false
var collected: bool = false
var day_index: int = 0
var streak: int = 0

func _ready() -> void:
	visible = false
	_check_daily()

func _check_daily() -> void:
	var today := _get_today_str()
	var last: String = GameData.settings.get("last_daily_claim", "")
	streak = GameData.settings.get("daily_streak", 0)
	day_index = GameData.settings.get("daily_day_index", 0)
	
	if last == today:
		collected = true
		return
	
	# Check if streak broken (yesterday vs last claim)
	var yesterday := _get_yesterday_str()
	if last != "" and last != yesterday:
		streak = 0
		day_index = 0
	
	collected = false

func can_claim() -> bool:
	return not collected

func show_popup() -> void:
	is_showing = true
	visible = true
	queue_redraw()

func hide_popup() -> void:
	is_showing = false
	visible = false

func claim() -> void:
	if collected:
		return
	
	var reward: Dictionary = REWARDS[day_index % REWARDS.size()]
	var coin_reward: int = reward["coins"]
	var gem_reward: int = reward["gems"]
	
	GameData.total_coins += coin_reward
	GameData.gems += gem_reward
	
	streak += 1
	day_index = (day_index + 1) % REWARDS.size()
	collected = true
	
	GameData.settings["last_daily_claim"] = _get_today_str()
	GameData.settings["daily_streak"] = streak
	GameData.settings["daily_day_index"] = day_index
	SaveManager.save_game()
	
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_showing:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var panel_w: float = 350.0
	var panel_h: float = 380.0
	var panel_x := (vp.x - panel_w) / 2
	var panel_y := (vp.y - panel_h) / 2
	
	# Collect button
	var btn_y := panel_y + panel_h - 60
	var btn_rect := Rect2(panel_x + 50, btn_y, panel_w - 100, 40)
	if btn_rect.has_point(pos) and not collected:
		claim()
		return
	
	# Close (outside panel or after collected)
	if not Rect2(panel_x, panel_y, panel_w, panel_h).has_point(pos) or collected:
		hide_popup()

func _process(_delta: float) -> void:
	if is_showing:
		queue_redraw()

func _draw() -> void:
	if not is_showing:
		return
	
	var vp := get_viewport_rect().size
	var font := ScreenWrap.neon_font
	
	# Dim
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.7))
	
	var panel_w: float = 350.0
	var panel_h: float = 380.0
	var px := (vp.x - panel_w) / 2
	var py := (vp.y - panel_h) / 2
	
	# Panel
	draw_rect(Rect2(px, py, panel_w, panel_h), Color(0.05, 0.05, 0.12, 0.95))
	var border := PackedVector2Array([
		Vector2(px, py), Vector2(px + panel_w, py),
		Vector2(px + panel_w, py + panel_h), Vector2(px, py + panel_h), Vector2(px, py)
	])
	draw_polyline(border, Color(1, 0.85, 0.2, 0.4), 1.5)
	
	# Title
	var title := "DAILY REWARD"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	NeonIcons.draw_star(self, Vector2((vp.x - ts.x) / 2 - 16, py + 22), 8.0, Color(1, 0.85, 0.2))
	draw_string(font, Vector2((vp.x - ts.x) / 2, py + 30), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 0.85, 0.2))
	
	# Streak
	draw_string(font, Vector2(px + 20, py + 55), "Streak: " + str(streak) + " days", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.5, 0.2))
	
	# Day cards
	var current_day := day_index % REWARDS.size()
	for i in REWARDS.size():
		var reward: Dictionary = REWARDS[i]
		var row := i / 4
		var col := i % 4
		var cx := px + 20 + col * 80
		var cy := py + 75 + row * 85
		var cw: float = 70.0
		var ch: float = 75.0
		
		var is_today := (i == current_day and not collected)
		var is_claimed := (i < current_day) or (i == current_day and collected)
		
		# Card bg
		var bg_color := Color(0.15, 0.15, 0.2, 0.6)
		if is_today:
			bg_color = Color(0.2, 0.15, 0, 0.6)
		elif is_claimed:
			bg_color = Color(0, 0.15, 0.1, 0.4)
		draw_rect(Rect2(cx, cy, cw, ch), bg_color)
		
		# Border
		var bc := Color(0.3, 0.3, 0.3, 0.3)
		if is_today:
			bc = Color(1, 0.85, 0.2, 0.7)
		draw_rect(Rect2(cx, cy, cw, ch), bc, false, 1.0)
		
		# Day label
		draw_string(font, Vector2(cx + 5, cy + 15), "Day " + str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6))
		
		# Reward
		var coin_val: int = reward["coins"]
		var gem_val: int = reward["gems"]
		if coin_val > 0:
			NeonIcons.draw_coin(self, Vector2(cx + 12, cy + 33), 5.0)
			draw_string(font, Vector2(cx + 22, cy + 40), str(coin_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.8))
		else:
			NeonIcons.draw_gem(self, Vector2(cx + 12, cy + 33), 5.0)
			draw_string(font, Vector2(cx + 22, cy + 40), str(gem_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.8))
		
		# Status
		if is_claimed:
			NeonIcons.draw_checkmark(self, Vector2(cx + 35, cy + 55), 7.0, Color(0, 1, 0.5))
		elif is_today:
			draw_string(font, Vector2(cx + 5, cy + 60), "◀ TODAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.85, 0.2))
	
	# Collect button
	var btn_y := py + panel_h - 60
	var btn_w := panel_w - 100
	var btn_x := px + 50
	if not collected:
		draw_rect(Rect2(btn_x, btn_y, btn_w, 40), Color(0.1, 0.3, 0.1, 0.7))
		draw_rect(Rect2(btn_x, btn_y, btn_w, 40), Color(0, 1, 0.5, 0.5), false, 1.5)
		var btn_text := "COLLECT"
		var bts := font.get_string_size(btn_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
		draw_string(font, Vector2(btn_x + (btn_w - bts.x) / 2, btn_y + 28), btn_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0, 1, 0.5))
	else:
		var done_text := "Collected! Tap to close"
		var dts := font.get_string_size(done_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, Vector2(btn_x + (btn_w - dts.x) / 2, btn_y + 25), done_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5))

func _get_today_str() -> String:
	var dt := Time.get_datetime_dict_from_system(true)
	return str(dt["year"]) + "-" + str(dt["month"]).pad_zeros(2) + "-" + str(dt["day"]).pad_zeros(2)

func _get_yesterday_str() -> String:
	var unix := Time.get_unix_time_from_system() - 86400
	var dt := Time.get_datetime_dict_from_unix_time(int(unix))
	return str(dt["year"]) + "-" + str(dt["month"]).pad_zeros(2) + "-" + str(dt["day"]).pad_zeros(2)
