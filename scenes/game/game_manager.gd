extends Node
## Game Manager — controls game state, wave spawning, enemies, and core loop.

enum State { COUNTDOWN, PLAYING, WAVE_CLEAR, GAME_OVER }

var current_state: State = State.COUNTDOWN
var countdown_timer: float = 0.0
var wave_clear_timer: float = 0.0
var combo_timer: float = 0.0
const COMBO_TIMEOUT: float = 2.5

# UFO spawning
var ufo_spawn_timer: float = 15.0
var active_ufos: int = 0
const MAX_UFOS := 2

@onready var player: CharacterBody2D = $"../GameWorld/Player"
@onready var asteroids_container: Node2D = $"../GameWorld/Asteroids"
@onready var bullets_container: Node2D = $"../GameWorld/Bullets"
@onready var effects_container: Node2D = $"../GameWorld/Effects"
@onready var enemies_container: Node2D = $"../GameWorld/Enemies"
@onready var hud: CanvasLayer = $"../HUD"

func _ready() -> void:
	asteroids_container.add_to_group("asteroids_container")
	bullets_container.add_to_group("bullets")
	effects_container.add_to_group("effects_container")
	enemies_container.add_to_group("enemies_container")
	
	EventBus.player_died.connect(_on_player_died)
	EventBus.asteroid_destroyed.connect(_on_asteroid_destroyed)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	
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
	PowerupManager.reset()
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
	for child in enemies_container.get_children():
		child.queue_free()
	Engine.time_scale = 1.0
	active_ufos = 0

# === Wave Management ===
func _start_next_wave() -> void:
	GameData.wave += 1
	current_state = State.COUNTDOWN
	countdown_timer = 2.0
	ufo_spawn_timer = maxf(25.0 - GameData.wave * 0.5, 8.0)
	EventBus.wave_started.emit(GameData.wave)

func _spawn_wave() -> void:
	var count := mini(5 + GameData.wave * 2, 40)
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var player_pos: Vector2 = player.global_position
	
	for i in count:
		var asteroid: Area2D = load("res://scenes/asteroids/asteroid.tscn").instantiate()
		
		var size_roll := randf()
		if GameData.wave <= 3:
			if size_roll < 0.7:
				asteroid.asteroid_size = 1
			elif size_roll < 0.9:
				asteroid.asteroid_size = 2
			else:
				asteroid.asteroid_size = 3
		else:
			if size_roll < 0.2:
				asteroid.asteroid_size = 0
			elif size_roll < 0.5:
				asteroid.asteroid_size = 1
			elif size_roll < 0.8:
				asteroid.asteroid_size = 2
			else:
				asteroid.asteroid_size = 3
		
		var spawn_pos: Vector2 = _random_edge_position(vp_size)
		var attempts := 0
		while spawn_pos.distance_to(player_pos) < 200 and attempts < 10:
			spawn_pos = _random_edge_position(vp_size)
			attempts += 1
		
		asteroid.position = spawn_pos
		
		var to_center: Vector2 = (vp_size / 2.0 - spawn_pos).normalized()
		var angle_offset := randf_range(-PI / 4, PI / 4)
		asteroid.move_velocity = to_center.rotated(angle_offset) * randf_range(40, 100)
		
		asteroids_container.add_child(asteroid)

func _random_edge_position(vp: Vector2) -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf() * vp.x, -20)
		1: return Vector2(randf() * vp.x, vp.y + 20)
		2: return Vector2(-20, randf() * vp.y)
		3: return Vector2(vp.x + 20, randf() * vp.y)
		_: return Vector2.ZERO

# === UFO Spawning ===
func _update_ufo_spawning(delta: float) -> void:
	if GameData.wave < 3:
		return
	
	# Count current UFOs
	active_ufos = enemies_container.get_child_count()
	if active_ufos >= MAX_UFOS:
		return
	
	ufo_spawn_timer -= delta
	if ufo_spawn_timer <= 0:
		ufo_spawn_timer = maxf(25.0 - GameData.wave * 0.5, 8.0)
		_spawn_ufo()

func _spawn_ufo() -> void:
	var from_left := randf() < 0.5
	var ufo: Area2D
	
	if GameData.wave >= 6 and randf() < 0.4:
		# Hunter UFO
		ufo = load("res://scenes/enemies/hunter_ufo.tscn").instantiate()
	else:
		# Scout UFO
		ufo = load("res://scenes/enemies/scout_ufo.tscn").instantiate()
	
	ufo.setup(from_left)
	enemies_container.add_child(ufo)

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
	
	# UFO spawning
	_update_ufo_spawning(delta)
	
	# Check for player collision with asteroids/enemies
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

func _process_game_over(delta: float) -> void:
	# Wait a moment, then return to menu on tap
	if Input.is_action_just_pressed("fire") or Input.is_action_just_pressed("thrust"):
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

# === Bomb ===
func _use_bomb() -> void:
	if not GameData.use_bomb():
		return
	
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake_extreme"):
		cam.shake_extreme()
	if cam and cam.has_method("slow_motion"):
		cam.slow_motion(0.2, 1.0)
	
	# Destroy all asteroids
	for asteroid in asteroids_container.get_children():
		if is_instance_valid(asteroid) and asteroid.has_method("take_damage"):
			asteroid.take_damage(999, Vector2.ZERO)
	
	# Damage all enemies (3 damage, per GDD)
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(3)
	
	# Destroy all enemy bullets
	for child in bullets_container.get_children():
		if is_instance_valid(child) and child.is_in_group("enemy_bullets"):
			child.queue_free()

# === Collisions ===
func _check_player_collisions() -> void:
	if player.is_dead or player.is_invincible:
		return
	
	# Player ↔ Asteroids
	for asteroid in asteroids_container.get_children():
		if not is_instance_valid(asteroid):
			continue
		var dist := player.global_position.distance_to(asteroid.global_position)
		if dist < asteroid.asteroid_radius * 0.7 + player.ship_size * 0.5:
			player.take_hit()
			return
	
	# Player ↔ Enemies
	for enemy in enemies_container.get_children():
		if not is_instance_valid(enemy):
			continue
		var dist := player.global_position.distance_to(enemy.global_position)
		var enemy_size: float = enemy.get("ufo_size") if enemy.get("ufo_size") else 30.0
		if dist < enemy_size * 0.5 + player.ship_size * 0.5:
			player.take_hit()
			return

# === Callbacks ===
func _on_player_died() -> void:
	current_state = State.GAME_OVER
	GameData.end_game()
	EventBus.game_over.emit(GameData.score, GameData.wave)

func _on_asteroid_destroyed(pos: Vector2, size_name: String, _type: String) -> void:
	combo_timer = COMBO_TIMEOUT
	
	# Spawn coins from destroyed asteroid
	_spawn_coins_at(pos, size_name)
	
	# Chance to spawn power-up (Medium/Large only)
	if size_name in ["LARGE", "HUGE", "MEDIUM"]:
		if randf() < 0.12:  # 12% chance
			_spawn_powerup_at(pos)

func _on_enemy_destroyed(_type: String, _pos: Vector2) -> void:
	combo_timer = COMBO_TIMEOUT

func _spawn_coins_at(pos: Vector2, size_name: String) -> void:
	var coin_count := 1
	var coin_tier := 0  # Bronze
	
	match size_name:
		"SMALL":
			coin_count = 1
			coin_tier = 0
		"MEDIUM":
			coin_count = 2
			coin_tier = 0
		"LARGE":
			coin_count = 2
			coin_tier = 1  # Silver
		"HUGE":
			coin_count = 3
			coin_tier = 1
	
	for i in coin_count:
		var coin: Area2D = load("res://scenes/collectibles/coin.tscn").instantiate()
		coin.tier = coin_tier
		coin.global_position = pos
		coin.setup_velocity(Vector2.RIGHT.rotated(randf() * TAU))
		effects_container.add_child(coin)

func _spawn_powerup_at(pos: Vector2) -> void:
	var types := ["shield", "multi_shot", "rapid_fire", "piercing", "extra_life", "bomb_pickup"]
	var weights := [15, 12, 12, 6, 5, 8]
	
	# Weighted random selection
	var total := 0
	for w in weights:
		total += w
	var roll := randi() % total
	var cumulative := 0
	var selected: String = types[0]
	for i in types.size():
		cumulative += weights[i]
		if roll < cumulative:
			selected = types[i]
			break
	
	var powerup: Area2D = load("res://scenes/powerups/powerup.tscn").instantiate()
	powerup.powerup_type = selected
	powerup.global_position = pos
	effects_container.add_child(powerup)
