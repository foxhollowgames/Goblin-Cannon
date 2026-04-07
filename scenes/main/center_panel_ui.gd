extends Control
## Center panel UI: wall health, cannon charge, timer, conquest path, bag, run gold.

var _gate_title_label: Label
var _conquest_path: VBoxContainer
var _conquest_goal_label: Label
var _wall_health_label: Label
var _wall_health_bar: ProgressBar
var _run_gold_label: Label
var _bag_label: Label
var _charge_label: Label
var _charge_progress: ProgressBar
var _charge_bar: Control
var _timer_label: Label
var _energy_flow_vfx_scene: PackedScene
var _energy_gain_label: Label
var _energy_gain_total: int = 0
var _energy_gain_tween: Tween
var _conquest_animate_next: bool = false
var _wall_cleared_flash_tween: Tween
const ENERGY_GAIN_LABEL_FADE_DURATION: float = 1.2
const ENERGY_GAIN_ACCUMULATE_THRESHOLD: float = 0.5
const COLOR_MAIN: Color = Color(0.95, 0.85, 0.4, 1)
const COLOR_CLEARED: Color = Color(0.3, 0.85, 0.35, 1)

func _apply_progress_bar_theme(bar: ProgressBar, fill_color: Color) -> void:
	if not bar:
		return
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.22, 0.22, 0.25, 1)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

func _ready() -> void:
	_energy_flow_vfx_scene = load("res://scenes/ui/energy_flow_vfx.tscn") as PackedScene
	var wall_under: Control = get_node_or_null("ConquestBar/WallHealthUnder/BarContainer") as Control
	if wall_under:
		_wall_health_label = wall_under.get_node_or_null("ValueLabel") as Label
		_wall_health_bar = wall_under.get_node_or_null("WallHealthBar") as ProgressBar
		if _wall_health_bar:
			_apply_progress_bar_theme(_wall_health_bar, Color(0.95, 0.4, 0.35, 1))
	# Hide the health and sidearm buckets (no longer used)
	var health_bucket: Control = get_node_or_null("BottomEnergyPools/BucketsPanel/HBox/HealthBucket") as Control
	if health_bucket:
		health_bucket.visible = false
	var sidearm_bucket: Control = get_node_or_null("BottomEnergyPools/BucketsPanel/HBox/SidearmBucket") as Control
	if sidearm_bucket:
		sidearm_bucket.visible = false
	var ui: Node = get_parent()
	if ui:
		_run_gold_label = ui.get_node_or_null("LeftPanel/RunGold") as Label
		var charge_bucket: Control = ui.get_node_or_null("CenterPanel/BottomEnergyPools/BucketsPanel/HBox/ChargeBucket/BarContainer") as Control
		if charge_bucket:
			_charge_bar = charge_bucket
			_charge_label = charge_bucket.get_node_or_null("ValueLabel") as Label
			_charge_progress = charge_bucket.get_node_or_null("Bar") as ProgressBar
			if _charge_progress:
				_apply_progress_bar_theme(_charge_progress, COLOR_MAIN)
	var bag_panel: Control = get_node_or_null("BagPanel") as Control
	if bag_panel:
		_bag_label = bag_panel.get_node_or_null("BagLabel") as Label
	var conquest_bar: VBoxContainer = get_node_or_null("ConquestBar") as VBoxContainer
	if conquest_bar:
		var content: Node = conquest_bar.get_node_or_null("ConquestContentCenter/ConquestContent")
		if content:
			_conquest_path = content.get_node_or_null("ConquestPathWrapper/ConquestPath") as VBoxContainer
			_conquest_goal_label = content.get_node_or_null("ConquestGoalLabel") as Label
			_gate_title_label = _conquest_goal_label
	# Create timer label above the conquest bar
	_create_timer_label()

func _create_timer_label() -> void:
	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	_timer_label.text = "3:00"
	_timer_label.add_theme_font_size_override("font_size", 32)
	_timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Insert at the top of the CenterPanel
	var cannon_col: VBoxContainer = get_node_or_null("CannonColumn") as VBoxContainer
	if cannon_col:
		cannon_col.add_child(_timer_label)
		cannon_col.move_child(_timer_label, 0)
	else:
		add_child(_timer_label)
		_timer_label.position = Vector2(0, 4)

func set_gate_name(gate_name: String) -> void:
	if _gate_title_label:
		_gate_title_label.text = gate_name if not gate_name.is_empty() else "Conquered!"

func set_conquest_walls(wall_names: Array, current_index: int, goal_name: String = "") -> void:
	if _conquest_goal_label:
		_conquest_goal_label.text = goal_name if not goal_name.is_empty() else "Conquest"
		_conquest_goal_label.visible = true
	if not _conquest_path:
		return
	var should_animate: bool = _conquest_animate_next
	_conquest_animate_next = false
	for child in _conquest_path.get_children():
		child.queue_free()
	var bubble_script: GDScript = load("res://scenes/ui/conquest_bubble.gd") as GDScript
	if not bubble_script:
		return
	const WALL_LABEL_MIN_WIDTH: int = 52
	for idx in range(wall_names.size() - 1, -1, -1):
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		var is_current: bool = (idx == current_index)
		var is_cleared: bool = (idx < current_index)
		var wall_label: Label = Label.new()
		wall_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wall_label.custom_minimum_size.x = WALL_LABEL_MIN_WIDTH
		if is_current:
			wall_label.text = "Wall %d" % (idx + 1)
			wall_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			wall_label.add_theme_font_size_override("font_size", 12)
		elif is_cleared:
			wall_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 0.6))
			wall_label.add_theme_font_size_override("font_size", 10)
		row.add_child(wall_label)
		var bubble: Control = Control.new()
		bubble.set_script(bubble_script)
		bubble.set("is_current", is_current)
		row.add_child(bubble)
		_conquest_path.add_child(row)
	if should_animate:
		_conquest_path.modulate.a = 0.0
		_conquest_path.position.y = 20.0
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_conquest_path, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(_conquest_path, "position:y", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func animate_wall_cleared() -> void:
	_conquest_animate_next = true
	if _wall_cleared_flash_tween and _wall_cleared_flash_tween.is_valid():
		_wall_cleared_flash_tween.kill()
	if _wall_health_bar:
		_wall_cleared_flash_tween = create_tween()
		var fill_style: StyleBoxFlat = StyleBoxFlat.new()
		fill_style.bg_color = COLOR_CLEARED
		fill_style.set_corner_radius_all(3)
		_wall_health_bar.add_theme_stylebox_override("fill", fill_style)
		_wall_cleared_flash_tween.tween_interval(1.2)
		_wall_cleared_flash_tween.tween_callback(_restore_health_bar_color)
	if _conquest_path:
		for child in _conquest_path.get_children():
			var bubble: Control = null
			for sub in child.get_children():
				if sub.get("is_current") == true:
					bubble = sub
					break
			if bubble:
				var pulse: Tween = create_tween()
				pulse.tween_property(bubble, "modulate", Color(0.3, 1.0, 0.4, 1.0), 0.3).set_ease(Tween.EASE_OUT)
				pulse.tween_property(bubble, "modulate", Color(1, 1, 1, 0.5), 0.8).set_ease(Tween.EASE_IN)
				break

func _restore_health_bar_color() -> void:
	if _wall_health_bar:
		_apply_progress_bar_theme(_wall_health_bar, Color(0.95, 0.4, 0.35, 1))

func set_fortification(current: int, maximum: int) -> void:
	var text: String = "%d/%d" % [current, maximum]
	if _wall_health_label:
		_wall_health_label.text = text
	if _wall_health_bar:
		_wall_health_bar.max_value = float(maximum)
		_wall_health_bar.value = float(current)
		_wall_health_bar.queue_redraw()

func set_run_gold(amount: int) -> void:
	if _run_gold_label:
		_run_gold_label.text = "Gold: %d" % amount

func set_bag(count: int) -> void:
	if _bag_label:
		_bag_label.text = "BAG: %d" % count

func set_charge(current: int, threshold: int) -> void:
	var display_current: int = current / 100
	if _charge_label:
		_charge_label.text = str(display_current)
	if _charge_progress:
		_charge_progress.max_value = float(threshold)
		_charge_progress.value = float(current)
		_charge_progress.queue_redraw()

func set_timer(seconds_remaining: float) -> void:
	if not _timer_label:
		return
	var mins: int = int(seconds_remaining) / 60
	var secs: int = int(seconds_remaining) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]
	# Color shifts to red when under 30 seconds
	if seconds_remaining <= 30.0:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.25, 0.2, 1))
	elif seconds_remaining <= 60.0:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3, 1))
	else:
		_timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

## Energy gain VFX (only main cannon now).
func show_energy_gain(main_internal: int, _sidearm_internal: int, _shield_internal: int, exit_position: Vector2, _alignment: int = 0) -> void:
	var end_bar: Control = _charge_bar
	var amount_display: int = main_internal / 100
	if not end_bar:
		return
	var end_rect: Rect2 = end_bar.get_global_rect()
	var end_pos: Vector2 = end_rect.get_center()

	# One flying VFX per gain burst; rapid sources (e.g. many leech ticks) reuse the label only.
	var reuse_label: bool = _energy_gain_label != null and is_instance_valid(_energy_gain_label) and _energy_gain_label.modulate.a > ENERGY_GAIN_ACCUMULATE_THRESHOLD
	if _energy_flow_vfx_scene and not reuse_label:
		var vfx: Control = _energy_flow_vfx_scene.instantiate() as Control
		if vfx and vfx.has_method("setup"):
			vfx.setup(exit_position, end_pos, COLOR_MAIN)
			var ui_layer: Node = get_parent()
			if ui_layer:
				ui_layer.add_child(vfx)

	_show_gain_on_main_bar(end_pos, amount_display)

func _show_gain_on_main_bar(end_pos: Vector2, amount_display: int) -> void:
	var reuse: bool = _energy_gain_label != null and is_instance_valid(_energy_gain_label) and _energy_gain_label.modulate.a > ENERGY_GAIN_ACCUMULATE_THRESHOLD
	if reuse:
		_energy_gain_total += amount_display
		_energy_gain_label.text = "+%d" % _energy_gain_total
		if _energy_gain_tween and _energy_gain_tween.is_valid():
			_energy_gain_tween.kill()
	else:
		_energy_gain_total = amount_display
		if _energy_gain_label and is_instance_valid(_energy_gain_label):
			_energy_gain_label.queue_free()
		_energy_gain_label = Label.new()
		_energy_gain_label.text = "+%d" % _energy_gain_total
		_energy_gain_label.position = end_pos + Vector2(8, -10)
		_energy_gain_label.add_theme_font_size_override("font_size", 18)
		_energy_gain_label.add_theme_color_override("font_color", COLOR_MAIN)
		_energy_gain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_parent().add_child(_energy_gain_label)
	_start_energy_gain_fade()

func _start_energy_gain_fade() -> void:
	if not _energy_gain_label or not is_instance_valid(_energy_gain_label):
		return
	_energy_gain_label.modulate.a = 1.0
	var t: Tween = create_tween()
	t.tween_property(_energy_gain_label, "modulate:a", 0.0, ENERGY_GAIN_LABEL_FADE_DURATION).set_delay(0.3).set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(_on_main_gain_faded)
	_energy_gain_tween = t

func _on_main_gain_faded() -> void:
	if _energy_gain_label and is_instance_valid(_energy_gain_label):
		_energy_gain_label.queue_free()
	_energy_gain_label = null
	_energy_gain_total = 0
