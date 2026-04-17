extends Control
## HUD overlay for custom drawing — active power-ups, heat bar, game over.

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	
	# === Heat Bar (bottom-center) ===
	_draw_heat_bar(vp)
	
	# === Active Power-ups (bottom-left) ===
	_draw_active_powerups(vp)
	
	# === Pause Button (top-right) ===
	_draw_pause_button(vp)
	
	# === Boss HP Bar (top-center) ===
	_draw_boss_hp(vp)
	
	# === Game Over overlay ===
	if GameData.lives <= 0:
		_draw_game_over(vp)

func _draw_heat_bar(vp: Vector2) -> void:
	var bar_w: float = 200.0
	var bar_h: float = 6.0
	var bar_x := (vp.x - bar_w) / 2
	var bar_y := vp.y - 35
	
	# Background
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2, 0.4))
	
	# Read heat from player
	var player := get_tree().get_first_node_in_group("player")
	var heat := 0.0
	if player and "heat" in player:
		heat = player.heat
	
	var heat_ratio := clampf(heat / 100.0, 0.0, 1.0)
	var heat_color := Color(0, 1, 1, 0.6)
	if heat_ratio > 0.8:
		heat_color = Color(1, 0.2, 0.2, 0.8)
	elif heat_ratio > 0.5:
		heat_color = Color(1, 1, 0, 0.7)
	draw_rect(Rect2(bar_x, bar_y, bar_w * heat_ratio, bar_h), heat_color)
	
	# Overheat warning
	if heat_ratio > 0.9:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(bar_x + bar_w / 2 - 30, bar_y - 4), "OVERHEAT!", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 0.3, 0.3, 0.9))

func _draw_active_powerups(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var x_start: float = 20.0
	var y_pos: float = vp.y - 70.0
	var icon_spacing: float = 55.0
	var idx := 0
	
	for type in PowerupManager.active_powerups:
		var ratio: float = PowerupManager.get_ratio(type)
		var config: Dictionary = PowerupManager.POWERUP_TYPES.get(type, {})
		var color: Color = config.get("color", Color.WHITE)
		
		var x: float = x_start + idx * icon_spacing
		var center := Vector2(x + 15, y_pos)
		
		# Background circle
		draw_circle(center, 14.0, Color(color, 0.1))
		draw_arc(center, 14.0, 0, TAU, 16, Color(color, 0.3), 1.0, true)
		
		# Timer arc (countdown)
		draw_arc(center, 14.0, -PI / 2, -PI / 2 + TAU * ratio, 16, Color(color, 0.8), 2.5, true)
		
		# Type label
		var label: String = type.substr(0, 3).to_upper()
		draw_string(font, Vector2(x + 3, y_pos + 4), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(color, 0.9))
		
		# Remaining seconds
		var remaining: float = PowerupManager.get_remaining(type)
		var time_str := str(ceili(remaining)) + "s"
		draw_string(font, Vector2(x + 6, y_pos + 22), time_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1, 1, 1, 0.5))
		
		idx += 1

func _draw_game_over(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	
	# Semi-transparent overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.4))
	
	var go_text := "GAME OVER"
	var go_size := font.get_string_size(go_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48)
	draw_string(font, Vector2((vp.x - go_size.x) / 2, vp.y * 0.33), go_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color(1, 0.3, 0.3))
	
	var score_text := "SCORE: " + str(GameData.score) + "  |  WAVE: " + str(GameData.wave)
	var score_size := font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	draw_string(font, Vector2((vp.x - score_size.x) / 2, vp.y * 0.40), score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 1, 0.8))
	
	# Coins earned
	var coins_text := "+" + str(GameData.coins) + " coins earned"
	var cs := font.get_string_size(coins_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	NeonIcons.draw_coin(self, Vector2((vp.x - cs.x) / 2 - 14, vp.y * 0.45 - 5), 5.0)
	draw_string(font, Vector2((vp.x - cs.x) / 2, vp.y * 0.45), coins_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 0.85, 0.2, 0.7))
	
	# Ad buttons
	if AdManager.can_show_ad("revive"):
		var rv_x := vp.x / 2 - 130
		var rv_y := vp.y * 0.52
		draw_rect(Rect2(rv_x, rv_y, 120, 35), Color(0, 0.15, 0, 0.6))
		draw_rect(Rect2(rv_x, rv_y, 120, 35), Color(0, 1, 0.5, 0.4), false, 1.0)
		NeonIcons.draw_tv(self, Vector2(rv_x + 15, rv_y + 17), 8.0, Color(0, 1, 0.5))
		draw_string(font, Vector2(rv_x + 30, rv_y + 23), "Revive", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 1, 0.5))
	
	if AdManager.can_show_ad("double_coins"):
		var dc_x := vp.x / 2 + 10
		var dc_y := vp.y * 0.52
		draw_rect(Rect2(dc_x, dc_y, 120, 35), Color(0.15, 0.1, 0, 0.6))
		draw_rect(Rect2(dc_x, dc_y, 120, 35), Color(1, 0.85, 0.2, 0.4), false, 1.0)
		NeonIcons.draw_tv(self, Vector2(dc_x + 15, dc_y + 17), 8.0, Color(1, 0.85, 0.2))
		draw_string(font, Vector2(dc_x + 30, dc_y + 23), "x2 Coins", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.85, 0.2))
	
	var restart_text := "Tap to Restart"
	var rs_size := font.get_string_size(restart_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(font, Vector2((vp.x - rs_size.x) / 2, vp.y * 0.62), restart_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1, 1, 1, 0.4 + 0.4 * abs(sin(Time.get_ticks_msec() * 0.003))))

func _draw_pause_button(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if GameData.lives <= 0:
		return
	# Pause icon top-right (drawn with NeonIcons)
	var px := vp.x - 45
	var py: float = 22.0
	NeonIcons.draw_pause(self, Vector2(px, py), 12.0, Color(0.8, 0.8, 0.8, 0.5))

func _draw_boss_hp(vp: Vector2) -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null or not is_instance_valid(boss):
		return
	if not "hp" in boss or not "max_hp" in boss:
		return
	
	var font := ThemeDB.fallback_font
	var hp_val: int = boss.hp
	var max_hp_val: int = boss.max_hp
	var ratio := clampf(float(hp_val) / float(max_hp_val), 0.0, 1.0)
	
	var bar_w := vp.x * 0.4
	var bar_x := (vp.x - bar_w) / 2
	var bar_y: float = 15.0
	
	# Background
	draw_rect(Rect2(bar_x, bar_y, bar_w, 10), Color(0.15, 0.15, 0.15, 0.6))
	# HP fill
	var hp_col := Color(1, 0.2, 0.2) if ratio < 0.3 else (Color(1, 0.8, 0) if ratio < 0.6 else Color(0, 1, 0.5))
	draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, 10), Color(hp_col, 0.7))
	# Border
	draw_rect(Rect2(bar_x, bar_y, bar_w, 10), Color(1, 1, 1, 0.2), false, 1.0)
	# HP text
	draw_string(font, Vector2(bar_x + bar_w / 2 - 20, bar_y + 9), str(hp_val) + "/" + str(max_hp_val), HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(1, 1, 1, 0.6))

func _input(event: InputEvent) -> void:
	var vp := get_viewport_rect().size
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return
	
	# Pause button (top-right)
	if GameData.lives > 0 and pos.x > vp.x - 65 and pos.y < 45:
		var pause_node := get_tree().root.find_child("PauseScreen", true, false)
		if pause_node and pause_node.has_method("toggle_pause"):
			pause_node.toggle_pause()
		return
	
	# Game over ad buttons
	if GameData.lives <= 0:
		if AdManager.can_show_ad("revive"):
			var rv_rect := Rect2(vp.x / 2 - 130, vp.y * 0.52, 120, 35)
			if rv_rect.has_point(pos):
				AdManager.show_ad("revive")
				return
		if AdManager.can_show_ad("double_coins"):
			var dc_rect := Rect2(vp.x / 2 + 10, vp.y * 0.52, 120, 35)
			if dc_rect.has_point(pos):
				AdManager.show_ad("double_coins")
				return
