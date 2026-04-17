extends Node
## Game Manager — controls game state, wave spawning, and core loop.

enum State { COUNTDOWN, PLAYING, WAVE_CLEAR, GAME_OVER }

var current_state: State = State.COUNTDOWN
var countdown_timer: float = 0.0
var wave_clear_timer: float = 0.0
var combo_timer: float = 0.0
const COMBO_TIMEOUT: float = 2.5

@onready var player: CharacterBody2D = $"../GameWorld/Player"
@onready var asteroids_container: Node2D = $"../GameWorld/Asteroids"
@onready var bullets_container: Node2D = $"../GameWorld/Bullets"
@onready var effects_container: Node2D = $"../GameWorld/Effects"
@onready var hud: CanvasLayer = $"../HUD"

func _ready() -> void:
	asteroids_container.add_to_group("asteroids_container")
	bullets_container.add_to_group("bullets")
	effects_container.add_to_group("effects_container")
	
	EventBus.player_died.connect(_on_player_died)
	EventBus.asteroid_destroyed.connect(_on_asteroid_destroyed)
	
	start_game()

func _process(delta: float) -> void:
	match current_state:
		State.COUNTDOWN:
			_process_countdown(delta)
		State.PLAYING:
			_process_playing(delta)
		State.WAVE_CLEAR:
			_process_wave_clear(delta)
		State.GAME_OVER:
			_process_game_over(delta)

# === Game Start ===
func start_game() -> void:
	GameData.reset_game()
	player.respawn()
	_clear_all()
	_start_next_wave()

func _clear_all() -> void:
	for child in asteroids_container.get_children():
		child.queue_free()
	for child in bullets_container.get_children():
		child.queue_free()
	for child in effects_container.get_children():
		child.queue_free()
	Engine.time_scale = 1.0

# === Wave Management ===
func _start_next_wave() -> void:
	GameData.wave += 1
	current_state = State.COUNTDOWN
	countdown_timer = 2.0
	EventBus.wave_started.emit(GameData.wave)

func _spawn_wave() -> void:
	var count := mini(5 + GameData.wave * 2, 40)
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var player_pos: Vector2 = player.global_position
	
	for i in count:
		var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		
		# Determine size based on wave
		var size_roll := randf()
		if GameData.wave <= 3:
			if size_roll < 0.7:
				asteroid.asteroid_size = 1  # LARGE
			elif size_roll < 0.9:
				asteroid.asteroid_size = 2  # MEDIUM
			else:
				asteroid.asteroid_size = 3  # SMALL
		else:
			if size_roll < 0.2:
				asteroid.asteroid_size = 0  # HUGE
			elif size_roll < 0.5:
				asteroid.asteroid_size = 1  # LARGE
			elif size_roll < 0.8:
				asteroid.asteroid_size = 2  # MEDIUM
			else:
				asteroid.asteroid_size = 3  # SMALL
		
		# Spawn on random edge, away from player
		var spawn_pos: Vector2 = _random_edge_position(vp_size)
		var attempts := 0
		while spawn_pos.distance_to(player_pos) < 200 and attempts < 10:
			spawn_pos = _random_edge_position(vp_size)
			attempts += 1
		
		asteroid.position = spawn_pos
		
		# Direction toward center ± random
		var to_center: Vector2 = (vp_size / 2.0 - spawn_pos).normalized()
		var angle_offset := randf_range(-PI / 4, PI / 4)
		asteroid.move_velocity = to_center.rotated(angle_offset) * randf_range(40, 100)
		
		asteroids_container.add_child(asteroid)

func _random_edge_position(vp: Vector2) -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf() * vp.x, -20)       # Top
		1: return Vector2(randf() * vp.x, vp.y + 20)  # Bottom
		2: return Vector2(-20, randf() * vp.y)         # Left
		3: return Vector2(vp.x + 20, randf() * vp.y)   # Right
		_: return Vector2.ZERO

# === State Processing ===
func _process_countdown(delta: float) -> void:
	countdown_timer -= delta
	if countdown_timer <= 0:
		current_state = State.PLAYING
		_spawn_wave()

func _process_playing(delta: float) -> void:
	# Combo timeout
	combo_timer -= delta
	if combo_timer <= 0 and GameData.combo > 0:
		GameData.reset_combo()
	
	# Bomb input
	if Input.is_action_just_pressed("bomb"):
		_use_bomb()
	
	# Check for player collision with asteroids
	_check_player_collisions()
	
	# Check if all asteroids destroyed
	if asteroids_container.get_child_count() == 0:
		current_state = State.WAVE_CLEAR
		wave_clear_timer = 2.0
		EventBus.wave_completed.emit(GameData.wave)

func _process_wave_clear(delta: float) -> void:
	wave_clear_timer -= delta
	if wave_clear_timer <= 0:
		_start_next_wave()

func _process_game_over(_delta: float) -> void:
	# Wait for restart input
	if Input.is_action_just_pressed("fire") or Input.is_action_just_pressed("thrust"):
		start_game()

# === Bomb ===
func _use_bomb() -> void:
	if not GameData.use_bomb():
		return  # No bombs left
	
	# Screen shake + slow-mo
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	if cam and cam.has_method("slow_motion"):
		cam.slow_motion(0.2, 1.0)
	
	# Destroy all asteroids on screen
	var asteroids := asteroids_container.get_children()
	for asteroid in asteroids:
		if is_instance_valid(asteroid) and asteroid.has_method("take_damage"):
			asteroid.take_damage(999, Vector2.ZERO)

# === Collisions ===
func _check_player_collisions() -> void:
	if player.is_dead or player.is_invincible:
		return
	
	for asteroid in asteroids_container.get_children():
		if not is_instance_valid(asteroid):
			continue
		var dist := player.global_position.distance_to(asteroid.global_position)
		if dist < asteroid.asteroid_radius * 0.7 + player.ship_size * 0.5:
			player.take_hit()
			break

# === Callbacks ===
func _on_player_died() -> void:
	current_state = State.GAME_OVER
	EventBus.game_over.emit(GameData.score, GameData.wave)

func _on_asteroid_destroyed(_pos: Vector2, _size: String, _type: String) -> void:
	combo_timer = COMBO_TIMEOUT
