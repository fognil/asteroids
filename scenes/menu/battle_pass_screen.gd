extends Control
## Battle Pass — 30-tier free/premium reward track with XP progression.

const TIERS := [
	{"free": {"type": "coins", "amount": 200}, "premium": {"type": "gems", "amount": 5}},
	{"free": {"type": "coins", "amount": 200}, "premium": {"type": "skin", "name": "EMBER"}},
	{"free": {"type": "bombs", "amount": 2}, "premium": {"type": "coins", "amount": 500}},
	{"free": {"type": "coins", "amount": 300}, "premium": {"type": "trail", "name": "FIRE"}},
	{"free": {"type": "gems", "amount": 3}, "premium": {"type": "frame", "name": "BRONZE"}},
	{"free": {"type": "coins", "amount": 300}, "premium": {"type": "gems", "amount": 10}},
	{"free": {"type": "lives", "amount": 1}, "premium": {"type": "skin", "name": "PHANTOM"}},
	{"free": {"type": "coins", "amount": 400}, "premium": {"type": "coins", "amount": 1000}},
	{"free": {"type": "coins", "amount": 400}, "premium": {"type": "trail", "name": "SPARKLE"}},
	{"free": {"type": "gems", "amount": 5}, "premium": {"type": "gems", "amount": 15}},
	{"free": {"type": "coins", "amount": 500}, "premium": {"type": "skin", "name": "COSMIC"}},
	{"free": {"type": "coins", "amount": 500}, "premium": {"type": "coins", "amount": 1000}},
	{"free": {"type": "bombs", "amount": 3}, "premium": {"type": "gems", "amount": 10}},
	{"free": {"type": "coins", "amount": 600}, "premium": {"type": "trail", "name": "ICE"}},
	{"free": {"type": "gems", "amount": 5}, "premium": {"type": "gems", "amount": 20}},
	{"free": {"type": "coins", "amount": 600}, "premium": {"type": "skin", "name": "FORTRESS"}},
	{"free": {"type": "coins", "amount": 700}, "premium": {"type": "coins", "amount": 1500}},
	{"free": {"type": "coins", "amount": 700}, "premium": {"type": "trail", "name": "NEON"}},
	{"free": {"type": "coins", "amount": 800}, "premium": {"type": "gems", "amount": 15}},
	{"free": {"type": "gems", "amount": 8}, "premium": {"type": "gems", "amount": 25}},
	{"free": {"type": "coins", "amount": 800}, "premium": {"type": "skin", "name": "VOID"}},
	{"free": {"type": "coins", "amount": 900}, "premium": {"type": "coins", "amount": 2000}},
	{"free": {"type": "coins", "amount": 900}, "premium": {"type": "trail", "name": "LIGHTNING"}},
	{"free": {"type": "coins", "amount": 1000}, "premium": {"type": "gems", "amount": 20}},
	{"free": {"type": "gems", "amount": 10}, "premium": {"type": "gems", "amount": 30}},
	{"free": {"type": "coins", "amount": 1000}, "premium": {"type": "skin", "name": "SUPERNOVA"}},
	{"free": {"type": "coins", "amount": 1200}, "premium": {"type": "coins", "amount": 3000}},
	{"free": {"type": "coins", "amount": 1200}, "premium": {"type": "trail", "name": "GALAXY"}},
	{"free": {"type": "coins", "amount": 1500}, "premium": {"type": "gems", "amount": 25}},
	{"free": {"type": "gems", "amount": 15}, "premium": {"type": "legendary", "name": "CHAMPION"}},
]

const XP_PER_TIER := 100

var scroll_offset: float = 0.0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	# Scroll
	elif event is InputEventScreenDrag:
		scroll_offset -= event.relative.y
		scroll_offset = clampf(scroll_offset, 0, float(TIERS.size()) * 65 - 300)
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_offset = maxf(scroll_offset - 40, 0)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_offset = minf(scroll_offset + 40, float(TIERS.size()) * 65 - 300)
			queue_redraw()

func _handle_tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var card_h: float = 55.0
	var x: float = 40.0
	var card_w := vp.x - 80
	
	var current_tier: int = GameData.settings.get("bp_tier", 0)
	var has_premium: bool = GameData.settings.get("bp_premium", false)
	
	for i in TIERS.size():
		var y := 90 + float(i) * (card_h + 10) - scroll_offset
		if y < 50 or y > vp.y - 20:
			continue
		if not Rect2(x, y, card_w, card_h).has_point(pos):
			continue
		
		# Claim free
		var claimed_free: Array = GameData.settings.get("bp_claimed_free", [])
		if i < current_tier and not claimed_free.has(i):
			_claim_reward(TIERS[i]["free"], i, true)
			return
		
		# Claim premium
		if has_premium:
			var claimed_prem: Array = GameData.settings.get("bp_claimed_premium", [])
			if i < current_tier and not claimed_prem.has(i):
				_claim_reward(TIERS[i]["premium"], i, false)
				return

func _claim_reward(reward: Dictionary, tier_idx: int, is_free: bool) -> void:
	var rtype: String = reward["type"]
	match rtype:
		"coins":
			GameData.total_coins += reward["amount"]
		"gems":
			GameData.gems += reward["amount"]
		"bombs":
			GameData.bombs = mini(GameData.bombs + reward["amount"], GameData.max_bombs)
		"lives":
			GameData.lives = mini(GameData.lives + reward["amount"], GameData.max_lives)
	
	var key := "bp_claimed_free" if is_free else "bp_claimed_premium"
	var claimed: Array = GameData.settings.get(key, [])
	claimed.append(tier_idx)
	GameData.settings[key] = claimed
	SaveManager.save_game()
	AudioManager.play_sfx("powerup")
	queue_redraw()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var current_tier: int = GameData.settings.get("bp_tier", 0)
	var current_xp: int = GameData.settings.get("bp_xp", 0)
	var has_premium: bool = GameData.settings.get("bp_premium", false)
	var claimed_free: Array = GameData.settings.get("bp_claimed_free", [])
	var claimed_prem: Array = GameData.settings.get("bp_claimed_premium", [])
	
	# XP progress
	var xp_ratio := float(current_xp) / float(XP_PER_TIER) if current_tier < TIERS.size() else 1.0
	draw_string(font, Vector2(40, 75), "Tier " + str(current_tier + 1) + "/" + str(TIERS.size()) + "  XP: " + str(current_xp) + "/" + str(XP_PER_TIER), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
	draw_rect(Rect2(40, 78, vp.x - 80, 4), Color(0.15, 0.15, 0.15, 0.5))
	draw_rect(Rect2(40, 78, (vp.x - 80) * xp_ratio, 4), Color(0.6, 0.3, 1, 0.7))
	
	var card_h: float = 55.0
	var card_w := vp.x - 80
	var x: float = 40.0
	
	for i in TIERS.size():
		var y := 90 + float(i) * (card_h + 10) - scroll_offset
		if y < 50 or y > vp.y:
			continue
		
		var tier: Dictionary = TIERS[i]
		var unlocked := i < current_tier
		var is_current := i == current_tier
		
		# Background
		var bg := Color(0.06, 0.06, 0.1, 0.6)
		if is_current:
			bg = Color(0.15, 0.1, 0.2, 0.6)
		elif unlocked:
			bg = Color(0.05, 0.08, 0.05, 0.5)
		draw_rect(Rect2(x, y, card_w, card_h), bg)
		
		# Tier number
		draw_string(font, Vector2(x + 8, y + 20), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.4, 0.4))
		
		# Free reward (left half)
		var free_text := _reward_text(tier["free"])
		var free_col := Color(1, 1, 1, 0.8) if unlocked else Color(0.5, 0.5, 0.5)
		if claimed_free.has(i):
			free_col = Color(0, 1, 0.5, 0.5)
			free_text = "✅ " + free_text
		draw_string(font, Vector2(x + 40, y + 20), "FREE: " + free_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, free_col)
		
		# Premium reward (right half)
		var prem_text := _reward_text(tier["premium"])
		var prem_col := Color(0.6, 0.3, 1, 0.6) if not has_premium else (Color(0.6, 0.3, 1, 0.8) if unlocked else Color(0.4, 0.3, 0.5))
		if claimed_prem.has(i):
			prem_col = Color(0, 1, 0.5, 0.5)
			prem_text = "✅ " + prem_text
		var prem_x := x + card_w * 0.5
		draw_string(font, Vector2(prem_x, y + 20), "⭐ " + prem_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, prem_col)
		if not has_premium:
			draw_string(font, Vector2(prem_x, y + 38), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.3, 0.3))
		
		# Claim indicator
		if unlocked and not claimed_free.has(i):
			draw_string(font, Vector2(x + card_w - 60, y + 20), "CLAIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 1, 0.5))
		
		# Border
		var bc := Color(0.2, 0.2, 0.2, 0.2)
		if is_current:
			bc = Color(0.6, 0.3, 1, 0.4)
		draw_rect(Rect2(x, y, card_w, card_h), bc, false, 1.0)

func _reward_text(reward: Dictionary) -> String:
	var rtype: String = reward["type"]
	match rtype:
		"coins": return "💰" + str(reward["amount"])
		"gems": return "💎" + str(reward["amount"])
		"bombs": return "💣×" + str(reward["amount"])
		"lives": return "❤️×" + str(reward["amount"])
		"skin": return "🎨 " + str(reward["name"])
		"trail": return "✨ " + str(reward["name"])
		"frame": return "🖼️ " + str(reward["name"])
		"legendary": return "🏆 " + str(reward["name"])
		_: return str(reward)
