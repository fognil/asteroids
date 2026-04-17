@warning_ignore("unused_signal")
extends Node
## Central signal hub — all game events go through here.
## Avoids tight coupling between scenes.

# === Game State ===
signal game_started
signal game_over(score: int, wave: int)
signal game_paused
signal game_resumed
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# === Player ===
signal player_died
signal player_respawned
signal player_hit(lives_remaining: int)
signal score_changed(new_score: int)
signal combo_changed(combo: int, multiplier: int)
signal combo_lost
signal heat_changed(heat: float)

# === Combat ===
signal asteroid_destroyed(position: Vector2, size: String, asteroid_type: String)
signal enemy_destroyed(enemy_type: String, position: Vector2)
signal boss_damaged(boss_id: String, hp_remaining: int)
signal boss_defeated(boss_id: String)

# === Items ===
signal powerup_collected(type: String)
signal powerup_expired(type: String)
signal coin_collected(value: int)
signal bomb_used(bombs_remaining: int)
