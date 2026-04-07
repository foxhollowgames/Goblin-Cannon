extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "PhantomTrail"

func run() -> void:
	test_phantom_has_world_space_trail_particles()
	test_non_phantom_has_no_trail_node()

func _phantom_def() -> BallDefinition:
	var d := BallDefinition.new()
	d.ability_name = "Phantom"
	d.alignment = Constants.ALIGNMENT_MAIN
	d.base_energy = Constants.legacy_display_energy_to_current(20)
	d.tier = 1
	d.rarity = Constants.RARITY_UNCOMMON
	d.city_weights = {}
	d.status_effects = {}
	d.shape_type = BallVisuals.ShapeType.HEXAGON
	return d

func test_phantom_has_world_space_trail_particles() -> void:
	begin("Phantom ball uses CPUParticles2D trail in world space with texture")
	var b: Node = RigidBody2D.new()
	b.set_script(load("res://scenes/balls/ball.gd"))
	b.set_definition(_phantom_def())
	var trail: Node = b.get_node_or_null("PhantomTrailParticles")
	assert_true(trail is CPUParticles2D, "trail node")
	var cpu: CPUParticles2D = trail as CPUParticles2D
	assert_false(cpu.local_coords, "world-space trail (not parent-locked smear)")
	assert_true(cpu.texture != null, "soft particle texture (not default square quad)")
	b.queue_free()

func test_non_phantom_has_no_trail_node() -> void:
	begin("Non-phantom ball does not spawn phantom trail")
	var b: Node = RigidBody2D.new()
	b.set_script(load("res://scenes/balls/ball.gd"))
	var d := BallDefinition.new()
	d.ability_name = "Explosive"
	d.alignment = Constants.ALIGNMENT_MAIN
	d.base_energy = Constants.legacy_display_energy_to_current(20)
	d.tier = 1
	d.rarity = Constants.RARITY_LEGENDARY
	d.city_weights = {}
	d.status_effects = {}
	d.shape_type = BallVisuals.ShapeType.CIRCLE
	b.set_definition(d)
	assert_true(b.get_node_or_null("PhantomTrailParticles") == null, "no phantom trail")
	b.queue_free()
