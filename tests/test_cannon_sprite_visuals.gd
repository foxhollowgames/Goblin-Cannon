extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "CannonSpriteVisuals"

func run() -> void:
	test_cannon_visual_texture_and_firing()
	test_circular_cannon_widget_single_rendering()
	cleanup()

func test_cannon_visual_texture_and_firing() -> void:
	begin("cannon_visual_texture_and_firing")
	var CannonVisualScript = load("res://scenes/combat/cannon_visual.gd")
	assert_not_null_val(CannonVisualScript, "CannonVisual script loads")
	var visual: Node2D = CannonVisualScript.new() as Node2D
	autofree(visual)
	assert_not_null_val(visual, "CannonVisual instance created")
	assert_not_null_val(CannonVisualScript.CANNON_TEXTURE, "Cannon texture loaded")
	assert_not_null_val(CannonVisualScript.FIRE_VFX_TEXTURE, "Cartoon Coffee fire VFX texture loaded")
	
	# Test charge energy overlay
	visual.set_charge(5000, 10000)
	assert_approx(visual.liquid_ratio, 0.5, 0.01, "CannonVisual charge ratio is 0.5")

	# Test triggering firing animation
	visual.trigger_firing_anim()
	assert_lt(visual._recoil_offset_x, 0.0, "Recoil offset x active on fire")
	assert_true(visual._show_muzzle_flash, "Muzzle flash active on fire")

func test_circular_cannon_widget_single_rendering() -> void:
	begin("circular_cannon_widget_single_rendering")
	var WidgetScript = load("res://scenes/ui/circular_cannon_widget.gd")
	assert_not_null_val(WidgetScript, "CircularCannonWidget script loads")
	var widget: Control = WidgetScript.new() as Control
	autofree(widget)
	assert_not_null_val(widget, "CircularCannonWidget instance created")

	# Test energy fill
	widget.set_energy(5000, 10000)
	assert_approx(widget.liquid_ratio, 0.5, 0.01, "Liquid energy ratio is 0.5")
	widget.trigger_firing_anim()
	assert_true(widget._is_firing, "Widget firing state active")

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: value was null" % msg)
