extends Control
## Fire button for mobile — tap to shoot, hold for auto-fire.

@export var button_color: Color = Color(1, 0.3, 0.3, 0.3)
@export var active_color: Color = Color(1, 0.3, 0.3, 0.6)

var is_pressed: bool = false
var touch_index: int = -1
var button_radius: float = 40.0

func _ready() -> void:
	var vp := get_viewport_rect().size
	var sc := ScreenWrap.get_ui_scale()
	button_radius = 55.0 * sc
	position = Vector2(vp.x - 150 * sc, vp.y - 150 * sc)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var local_pos := touch.position - global_position
		
		if touch.pressed and local_pos.length() < button_radius * 1.5:
			is_pressed = true
			touch_index = touch.index
			Input.action_press("fire")
		elif not touch.pressed and touch.index == touch_index:
			is_pressed = false
			touch_index = -1
			Input.action_release("fire")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var sc := ScreenWrap.get_ui_scale()
	var color := active_color if is_pressed else button_color
	draw_circle(Vector2.ZERO, button_radius, color)
	draw_arc(Vector2.ZERO, button_radius, 0, TAU, 32, Color(1, 1, 1, 0.3), 2.0 * sc, true)
	
	# "FIRE" text
	var font := ThemeDB.fallback_font
	var fs := int(18 * sc)
	var text_size := font.get_string_size("FIRE", HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, Vector2(-text_size.x / 2, fs * 0.35), "FIRE", HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.8))

