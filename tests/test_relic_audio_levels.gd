extends "res://tests/test_base.gd"

const PolyominoMachineryComponentScript = preload("res://scenes/board/machinery/polyomino_machinery_component.gd")
const PinballBumperScript = preload("res://scenes/board/machinery/pinball_bumper.gd")
const SpeedBoostWheelScript = preload("res://scenes/board/machinery/speed_boost_wheel.gd")
const ManaSiphonScript = preload("res://scenes/board/machinery/mana_siphon.gd")
const DirectionalDeflectorScript = preload("res://scenes/board/machinery/directional_deflector.gd")

func _init() -> void:
	suite_name = "RelicAudioLevels"

func run() -> void:
	test_default_machinery_volume_levels()
	test_dedicated_audio_bus_routing()
	test_pitch_modulation_range()
	test_audio_concurrency_throttling()

func test_default_machinery_volume_levels() -> void:
	begin("Relic machinery base volume levels are below -12.0 dB and within [-18.0 dB, -14.0 dB]")
	
	var bumper = PinballBumperScript.new()
	var siphon = ManaSiphonScript.new()
	var booster = SpeedBoostWheelScript.new()
	var deflector = DirectionalDeflectorScript.new()
	
	var components: Array = [bumper, siphon, booster, deflector]
	for comp in components:
		var player: AudioStreamPlayer2D = comp.get_audio_player()
		assert_true(player != null, "audio player exists for component")
		assert_true(player.volume_db <= -12.0, "volume_db (%f) is below -12.0 dB" % player.volume_db)
		assert_true(player.volume_db >= -18.0 and player.volume_db <= -14.0, "volume_db (%f) is within [-18.0 dB, -14.0 dB]" % player.volume_db)
		comp.free()

func test_dedicated_audio_bus_routing() -> void:
	begin("Relic machinery audio players route to dedicated Machinery bus")
	
	var bumper = PinballBumperScript.new()
	var siphon = ManaSiphonScript.new()
	var booster = SpeedBoostWheelScript.new()
	var deflector = DirectionalDeflectorScript.new()
	
	var components: Array = [bumper, siphon, booster, deflector]
	for comp in components:
		var player: AudioStreamPlayer2D = comp.get_audio_player()
		assert_true(player != null, "audio player exists for component")
		assert_eq(player.bus, &"Machinery", "audio player routes to Machinery bus")
		comp.free()

func test_pitch_modulation_range() -> void:
	begin("Audio feedback applies random pitch modulation between 0.95 and 1.05")
	
	var bumper = PinballBumperScript.new()
	bumper.get_audio_player()
	
	var pitches: Array[float] = []
	for i in range(20):
		PolyominoMachineryComponentScript.reset_audio_throttle()
		bumper._play_audio_feedback()
		var p: float = bumper.get_audio_player().pitch_scale
		assert_true(p >= 0.95 and p <= 1.05, "pitch_scale (%f) is within [0.95, 1.05]" % p)
		pitches.append(p)
	
	# Verify that pitch modulation is not strictly static
	var has_variation: bool = false
	for i in range(1, pitches.size()):
		if not is_equal_approx(pitches[i], pitches[0]):
			has_variation = true
			break
	assert_true(has_variation, "pitch scale varies across activations")
	
	bumper.free()

func test_audio_concurrency_throttling() -> void:
	begin("Audio concurrency throttling suppresses rapid sequential triggers")
	
	var bumper1 = PinballBumperScript.new()
	var bumper2 = PinballBumperScript.new()
	
	PolyominoMachineryComponentScript.reset_audio_throttle()
	
	# Initial trigger at t = 1000ms
	assert_true(bumper1.can_play_audio(1000), "initial audio trigger is allowed")
	bumper1._play_audio_feedback(1000)
	
	# Immediate subsequent trigger on same stream at t = 1020ms (within 50ms interval)
	assert_false(bumper2.can_play_audio(1020), "second trigger at 20ms is throttled")
	
	# Subsequent trigger at t = 1060ms (after 50ms interval)
	assert_true(bumper2.can_play_audio(1060), "subsequent trigger at 60ms is allowed")
	
	# Reset allows immediate trigger
	PolyominoMachineryComponentScript.reset_audio_throttle()
	assert_true(bumper2.can_play_audio(1020), "trigger allowed after throttle reset")
	
	bumper1.free()
	bumper2.free()
