extends Control
## Shop screen — coin/gem packs, special offers.

const COIN_PACKS := [
	{"name": "Handful", "coins": 500, "price": "$0.99", "bonus": ""},
	{"name": "Pile", "coins": 1200, "price": "$1.99", "bonus": "+20%"},
	{"name": "Chest", "coins": 3500, "price": "$4.99", "bonus": "+40%"},
	{"name": "Vault", "coins": 8000, "price": "$9.99", "bonus": "+60%"},
	{"name": "Mega Vault", "coins": 20000, "price": "$19.99", "bonus": "+100% ⭐"},
]

const GEM_PACKS := [
	{"name": "Few", "gems": 10, "price": "$0.99", "bonus": ""},
	{"name": "Bunch", "gems": 25, "price": "$1.99", "bonus": "+25%"},
	{"name": "Pouch", "gems": 60, "price": "$4.99", "bonus": "+50%"},
	{"name": "Hoard", "gems": 150, "price": "$9.99", "bonus": "+100%"},
]

const SPECIAL_OFFERS := [
	{"name": "🚀 Starter Pack", "desc": "💰2000 + 💎20 + Viper Ship", "price": "$1.99"},
	{"name": "🚫 No Ads", "desc": "Remove ALL ad placements", "price": "$4.99"},
	{"name": "⭐ VIP Pass", "desc": "×2 coins permanent + skin", "price": "$9.99"},
]

var active_tab: int = 0  # 0=coins, 1=gems, 2=offers

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	
	# Tab buttons
	if pos.y > 55 and pos.y < 85:
		var tab_w := (vp.x - 80) / 3.0
		var tab_idx := int((pos.x - 40) / tab_w)
		if tab_idx >= 0 and tab_idx < 3:
			active_tab = tab_idx
			queue_redraw()
			return
	
	# Pack buttons (placeholder — IAP not implemented yet)
	# For now, show "Coming Soon" on tap

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	
	# Sub-tabs
	var tab_names := ["💰 Coins", "💎 Gems", "🎁 Offers"]
	var tab_w := (vp.x - 80) / 3.0
	for i in 3:
		var tx := 40 + float(i) * tab_w
		var ty: float = 55.0
		var is_active := i == active_tab
		draw_rect(Rect2(tx, ty, tab_w - 5, 25), Color(0.1, 0.1, 0.15, 0.6) if not is_active else Color(0, 0.2, 0.15, 0.6))
		var label: String = tab_names[i]
		var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		var label_color := Color(0.5, 0.5, 0.5) if not is_active else Color(0, 1, 0.5)
		draw_string(font, Vector2(tx + (tab_w - 5 - ls.x) / 2, ty + 18), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, label_color)
	
	match active_tab:
		0: _draw_coin_packs(vp, font)
		1: _draw_gem_packs(vp, font)
		2: _draw_offers(vp, font)

func _draw_coin_packs(vp: Vector2, font: Font) -> void:
	var y_start: float = 100.0
	var card_h: float = 60.0
	var card_w := vp.x - 80
	var x: float = 40.0
	
	for i in COIN_PACKS.size():
		var pack: Dictionary = COIN_PACKS[i]
		var y := y_start + float(i) * (card_h + 8)
		
		draw_rect(Rect2(x, y, card_w, card_h), Color(0.08, 0.08, 0.12, 0.6))
		
		var pack_name: String = pack["name"]
		draw_string(font, Vector2(x + 15, y + 22), "💰 " + pack_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.85, 0.2))
		
		var coins_val: int = pack["coins"]
		draw_string(font, Vector2(x + 15, y + 45), str(coins_val) + " coins", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
		
		var bonus_str: String = pack["bonus"]
		if bonus_str != "":
			draw_string(font, Vector2(x + 180, y + 45), bonus_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0, 1, 0.5, 0.7))
		
		# Price button
		var price_str: String = pack["price"]
		var btn_x := x + card_w - 90
		draw_rect(Rect2(btn_x, y + 10, 75, 35), Color(0, 0.3, 0.15, 0.5))
		draw_rect(Rect2(btn_x, y + 10, 75, 35), Color(0, 1, 0.5, 0.4), false, 1.0)
		var ps := font.get_string_size(price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, Vector2(btn_x + (75 - ps.x) / 2, y + 33), price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0, 1, 0.5))

func _draw_gem_packs(vp: Vector2, font: Font) -> void:
	var y_start: float = 100.0
	var card_h: float = 60.0
	var card_w := vp.x - 80
	var x: float = 40.0
	
	for i in GEM_PACKS.size():
		var pack: Dictionary = GEM_PACKS[i]
		var y := y_start + float(i) * (card_h + 8)
		
		draw_rect(Rect2(x, y, card_w, card_h), Color(0.06, 0.06, 0.12, 0.6))
		
		var pack_name: String = pack["name"]
		draw_string(font, Vector2(x + 15, y + 22), "💎 " + pack_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.4, 0.8, 1))
		
		var gems_val: int = pack["gems"]
		draw_string(font, Vector2(x + 15, y + 45), str(gems_val) + " gems", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
		
		var bonus_str: String = pack["bonus"]
		if bonus_str != "":
			draw_string(font, Vector2(x + 150, y + 45), bonus_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0, 1, 0.5, 0.7))
		
		var price_str: String = pack["price"]
		var btn_x := x + card_w - 90
		draw_rect(Rect2(btn_x, y + 10, 75, 35), Color(0.1, 0.1, 0.3, 0.5))
		draw_rect(Rect2(btn_x, y + 10, 75, 35), Color(0.4, 0.8, 1, 0.4), false, 1.0)
		var ps := font.get_string_size(price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, Vector2(btn_x + (75 - ps.x) / 2, y + 33), price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.4, 0.8, 1))

func _draw_offers(vp: Vector2, font: Font) -> void:
	var y_start: float = 100.0
	var card_h: float = 70.0
	var card_w := vp.x - 80
	var x: float = 40.0
	
	for i in SPECIAL_OFFERS.size():
		var offer: Dictionary = SPECIAL_OFFERS[i]
		var y := y_start + float(i) * (card_h + 10)
		
		draw_rect(Rect2(x, y, card_w, card_h), Color(0.1, 0.08, 0.02, 0.6))
		draw_rect(Rect2(x, y, card_w, card_h), Color(1, 0.85, 0.2, 0.2), false, 1.0)
		
		var offer_name: String = offer["name"]
		draw_string(font, Vector2(x + 15, y + 22), offer_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0.2))
		
		var desc: String = offer["desc"]
		draw_string(font, Vector2(x + 15, y + 45), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
		
		var price_str: String = offer["price"]
		var btn_x := x + card_w - 90
		draw_rect(Rect2(btn_x, y + 15, 75, 40), Color(0.3, 0.2, 0, 0.5))
		draw_rect(Rect2(btn_x, y + 15, 75, 40), Color(1, 0.85, 0.2, 0.5), false, 1.0)
		var ps := font.get_string_size(price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, Vector2(btn_x + (75 - ps.x) / 2, y + 40), price_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 0.85, 0.2))
