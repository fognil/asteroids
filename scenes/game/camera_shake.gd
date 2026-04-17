extends Camera2D
## Camera with screen shake — attach to main Camera2D.

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

# Slow-motion
var slow_mo_timer: float = 0.0
var slow_mo_target: float = 1.0

func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	# === Screen Shake ===
	if shake_timer > 0:
		shake_timer -= delta
		var progress := shake_timer / shake_duration if shake_duration > 0 else 0.0
		var current_intensity := shake_intensity * progress  # Fade out
		offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
	else:
		offset = Vector2.ZERO
	
	# === Slow Motion ===
	if slow_mo_timer > 0:
		slow_mo_timer -= get_process_delta_time()  # Use unscaled time
		if slow_mo_timer <= 0:
			Engine.time_scale = 1.0
		else:
			Engine.time_scale = lerpf(Engine.time_scale, slow_mo_target, 0.1)

## Shake the camera.
## intensity: pixel offset (2=light, 8=heavy, 15=extreme)
## duration: seconds
func shake(intensity: float, duration: float) -> void:
	# Only override if stronger shake
	if intensity > shake_intensity * (shake_timer / shake_duration if shake_duration > 0 else 0):
		shake_intensity = intensity
		shake_duration = duration
		shake_timer = duration

## Trigger slow motion.
## time_scale: 0.2 = very slow, 0.5 = half speed
## duration: seconds (real-time)
func slow_motion(time_scale: float, duration: float) -> void:
	slow_mo_target = time_scale
	slow_mo_timer = duration
	Engine.time_scale = time_scale

## Convenience presets
func shake_light() -> void:
	shake(3.0, 0.1)

func shake_medium() -> void:
	shake(6.0, 0.15)

func shake_heavy() -> void:
	shake(10.0, 0.25)

func shake_extreme() -> void:
	shake(18.0, 0.4)
