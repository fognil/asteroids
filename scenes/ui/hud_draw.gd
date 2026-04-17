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
	var sc := ScreenWrap.get_ui_scale()
	var bar_w := 350.0 * sc
	var bar_h := 10.0 * sc
	var bar_x := (vp.x - bar_w) / 2
	var bar_y := vp.y - 55 * sc
	
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
		var font := ScreenWrap.neon_font
		var fs := int(20 * sc)
		draw_string(font, Vector2(bar_x + bar_w / 2 - 50 * sc, bar_y - 8 * sc), "OVERHEAT!", HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 0.3, 0.3, 0.9))

func _draw_active_powerups(vp: Vector2) -> void:
	var sc := ScreenWrap.get_ui_scale()
	var font := ScreenWrap.neon_font
	var x_start := 30.0 * sc
	var y_pos := vp.y - 110.0 * sc
	var icon_spacing := 90.0 * sc
	var idx := 0
	var fs := int(16 * sc)
	var fs_sm := int(18 * sc)
	var r := 22.0 * sc
	
	for type in PowerupManager.active_powerups:
		var ratio: float = PowerupManager.get_ratio(type)
		var config: Dictionary = PowerupManager.POWERUP_TYPES.get(type, {})
		var color: Color = config.get("color", Color.WHITE)
		
		var x: float = x_start + idx * icon_spacing
		var center := Vector2(x + 25 * sc, y_pos)
		
		# Background circle
		draw_circle(center, r, Color(color, 0.1))
		draw_arc(center, r, 0, TAU, 16, Color(color, 0.3), 1.5 * sc, true)
		
		# Timer arc (countdown)
		draw_arc(center, r, -PI / 2, -PI / 2 + TAU * ratio, 16, Color(color, 0.8), 4.0 * sc, true)
		
		# Type label
		var label: String = type.substr(0, 3).to_upper()
		draw_string(font, Vector2(x + 10 * sc, y_pos + 5 * sc), label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(color, 0.9))
		
		# Remaining seconds
		var remaining: float = PowerupManager.get_remaining(type)
		var time_str := str(ceili(remaining)) + "s"
		draw_string(font, Vector2(x + 12 * sc, y_pos + 35 * sc), time_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fs_sm, Color(1, 1, 1, 0.5))
		
		idx += 1

func _draw_game_over(vp: Vector2) -> void:
	var sc := ScreenWrap.get_ui_scale()
	var font := ScreenWrap.neon_font
	
	# Semi-transparent overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.4))
	
	var go_fs := int(80 * sc)
	var go_text := "GAME OVER"
	var go_size := font.get_string_size(go_text, HORIZONTAL_ALIGNMENT_CENTER, -1, go_fs)
	draw_string(font, Vector2((vp.x - go_size.x) / 2, vp.y * 0.33), go_text, HORIZONTAL_ALIGNMENT_CENTER, -1, go_fs, Color(1, 0.3, 0.3))
	
	var fs := int(36 * sc)
	var score_text := "SCORE: " + str(GameData.score) + "  |  WAVE: " + str(GameData.wave)
	var score_size := font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, Vector2((vp.x - score_size.x) / 2, vp.y * 0.40), score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.8))
	
	# Coins earned
	var fs_sm := int(24 * sc)
	var coins_text := "+" + str(GameData.coins) + " coins earned"
	var cs := font.get_string_size(coins_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs_sm)
	NeonIcons.draw_coin(self, Vector2((vp.x - cs.x) / 2 - 22 * sc, vp.y * 0.45 - 8 * sc), 8.0 * sc)
	draw_string(font, Vector2((vp.x - cs.x) / 2, vp.y * 0.45), coins_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs_sm, Color(1, 0.85, 0.2, 0.7))
	
	# Ad buttons
	var btn_w := 200.0 * sc
	var btn_h := 60.0 * sc
	
	if AdManager.can_show_ad("revive"):
		var rv_x := vp.x / 2 - btn_w - 10 * sc
		var rv_y := vp.y * 0.52
		draw_rect(Rect2(rv_x, rv_y, btn_w, btn_h), Color(0, 0.15, 0, 0.6))
		draw_rect(Rect2(rv_x, rv_y, btn_w, btn_h), Color(0, 1, 0.5, 0.4), false, 2.0 * sc)
		NeonIcons.draw_tv(self, Vector2(rv_x + 25 * sc, rv_y + btn_h / 2), 12.0 * sc, Color(0, 1, 0.5))
		draw_string(font, Vector2(rv_x + 50 * sc, rv_y + btn_h / 2 + fs_sm * 0.35), "Revive", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0, 1, 0.5))
	
	if AdManager.can_show_ad("double_coins"):
		var dc_x := vp.x / 2 + 10 * sc
		var dc_y := vp.y * 0.52
		draw_rect(Rect2(dc_x, dc_y, btn_w, btn_h), Color(0.15, 0.1, 0, 0.6))
		draw_rect(Rect2(dc_x, dc_y, btn_w, btn_h), Color(1, 0.85, 0.2, 0.4), false, 2.0 * sc)
		NeonIcons.draw_tv(self, Vector2(dc_x + 25 * sc, dc_y + btn_h / 2), 12.0 * sc, Color(1, 0.85, 0.2))
		draw_string(font, Vector2(dc_x + 50 * sc, dc_y + btn_h / 2 + fs_sm * 0.35), "x2 Coins", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(1, 0.85, 0.2))
	
	var restart_fs := int(28 * sc)
	var restart_text := "Tap to Restart"
	var rs_size := font.get_string_size(restart_text, HORIZONTAL_ALIGNMENT_CENTER, -1, restart_fs)
	draw_string(font, Vector2((vp.x - rs_size.x) / 2, vp.y * 0.62), restart_text, HORIZONTAL_ALIGNMENT_CENTER, -1, restart_fs, Color(1, 1, 1, 0.4 + 0.4 * abs(sin(Time.get_ticks_msec() * 0.003))))

func _draw_pause_button(vp: Vector2) -> void:
	var sc := ScreenWrap.get_ui_scale()
	if GameData.lives <= 0:
		return
	var px := vp.x - 70 * sc
	var py := 35.0 * sc
	NeonIcons.draw_pause(self, Vector2(px, py), 20.0 * sc, Color(0.8, 0.8, 0.8, 0.5))

func _draw_boss_hp(vp: Vector2) -> void:
	var sc := ScreenWrap.get_ui_scale()
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null or not is_instance_valid(boss):
		return
	if not "hp" in boss or not "max_hp" in boss:
		return
	
	var font := ScreenWrap.neon_font
	var hp_val: int = boss.hp
	var max_hp_val: int = boss.max_hp
	var ratio := clampf(float(hp_val) / float(max_hp_val), 0.0, 1.0)
	
	var bar_w := vp.x * 0.4
	var bar_x := (vp.x - bar_w) / 2
	var bar_y := 20.0 * sc
	var bar_h := 16.0 * sc
	
	# Background
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.15, 0.6))
	# HP fill
	var hp_col := Color(1, 0.2, 0.2) if ratio < 0.3 else (Color(1, 0.8, 0) if ratio < 0.6 else Color(0, 1, 0.5))
	draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, bar_h), Color(hp_col, 0.7))
	# Border
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(1, 1, 1, 0.2), false, 1.5 * sc)
	# HP text
	var hp_fs := int(16 * sc)
	draw_string(font, Vector2(bar_x + bar_w / 2 - 30 * sc, bar_y + bar_h - 2 * sc), str(hp_val) + "/" + str(max_hp_val), HORIZONTAL_ALIGNMENT_CENTER, -1, hp_fs, Color(1, 1, 1, 0.6))

func _input(event: InputEvent) -> void:
	var vp := get_viewport_rect().size
	var sc := ScreenWrap.get_ui_scale()
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return
	
	# Pause button (top-right)
	if GameData.lives > 0 and pos.x > vp.x - 100 * sc and pos.y < 70 * sc:
		var pause_node := get_tree().root.find_child("PauseScreen", true, false)
		if pause_node and pause_node.has_method("toggle_pause"):
			pause_node.toggle_pause()
		return
	
	# Game over ad buttons
	if GameData.lives <= 0:
		var btn_w := 200.0 * sc
		var btn_h := 60.0 * sc
		if AdManager.can_show_ad("revive"):
			var rv_rect := Rect2(vp.x / 2 - btn_w - 10 * sc, vp.y * 0.52, btn_w, btn_h)
			if rv_rect.has_point(pos):
				AdManager.show_ad("revive")
				return
		if AdManager.can_show_ad("double_coins"):
			var dc_rect := Rect2(vp.x / 2 + 10 * sc, vp.y * 0.52, btn_w, btn_h)
			if dc_rect.has_point(pos):
				AdManager.show_ad("double_coins")
				return
