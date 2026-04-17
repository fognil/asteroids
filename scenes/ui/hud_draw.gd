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
	draw_string(font, Vector2((vp.x - go_size.x) / 2, vp.y * 0.38), go_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color(1, 0.3, 0.3))
	
	var score_text := "SCORE: " + str(GameData.score) + "  |  WAVE: " + str(GameData.wave)
	var score_size := font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	draw_string(font, Vector2((vp.x - score_size.x) / 2, vp.y * 0.45), score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 1, 0.8))
	
	var restart_text := "Tap or Press SPACE to Restart"
	var rs_size := font.get_string_size(restart_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(font, Vector2((vp.x - rs_size.x) / 2, vp.y * 0.52), restart_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1, 1, 1, 0.4 + 0.4 * abs(sin(Time.get_ticks_msec() * 0.003))))
