extends Control
## Tutorial overlay — first-time guide for new players (Wave 1-2 only).

var step: int = 0
var is_active: bool = false
var step_timer: float = 0.0
var completed: bool = false

const STEPS := [
	{"text": "Drag LEFT JOYSTICK to MOVE", "highlight": "joystick", "duration": 5.0},
	{"text": "Tap FIRE to SHOOT", "highlight": "fire", "duration": 4.0},
	{"text": "Destroy all ASTEROIDS!", "highlight": "none", "duration": 4.0},
	{"text": "Collect COINS for upgrades!", "highlight": "none", "duration": 4.0},
	{"text": "Build COMBOS by destroying quickly!", "highlight": "none", "duration": 5.0},
]

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Check if tutorial already completed
	if GameData.settings.get("tutorial_done", false):
		completed = true

func start_tutorial() -> void:
	if completed:
		return
	is_active = true
	visible = true
	step = 0
	step_timer = STEPS[0]["duration"]
	queue_redraw()

func _process(delta: float) -> void:
	if not is_active:
		return
	
	step_timer -= delta
	if step_timer <= 0:
		step += 1
		if step >= STEPS.size():
			_complete()
			return
		step_timer = STEPS[step]["duration"]
	queue_redraw()

func _complete() -> void:
	is_active = false
	visible = false
	completed = true
	GameData.settings["tutorial_done"] = true
	SaveManager.save_game()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	# Tap to skip step
	if event is InputEventScreenTouch and event.pressed:
		step += 1
		if step >= STEPS.size():
			_complete()
			return
		step_timer = STEPS[step]["duration"]

func _draw() -> void:
	if not is_active or step >= STEPS.size():
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var current: Dictionary = STEPS[step]
	var text: String = current["text"]
	var highlight: String = current["highlight"]
	
	# Semi-transparent overlay at top
	draw_rect(Rect2(0, 0, vp.x, 80), Color(0, 0, 0, 0.6))
	
	# Tutorial text
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 22)
	draw_string(font, Vector2((vp.x - ts.x) / 2, 45), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(0, 1, 1))
	
	# Step indicator
	var step_text := "Step " + str(step + 1) + "/" + str(STEPS.size()) + "  (Tap to skip)"
	var sts := font.get_string_size(step_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	draw_string(font, Vector2((vp.x - sts.x) / 2, 68), step_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.5, 0.5, 0.5))
	
	# Highlight arrows
	var time := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(time * 3.0)
	
	match highlight:
		"joystick":
			var jpos := Vector2(150, vp.y - 150)
			draw_arc(jpos, 60 + pulse * 10, 0, TAU, 12, Color(0, 1, 1, 0.3 + pulse * 0.3), 2.0, true)
			draw_string(font, Vector2(jpos.x - 10, jpos.y - 80), "↓", HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color(0, 1, 1, pulse))
		"fire":
			var fpos := Vector2(vp.x - 120, vp.y - 120)
			draw_arc(fpos, 45 + pulse * 8, 0, TAU, 12, Color(1, 0.3, 0, 0.3 + pulse * 0.3), 2.0, true)
			draw_string(font, Vector2(fpos.x - 10, fpos.y - 60), "↓", HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color(1, 0.3, 0, pulse))
