extends Node
## Manages runtime + persistent game state.

# --- Runtime State (reset each game) ---
var score: int = 0
var high_score: int = 0
var lives: int = 3
var max_lives: int = 5
var wave: int = 0
var coins: int = 0  # Session coins
var bombs: int = 3
var max_bombs: int = 5
var combo: int = 0
var combo_multiplier: int = 1
var heat: float = 0.0  # Tracked for HUD

# --- Persistent State ---
var total_coins: int = 0
var gems: int = 0
var total_coins_earned: int = 0
var total_asteroids_destroyed: int = 0
var total_games_played: int = 0
var player_level: int = 1
var player_xp: int = 0
var best_wave: int = 0
var best_combo: int = 0
var equipped_ship: String = "phoenix"

# --- Ships ---
var ships_data: Dictionary = {
	"phoenix": { "unlocked": true, "skin": "default" },
	"viper": { "unlocked": false, "skin": "default" },
	"nebula": { "unlocked": false, "skin": "default" },
	"titan": { "unlocked": false, "skin": "default" },
	"shadow": { "unlocked": false, "skin": "default" },
	"omega": { "unlocked": false, "skin": "default" },
}

const SHIP_STATS := {
	"phoenix": { "name": "Phoenix MK-I", "speed": 60, "fire": 60, "shield": 60, "color": Color(0, 1, 1), "price_coins": 0, "price_gems": 0 },
	"viper": { "name": "Viper", "speed": 85, "fire": 50, "shield": 30, "color": Color(0.2, 1, 0.4), "price_coins": 5000, "price_gems": 0 },
	"nebula": { "name": "Nebula", "speed": 50, "fire": 70, "shield": 70, "color": Color(0.6, 0.3, 1), "price_coins": 12000, "price_gems": 0 },
	"titan": { "name": "Titan", "speed": 35, "fire": 40, "shield": 95, "color": Color(1, 0.8, 0), "price_coins": 25000, "price_gems": 0 },
	"shadow": { "name": "Shadow", "speed": 90, "fire": 80, "shield": 20, "color": Color(0.5, 0, 1), "price_coins": 0, "price_gems": 100 },
	"omega": { "name": "Omega", "speed": 70, "fire": 90, "shield": 50, "color": Color(1, 0.2, 0.2), "price_coins": 0, "price_gems": 250 },
}

# --- Upgrades ---
var upgrades: Dictionary = {
	"fire_rate": 0,
	"thrust_power": 0,
	"shield_duration": 0,
	"bomb_power": 0,
	"magnet_range": 0,
	"extra_life": 0,
	"extra_bomb": 0,
	"score_bonus": 0,
}

const UPGRADE_CONFIG := {
	"fire_rate": { "name": "Fire Rate", "icon": "🔫", "max": 10, "base_cost": 300, "cost_mult": 1.5, "effect": "+15% fire rate / level" },
	"thrust_power": { "name": "Thrust Power", "icon": "🚀", "max": 10, "base_cost": 250, "cost_mult": 1.5, "effect": "+10% thrust / level" },
	"shield_duration": { "name": "Shield Duration", "icon": "🛡️", "max": 10, "base_cost": 400, "cost_mult": 1.5, "effect": "+10% shield / level" },
	"bomb_power": { "name": "Bomb Power", "icon": "💣", "max": 10, "base_cost": 500, "cost_mult": 1.5, "effect": "+15% blast / level" },
	"magnet_range": { "name": "Magnet Range", "icon": "🧲", "max": 10, "base_cost": 200, "cost_mult": 1.4, "effect": "+15% range / level" },
	"extra_life": { "name": "Starting Lives", "icon": "❤️", "max": 3, "base_cost": 2000, "cost_mult": 2.0, "effect": "+1 starting life" },
	"extra_bomb": { "name": "Starting Bombs", "icon": "💣", "max": 3, "base_cost": 1500, "cost_mult": 2.0, "effect": "+1 starting bomb" },
	"score_bonus": { "name": "Score Bonus", "icon": "⭐", "max": 10, "base_cost": 350, "cost_mult": 1.5, "effect": "+5% score / level" },
}

# --- Settings ---
var settings: Dictionary = {
	"control_mode": "floating_joystick",
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 1.0,
	"vibration": true,
	"screen_shake": true,
}

func _ready() -> void:
	SaveManager.load_game()

func reset_game() -> void:
	total_games_played += 1
	
	# Apply upgrade bonuses
	var extra_lives: int = upgrades.get("extra_life", 0)
	var extra_bombs: int = upgrades.get("extra_bomb", 0)
	var base_lives: int = 3 + extra_lives
	var base_bombs: int = 3 + extra_bombs
	
	score = 0
	lives = base_lives
	wave = 0
	combo = 0
	combo_multiplier = 1
	bombs = base_bombs
	coins = 0
	heat = 0.0

func end_game() -> void:
	# Persist session earnings
	total_coins += coins
	total_coins_earned += coins
	
	if wave > best_wave:
		best_wave = wave
	if combo > best_combo:
		best_combo = combo
	
	# XP from gameplay
	var xp_earned := int(score / 100.0) + wave * 10
	add_xp(xp_earned)
	
	SaveManager.save_game()

func add_score(amount: int) -> void:
	var score_level: int = upgrades.get("score_bonus", 0)
	var bonus: float = 1.0 + score_level * 0.05
	if PowerupManager.is_active("score_x2"):
		bonus *= 2.0
	var final_amount := int(float(amount) * float(combo_multiplier) * bonus)
	score += final_amount
	if score > high_score:
		high_score = score
	EventBus.score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	EventBus.player_hit.emit(lives)

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

# --- XP / Level ---
func add_xp(amount: int) -> void:
	player_xp += amount
	var needed := 100 + player_level * 50
	while player_xp >= needed and player_level < 50:
		player_xp -= needed
		player_level += 1
		# Level up rewards
		total_coins += 100
		gems += 1
		if player_level % 5 == 0:
			total_coins += 500
		needed = 100 + player_level * 50

# --- Upgrades ---
func get_upgrade_cost(upgrade_id: String) -> int:
	if upgrade_id not in UPGRADE_CONFIG:
		return 99999
	var config: Dictionary = UPGRADE_CONFIG[upgrade_id]
	var level: int = upgrades.get(upgrade_id, 0)
	if level >= config["max"]:
		return -1  # Maxed
	return int(float(config["base_cost"]) * pow(float(config["cost_mult"]), float(level)))

func buy_upgrade(upgrade_id: String) -> bool:
	var cost := get_upgrade_cost(upgrade_id)
	if cost < 0:
		return false  # Already maxed
	if total_coins < cost:
		return false  # Not enough coins
	
	total_coins -= cost
	upgrades[upgrade_id] = upgrades.get(upgrade_id, 0) + 1
	SaveManager.save_game()
	return true

# --- Ships ---
func unlock_ship(ship_id: String) -> bool:
	if ship_id not in SHIP_STATS:
		return false
	if ships_data[ship_id]["unlocked"]:
		return false
	
	var stats: Dictionary = SHIP_STATS[ship_id]
	var coin_price: int = stats["price_coins"]
	var gem_price: int = stats["price_gems"]
	
	if coin_price > 0:
		if total_coins < coin_price:
			return false
		total_coins -= coin_price
	elif gem_price > 0:
		if gems < gem_price:
			return false
		gems -= gem_price
	
	ships_data[ship_id]["unlocked"] = true
	SaveManager.save_game()
	return true

func equip_ship(ship_id: String) -> bool:
	if ship_id not in ships_data:
		return false
	if not ships_data[ship_id]["unlocked"]:
		return false
	equipped_ship = ship_id
	SaveManager.save_game()
	return true

func get_ship_color() -> Color:
	if equipped_ship in SHIP_STATS:
		return SHIP_STATS[equipped_ship]["color"]
	return Color(0, 1, 1)
