extends Node
## IAPManager — Android In-App Purchase wrapper using GodotGooglePlayBilling plugin.
## Handles purchase flow, product queries, and receipt delivery.

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)

# Product IDs matching Google Play Console
const PRODUCTS := {
	# Coin Packs
	"coins_500": {"type": "inapp", "coins": 500},
	"coins_1200": {"type": "inapp", "coins": 1200},
	"coins_3500": {"type": "inapp", "coins": 3500},
	"coins_8000": {"type": "inapp", "coins": 8000},
	"coins_20000": {"type": "inapp", "coins": 20000},
	# Gem Packs
	"gems_10": {"type": "inapp", "gems": 10},
	"gems_25": {"type": "inapp", "gems": 25},
	"gems_60": {"type": "inapp", "gems": 60},
	"gems_150": {"type": "inapp", "gems": 150},
	# Special
	"starter_pack": {"type": "inapp", "coins": 2000, "gems": 20},
	"no_ads": {"type": "inapp"},
	"vip_pass": {"type": "inapp"},
	"battle_pass": {"type": "inapp"},
}

var billing_plugin: Object = null
var billing_connected: bool = false
var product_details: Dictionary = {}

func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		billing_plugin = Engine.get_singleton("GodotGooglePlayBilling")
		billing_plugin.billing_resume.connect(_on_billing_resume)
		billing_plugin.connected.connect(_on_connected)
		billing_plugin.disconnected.connect(_on_disconnected)
		billing_plugin.connect_error.connect(_on_connect_error)
		billing_plugin.purchases_updated.connect(_on_purchases_updated)
		billing_plugin.purchase_error.connect(_on_purchase_error)
		billing_plugin.product_details_query_completed.connect(_on_product_details)
		billing_plugin.product_details_query_error.connect(_on_product_details_error)
		billing_plugin.purchase_consumed.connect(_on_purchase_consumed)
		billing_plugin.purchase_consumption_error.connect(_on_consumption_error)
		billing_plugin.startConnection()
	else:
		print("[IAP] GodotGooglePlayBilling not available — running in editor/non-Android")

func _on_connected() -> void:
	billing_connected = true
	print("[IAP] Connected to Google Play Billing")
	# Query product details
	var product_ids := PackedStringArray(PRODUCTS.keys())
	billing_plugin.queryProductDetails(product_ids, "inapp")

func _on_disconnected() -> void:
	billing_connected = false
	print("[IAP] Disconnected from billing")

func _on_connect_error(_code: int, _message: String) -> void:
	print("[IAP] Connection error: ", _message)

func _on_billing_resume() -> void:
	if billing_plugin:
		billing_plugin.startConnection()

func _on_product_details(details: Array) -> void:
	for detail in details:
		if detail is Dictionary:
			var pid: String = detail.get("product_id", "")
			if pid != "":
				product_details[pid] = detail
	print("[IAP] Loaded ", product_details.size(), " product details")

func _on_product_details_error(_code: int, _message: String, _ids: Array) -> void:
	print("[IAP] Product details error: ", _message)

func purchase(product_id: String) -> void:
	if not billing_connected:
		purchase_failed.emit(product_id, "Not connected to billing")
		return
	if product_id not in PRODUCTS:
		purchase_failed.emit(product_id, "Unknown product")
		return
	billing_plugin.purchase(product_id)

func _on_purchases_updated(purchases: Array) -> void:
	for purchase_data in purchases:
		if purchase_data is Dictionary:
			var pid: String = purchase_data.get("product_id", "")
			var state: int = purchase_data.get("purchase_state", -1)
			var token: String = purchase_data.get("purchase_token", "")
			
			if state == 1:  # Purchased
				_deliver_product(pid)
				# Consume consumable purchases
				if pid in PRODUCTS and PRODUCTS[pid].get("type", "") == "inapp":
					if pid != "no_ads" and pid != "vip_pass":
						billing_plugin.consumePurchase(token)
					else:
						billing_plugin.acknowledgePurchase(token)
				purchase_completed.emit(pid)

func _on_purchase_error(_code: int, _message: String) -> void:
	print("[IAP] Purchase error: ", _message)
	purchase_failed.emit("", _message)

func _on_purchase_consumed(_token: String) -> void:
	print("[IAP] Purchase consumed")

func _on_consumption_error(_code: int, _message: String, _token: String) -> void:
	print("[IAP] Consumption error: ", _message)

func _deliver_product(product_id: String) -> void:
	if product_id not in PRODUCTS:
		return
	
	var product: Dictionary = PRODUCTS[product_id]
	
	if product.has("coins"):
		var coin_amount: int = product["coins"]
		GameData.total_coins += coin_amount
	if product.has("gems"):
		var gem_amount: int = product["gems"]
		GameData.gems += gem_amount
	
	match product_id:
		"no_ads":
			GameData.settings["no_ads"] = true
		"vip_pass":
			GameData.settings["vip_pass"] = true
			GameData.settings["no_ads"] = true  # VIP includes no ads
		"battle_pass":
			GameData.settings["bp_premium"] = true
	
	SaveManager.save_game()
	print("[IAP] Delivered: ", product_id)

func get_price(product_id: String) -> String:
	if product_id in product_details:
		return product_details[product_id].get("price", "$?.??")
	# Fallback prices
	match product_id:
		"coins_500", "gems_10": return "$0.99"
		"coins_1200", "gems_25", "starter_pack": return "$1.99"
		"coins_3500", "gems_60", "no_ads": return "$4.99"
		"coins_8000", "gems_150", "vip_pass": return "$9.99"
		"coins_20000": return "$19.99"
		"battle_pass": return "$4.99"
	return "$?.??"

func has_no_ads() -> bool:
	return GameData.settings.get("no_ads", false)

func has_vip() -> bool:
	return GameData.settings.get("vip_pass", false)

func restore_purchases() -> void:
	if billing_plugin and billing_connected:
		billing_plugin.queryPurchases("inapp")
