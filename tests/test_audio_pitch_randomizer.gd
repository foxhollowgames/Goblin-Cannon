extends "res://tests/test_base.gd"

const AudioPitchRandomizerScript = preload("res://autoloads/audio_pitch_randomizer.gd")

func _init() -> void:
	suite_name = "AudioPitchRandomizer"

func run() -> void:
	test_default_pitch_range()
	test_custom_pitch_range()
	test_pitch_variation_across_calls()
	test_audio_concurrency_throttling()
	test_throttling_independent_keys()
	test_throttle_reset()
	test_configure_player_buses()
	test_configure_player_2d_max_distance()
	test_play_sound_workflow()

func test_default_pitch_range() -> void:
	begin("get_randomized_pitch produces values strictly within default [0.95, 1.05] range")
	for i in range(100):
		var p: float = AudioPitchRandomizer.get_randomized_pitch()
		assert_gte(p, AudioPitchRandomizer.DEFAULT_MIN_PITCH, "pitch >= default min")
		assert_lte(p, AudioPitchRandomizer.DEFAULT_MAX_PITCH, "pitch <= default max")

func test_custom_pitch_range() -> void:
	begin("get_randomized_pitch produces values strictly within custom ranges")
	for i in range(50):
		var p: float = AudioPitchRandomizer.get_randomized_pitch(0.80, 1.20)
		assert_gte(p, 0.80, "custom pitch >= 0.80")
		assert_lte(p, 1.20, "custom pitch <= 1.20")

func test_pitch_variation_across_calls() -> void:
	begin("get_randomized_pitch produces varied values across consecutive invocations")
	var pitches: Array[float] = []
	for i in range(20):
		pitches.append(AudioPitchRandomizer.get_randomized_pitch())

	var has_variation: bool = false
	for i in range(1, pitches.size()):
		if not is_equal_approx(pitches[i], pitches[0]):
			has_variation = true
			break
	assert_true(has_variation, "pitch scale varies across activations")

func test_audio_concurrency_throttling() -> void:
	begin("can_play_audio throttles rapid sequential triggers on identical key")
	AudioPitchRandomizer.reset_throttle()
	var key: StringName = &"sfx_hit"

	# Initial play at t = 1000
	assert_true(AudioPitchRandomizer.can_play_audio(key, 50, 1000), "initial trigger is allowed")
	AudioPitchRandomizer.record_audio_played(key, 1000)

	# Trigger at t = 1020 (delta 20ms < 50ms) -> throttled
	assert_false(AudioPitchRandomizer.can_play_audio(key, 50, 1020), "trigger within 50ms is throttled")

	# Trigger at t = 1050 (delta 50ms == 50ms) -> allowed
	assert_true(AudioPitchRandomizer.can_play_audio(key, 50, 1050), "trigger at exact 50ms interval is allowed")
	AudioPitchRandomizer.record_audio_played(key, 1050)

	# Trigger at t = 1110 (delta 60ms > 50ms) -> allowed
	assert_true(AudioPitchRandomizer.can_play_audio(key, 50, 1110), "trigger after interval is allowed")

func test_throttling_independent_keys() -> void:
	begin("Concurrency throttling tracks different keys independently")
	AudioPitchRandomizer.reset_throttle()
	var key_a: StringName = &"cannon_fire"
	var key_b: StringName = &"wall_hit"

	AudioPitchRandomizer.record_audio_played(key_a, 1000)
	assert_false(AudioPitchRandomizer.can_play_audio(key_a, 50, 1020), "key_a throttled at t=1020")
	assert_true(AudioPitchRandomizer.can_play_audio(key_b, 50, 1020), "key_b allowed at t=1020")

func test_throttle_reset() -> void:
	begin("reset_throttle clears all recorded timestamps")
	var key: StringName = &"bumper_bounce"
	AudioPitchRandomizer.record_audio_played(key, 1000)
	assert_false(AudioPitchRandomizer.can_play_audio(key, 50, 1020), "key throttled before reset")

	AudioPitchRandomizer.reset_throttle()
	assert_true(AudioPitchRandomizer.can_play_audio(key, 50, 1020), "key allowed immediately after reset")

func test_configure_player_buses() -> void:
	begin("configure_player assigns player to SFX, Machinery, and UI buses with volume_db")
	var player = AudioStreamPlayer.new()

	AudioPitchRandomizer.configure_player(player, &"SFX", -6.0)
	assert_eq(player.bus, &"SFX", "routed to SFX bus")
	assert_approx(player.volume_db, -6.0, 0.01, "volume set to -6.0 dB")

	AudioPitchRandomizer.configure_player(player, &"Machinery", -16.0)
	assert_eq(player.bus, &"Machinery", "routed to Machinery bus")
	assert_approx(player.volume_db, -16.0, 0.01, "volume set to -16.0 dB")

	AudioPitchRandomizer.configure_player(player, &"UI", -8.0)
	assert_eq(player.bus, &"UI", "routed to UI bus")
	assert_approx(player.volume_db, -8.0, 0.01, "volume set to -8.0 dB")

	player.free()

func test_configure_player_2d_max_distance() -> void:
	begin("configure_player configures max_distance on AudioStreamPlayer2D")
	var player_2d = AudioStreamPlayer2D.new()
	AudioPitchRandomizer.configure_player(player_2d, &"Machinery", -14.0, 1200.0)

	assert_eq(player_2d.bus, &"Machinery", "player_2d routed to Machinery")
	assert_approx(player_2d.volume_db, -14.0, 0.01, "player_2d volume is -14.0 dB")
	assert_approx(player_2d.max_distance, 1200.0, 0.01, "player_2d max_distance is 1200.0")

	player_2d.free()

func test_play_sound_workflow() -> void:
	begin("play_sound modulates pitch and enforces throttling")
	AudioPitchRandomizer.reset_throttle()
	var player = AudioStreamPlayer2D.new()
	var key: String = "test_cue"

	var played_first: bool = AudioPitchRandomizer.play_sound(player, key, 50, 0.95, 1.05, 2000)
	assert_true(played_first, "first play_sound call succeeds")
	assert_gte(player.pitch_scale, 0.95, "pitch_scale >= 0.95")
	assert_lte(player.pitch_scale, 1.05, "pitch_scale <= 1.05")

	var played_second: bool = AudioPitchRandomizer.play_sound(player, key, 50, 0.95, 1.05, 2020)
	assert_false(played_second, "second play_sound within throttle interval returns false")

	var played_third: bool = AudioPitchRandomizer.play_sound(player, key, 50, 0.95, 1.05, 2060)
	assert_true(played_third, "third play_sound after interval succeeds")

	player.free()

