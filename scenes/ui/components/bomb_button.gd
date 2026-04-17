extends Control
## Bomb button for mobile — tap to use bomb.

@export var button_color: Color = Color(1, 0.6, 0, 0.3)
@export var active_color: Color = Color(1, 0.6, 0, 0.6)

var is_pressed: bool = false
var touch_index: int = -1
var button_radius: float = 30.0

func _ready() -> void:
	var vp := get_viewport_rect().size
	var sc := vp.y / 1080.0
	button_radius = 50.0 * sc
	position = Vector2(vp.x - 180 * sc, vp.y - 340 * sc)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var local_pos := touch.position - global_position
		
		if touch.pressed and local_pos.length() < button_radius * 1.5:
			is_pressed = true
			touch_index = touch.index
			Input.action_press("bomb")
			# Auto-release after brief delay
			get_tree().create_timer(0.1).timeout.connect(func():
				Input.action_release("bomb")
			)
		elif not touch.pressed and touch.index == touch_index:
			is_pressed = false
			touch_index = -1

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var sc := get_viewport_rect().size.y / 1080.0
	var color := active_color if is_pressed else button_color
	draw_circle(Vector2.ZERO, button_radius, color)
	draw_arc(Vector2.ZERO, button_radius, 0, TAU, 32, Color(1, 0.6, 0, 0.3), 3.0 * sc, true)
	
	var font := ThemeDB.fallback_font
	var fs := int(18 * sc)
	var text := "BOMB x%d" % GameData.bombs
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, Vector2(-text_size.x / 2, fs * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.8))
