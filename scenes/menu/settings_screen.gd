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
	var panel_x := vp.x * 0.15
	var panel_w := vp.x * 0.7
	
	# Close button (top-right of panel)
	if pos.x > panel_x + panel_w - 50 and pos.y < 90:
		hide_settings()
		return
	
	# Volume sliders — tap to adjust
	var settings_items := ["master_volume", "music_volume", "sfx_volume"]
	var slider_y_start: float = 130.0
	var slider_h: float = 50.0
	var slider_x := panel_x + 200
	var slider_w := panel_w - 250
	
	for i in settings_items.size():
		var y := slider_y_start + float(i) * slider_h
		if pos.y > y and pos.y < y + slider_h and pos.x > slider_x and pos.x < slider_x + slider_w:
			var ratio := (pos.x - slider_x) / slider_w
			GameData.settings[settings_items[i]] = clampf(ratio, 0.0, 1.0)
			queue_redraw()
			return
	
	# Toggle options
	var toggle_items := ["vibration", "screen_shake"]
	var toggle_y_start := slider_y_start + settings_items.size() * slider_h + 20
	
	for i in toggle_items.size():
		var y := toggle_y_start + float(i) * 45.0
		if pos.y > y and pos.y < y + 40:
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
	var font := ThemeDB.fallback_font
	
	# Dim overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.7))
	
	# Panel
	var panel_x := vp.x * 0.15
	var panel_y: float = 55.0
	var panel_w := vp.x * 0.7
	var panel_h := vp.y - 110
	draw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.05, 0.05, 0.1, 0.95))
	var border := PackedVector2Array([
		Vector2(panel_x, panel_y), Vector2(panel_x + panel_w, panel_y),
		Vector2(panel_x + panel_w, panel_y + panel_h), Vector2(panel_x, panel_y + panel_h), Vector2(panel_x, panel_y)
	])
	draw_polyline(border, Color(0, 1, 1, 0.3), 1.5)
	
	# Title
	NeonIcons.draw_gear(self, Vector2(panel_x + 30, panel_y + 22), 10.0, Color(0, 1, 1))
	draw_string(font, Vector2(panel_x + 48, panel_y + 30), "SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0, 1, 1))
	# Close
	draw_string(font, Vector2(panel_x + panel_w - 40, panel_y + 30), "✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.5))
	
	# Volume sliders
	var slider_items := [
		{"key": "master_volume", "label": "Master Volume"},
		{"key": "music_volume", "label": "Music Volume"},
		{"key": "sfx_volume", "label": "SFX Volume"},
	]
	var slider_y_start: float = 130.0
	var slider_h: float = 50.0
	var slider_x := panel_x + 200
	var slider_w := panel_w - 250
	
	for i in slider_items.size():
		var item: Dictionary = slider_items[i]
		var y := slider_y_start + float(i) * slider_h
		var val: float = GameData.settings.get(item["key"], 0.8)
		
		# Label
		var label_str: String = item["label"]
		draw_string(font, Vector2(panel_x + 20, y + 25), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
		
		# Slider track
		draw_rect(Rect2(slider_x, y + 15, slider_w, 8), Color(0.2, 0.2, 0.2, 0.6))
		# Filled
		draw_rect(Rect2(slider_x, y + 15, slider_w * val, 8), Color(0, 1, 1, 0.6))
		# Knob
		draw_circle(Vector2(slider_x + slider_w * val, y + 19), 8, Color(0, 1, 1, 0.9))
		# Value
		draw_string(font, Vector2(slider_x + slider_w + 15, y + 25), str(int(val * 100)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
	
	# Toggles
	var toggle_items := [
		{"key": "vibration", "label": "Vibration"},
		{"key": "screen_shake", "label": "Screen Shake"},
	]
	var toggle_y_start := slider_y_start + slider_items.size() * slider_h + 30
	
	draw_string(font, Vector2(panel_x + 20, toggle_y_start - 5), "──── Options ────", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.4))
	
	for i in toggle_items.size():
		var item: Dictionary = toggle_items[i]
		var y := toggle_y_start + float(i) * 45.0 + 10
		var enabled: bool = GameData.settings.get(item["key"], true)
		
		var label_str: String = item["label"]
		draw_string(font, Vector2(panel_x + 20, y + 20), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
		
		# Toggle box
		var toggle_x := panel_x + panel_w - 80
		draw_rect(Rect2(toggle_x, y + 5, 50, 22), Color(0.2, 0.2, 0.2, 0.6))
		if enabled:
			draw_rect(Rect2(toggle_x + 25, y + 5, 25, 22), Color(0, 1, 1, 0.7))
			draw_string(font, Vector2(toggle_x + 30, y + 22), "ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 1, 1))
		else:
			draw_rect(Rect2(toggle_x, y + 5, 25, 22), Color(0.4, 0.4, 0.4, 0.5))
			draw_string(font, Vector2(toggle_x + 4, y + 22), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
	
	# Credits
	var credits_y := toggle_y_start + toggle_items.size() * 45 + 60
	draw_string(font, Vector2(panel_x + 20, credits_y), "Neon Asteroids v1.0", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.3, 0.3))
