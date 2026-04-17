extends Node
## AudioManager — Procedural SFX + Music bus control.
## Generates retro synth sounds once at startup and caches them.

var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 0.8

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8
var music_player: AudioStreamPlayer = null

# Cached SFX streams — generated once, played many times
var _sfx_cache: Dictionary = {}

func _ready() -> void:
	# Create SFX player pool
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)
	
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	_apply_volumes()
	_generate_all_sfx()

func _apply_volumes() -> void:
	master_volume = GameData.settings.get("master_volume", 0.8)
	music_volume = GameData.settings.get("music_volume", 0.6)
	sfx_volume = GameData.settings.get("sfx_volume", 0.8)

func _get_free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]  # Steal oldest

# === Procedural SFX Generation ===

func _generate_tone(freq: float, duration: float, volume: float = 1.0, wave_type: int = 0) -> AudioStreamWAV:
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false
	
	var data := PackedByteArray()
	data.resize(samples)
	
	for i in samples:
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (t / duration)  # Linear decay
		env = clampf(env, 0, 1)
		
		var sample: float = 0.0
		match wave_type:
			0:  # Sine
				sample = sin(t * freq * TAU)
			1:  # Square
				sample = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			2:  # Noise
				sample = randf_range(-1, 1)
			3:  # Sawtooth
				sample = fmod(t * freq, 1.0) * 2.0 - 1.0
		
		sample *= env * volume
		data[i] = int(clampf(sample * 127 + 128, 0, 255))
	
	audio.data = data
	return audio

func _generate_sweep(start_freq: float, end_freq: float, duration: float, volume: float = 1.0) -> AudioStreamWAV:
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false
	
	var data := PackedByteArray()
	data.resize(samples)
	
	for i in samples:
		var t := float(i) / float(sample_rate)
		var ratio := t / duration
		var freq := lerpf(start_freq, end_freq, ratio)
		var env := 1.0 - ratio
		var sample := sin(t * freq * TAU) * env * volume
		data[i] = int(clampf(sample * 127 + 128, 0, 255))
	
	audio.data = data
	return audio

# === Cache all SFX at startup ===

func _generate_all_sfx() -> void:
	# Generate at unity volume (1.0) — volume adjusted at playback via volume_db
	_sfx_cache["shoot"] = _generate_sweep(800, 200, 0.08, 1.0)
	_sfx_cache["asteroid_hit"] = _generate_tone(150, 0.1, 1.0, 2)
	_sfx_cache["asteroid_split"] = _generate_sweep(300, 80, 0.15, 1.0)
	_sfx_cache["explosion"] = _generate_tone(80, 0.3, 1.0, 2)
	_sfx_cache["explosion_big"] = _generate_tone(50, 0.5, 1.0, 2)
	_sfx_cache["coin_collect"] = _generate_tone(1200, 0.06, 0.7, 0)
	_sfx_cache["powerup"] = _generate_sweep(400, 1200, 0.2, 0.6)
	_sfx_cache["shield_activate"] = _generate_sweep(300, 800, 0.3, 0.5)
	_sfx_cache["shield_break"] = _generate_sweep(800, 100, 0.2, 1.0)
	_sfx_cache["player_hit"] = _generate_sweep(400, 60, 0.3, 1.0)
	_sfx_cache["player_death"] = _generate_tone(60, 0.8, 1.0, 2)
	_sfx_cache["bomb"] = _generate_tone(40, 0.6, 1.0, 2)
	_sfx_cache["overheat"] = _generate_tone(1000, 0.15, 0.4, 1)
	_sfx_cache["ufo_appear"] = _generate_sweep(200, 600, 0.4, 0.3)
	_sfx_cache["boss_warning"] = _generate_tone(600, 0.5, 0.8, 1)
	_sfx_cache["boss_hit"] = _generate_tone(120, 0.15, 1.0, 2)
	_sfx_cache["boss_death"] = _generate_tone(30, 1.2, 1.0, 2)
	_sfx_cache["combo_up"] = _generate_sweep(600, 1000, 0.1, 0.5)
	_sfx_cache["combo_lost"] = _generate_sweep(500, 200, 0.2, 0.4)
	_sfx_cache["ui_tap"] = _generate_tone(800, 0.03, 0.3, 0)
	_sfx_cache["wave_start"] = _generate_sweep(300, 600, 0.15, 0.5)
	_sfx_cache["wave_clear"] = _generate_sweep(400, 1200, 0.3, 0.6)
	_sfx_cache["game_over"] = _generate_sweep(600, 100, 0.6, 0.6)

# === Play SFX ===

func play_sfx(sfx_name: String) -> void:
	var vol := master_volume * sfx_volume
	if vol < 0.01:
		return
	
	if sfx_name not in _sfx_cache:
		return
	
	var player := _get_free_player()
	player.stream = _sfx_cache[sfx_name]
	player.volume_db = linear_to_db(vol)
	player.play()

# === Music ===

func play_music(_track: String) -> void:
	# Placeholder — in production, load actual music files
	# For now, generate a simple ambient tone
	var vol := master_volume * music_volume
	if vol < 0.01:
		return
	
	var stream := _generate_tone(110, 2.0, vol * 0.15, 0)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size()
	music_player.stream = stream
	music_player.volume_db = linear_to_db(vol * 0.3)
	music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()
