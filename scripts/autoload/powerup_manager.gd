extends Node
## PowerupManager — tracks active power-ups, applies/removes effects.

# Active power-ups: { type_name: { "remaining": float, "duration": float } }
var active_powerups: Dictionary = {}

# Saved original values for safe deactivation
var _original_fire_rate: float = -1.0
var _slow_mo_active: bool = false

# Power-up type definitions
const POWERUP_TYPES := {
	"shield": { "duration": 15.0, "color": Color(0.2, 0.6, 1.0), "instant": false },
	"multi_shot": { "duration": 10.0, "color": Color(0.2, 1.0, 0.4), "instant": false },
	"rapid_fire": { "duration": 8.0, "color": Color(1.0, 1.0, 0.2), "instant": false },
	"piercing": { "duration": 8.0, "color": Color(1.0, 0.3, 0.2), "instant": false },
	"slow_mo": { "duration": 5.0, "color": Color(0.4, 0.2, 1.0), "instant": false },
	"score_x2": { "duration": 12.0, "color": Color(1.0, 0.85, 0.0), "instant": false },
	"extra_life": { "duration": 0.0, "color": Color(1.0, 0.4, 0.6), "instant": true },
	"bomb_pickup": { "duration": 0.0, "color": Color(1.0, 0.6, 0.0), "instant": true },
}

func _process(delta: float) -> void:
	var expired: Array[String] = []
	for type in active_powerups:
		active_powerups[type]["remaining"] -= delta
		if active_powerups[type]["remaining"] <= 0:
			expired.append(type)
	
	for type in expired:
		_deactivate(type)

func activate(type: String) -> void:
	if type not in POWERUP_TYPES:
		return
	
	var config: Dictionary = POWERUP_TYPES[type]
	
	# Instant power-ups
	if config["instant"]:
		_apply_instant(type)
		return
	
	# Duration power-ups — reset if already active (no stacking)
	if type in active_powerups:
		active_powerups[type]["remaining"] = config["duration"]
	else:
		active_powerups[type] = {
			"remaining": config["duration"],
			"duration": config["duration"]
		}
		_apply_effect(type)
	
	EventBus.powerup_collected.emit(type)

func _apply_instant(type: String) -> void:
	match type:
		"extra_life":
			if GameData.lives < GameData.max_lives:
				GameData.lives += 1
				EventBus.player_hit.emit(GameData.lives)
		"bomb_pickup":
			if GameData.bombs < GameData.max_bombs:
				GameData.bombs += 1
	EventBus.powerup_collected.emit(type)

func _apply_effect(type: String) -> void:
	var player := _get_player()
	if player == null:
		return
	
	match type:
		"shield":
			player.has_shield = true
			AudioManager.play_sfx("shield_activate")
		"rapid_fire":
			# Save original value for safe restoration
			if _original_fire_rate < 0:
				_original_fire_rate = player.fire_rate
			player.fire_rate = _original_fire_rate * 0.5
		"slow_mo":
			_slow_mo_active = true
			Engine.time_scale = 0.5
		"multi_shot":
			pass
		"piercing":
			pass
		"score_x2":
			pass  # Handled in GameData.add_score

func _deactivate(type: String) -> void:
	if type not in active_powerups:
		return
	
	var player := _get_player()
	if player:
		match type:
			"shield":
				player.has_shield = false
			"rapid_fire":
				# Restore original value instead of multiply
				if _original_fire_rate > 0:
					player.fire_rate = _original_fire_rate
					_original_fire_rate = -1.0
			"slow_mo":
				_slow_mo_active = false
				# Only restore if camera isn't also doing slow-mo
				if not _is_camera_slow_mo():
					Engine.time_scale = 1.0
	
	active_powerups.erase(type)
	EventBus.powerup_expired.emit(type)

func is_active(type: String) -> bool:
	return type in active_powerups

func is_slow_mo_active() -> bool:
	return _slow_mo_active

func get_remaining(type: String) -> float:
	if type in active_powerups:
		return active_powerups[type]["remaining"]
	return 0.0

func get_ratio(type: String) -> float:
	if type in active_powerups:
		var data: Dictionary = active_powerups[type]
		return data["remaining"] / data["duration"]
	return 0.0

func reset() -> void:
	# Deactivate all
	for type in active_powerups.keys():
		_deactivate(type)
	active_powerups.clear()
	_original_fire_rate = -1.0
	_slow_mo_active = false

func _get_player() -> CharacterBody2D:
	var p := Engine.get_main_loop()
	if p is SceneTree:
		return (p as SceneTree).get_first_node_in_group("player") as CharacterBody2D
	return null

func _is_camera_slow_mo() -> bool:
	var p := Engine.get_main_loop()
	if p is SceneTree:
		var cam := (p as SceneTree).root.get_viewport().get_camera_2d()
		if cam and "slow_mo_timer" in cam:
			return cam.slow_mo_timer > 0
	return false
