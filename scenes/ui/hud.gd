extends CanvasLayer
## HUD — manages all UI elements via Label nodes + custom draw on HUDDraw child.

@onready var score_label: Label = $ScoreLabel
@onready var high_label: Label = $HighScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var wave_label: Label = $WaveLabel
@onready var combo_label: Label = $ComboLabel
@onready var wave_announce: Label = $WaveAnnounce
@onready var hud_draw: Control = $HUDDraw

var displayed_score: float = 0.0
var target_score: int = 0
var wave_announce_timer: float = 0.0

func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.combo_lost.connect(_on_combo_lost)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.bomb_used.connect(_on_bomb_used)
	EventBus.coin_collected.connect(_on_coin_collected)
	
	_update_lives()
	_update_bombs()
	wave_announce.text = ""
	combo_label.text = ""

func _process(delta: float) -> void:
	# Smooth score
	displayed_score = lerpf(displayed_score, float(target_score), delta * 8.0)
	score_label.text = "SCORE: " + str(int(displayed_score))
	high_label.text = "HIGH: " + str(GameData.high_score)
	
	# Coins
	wave_label.text = "WAVE: " + str(GameData.wave) + "  🪙 " + str(GameData.coins)
	
	# Wave announce fade
	if wave_announce_timer > 0:
		wave_announce_timer -= delta
		wave_announce.modulate.a = clampf(wave_announce_timer / 2.0, 0, 1)
		if wave_announce_timer <= 0:
			wave_announce.text = ""
	
	# Update power-up draw
	if hud_draw:
		hud_draw.queue_redraw()

func _update_lives() -> void:
	var hearts := ""
	for i in GameData.max_lives:
		if i < GameData.lives:
			hearts += "♥"
		else:
			hearts += "♡"
	lives_label.text = hearts

func _update_bombs() -> void:
	pass  # Bomb count shown on bomb button

# === Signal Handlers ===
func _on_score_changed(new_score: int) -> void:
	target_score = new_score

func _on_wave_started(wave_number: int) -> void:
	wave_announce.text = "WAVE " + str(wave_number)
	wave_announce.modulate.a = 1.0
	wave_announce_timer = 3.0

func _on_wave_completed(_wave_number: int) -> void:
	wave_announce.text = "WAVE CLEAR!"
	wave_announce.modulate.a = 1.0
	wave_announce_timer = 2.0

func _on_combo_changed(_combo: int, multiplier: int) -> void:
	if multiplier > 1:
		combo_label.text = "×" + str(multiplier) + " COMBO!"
		combo_label.modulate = Color(1, 1, 0) if multiplier < 5 else Color(1, 0.5, 0) if multiplier < 10 else Color(1, 0.2, 0.2)
	else:
		combo_label.text = ""

func _on_combo_lost() -> void:
	combo_label.text = ""

func _on_player_hit(_lives: int) -> void:
	_update_lives()

func _on_bomb_used(_remaining: int) -> void:
	_update_bombs()

func _on_coin_collected(_value: int) -> void:
	pass  # Auto-updates via _process
