extends Control
## Achievements screen — popup overlay with milestones.

const ACHIEVEMENTS := [
	{"id": "first_game", "name": "First Flight", "desc": "Play your first game", "key": "total_games_played", "target": 1, "gems": 1},
	{"id": "play_10", "name": "Regular Pilot", "desc": "Play 10 games", "key": "total_games_played", "target": 10, "gems": 3},
	{"id": "play_50", "name": "Veteran Pilot", "desc": "Play 50 games", "key": "total_games_played", "target": 50, "gems": 10},
	{"id": "destroy_100", "name": "Rock Crusher", "desc": "Destroy 100 asteroids", "key": "total_asteroids_destroyed", "target": 100, "gems": 3},
	{"id": "destroy_1000", "name": "Asteroid Annihilator", "desc": "Destroy 1,000 asteroids", "key": "total_asteroids_destroyed", "target": 1000, "gems": 10},
	{"id": "destroy_5000", "name": "Space Cleaner", "desc": "Destroy 5,000 asteroids", "key": "total_asteroids_destroyed", "target": 5000, "gems": 25},
	{"id": "wave_5", "name": "Survivor", "desc": "Reach Wave 5", "key": "best_wave", "target": 5, "gems": 2},
	{"id": "wave_10", "name": "Endurance", "desc": "Reach Wave 10", "key": "best_wave", "target": 10, "gems": 5},
	{"id": "wave_15", "name": "Hardened", "desc": "Reach Wave 15", "key": "best_wave", "target": 15, "gems": 8},
	{"id": "wave_25", "name": "Unstoppable", "desc": "Reach Wave 25", "key": "best_wave", "target": 25, "gems": 15},
	{"id": "combo_10", "name": "Combo Starter", "desc": "Build a 10× combo", "key": "best_combo", "target": 10, "gems": 3},
	{"id": "combo_30", "name": "Combo Master", "desc": "Build a 30× combo", "key": "best_combo", "target": 30, "gems": 10},
	{"id": "combo_50", "name": "Combo Legend", "desc": "Build a 50× combo", "key": "best_combo", "target": 50, "gems": 20},
	{"id": "score_10k", "name": "10K Club", "desc": "Score 10,000 points", "key": "high_score", "target": 10000, "gems": 3},
	{"id": "score_50k", "name": "50K Club", "desc": "Score 50,000 points", "key": "high_score", "target": 50000, "gems": 10},
	{"id": "score_100k", "name": "100K Club", "desc": "Score 100,000 points", "key": "high_score", "target": 100000, "gems": 25},
	{"id": "coins_10k", "name": "Coin Collector", "desc": "Earn 10,000 total coins", "key": "total_coins_earned", "target": 10000, "gems": 5},
	{"id": "coins_50k", "name": "Rich Pilot", "desc": "Earn 50,000 total coins", "key": "total_coins_earned", "target": 50000, "gems": 15},
	{"id": "level_10", "name": "Rising Star", "desc": "Reach Level 10", "key": "player_level", "target": 10, "gems": 5},
	{"id": "level_25", "name": "Elite Pilot", "desc": "Reach Level 25", "key": "player_level", "target": 25, "gems": 15},
]

var scroll_offset: float = 0.0

func check_achievements() -> void:
	var claimed: Array = GameData.settings.get("achievements_claimed", [])
	for ach in ACHIEVEMENTS:
		var ach_id: String = ach["id"]
		if claimed.has(ach_id):
			continue
		var progress := _get_progress(ach)
		var target: int = ach["target"]
		if progress >= target:
			var gem_reward: int = ach["gems"]
			GameData.gems += gem_reward
			claimed.append(ach["id"])
			AudioManager.play_sfx("powerup")
	GameData.settings["achievements_claimed"] = claimed
	SaveManager.save_game()

func _get_progress(ach: Dictionary) -> int:
	var key: String = ach["key"]
	if key in GameData:
		return GameData.get(key)
	return 0

func show_popup() -> void:
	scroll_offset = 0.0
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func hide_popup() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _get_panel_rect(vp: Vector2, sc: float) -> Rect2:
	var pw := minf(850 * sc, vp.x * 0.9)
	var ph := minf(650 * sc, vp.y * 0.85)
	var px := (vp.x - pw) / 2
	var py := (vp.y - ph) / 2
	return Rect2(px, py, pw, ph)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Scrolling
	if event is InputEventScreenDrag:
		scroll_offset -= event.relative.y
		scroll_offset = clampf(scroll_offset, 0, float(ACHIEVEMENTS.size()) * 55 - 200)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_offset = maxf(scroll_offset - 40, 0)
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_offset = minf(scroll_offset + 40, float(ACHIEVEMENTS.size()) * 55 - 200)
			queue_redraw()
			get_viewport().set_input_as_handled()
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
	
	# Close button
	var close_rect := Rect2(panel.position.x + panel.size.x - 50 * sc, panel.position.y + 10 * sc, 40 * sc, 40 * sc)
	if close_rect.has_point(pos):
		hide_popup()
		get_viewport().set_input_as_handled()
		return
	
	# Tap outside → close
	if not panel.has_point(pos):
		hide_popup()
		get_viewport().set_input_as_handled()
		return
	
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var sc := ScreenWrap.get_ui_scale()
	var font := ScreenWrap.neon_font
	var claimed: Array = GameData.settings.get("achievements_claimed", [])
	
	# Dark overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.7))
	
	# Panel
	var panel := _get_panel_rect(vp, sc)
	draw_rect(panel, Color(0.03, 0.04, 0.08, 0.95))
	draw_rect(panel, Color(0.6, 0.2, 1, 0.3), false, 2.0 * sc)
	
	var px := panel.position.x
	var py := panel.position.y
	var pw := panel.size.x
	var ph := panel.size.y
	
	# Close X
	var cx := px + pw - 35 * sc
	var cy := py + 30 * sc
	var xs := 12.0 * sc
	draw_line(Vector2(cx - xs, cy - xs), Vector2(cx + xs, cy + xs), Color(1, 0.3, 0.3, 0.8), 3.0 * sc)
	draw_line(Vector2(cx + xs, cy - xs), Vector2(cx - xs, cy + xs), Color(1, 0.3, 0.3, 0.8), 3.0 * sc)
	
	# Title
	var title_fs := int(20 * sc)
	var done_count := claimed.size()
	NeonIcons.draw_medal(self, Vector2(px + 25 * sc, py + 35 * sc), 10.0 * sc, Color(1, 0.85, 0.2))
	draw_string(font, Vector2(px + 50 * sc, py + 42 * sc), "ACHIEVEMENTS " + str(done_count) + "/" + str(ACHIEVEMENTS.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, Color(1, 0.85, 0.2))
	
	# Separator
	draw_line(Vector2(px + 15 * sc, py + 58 * sc), Vector2(px + pw - 15 * sc, py + 58 * sc), Color(0.6, 0.2, 1, 0.15), 1.0)
	
	# Achievement cards
	var card_h := 50.0 * sc
	var card_gap := 6.0 * sc
	var content_y := py + 68 * sc
	var content_h := ph - 78 * sc
	
	for i in ACHIEVEMENTS.size():
		var cy2 := content_y + float(i) * (card_h + card_gap) - scroll_offset
		if cy2 + card_h < content_y or cy2 > py + ph:
			continue
		
		var ach: Dictionary = ACHIEVEMENTS[i]
		var ach_id: String = ach["id"]
		var is_claimed: bool = claimed.has(ach_id)
		var progress := _get_progress(ach)
		var target: int = ach["target"]
		var ratio := clampf(float(progress) / float(target), 0.0, 1.0)
		
		# Card bg
		var card_x := px + 15 * sc
		var card_w := pw - 30 * sc
		var bg := Color(0.05, 0.1, 0.05, 0.5) if is_claimed else Color(0.06, 0.06, 0.12, 0.5)
		draw_rect(Rect2(card_x, cy2, card_w, card_h), bg)
		var border_col := Color(0, 1, 0.5, 0.2) if is_claimed else Color(0.3, 0.3, 0.4, 0.2)
		draw_rect(Rect2(card_x, cy2, card_w, card_h), border_col, false, 1.0)
		
		# Name
		var name_fs := int(13 * sc)
		var ach_name: String = ach["name"]
		var name_col := Color(0, 1, 0.5, 0.9) if is_claimed else Color(1, 1, 1, 0.8)
		draw_string(font, Vector2(card_x + 12 * sc, cy2 + 20 * sc), ach_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs, name_col)
		
		# Desc
		var desc_fs := int(10 * sc)
		var desc: String = ach["desc"]
		draw_string(font, Vector2(card_x + 12 * sc, cy2 + 36 * sc), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, desc_fs, Color(0.5, 0.5, 0.5))
		
		# Progress bar
		var bar_x := card_x + card_w * 0.58
		var bar_w := card_w * 0.25
		draw_rect(Rect2(bar_x, cy2 + 20 * sc, bar_w, 8 * sc), Color(0.15, 0.15, 0.15, 0.5))
		var bar_col := Color(0, 1, 0.5, 0.6) if is_claimed else Color(0, 1, 1, 0.4)
		draw_rect(Rect2(bar_x, cy2 + 20 * sc, bar_w * ratio, 8 * sc), bar_col)
		draw_string(font, Vector2(bar_x, cy2 + 42 * sc), str(mini(progress, target)) + "/" + str(target), HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 * sc), Color(0.4, 0.4, 0.4))
		
		# Gem reward
		var gem_val: int = ach["gems"]
		var reward_col := Color(0, 1, 0.5, 0.6) if is_claimed else Color(0.4, 0.8, 1, 0.6)
		NeonIcons.draw_gem(self, Vector2(card_x + card_w - 50 * sc, cy2 + 15 * sc), 6.0 * sc, reward_col)
		draw_string(font, Vector2(card_x + card_w - 38 * sc, cy2 + 22 * sc), str(gem_val), HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * sc), reward_col)
		
		if is_claimed:
			NeonIcons.draw_checkmark(self, Vector2(card_x + card_w - 48 * sc, cy2 + 38 * sc), 6.0 * sc, Color(0, 1, 0.5, 0.6))
