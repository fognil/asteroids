extends Control
## Pause Screen — Resume, Settings, Quit to Menu overlay.

var is_paused: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle_pause() -> void:
	if is_paused:
		resume()
	else:
		pause()

func pause() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true
	queue_redraw()

func resume() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not is_paused:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var cx := vp.x / 2
	var cy := vp.y / 2
	var btn_w: float = 200.0
	var btn_h: float = 45.0
	
	# Resume
	if Rect2(cx - btn_w / 2, cy - 60, btn_w, btn_h).has_point(pos):
		resume()
		return
	
	# Settings
	if Rect2(cx - btn_w / 2, cy, btn_w, btn_h).has_point(pos):
		# Open settings
		var settings := get_tree().get_first_node_in_group("settings_screen")
		if settings and settings.has_method("show_settings"):
			settings.show_settings()
		return
	
	# Quit
	if Rect2(cx - btn_w / 2, cy + 60, btn_w, btn_h).has_point(pos):
		resume()
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
		return

func _process(_delta: float) -> void:
	if is_paused:
		queue_redraw()

func _draw() -> void:
	if not is_paused:
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	
	# Dim overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.75))
	
	var cx := vp.x / 2
	var cy := vp.y / 2
	var btn_w: float = 200.0
	var btn_h: float = 45.0
	
	# Title
	var title := "⏸ PAUSED"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	draw_string(font, Vector2((vp.x - ts.x) / 2, cy - 100), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color(0, 1, 1))
	
	# Resume button
	_draw_button(font, cx, cy - 60, btn_w, btn_h, "▶ RESUME", Color(0, 1, 0.5))
	
	# Settings button
	_draw_button(font, cx, cy, btn_w, btn_h, "⚙️ SETTINGS", Color(0.5, 0.5, 0.5))
	
	# Quit button
	_draw_button(font, cx, cy + 60, btn_w, btn_h, "✖ QUIT", Color(1, 0.3, 0.3))

func _draw_button(font: Font, cx: float, y: float, w: float, h: float, text: String, col: Color) -> void:
	var x := cx - w / 2
	draw_rect(Rect2(x, y, w, h), Color(0.08, 0.08, 0.12, 0.7))
	draw_rect(Rect2(x, y, w, h), Color(col, 0.4), false, 1.5)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(font, Vector2(cx - text_size.x / 2, y + 30), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, col)
