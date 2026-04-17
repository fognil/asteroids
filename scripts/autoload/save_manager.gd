extends Node
## SaveManager — handles save/load game data to disk.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := "2.0"

func save_game() -> void:
	var data := _build_save_data()
	var json_string := JSON.stringify(data, "  ")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return false
	
	var data: Dictionary = json.data
	
	# Version check & migration
	var saved_version: String = data.get("version", "1.0")
	if saved_version != SAVE_VERSION:
		data = _migrate_save(data, saved_version)
	
	_apply_save_data(data)
	return true

func _migrate_save(data: Dictionary, from_version: String) -> Dictionary:
	# Add migration steps here as versions change
	# Example: if from_version < "2.0", add new fields with defaults
	if not data.has("player"):
		data["player"] = {}
	var p: Dictionary = data["player"]
	# Ensure all fields exist with defaults
	p["level"] = p.get("level", 1)
	p["xp"] = p.get("xp", 0)
	p["coins"] = p.get("coins", 0)
	p["gems"] = p.get("gems", 0)
	p["high_score"] = p.get("high_score", 0)
	p["best_wave"] = p.get("best_wave", 0)
	p["best_combo"] = p.get("best_combo", 0)
	p["total_asteroids"] = p.get("total_asteroids", 0)
	p["total_games"] = p.get("total_games", 0)
	p["total_coins_earned"] = p.get("total_coins_earned", 0)
	data["version"] = SAVE_VERSION
	return data

func _build_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"player": {
			"level": GameData.player_level,
			"xp": GameData.player_xp,
			"coins": GameData.total_coins,
			"gems": GameData.gems,
			"high_score": GameData.high_score,
			"best_wave": GameData.best_wave,
			"best_combo": GameData.best_combo,
			"total_asteroids": GameData.total_asteroids_destroyed,
			"total_games": GameData.total_games_played,
			"total_coins_earned": GameData.total_coins_earned,
		},
		"ships": GameData.ships_data.duplicate(true),
		"upgrades": GameData.upgrades.duplicate(true),
		"settings": GameData.settings.duplicate(true),
		"equipped_ship": GameData.equipped_ship,
	}

func _apply_save_data(data: Dictionary) -> void:
	if "player" in data:
		var p: Dictionary = data["player"]
		GameData.player_level = p.get("level", 1)
		GameData.player_xp = p.get("xp", 0)
		GameData.total_coins = p.get("coins", 0)
		GameData.gems = p.get("gems", 0)
		GameData.high_score = p.get("high_score", 0)
		GameData.best_wave = p.get("best_wave", 0)
		GameData.best_combo = p.get("best_combo", 0)
		GameData.total_asteroids_destroyed = p.get("total_asteroids", 0)
		GameData.total_games_played = p.get("total_games", 0)
		GameData.total_coins_earned = p.get("total_coins_earned", 0)
	
	if "ships" in data:
		GameData.ships_data = data["ships"]
	
	if "upgrades" in data:
		GameData.upgrades = data["upgrades"]
	
	if "settings" in data:
		GameData.settings = data["settings"]
	
	if "equipped_ship" in data:
		GameData.equipped_ship = data["equipped_ship"]
