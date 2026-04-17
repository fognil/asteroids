extends ColorRect
## ScreenFlash — full-screen overlay for flash effects (damage, powerup, bomb).

var flash_alpha: float = 0.0
var flash_decay: float = 4.0

func _ready() -> void:
	add_to_group("screen_flash")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 0)

func flash(col: Color = Color.WHITE, intensity: float = 0.6) -> void:
	color = Color(col.r, col.g, col.b, 0)
	flash_alpha = intensity

func flash_damage() -> void:
	flash(Color(1, 0.1, 0.1), 0.3)

func flash_powerup() -> void:
	flash(Color(0, 1, 1), 0.2)

func flash_bomb() -> void:
	flash(Color(1, 1, 1), 0.8)

func _process(delta: float) -> void:
	if flash_alpha > 0.001:
		flash_alpha = maxf(flash_alpha - flash_decay * delta, 0)
		color.a = flash_alpha
	elif color.a > 0:
		color.a = 0
