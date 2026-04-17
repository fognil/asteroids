extends Area2D
## Bullet — flies straight, wraps screen, despawns after lifetime.

var direction: Vector2 = Vector2.UP
var speed: float = 800.0
var color: Color = Color(0, 1, 1)
var lifetime: float = 1.5

func _ready() -> void:
	# Connect to body/area entered for collision
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	position = ScreenWrap.wrap_position(position, 5.0)
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	queue_redraw()

func _draw() -> void:
	var glow := Color(color, 0.3)
	# Glow
	draw_line(Vector2(0, 4), Vector2(0, -8), glow, 5.0, true)
	# Core
	draw_line(Vector2(0, 3), Vector2(0, -6), color, 2.0, true)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroids"):
		area.take_damage(1, direction)
		queue_free()
	elif area.is_in_group("enemies"):
		area.take_damage(1)
		queue_free()
