extends Control
## Main Menu / Hub — ship preview, play button, navigation to sub-screens.

var ship_rotation: float = 0.0
var play_glow: float = 0.0
var selected_tab: int = -1  # -1 = hub, 0=hangar, 1=upgrade, 2=pass, 3=mission, 4=shop
var star_bg: Array[Dictionary] = []

func _ready() -> void:
	_generate_stars()

func _generate_stars() -> void:
	for i in 100:
		star_bg.append({
			"pos": Vector2(randf() * 1920, randf() * 1080),
			"size": randf_range(0.3, 1.5),
			"brightness": randf_range(0.1, 0.4),
			"speed": randf_range(0.5, 2.5),
			"offset": randf() * TAU,
		})

func _process(delta: float) -> void:
	ship_rotation += delta * 0.3
	play_glow += delta * 2.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(event.position)

func _handle_touch(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	
	if selected_tab >= 0:
		# Check back button
		if pos.x < 100 and pos.y < 60:
			selected_tab = -1
			return
		
		# Handle sub-screen taps
		if selected_tab == 1:  # Upgrades
			_handle_upgrade_tap(pos, vp)
		elif selected_tab == 0:  # Hangar
			_handle_hangar_tap(pos, vp)
		return
	
	# PLAY button area (center)
	var play_rect := Rect2(vp.x / 2 - 120, vp.y * 0.58, 240, 55)
	if play_rect.has_point(pos):
		_start_game()
		return
	
	# Bottom nav tabs
	var tab_y := vp.y - 60
	if pos.y > tab_y:
		var tab_width := vp.x / 5.0
		var tab_idx := int(pos.x / tab_width)
		if tab_idx >= 0 and tab_idx < 5:
			selected_tab = tab_idx

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _draw() -> void:
	var vp := get_viewport_rect().size
	var time := Time.get_ticks_msec() / 1000.0
	var font := ThemeDB.fallback_font
	
	# Background
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.02, 0.04))
	
	# Stars
	for star in star_bg:
		var twinkle := 0.4 + 0.6 * sin(time * star["speed"] + star["offset"])
		var spos: Vector2 = star["pos"]
		draw_circle(spos, star["size"], Color(1, 1, 1, star["brightness"] * twinkle))
	
	if selected_tab >= 0:
		_draw_sub_screen(vp, font, time)
		return
	
	# === HUB MAIN ===
	_draw_status_bar(vp, font)
	_draw_ship_preview(vp, font, time)
	_draw_play_button(vp, font, time)
	_draw_best_scores(vp, font)
	_draw_nav_bar(vp, font)

func _draw_status_bar(vp: Vector2, font: Font) -> void:
	# Top bar background
	draw_rect(Rect2(0, 0, vp.x, 45), Color(0, 0, 0, 0.5))
	
	# Coins
	draw_string(font, Vector2(20, 30), "💰 " + str(GameData.total_coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.85, 0.2))
	# Gems
	draw_string(font, Vector2(180, 30), "💎 " + str(GameData.gems), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1))
	# Level
	draw_string(font, Vector2(300, 30), "🏆 Lv." + str(GameData.player_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.8, 0.8))

func _draw_ship_preview(vp: Vector2, font: Font, time: float) -> void:
	var center := Vector2(vp.x / 2, vp.y * 0.35)
	var ship_color: Color = GameData.get_ship_color()
	var s: float = 35.0
	
	# Draw rotating ship
	var pts := PackedVector2Array()
	var rot := ship_rotation
	var ship_points_raw := [
		Vector2(0, -s), Vector2(-s * 0.6, s * 0.7), Vector2(-s * 0.15, s * 0.4),
		Vector2(0, s * 0.55), Vector2(s * 0.15, s * 0.4), Vector2(s * 0.6, s * 0.7), Vector2(0, -s)
	]
	for p in ship_points_raw:
		pts.append(center + p.rotated(rot))
	
	# Glow
	draw_polyline(pts, Color(ship_color, 0.2), 8.0, true)
	draw_polyline(pts, Color(ship_color, 0.5), 4.0, true)
	draw_polyline(pts, ship_color, 2.0, true)
	
	# Ship name
	var ship_name: String = ""
	if GameData.equipped_ship in GameData.SHIP_STATS:
		ship_name = GameData.SHIP_STATS[GameData.equipped_ship]["name"]
	var name_size := font.get_string_size(ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	draw_string(font, Vector2((vp.x - name_size.x) / 2, center.y + s + 30), ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(ship_color, 0.9))

func _draw_play_button(vp: Vector2, font: Font, time: float) -> void:
	var btn_x := vp.x / 2 - 120
	var btn_y := vp.y * 0.58
	var btn_w: float = 240.0
	var btn_h: float = 55.0
	
	# Glow pulse
	var pulse := 0.5 + 0.5 * sin(time * 2.0)
	var glow_color := Color(0, 1, 1, 0.1 + pulse * 0.1)
	draw_rect(Rect2(btn_x - 4, btn_y - 4, btn_w + 8, btn_h + 8), glow_color)
	
	# Button background
	draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0, 0.2, 0.3, 0.6))
	# Border
	var border_pts := PackedVector2Array([
		Vector2(btn_x, btn_y), Vector2(btn_x + btn_w, btn_y),
		Vector2(btn_x + btn_w, btn_y + btn_h), Vector2(btn_x, btn_y + btn_h), Vector2(btn_x, btn_y)
	])
	draw_polyline(border_pts, Color(0, 1, 1, 0.6 + pulse * 0.3), 2.0)
	
	# Text
	var play_text := "▶  P L A Y"
	var text_size := font.get_string_size(play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 26)
	draw_string(font, Vector2((vp.x - text_size.x) / 2, btn_y + 36), play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 26, Color(0, 1, 1))

func _draw_best_scores(vp: Vector2, font: Font) -> void:
	var y := vp.y * 0.72
	var text := "Best Score: " + str(GameData.high_score) + "   |   Best Wave: " + str(GameData.best_wave)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	draw_string(font, Vector2((vp.x - text_size.x) / 2, y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5, 0.7))

func _draw_nav_bar(vp: Vector2, font: Font) -> void:
	var bar_h: float = 60.0
	var bar_y := vp.y - bar_h
	
	# Background
	draw_rect(Rect2(0, bar_y, vp.x, bar_h), Color(0, 0, 0, 0.7))
	draw_line(Vector2(0, bar_y), Vector2(vp.x, bar_y), Color(0.3, 0.3, 0.3, 0.5), 1.0)
	
	var tabs := ["🚀 Hangar", "⬆️ Upgrade", "🎫 Pass", "🎯 Mission", "🛒 Shop"]
	var tab_w := vp.x / 5.0
	
	for i in tabs.size():
		var x := i * tab_w
		var tab_color := Color(0.5, 0.5, 0.5, 0.6)
		if i == selected_tab:
			tab_color = Color(0, 1, 1, 0.9)
		var label: String = tabs[i]
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		draw_string(font, Vector2(x + (tab_w - label_size.x) / 2, bar_y + 38), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, tab_color)

# === Sub Screens ===
func _draw_sub_screen(vp: Vector2, font: Font, time: float) -> void:
	# Header
	draw_rect(Rect2(0, 0, vp.x, 50), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(20, 35), "← Back", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 1, 1, 0.8))
	draw_string(font, Vector2(vp.x - 150, 35), "💰 " + str(GameData.total_coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0.2))
	
	match selected_tab:
		0: _draw_hangar(vp, font, time)
		1: _draw_upgrades(vp, font)
		2: _draw_pass(vp, font)
		3: _draw_missions(vp, font)
		4: _draw_shop(vp, font)
	
	_draw_nav_bar(vp, font)

func _draw_hangar(vp: Vector2, font: Font, time: float) -> void:
	var title := "🚀 HANGAR"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0, 1, 1))
	
	# Ship list
	var ship_ids := ["phoenix", "viper", "nebula", "titan", "shadow", "omega"]
	var card_w: float = 250.0
	var card_h: float = 120.0
	var start_x := (vp.x - card_w * 3 - 20 * 2) / 2
	var start_y: float = 80.0
	
	for i in ship_ids.size():
		var ship_id: String = ship_ids[i]
		var stats: Dictionary = GameData.SHIP_STATS[ship_id]
		var ship_data: Dictionary = GameData.ships_data[ship_id]
		var col := i % 3
		var row := i / 3
		var x := start_x + col * (card_w + 20)
		var y := start_y + row * (card_h + 20)
		
		var is_equipped := GameData.equipped_ship == ship_id
		var is_unlocked: bool = ship_data.get("unlocked", false)
		var card_color := stats["color"] if is_unlocked else Color(0.3, 0.3, 0.3)
		var alpha := 1.0 if is_unlocked else 0.4
		
		# Card bg
		draw_rect(Rect2(x, y, card_w, card_h), Color(card_color, 0.05))
		var border := PackedVector2Array([
			Vector2(x, y), Vector2(x + card_w, y), Vector2(x + card_w, y + card_h),
			Vector2(x, y + card_h), Vector2(x, y)
		])
		draw_polyline(border, Color(card_color, 0.3 + (0.4 if is_equipped else 0.0)), 1.5)
		
		# Ship name
		var name_str: String = stats["name"]
		draw_string(font, Vector2(x + 10, y + 22), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(card_color, alpha))
		
		# Stats
		draw_string(font, Vector2(x + 10, y + 42), "SPD: " + str(stats["speed"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, alpha))
		draw_string(font, Vector2(x + 90, y + 42), "FIRE: " + str(stats["fire"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, alpha))
		draw_string(font, Vector2(x + 170, y + 42), "DEF: " + str(stats["shield"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, alpha))
		
		# Status
		if is_equipped:
			draw_string(font, Vector2(x + 10, y + card_h - 15), "✅ EQUIPPED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 0.5))
		elif is_unlocked:
			draw_string(font, Vector2(x + 10, y + card_h - 15), "TAP TO EQUIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 1, 0.6))
		else:
			var price_str := ""
			if stats["price_coins"] > 0:
				price_str = "💰 " + str(stats["price_coins"])
			else:
				price_str = "💎 " + str(stats["price_gems"])
			draw_string(font, Vector2(x + 10, y + card_h - 15), "🔒 " + price_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))

func _handle_hangar_tap(pos: Vector2, vp: Vector2) -> void:
	var ship_ids := ["phoenix", "viper", "nebula", "titan", "shadow", "omega"]
	var card_w: float = 250.0
	var card_h: float = 120.0
	var start_x := (vp.x - card_w * 3 - 20 * 2) / 2
	var start_y: float = 80.0
	
	for i in ship_ids.size():
		var col := i % 3
		var row := i / 3
		var x := start_x + col * (card_w + 20)
		var y := start_y + row * (card_h + 20)
		
		if Rect2(x, y, card_w, card_h).has_point(pos):
			var ship_id: String = ship_ids[i]
			if GameData.ships_data[ship_id]["unlocked"]:
				GameData.equip_ship(ship_id)
			else:
				GameData.unlock_ship(ship_id)

func _draw_upgrades(vp: Vector2, font: Font) -> void:
	var title := "⬆️ UPGRADES"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0, 1, 1))
	
	var upgrade_ids := ["fire_rate", "thrust_power", "shield_duration", "bomb_power", "magnet_range", "extra_life", "extra_bomb", "score_bonus"]
	var card_h: float = 55.0
	var card_w: float = vp.x - 80
	var start_y: float = 70.0
	
	for i in upgrade_ids.size():
		var uid: String = upgrade_ids[i]
		var config: Dictionary = GameData.UPGRADE_CONFIG[uid]
		var level: int = GameData.upgrades.get(uid, 0)
		var max_level: int = config["max"]
		var cost := GameData.get_upgrade_cost(uid)
		var y := start_y + i * (card_h + 8)
		var x: float = 40.0
		
		# Card bg
		draw_rect(Rect2(x, y, card_w, card_h), Color(0.1, 0.1, 0.15, 0.6))
		
		# Icon + Name
		var name_str: String = config["icon"] + " " + config["name"]
		draw_string(font, Vector2(x + 10, y + 20), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.9))
		
		# Level
		var lvl_str := "Lv." + str(level) + "/" + str(max_level)
		draw_string(font, Vector2(x + 200, y + 20), lvl_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 1, 0.7))
		
		# Progress bar
		var bar_x := x + 280
		var bar_w: float = 150.0
		var ratio := float(level) / float(max_level)
		draw_rect(Rect2(bar_x, y + 10, bar_w, 10), Color(0.2, 0.2, 0.2, 0.5))
		draw_rect(Rect2(bar_x, y + 10, bar_w * ratio, 10), Color(0, 1, 1, 0.6))
		
		# Effect
		var eff: String = config["effect"]
		draw_string(font, Vector2(x + 10, y + 42), eff, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
		
		# Cost / Max button
		if level >= max_level:
			draw_string(font, Vector2(x + card_w - 80, y + 35), "MAX", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.2))
		else:
			var cost_str := "💰 " + str(cost)
			var can_afford := GameData.total_coins >= cost
			var cost_color := Color(0.2, 1, 0.4) if can_afford else Color(0.5, 0.5, 0.5)
			draw_string(font, Vector2(x + card_w - 100, y + 35), cost_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, cost_color)

func _handle_upgrade_tap(pos: Vector2, vp: Vector2) -> void:
	var upgrade_ids := ["fire_rate", "thrust_power", "shield_duration", "bomb_power", "magnet_range", "extra_life", "extra_bomb", "score_bonus"]
	var card_h: float = 55.0
	var start_y: float = 70.0
	var card_w := vp.x - 80
	
	for i in upgrade_ids.size():
		var y := start_y + i * (card_h + 8)
		if Rect2(40, y, card_w, card_h).has_point(pos):
			GameData.buy_upgrade(upgrade_ids[i])

func _draw_pass(vp: Vector2, font: Font) -> void:
	var title := "🎫 GALACTIC PASS"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0.6, 0.3, 1))
	draw_string(font, Vector2(vp.x / 2 - 80, vp.y / 2), "Coming Soon...", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.5, 0.5, 0.5))

func _draw_missions(vp: Vector2, font: Font) -> void:
	var title := "🎯 MISSIONS"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1, 0.8, 0))
	draw_string(font, Vector2(vp.x / 2 - 80, vp.y / 2), "Coming Soon...", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.5, 0.5, 0.5))

func _draw_shop(vp: Vector2, font: Font) -> void:
	var title := "🛒 SHOP"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0, 1, 0.5))
	draw_string(font, Vector2(vp.x / 2 - 80, vp.y / 2), "Coming Soon...", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.5, 0.5, 0.5))
