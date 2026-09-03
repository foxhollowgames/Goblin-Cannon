extends Node2D
class_name PolyominoModuleNode
## Compound multi-cell polyomino module node on the board.
## Scales and spawns internal kinetic machinery components matching module shape and rotation.

signal machinery_triggered(component: PolyominoMachineryComponent, ball: Node, energy_granted: int, impulse: Vector2)
signal goal_completed(module_node: Node, goal_type: int, reward_type: int, triggering_ball: Node, reward_data: Dictionary)
signal bank_completed(bank_id: StringName, reward_type: int, reward_value: int)

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoMachineryComponentScript = preload("res://scenes/board/machinery/polyomino_machinery_component.gd")
const PinballBumperScript = preload("res://scenes/board/machinery/pinball_bumper.gd")
const SpeedBoostWheelScript = preload("res://scenes/board/machinery/speed_boost_wheel.gd")
const ManaSiphonScript = preload("res://scenes/board/machinery/mana_siphon.gd")
const DirectionalDeflectorScript = preload("res://scenes/board/machinery/directional_deflector.gd")
const RolloverSwitchScript = preload("res://scenes/board/machinery/rollover_switch.gd")
const PopBumperScript = preload("res://scenes/board/machinery/pop_bumper.gd")
const DropTargetScript = preload("res://scenes/board/machinery/drop_target.gd")
const WireGateScript = preload("res://scenes/board/machinery/wire_gate.gd")
const SlingshotKickerScript = preload("res://scenes/board/machinery/slingshot_kicker.gd")
const StandupTargetScript = preload("res://scenes/board/machinery/standup_target.gd")
const SpinnerScript = preload("res://scenes/board/machinery/spinner.gd")
const ScoopSinkholeScript = preload("res://scenes/board/machinery/scoop_sinkhole.gd")
const BallLockScript = preload("res://scenes/board/machinery/ball_lock.gd")
const GuideTrackScript = preload("res://scenes/board/machinery/guide_track.gd")
const OrbitLoopScript = preload("res://scenes/board/machinery/orbit_loop.gd")
const CaptiveBallScript = preload("res://scenes/board/machinery/captive_ball.gd")
const MechanicalDiverterScript = preload("res://scenes/board/machinery/mechanical_diverter.gd")
const VerticalUpKickerScript = preload("res://scenes/board/machinery/vertical_up_kicker.gd")
const BashToyScript = preload("res://scenes/board/machinery/bash_toy.gd")
const OutlaneKickbackScript = preload("res://scenes/board/machinery/outlane_kickback.gd")

const GoalArchetype = PolyominoModuleData.GoalArchetype
const RewardType = PolyominoModuleData.RewardType

const CELL_WIDTH: float = 52.0
const CELL_HEIGHT: float = 56.0

var item: Resource = null
var module_data: PolyominoModuleData = null
var grid_position: Vector2i = Vector2i.ZERO
var rotation_step: int = 0

var _components: Array[PolyominoMachineryComponent] = []
var _components_by_cell: Dictionary = {} # Vector2i (anchored local cell) -> PolyominoMachineryComponent
var _anchored_cells: Array[Vector2i] = []
var _accent_color: Color = Color(0.6, 0.6, 0.6)

# Pinball goal runtime tracking state
var _hit_cells: Dictionary = {} # Vector2i -> bool (for Target Bank)
var _sequence_index: int = 0 # for Sequential Route
var _orbit_count: int = 0 # for Orbit Flow
var _jackpot_pool: int = 0 # for Jackpot Accumulator
var _lock_count: int = 0 # for Sinkhole Lock / Multiball
var _hurry_up_active: bool = false
var _hurry_up_timer: float = 0.0
var _goal_flash_timer: float = 0.0
var _floating_banner_text: String = ""
var _floating_banner_timer: float = 0.0

func setup_module(p_item: Resource, p_grid_pos: Vector2i, p_rotation: int = 0) -> void:
	item = p_item
	grid_position = p_grid_pos
	rotation_step = posmod(p_rotation, 4)

	if item and "module_data" in item and item.module_data != null:
		module_data = item.module_data
	else:
		module_data = PolyominoModuleData.new()
		module_data.cells = [Vector2i.ZERO]

	var tier: int = module_data.tier
	_accent_color = Constants.shop_rarity_accent_color(tier)
	reset_goal_state()

	_rebuild_components()
	queue_redraw()

func reset_goal_state() -> void:
	_hit_cells.clear()
	_sequence_index = 0
	_orbit_count = 0
	_jackpot_pool = 0
	_lock_count = 0
	_hurry_up_active = false
	_hurry_up_timer = 0.0
	_goal_flash_timer = 0.0
	_floating_banner_timer = 0.0

func _rebuild_components() -> void:
	for comp in _components:
		if is_instance_valid(comp):
			comp.queue_free()
	_components.clear()
	_components_by_cell.clear()

	_anchored_cells = module_data.get_anchored_rotated_cells(rotation_step)
	var orig_cells: Array[Vector2i] = module_data.cells

	for idx in range(_anchored_cells.size()):
		var local_c: Vector2i = _anchored_cells[idx]
		var orig_c: Vector2i = orig_cells[idx] if idx < orig_cells.size() else local_c

		var c_type: int = module_data.get_cell_type_at(orig_c)
		if c_type == PolyominoModuleData.CellType.EMPTY:
			continue
		var orig_dir: Vector2 = module_data.get_cell_direction_at(orig_c)
		var rot_dir: Vector2 = PolyominoModuleData.get_rotated_direction(orig_dir, rotation_step)
		var energy_val: int = module_data.get_cell_energy_value(orig_c)

		var comp: PolyominoMachineryComponent = _create_component_for_type(c_type)
		if comp == null:
			continue
		comp.local_cell = local_c
		comp.cell_type = c_type
		comp.direction = rot_dir
		if energy_val > 0:
			comp.base_energy = energy_val
		comp.set_accent_color(_accent_color)

		# Position component at cell center
		comp.position = Vector2(float(local_c.x) * CELL_WIDTH, float(local_c.y) * CELL_HEIGHT)
		comp.component_activated.connect(_on_component_activated)

		add_child(comp)
		_components.append(comp)
		_components_by_cell[local_c] = comp

func _create_component_for_type(c_type: int) -> PolyominoMachineryComponent:
	match c_type:
		PolyominoModuleData.CellType.EMPTY:
			return null
		PolyominoModuleData.CellType.BUMPER:
			return PinballBumperScript.new()
		PolyominoModuleData.CellType.ACCELERATOR, PolyominoModuleData.CellType.ROTARY_BOOSTER:
			return SpeedBoostWheelScript.new()
		PolyominoModuleData.CellType.MANA_SIPHON:
			return ManaSiphonScript.new()
		PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR, PolyominoModuleData.CellType.FUNNEL, PolyominoModuleData.CellType.GUIDE_RAIL:
			return DirectionalDeflectorScript.new()
		PolyominoModuleData.CellType.ROLLOVER_SWITCH:
			return RolloverSwitchScript.new()
		PolyominoModuleData.CellType.POP_BUMPER:
			return PopBumperScript.new()
		PolyominoModuleData.CellType.DROP_TARGET:
			return DropTargetScript.new()
		PolyominoModuleData.CellType.WIRE_GATE:
			return WireGateScript.new()
		PolyominoModuleData.CellType.SLINGSHOT:
			return SlingshotKickerScript.new()
		PolyominoModuleData.CellType.STANDUP_TARGET:
			return StandupTargetScript.new()
		PolyominoModuleData.CellType.SPINNER:
			return SpinnerScript.new()
		PolyominoModuleData.CellType.SCOOP_SINKHOLE:
			return ScoopSinkholeScript.new()
		PolyominoModuleData.CellType.BALL_LOCK:
			return BallLockScript.new()
		PolyominoModuleData.CellType.GUIDE_TRACK:
			return GuideTrackScript.new()
		PolyominoModuleData.CellType.ORBIT_LOOP:
			return OrbitLoopScript.new()
		PolyominoModuleData.CellType.CAPTIVE_BALL:
			return CaptiveBallScript.new()
		PolyominoModuleData.CellType.MECHANICAL_DIVERTER:
			return MechanicalDiverterScript.new()
		PolyominoModuleData.CellType.VERTICAL_UP_KICKER:
			return VerticalUpKickerScript.new()
		PolyominoModuleData.CellType.BASH_TOY:
			return BashToyScript.new()
		PolyominoModuleData.CellType.OUTLANE_KICKBACK:
			return OutlaneKickbackScript.new()
		_:
			return PinballBumperScript.new()

func _on_component_activated(comp: PolyominoMachineryComponent, ball: Node, energy: int, impulse: Vector2) -> void:
	machinery_triggered.emit(comp, ball, energy, impulse)
	if comp and comp.cell_type == PolyominoModuleData.CellType.ROLLOVER_SWITCH:
		_check_rollover_bank_completion(comp)
	_evaluate_goal_progress(comp, ball, energy)

func _check_rollover_bank_completion(sw: Node) -> void:
	if sw == null:
		return
	var b_id: StringName = sw.get("bank_id") if "bank_id" in sw else &"bank_1"
	var all_lit: bool = true
	var count: int = 0
	for comp in _components:
		if comp and comp.cell_type == PolyominoModuleData.CellType.ROLLOVER_SWITCH:
			var comp_b_id: StringName = comp.get("bank_id") if "bank_id" in comp else &"bank_1"
			if comp_b_id == b_id:
				count += 1
				var is_sw_lit: bool = comp.get("is_lit") if "is_lit" in comp else false
				if not is_sw_lit:
					all_lit = false
					break
	if count > 0 and all_lit:
		bank_completed.emit(b_id, RewardType.ENERGY_SURGE, 15)


func _evaluate_goal_progress(comp: PolyominoMachineryComponent, ball: Node, energy: int) -> void:
	if module_data == null or is_ghost:
		return
	var g_type: int = module_data.goal_type
	if g_type == GoalArchetype.NONE:
		return

	match g_type:
		GoalArchetype.TARGET_BANK:
			_hit_cells[comp.local_cell] = true
			if _hit_cells.size() >= _components.size():
				_hit_cells.clear()
				_trigger_goal_completion(ball)

		GoalArchetype.SEQUENCE_ROUTE:
			var target_seq: Array[Vector2i] = []
			if not module_data.goal_target_sequence.is_empty():
				target_seq = module_data.goal_target_sequence
			else:
				for c in _components:
					target_seq.append(c.local_cell)
			if not target_seq.is_empty():
				var expected: Vector2i = target_seq[mini(_sequence_index, target_seq.size() - 1)]
				if comp.local_cell == expected:
					_sequence_index += 1
					if _sequence_index >= target_seq.size():
						_sequence_index = 0
						_trigger_goal_completion(ball)
				else:
					_sequence_index = 1 if comp.local_cell == target_seq[0] else 0

		GoalArchetype.ORBIT_FLOW:
			_orbit_count += 1
			var req_orbits: int = maxi(2, module_data.goal_target_count)
			if _orbit_count >= req_orbits:
				_orbit_count = 0
				_trigger_goal_completion(ball)

		GoalArchetype.SINKHOLE_LOCK:
			_lock_count += 1
			var req_locks: int = maxi(1, module_data.goal_target_count)
			if _lock_count >= req_locks:
				_lock_count = 0
				_trigger_goal_completion(ball)

		GoalArchetype.JACKPOT_ACCUMULATOR:
			_jackpot_pool += maxi(5, energy * 2)
			var payout_target: int = maxi(15, module_data.reward_energy)
			if comp.cell_type == PolyominoModuleData.CellType.ROTARY_BOOSTER or comp.cell_type == PolyominoModuleData.CellType.MANA_SIPHON or _components.size() <= 1:
				var final_payout: int = maxi(payout_target, _jackpot_pool)
				_jackpot_pool = 0
				_trigger_goal_completion(ball, final_payout)

		GoalArchetype.HURRY_UP_FRENZY:
			if not _hurry_up_active:
				_hurry_up_active = true
				_hurry_up_timer = module_data.goal_time_limit if module_data.goal_time_limit > 0.0 else 4.0
			else:
				_hurry_up_active = false
				_hurry_up_timer = 0.0
				_trigger_goal_completion(ball)

		GoalArchetype.MULTIBALL_RESERVOIR:
			_lock_count += 1
			var req_mb: int = maxi(2, module_data.goal_target_count)
			if _lock_count >= req_mb:
				_lock_count = 0
				_trigger_goal_completion(ball)

	queue_redraw()

func _trigger_goal_completion(ball: Node, bonus_energy: int = 0) -> void:
	var r_energy: int = bonus_energy if bonus_energy > 0 else module_data.reward_energy
	var reward_data: Dictionary = {
		"energy": r_energy,
		"ball_count": module_data.reward_ball_count,
		"goal_title": module_data.goal_title,
		"goal_type": module_data.goal_type,
		"reward_type": module_data.reward_type,
		"reward_desc": module_data.reward_description,
		"global_position": global_position
	}
	goal_completed.emit(self, module_data.goal_type, module_data.reward_type, ball, reward_data)
	_goal_flash_timer = 0.6
	_floating_banner_text = module_data.goal_title.to_upper() if not module_data.goal_title.is_empty() else "GOAL COMPLETE!"
	_floating_banner_timer = 1.2
	queue_redraw()

var is_ghost: bool = false

func set_ghost_state(p_ghost: bool) -> void:
	is_ghost = p_ghost
	modulate.a = 0.5 if is_ghost else 1.0
	queue_redraw()

func is_ghost_state_active() -> bool:
	return is_ghost

## Checks and triggers interaction if a ball contacts any machinery component in this module.
## Checks and triggers interaction if a ball contacts any machinery component or wall enclosure in this module.
func check_ball_collision(ball: Node, sim_tick: int) -> Dictionary:
	if is_ghost:
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }
	if not is_instance_valid(ball):
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }

	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var ball_radius: float = Constants.BALL_RADIUS

	for comp in _components:
		if not is_instance_valid(comp):
			continue
		var comp_pos: Vector2 = comp.global_position if comp.is_inside_tree() else (position + comp.position)
		var hit_dist: float = comp.component_radius + ball_radius + 4.0
		if ball_pos.distance_squared_to(comp_pos) <= (hit_dist * hit_dist):
			var result: Dictionary = comp.trigger_activation(ball, sim_tick)
			if result.get("activated", false):
				return result

	return _check_wall_segment_collision(ball)

func _check_wall_segment_collision(ball: Node) -> Dictionary:
	if module_data == null:
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }
	var segments: Array[Dictionary] = module_data.get_solid_edge_segments(rotation_step)
	if segments.is_empty():
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }

	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var ball_vel: Vector2 = ball.linear_velocity if "linear_velocity" in ball else Vector2.ZERO
	var ball_radius: float = Constants.BALL_RADIUS
	var module_base_pos: Vector2 = global_position if is_inside_tree() else position

	for seg in segments:
		var p1_local: Vector2 = seg["p1"]
		var p2_local: Vector2 = seg["p2"]
		var w1: Vector2 = module_base_pos + Vector2(p1_local.x * CELL_WIDTH, p1_local.y * CELL_HEIGHT)
		var w2: Vector2 = module_base_pos + Vector2(p2_local.x * CELL_WIDTH, p2_local.y * CELL_HEIGHT)
		var norm: Vector2 = seg["normal"]

		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(ball_pos, w1, w2)
		var dist: float = ball_pos.distance_to(closest)
		if dist <= ball_radius + 2.0:
			var hit_normal: Vector2 = (ball_pos - closest).normalized()
			if hit_normal.length_squared() < 0.01:
				hit_normal = norm
			var eff_vel: Vector2 = ball_vel if ball_vel.length_squared() > 0.01 else -hit_normal * 100.0
			var bounce_dot: float = eff_vel.dot(hit_normal)
			if bounce_dot <= 0.0:
				var reflected: Vector2 = eff_vel.bounce(hit_normal) * 0.85
				if "linear_velocity" in ball:
					ball.linear_velocity = reflected
				return {
					"activated": true,
					"energy_granted": 0,
					"impulse_applied": reflected - eff_vel,
					"wall_hit": true
				}
	return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }

## Returns true if all active balls are completely outside this module's collision footprint.
func is_area_clear_of_balls(active_balls: Array, ball_radius: float = Constants.BALL_RADIUS) -> bool:
	var base_pos: Vector2 = global_position if is_inside_tree() else position
	for c in _anchored_cells:
		var center: Vector2 = base_pos + Vector2(float(c.x) * CELL_WIDTH, float(c.y) * CELL_HEIGHT)
		var cell_rect: Rect2 = Rect2(center.x - CELL_WIDTH * 0.5, center.y - CELL_HEIGHT * 0.5, CELL_WIDTH, CELL_HEIGHT)
		var check_rect: Rect2 = cell_rect.grow(ball_radius + 2.0)
		for ball in active_balls:
			if not is_instance_valid(ball):
				continue
			var b_pos: Vector2 = ball.global_position if (ball.is_inside_tree() and "global_position" in ball) else (ball.position if "position" in ball else Vector2.ZERO)
			if check_rect.has_point(b_pos):
				return false
	return true

func get_all_components() -> Array[PolyominoMachineryComponent]:
	return _components

func get_component_at_local_cell(cell: Vector2i) -> PolyominoMachineryComponent:
	return _components_by_cell.get(cell, null)

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	if _hurry_up_active:
		_hurry_up_timer -= delta
		if _hurry_up_timer <= 0.0:
			_hurry_up_active = false
			_hurry_up_timer = 0.0
		needs_redraw = true
	if _goal_flash_timer > 0.0:
		_goal_flash_timer = maxf(0.0, _goal_flash_timer - delta)
		needs_redraw = true
	if _floating_banner_timer > 0.0:
		_floating_banner_timer = maxf(0.0, _floating_banner_timer - delta)
		needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	if _anchored_cells.is_empty():
		return

	var half_w: float = CELL_WIDTH * 0.5
	var half_h: float = CELL_HEIGHT * 0.5

	# Base background color or flashing goal aura
	var bg_col := Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.15)
	if _goal_flash_timer > 0.0:
		var flash_alpha: float = (_goal_flash_timer / 0.6) * 0.45
		bg_col = Color(1.0, 0.85, 0.2, flash_alpha)
	elif _hurry_up_active:
		var pulse: float = 0.15 + 0.15 * sin(Time.get_ticks_msec() * 0.012)
		bg_col = Color(1.0, 0.3, 0.2, pulse)

	var wall_ink_col := Color(0.08, 0.05, 0.12, 0.95)
	var wall_highlight_col := _accent_color.lightened(0.2)
	if _goal_flash_timer > 0.0:
		wall_highlight_col = Color(1.0, 0.95, 0.5, 1.0)

	# 1. Draw transparent background for all cells
	for c in _anchored_cells:
		var center := Vector2(float(c.x) * CELL_WIDTH, float(c.y) * CELL_HEIGHT)
		var cell_rect := Rect2(center.x - half_w, center.y - half_h, CELL_WIDTH, CELL_HEIGHT)
		draw_rect(cell_rect, bg_col)

	# 2. Draw wall enclosures and internal dividing lines
	if module_data != null:
		var segments: Array[Dictionary] = module_data.get_solid_edge_segments(rotation_step)
		for seg in segments:
			var p1_l: Vector2 = seg["p1"]
			var p2_l: Vector2 = seg["p2"]
			var p1_px := Vector2(p1_l.x * CELL_WIDTH, p1_l.y * CELL_HEIGHT)
			var p2_px := Vector2(p2_l.x * CELL_WIDTH, p2_l.y * CELL_HEIGHT)
			var is_internal: bool = seg.get("is_internal", false)

			if is_internal:
				draw_line(p1_px, p2_px, wall_ink_col, 3.0)
				draw_line(p1_px, p2_px, Color(0.3, 0.8, 1.0, 0.8), 1.5)
			else:
				draw_line(p1_px, p2_px, wall_ink_col, 4.0)
				draw_line(p1_px, p2_px, wall_highlight_col, 2.0)
	else:
		# Fallback outer outline rendering
		for c in _anchored_cells:
			var center := Vector2(float(c.x) * CELL_WIDTH, float(c.y) * CELL_HEIGHT)
			var top_l := Vector2(center.x - half_w, center.y - half_h)
			var top_r := Vector2(center.x + half_w, center.y - half_h)
			var bot_l := Vector2(center.x - half_w, center.y + half_h)
			var bot_r := Vector2(center.x + half_w, center.y + half_h)

			if not _anchored_cells.has(Vector2i(c.x, c.y - 1)):
				draw_line(top_l, top_r, wall_ink_col, 3.5)
				draw_line(top_l, top_r, wall_highlight_col, 1.5)
			if not _anchored_cells.has(Vector2i(c.x, c.y + 1)):
				draw_line(bot_l, bot_r, wall_ink_col, 3.5)
				draw_line(bot_l, bot_r, wall_highlight_col, 1.5)
			if not _anchored_cells.has(Vector2i(c.x - 1, c.y)):
				draw_line(top_l, bot_l, wall_ink_col, 3.5)
				draw_line(top_l, bot_l, wall_highlight_col, 1.5)
			if not _anchored_cells.has(Vector2i(c.x + 1, c.y)):
				draw_line(top_r, bot_r, wall_ink_col, 3.5)
				draw_line(top_r, bot_r, wall_highlight_col, 1.5)

	# 3. Draw goal status markers on components
	if module_data != null and not is_ghost:
		match module_data.goal_type:
			GoalArchetype.TARGET_BANK:
				for c in _components:
					var comp_pos: Vector2 = c.position
					if _hit_cells.has(c.local_cell):
						draw_arc(comp_pos, c.component_radius + 4.0, 0, TAU, 16, Color(1.0, 0.85, 0.2, 0.9), 2.5)
					else:
						draw_circle(comp_pos + Vector2(0, -c.component_radius - 2.0), 2.5, Color(0.4, 0.4, 0.4, 0.6))
			GoalArchetype.SEQUENCE_ROUTE:
				var target_seq: Array[Vector2i] = module_data.goal_target_sequence
				if target_seq.is_empty():
					for comp_item in _components:
						target_seq.append(comp_item.local_cell)
				if not target_seq.is_empty():
					var cur_step: Vector2i = target_seq[mini(_sequence_index, target_seq.size() - 1)]
					var cur_comp: PolyominoMachineryComponent = _components_by_cell.get(cur_step, null)
					if cur_comp != null:
						var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
						draw_arc(cur_comp.position, cur_comp.component_radius + 5.0, 0, TAU, 16, Color(0.2, 0.9, 1.0, pulse), 3.0)

	# 4. Floating comic banner text on goal achievement
	if _floating_banner_timer > 0.0 and not _floating_banner_text.is_empty():
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 14
		var alpha: float = clampf(_floating_banner_timer / 0.4, 0.0, 1.0)
		var text_pos: Vector2 = Vector2(-20, -18.0 - (1.2 - _floating_banner_timer) * 20.0)
		draw_string(font, text_pos + Vector2(1, 1), _floating_banner_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.0, 0.0, 0.0, alpha))
		draw_string(font, text_pos, _floating_banner_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 0.9, 0.2, alpha))
