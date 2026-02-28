extends Control
## Updates city gate fortification (GDD §11), Goblin Cannon health/balls/charge from game state.

var _gate_title_label: Label  ## City/gate name at top of conquest block (e.g. "Halflings").
var _conquest_path: VBoxContainer  ## Conquest path: bubbles and segments.
var _conquest_goal_label: Label  ## Same as _gate_title_label; kept for set_conquest_walls.
var _wall_health_label: Label
var _wall_health_bar: ProgressBar
var _health_label: Label
var _health_progress: ProgressBar
var _balls_label: Label
var _bag_label: Label
var _charge_label: Label
var _charge_progress: ProgressBar
var _charge_bar: Control
var _shield_bar: Control  ## HealthShieldBar container (shield energy gain flies here)
var _sidearm_bar: Control
var _shield_progress: ProgressBar  ## Shield overlay on health bar
var _current_health: int = 0
var _current_health_max: int = 100
var _current_shield: int = 0
var _sidearm_value: Label
var _next_bonus_label: Label
var _energy_flow_vfx_scene: PackedScene
var _energy_gain_label: Label
var _energy_gain_total: int = 0
var _energy_gain_tween: Tween
var _shield_gain_label: Label
var _shield_gain_total: int = 0
var _shield_gain_tween: Tween
var _sidearm_gain_label: Label
var _sidearm_gain_total: int = 0
var _sidearm_gain_tween: Tween
const ENERGY_GAIN_LABEL_FADE_DURATION: float = 1.2
const ENERGY_GAIN_ACCUMULATE_THRESHOLD: float = 0.5
const COLOR_MAIN: Color = Color(0.95, 0.85, 0.4, 1)      # yellow (cannon)
const COLOR_SIDEARM: Color = Color(0.95, 0.35, 0.3, 1)   # red
const COLOR_SHIELD: Color = Color(0.4, 0.75, 1.0, 1)    # blue

## Apply visible background and fill StyleBoxes so the ProgressBar draws correctly (Godot 4 default theme can fail to show fill).
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
	## Health/shield bar is in bottom bar next to cannon (same row as CHARGE/SIDEARM).
	var health_bucket: Control = get_node_or_null("BottomEnergyPools/BucketsPanel/HBox/HealthBucket/BarContainer") as Control
	if health_bucket:
		_shield_bar = health_bucket
		_health_label = health_bucket.get_node_or_null("ValueLabel") as Label
		_health_progress = health_bucket.get_node_or_null("HealthProgress") as ProgressBar
		_shield_progress = health_bucket.get_node_or_null("ShieldOverlay") as ProgressBar
		if _health_progress:
			_apply_progress_bar_theme(_health_progress, Color(0.4, 0.9, 0.5, 1))
		if _shield_progress:
			_apply_progress_bar_theme(_shield_progress, COLOR_SHIELD)
			## Transparent background so green health bar is visible underneath
			var transparent_bg: StyleBoxFlat = StyleBoxFlat.new()
			transparent_bg.bg_color = Color(0, 0, 0, 0)
			transparent_bg.set_corner_radius_all(3)
			_shield_progress.add_theme_stylebox_override("background", transparent_bg)
	## Parent is UILayer (CanvasLayer), not Control — use Node so lookup succeeds.
	## Attributes, abilities, and milestone are on the board (LeftPanel/BoardStatsPanel).
	var ui: Node = get_parent()
	if ui:
		_balls_label = ui.get_node_or_null("LeftPanel/HopperBalls") as Label
		_next_bonus_label = ui.get_node_or_null("LeftPanel/BoardStatsPanel/NextBonus/VBox/Progress") as Label
		var charge_bucket: Control = ui.get_node_or_null("CenterPanel/BottomEnergyPools/BucketsPanel/HBox/ChargeBucket/BarContainer") as Control
		if charge_bucket:
			_charge_bar = charge_bucket
			_charge_label = charge_bucket.get_node_or_null("ValueLabel") as Label
			_charge_progress = charge_bucket.get_node_or_null("Bar") as ProgressBar
			if _charge_progress:
				_apply_progress_bar_theme(_charge_progress, COLOR_MAIN)
		var sidearm_bucket: Control = ui.get_node_or_null("CenterPanel/BottomEnergyPools/BucketsPanel/HBox/SidearmBucket/BarContainer") as Control
		if sidearm_bucket:
			_sidearm_bar = sidearm_bucket
			_sidearm_value = sidearm_bucket.get_node_or_null("ValueLabel") as Label
			var sidearm_bar: ProgressBar = sidearm_bucket.get_node_or_null("Bar") as ProgressBar
			if sidearm_bar:
				_apply_progress_bar_theme(sidearm_bar, COLOR_SIDEARM)
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

## Set gate name from city (e.g. "Village Gate" for Halfling Shire). GDD §11.
func set_gate_name(gate_name: String) -> void:
	if _gate_title_label:
		_gate_title_label.text = gate_name if not gate_name.is_empty() else "Conquered!"

## Conquest path: vertical bubbles (wall sections) connected by segments. current_index is 0-based.
## goal_name: optional label at top (e.g. "Halflings").
func set_conquest_walls(wall_names: Array, current_index: int, goal_name: String = "") -> void:
	if _conquest_goal_label:
		_conquest_goal_label.text = goal_name if not goal_name.is_empty() else "Conquest"
		_conquest_goal_label.visible = true
	if not _conquest_path:
		return
	for child in _conquest_path.get_children():
		child.queue_free()
	var bubble_script: GDScript = load("res://scenes/ui/conquest_bubble.gd") as GDScript
	if not bubble_script:
		return
	const WALL_LABEL_MIN_WIDTH: int = 52
	# Display order: top = last wall, bottom = current (index 0). So iterate from last to 0.
	for idx in range(wall_names.size() - 1, -1, -1):
		# Row: optional "Wall N" label on left, then bubble
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		var is_current: bool = (idx == current_index)
		var wall_label: Label = Label.new()
		wall_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wall_label.custom_minimum_size.x = WALL_LABEL_MIN_WIDTH
		if is_current:
			wall_label.text = "Wall %d" % (idx + 1)
			wall_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			wall_label.add_theme_font_size_override("font_size", 12)
		row.add_child(wall_label)
		var bubble: Control = Control.new()
		bubble.set_script(bubble_script)
		bubble.set("is_current", is_current)
		row.add_child(bubble)
		_conquest_path.add_child(row)

func _update_health_shield_label() -> void:
	if _health_label:
		if _current_shield > 0:
			_health_label.text = "%d/%d (+%d)" % [_current_health, _current_health_max, _current_shield]
		else:
			_health_label.text = "%d/%d" % [_current_health, _current_health_max]

func set_fortification(current: int, maximum: int) -> void:
	var text: String = "%d/%d" % [current, maximum]
	if _wall_health_label:
		_wall_health_label.text = text
	if _wall_health_bar:
		_wall_health_bar.max_value = float(maximum)
		_wall_health_bar.value = float(current)
		_wall_health_bar.queue_redraw()

func set_health(current: int, maximum: int) -> void:
	_current_health = current
	_current_health_max = maximum
	_update_health_shield_label()
	if _health_progress:
		_health_progress.max_value = float(maximum)
		_health_progress.value = float(current)
		_health_progress.queue_redraw()
	if _shield_progress:
		_shield_progress.max_value = float(maximum)
		_shield_progress.queue_redraw()

func set_balls(current: int, maximum: int) -> void:
	if _balls_label:
		_balls_label.text = "BALLS: %d/%d" % [current, maximum]

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

## Shield overlay on health bar (same scale as health). Display units.
func set_shield(display_value: int) -> void:
	_current_shield = display_value
	_update_health_shield_label()
	if _shield_progress:
		_shield_progress.max_value = float(maxi(_current_health_max, 1))
		_shield_progress.value = clampf(float(display_value), 0.0, _shield_progress.max_value)
		_shield_progress.queue_redraw()

## Sidearm pool display (display units). Bar max is 100 for visual fill.
const SIDEARM_BAR_MAX_DISPLAY: int = 100
func set_sidearm(display_value: int) -> void:
	if _sidearm_value:
		_sidearm_value.text = str(display_value)
	var sidearm_bar: ProgressBar = _sidearm_bar.get_node_or_null("Bar") as ProgressBar if _sidearm_bar else null
	if sidearm_bar:
		sidearm_bar.max_value = float(SIDEARM_BAR_MAX_DISPLAY)
		sidearm_bar.value = clampf(float(display_value), 0.0, float(SIDEARM_BAR_MAX_DISPLAY))
		sidearm_bar.queue_redraw()

## GDD §12: Next Bonus shows progress toward next milestone (XP-style, 3 balls + 2 stats). Display units.
func set_next_bonus(current: int, next_threshold: int) -> void:
	if _next_bonus_label:
		_next_bonus_label.text = "%d/%d" % [current, next_threshold]

## Called when a ball reaches the bottom and energy is allocated. Spawns alignment-colored flow VFX and +X on the matching bar.
## alignment: 0 = main (yellow), 1 = sidearm (red), 2 = shield (blue).
func show_energy_gain(main_internal: int, sidearm_internal: int, shield_internal: int, exit_position: Vector2, alignment: int = 0) -> void:
	var end_bar: Control = null
	var amount_display: int = 0
	var particle_color: Color = COLOR_MAIN
	if alignment == 0:
		end_bar = _charge_bar
		amount_display = main_internal / 100
		particle_color = COLOR_MAIN
	elif alignment == 1:
		end_bar = _sidearm_bar
		amount_display = sidearm_internal / 100
		particle_color = COLOR_SIDEARM
	else:
		end_bar = _shield_bar
		amount_display = shield_internal / 100
		particle_color = COLOR_SHIELD
	if not end_bar:
		return
	var end_rect: Rect2 = end_bar.get_global_rect()
	var end_pos: Vector2 = end_rect.get_center()

	if _energy_flow_vfx_scene:
		var vfx: Control = _energy_flow_vfx_scene.instantiate() as Control
		if vfx and vfx.has_method("setup"):
			vfx.setup(exit_position, end_pos, particle_color)
			var ui_layer: Node = get_parent()
			if ui_layer:
				ui_layer.add_child(vfx)

	if alignment == 0:
		_show_gain_on_main_bar(end_pos, amount_display)
	elif alignment == 1:
		_show_gain_on_sidearm_bar(end_pos, amount_display)
	else:
		_show_gain_on_shield_bar(end_pos, amount_display)

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
	_start_energy_gain_fade(0, _energy_gain_label, func(): _on_main_gain_faded())

func _show_gain_on_sidearm_bar(end_pos: Vector2, amount_display: int) -> void:
	var reuse: bool = _sidearm_gain_label != null and is_instance_valid(_sidearm_gain_label) and _sidearm_gain_label.modulate.a > ENERGY_GAIN_ACCUMULATE_THRESHOLD
	if reuse:
		_sidearm_gain_total += amount_display
		_sidearm_gain_label.text = "+%d" % _sidearm_gain_total
		if _sidearm_gain_tween and _sidearm_gain_tween.is_valid():
			_sidearm_gain_tween.kill()
	else:
		_sidearm_gain_total = amount_display
		if _sidearm_gain_label and is_instance_valid(_sidearm_gain_label):
			_sidearm_gain_label.queue_free()
		_sidearm_gain_label = Label.new()
		_sidearm_gain_label.text = "+%d" % _sidearm_gain_total
		_sidearm_gain_label.position = end_pos + Vector2(8, -10)
		_sidearm_gain_label.add_theme_font_size_override("font_size", 18)
		_sidearm_gain_label.add_theme_color_override("font_color", COLOR_SIDEARM)
		_sidearm_gain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_parent().add_child(_sidearm_gain_label)
	_start_energy_gain_fade(1, _sidearm_gain_label, func(): _on_sidearm_gain_faded())

func _show_gain_on_shield_bar(end_pos: Vector2, amount_display: int) -> void:
	var reuse: bool = _shield_gain_label != null and is_instance_valid(_shield_gain_label) and _shield_gain_label.modulate.a > ENERGY_GAIN_ACCUMULATE_THRESHOLD
	if reuse:
		_shield_gain_total += amount_display
		_shield_gain_label.text = "+%d" % _shield_gain_total
		if _shield_gain_tween and _shield_gain_tween.is_valid():
			_shield_gain_tween.kill()
	else:
		_shield_gain_total = amount_display
		if _shield_gain_label and is_instance_valid(_shield_gain_label):
			_shield_gain_label.queue_free()
		_shield_gain_label = Label.new()
		_shield_gain_label.text = "+%d" % _shield_gain_total
		_shield_gain_label.position = end_pos + Vector2(8, -10)
		_shield_gain_label.add_theme_font_size_override("font_size", 18)
		_shield_gain_label.add_theme_color_override("font_color", COLOR_SHIELD)
		_shield_gain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_parent().add_child(_shield_gain_label)
	_start_energy_gain_fade(2, _shield_gain_label, func(): _on_shield_gain_faded())

func _start_energy_gain_fade(bar_type: int, label_ref: Label, on_faded: Callable) -> void:
	if not label_ref or not is_instance_valid(label_ref):
		return
	label_ref.modulate.a = 1.0
	var t: Tween = create_tween()
	t.tween_property(label_ref, "modulate:a", 0.0, ENERGY_GAIN_LABEL_FADE_DURATION).set_delay(0.3).set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(on_faded)
	if bar_type == 0:
		_energy_gain_tween = t
	elif bar_type == 1:
		_sidearm_gain_tween = t
	else:
		_shield_gain_tween = t

func _on_main_gain_faded() -> void:
	if _energy_gain_label and is_instance_valid(_energy_gain_label):
		_energy_gain_label.queue_free()
	_energy_gain_label = null
	_energy_gain_total = 0

func _on_sidearm_gain_faded() -> void:
	if _sidearm_gain_label and is_instance_valid(_sidearm_gain_label):
		_sidearm_gain_label.queue_free()
	_sidearm_gain_label = null
	_sidearm_gain_total = 0

func _on_shield_gain_faded() -> void:
	if _shield_gain_label and is_instance_valid(_shield_gain_label):
		_shield_gain_label.queue_free()
	_shield_gain_label = null
	_shield_gain_total = 0
