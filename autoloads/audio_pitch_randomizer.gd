extends Node
## Central pitch randomizer and audio utility for repetitive sound effects.
## Provides narrow-band pitch randomization, timestamp-based concurrency throttling,
## and consistent audio bus routing / volume attenuation across gameplay systems.

const DEFAULT_MIN_PITCH: float = 0.95
const DEFAULT_MAX_PITCH: float = 1.05
const DEFAULT_THROTTLE_INTERVAL_MSEC: int = 50
const MIN_AUDIO_INTERVAL_MSEC: int = 50

static var _last_audio_play_msec: Dictionary = {}

## Returns a randomized pitch scale within [min_scale, max_scale].
static func get_randomized_pitch(min_scale: float = DEFAULT_MIN_PITCH, max_scale: float = DEFAULT_MAX_PITCH) -> float:
	return randf_range(min_scale, max_scale)

## Checks whether audio associated with `key` can play without violating concurrency throttle.
static func can_play_audio(key: Variant, min_interval_ms: int = DEFAULT_THROTTLE_INTERVAL_MSEC, now_msec: int = -1) -> bool:
	if now_msec < 0:
		now_msec = Time.get_ticks_msec()
	if not _last_audio_play_msec.has(key):
		return true
	return (now_msec - int(_last_audio_play_msec[key])) >= min_interval_ms

## Records the timestamp when an audio cue with `key` was triggered.
static func record_audio_played(key: Variant, now_msec: int = -1) -> void:
	if now_msec < 0:
		now_msec = Time.get_ticks_msec()
	_last_audio_play_msec[key] = now_msec

## Resets all concurrency throttle timestamps.
static func reset_throttle() -> void:
	_last_audio_play_msec.clear()

## Configures an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node.
static func configure_player(player: Node, bus_name: StringName = &"SFX", volume_db: float = 0.0, max_distance: float = 0.0) -> void:
	if player == null:
		return
	if "bus" in player:
		player.bus = bus_name
	if "volume_db" in player:
		player.volume_db = volume_db
	if max_distance > 0.0 and "max_distance" in player:
		player.max_distance = max_distance

## Helper to apply randomized pitch and trigger playback if not throttled.
static func play_sound(
	player: Node,
	key: Variant = null,
	min_interval_ms: int = DEFAULT_THROTTLE_INTERVAL_MSEC,
	min_scale: float = DEFAULT_MIN_PITCH,
	max_scale: float = DEFAULT_MAX_PITCH,
	now_msec: int = -1
) -> bool:
	if player == null:
		return false
	var stream_key: Variant = key
	if stream_key == null:
		stream_key = player.get("stream") if player.get("stream") != null else player
	if now_msec < 0:
		now_msec = Time.get_ticks_msec()
	if not can_play_audio(stream_key, min_interval_ms, now_msec):
		return false
	record_audio_played(stream_key, now_msec)
	if "pitch_scale" in player:
		player.pitch_scale = get_randomized_pitch(min_scale, max_scale)
	if player.has_method("play"):
		if "stream" in player:
			if player.stream != null:
				player.play()
		else:
			player.play()
	return true
