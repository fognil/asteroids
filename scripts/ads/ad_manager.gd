extends Node
## AdManager — Rewarded ad wrapper for AdMob on Android.
## Placements: Revive, Double Coins, Daily ×2, Free Bomb, Bonus Coins.

signal ad_rewarded(placement: String)
signal ad_failed(placement: String)

var admob_plugin: Object = null
var is_loaded: bool = false
var current_placement: String = ""

# AdMob Rewarded Ad Unit IDs (replace with real ones for production)
const AD_UNIT_REWARDED := "ca-app-pub-3940256099942544/5224354917"  # Test ID

# Session caps
var revive_count: int = 0
var double_coins_count: int = 0
const MAX_REVIVE_PER_SESSION := 2
const MAX_DOUBLE_COINS_PER_GAME := 1

func _ready() -> void:
	if Engine.has_singleton("AdMob"):
		admob_plugin = Engine.get_singleton("AdMob")
		admob_plugin.initialization_complete.connect(_on_init_complete)
		admob_plugin.rewarded_ad_loaded.connect(_on_ad_loaded)
		admob_plugin.rewarded_ad_failed_to_load.connect(_on_ad_failed_to_load)
		admob_plugin.rewarded_interstitial_ad_loaded.connect(_on_ad_loaded)
		admob_plugin.user_earned_reward.connect(_on_user_earned_reward)
		admob_plugin.rewarded_ad_closed.connect(_on_ad_closed)
		admob_plugin.initialize()
	else:
		print("[Ads] AdMob not available — running in editor/non-Android")

func _on_init_complete(_status: int) -> void:
	print("[Ads] AdMob initialized")
	_preload_ad()

func _preload_ad() -> void:
	if admob_plugin:
		admob_plugin.load_rewarded_ad(AD_UNIT_REWARDED)

func _on_ad_loaded(_unit: String) -> void:
	is_loaded = true
	print("[Ads] Rewarded ad loaded")

func _on_ad_failed_to_load(_unit: String, _error: int) -> void:
	is_loaded = false
	print("[Ads] Failed to load ad")

func can_show_ad(placement: String) -> bool:
	# Respect No Ads purchase
	if GameData.settings.get("no_ads", false):
		return false
	
	match placement:
		"revive":
			return revive_count < MAX_REVIVE_PER_SESSION
		"double_coins":
			return double_coins_count < MAX_DOUBLE_COINS_PER_GAME
		"daily_x2":
			var claimed: bool = GameData.settings.get("daily_ad_claimed", false)
			return not claimed
		"free_bomb":
			return true
		"bonus_coins":
			var today_count: int = GameData.settings.get("bonus_ad_count", 0)
			return today_count < 5
	return false

func show_ad(placement: String) -> void:
	current_placement = placement
	
	if admob_plugin and is_loaded:
		admob_plugin.show_rewarded_ad()
	else:
		# Fallback for testing — auto-reward in editor
		print("[Ads] No ad available, auto-rewarding for testing")
		_deliver_reward(placement)

func _on_user_earned_reward(_unit: String, _type: String, _amount: int) -> void:
	_deliver_reward(current_placement)

func _on_ad_closed(_unit: String) -> void:
	is_loaded = false
	_preload_ad()  # Preload next ad

func _deliver_reward(placement: String) -> void:
	match placement:
		"revive":
			revive_count += 1
			GameData.lives = 1
			ad_rewarded.emit("revive")
		"double_coins":
			double_coins_count += 1
			GameData.total_coins += GameData.coins  # Double session coins
			ad_rewarded.emit("double_coins")
		"daily_x2":
			GameData.settings["daily_ad_claimed"] = true
			ad_rewarded.emit("daily_x2")
		"free_bomb":
			GameData.bombs = mini(GameData.bombs + 1, GameData.max_bombs)
			ad_rewarded.emit("free_bomb")
		"bonus_coins":
			GameData.total_coins += 100
			var count: int = GameData.settings.get("bonus_ad_count", 0)
			GameData.settings["bonus_ad_count"] = count + 1
			ad_rewarded.emit("bonus_coins")
	
	SaveManager.save_game()

func reset_session() -> void:
	revive_count = 0
	double_coins_count = 0
