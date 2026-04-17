extends Control
## Settings screen — volume, controls, visual options.

var is_visible_settings: bool = false

func _ready() -> void:
	add_to_group("settings_screen")
	visible = false

func show_settings() -> void:
	is_visible_settings = true
	visible = true
	queue_redraw()

func hide_settings() -> void:
	is_visible_settings = false
	visible = false
	SaveManager.save_game()

func _input(event: InputEvent) -> void:
	if not is_visible_settings:
		return
	
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var sc := vp.y / 1080.0
	var panel_x := vp.x * 0.15
	var panel_w := vp.x * 0.7
	var panel_y := 80.0 * sc
	
	# Close button (top-right of panel)
	if pos.x > panel_x + panel_w - 80 * sc and pos.y < panel_y + 60 * sc:
		hide_settings()
		return
	
	# Volume sliders — tap to adjust
	var settings_items := ["master_volume", "music_volume", "sfx_volume"]
	var slider_y_start := panel_y + 100 * sc
	var slider_h := 80.0 * sc
	var slider_x := panel_x + 320 * sc
	var slider_w := panel_w - 400 * sc
	
	for i in settings_items.size():
		var y := slider_y_start + float(i) * slider_h
		if pos.y > y and pos.y < y + slider_h and pos.x > slider_x and pos.x < slider_x + slider_w:
			var ratio := (pos.x - slider_x) / slider_w
			GameData.settings[settings_items[i]] = clampf(ratio, 0.0, 1.0)
			queue_redraw()
			return
	
	# Toggle options
	var toggle_items := ["vibration", "screen_shake"]
	var toggle_y_start := slider_y_start + settings_items.size() * slider_h + 30 * sc
	
	for i in toggle_items.size():
		var y := toggle_y_start + float(i) * 70.0 * sc
		if pos.y > y and pos.y < y + 60 * sc:
			var key: String = toggle_items[i]
			GameData.settings[key] = not GameData.settings.get(key, true)
			queue_redraw()
			return

func _process(_delta: float) -> void:
	if is_visible_settings:
		queue_redraw()

func _draw() -> void:
	if not is_visible_settings:
		return
	
	var vp := get_viewport_rect().size
	var sc := vp.y / 1080.0
	var font := ThemeDB.fallback_font
	
	# Dim overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.7))
	
	# Panel
	var panel_x := vp.x * 0.15
	var panel_y := 80.0 * sc
	var panel_w := vp.x * 0.7
	var panel_h := vp.y - 160 * sc
	draw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.05, 0.05, 0.1, 0.95))
	var border := PackedVector2Array([
		Vector2(panel_x, panel_y), Vector2(panel_x + panel_w, panel_y),
		Vector2(panel_x + panel_w, panel_y + panel_h), Vector2(panel_x, panel_y + panel_h), Vector2(panel_x, panel_y)
	])
	draw_polyline(border, Color(0, 1, 1, 0.3), 2.0 * sc)
	
	# Title
	var title_fs := int(36 * sc)
	NeonIcons.draw_gear(self, Vector2(panel_x + 40 * sc, panel_y + 36 * sc), 16.0 * sc, Color(0, 1, 1))
	draw_string(font, Vector2(panel_x + 70 * sc, panel_y + 48 * sc), "SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, Color(0, 1, 1))
	# Close X
	draw_string(font, Vector2(panel_x + panel_w - 60 * sc, panel_y + 48 * sc), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, Color(1, 1, 1, 0.5))
	
	# Separator
	draw_line(Vector2(panel_x + 20 * sc, panel_y + 70 * sc), Vector2(panel_x + panel_w - 20 * sc, panel_y + 70 * sc), Color(0.3, 0.3, 0.4, 0.3), 1.0)
	
	# Volume sliders
	var slider_items := [
		{"key": "master_volume", "label": "Master Volume"},
		{"key": "music_volume", "label": "Music Volume"},
		{"key": "sfx_volume", "label": "SFX Volume"},
	]
	var slider_y_start := panel_y + 100 * sc
	var slider_h := 80.0 * sc
	var slider_x := panel_x + 320 * sc
	var slider_w := panel_w - 400 * sc
	var fs := int(24 * sc)
	var fs_sm := int(20 * sc)
	
	for i in slider_items.size():
		var item: Dictionary = slider_items[i]
		var y := slider_y_start + float(i) * slider_h
		var val: float = GameData.settings.get(item["key"], 0.8)
		
		# Label
		var label_str: String = item["label"]
		draw_string(font, Vector2(panel_x + 30 * sc, y + 40 * sc), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.8, 0.8, 0.8))
		
		# Slider track
		draw_rect(Rect2(slider_x, y + 28 * sc, slider_w, 12 * sc), Color(0.2, 0.2, 0.2, 0.6))
		# Filled
		draw_rect(Rect2(slider_x, y + 28 * sc, slider_w * val, 12 * sc), Color(0, 1, 1, 0.6))
		# Knob
		draw_circle(Vector2(slider_x + slider_w * val, y + 34 * sc), 12 * sc, Color(0, 1, 1, 0.9))
		# Value
		draw_string(font, Vector2(slider_x + slider_w + 25 * sc, y + 40 * sc), str(int(val * 100)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0.6, 0.6, 0.6))
	
	# Toggles
	var toggle_items := [
		{"key": "vibration", "label": "Vibration"},
		{"key": "screen_shake", "label": "Screen Shake"},
	]
	var toggle_y_start := slider_y_start + slider_items.size() * slider_h + 40 * sc
	
	draw_line(Vector2(panel_x + 20 * sc, toggle_y_start - 15 * sc), Vector2(panel_x + panel_w - 20 * sc, toggle_y_start - 15 * sc), Color(0.3, 0.3, 0.4, 0.3), 1.0)
	draw_string(font, Vector2(panel_x + 30 * sc, toggle_y_start + 5 * sc), "Options", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0.4, 0.4, 0.4))
	
	for i in toggle_items.size():
		var item: Dictionary = toggle_items[i]
		var y := toggle_y_start + float(i) * 70.0 * sc + 25 * sc
		var enabled: bool = GameData.settings.get(item["key"], true)
		
		var label_str: String = item["label"]
		draw_string(font, Vector2(panel_x + 30 * sc, y + 35 * sc), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.8, 0.8, 0.8))
		
		# Toggle box
		var toggle_x := panel_x + panel_w - 130 * sc
		var tw := 80.0 * sc
		var th := 36.0 * sc
		draw_rect(Rect2(toggle_x, y + 12 * sc, tw, th), Color(0.2, 0.2, 0.2, 0.6))
		if enabled:
			draw_rect(Rect2(toggle_x + tw / 2, y + 12 * sc, tw / 2, th), Color(0, 1, 1, 0.7))
			draw_string(font, Vector2(toggle_x + tw / 2 + 8 * sc, y + 36 * sc), "ON", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0, 1, 1))
		else:
			draw_rect(Rect2(toggle_x, y + 12 * sc, tw / 2, th), Color(0.4, 0.4, 0.4, 0.5))
			draw_string(font, Vector2(toggle_x + 8 * sc, y + 36 * sc), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0.5, 0.5, 0.5))
	
	# Credits
	var credits_y := toggle_y_start + toggle_items.size() * 70 * sc + 100 * sc
	draw_string(font, Vector2(panel_x + 30 * sc, credits_y), "Neon Asteroids v1.0", HORIZONTAL_ALIGNMENT_LEFT, -1, fs_sm, Color(0.3, 0.3, 0.3))
