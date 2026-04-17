extends CanvasLayer
## HUD — displays score, lives, wave, combo, heat, and game over.

@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var wave_label: Label = $WaveLabel
@onready var combo_label: Label = $ComboLabel
@onready var heat_bar: ColorRect = $HeatBarBg/HeatBar
@onready var game_over_panel: Control = $GameOverPanel
@onready var game_over_score: Label = $GameOverPanel/GameOverScore
@onready var wave_announce: Label = $WaveAnnounce

var displayed_score: float = 0.0
var wave_announce_timer: float = 0.0

func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.combo_lost.connect(_on_combo_lost)
	EventBus.heat_changed.connect(_on_heat_changed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.player_died.connect(func(): pass)  # Placeholder
	
	game_over_panel.visible = false
	wave_announce.visible = false
	combo_label.visible = false
	_update_lives(3)

func _process(delta: float) -> void:
	# Smooth score display
	displayed_score = lerpf(displayed_score, GameData.score, 10.0 * delta)
	score_label.text = "SCORE: %d" % int(displayed_score)
	high_score_label.text = "HIGH: %d" % GameData.high_score
	
	# Wave announce fade
	if wave_announce.visible:
		wave_announce_timer -= delta
		if wave_announce_timer <= 0:
			wave_announce.visible = false
		elif wave_announce_timer < 0.5:
			wave_announce.modulate.a = wave_announce_timer / 0.5

func _on_score_changed(_score: int) -> void:
	pass  # Handled in _process via lerp

func _on_player_hit(lives: int) -> void:
	_update_lives(lives)

func _update_lives(lives: int) -> void:
	var hearts := ""
	for i in lives:
		hearts += "♥ "
	for i in range(lives, GameData.max_lives):
		hearts += "♡ "
	lives_label.text = hearts.strip_edges()

func _on_wave_started(wave: int) -> void:
	wave_label.text = "WAVE: %d" % wave
	wave_announce.text = "W A V E  %d" % wave
	wave_announce.visible = true
	wave_announce.modulate.a = 1.0
	wave_announce_timer = 2.0

func _on_wave_completed(_wave: int) -> void:
	wave_announce.text = "W A V E  C L E A R !"
	wave_announce.visible = true
	wave_announce.modulate.a = 1.0
	wave_announce_timer = 1.5

func _on_combo_changed(combo: int, multiplier: int) -> void:
	if combo >= 5:
		combo_label.visible = true
		combo_label.text = "×%d COMBO" % combo
		if multiplier >= 10:
			combo_label.text += "\n🔥 LEGENDARY!"
			combo_label.add_theme_font_size_override("font_size", 48)
		elif multiplier >= 5:
			combo_label.text += "\n💀 INSANE!"
			combo_label.add_theme_font_size_override("font_size", 40)
		elif multiplier >= 3:
			combo_label.text += "\n⚡ AMAZING!"
			combo_label.add_theme_font_size_override("font_size", 34)
		elif multiplier >= 2:
			combo_label.text += "\n✨ GREAT!"
			combo_label.add_theme_font_size_override("font_size", 28)
	else:
		combo_label.visible = combo > 0
		combo_label.text = "×%d" % combo if combo > 0 else ""
		combo_label.add_theme_font_size_override("font_size", 22)

func _on_combo_lost() -> void:
	combo_label.visible = false

func _on_heat_changed(heat: float) -> void:
	var ratio := heat / 100.0
	heat_bar.scale.x = ratio
	if heat >= 80:
		heat_bar.color = Color(1, 0, 0)
	elif heat >= 50:
		heat_bar.color = Color(1, 1, 0)
	else:
		heat_bar.color = Color(0, 0.7, 1)

func _on_game_over(score: int, wave: int) -> void:
	game_over_panel.visible = true
	game_over_score.text = "SCORE: %d\nWAVE: %d\nBEST: %d\n\n[TAP TO RESTART]" % [score, wave, GameData.high_score]
