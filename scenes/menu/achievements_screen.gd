extends Control
## Achievements screen — track and display player milestones.

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
			# Auto-claim
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

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenDrag:
		scroll_offset -= event.relative.y
		scroll_offset = clampf(scroll_offset, 0, float(ACHIEVEMENTS.size()) * 55 - 200)
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_offset = maxf(scroll_offset - 40, 0)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_offset = minf(scroll_offset + 40, float(ACHIEVEMENTS.size()) * 55 - 200)
			queue_redraw()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var claimed: Array = GameData.settings.get("achievements_claimed", [])
	
	# Header + count
	var done_count := claimed.size()
	NeonIcons.draw_medal(self, Vector2(48, 78), 8.0, Color(1, 0.85, 0.2))
	draw_string(font, Vector2(62, 85), "ACHIEVEMENTS: " + str(done_count) + "/" + str(ACHIEVEMENTS.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.2))
	
	var card_h: float = 45.0
	var card_w := vp.x - 80
	var x: float = 40.0
	
	for i in ACHIEVEMENTS.size():
		var y := 100 + float(i) * (card_h + 8) - scroll_offset
		if y < 60 or y > vp.y:
			continue
		
		var ach: Dictionary = ACHIEVEMENTS[i]
		var ach_id: String = ach["id"]
		var is_claimed: bool = claimed.has(ach_id)
		var progress := _get_progress(ach)
		var target: int = ach["target"]
		var ratio := clampf(float(progress) / float(target), 0.0, 1.0)
		
		# Background
		var bg := Color(0.05, 0.08, 0.05, 0.4) if is_claimed else Color(0.06, 0.06, 0.1, 0.5)
		draw_rect(Rect2(x, y, card_w, card_h), bg)
		
		# Name + desc
		var ach_name: String = ach["name"]
		var name_col := Color(0, 1, 0.5, 0.8) if is_claimed else Color(1, 1, 1, 0.7)
		draw_string(font, Vector2(x + 10, y + 16), ach_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, name_col)
		
		var desc: String = ach["desc"]
		draw_string(font, Vector2(x + 10, y + 32), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
		
		# Progress bar
		var bar_x := x + card_w * 0.6
		var bar_w := card_w * 0.25
		draw_rect(Rect2(bar_x, y + 18, bar_w, 6), Color(0.15, 0.15, 0.15, 0.5))
		var bar_col := Color(0, 1, 0.5, 0.5) if is_claimed else Color(0, 1, 1, 0.4)
		draw_rect(Rect2(bar_x, y + 18, bar_w * ratio, 6), bar_col)
		draw_string(font, Vector2(bar_x, y + 35), str(mini(progress, target)) + "/" + str(target), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.4, 0.4))
		
		# Reward
		var gem_val: int = ach["gems"]
		var reward_col := Color(0, 1, 0.5, 0.5) if is_claimed else Color(0.4, 0.8, 1, 0.5)
		NeonIcons.draw_gem(self, Vector2(x + card_w - 45, y + 12), 5.0, reward_col)
		draw_string(font, Vector2(x + card_w - 35, y + 18), str(gem_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, reward_col)
		
		if is_claimed:
			NeonIcons.draw_checkmark(self, Vector2(x + card_w - 42, y + 33), 5.0, Color(0, 1, 0.5, 0.5))
