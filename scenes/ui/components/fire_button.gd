extends Control
## Fire button for mobile — tap to shoot, hold for auto-fire.

@export var button_radius: float = 40.0
@export var button_color: Color = Color(1, 0.3, 0.3, 0.3)
@export var active_color: Color = Color(1, 0.3, 0.3, 0.6)

var is_pressed: bool = false
var touch_index: int = -1

func _ready() -> void:
	# Position at bottom-right
	var vp := get_viewport_rect().size
	position = Vector2(vp.x - 120, vp.y - 120)

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
	var color := active_color if is_pressed else button_color
	draw_circle(Vector2.ZERO, button_radius, color)
	draw_arc(Vector2.ZERO, button_radius, 0, TAU, 32, Color(1, 1, 1, 0.3), 2.0, true)
	
	# "FIRE" text
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size("FIRE", HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	draw_string(font, Vector2(-text_size.x / 2, 5), "FIRE", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 1, 1, 0.8))
