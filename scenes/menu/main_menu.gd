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
	missions_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	missions_screen.visible = false
	add_child(missions_screen)
	
	# Create shop screen
	shop_screen = load("res://scenes/menu/shop_screen.gd").new()
	shop_screen.anchors_preset = Control.PRESET_FULL_RECT
	shop_screen.anchor_right = 1.0
	shop_screen.anchor_bottom = 1.0
	shop_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_screen.visible = false
	add_child(shop_screen)
	
	# Create battle pass screen
	battle_pass_screen = load("res://scenes/menu/battle_pass_screen.gd").new()
	battle_pass_screen.anchors_preset = Control.PRESET_FULL_RECT
	battle_pass_screen.anchor_right = 1.0
	battle_pass_screen.anchor_bottom = 1.0
	battle_pass_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_pass_screen.visible = false
	add_child(battle_pass_screen)
	
	# Create leaderboard screen
	leaderboard_screen = load("res://scenes/menu/leaderboard_screen.gd").new()
	leaderboard_screen.anchors_preset = Control.PRESET_FULL_RECT
	leaderboard_screen.anchor_right = 1.0
	leaderboard_screen.anchor_bottom = 1.0
	leaderboard_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leaderboard_screen.visible = false
	add_child(leaderboard_screen)
	
	# Create achievements screen
	achievements_screen = load("res://scenes/menu/achievements_screen.gd").new()
	achievements_screen.anchors_preset = Control.PRESET_FULL_RECT
	achievements_screen.anchor_right = 1.0
	achievements_screen.anchor_bottom = 1.0
	achievements_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var sc := vp.y / 1080.0
	for i in 150:
		star_bg.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"size": randf_range(0.5, 2.5) * sc,
			"brightness": randf_range(0.1, 0.4),
			"speed": randf_range(0.5, 2.5),
			"offset": randf() * TAU,
		})

func _process(delta: float) -> void:
	ship_rotation += delta * 0.3
	play_glow += delta * 2.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Only handle MouseButton — Godot auto-translates touch → mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(event.position)

func _handle_touch(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var sc := vp.y / 1080.0
	
	# === Always check nav bar first (works from any screen) ===
	var margin := 16.0 * sc
	var bar_h := 130.0 * sc
	var tab_y := vp.y - bar_h
	if pos.y > tab_y and pos.x > margin and pos.x < vp.x - margin:
		var bw := vp.x - margin * 2
		var tab_width := bw / 5.0
		var tab_idx := int((pos.x - margin) / tab_width)
		if tab_idx >= 0 and tab_idx < 5:
			_hide_subscreens()
			if tab_idx == selected_tab:
				# Tap active tab again → return to hub
				selected_tab = -1
			else:
				selected_tab = tab_idx
		return
	
	# === Sub-screen content taps ===
	if selected_tab >= 0:
		if selected_tab == 1:  # Upgrades
			_handle_upgrade_tap(pos, vp)
		elif selected_tab == 0:  # Hangar
			_handle_hangar_tap(pos, vp)
		return
	
	# === Hub taps ===
	# Settings gear (top-right, inside 90px bar)
	if pos.x > vp.x - 80 * sc and pos.y < 90 * sc:
		if settings_screen and settings_screen.has_method("show_settings"):
			settings_screen.show_settings()
		return
	
	# PLAY button area
	var play_w := 480.0 * sc
	var play_h := 100.0 * sc
	var play_rect := Rect2((vp.x - play_w) / 2, vp.y * 0.59, play_w, play_h)
	if play_rect.has_point(pos):
		_start_game()
		return
	
	# Leaderboard button
	var btn_w := 300.0 * sc
	var btn_h := 75.0 * sc
	var gap := 24.0 * sc
	var total_w := btn_w * 2 + gap
	var btn_y := vp.y * 0.75
	var lb_x := (vp.x - total_w) / 2
	var lb_rect := Rect2(lb_x, btn_y, btn_w, btn_h)
	if lb_rect.has_point(pos):
		_hide_subscreens()
		if leaderboard_screen:
			leaderboard_screen.show_popup()
		return
	
	# Achievements button
	var ach_x := lb_x + btn_w + gap
	var ach_rect := Rect2(ach_x, btn_y, btn_w, btn_h)
	if ach_rect.has_point(pos):
		_hide_subscreens()
		if achievements_screen:
			achievements_screen.show_popup()
		return

func _hide_subscreens() -> void:
	if missions_screen:
		missions_screen.visible = false
	if shop_screen:
		shop_screen.visible = false
	if battle_pass_screen:
		battle_pass_screen.visible = false
	if leaderboard_screen:
		leaderboard_screen.hide_popup()
	if achievements_screen:
		achievements_screen.hide_popup()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _draw() -> void:
	var vp := get_viewport_rect().size
	var time := Time.get_ticks_msec() / 1000.0
	var font := ScreenWrap.neon_font
	
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
	var sc := vp.y / 1080.0
	var bar_h := 90.0 * sc
	
	# === Dark frosted panel background ===
	draw_rect(Rect2(0, 0, vp.x, bar_h), Color(0.015, 0.02, 0.045, 0.92))
	# Top edge accent line (gradient gold -> cyan)
	draw_line(Vector2(0, 0), Vector2(vp.x * 0.3, 0), Color(1, 0.75, 0.1, 0.5), 2.0 * sc)
	draw_line(Vector2(vp.x * 0.3, 0), Vector2(vp.x * 0.7, 0), Color(0, 1, 1, 0.15), 1.0 * sc)
	draw_line(Vector2(vp.x * 0.7, 0), Vector2(vp.x, 0), Color(0, 1, 1, 0.5), 2.0 * sc)
	# Bottom edge
	draw_line(Vector2(0, bar_h), Vector2(vp.x, bar_h), Color(0, 1, 1, 0.15), 1.5 * sc)
	
	var cy := bar_h / 2.0
	var fs := int(36 * sc)
	var badge_r := 26.0 * sc
	var icon_s := 14.0 * sc
	
	# === LEFT PANEL: Coins + Gems bordered area ===
	var left_panel_w := 420.0 * sc
	var left_panel_h := 56.0 * sc
	var left_panel_y := (bar_h - left_panel_h) / 2
	var left_panel_x := 20.0 * sc
	# Panel border
	var lp := PackedVector2Array([
		Vector2(left_panel_x, left_panel_y),
		Vector2(left_panel_x + left_panel_w, left_panel_y),
		Vector2(left_panel_x + left_panel_w, left_panel_y + left_panel_h),
		Vector2(left_panel_x, left_panel_y + left_panel_h),
		Vector2(left_panel_x, left_panel_y)
	])
	draw_rect(Rect2(left_panel_x, left_panel_y, left_panel_w, left_panel_h), Color(0.03, 0.04, 0.08, 0.7))
	draw_polyline(lp, Color(0, 1, 1, 0.2), 1.5 * sc)
	
	# -- Coin badge (gold circle with inner details) --
	var coin_cx := left_panel_x + 40 * sc
	# Outer ring glow
	for g in 3:
		draw_arc(Vector2(coin_cx, cy), badge_r + float(g) * 3 * sc, 0, TAU, 24, Color(1, 0.75, 0.1, 0.04 - float(g) * 0.01), 3.0 * sc, true)
	# Filled gold circle
	draw_circle(Vector2(coin_cx, cy), badge_r, Color(0.35, 0.25, 0.02, 0.8))
	draw_arc(Vector2(coin_cx, cy), badge_r, 0, TAU, 24, Color(1, 0.8, 0.15, 0.9), 2.5 * sc, true)
	# Inner coin detail
	draw_arc(Vector2(coin_cx, cy), badge_r * 0.65, 0, TAU, 16, Color(1, 0.85, 0.2, 0.5), 1.5 * sc, true)
	NeonIcons.draw_coin(self, Vector2(coin_cx, cy), icon_s, Color(1, 0.9, 0.3))
	# Coin amount with glow
	var coin_str := _format_number(GameData.total_coins)
	draw_string(font, Vector2(coin_cx + badge_r + 14 * sc, cy + fs * 0.35), coin_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.5, 0.15))
	draw_string(font, Vector2(coin_cx + badge_r + 14 * sc, cy + fs * 0.35), coin_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.7, 0.95))
	
	# -- Gem badge (purple/blue diamond) --
	var gem_cx := left_panel_x + 245 * sc
	# Glow rings
	for g in 3:
		draw_arc(Vector2(gem_cx, cy), badge_r + float(g) * 3 * sc, 0, TAU, 24, Color(0.5, 0.3, 1, 0.04 - float(g) * 0.01), 3.0 * sc, true)
	# Filled purple circle
	draw_circle(Vector2(gem_cx, cy), badge_r, Color(0.12, 0.05, 0.25, 0.8))
	draw_arc(Vector2(gem_cx, cy), badge_r, 0, TAU, 24, Color(0.55, 0.35, 1, 0.9), 2.5 * sc, true)
	# Inner diamond shape
	var d := badge_r * 0.5
	var diamond := PackedVector2Array([
		Vector2(gem_cx, cy - d), Vector2(gem_cx + d * 0.7, cy),
		Vector2(gem_cx, cy + d), Vector2(gem_cx - d * 0.7, cy),
		Vector2(gem_cx, cy - d)
	])
	draw_polyline(diamond, Color(0.6, 0.4, 1, 0.6), 1.5 * sc)
	NeonIcons.draw_gem(self, Vector2(gem_cx, cy), icon_s, Color(0.6, 0.5, 1))
	# Gem amount with glow
	var gem_str := str(GameData.gems)
	draw_string(font, Vector2(gem_cx + badge_r + 14 * sc, cy + fs * 0.35), gem_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.6, 0.4, 1, 0.15))
	draw_string(font, Vector2(gem_cx + badge_r + 14 * sc, cy + fs * 0.35), gem_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.7, 0.55, 1, 0.95))
	
	# === RIGHT SIDE: Level badge with shield ===
	var level_text := "LEVEL " + str(GameData.player_level)
	var level_size := font.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var right_panel_w := level_size.x + 90 * sc
	var right_panel_x := vp.x - right_panel_w - 20 * sc
	var right_panel_y := (bar_h - left_panel_h) / 2
	# Panel border
	var rp := PackedVector2Array([
		Vector2(right_panel_x, right_panel_y),
		Vector2(right_panel_x + right_panel_w, right_panel_y),
		Vector2(right_panel_x + right_panel_w, right_panel_y + left_panel_h),
		Vector2(right_panel_x, right_panel_y + left_panel_h),
		Vector2(right_panel_x, right_panel_y)
	])
	draw_rect(Rect2(right_panel_x, right_panel_y, right_panel_w, left_panel_h), Color(0.03, 0.04, 0.08, 0.7))
	draw_polyline(rp, Color(0, 1, 1, 0.2), 1.5 * sc)
	# Shield icon
	var shield_cx := right_panel_x + 35 * sc
	NeonIcons.draw_shield(self, Vector2(shield_cx, cy), 18.0 * sc, Color(0, 1, 1, 0.8))
	# Level text with glow
	var lt_x := shield_cx + 32 * sc
	draw_string(font, Vector2(lt_x, cy + fs * 0.35), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 1, 1, 0.12))
	draw_string(font, Vector2(lt_x, cy + fs * 0.35), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 1, 1, 0.95))
	
	# Settings gear (separate, far right) — only if there's space
	var gear_x := vp.x - 50 * sc
	if gear_x > right_panel_x + right_panel_w + 20 * sc:
		NeonIcons.draw_gear(self, Vector2(gear_x, cy), 20.0 * sc, Color(0, 1, 1, 0.5))

func _format_number(n: int) -> String:
	if n >= 1000000:
		@warning_ignore("integer_division")
		return str(n / 1000000) + "." + str((n % 1000000) / 100000) + "M"
	elif n >= 1000:
		@warning_ignore("integer_division")
		return str(n / 1000) + "," + str(n % 1000).pad_zeros(3)
	return str(n)

func _draw_hex_grid(vp: Vector2, time: float) -> void:
	## Subtle hexagonal grid background
	var sc := vp.y / 1080.0
	var hex_size := 65.0 * sc
	var hex_h := hex_size * 2.0
	var hex_w := sqrt(3.0) * hex_size
	var alpha_base: float = 0.035
	
	for row in int(vp.y / (hex_h * 0.75)) + 2:
		for col in int(vp.x / hex_w) + 2:
			var cx := float(col) * hex_w + (hex_w * 0.5 if row % 2 == 1 else 0.0)
			var cy := float(row) * hex_h * 0.75
			
			# Distance from center for fading — stronger fade
			var dist := Vector2(cx, cy).distance_to(vp / 2) / (vp.length() / 2)
			var alpha := alpha_base * clampf(1.0 - dist * 0.7, 0.1, 1.0)
			
			var hex_pts := PackedVector2Array()
			for i in 7:
				var angle := float(i) / 6.0 * TAU + PI / 6
				hex_pts.append(Vector2(cx + cos(angle) * hex_size, cy + sin(angle) * hex_size))
			draw_polyline(hex_pts, Color(0.3, 0.5, 0.7, alpha), 1.0 * sc, true)

func _draw_nebula_gradient(vp: Vector2) -> void:
	## Subtle purple/blue nebula gradient in background
	var sc := vp.y / 1080.0
	# Purple glow right side
	for i in 12:
		var r := (150.0 + float(i) * 60.0) * sc
		draw_circle(Vector2(vp.x * 0.85, vp.y * 0.3), r, Color(0.15, 0.05, 0.25, 0.012))
	# Blue glow left side
	for i in 10:
		var r := (120.0 + float(i) * 50.0) * sc
		draw_circle(Vector2(vp.x * 0.15, vp.y * 0.7), r, Color(0.05, 0.1, 0.2, 0.012))

func _draw_ship_preview(vp: Vector2, font: Font, time: float) -> void:
	var sc := vp.y / 1080.0
	var center := Vector2(vp.x / 2, vp.y * 0.32)
	var ship_color: Color = GameData.get_ship_color()
	var s := 120.0 * sc  # Large ship for 1080p
	var rot := ship_rotation
	
	# === Detailed wireframe ship ===
	var body := PackedVector2Array()
	var body_raw := [
		Vector2(0, -s * 1.2), Vector2(-s * 0.12, -s * 0.9), Vector2(-s * 0.2, -s * 0.4),
		Vector2(-s * 0.25, -s * 0.1), Vector2(-s * 0.22, s * 0.3), Vector2(-s * 0.18, s * 0.6),
		Vector2(-s * 0.1, s * 0.7), Vector2(0, s * 0.55), Vector2(s * 0.1, s * 0.7),
		Vector2(s * 0.18, s * 0.6), Vector2(s * 0.22, s * 0.3), Vector2(s * 0.25, -s * 0.1),
		Vector2(s * 0.2, -s * 0.4), Vector2(s * 0.12, -s * 0.9), Vector2(0, -s * 1.2),
	]
	for p in body_raw:
		body.append(center + p.rotated(rot))
	
	var lwing := PackedVector2Array()
	for p in [Vector2(-s*0.25,-s*0.1), Vector2(-s*0.7,s*0.3), Vector2(-s*0.8,s*0.5), Vector2(-s*0.65,s*0.55), Vector2(-s*0.22,s*0.3)]:
		lwing.append(center + p.rotated(rot))
	var rwing := PackedVector2Array()
	for p in [Vector2(s*0.25,-s*0.1), Vector2(s*0.7,s*0.3), Vector2(s*0.8,s*0.5), Vector2(s*0.65,s*0.55), Vector2(s*0.22,s*0.3)]:
		rwing.append(center + p.rotated(rot))
	
	# Engine pods
	var leng := PackedVector2Array()
	for p in [Vector2(-s*0.45,s*0.3), Vector2(-s*0.5,s*0.65), Vector2(-s*0.35,s*0.65), Vector2(-s*0.3,s*0.3)]:
		leng.append(center + p.rotated(rot))
	var reng := PackedVector2Array()
	for p in [Vector2(s*0.45,s*0.3), Vector2(s*0.5,s*0.65), Vector2(s*0.35,s*0.65), Vector2(s*0.3,s*0.3)]:
		reng.append(center + p.rotated(rot))
	
	# Cockpit
	var cockpit := PackedVector2Array()
	for p in [Vector2(-s*0.1,-s*0.6), Vector2(0,-s*0.8), Vector2(s*0.1,-s*0.6), Vector2(0,-s*0.35), Vector2(-s*0.1,-s*0.6)]:
		cockpit.append(center + p.rotated(rot))
	
	# Struts
	var s1a := center + Vector2(-s*0.35,s*0.1).rotated(rot)
	var s1b := center + Vector2(-s*0.6,s*0.4).rotated(rot)
	var s2a := center + Vector2(s*0.35,s*0.1).rotated(rot)
	var s2b := center + Vector2(s*0.6,s*0.4).rotated(rot)
	
	# Additional detail lines for depth
	var spine_a := center + Vector2(0,-s*0.9).rotated(rot)
	var spine_b := center + Vector2(0,s*0.5).rotated(rot)
	var cross_a := center + Vector2(-s*0.2,s*0.0).rotated(rot)
	var cross_b := center + Vector2(s*0.2,s*0.0).rotated(rot)
	
	# === Draw with glow layers ===
	var lw := sc  # Line width scale
	# Layer 1: Wide glow
	var glow1 := Color(ship_color, 0.06)
	draw_polyline(body, glow1, 18.0 * lw, true)
	draw_polyline(lwing, glow1, 18.0 * lw, true)
	draw_polyline(rwing, glow1, 18.0 * lw, true)
	
	# Layer 2: Medium glow
	var glow2 := Color(ship_color, 0.15)
	draw_polyline(body, glow2, 6.0 * lw, true)
	draw_polyline(lwing, glow2, 6.0 * lw, true)
	draw_polyline(rwing, glow2, 6.0 * lw, true)
	
	# Layer 3: Sharp lines
	draw_polyline(body, ship_color, 2.5 * lw, true)
	draw_polyline(lwing, ship_color, 2.5 * lw, true)
	draw_polyline(rwing, ship_color, 2.5 * lw, true)
	draw_polyline(leng, Color(ship_color, 0.7), 2.0 * lw, true)
	draw_polyline(reng, Color(ship_color, 0.7), 2.0 * lw, true)
	draw_polyline(cockpit, Color(ship_color, 0.6), 1.5 * lw, true)
	
	# Detail lines
	draw_line(s1a, s1b, Color(ship_color, 0.25), 1.0 * lw)
	draw_line(s2a, s2b, Color(ship_color, 0.25), 1.0 * lw)
	draw_line(spine_a, spine_b, Color(ship_color, 0.15), 1.0 * lw)
	draw_line(cross_a, cross_b, Color(ship_color, 0.15), 1.0 * lw)
	
	# Engine glow dots (pulsing)
	var engine_pulse := 0.5 + 0.5 * sin(time * 4.0)
	var el := center + Vector2(-s*0.42, s*0.65).rotated(rot)
	var er := center + Vector2(s*0.42, s*0.65).rotated(rot)
	draw_circle(el, (5.0 + engine_pulse * 4.0) * sc, Color(ship_color, 0.3 + engine_pulse * 0.3))
	draw_circle(er, (5.0 + engine_pulse * 4.0) * sc, Color(ship_color, 0.3 + engine_pulse * 0.3))
	
	# Ship name with glow
	var ship_name: String = ""
	if GameData.equipped_ship in GameData.SHIP_STATS:
		ship_name = GameData.SHIP_STATS[GameData.equipped_ship]["name"].to_upper()
	var name_fs := int(38 * sc)
	var name_size := font.get_string_size(ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, name_fs)
	var name_x := (vp.x - name_size.x) / 2
	var name_y := center.y + s * 1.0 + 40 * sc
	# Text glow
	draw_string(font, Vector2(name_x, name_y), ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, name_fs, Color(ship_color, 0.3))
	draw_string(font, Vector2(name_x, name_y), ship_name, HORIZONTAL_ALIGNMENT_CENTER, -1, name_fs, Color(ship_color, 0.9))

func _draw_play_button(vp: Vector2, font: Font, time: float) -> void:
	var sc := vp.y / 1080.0
	var btn_w := 480.0 * sc
	var btn_h := 100.0 * sc
	var btn_x := (vp.x - btn_w) / 2
	var btn_y := vp.y * 0.59
	var r := btn_h / 2.0
	var pulse := 0.5 + 0.5 * sin(time * 2.5)
	
	# === Premium pill-shaped button ===
	var pill := PackedVector2Array()
	for i in 17:
		var angle := PI / 2 + float(i) / 16.0 * PI
		pill.append(Vector2(btn_x + r + cos(angle) * r, btn_y + r + sin(angle) * r))
	pill.append(Vector2(btn_x + btn_w - r, btn_y))
	for i in 17:
		var angle := -PI / 2 + float(i) / 16.0 * PI
		pill.append(Vector2(btn_x + btn_w - r + cos(angle) * r, btn_y + r + sin(angle) * r))
	pill.append(Vector2(btn_x + r, btn_y + btn_h))
	pill.append(pill[0])
	
	# Layer 1: Outer glow (wide, soft)
	draw_polyline(pill, Color(0, 1, 1, 0.04 + pulse * 0.04), 24.0 * sc, true)
	# Layer 2: Mid glow
	draw_polyline(pill, Color(0, 1, 1, 0.08 + pulse * 0.06), 12.0 * sc, true)
	
	# Fill — dark tinted glass
	draw_rect(Rect2(btn_x + r, btn_y + 2*sc, btn_w - r * 2, btn_h - 4*sc), Color(0, 0.12, 0.18, 0.65))
	draw_circle(Vector2(btn_x + r, btn_y + r), r - 2*sc, Color(0, 0.12, 0.18, 0.65))
	draw_circle(Vector2(btn_x + btn_w - r, btn_y + r), r - 2*sc, Color(0, 0.12, 0.18, 0.65))
	
	# Inner highlight (top edge shine)
	var shine_pts := PackedVector2Array()
	for i in 17:
		var angle := PI / 2 + float(i) / 16.0 * PI
		shine_pts.append(Vector2(btn_x + r + cos(angle) * (r - 4*sc), btn_y + r + sin(angle) * (r - 4*sc)))
	shine_pts.append(Vector2(btn_x + btn_w - r, btn_y + 4*sc))
	for i in 5:
		var angle := -PI / 2 + float(i) / 16.0 * PI
		shine_pts.append(Vector2(btn_x + btn_w - r + cos(angle) * (r - 4*sc), btn_y + r + sin(angle) * (r - 4*sc)))
	draw_polyline(shine_pts, Color(0.4, 0.9, 1, 0.12 + pulse * 0.06), 1.5 * sc, true)
	
	# Main border (thick, glowing)
	draw_polyline(pill, Color(0, 0.85, 0.9, 0.55 + pulse * 0.25), 3.5 * sc, true)
	# Inner border (thin)
	var inner_pill := PackedVector2Array()
	var ir := r - 5 * sc
	for i in 17:
		var angle := PI / 2 + float(i) / 16.0 * PI
		inner_pill.append(Vector2(btn_x + r + cos(angle) * ir, btn_y + r + sin(angle) * ir))
	inner_pill.append(Vector2(btn_x + btn_w - r, btn_y + (r - ir)))
	for i in 17:
		var angle := -PI / 2 + float(i) / 16.0 * PI
		inner_pill.append(Vector2(btn_x + btn_w - r + cos(angle) * ir, btn_y + r + sin(angle) * ir))
	inner_pill.append(Vector2(btn_x + r, btn_y + r + ir))
	inner_pill.append(inner_pill[0])
	draw_polyline(inner_pill, Color(0, 1, 1, 0.15), 1.5 * sc, true)
	
	# Bottom underline glow
	draw_line(Vector2(btn_x + 40*sc, btn_y + btn_h + 8*sc), Vector2(btn_x + btn_w - 40*sc, btn_y + btn_h + 8*sc), Color(0, 1, 1, 0.08 + pulse * 0.06), 5.0 * sc)
	
	# Play icon + text (larger, bolder)
	var play_fs := int(54 * sc)
	var play_text := "PLAY"
	var text_size := font.get_string_size(play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, play_fs)
	var tx := (vp.x - text_size.x) / 2 + 15 * sc
	# Play triangle icon
	NeonIcons.draw_play(self, Vector2(tx - 50*sc, btn_y + btn_h / 2), 24.0 * sc, Color(0, 1, 1, 0.9))
	# Text glow layer
	draw_string(font, Vector2(tx, btn_y + btn_h / 2 + play_fs * 0.35), play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, play_fs, Color(0, 1, 1, 0.3))
	# Main text
	draw_string(font, Vector2(tx, btn_y + btn_h / 2 + play_fs * 0.35), play_text, HORIZONTAL_ALIGNMENT_CENTER, -1, play_fs, Color(0.85, 1, 1))

func _draw_best_scores(vp: Vector2, font: Font) -> void:
	var sc := vp.y / 1080.0
	# === Premium glass panel buttons ===
	var btn_w := 300.0 * sc
	var btn_h := 75.0 * sc
	var gap := 24.0 * sc
	var total_w := btn_w * 2 + gap
	var btn_y := vp.y * 0.75
	var lb_x := (vp.x - total_w) / 2
	var ach_x := lb_x + btn_w + gap
	var fs := int(26 * sc)
	var icon_s := 18.0 * sc
	
	# -- Leaderboard button (gold accent, glass panel) --
	# Background
	draw_rect(Rect2(lb_x, btn_y, btn_w, btn_h), Color(0.1, 0.08, 0.02, 0.5))
	# Border with glow
	var lb_border := PackedVector2Array([
		Vector2(lb_x, btn_y), Vector2(lb_x + btn_w, btn_y),
		Vector2(lb_x + btn_w, btn_y + btn_h), Vector2(lb_x, btn_y + btn_h), Vector2(lb_x, btn_y)
	])
	draw_polyline(lb_border, Color(1, 0.8, 0.15, 0.12), 5.0 * sc)
	draw_polyline(lb_border, Color(1, 0.8, 0.15, 0.45), 2.0 * sc)
	# Left accent bar
	draw_rect(Rect2(lb_x, btn_y, 4*sc, btn_h), Color(1, 0.8, 0.15, 0.7))
	# Trophy icon (larger)
	NeonIcons.draw_trophy(self, Vector2(lb_x + 40*sc, btn_y + btn_h / 2), icon_s, Color(1, 0.85, 0.2, 0.9))
	# Text with glow
	draw_string(font, Vector2(lb_x + 68*sc, btn_y + btn_h/2 + fs*0.35), "Leaderboard", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.85, 0.2, 0.15))
	draw_string(font, Vector2(lb_x + 68*sc, btn_y + btn_h/2 + fs*0.35), "Leaderboard", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.9, 0.5, 0.9))
	
	# -- Achievements button (purple accent, glass panel) --
	draw_rect(Rect2(ach_x, btn_y, btn_w, btn_h), Color(0.06, 0.02, 0.1, 0.5))
	var ach_border := PackedVector2Array([
		Vector2(ach_x, btn_y), Vector2(ach_x + btn_w, btn_y),
		Vector2(ach_x + btn_w, btn_y + btn_h), Vector2(ach_x, btn_y + btn_h), Vector2(ach_x, btn_y)
	])
	draw_polyline(ach_border, Color(0.55, 0.3, 1, 0.12), 5.0 * sc)
	draw_polyline(ach_border, Color(0.55, 0.3, 1, 0.45), 2.0 * sc)
	draw_rect(Rect2(ach_x, btn_y, 4*sc, btn_h), Color(0.55, 0.3, 1, 0.7))
	NeonIcons.draw_medal(self, Vector2(ach_x + 40*sc, btn_y + btn_h / 2), icon_s, Color(0.6, 0.35, 1, 0.9))
	draw_string(font, Vector2(ach_x + 68*sc, btn_y + btn_h/2 + fs*0.35), "Achievements", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.55, 0.3, 1, 0.15))
	draw_string(font, Vector2(ach_x + 68*sc, btn_y + btn_h/2 + fs*0.35), "Achievements", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.7, 0.5, 1, 0.9))

func _draw_nav_bar(vp: Vector2, font: Font) -> void:
	var sc := vp.y / 1080.0
	var bar_h := 130.0 * sc
	var bar_y := vp.y - bar_h
	var margin := 16.0 * sc
	
	# === Frosted glass panel with border ===
	# Background fill
	draw_rect(Rect2(margin, bar_y, vp.x - margin * 2, bar_h - margin / 2), Color(0.02, 0.025, 0.06, 0.9))
	
	# Panel border (rounded feel with corner accents)
	var bx := margin
	var by := bar_y
	var bw := vp.x - margin * 2
	var bh := bar_h - margin / 2
	var nav_border := PackedVector2Array([
		Vector2(bx, by), Vector2(bx + bw, by),
		Vector2(bx + bw, by + bh), Vector2(bx, by + bh), Vector2(bx, by)
	])
	# Outer glow
	draw_polyline(nav_border, Color(0, 1, 1, 0.08), 6.0 * sc)
	# Main border
	draw_polyline(nav_border, Color(0, 1, 1, 0.35), 2.0 * sc)
	
	# Top accent line (gold gradient for premium feel)
	var accent_w := bw * 0.6
	var accent_x := bx + (bw - accent_w) / 2
	draw_line(Vector2(accent_x, by), Vector2(accent_x + accent_w * 0.3, by), Color(1, 0.75, 0.1, 0.5), 2.5 * sc)
	draw_line(Vector2(accent_x + accent_w * 0.3, by), Vector2(accent_x + accent_w * 0.7, by), Color(1, 0.75, 0.1, 0.2), 2.0 * sc)
	draw_line(Vector2(accent_x + accent_w * 0.7, by), Vector2(accent_x + accent_w, by), Color(1, 0.75, 0.1, 0.5), 2.5 * sc)
	
	# Corner accent dots
	for corner in [Vector2(bx + 4*sc, by + 4*sc), Vector2(bx + bw - 4*sc, by + 4*sc),
				   Vector2(bx + 4*sc, by + bh - 4*sc), Vector2(bx + bw - 4*sc, by + bh - 4*sc)]:
		draw_circle(corner, 2.0 * sc, Color(0, 1, 1, 0.4))
	
	var tab_names := ["Hangar", "Upgrade", "Pass", "Mission", "Shop"]
	var tab_w := bw / 5.0
	
	for i in tab_names.size():
		var x := bx + float(i) * tab_w
		var cx := x + tab_w / 2.0
		var is_active := (i == selected_tab)
		var tab_color := Color(0.45, 0.5, 0.6, 0.55)
		var icon_s := 22.0 * sc
		var label_fs := int(22 * sc)
		
		if is_active:
			tab_color = Color(0, 1, 1, 1.0)
			icon_s = 26.0 * sc
			
			# === Active tab highlight box ===
			var tab_pad := 6.0 * sc
			var tab_box_x := x + tab_pad
			var tab_box_y := by + tab_pad
			var tab_box_w := tab_w - tab_pad * 2
			var tab_box_h := bh - tab_pad * 2
			# Highlight fill
			draw_rect(Rect2(tab_box_x, tab_box_y, tab_box_w, tab_box_h), Color(0, 0.15, 0.25, 0.3))
			# Highlight border
			var tb := PackedVector2Array([
				Vector2(tab_box_x, tab_box_y), Vector2(tab_box_x + tab_box_w, tab_box_y),
				Vector2(tab_box_x + tab_box_w, tab_box_y + tab_box_h),
				Vector2(tab_box_x, tab_box_y + tab_box_h), Vector2(tab_box_x, tab_box_y)
			])
			draw_polyline(tb, Color(0, 1, 1, 0.45), 1.5 * sc)
			# Bottom glow line
			draw_line(Vector2(tab_box_x + 15*sc, tab_box_y + tab_box_h), Vector2(tab_box_x + tab_box_w - 15*sc, tab_box_y + tab_box_h), Color(0, 1, 1, 0.6), 2.5 * sc)
		
		# Separator lines between tabs
		if i > 0:
			draw_line(Vector2(x, by + 20*sc), Vector2(x, by + bh - 20*sc), Color(0.3, 0.4, 0.5, 0.15), 1.0 * sc)
		
		# Draw icon (centered, larger)
		var icon_y := by + bh * 0.38
		match i:
			0: NeonIcons.draw_ship_icon(self, Vector2(cx, icon_y), icon_s, tab_color)
			1: NeonIcons.draw_upgrade_arrow(self, Vector2(cx, icon_y), icon_s, tab_color)
			2: NeonIcons.draw_ticket(self, Vector2(cx, icon_y), icon_s, tab_color)
			3: NeonIcons.draw_crosshair(self, Vector2(cx, icon_y), icon_s, tab_color)
			4: NeonIcons.draw_cart(self, Vector2(cx, icon_y), icon_s, tab_color)
		
		# Label (below icon)
		var label: String = tab_names[i]
		var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, label_fs)
		var label_y := by + bh * 0.78
		# Text glow for active
		if is_active:
			draw_string(font, Vector2(cx - ls.x / 2, label_y), label, HORIZONTAL_ALIGNMENT_CENTER, -1, label_fs, Color(0, 1, 1, 0.15))
		draw_string(font, Vector2(cx - ls.x / 2, label_y), label, HORIZONTAL_ALIGNMENT_CENTER, -1, label_fs, tab_color)

# === Sub Screens ===
func _draw_sub_screen(vp: Vector2, font: Font, time: float) -> void:
	# Header (no back button — use nav bar to navigate)
	var sc := vp.y / 1080.0
	var hdr_h := 80.0 * sc
	var hdr_fs := int(28 * sc)
	draw_rect(Rect2(0, 0, vp.x, hdr_h), Color(0, 0, 0, 0.6))
	draw_line(Vector2(0, hdr_h), Vector2(vp.x, hdr_h), Color(0.2, 0.3, 0.4, 0.3), 1.0)
	# Coins on right
	NeonIcons.draw_coin(self, Vector2(vp.x - 250 * sc, hdr_h / 2), 10.0 * sc)
	draw_string(font, Vector2(vp.x - 230 * sc, hdr_h / 2 + hdr_fs * 0.35), str(GameData.total_coins), HORIZONTAL_ALIGNMENT_LEFT, -1, hdr_fs, Color(1, 0.85, 0.2))
	
	match selected_tab:
		0: _draw_hangar(vp, font, time)
		1: _draw_upgrades(vp, font)
		2: _draw_pass(vp, font)
		3: _draw_missions(vp, font)
		4: _draw_shop(vp, font)
	
	_draw_nav_bar(vp, font)

func _draw_hangar(vp: Vector2, font: Font, time: float) -> void:
	var sc := vp.y / 1080.0
	var ship_ids := ["phoenix", "viper", "nebula", "titan", "shadow", "omega"]
	var selected_ship: String = _hangar_selected if _hangar_selected != "" else GameData.equipped_ship
	var stats: Dictionary = GameData.SHIP_STATS[selected_ship]
	var ship_data: Dictionary = GameData.ships_data[selected_ship]
	var ship_col: Color = stats["color"]
	var is_unlocked: bool = ship_data.get("unlocked", false)
	var is_equipped := GameData.equipped_ship == selected_ship
	
	# === Large Ship Preview (center) ===
	var preview_y := vp.y * 0.38
	var preview_size := 170.0 * sc
	var alpha := 1.0 if is_unlocked else 0.35
	var preview_col := Color(ship_col, alpha)
	
	# Rotating glow behind ship
	var glow_r := preview_size * 1.1
	for i in 3:
		var a := time * 0.5 + float(i) * TAU / 3.0
		var gx := vp.x / 2 + cos(a) * glow_r * 0.12
		var gy := preview_y + sin(a) * glow_r * 0.12
		draw_circle(Vector2(gx, gy), glow_r, Color(ship_col, 0.025))
	
	# Ship wireframe
	NeonIcons.draw_ship_by_id(self, selected_ship, Vector2(vp.x / 2, preview_y), preview_size, preview_col, 2.5 * sc)
	
	# Ship name below preview
	var name_str: String = stats["name"]
	var name_fs := int(36 * sc)
	var ns := font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, name_fs)
	draw_string(font, Vector2((vp.x - ns.x) / 2, preview_y + preview_size + 25 * sc), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, name_fs, Color(ship_col, alpha))
	
	# === Stats Bars (left & right of ship) ===
	var bar_w := 220.0 * sc
	var bar_h := 14.0 * sc
	var label_fs := int(15 * sc)
	var left_x := vp.x / 2 - preview_size - bar_w - 20 * sc
	var right_x := vp.x / 2 + preview_size + 20 * sc
	
	# Left: SPEED (centered vertically with ship)
	var sy := preview_y - 25 * sc
	draw_string(font, Vector2(left_x, sy), "SPEED", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(0.5, 0.5, 0.5))
	draw_string(font, Vector2(left_x + bar_w - 50 * sc, sy), str(stats["speed"]) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(0, 1, 1, 0.8))
	draw_rect(Rect2(left_x, sy + 5 * sc, bar_w, bar_h), Color(0.12, 0.12, 0.18, 0.5))
	_draw_stat_bar_segments(left_x, sy + 5 * sc, bar_w, bar_h, float(stats["speed"]) / 100.0, Color(0, 1, 1, 0.7), sc)
	
	# Left: ARMOR
	sy += 55 * sc
	draw_string(font, Vector2(left_x, sy), "ARMOR", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(0.5, 0.5, 0.5))
	draw_string(font, Vector2(left_x + bar_w - 50 * sc, sy), str(stats["shield"]) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(1, 0.8, 0, 0.8))
	draw_rect(Rect2(left_x, sy + 5 * sc, bar_w, bar_h), Color(0.12, 0.12, 0.18, 0.5))
	_draw_stat_bar_segments(left_x, sy + 5 * sc, bar_w, bar_h, float(stats["shield"]) / 100.0, Color(1, 0.8, 0, 0.7), sc)
	
	# Right: FIRE RATE
	sy = preview_y - 25 * sc
	draw_string(font, Vector2(right_x, sy), "FIRE RATE", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(0.5, 0.5, 0.5))
	draw_string(font, Vector2(right_x + bar_w - 50 * sc, sy), str(stats["fire"]) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(1, 0.3, 0.3, 0.8))
	draw_rect(Rect2(right_x, sy + 5 * sc, bar_w, bar_h), Color(0.12, 0.12, 0.18, 0.5))
	_draw_stat_bar_segments(right_x, sy + 5 * sc, bar_w, bar_h, float(stats["fire"]) / 100.0, Color(1, 0.3, 0.3, 0.7), sc)
	
	# Right: SHIELD
	sy += 55 * sc
	draw_string(font, Vector2(right_x, sy), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(0.5, 0.5, 0.5))
	draw_string(font, Vector2(right_x + bar_w - 50 * sc, sy), str(stats["shield"]) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs, Color(0.4, 0.8, 1, 0.8))
	draw_rect(Rect2(right_x, sy + 5 * sc, bar_w, bar_h), Color(0.12, 0.12, 0.18, 0.5))
	_draw_stat_bar_segments(right_x, sy + 5 * sc, bar_w, bar_h, float(stats["shield"]) / 100.0, Color(0.4, 0.8, 1, 0.7), sc)
	
	# === Ship Selection Cards (horizontal strip) ===
	var card_w := 175.0 * sc
	var card_h := 185.0 * sc
	var card_gap := 16.0 * sc
	var total_cards_w := ship_ids.size() * card_w + (ship_ids.size() - 1) * card_gap
	var cards_x := (vp.x - total_cards_w) / 2
	var cards_y := vp.y - 150 * sc - card_h - 60 * sc
	
	for i in ship_ids.size():
		var sid: String = ship_ids[i]
		var s_stats: Dictionary = GameData.SHIP_STATS[sid]
		var s_data: Dictionary = GameData.ships_data[sid]
		var s_col: Color = s_stats["color"]
		var s_unlocked: bool = s_data.get("unlocked", false)
		var s_equipped := GameData.equipped_ship == sid
		var is_selected := sid == selected_ship
		var cx := cards_x + float(i) * (card_w + card_gap)
		
		# Card background
		var card_bg := Color(s_col.r * 0.08, s_col.g * 0.08, s_col.b * 0.08, 0.5) if is_selected else Color(0.04, 0.04, 0.08, 0.6)
		draw_rect(Rect2(cx, cards_y, card_w, card_h), card_bg)
		
		# Card border
		var border_col := Color(s_col, 0.7) if is_selected else Color(0.25, 0.25, 0.35, 0.3)
		var border_w := 2.5 * sc if is_selected else 1.0 * sc
		draw_rect(Rect2(cx, cards_y, card_w, card_h), border_col, false, border_w)
		if is_selected:
			draw_rect(Rect2(cx - 2 * sc, cards_y - 2 * sc, card_w + 4 * sc, card_h + 4 * sc), Color(s_col, 0.08), false, 5.0 * sc)
		
		# Ship thumbnail
		var thumb_size := 30.0 * sc
		var thumb_alpha := 1.0 if s_unlocked else 0.3
		NeonIcons.draw_ship_by_id(self, sid, Vector2(cx + card_w / 2, cards_y + 55 * sc), thumb_size, Color(s_col, thumb_alpha), 1.5 * sc)
		
		# Ship name
		var card_fs := int(14 * sc)
		var s_name: String = s_stats["name"]
		var sns := font.get_string_size(s_name, HORIZONTAL_ALIGNMENT_CENTER, -1, card_fs)
		draw_string(font, Vector2(cx + (card_w - sns.x) / 2, cards_y + 110 * sc), s_name, HORIZONTAL_ALIGNMENT_CENTER, -1, card_fs, Color(1, 1, 1, 0.8 if s_unlocked else 0.35))
		
		# Star rating
		var total_s: int = int(s_stats["speed"]) + int(s_stats["fire"]) + int(s_stats["shield"])
		var n_stars := clampi(1 + int(float(total_s) / 60.0), 1, 5)
		var star_x := cx + (card_w - n_stars * 16 * sc) / 2
		for si in n_stars:
			var ssx := star_x + float(si) * 16 * sc + 8 * sc
			_draw_mini_star(Vector2(ssx, cards_y + 130 * sc), 6.0 * sc, Color(1, 0.85, 0.2, 0.7 if s_unlocked else 0.2))
		
		# Lock / Price / Equipped badge
		if s_equipped:
			var eq_fs := int(12 * sc)
			var eq_str := "EQUIPPED"
			var eqs := font.get_string_size(eq_str, HORIZONTAL_ALIGNMENT_CENTER, -1, eq_fs)
			var ebx := cx + (card_w - eqs.x - 16 * sc) / 2
			draw_rect(Rect2(ebx, cards_y + 148 * sc, eqs.x + 16 * sc, 24 * sc), Color(0, 0.25, 0.15, 0.4))
			draw_rect(Rect2(ebx, cards_y + 148 * sc, eqs.x + 16 * sc, 24 * sc), Color(0, 1, 0.5, 0.4), false, 1.0)
			draw_string(font, Vector2(cx + (card_w - eqs.x) / 2, cards_y + 165 * sc), eq_str, HORIZONTAL_ALIGNMENT_CENTER, -1, eq_fs, Color(0, 1, 0.5))
		elif not s_unlocked:
			NeonIcons.draw_lock(self, Vector2(cx + card_w / 2 - 22 * sc, cards_y + 152 * sc), 7.0 * sc, Color(0.4, 0.4, 0.4))
			var price_fs := int(13 * sc)
			if s_stats["price_coins"] > 0:
				NeonIcons.draw_coin(self, Vector2(cx + card_w / 2 - 3 * sc, cards_y + 155 * sc), 6.0 * sc, Color(1, 0.85, 0.2, 0.5))
				draw_string(font, Vector2(cx + card_w / 2 + 10 * sc, cards_y + 163 * sc), str(s_stats["price_coins"]), HORIZONTAL_ALIGNMENT_LEFT, -1, price_fs, Color(1, 0.85, 0.2, 0.5))
			else:
				NeonIcons.draw_gem(self, Vector2(cx + card_w / 2 - 3 * sc, cards_y + 155 * sc), 6.0 * sc, Color(0.4, 0.8, 1, 0.5))
				draw_string(font, Vector2(cx + card_w / 2 + 10 * sc, cards_y + 163 * sc), str(s_stats["price_gems"]), HORIZONTAL_ALIGNMENT_LEFT, -1, price_fs, Color(0.4, 0.8, 1, 0.5))
	
	# === Bottom Action Button ===
	var btn_w := 350.0 * sc
	var btn_h := 55.0 * sc
	var btn_x := (vp.x - btn_w) / 2
	var btn_y := cards_y + card_h + 10 * sc
	
	if is_equipped:
		draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0, 0.12, 0.08, 0.5))
		draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0, 1, 0.5, 0.5), false, 2.0 * sc)
		var eqfs := int(24 * sc)
		var eq_str := "EQUIPPED"
		var eqs := font.get_string_size(eq_str, HORIZONTAL_ALIGNMENT_CENTER, -1, eqfs)
		draw_string(font, Vector2(btn_x + (btn_w - eqs.x) / 2, btn_y + 37 * sc), eq_str, HORIZONTAL_ALIGNMENT_CENTER, -1, eqfs, Color(0, 1, 0.5))
	elif is_unlocked:
		draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0, 0.15, 0.2, 0.5))
		draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0, 1, 1, 0.5), false, 2.0 * sc)
		var selfs := int(24 * sc)
		var sel_str := "SELECT"
		var sels := font.get_string_size(sel_str, HORIZONTAL_ALIGNMENT_CENTER, -1, selfs)
		draw_string(font, Vector2(btn_x + (btn_w - sels.x) / 2, btn_y + 37 * sc), sel_str, HORIZONTAL_ALIGNMENT_CENTER, -1, selfs, Color(0, 1, 1))
	else:
		draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0.12, 0.08, 0, 0.5))
		draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(1, 0.85, 0.2, 0.5), false, 2.0 * sc)
		var buyfs := int(24 * sc)
		var price_str := "BUY  "
		if stats["price_coins"] > 0:
			price_str += str(stats["price_coins"])
		else:
			price_str += str(stats["price_gems"])
		var buys := font.get_string_size(price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, buyfs)
		draw_string(font, Vector2(btn_x + (btn_w - buys.x) / 2, btn_y + 37 * sc), price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, buyfs, Color(1, 0.85, 0.2))

func _draw_stat_bar_segments(x: float, y: float, w: float, h: float, ratio: float, color: Color, sc: float) -> void:
	var segments := 10
	var seg_gap := 3.0 * sc
	var seg_w := (w - seg_gap * (segments - 1)) / float(segments)
	var filled := int(ratio * segments)
	for i in segments:
		var sx := x + float(i) * (seg_w + seg_gap)
		var seg_col := color if i < filled else Color(0.1, 0.1, 0.15, 0.3)
		draw_rect(Rect2(sx, y, seg_w, h), seg_col)

func _draw_mini_star(pos: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 11:
		var angle := float(i) / 10.0 * TAU - PI / 2
		var r := size if i % 2 == 0 else size * 0.4
		pts.append(pos + Vector2(cos(angle) * r, sin(angle) * r))
	draw_polyline(pts, color, 1.2)

var _hangar_selected: String = ""

func _handle_hangar_tap(pos: Vector2, vp: Vector2) -> void:
	var sc := vp.y / 1080.0
	var ship_ids := ["phoenix", "viper", "nebula", "titan", "shadow", "omega"]
	var card_w := 175.0 * sc
	var card_h := 185.0 * sc
	var card_gap := 16.0 * sc
	var total_cards_w := ship_ids.size() * card_w + (ship_ids.size() - 1) * card_gap
	var cards_x := (vp.x - total_cards_w) / 2
	var cards_y := vp.y - 150 * sc - card_h - 60 * sc
	
	# Check card taps (select ship)
	for i in ship_ids.size():
		var cx := cards_x + float(i) * (card_w + card_gap)
		if Rect2(cx, cards_y, card_w, card_h).has_point(pos):
			_hangar_selected = ship_ids[i]
			return
	
	# Check action button tap
	var btn_w := 350.0 * sc
	var btn_h := 55.0 * sc
	var btn_x := (vp.x - btn_w) / 2
	var btn_y := cards_y + card_h + 10 * sc
	
	if Rect2(btn_x, btn_y, btn_w, btn_h).has_point(pos):
		var selected_ship: String = _hangar_selected if _hangar_selected != "" else GameData.equipped_ship
		if GameData.ships_data[selected_ship]["unlocked"]:
			GameData.equip_ship(selected_ship)
		else:
			GameData.unlock_ship(selected_ship)

func _draw_upgrades(vp: Vector2, font: Font) -> void:
	var sc := vp.y / 1080.0
	var upgrade_ids := ["fire_rate", "thrust_power", "shield_duration", "bomb_power", "magnet_range", "extra_life", "extra_bomb", "score_bonus"]
	
	# Grid: 4 columns × 2 rows
	var cols := 4
	var margin := 40.0 * sc
	var gap := 14.0 * sc
	var card_w := (vp.x - margin * 2 - gap * (cols - 1)) / float(cols)
	var card_h := 200.0 * sc
	var start_y := 95.0 * sc
	var max_y := vp.y - 160 * sc
	
	var fs_name := int(16 * sc)
	var fs_lvl := int(13 * sc)
	var fs_sm := int(11 * sc)
	var fs_btn := int(15 * sc)
	
	for i in upgrade_ids.size():
		var uid: String = upgrade_ids[i]
		var config: Dictionary = GameData.UPGRADE_CONFIG[uid]
		var level: int = GameData.upgrades.get(uid, 0)
		var max_level: int = config["max"]
		var cost := GameData.get_upgrade_cost(uid)
		var is_max := level >= max_level
		var can_afford := GameData.total_coins >= cost
		
		var col := i % cols
		var row := i / cols
		var x := margin + col * (card_w + gap)
		var y := start_y + row * (card_h + gap)
		
		if y + card_h > max_y:
			continue
		
		# Card background
		var bg := Color(0.06, 0.07, 0.12, 0.7)
		draw_rect(Rect2(x, y, card_w, card_h), bg)
		
		# Card border
		var bdr := Color(0, 1, 1, 0.15)
		if is_max:
			bdr = Color(1, 0.85, 0.2, 0.3)
		draw_rect(Rect2(x, y, card_w, card_h), bdr, false, 1.5 * sc)
		
		# Diagonal shine
		draw_line(Vector2(x + card_w * 0.4, y), Vector2(x + card_w, y + card_h * 0.6), Color(1, 1, 1, 0.02), card_w * 0.3)
		
		# Icon (neon circle + symbol)
		var icon_x := x + 40 * sc
		var icon_y := y + 42 * sc
		var icon_r := 22.0 * sc
		draw_circle(Vector2(icon_x, icon_y), icon_r, Color(0.05, 0.08, 0.15, 0.8))
		draw_circle(Vector2(icon_x, icon_y), icon_r, Color(0, 1, 1, 0.3), false, 1.5 * sc)
		_draw_upgrade_icon(uid, Vector2(icon_x, icon_y), icon_r * 0.6, sc)
		
		# Name
		var name_str: String = config["name"]
		draw_string(font, Vector2(icon_x + icon_r + 10 * sc, y + 35 * sc), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_name, Color(1, 1, 1, 0.9))
		
		# Level
		var lvl_str := "Lvl " + str(level)
		draw_string(font, Vector2(icon_x + icon_r + 10 * sc, y + 55 * sc), lvl_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_lvl, Color(0, 1, 1, 0.7))
		
		# MAX badge (top-right corner)
		if is_max:
			var mbx := x + card_w - 42 * sc
			var mby := y + 8 * sc
			draw_circle(Vector2(mbx + 14 * sc, mby + 14 * sc), 16 * sc, Color(1, 0.85, 0.2, 0.15))
			draw_circle(Vector2(mbx + 14 * sc, mby + 14 * sc), 16 * sc, Color(1, 0.85, 0.2, 0.5), false, 1.5 * sc)
			draw_string(font, Vector2(mbx + 2 * sc, mby + 19 * sc), "MAX", HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * sc), Color(1, 0.85, 0.2))
		
		# Segment progress bar
		var bar_x := x + 12 * sc
		var bar_y := y + 78 * sc
		var bar_w := card_w - 24 * sc
		var seg_count := max_level
		var seg_gap := 3.0 * sc
		var seg_w := (bar_w - seg_gap * (seg_count - 1)) / float(seg_count)
		
		for si in seg_count:
			var sx := bar_x + float(si) * (seg_w + seg_gap)
			var seg_col := Color(0, 1, 1, 0.7) if si < level else Color(0.12, 0.12, 0.18, 0.5)
			if is_max and si < level:
				seg_col = Color(1, 0.85, 0.2, 0.7)
			draw_rect(Rect2(sx, bar_y, seg_w, 10 * sc), seg_col)
		
		# Progress text
		var prog_str := str(level) + "/" + str(max_level)
		draw_string(font, Vector2(x + card_w - 55 * sc, bar_y + 25 * sc), prog_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0.5, 0.5, 0.5))
		
		# Effect text
		var eff: String = config["effect"]
		draw_string(font, Vector2(bar_x, bar_y + 27 * sc), eff, HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * sc), Color(0.4, 0.4, 0.4))
		
		# Buy / MAX button
		var btn_x := x + 12 * sc
		var btn_y := y + card_h - 50 * sc
		var btn_w := card_w - 24 * sc
		var btn_h := 38.0 * sc
		
		if is_max:
			draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0.15, 0.12, 0, 0.3))
			draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(1, 0.85, 0.2, 0.3), false, 1.0 * sc)
			var max_str := "MAX"
			var ms := font.get_string_size(max_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fs_btn)
			draw_string(font, Vector2(btn_x + (btn_w - ms.x) / 2, btn_y + 26 * sc), max_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fs_btn, Color(1, 0.85, 0.2, 0.6))
		else:
			var btn_bg := Color(0.1, 0.2, 0.05, 0.5) if can_afford else Color(0.1, 0.1, 0.1, 0.4)
			var btn_border := Color(0.2, 1, 0.4, 0.6) if can_afford else Color(0.3, 0.3, 0.3, 0.3)
			draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), btn_bg)
			draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), btn_border, false, 1.5 * sc)
			
			var cost_str := str(cost)
			var cs := font.get_string_size(cost_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fs_btn)
			var total_w := cs.x + 22 * sc  # coin icon + gap + text
			var cx := btn_x + (btn_w - total_w) / 2
			draw_string(font, Vector2(cx, btn_y + 26 * sc), cost_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_btn, Color(0.2, 1, 0.4) if can_afford else Color(0.5, 0.5, 0.5))
			NeonIcons.draw_coin(self, Vector2(cx + cs.x + 10 * sc, btn_y + 17 * sc), 7.0 * sc, Color(1, 0.85, 0.2, 0.8) if can_afford else Color(0.4, 0.4, 0.4))
	
	# Bottom bar: TOTAL COINS + UPGRADE ALL
	var bot_y := start_y + 2 * (card_h + gap) + 5 * sc
	if bot_y < max_y:
		var coin_fs := int(18 * sc)
		var coin_str := "TOTAL COINS: " + str(GameData.total_coins)
		draw_string(font, Vector2(vp.x / 2 - 200 * sc, bot_y + 20 * sc), coin_str, HORIZONTAL_ALIGNMENT_LEFT, -1, coin_fs, Color(1, 0.85, 0.2, 0.8))
		NeonIcons.draw_coin(self, Vector2(vp.x / 2 - 220 * sc, bot_y + 10 * sc), 8.0 * sc, Color(1, 0.85, 0.2))

func _draw_upgrade_icon(uid: String, pos: Vector2, size: float, sc: float) -> void:
	match uid:
		"fire_rate":
			NeonIcons.draw_crosshair(self, pos, size, Color(0, 1, 1))
		"thrust_power":
			# Rocket shape
			draw_line(pos + Vector2(0, -size), pos + Vector2(0, size * 0.5), Color(0, 1, 1, 0.8), 2.0 * sc)
			draw_line(pos + Vector2(-size * 0.4, size * 0.3), pos + Vector2(0, -size * 0.5), Color(0, 1, 1, 0.6), 1.5 * sc)
			draw_line(pos + Vector2(size * 0.4, size * 0.3), pos + Vector2(0, -size * 0.5), Color(0, 1, 1, 0.6), 1.5 * sc)
		"shield_duration":
			NeonIcons.draw_shield(self, pos, size, Color(0, 1, 1))
		"bomb_power":
			draw_circle(pos, size * 0.5, Color(0, 1, 1, 0.3))
			draw_circle(pos, size * 0.5, Color(0, 1, 1, 0.8), false, 1.5 * sc)
			draw_line(pos + Vector2(size * 0.3, -size * 0.3), pos + Vector2(size * 0.6, -size * 0.6), Color(0, 1, 1, 0.6), 1.5 * sc)
		"magnet_range":
			# U-magnet
			var pts := PackedVector2Array([
				pos + Vector2(-size * 0.5, -size * 0.5),
				pos + Vector2(-size * 0.5, size * 0.2),
				pos + Vector2(0, size * 0.5),
				pos + Vector2(size * 0.5, size * 0.2),
				pos + Vector2(size * 0.5, -size * 0.5),
			])
			draw_polyline(pts, Color(0, 1, 1, 0.8), 2.0 * sc)
		"extra_life":
			NeonIcons.draw_heart(self, pos, size, Color(1, 0.3, 0.4))
		"extra_bomb":
			draw_circle(pos, size * 0.5, Color(1, 0.5, 0, 0.3))
			draw_circle(pos, size * 0.5, Color(1, 0.5, 0, 0.8), false, 1.5 * sc)
			draw_line(pos + Vector2(size * 0.3, -size * 0.3), pos + Vector2(size * 0.6, -size * 0.6), Color(1, 0.5, 0, 0.6), 1.5 * sc)
		"score_bonus":
			_draw_mini_star(pos, size * 0.7, Color(0, 1, 1, 0.8))

func _handle_upgrade_tap(pos: Vector2, vp: Vector2) -> void:
	var sc := vp.y / 1080.0
	var upgrade_ids := ["fire_rate", "thrust_power", "shield_duration", "bomb_power", "magnet_range", "extra_life", "extra_bomb", "score_bonus"]
	var cols := 4
	var margin := 40.0 * sc
	var gap := 14.0 * sc
	var card_w := (vp.x - margin * 2 - gap * (cols - 1)) / float(cols)
	var card_h := 200.0 * sc
	var start_y := 95.0 * sc
	
	for i in upgrade_ids.size():
		var col := i % cols
		var row := i / cols
		var x := margin + col * (card_w + gap)
		var y := start_y + row * (card_h + gap)
		
		# Hit test on buy button area (bottom of card)
		var btn_x := x + 12 * sc
		var btn_y := y + card_h - 50 * sc
		var btn_w := card_w - 24 * sc
		var btn_h := 38.0 * sc
		
		if Rect2(btn_x, btn_y, btn_w, btn_h).has_point(pos):
			GameData.buy_upgrade(upgrade_ids[i])
			return

func _draw_pass(vp: Vector2, font: Font) -> void:
	var sc := vp.y / 1080.0
	var title := "GALACTIC PASS"
	var title_fs := int(40 * sc)
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, title_fs)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 60 * sc), title, HORIZONTAL_ALIGNMENT_CENTER, -1, title_fs, Color(0.6, 0.3, 1))
	if battle_pass_screen:
		battle_pass_screen.visible = (selected_tab == 2)

func _draw_missions(vp: Vector2, font: Font) -> void:
	var sc := vp.y / 1080.0
	var title := "MISSIONS"
	var title_fs := int(40 * sc)
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, title_fs)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 60 * sc), title, HORIZONTAL_ALIGNMENT_CENTER, -1, title_fs, Color(1, 0.8, 0))
	if missions_screen:
		missions_screen.visible = (selected_tab == 3)

func _draw_shop(vp: Vector2, font: Font) -> void:
	var sc := vp.y / 1080.0
	var title := "SHOP"
	var title_fs := int(40 * sc)
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, title_fs)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 60 * sc), title, HORIZONTAL_ALIGNMENT_CENTER, -1, title_fs, Color(0, 1, 0.5))
	if shop_screen:
		shop_screen.visible = (selected_tab == 4)
