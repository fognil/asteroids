extends Area2D
## Enemy bullet — damages player on contact, ignores asteroids.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var color: Color = Color(1.0, 0.3, 0.2)
var lifetime: float = 4.0

func _ready() -> void:
	add_to_group("enemy_bullets")
	_setup_collision()

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child.call_deferred(collision)
	
	collision_layer = 64   # Enemy bullet layer
	collision_mask = 1     # Player layer
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	# Despawn off screen (no wrap for enemy bullets)
	var vp := ScreenWrap.get_viewport_size()
	if position.x < -20 or position.x > vp.x + 20 or position.y < -20 or position.y > vp.y + 20:
		queue_free()
		return
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_hit"):
			body.take_hit()
		queue_free()

func _draw() -> void:
	# Red/orange glowing dot
	draw_circle(Vector2.ZERO, 4.0, Color(color, 0.3))
	draw_circle(Vector2.ZERO, 2.5, color)
	# Trail
	var trail_dir := -direction.normalized() * 8
	draw_line(Vector2.ZERO, trail_dir, Color(color, 0.4), 1.5)
