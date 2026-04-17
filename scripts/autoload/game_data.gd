extends Node
## Manages runtime game state: score, lives, wave, coins.
## Will handle save/load in Phase 4.

# --- Runtime State (reset each game) ---
var score: int = 0
var high_score: int = 0
var lives: int = 3
var max_lives: int = 5
var wave: int = 0
var coins: int = 0
var bombs: int = 3
var max_bombs: int = 5
var combo: int = 0
var combo_multiplier: int = 1

# --- Persistent State (placeholder for save/load) ---
var total_coins: int = 0
var total_asteroids_destroyed: int = 0
var total_games_played: int = 0

func reset_game() -> void:
	score = 0
	lives = 3
	wave = 0
	combo = 0
	combo_multiplier = 1
	bombs = 3

func add_score(amount: int) -> void:
	var final_amount := amount * combo_multiplier
	score += final_amount
	if score > high_score:
		high_score = score
	EventBus.score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	EventBus.player_hit.emit(lives)
	if lives <= 0:
		EventBus.player_died.emit()

func add_combo() -> void:
	combo += 1
	if combo >= 50:
		combo_multiplier = 10
	elif combo >= 20:
		combo_multiplier = 5
	elif combo >= 10:
		combo_multiplier = 3
	elif combo >= 5:
		combo_multiplier = 2
	else:
		combo_multiplier = 1
	EventBus.combo_changed.emit(combo, combo_multiplier)

func reset_combo() -> void:
	if combo > 0:
		combo = 0
		combo_multiplier = 1
		EventBus.combo_lost.emit()

func use_bomb() -> bool:
	if bombs > 0:
		bombs -= 1
		EventBus.bomb_used.emit(bombs)
		return true
	return false
