extends Control
## Main Menu / Hub — ship preview, play button, navigation to sub-screens.

var ship_rotation: float = 0.0
var play_glow: float = 0.0
var selected_tab: int = -1  # -1 = hub, 0=hangar, 1=upgrade, 2=pass, 3=mission, 4=shop
var star_bg: Array[Dictionary] = []
var settings_screen: Control = null
var daily_reward: Control = null
var missions_screen: Control = null
var shop_screen: Control = null
var battle_pass_screen: Control = null
var leaderboard_screen: Control = null
var achievements_screen: Control = null

func _ready() -> void:
	_generate_stars()
	# Create settings screen
	settings_screen = load("res://scenes/menu/settings_screen.gd").new()
	settings_screen.anchors_preset = Control.PRESET_FULL_RECT
	settings_screen.anchor_right = 1.0
	settings_screen.anchor_bottom = 1.0
	add_child(settings_screen)
	
	# Create daily reward popup
	daily_reward = load("res://scenes/menu/daily_reward.gd").new()
	daily_reward.anchors_preset = Control.PRESET_FULL_RECT
	daily_reward.anchor_right = 1.0
	daily_reward.anchor_bottom = 1.0
	add_child(daily_reward)
	
	# Create missions screen
	missions_screen = load("res://scenes/menu/missions_screen.gd").new()
	missions_screen.anchors_preset = Control.PRESET_FULL_RECT
	missions_screen.anchor_right = 1.0
	missions_screen.anchor_bottom = 1.0
	missions_screen.visible = false
	add_child(missions_screen)
	
	# Create shop screen
	shop_screen = load("res://scenes/menu/shop_screen.gd").new()
	shop_screen.anchors_preset = Control.PRESET_FULL_RECT
	shop_screen.anchor_right = 1.0
	shop_screen.anchor_bottom = 1.0
	shop_screen.visible = false
	add_child(shop_screen)
	
	# Create battle pass screen
	battle_pass_screen = load("res://scenes/menu/battle_pass_screen.gd").new()
	battle_pass_screen.anchors_preset = Control.PRESET_FULL_RECT
	battle_pass_screen.anchor_right = 1.0
	battle_pass_screen.anchor_bottom = 1.0
	battle_pass_screen.visible = false
	add_child(battle_pass_screen)
	
	# Create leaderboard screen
	leaderboard_screen = load("res://scenes/menu/leaderboard_screen.gd").new()
	leaderboard_screen.anchors_preset = Control.PRESET_FULL_RECT
	leaderboard_screen.anchor_right = 1.0
	leaderboard_screen.anchor_bottom = 1.0
	leaderboard_screen.visible = false
	add_child(leaderboard_screen)
	
	# Create achievements screen
	achievements_screen = load("res://scenes/menu/achievements_screen.gd").new()
	achievements_screen.anchors_preset = Control.PRESET_FULL_RECT
	achievements_screen.anchor_right = 1.0
	achievements_screen.anchor_bottom = 1.0
	achievements_screen.visible = false
	add_child(achievements_screen)
	
	# Check achievements on menu load
	if achievements_screen.has_method("check_achievements"):
		achievements_screen.check_achievements()
	
	# Auto-show daily reward if unclaimed
	if daily_reward.has_method("can_claim") and daily_reward.can_claim():
		daily_reward.show_popup()

func _generate_stars() -> void:
	var vp := ScreenWrap.get_viewport_size()
	for i in 100:
		star_bg.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
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
			_hide_subscreens()
			selected_tab = -1
			return
		
		# Handle sub-screen taps
		if selected_tab == 1:  # Upgrades
			_handle_upgrade_tap(pos, vp)
		elif selected_tab == 0:  # Hangar
			_handle_hangar_tap(pos, vp)
		return
	
	# Settings gear (top-right)
	if pos.x > vp.x - 60 and pos.y < 50:
		if settings_screen and settings_screen.has_method("show_settings"):
			settings_screen.show_settings()
		return
	
	# PLAY button area (center, pill-shaped)
	var play_w: float = 260.0
	var play_h: float = 55.0
	var play_rect := Rect2((vp.x - play_w) / 2, vp.y * 0.60, play_w, play_h)
	if play_rect.has_point(pos):
		_start_game()
		return
	
	# Leaderboard button
	var btn_w: float = 165.0
	var btn_h: float = 42.0
	var gap: float = 12.0
	var total_w := btn_w * 2 + gap
	var btn_y := vp.y * 0.74
	var lb_x := (vp.x - total_w) / 2
	var lb_rect := Rect2(lb_x, btn_y, btn_w, btn_h)
	if lb_rect.has_point(pos):
		_hide_subscreens()
		if leaderboard_screen:
			leaderboard_screen.visible = not leaderboard_screen.visible
		if achievements_screen:
			achievements_screen.visible = false
		return
	
	# Achievements button
	var ach_x := lb_x + btn_w + gap
	var ach_rect := Rect2(ach_x, btn_y, btn_w, btn_h)
	if ach_rect.has_point(pos):
		_hide_subscreens()
		if achievements_screen:
			achievements_screen.visible = not achievements_screen.visible
		if leaderboard_screen:
			leaderboard_screen.visible = false
		return
	
	# Bottom nav tabs (70px height)
	var tab_y := vp.y - 70
	if pos.y > tab_y:
		var tab_width := vp.x / 5.0
		var tab_idx := int(pos.x / tab_width)
		if tab_idx >= 0 and tab_idx < 5:
			selected_tab = tab_idx

func _hide_subscreens() -> void:
	if missions_screen:
		missions_screen.visible = false
	if shop_screen:
		shop_screen.visible = false
	if battle_pass_screen:
		battle_pass_screen.visible = false
	if leaderboard_screen:
		leaderboard_screen.visible = false
	if achievements_screen:
		achievements_screen.visible = false

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _draw() -> void:
	var vp := get_viewport_rect().size
	var time := Time.get_ticks_msec() / 1000.0
	var font := ThemeDB.fallback_font
	
	# Background
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.02, 0.04))
	
	# Nebula gradient
	_draw_nebula_gradient(vp)
	
	# Stars
	for star in star_bg:
		var twinkle := 0.4 + 0.6 * sin(time * star["speed"] + star["offset"])
		var spos: Vector2 = star["pos"]
		draw_circle(spos, star["size"], Color(1, 1, 1, star["brightness"] * twinkle))
	
	# Hex grid
	_draw_hex_grid(vp, time)
	
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
	# Frosted glass top bar
	draw_rect(Rect2(0, 0, vp.x, 50), Color(0.02, 0.02, 0.06, 0.85))
	draw_line(Vector2(0, 50), Vector2(vp.x, 50), Color(0.2, 0.4, 0.5, 0.3), 1.0)
	
	# Coins — gold circle badge + amount
	var coin_x: float = 20.0
	draw_circle(Vector2(coin_x + 15, 25), 13.0, Color(0.3, 0.2, 0, 0.5))
	draw_arc(Vector2(coin_x + 15, 25), 13.0, 0, TAU, 16, Color(1, 0.85, 0.2, 0.5), 1.5, true)
	NeonIcons.draw_coin(self, Vector2(coin_x + 15, 25), 7.0, Color(1, 0.85, 0.2))
	draw_string(font, Vector2(coin_x + 34, 31), str(GameData.total_coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
	
	# Gems — diamond badge + amount
	var gem_x: float = 160.0
	draw_circle(Vector2(gem_x + 15, 25), 13.0, Color(0, 0.1, 0.2, 0.5))
	draw_arc(Vector2(gem_x + 15, 25), 13.0, 0, TAU, 16, Color(0.4, 0.8, 1, 0.5), 1.5, true)
	NeonIcons.draw_gem(self, Vector2(gem_x + 15, 25), 7.0, Color(0.4, 0.8, 1))
	draw_string(font, Vector2(gem_x + 34, 31), str(GameData.gems), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
	
	# Level — right side with shield badge
	var level_text := "LEVEL " + str(GameData.player_level)
	var level_size := font.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var lx := vp.x - level_size.x - 55
	NeonIcons.draw_medal(self, Vector2(lx, 25), 9.0, Color(0, 1, 1, 0.8))
	draw_string(font, Vector2(lx + 18, 31), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 1, 1, 0.9))
	
	# Settings gear far right
	NeonIcons.draw_gear(self, Vector2(vp.x - 30, 25), 11.0, Color(0.5, 0.5, 0.6, 0.6))

func _draw_hex_grid(vp: Vector2, time: float) -> void:
	## Subtle hexagonal grid background
	var hex_size: float = 40.0
	var hex_h := hex_size * 2.0
	var hex_w := sqrt(3.0) * hex_size
	var alpha_base: float = 0.04
	
	for row in int(vp.y / (hex_h * 0.75)) + 2:
		for col in int(vp.x / hex_w) + 2:
			var cx := float(col) * hex_w + (hex_w * 0.5 if row % 2 == 1 else 0.0)
			var cy := float(row) * hex_h * 0.75
			
			# Distance from center for fading
			var dist := Vector2(cx, cy).distance_to(vp / 2) / (vp.length() / 2)
			var alpha := alpha_base * clampf(1.0 - dist * 0.5, 0.2, 1.0)
			
			# Pulse effect — subtle wave
			alpha += 0.01 * sin(time * 0.5 + cx * 0.01 + cy * 0.01)
			
			var hex_pts := PackedVector2Array()
			for i in 7:
				var angle := float(i) / 6.0 * TAU + PI / 6
				hex_pts.append(Vector2(cx + cos(angle) * hex_size, cy + sin(angle) * hex_size))
			draw_polyline(hex_pts, Color(0.3, 0.5, 0.7, alpha), 0.5, true)

func _draw_nebula_gradient(vp: Vector2) -> void:
	## Subtle purple/blue nebula gradient in background
	# Purple glow right side
	for i in 8:
		var r := 100.0 + float(i) * 40.0
		draw_circle(Vector2(vp.x * 0.85, vp.y * 0.3), r, Color(0.15, 0.05, 0.25, 0.015))
	# Blue glow left side
	for i in 6:
		var r := 80.0 + float(i) * 35.0
		draw_circle(Vector2(vp.x * 0.15, vp.y * 0.7), r, Color(0.05, 0.1, 0.2, 0.015))

func _draw_ship_preview(vp: Vector2, font: Font, time: float) -> void:
	var center := Vector2(vp.x / 2, vp.y * 0.33)
	var ship_color: Color = GameData.get_ship_color()
	var s: float = 55.0  # Bigger ship
	var rot := ship_rotation
	
	# === Detailed wireframe ship ===
	# Main body
	var body := PackedVector2Array()
	var body_raw := [
		Vector2(0, -s * 1.2),          # Nose tip
		Vector2(-s * 0.12, -s * 0.9),  # Nose left
		Vector2(-s * 0.2, -s * 0.4),   # Cockpit left
		Vector2(-s * 0.25, -s * 0.1),  # Body middle left
		Vector2(-s * 0.22, s * 0.3),   # Body lower left
		Vector2(-s * 0.18, s * 0.6),   # Tail left
		Vector2(-s * 0.1, s * 0.7),    # Tail inner left
		Vector2(0, s * 0.55),           # Tail center
		Vector2(s * 0.1, s * 0.7),     # Tail inner right
		Vector2(s * 0.18, s * 0.6),    # Tail right
		Vector2(s * 0.22, s * 0.3),    # Body lower right
		Vector2(s * 0.25, -s * 0.1),   # Body middle right
		Vector2(s * 0.2, -s * 0.4),    # Cockpit right
		Vector2(s * 0.12, -s * 0.9),   # Nose right
		Vector2(0, -s * 1.2),          # Close
	]
	for p in body_raw:
		body.append(center + p.rotated(rot))
	
	# Left wing
	var lwing := PackedVector2Array()
	var lwing_raw := [
		Vector2(-s * 0.25, -s * 0.1),
		Vector2(-s * 0.7, s * 0.3),
		Vector2(-s * 0.8, s * 0.5),
		Vector2(-s * 0.65, s * 0.55),
		Vector2(-s * 0.22, s * 0.3),
	]
	for p in lwing_raw:
		lwing.append(center + p.rotated(rot))
	
	# Right wing
	var rwing := PackedVector2Array()
	var rwing_raw := [
		Vector2(s * 0.25, -s * 0.1),
		Vector2(s * 0.7, s * 0.3),
		Vector2(s * 0.8, s * 0.5),
		Vector2(s * 0.65, s * 0.55),
		Vector2(s * 0.22, s * 0.3),
	]
	for p in rwing_raw:
		rwing.append(center + p.rotated(rot))
	
	# Engine pods
	var leng := PackedVector2Array()
	for p in [Vector2(-s * 0.45, s * 0.3), Vector2(-s * 0.5, s * 0.65), Vector2(-s * 0.35, s * 0.65), Vector2(-s * 0.3, s * 0.3)]:
		leng.append(center + p.rotated(rot))
	var reng := PackedVector2Array()
	for p in [Vector2(s * 0.45, s * 0.3), Vector2(s * 0.5, s * 0.65), Vector2(s * 0.35, s * 0.65), Vector2(s * 0.3, s * 0.3)]:
		reng.append(center + p.rotated(rot))
	
	# Cockpit lines
	var cockpit := PackedVector2Array()
	for p in [Vector2(-s * 0.1, -s * 0.6), Vector2(0, -s * 0.8), Vector2(s * 0.1, -s * 0.6), Vector2(0, -s * 0.35), Vector2(-s * 0.1, -s * 0.6)]:
		cockpit.append(center + p.rotated(rot))
	
	# Cross struts (detail lines)
	var strut1_a := center + Vector2(-s * 0.35, s * 0.1).rotated(rot)
	var strut1_b := center + Vector2(-s * 0.6, s * 0.4).rotated(rot)
	var strut2_a := center + Vector2(s * 0.35, s * 0.1).rotated(rot)
	var strut2_b := center + Vector2(s * 0.6, s * 0.4).rotated(rot)
	
	# === Draw with glow layers ===
	# Layer 1: Wide glow
	var glow1 := Color(ship_color, 0.08)
	draw_polyline(body, glow1, 10.0, true)
	draw_polyline(lwing, glow1, 10.0, true)
	draw_polyline(rwing, glow1, 10.0, true)
	
	# Layer 2: Medium glow
	var glow2 := Color(ship_color, 0.2)
	draw_polyline(body, glow2, 4.0, true)
	draw_polyline(lwing, glow2, 4.0, true)
	draw_polyline(rwing, glow2, 4.0, true)
	
	# Layer 3: Sharp lines
	draw_polyline(body, ship_color, 1.5, true)
	draw_polyline(lwing, ship_color, 1.5, true)
	draw_polyline(rwing, ship_color, 1.5, true)
	draw_polyline(leng, Color(ship_color, 0.7), 1.0, true)
	draw_polyline(reng, Color(ship_color, 0.7), 1.0, true)
	draw_polyline(cockpit, Color(ship_color, 0.6), 1.0, true)
	
	# Detail struts
	draw_line(strut1_a, strut1_b, Color(ship_color, 0.3), 0.5)
	draw_line(strut2_a, strut2_b, Color(ship_color, 0.3), 0.5)
	
	# Engine glow dots (pulsing)
	var engine_pulse := 0.5 + 0.5 * sin(time * 4.0)
	var el := center + Vector2(-s * 0.42, s * 0.65).rotated(rot)
	var er := center + Vector2(s * 0.42, s * 0.65).rotated(rot)
	draw_circle(el, 3.0 + engine_pulse * 2.0, Color(ship_color, 0.3 + engine_pulse * 0.3))
	draw_circle(er, 3.0 + engine_pulse * 2.0, Color(ship_color, 0.3 + engine_pulse * 0.3))
	
	# Ship name with glow
	var ship_name: String = ""
	if GameData.equipped_ship in GameData.SHIP_STATS:
		ship_name = GameData.SHIP_STATS[GameData.equipped_ship]["name"].to_upper()
	var name_size := font.get_string_size(ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 22)
	var name_x := (vp.x - name_size.x) / 2
	var name_y := center.y + s * 1.2 + 25
	# Text glow
	draw_string(font, Vector2(name_x, name_y), ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(ship_color, 0.3))
	draw_string(font, Vector2(name_x, name_y), ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(ship_color, 0.9))

func _draw_play_button(vp: Vector2, font: Font, time: float) -> void:
	var btn_w: float = 260.0
	var btn_h: float = 55.0
	var btn_x := (vp.x - btn_w) / 2
	var btn_y := vp.y * 0.60
	var r := btn_h / 2.0  # Pill radius
	var pulse := 0.5 + 0.5 * sin(time * 2.5)
	
	# === Pill-shaped button ===
	# Build pill outline
	var pill := PackedVector2Array()
	# Left semicircle
	for i in 13:
		var angle := PI / 2 + float(i) / 12.0 * PI
		pill.append(Vector2(btn_x + r + cos(angle) * r, btn_y + r + sin(angle) * r))
	# Top line
	pill.append(Vector2(btn_x + btn_w - r, btn_y))
	# Right semicircle
	for i in 13:
		var angle := -PI / 2 + float(i) / 12.0 * PI
		pill.append(Vector2(btn_x + btn_w - r + cos(angle) * r, btn_y + r + sin(angle) * r))
	# Bottom line
	pill.append(Vector2(btn_x + r, btn_y + btn_h))
	pill.append(pill[0])
	
	# Glow layer (wide, pulsing)
	draw_polyline(pill, Color(0, 1, 1, 0.06 + pulse * 0.06), 12.0, true)
	# Fill (dark glass)
	draw_rect(Rect2(btn_x + r, btn_y, btn_w - r * 2, btn_h), Color(0, 0.15, 0.2, 0.5))
	draw_circle(Vector2(btn_x + r, btn_y + r), r, Color(0, 0.15, 0.2, 0.5))
	draw_circle(Vector2(btn_x + btn_w - r, btn_y + r), r, Color(0, 0.15, 0.2, 0.5))
	# Border (bright)
	draw_polyline(pill, Color(0, 1, 1, 0.5 + pulse * 0.3), 2.0, true)
	# Inner bright edge
	draw_polyline(pill, Color(0, 1, 1, 0.15 + pulse * 0.1), 4.0, true)
	
	# Underline glow
	draw_line(Vector2(btn_x + 30, btn_y + btn_h + 4), Vector2(btn_x + btn_w - 30, btn_y + btn_h + 4), Color(0, 1, 1, 0.15 + pulse * 0.1), 3.0)
	
	# Play icon + text
	var play_text := "PLAY"
	var text_size := font.get_string_size(play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	var tx := (vp.x - text_size.x) / 2
	NeonIcons.draw_play(self, Vector2(tx - 24, btn_y + btn_h / 2), 12.0, Color(0, 1, 1))
	# Text glow
	draw_string(font, Vector2(tx, btn_y + 38), play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color(0, 1, 1, 0.4))
	draw_string(font, Vector2(tx, btn_y + 38), play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color(0, 1, 1))

func _draw_best_scores(vp: Vector2, font: Font) -> void:
	# === Glass panel buttons: Leaderboard + Achievements ===
	var btn_w: float = 165.0
	var btn_h: float = 42.0
	var gap: float = 12.0
	var total_w := btn_w * 2 + gap
	var btn_y := vp.y * 0.74
	var lb_x := (vp.x - total_w) / 2
	var ach_x := lb_x + btn_w + gap
	
	# -- Leaderboard button (gold accent) --
	# Glass fill
	draw_rect(Rect2(lb_x, btn_y, btn_w, btn_h), Color(0.12, 0.1, 0.03, 0.5))
	# Border
	draw_rect(Rect2(lb_x, btn_y, btn_w, btn_h), Color(1, 0.85, 0.2, 0.35), false, 1.5)
	# Left accent bar
	draw_rect(Rect2(lb_x, btn_y, 3, btn_h), Color(1, 0.85, 0.2, 0.6))
	# Icon + text
	NeonIcons.draw_trophy(self, Vector2(lb_x + 22, btn_y + btn_h / 2), 9.0, Color(1, 0.85, 0.2, 0.8))
	draw_string(font, Vector2(lb_x + 40, btn_y + 27), "Leaderboard", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.2, 0.85))
	
	# -- Achievements button (purple accent) --
	draw_rect(Rect2(ach_x, btn_y, btn_w, btn_h), Color(0.08, 0.03, 0.12, 0.5))
	draw_rect(Rect2(ach_x, btn_y, btn_w, btn_h), Color(0.6, 0.3, 1, 0.35), false, 1.5)
	draw_rect(Rect2(ach_x, btn_y, 3, btn_h), Color(0.6, 0.3, 1, 0.6))
	NeonIcons.draw_medal(self, Vector2(ach_x + 22, btn_y + btn_h / 2), 9.0, Color(0.6, 0.3, 1, 0.8))
	draw_string(font, Vector2(ach_x + 40, btn_y + 27), "Achievements", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.3, 1, 0.85))

func _draw_nav_bar(vp: Vector2, font: Font) -> void:
	var bar_h: float = 70.0
	var bar_y := vp.y - bar_h
	
	# Frosted glass background
	draw_rect(Rect2(0, bar_y, vp.x, bar_h), Color(0.03, 0.03, 0.06, 0.88))
	# Top border line
	draw_line(Vector2(0, bar_y), Vector2(vp.x, bar_y), Color(0.2, 0.3, 0.4, 0.4), 1.0)
	
	var tab_names := ["Hangar", "Upgrade", "Pass", "Mission", "Shop"]
	var tab_w := vp.x / 5.0
	
	for i in tab_names.size():
		var x := float(i) * tab_w
		var cx := x + tab_w / 2.0
		var is_active := (i == selected_tab)
		var tab_color := Color(0.4, 0.4, 0.5, 0.5)
		var icon_size: float = 10.0
		var label_size_px: int = 12
		
		if is_active:
			tab_color = Color(0, 1, 1, 0.95)
			# Active tab glow background
			draw_rect(Rect2(x + 2, bar_y, tab_w - 4, bar_h), Color(0, 0.2, 0.3, 0.15))
			# Bottom indicator line
			draw_line(Vector2(cx - 20, bar_y + bar_h - 3), Vector2(cx + 20, bar_y + bar_h - 3), Color(0, 1, 1, 0.7), 2.0)
			# Icon glow
			icon_size = 12.0
		
		# Draw icon
		var icon_y := bar_y + 22.0
		match i:
			0: NeonIcons.draw_ship_icon(self, Vector2(cx, icon_y), icon_size, tab_color)
			1: NeonIcons.draw_upgrade_arrow(self, Vector2(cx, icon_y), icon_size, tab_color)
			2: NeonIcons.draw_ticket(self, Vector2(cx, icon_y), icon_size, tab_color)
			3: NeonIcons.draw_crosshair(self, Vector2(cx, icon_y), icon_size, tab_color)
			4: NeonIcons.draw_cart(self, Vector2(cx, icon_y), icon_size, tab_color)
		
		# Label
		var label: String = tab_names[i]
		var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, label_size_px)
		draw_string(font, Vector2(cx - ls.x / 2, bar_y + 50), label, HORIZONTAL_ALIGNMENT_CENTER, -1, label_size_px, tab_color)

# === Sub Screens ===
func _draw_sub_screen(vp: Vector2, font: Font, time: float) -> void:
	# Header
	draw_rect(Rect2(0, 0, vp.x, 50), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(20, 35), "← Back", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 1, 1, 0.8))
	NeonIcons.draw_coin(self, Vector2(vp.x - 158, 27), 6.0)
	draw_string(font, Vector2(vp.x - 145, 35), str(GameData.total_coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0.2))
	
	match selected_tab:
		0: _draw_hangar(vp, font, time)
		1: _draw_upgrades(vp, font)
		2: _draw_pass(vp, font)
		3: _draw_missions(vp, font)
		4: _draw_shop(vp, font)
	
	_draw_nav_bar(vp, font)

func _draw_hangar(vp: Vector2, font: Font, time: float) -> void:
	var title := "HANGAR"
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
		var ship_col: Color = stats["color"]
		var card_color: Color = ship_col if is_unlocked else Color(0.3, 0.3, 0.3)
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
			NeonIcons.draw_checkmark(self, Vector2(x + 18, y + card_h - 20), 6.0)
			draw_string(font, Vector2(x + 30, y + card_h - 15), "EQUIPPED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 0.5))
		elif is_unlocked:
			draw_string(font, Vector2(x + 10, y + card_h - 15), "TAP TO EQUIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 1, 1, 0.6))
		else:
			var price_str := ""
			if stats["price_coins"] > 0:
				price_str = str(stats["price_coins"])
				NeonIcons.draw_lock(self, Vector2(x + 18, y + card_h - 20), 6.0)
				NeonIcons.draw_coin(self, Vector2(x + 38, y + card_h - 20), 5.0)
				draw_string(font, Vector2(x + 48, y + card_h - 15), price_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
			else:
				price_str = str(stats["price_gems"])
				NeonIcons.draw_lock(self, Vector2(x + 18, y + card_h - 20), 6.0)
				NeonIcons.draw_gem(self, Vector2(x + 38, y + card_h - 20), 5.0)
				draw_string(font, Vector2(x + 48, y + card_h - 15), price_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))

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
	var title := "UPGRADES"
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
			var can_afford := GameData.total_coins >= cost
			var cost_color := Color(0.2, 1, 0.4) if can_afford else Color(0.5, 0.5, 0.5)
			NeonIcons.draw_coin(self, Vector2(x + card_w - 100, y + 28), 5.0, cost_color)
			draw_string(font, Vector2(x + card_w - 88, y + 35), str(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, cost_color)

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
	var title := "GALACTIC PASS"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0.6, 0.3, 1))
	if battle_pass_screen:
		battle_pass_screen.visible = (selected_tab == 2)

func _draw_missions(vp: Vector2, font: Font) -> void:
	var title := "MISSIONS"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1, 0.8, 0))
	# Show missions sub-screen
	if missions_screen:
		missions_screen.visible = (selected_tab == 3)

func _draw_shop(vp: Vector2, font: Font) -> void:
	var title := "SHOP"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 38), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0, 1, 0.5))
	# Show shop sub-screen
	if shop_screen:
		shop_screen.visible = (selected_tab == 4)
