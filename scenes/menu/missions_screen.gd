extends Control
## Missions screen — Daily (3) + Weekly (3) missions with progress tracking.

const DAILY_POOL := [
	{"id": "destroy_50", "desc": "Destroy 50 asteroids", "target": 50, "key": "total_asteroids_destroyed", "coins": 100},
	{"id": "wave_5", "desc": "Reach Wave 5", "target": 5, "key": "best_wave", "coins": 100},
	{"id": "combo_10", "desc": "Build 10× combo", "target": 10, "key": "best_combo", "coins": 150},
	{"id": "play_3", "desc": "Play 3 games", "target": 3, "key": "total_games_played", "coins": 100},
	{"id": "score_5000", "desc": "Earn 5,000 score", "target": 5000, "key": "high_score", "coins": 150},
	{"id": "wave_10", "desc": "Reach Wave 10", "target": 10, "key": "best_wave", "coins": 200},
]

const WEEKLY_POOL := [
	{"id": "destroy_500", "desc": "Destroy 500 asteroids", "target": 500, "key": "total_asteroids_destroyed", "coins": 500},
	{"id": "wave_15", "desc": "Reach Wave 15", "target": 15, "key": "best_wave", "coins": 800},
	{"id": "play_15", "desc": "Play 15 games", "target": 15, "key": "total_games_played", "coins": 500},
	{"id": "combo_30", "desc": "Build 30× combo", "target": 30, "key": "best_combo", "gems": 5},
	{"id": "score_50000", "desc": "Earn 50,000 total score", "target": 50000, "key": "high_score", "coins": 800},
]

var active_dailies: Array[Dictionary] = []
var active_weeklies: Array[Dictionary] = []
var claimed_dailies: Array[String] = []
var claimed_weeklies: Array[String] = []

func _ready() -> void:
	_load_missions()

func _load_missions() -> void:
	var saved_daily_ids: Array = GameData.settings.get("mission_daily_ids", [])
	var saved_weekly_ids: Array = GameData.settings.get("mission_weekly_ids", [])
	claimed_dailies = []
	claimed_weeklies = []
	var cd: Array = GameData.settings.get("claimed_dailies", [])
	for item in cd:
		claimed_dailies.append(str(item))
	var cw: Array = GameData.settings.get("claimed_weeklies", [])
	for item in cw:
		claimed_weeklies.append(str(item))
	
	var daily_reset: String = GameData.settings.get("daily_reset", "")
	var today := _get_today_str()
	
	if daily_reset != today or saved_daily_ids.is_empty():
		_generate_dailies()
		GameData.settings["daily_reset"] = today
		GameData.settings["claimed_dailies"] = []
		claimed_dailies = []
		SaveManager.save_game()
	else:
		active_dailies = []
		for did in saved_daily_ids:
			for m in DAILY_POOL:
				if m["id"] == did:
					active_dailies.append(m.duplicate())
	
	# Weekly (simplified — reset every 7 days)
	if saved_weekly_ids.is_empty():
		_generate_weeklies()
		GameData.settings["claimed_weeklies"] = []
		claimed_weeklies = []
		SaveManager.save_game()
	else:
		active_weeklies = []
		for wid in saved_weekly_ids:
			for m in WEEKLY_POOL:
				if m["id"] == wid:
					active_weeklies.append(m.duplicate())

func _generate_dailies() -> void:
	active_dailies = []
	var pool := DAILY_POOL.duplicate()
	for _i in mini(3, pool.size()):
		var idx := randi() % pool.size()
		active_dailies.append(pool[idx].duplicate())
		pool.remove_at(idx)
	
	var ids: Array[String] = []
	for m in active_dailies:
		ids.append(m["id"])
	GameData.settings["mission_daily_ids"] = ids

func _generate_weeklies() -> void:
	active_weeklies = []
	var pool := WEEKLY_POOL.duplicate()
	for _i in mini(3, pool.size()):
		var idx := randi() % pool.size()
		active_weeklies.append(pool[idx].duplicate())
		pool.remove_at(idx)
	
	var ids: Array[String] = []
	for m in active_weeklies:
		ids.append(m["id"])
	GameData.settings["mission_weekly_ids"] = ids

func _get_progress(mission: Dictionary) -> int:
	var key: String = mission["key"]
	return GameData.get(key) if key in GameData else 0

func claim_mission(mission_id: String, is_daily: bool) -> void:
	var missions: Array[Dictionary] = active_dailies if is_daily else active_weeklies
	var claimed: Array[String] = claimed_dailies if is_daily else claimed_weeklies
	
	if mission_id in claimed:
		return
	
	for m in missions:
		if m["id"] == mission_id:
			var progress := _get_progress(m)
			var target: int = m["target"]
			if progress >= target:
				var coin_reward: int = m.get("coins", 0)
				var gem_reward: int = m.get("gems", 0)
				GameData.total_coins += coin_reward
				GameData.gems += gem_reward
				claimed.append(mission_id)
				
				if is_daily:
					GameData.settings["claimed_dailies"] = claimed_dailies
				else:
					GameData.settings["claimed_weeklies"] = claimed_weeklies
				SaveManager.save_game()
			break

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var x: float = 40.0
	var card_w := vp.x - 80
	var card_h: float = 50.0
	
	# Daily missions
	var y_start: float = 100.0
	for i in active_dailies.size():
		var y := y_start + float(i) * (card_h + 5)
		if Rect2(x, y, card_w, card_h).has_point(pos):
			var mid: String = active_dailies[i]["id"]
			claim_mission(mid, true)
			queue_redraw()
			return
	
	# Weekly missions
	var wy_start := y_start + active_dailies.size() * (card_h + 5) + 50
	for i in active_weeklies.size():
		var y := wy_start + float(i) * (card_h + 5)
		if Rect2(x, y, card_w, card_h).has_point(pos):
			var mid: String = active_weeklies[i]["id"]
			claim_mission(mid, false)
			queue_redraw()
			return

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var x: float = 40.0
	var card_w := vp.x - 80
	var card_h: float = 50.0
	
	# Daily header
	draw_string(font, Vector2(x, 85), "── DAILY MISSIONS ──", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 1, 1, 0.6))
	
	var y_start: float = 100.0
	for i in active_dailies.size():
		var m: Dictionary = active_dailies[i]
		var y := y_start + float(i) * (card_h + 5)
		_draw_mission_card(font, x, y, card_w, card_h, m, m["id"] in claimed_dailies)
	
	# Weekly header
	var wy_start := y_start + active_dailies.size() * (card_h + 5) + 30
	draw_string(font, Vector2(x, wy_start + 15), "── WEEKLY MISSIONS ──", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.8, 0, 0.6))
	wy_start += 30
	
	for i in active_weeklies.size():
		var m: Dictionary = active_weeklies[i]
		var y := wy_start + float(i) * (card_h + 5)
		_draw_mission_card(font, x, y, card_w, card_h, m, m["id"] in claimed_weeklies)

func _draw_mission_card(font: Font, x: float, y: float, w: float, h: float, m: Dictionary, is_claimed: bool) -> void:
	var progress := _get_progress(m)
	var target: int = m["target"]
	var complete := progress >= target
	
	# Background
	var bg := Color(0.08, 0.08, 0.12, 0.6)
	if is_claimed:
		bg = Color(0, 0.1, 0.05, 0.4)
	elif complete:
		bg = Color(0.1, 0.15, 0.05, 0.6)
	draw_rect(Rect2(x, y, w, h), bg)
	
	# Description
	var desc: String = m["desc"]
	draw_string(font, Vector2(x + 10, y + 20), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.8))
	
	# Progress bar
	var bar_x := x + 10
	var bar_y := y + h - 15
	var bar_w := w * 0.5
	var ratio := clampf(float(progress) / float(target), 0, 1)
	draw_rect(Rect2(bar_x, bar_y, bar_w, 6), Color(0.2, 0.2, 0.2, 0.5))
	draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, 6), Color(0, 1, 1, 0.6) if not complete else Color(0, 1, 0.5, 0.6))
	
	# Progress text
	draw_string(font, Vector2(bar_x + bar_w + 10, y + h - 8), str(mini(progress, target)) + "/" + str(target), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
	
	# Reward
	var coin_val: int = m.get("coins", 0)
	var gem_val: int = m.get("gems", 0)
	var reward_col := Color(1, 0.85, 0.2)
	
	if is_claimed:
		NeonIcons.draw_checkmark(self, Vector2(x + w - 75, y + 14), 6.0, Color(0, 1, 0.5, 0.6))
		draw_string(font, Vector2(x + w - 62, y + 20), "DONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 0.5, 0.6))
	elif complete:
		draw_string(font, Vector2(x + w - 80, y + 20), "CLAIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 0.5))
		if coin_val > 0:
			NeonIcons.draw_coin(self, Vector2(x + w - 75, y + 31), 4.0, reward_col)
			draw_string(font, Vector2(x + w - 65, y + 38), str(coin_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, reward_col)
		else:
			NeonIcons.draw_gem(self, Vector2(x + w - 75, y + 31), 4.0, Color(0.4, 0.8, 1))
			draw_string(font, Vector2(x + w - 65, y + 38), str(gem_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.8, 1))
	else:
		if coin_val > 0:
			NeonIcons.draw_coin(self, Vector2(x + w - 75, y + 18), 4.0, Color(0.5, 0.5, 0.5))
			draw_string(font, Vector2(x + w - 65, y + 25), str(coin_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.5))
		else:
			NeonIcons.draw_gem(self, Vector2(x + w - 75, y + 18), 4.0, Color(0.5, 0.5, 0.5))
			draw_string(font, Vector2(x + w - 65, y + 25), str(gem_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.5))

func _get_today_str() -> String:
	var dt := Time.get_datetime_dict_from_system(true)
	return str(dt["year"]) + "-" + str(dt["month"]).pad_zeros(2) + "-" + str(dt["day"]).pad_zeros(2)
