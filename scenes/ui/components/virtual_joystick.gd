extends Control
## Virtual floating joystick for mobile touch controls.
## Place in a CanvasLayer; outputs direction via `joystick_vector`.

signal joystick_moved(direction: Vector2)

@export var joystick_radius: float = 80.0
@export var knob_radius: float = 30.0
@export var dead_zone: float = 0.1
@export var base_color: Color = Color(1, 1, 1, 0.15)
@export var knob_color: Color = Color(0, 1, 1, 0.4)

var is_active: bool = false
var touch_index: int = -1
var center: Vector2 = Vector2.ZERO
var knob_position: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var sc := ScreenWrap.get_ui_scale()
	joystick_radius = 80.0 * sc
	knob_radius = 30.0 * sc
	# Only respond to touches on left half
	mouse_filter = Control.MOUSE_FILTER_PASS

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var vp_width := get_viewport_rect().size.x
		
		if touch.pressed and touch.position.x < vp_width * 0.5:
			# Start joystick on left half of screen
			if not is_active:
				is_active = true
				touch_index = touch.index
				center = touch.position
				knob_position = center
				joystick_vector = Vector2.ZERO
		elif not touch.pressed and touch.index == touch_index:
			# Release
			is_active = false
			touch_index = -1
			joystick_vector = Vector2.ZERO
			joystick_moved.emit(Vector2.ZERO)
	
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_index and is_active:
			var diff := drag.position - center
			if diff.length() > joystick_radius:
				diff = diff.normalized() * joystick_radius
			knob_position = center + diff
			
			var ratio := diff.length() / joystick_radius
			if ratio < dead_zone:
				joystick_vector = Vector2.ZERO
			else:
				joystick_vector = diff.normalized() * ((ratio - dead_zone) / (1.0 - dead_zone))
			
			joystick_moved.emit(joystick_vector)

func _process(_delta: float) -> void:
	# Feed joystick to player
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and player.has_method("_handle_input"):
		player.move_input = joystick_vector
	elif player:
		player.set("move_input", joystick_vector)
	
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
	
	# Draw base circle
	draw_circle(center, joystick_radius, base_color)
	draw_arc(center, joystick_radius, 0, TAU, 64, Color(1, 1, 1, 0.2), 2.0, true)
	
	# Draw knob
	draw_circle(knob_position, knob_radius, knob_color)
	draw_arc(knob_position, knob_radius, 0, TAU, 32, Color(0, 1, 1, 0.5), 2.0, true)
