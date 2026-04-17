extends Area2D
## Bullet — flies straight, wraps screen, despawns after lifetime.
## Supports piercing (don't despawn on hit) via PowerupManager.

var direction: Vector2 = Vector2.UP
var speed: float = 800.0
var color: Color = Color(0, 1, 1)
var lifetime: float = 1.5
var is_piercing: bool = false

func _ready() -> void:
	add_to_group("player_bullets")
	area_entered.connect(_on_area_entered)
	# Check if piercing is active
	is_piercing = PowerupManager.is_active("piercing")

func _process(delta: float) -> void:
	position += direction * speed * delta
	position = ScreenWrap.wrap_position(position, 5.0)
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	queue_redraw()

func _draw() -> void:
	var draw_color := color
	if is_piercing:
		draw_color = Color(1.0, 0.3, 0.2)  # Red for piercing
	
	var glow := Color(draw_color, 0.3)
	# Glow
	draw_line(Vector2(0, 4), Vector2(0, -8), glow, 5.0, true)
	# Core
	draw_line(Vector2(0, 3), Vector2(0, -6), draw_color, 2.0, true)
	# Piercing trail
	if is_piercing:
		draw_line(Vector2(0, 6), Vector2(0, 14), Color(1, 0.3, 0.1, 0.3), 3.0, true)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroids"):
		area.take_damage(1, direction)
		if not is_piercing:
			queue_free()
	elif area.is_in_group("enemies"):
		area.take_damage(1)
		if not is_piercing:
			queue_free()
