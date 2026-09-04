extends Node2D
## Board (§6.3). Single authority for hit detection and per-ball energy. Flush once per sim tick.

signal ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2, status_effects: Dictionary)
signal ball_ability_on_peg_hit(status_effects: Dictionary)  ## GDD §8: ball ability triggered on peg hit; apply status to minions.
signal ball_exited_board(ball: Node, reason: int)
## When a ball finishes returning to the top play line (goblin grab, fragment echo, …). Hook upgrades here; peg types only drive the motion.
signal ball_reset_to_top(ball: Node, reason: StringName)
signal leech_drain(amount_display: int, alignment: int, peg_id: int)  ## Leech status on peg: periodic energy drain (5/sec for 10 sec).
signal gold_gained(amount: int, origin_position: Vector2)
signal module_placed_on_board(item: Resource, grid_pos: Vector2i, rotation: int)
signal module_unslotted_from_board(item: Resource)
signal module_machinery_activated(component: Node, ball: Node, energy_granted: int, impulse: Vector2)
signal module_solidified(item: Resource)
signal peg_solidified(peg: Node)
signal ghost_state_changed(component: Variant, is_ghost: bool)
signal relic_goal_achieved(module_node: Node, goal_type: int, reward_type: int, triggering_ball: Node, reward_data: Dictionary)
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoGoalRewardHandler = preload("res://scenes/board/machinery/polyomino_goal_reward_handler.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const BOARD_GRID_COLS: int = 15
const BOARD_GRID_ROWS: int = 8
const BOARD_GRID_START_X: float = 116.0
const BOARD_GRID_START_Y: float = 200.0
const BOARD_GRID_COL_SPACING: float = 52.0
const BOARD_GRID_ROW_SPACING: float = 56.0

const BALL_RESET_REASON_GOBLIN_GRAB: StringName = &"goblin_grab"
const BALL_RESET_REASON_FRAGMENT_ECHO: StringName = &"fragment_echo"
const BALL_RESET_REASON_BUFFET_FEAST: StringName = &"buffet_feast"
const BUFFET_EAT_DURATION_SEC: float = 5.0

const REASON_BOTTOM: int = 0
const REASON_STALL: int = 1
const REASON_OFF_SCREEN: int = 2
## Volatile ball broke open (gas released); ball returns to hopper / bag like a normal exit.
const REASON_VOLATILE_BREAK: int = 3
## Elf Palace black hole event consumed the ball; hopper return is delayed (see GameCoordinator).
const REASON_BLACK_HOLE: int = 4

## Bottom 10px of viewport (720 - 10): balls that enter this band turn into energy.
const BOTTOM_ZONE_Y: float = 710.0
const OFF_SCREEN_Y: float = 730.0
## Horizontal bounds: match play area (board 0..960) so balls that bounce out left/right are returned to hopper instead of staying in _active_balls.
const OFF_SCREEN_X_LEFT: float = -20.0
const OFF_SCREEN_X_RIGHT: float = 980.0
## Peg hit energy (display); scaled with main cannon 100-base (legacy was 10 @ 800 charge).
const PEG_DISPLAY_ENERGY_PER_HIT: int = maxi(1, (10 * Constants.MAIN_CANNON_CHARGE_DISPLAY + 399) / 800)
const _GAS_CLOUD_VISUAL_SCRIPT: GDScript = preload("res://scenes/board/gas_cloud_visual.gd")

var _placed_modules: Dictionary = {}  # instance_id (StringName) -> JunkBoxItem
var _occupied_board_cells: Dictionary = {}  # Vector2i -> instance_id (StringName)
var _placed_module_nodes: Dictionary = {}  # instance_id -> Node2D
var _ghost_placed_modules: Dictionary = {}  # instance_id (StringName) -> bool
var _ghost_placed_pegs: Dictionary = {}  # peg_id (int) -> Node
var _suppressed_pegs_by_cell: Dictionary = {}  # Vector2i -> Node
var _suppressed_pegs_by_module: Dictionary = {}  # StringName -> Array[Node]
var _hovered_module_instance_id: StringName = &""
var _modules_container: Node2D = null
var _drag_controller: Node = null

var _active_balls: Array[Node] = []
var _hit_cooldown: HitCooldown
var _spawn_position: Vector2 = Vector2(480, 80)  # At gate height so ball falls naturally from hopper
var _peg_by_id: Dictionary = {}
var _balls_container: Node2D
var _game_coordinator: Node = null
var _peg_scene: PackedScene
var _energy_popup_scene: PackedScene
const ENERGY_POPUP_POOL_PREALLOC: int = 48
const ENERGY_POPUP_POOL_MAX_IDLE: int = 96
## Cap leech popup + pulse visuals per second-tick when many pegs drain (energy + leech_drain still apply for all).
const LEECH_VISUAL_BUDGET_PER_TICK: int = 64
var _energy_popup_pool_idle: Array[Node2D] = []
var _hit_effect_scene: PackedScene
var _treasure_chest_break_scene: PackedScene
var _chain_lightning_arc_scene: PackedScene
var _ball_scene: PackedScene
var _next_split_ball_id: int = 100000
## Leech status: each entry { peg_id, alignment, drains_remaining }; drain 5 energy/sec for 10 sec per peg hit.
var _leeched_pegs: Array = []
## Hard caps (GDD): 1 explosion per peg per sim tick; 1 supernova per peg per sim tick; conduction once per chain event.
var _explosion_triggered_pegs_this_tick: Dictionary = {}  # peg_id -> true
var _supernova_triggered_pegs_this_tick: Dictionary = {}
var _chain_conduction_done_this_event: bool = false
## Empty checkerboard positions for wall-break extra pegs; count already spawned so we can add more mid-run.
var _layout_empty_slots: Array = []
var _extra_pegs_spawned_count: int = 0
## Per-ball hit counts for cross-link upgrades (ricochet_blast, static_bounce, overdrive).
var _ball_hit_count_this_visit: Dictionary = {}
## Per-ball splitter trigger flag (each ball can only be split once per visit by a Splitter peg).
var _splitter_triggered_this_visit: Dictionary = {}
## Goblin grab effect scene (loaded once).
var _goblin_grab_scene: GDScript = null
## Prevents duplicate grab tweens / hand nodes if the same ball is processed twice in one tick.
var _goblin_grab_in_progress: Dictionary = {}  # ball_id -> true
## After a grab finishes, skip goblin_reset hits until this sim_tick (ball_id -> first tick where hits apply again).
var _goblin_reset_grace_until_tick: Dictionary = {}
## Halfling buffet table: balls that hit stick together for 5s (rumble), then return to hopper.
var _buffet_sequence_active: bool = false
var _buffet_peg_id: int = -1
var _buffet_affected_balls: Array = []
var _buffet_rumble_tween: Tween = null
var _buffet_break_script: GDScript = null
## Human Kingdom: sticky slime coats normal pegs; balls stick until others free the peg.
var _sticky_slime_stuck_balls: Dictionary = {}  # peg_id -> Array[Node]
var _ball_stuck_on_sticky_peg: Dictionary = {}  # ball_id -> peg_id
var _hopper: Node = null
## Last sim_tick passed to run_ball_steps / flush_tick (for tween callbacks that need a reference tick).
var _board_sim_tick: int = 0
## Phantom peg-pass counts for phase_detonation.
var _phantom_pegs_visited: Dictionary = {}
## Phantom trail positions for spectral_conduit: Array of { position: Vector2, tick: int }.
var _phantom_trail: Array = []
## Ghost Trail (wall break): peg_id -> expiry sim_tick. Pegs in trail grant +1 energy on hit.
var _ghost_trail_pegs: Dictionary = {}
## Recently chain-hit peg ticks for phantom_resonance: peg_id -> sim_tick.
var _chain_hit_peg_ticks: Dictionary = {}
## Overdrive Cascade boss: all balls gain +1 energy per hit until this tick.
var _overdrive_cascade_end_tick: int = 0
## Storm Feedback: temporary energy boost when chain lightning arcs between energized pegs.
var _storm_feedback_end_tick: int = 0
## Mass Cascade: temporary energy bonus while two split fragments are near each other.
var _mass_cascade_end_tick: int = 0
## Storm of Fragments (boss): per-fragment count of energized pegs hit. ball_id -> count.
var _ball_energized_pegs_hit: Dictionary = {}
## Dynamic pegs (e.g. milestone board event) use ids >= this after layout spawn.
var _next_dynamic_peg_id: int = 500000
## Volatile reagent gas: { "id", "center": Vector2, "radius", "end_tick", "is_damage" } in global space.
var _gas_clouds: Array = []
var _next_gas_cloud_id: int = 1
## Elf Palace: BlackHoleController — pull + consume while active.
var _black_hole_active: bool = false
var _black_hole_center_global: Vector2 = Vector2.ZERO
var _black_hole_deadline_ms: int = 0
var _black_hole_visual: Node2D = null
## Binary: unordered ball pair (min_id, max_id) -> last sim_tick when ball–ball split fired
var _binary_ball_pair_last_split_tick: Dictionary = {}
## Constellation laser line hits: "minId|maxId|pegId" -> last sim_tick
var _constellation_laser_peg_last_tick: Dictionary = {}
## When true, next frame must redraw to erase beams after the last pair of Constellation balls is gone.
var _had_constellation_laser_visual: bool = false

func _ready() -> void:
	_hit_cooldown = HitCooldown.new()
	var main: Node = get_parent()
	if main:
		_game_coordinator = main.get_node_or_null("GameCoordinator")
		_hopper = main.get_node_or_null("Hopper")
		_balls_container = main.get_node_or_null("BallsContainer") as Node2D
	if not _balls_container:
		_balls_container = self
	_peg_scene = load("res://scenes/board/peg.tscn") as PackedScene
	_energy_popup_scene = load("res://scenes/board/energy_popup.tscn") as PackedScene
	_hit_effect_scene = load("res://scenes/board/ball_hit_effect.tscn") as PackedScene
	_treasure_chest_break_scene = load("res://scenes/board/treasure_chest_break_effect.tscn") as PackedScene
	_chain_lightning_arc_scene = load("res://scenes/board/chain_lightning_arc_effect.tscn") as PackedScene
	_ball_scene = load("res://scenes/balls/ball.tscn") as PackedScene
	_goblin_grab_scene = load("res://scenes/board/goblin_grab_effect.gd") as GDScript
	_buffet_break_script = load("res://scenes/board/buffet_table_break_effect.gd") as GDScript
	_warm_energy_popup_pool()
	_spawn_peg_layout()
	_modules_container = Node2D.new()
	_modules_container.name = "PlacedModules"
	_modules_container.z_index = 2
	add_child(_modules_container)
	set_process(true)

func _process(_delta: float) -> void:
	var main: Node = get_parent()
	if not main:
		return
	var hopper: Node2D = main.get_node_or_null("Hopper") as Node2D
	if hopper:
		_spawn_position.x = hopper.global_position.x
	_process_ghost_states(_board_sim_tick)

func get_active_ball_count() -> int:
	return _active_balls.size()

## Destroy one ball on the board for which predicate returns true (e.g. almanac remove).
func remove_and_destroy_one_ball_if(predicate: Callable) -> bool:
	if not _balls_container:
		return false
	for ball in _balls_container.get_children():
		if not is_instance_valid(ball):
			continue
		if ball.has_method("is_split_twin") and ball.is_split_twin():
			continue
		if predicate.call(ball):
			_active_balls.erase(ball)
			ball.queue_free()
			return true
	return false

func spawn_ball_at_start(ball: Node) -> void:
	if not ball:
		return
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	_ball_hit_count_this_visit[bid] = 0
	_phantom_pegs_visited[bid] = 0
	_splitter_triggered_this_visit[bid] = false
	if ball.get_parent() == _balls_container:
		if ball.has_method("reset_split_for_new_visit"):
			ball.reset_split_for_new_visit()
		if ball.has_method("reset_gas_buff_state_for_board_visit"):
			ball.reset_gas_buff_state_for_board_visit()
		_active_balls.append(ball)
		return
	if "freeze" in ball:
		ball.freeze = false
	if ball.has_method("reset_split_for_new_visit"):
		ball.reset_split_for_new_visit()
	if ball.has_method("reset_gas_buff_state_for_board_visit"):
		ball.reset_gas_buff_state_for_board_visit()
	ball.global_position = _spawn_position
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	_balls_container.add_child(ball)
	_active_balls.append(ball)

## Fragment Echo (wall break): ghost-float fragment back to top, then release. Do not reset split state.
func respawn_fragment_at_top(ball: Node) -> void:
	if not ball:
		return
	if ball.get_parent() != _balls_container:
		return
	var exit_x: float = clampf(ball.global_position.x, 40.0, 920.0)
	var target_pos: Vector2 = Vector2(exit_x, _spawn_position.y)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "angular_velocity" in ball:
		ball.angular_velocity = 0.0
	if "freeze_mode" in ball:
		ball.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	if "freeze" in ball:
		ball.freeze = true
	if ball.has_method("start_echo_float"):
		ball.start_echo_float()
	ball.set_meta("echo_target", target_pos)
	var tween: Tween = create_tween()
	tween.tween_property(ball, "global_position", target_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finish_fragment_echo.bind(ball))

func _finish_fragment_echo(ball: Node) -> void:
	if not is_instance_valid(ball):
		return
	var target_pos: Vector2 = ball.get_meta("echo_target", _spawn_position)
	if ball.has_method("end_echo_float"):
		ball.end_echo_float()
	if "freeze" in ball:
		ball.freeze = false
	ball.global_position = target_pos
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "angular_velocity" in ball:
		ball.angular_velocity = 0.0
	if "lock_rotation" in ball:
		ball.lock_rotation = true
	_active_balls.append(ball)
	ball.remove_meta("echo_target")
	_emit_ball_reset_to_top(ball, BALL_RESET_REASON_FRAGMENT_ECHO)

func get_peg_by_id(id: int) -> Node:
	return _peg_by_id.get(id)

## Board-local position for milestone peg: never overlaps a peg center (same radius as normal pegs).
func resolve_milestone_event_position(preferred: Vector2, x_min: float, x_max: float) -> Vector2:
	var preferred_cell := world_to_board_cell(preferred)
	var preferred_world := board_cell_to_world(preferred_cell)
	if is_cell_empty(preferred_cell) and preferred_world.x >= x_min and preferred_world.x <= x_max:
		return preferred_world

	var best_pos: Vector2 = preferred_world
	var best_dist: float = INF
	var empty_cells := get_empty_grid_cells()
	for cell in empty_cells:
		var pos: Vector2 = board_cell_to_world(cell)
		if pos.x < x_min or pos.x > x_max:
			continue
		var d: float = pos.distance_to(preferred)
		if d < best_dist:
			best_dist = d
			best_pos = pos

	if best_dist < INF:
		return best_pos

	for cell in empty_cells:
		var pos: Vector2 = board_cell_to_world(cell)
		var d2: float = pos.distance_to(preferred)
		if d2 < best_dist:
			best_dist = d2
			best_pos = pos

	if best_dist < INF:
		return best_pos

	var clamped_col: int = clampi(preferred_cell.x, 0, BOARD_GRID_COLS - 1)
	var clamped_row: int = clampi(preferred_cell.y, 0, BOARD_GRID_ROWS - 1)
	return board_cell_to_world(Vector2i(clamped_col, clamped_row))

func _is_clear_for_milestone_peg(local_pos: Vector2) -> bool:
	var cell: Vector2i = world_to_board_cell(local_pos)
	return is_cell_empty(cell)

## Spawn a milestone board-event peg at board-local position (caller: BoardEventController).
func spawn_milestone_event_peg_at(local_pos: Vector2, x_min: float = 100.0, x_max: float = 860.0) -> int:
	if not _peg_scene:
		return -1
	var pos: Vector2 = resolve_milestone_event_position(local_pos, x_min, x_max)
	var p: Node = _peg_scene.instantiate()
	p.position = pos
	p.peg_id = _next_dynamic_peg_id
	p.peg_extra_kind = "milestone_event"
	_peg_by_id[_next_dynamic_peg_id] = p
	_next_dynamic_peg_id += 1
	add_child(p)
	return p.peg_id

## Timeout or cleanup: remove milestone event peg without granting reward.
func remove_milestone_event_peg(peg_id: int) -> void:
	if not _peg_by_id.has(peg_id):
		return
	var peg: Node = _peg_by_id[peg_id]
	if str(peg.get("peg_extra_kind")) != "milestone_event":
		return
	_peg_by_id.erase(peg_id)
	if peg and is_instance_valid(peg):
		peg.queue_free()

func _process_milestone_event_pegs(_sim_tick: int) -> void:
	for pid in _peg_by_id.duplicate():
		var peg: Node = _peg_by_id[pid]
		if str(peg.get("peg_extra_kind")) != "milestone_event":
			continue
		if not peg.has_method("was_just_destroyed") or not peg.was_just_destroyed():
			continue
		_complete_milestone_event_peg(int(pid), true)

func _complete_milestone_event_peg(peg_id: int, grant_reward: bool) -> void:
	if not _peg_by_id.has(peg_id):
		return
	var peg: Node = _peg_by_id[peg_id]
	if str(peg.get("peg_extra_kind")) != "milestone_event":
		return
	_peg_by_id.erase(peg_id)
	if peg and is_instance_valid(peg):
		peg.queue_free()
	if grant_reward and _game_coordinator and _game_coordinator.has_method("notify_milestone_reward_from_board"):
		_game_coordinator.notify_milestone_reward_from_board()
	var bec: Node = get_node_or_null("BoardEventController")
	if bec and bec.has_method("on_milestone_event_ended"):
		bec.on_milestone_event_ended(grant_reward)

## Treasure chest: durable peg; breaking grants onboard passive upgrade draft.
func spawn_treasure_chest_peg_at(local_pos: Vector2, x_min: float = 100.0, x_max: float = 860.0) -> int:
	if not _peg_scene:
		return -1
	var pos: Vector2 = resolve_milestone_event_position(local_pos, x_min, x_max)
	var p: Node = _peg_scene.instantiate()
	p.position = pos
	p.peg_id = _next_dynamic_peg_id
	p.peg_extra_kind = "treasure_chest"
	_peg_by_id[_next_dynamic_peg_id] = p
	_next_dynamic_peg_id += 1
	add_child(p)
	return p.peg_id

func remove_treasure_chest_peg(peg_id: int) -> void:
	if not _peg_by_id.has(peg_id):
		return
	var peg: Node = _peg_by_id[peg_id]
	if str(peg.get("peg_extra_kind")) != "treasure_chest":
		return
	_peg_by_id.erase(peg_id)
	if peg and is_instance_valid(peg):
		peg.queue_free()

func _process_treasure_chest_pegs(_sim_tick: int) -> void:
	for pid in _peg_by_id.duplicate():
		var peg: Node = _peg_by_id[pid]
		if str(peg.get("peg_extra_kind")) != "treasure_chest":
			continue
		if not peg.has_method("was_just_destroyed") or not peg.was_just_destroyed():
			continue
		_complete_treasure_chest_peg(int(pid), true)

func _complete_treasure_chest_peg(peg_id: int, grant_reward: bool) -> void:
	if not _peg_by_id.has(peg_id):
		return
	var peg: Node = _peg_by_id[peg_id]
	if str(peg.get("peg_extra_kind")) != "treasure_chest":
		return
	var break_pos: Vector2 = peg.global_position if peg and peg.get("global_position") else global_position
	_peg_by_id.erase(peg_id)
	if grant_reward:
		_spawn_treasure_chest_break_effect(break_pos)
	if peg and is_instance_valid(peg):
		peg.queue_free()
	if grant_reward and _game_coordinator and _game_coordinator.has_method("notify_onboard_effect_from_board"):
		_game_coordinator.notify_onboard_effect_from_board()
	var tcc: Node = get_node_or_null("TreasureChestController")
	if tcc and tcc.has_method("on_treasure_event_ended"):
		tcc.on_treasure_event_ended(grant_reward)

## Halfling Shire: buffet table peg — first hit starts feast sequence on Board (not durability-based).
func spawn_buffet_table_peg_at(local_pos: Vector2, x_min: float = 100.0, x_max: float = 860.0) -> int:
	if not _peg_scene:
		return -1
	var pos: Vector2 = resolve_milestone_event_position(local_pos, x_min, x_max)
	var p: Node = _peg_scene.instantiate()
	p.position = pos
	p.peg_id = _next_dynamic_peg_id
	p.peg_extra_kind = "buffet_table"
	_peg_by_id[_next_dynamic_peg_id] = p
	_next_dynamic_peg_id += 1
	add_child(p)
	return p.peg_id

func remove_buffet_table_peg(peg_id: int) -> void:
	if not _peg_by_id.has(peg_id):
		return
	var peg: Node = _peg_by_id[peg_id]
	if str(peg.get("peg_extra_kind")) != "buffet_table":
		return
	_peg_by_id.erase(peg_id)
	if peg and is_instance_valid(peg):
		peg.queue_free()

## Human Kingdom event: pick distinct normal pegs for slime coating.
func pick_random_normal_peg_ids_for_sticky_event(count: int) -> Array[int]:
	var out: Array[int] = []
	var candidates: Array[int] = []
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if p and is_instance_valid(p) and str(p.peg_extra_kind) == "":
			candidates.append(int(pid))
	if candidates.is_empty():
		return out
	candidates.shuffle()
	var n: int = mini(count, candidates.size())
	for i in range(n):
		out.append(candidates[i])
	return out

func set_sticky_slime_preview_highlights(peg_ids: Array, enabled: bool) -> void:
	for entry in peg_ids:
		var pid: int = int(entry)
		var p: Node = _peg_by_id.get(pid)
		if p and p.has_method("set_hover_highlight"):
			p.set_hover_highlight(enabled, "sticky_preview")

## Convert normal pegs to sticky slime (event active phase).
func apply_sticky_slime_to_peg_ids(peg_ids: Array[int]) -> void:
	for pid in peg_ids:
		var peg: Node = _peg_by_id.get(int(pid))
		if not peg or not is_instance_valid(peg):
			continue
		if str(peg.peg_extra_kind) != "":
			continue
		var saved: String = ""
		if peg.has_method("configure_sticky_slime_overlay"):
			peg.configure_sticky_slime_overlay(saved)

func restore_peg_physics_after_sticky_slime(peg: Node, saved_kind: String) -> void:
	if not peg:
		return
	if saved_kind.is_empty():
		_reset_peg_to_plain_physics(peg)
	else:
		convert_specific_peg(peg.peg_id, saved_kind)

func _reset_peg_to_plain_physics(peg: Node) -> void:
	if peg.has_method("reset_collision_shape_to_default_circle"):
		peg.reset_collision_shape_to_default_circle()
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	peg.physics_material_override = mat

func _sticky_slime_ball_offset(stack_index: int) -> Vector2:
	var i: int = maxi(0, stack_index)
	var ring: float = Constants.PEG_RADIUS + Constants.BALL_RADIUS + 3.0
	var ang: float = TAU * 0.25 + float(i) * 0.73
	return Vector2(cos(ang), sin(ang)) * ring

func _pin_ball_to_sticky_slime(ball: Node, peg: Node, stack_index: int) -> void:
	if not is_instance_valid(ball) or not is_instance_valid(peg):
		return
	if "freeze_mode" in ball:
		ball.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	if "freeze" in ball:
		ball.freeze = true
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "angular_velocity" in ball:
		ball.angular_velocity = 0.0
	ball.global_position = peg.global_position + _sticky_slime_ball_offset(stack_index)

func _process_sticky_slime_peg_hit(ball: Node, pid: int, peg: Node, _sim_tick: int) -> void:
	if not peg:
		return
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	if not _sticky_slime_stuck_balls.has(pid):
		_sticky_slime_stuck_balls[pid] = []
	var arr: Array = _sticky_slime_stuck_balls[pid]
	if arr.find(ball) < 0:
		arr.append(ball)
	_ball_stuck_on_sticky_peg[bid] = pid
	_pin_ball_to_sticky_slime(ball, peg, arr.size() - 1)
	var energy_this_hit: int = PEG_DISPLAY_ENERGY_PER_HIT
	if ball.has_method("add_peg_energy"):
		ball.add_peg_energy(energy_this_hit)
	_spawn_energy_popup(peg, energy_this_hit)
	if peg.has_method("consume_sticky_slime_ball_hit") and peg.consume_sticky_slime_ball_hit():
		_break_sticky_slime_peg(pid)

func _release_sticky_slime_balls_from_peg(pid: int) -> void:
	var balls: Array = _sticky_slime_stuck_balls.get(pid, [])
	_sticky_slime_stuck_balls.erase(pid)
	for ball in balls:
		if not is_instance_valid(ball):
			continue
		var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
		_ball_stuck_on_sticky_peg.erase(bid)
		if "freeze" in ball:
			ball.freeze = false
		if "linear_velocity" in ball:
			ball.linear_velocity = Vector2(randf_range(-50.0, 50.0), randf_range(40.0, 110.0))

func _break_sticky_slime_peg(pid: int) -> void:
	var peg: Node = _peg_by_id.get(pid)
	_release_sticky_slime_balls_from_peg(pid)
	if not peg or not is_instance_valid(peg):
		return
	if str(peg.peg_extra_kind) != "sticky_slime":
		return
	var saved: String = str(peg.sticky_slime_saved_kind) if peg.get("sticky_slime_saved_kind") != null else ""
	if peg.has_method("end_sticky_slime_overlay"):
		peg.end_sticky_slime_overlay(saved)
	restore_peg_physics_after_sticky_slime(peg, saved)
	if peg.has_method("enter_break_recovery_after_sticky_slime"):
		peg.enter_break_recovery_after_sticky_slime()
	var ssc: Node = get_node_or_null("StickySlimeController")
	if ssc and ssc.has_method("on_sticky_slime_peg_broken"):
		ssc.on_sticky_slime_peg_broken(pid)

func revert_sticky_slime_peg_after_event_timeout(peg_id: int) -> void:
	var peg: Node = _peg_by_id.get(peg_id)
	if not peg or not is_instance_valid(peg):
		return
	if str(peg.peg_extra_kind) != "sticky_slime":
		return
	var saved: String = str(peg.sticky_slime_saved_kind) if peg.get("sticky_slime_saved_kind") != null else ""
	_release_sticky_slime_balls_from_peg(peg_id)
	if peg.has_method("end_sticky_slime_overlay"):
		peg.end_sticky_slime_overlay(saved)
	restore_peg_physics_after_sticky_slime(peg, saved)

func is_buffet_sequence_active() -> bool:
	return _buffet_sequence_active

func _spawn_buffet_table_break_effect(world_pos: Vector2) -> void:
	if not _buffet_break_script:
		return
	var fx: Node2D = Node2D.new()
	fx.set_script(_buffet_break_script)
	fx.global_position = world_pos
	fx.z_index = 106
	var parent_n: Node = get_parent()
	if parent_n:
		parent_n.add_child(fx)

func _buffet_stuck_offset_for_index(i: int) -> Vector2:
	var spread: float = float(i) * 0.9
	return Vector2(
		sin(spread * 2.1) * (8.0 + float(i) * 1.5),
		-10.0 + cos(spread * 1.7) * 5.5 - float(i) * 2.8
	)

## Keeps all stuck balls clustered on the peg with a shared rumble offset (so nothing drifts away).
func _buffet_rumble_phase_tick(peg_id: int, phase: float) -> void:
	var peg: Node = _peg_by_id.get(peg_id)
	if peg == null or not is_instance_valid(peg):
		return
	var jitter: Vector2 = Vector2(sin(phase * 40.0) * 3.8, cos(phase * 33.0) * 2.6)
	for i in range(_buffet_affected_balls.size()):
		var ball: Node = _buffet_affected_balls[i]
		if not is_instance_valid(ball):
			continue
		ball.global_position = peg.global_position + _buffet_stuck_offset_for_index(i) + jitter

func _capture_ball_for_buffet(ball: Node, peg_id: int) -> void:
	if not is_instance_valid(ball):
		return
	if ball in _buffet_affected_balls:
		return
	var peg: Node = _peg_by_id.get(peg_id)
	if peg == null or not is_instance_valid(peg):
		return
	_active_balls.erase(ball)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "angular_velocity" in ball:
		ball.angular_velocity = 0.0
	if "freeze" in ball:
		ball.freeze = true
	var idx: int = _buffet_affected_balls.size()
	_buffet_affected_balls.append(ball)
	ball.global_position = peg.global_position + _buffet_stuck_offset_for_index(idx)

func _add_ball_to_buffet_feast(ball: Node, peg_id: int) -> void:
	if not _buffet_sequence_active or int(peg_id) != _buffet_peg_id:
		return
	_capture_ball_for_buffet(ball, peg_id)

func _begin_buffet_table_sequence(trigger: Node, peg_id: int) -> void:
	if _buffet_sequence_active:
		return
	var peg: Node = _peg_by_id.get(peg_id)
	if peg == null or not is_instance_valid(peg) or trigger == null or not is_instance_valid(trigger):
		return
	_buffet_sequence_active = true
	_buffet_peg_id = peg_id
	_capture_ball_for_buffet(trigger, peg_id)
	if _buffet_rumble_tween and _buffet_rumble_tween.is_valid():
		_buffet_rumble_tween.kill()
	_buffet_rumble_tween = create_tween()
	_buffet_rumble_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_buffet_rumble_tween.tween_method(_buffet_rumble_phase_tick.bind(peg_id), 0.0, 1.0, BUFFET_EAT_DURATION_SEC).set_trans(Tween.TRANS_LINEAR)
	_buffet_rumble_tween.tween_callback(_finish_buffet_table_sequence.bind(peg_id))

func _finish_buffet_table_sequence(peg_id: int) -> void:
	if _buffet_rumble_tween and _buffet_rumble_tween.is_valid():
		_buffet_rumble_tween.kill()
	_buffet_rumble_tween = null
	var peg: Node = _peg_by_id.get(peg_id) if _peg_by_id.has(peg_id) else null
	var break_pos: Vector2 = peg.global_position if peg and is_instance_valid(peg) and peg.get("global_position") != null else global_position
	_spawn_buffet_table_break_effect(break_pos)
	if peg_id >= 0:
		remove_buffet_table_peg(peg_id)
	var btc: Node = get_node_or_null("BuffetTableController")
	if btc and btc.has_method("on_buffet_event_ended"):
		btc.on_buffet_event_ended(true)
	var hopper: Node = _hopper
	if hopper == null:
		var main: Node = get_parent()
		hopper = main.get_node_or_null("Hopper") if main else null
	for ball in _buffet_affected_balls:
		if not is_instance_valid(ball):
			continue
		if ball.has_method("is_bloom_spawn") and ball.is_bloom_spawn():
			ball.queue_free()
			continue
		if ball.has_method("is_split_twin") and ball.is_split_twin():
			ball.queue_free()
			continue
		if hopper and hopper.has_method("return_ball"):
			hopper.return_ball(ball)
			_emit_ball_reset_to_top(ball, BALL_RESET_REASON_BUFFET_FEAST)
	_buffet_affected_balls.clear()
	_buffet_sequence_active = false
	_buffet_peg_id = -1

## Tag a peg as an explosion source (e.g. bomb peg) so explosion upgrades (Cluster Grenade, radius, etc.) apply.
func _tag_peg_as_explosion_source(peg: Node) -> void:
	if peg and not peg.is_in_group("explosion_source"):
		peg.add_to_group("explosion_source")

func _spawn_gas_cloud(world_pos: Vector2, sim_tick: int) -> void:
	var is_damage: bool = (randi() % 2) == 0
	var cid: int = _next_gas_cloud_id
	_next_gas_cloud_id += 1
	var vis: Node2D = _GAS_CLOUD_VISUAL_SCRIPT.new() as Node2D
	vis.call("setup", to_local(world_pos), Constants.GAS_CLOUD_RADIUS_PX, cid)
	add_child(vis)
	var cloud: Dictionary = {
		"id": cid,
		"center": world_pos,
		"radius": Constants.GAS_CLOUD_RADIUS_PX,
		"end_tick": sim_tick + Constants.GAS_CLOUD_DURATION_TICKS,
		"is_damage": is_damage,
		"visual": vis
	}
	_gas_clouds.append(cloud)

func _prune_expired_gas_clouds(sim_tick: int) -> void:
	var kept: Array = []
	var changed: bool = false
	for c in _gas_clouds:
		var et: int = int(c.get("end_tick", -1))
		if et > sim_tick:
			kept.append(c)
		else:
			changed = true
			var vis: Node = c.get("visual", null) as Node
			if vis != null and is_instance_valid(vis):
				vis.queue_free()
	if changed:
		_gas_clouds = kept

func _apply_gas_cloud_overlap(sim_tick: int) -> void:
	for b in _active_balls:
		if not is_instance_valid(b):
			continue
		if not b.has_method("try_claim_gas_cloud"):
			continue
		var pos: Vector2 = b.get_global_sim_position() if b.has_method("get_global_sim_position") else b.global_position
		for c in _gas_clouds:
			if sim_tick > int(c.get("end_tick", -1)):
				continue
			var center: Vector2 = c.get("center", Vector2.ZERO)
			var rad: float = float(c.get("radius", Constants.GAS_CLOUD_RADIUS_PX))
			if pos.distance_to(center) > rad:
				continue
			var cid: int = int(c.get("id", 0))
			var is_damage: bool = bool(c.get("is_damage", true))
			b.try_claim_gas_cloud(cid, is_damage)

func _release_volatile_ball(ball: Node, world_pos: Vector2, sim_tick: int) -> void:
	_spawn_gas_cloud(world_pos, sim_tick)
	_spawn_hit_effect(world_pos, {}, "Volatile", false)
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	_active_balls.erase(ball)
	_ball_hit_count_this_visit.erase(bid)
	_phantom_pegs_visited.erase(bid)
	_ball_energized_pegs_hit.erase(bid)
	_splitter_triggered_this_visit.erase(bid)
	if is_instance_valid(ball):
		ball_exited_board.emit(ball, REASON_VOLATILE_BREAK)

## Child nodes' sim_tick may queue_free balls still listed in _active_balls; drop those refs before ball logic runs.
func _remove_freed_active_balls() -> void:
	var i: int = _active_balls.size()
	while i > 0:
		i -= 1
		if not is_instance_valid(_active_balls[i]):
			_active_balls.remove_at(i)

func run_ball_steps(sim_tick: int) -> void:
	_board_sim_tick = sim_tick
	_prune_expired_gas_clouds(sim_tick)
	_apply_gas_cloud_overlap(sim_tick)
	_explosion_triggered_pegs_this_tick.clear()
	_supernova_triggered_pegs_this_tick.clear()
	for p in get_children():
		if p.has_method("sim_tick"):
			p.sim_tick(sim_tick)
	_remove_freed_active_balls()
	_apply_magnet_and_gravity_well_forces()
	_tick_black_hole_event(sim_tick)
	for b in _active_balls.duplicate():
		if not is_instance_valid(b):
			_active_balls.erase(b)
			continue
		if not (b in _active_balls):
			continue
		var bid_pin: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
		if _ball_stuck_on_sticky_peg.has(bid_pin):
			var st_pid: int = int(_ball_stuck_on_sticky_peg[bid_pin])
			var st_peg: Node = _peg_by_id.get(st_pid)
			if st_peg and is_instance_valid(st_peg):
				var st_arr: Array = _sticky_slime_stuck_balls.get(st_pid, [])
				var st_i: int = st_arr.find(b)
				_pin_ball_to_sticky_slime(b, st_peg, st_i)
			else:
				_ball_stuck_on_sticky_peg.erase(bid_pin)
				if "freeze" in b:
					b.freeze = false
			continue
		if b.has_method("step_one_sim_tick"):
			var def: Resource = b.get_definition() if b.has_method("get_definition") else null
			var bdef: BallDefinition = def as BallDefinition if def is BallDefinition else null
			var ability_key: String = _ability_key(bdef)
			var peg: Node
			if ability_key == "Phantom":
				peg = _get_peg_overlapping_phantom_ball(b)
			else:
				peg = b.step_one_sim_tick(sim_tick)
			if peg and peg.get("peg_id") != null:
				var pid: int = peg.peg_id
				var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
				var ek_early: String = str(peg.get("peg_extra_kind")) if peg.get("peg_extra_kind") != null else ""
				if ek_early == "goblin_reset" and sim_tick < _goblin_reset_grace_until_tick.get(bid, -999999999):
					continue
				if ek_early == "buffet_table":
					if _buffet_sequence_active:
						if pid == _buffet_peg_id and _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
							_hit_cooldown.record_hit(bid, pid, sim_tick)
							_add_ball_to_buffet_feast(b, pid)
						continue
					if _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
						_hit_cooldown.record_hit(bid, pid, sim_tick)
						_begin_buffet_table_sequence(b, pid)
					continue
				if ek_early == "sticky_slime":
					if _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
						_hit_cooldown.record_hit(bid, pid, sim_tick)
						_ball_hit_count_this_visit[bid] = _ball_hit_count_this_visit.get(bid, 0) + 1
						_process_sticky_slime_peg_hit(b, pid, peg, sim_tick)
					continue
				if _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					_hit_cooldown.record_hit(bid, pid, sim_tick)
					_ball_hit_count_this_visit[bid] = _ball_hit_count_this_visit.get(bid, 0) + 1
					var energy_this_hit: int = PEG_DISPLAY_ENERGY_PER_HIT
					if ek_early == "gold" or ek_early == "lucky_gold":
						energy_this_hit *= Constants.GOLD_PEG_ENERGY_MULTIPLIER
						var gold_gain: int = 1
						if GameState and GameState.has_boss_upgrade(&"gilded_covenant"):
							gold_gain += 1
						gold_gained.emit(gold_gain, peg.global_position)
					# Overdrive Cascade (boss): all balls gain +1 legacy-display energy per hit during active window
					if _overdrive_cascade_end_tick > 0 and sim_tick <= _overdrive_cascade_end_tick:
						energy_this_hit += Constants.legacy_display_energy_to_current(1)
					# Ghost Trail: pegs in phantom trail grant +1 energy
					if GameState and GameState.has_wall_break_upgrade(&"ghost_trail") and _ghost_trail_pegs.has(pid):
						energy_this_hit += Constants.legacy_display_energy_to_current(1)
					# Resonant Bounce: plain balls on energized pegs gain +1 energy per energize stack
					if ability_key.is_empty() and GameState and GameState.has_wall_break_upgrade(&"resonant_bounce"):
						if peg.has_method("get_energize_stacks"):
							energy_this_hit += peg.get_energize_stacks() * Constants.legacy_display_energy_to_current(1)
					# Crown Ricochet (boss): plain balls after 4 peg hits in this fall get extra energy on later hits
					if ability_key.is_empty() and GameState and GameState.has_boss_upgrade(&"crown_ricochet"):
						if _ball_hit_count_this_visit.get(bid, 0) >= 5:
							energy_this_hit += Constants.legacy_display_energy_to_current(2)
					# Resonant Well (boss): Energize balls get flat bonus on every peg hit
					if ability_key == "Energize" and GameState and GameState.has_boss_upgrade(&"resonant_well"):
						energy_this_hit += Constants.legacy_display_energy_to_current(2)
					# Phantom Resonance (boss): Phantom through recently chain-hit pegs gain double energy
					if ability_key == "Phantom" and GameState and GameState.has_boss_upgrade(&"phantom_resonance"):
						if _chain_hit_peg_ticks.get(pid, 0) > 0 and (sim_tick - _chain_hit_peg_ticks.get(pid, 0)) < Constants.SIM_TICKS_PER_SECOND * 2:
							energy_this_hit *= 2
					# Phase Sovereign (boss): Phantom peg hits pay more energy
					if ability_key == "Phantom" and GameState and GameState.has_boss_upgrade(&"phase_sovereign"):
						energy_this_hit = int(round(float(energy_this_hit) * 1.22))
					# Overdrive Hits: after 5 peg hits in one fall, double energy per hit
					if GameState and GameState.has_wall_break_upgrade(&"overdrive_hits"):
						if _ball_hit_count_this_visit.get(bid, 0) > 5:
							energy_this_hit *= 2
					# Storm Feedback: temporary energy boost from chain-energize synergy
					if _storm_feedback_end_tick > 0 and sim_tick <= _storm_feedback_end_tick:
						energy_this_hit += Constants.legacy_display_energy_to_current(2)
					# Mass Cascade: temporary bonus while fragments are near each other
					if _mass_cascade_end_tick > 0 and sim_tick <= _mass_cascade_end_tick:
						energy_this_hit += Constants.legacy_display_energy_to_current(1)
					# Kinetic Charge: Rubbery on energized pegs gain speed + extra energy
					if ability_key == "Rubbery" and GameState and GameState.has_wall_break_upgrade(&"kinetic_charge"):
						if peg.has_method("has_energized_stacks") and peg.has_energized_stacks():
							energy_this_hit += Constants.legacy_display_energy_to_current(3)
							if "linear_velocity" in b:
								b.linear_velocity *= 1.15
					# Velocity Dividend (boss): mid–high speed Rubbery peg hits, no chain lightning
					if ability_key == "Rubbery" and GameState and GameState.has_boss_upgrade(&"velocity_dividend") and "linear_velocity" in b:
						var spd: float = b.linear_velocity.length()
						var v_lo: float = Constants.MAX_BALL_SPEED * 0.65
						var v_hi: float = Constants.MAX_BALL_SPEED * 0.85
						if spd >= v_lo and spd < v_hi:
							energy_this_hit += Constants.legacy_display_energy_to_current(3)
					if ability_key == "Leech":
						var _ldur: int = GameState.get_leech_duration_sec() if GameState else Constants.LEECH_DURATION_SEC
						_leeched_pegs.append({ "peg_id": pid, "alignment": bdef.alignment, "drains_remaining": _ldur })
						if peg.has_method("add_leech_stack"):
							peg.add_leech_stack()
					# Draining Fragments: Split twins apply mini-leech (half duration) on hit
					if GameState and GameState.has_wall_break_upgrade(&"draining_fragments"):
						if b.has_method("is_split_twin") and b.is_split_twin() and ability_key != "Leech":
							var _ldur_half: int = maxi(1, (GameState.get_leech_duration_sec() if GameState else Constants.LEECH_DURATION_SEC) / 2)
							_leeched_pegs.append({ "peg_id": pid, "alignment": bdef.alignment if bdef else 0, "drains_remaining": _ldur_half })
							if peg.has_method("add_leech_stack"):
								peg.add_leech_stack()
					# Plain-ball swarm milestone stats (empty ability_name only).
					if ability_key.is_empty() and GameState:
						energy_this_hit += GameState.plain_surge_stacks * Constants.legacy_display_energy_to_current(1)
						if _ball_hit_count_this_visit.get(bid, 0) > 5:
							energy_this_hit += GameState.plain_momentum_stacks * Constants.legacy_display_energy_to_current(1)
						if GameState.plain_horde_stacks > 0:
							var horde_n: int = _count_plain_balls_for_horde_bonus()
							var horde_bonus: int = mini((horde_n / 5) * GameState.plain_horde_stacks, 3)
							energy_this_hit += horde_bonus * Constants.legacy_display_energy_to_current(1)
					# Treasure chest: % bonus to peg-hit energy (numeric passives)
					if GameState:
						if ability_key == "Phantom" and GameState.chest_phantom_energy_stacks > 0:
							energy_this_hit = int(round(energy_this_hit * (1.0 + 0.05 * float(GameState.chest_phantom_energy_stacks))))
						if ability_key == "Rubbery" and GameState.chest_rubbery_energy_stacks > 0:
							energy_this_hit = int(round(energy_this_hit * (1.0 + 0.05 * float(GameState.chest_rubbery_energy_stacks))))
						if ability_key.is_empty() and GameState.chest_bounce_energy_stacks > 0:
							energy_this_hit = int(round(energy_this_hit * (1.0 + 0.05 * float(GameState.chest_bounce_energy_stacks))))
						if GameState.chest_split_energy_stacks > 0 and b.has_method("is_split_twin") and b.is_split_twin():
							energy_this_hit = int(round(energy_this_hit * (1.0 + 0.05 * float(GameState.chest_split_energy_stacks))))
					# Twin Mandate (boss): split fragments deal more peg-hit energy
					if GameState and GameState.has_boss_upgrade(&"twin_mandate") and b.has_method("is_split_twin") and b.is_split_twin():
						energy_this_hit = int(round(float(energy_this_hit) * 1.18))
					if b.has_method("get_gas_energy_stack_count"):
						energy_this_hit += b.get_gas_energy_stack_count() * Constants.legacy_display_energy_to_current(Constants.GAS_BUFF_ENERGY_LEGACY_PER_STACK)
					if b.has_method("add_peg_energy"):
						b.add_peg_energy(energy_this_hit)
					var has_attribute: bool = bdef != null and (not bdef.status_effects.is_empty() or not ability_key.is_empty())
					var is_energize: bool = (ability_key == "Energize")
					# Energized Fragments: Split twins energize every peg they touch
					var apply_energize_from_fragment: bool = false
					if GameState and GameState.has_wall_break_upgrade(&"energized_fragments"):
						if b.has_method("is_split_twin") and b.is_split_twin():
							apply_energize_from_fragment = true
					# Phase Siphon: Phantom balls drain 1 energize stack from energized pegs for +50% energy
					if ability_key == "Phantom" and GameState and GameState.has_wall_break_upgrade(&"phase_siphon"):
						if peg.has_method("has_energized_stacks") and peg.has_energized_stacks():
							if peg.has_method("consume_energize_stack"):
								peg.consume_energize_stack()
							if b.has_method("add_peg_energy"):
								b.add_peg_energy(energy_this_hit / 2)
					if ability_key == "Phantom":
						_phantom_pegs_visited[bid] = _phantom_pegs_visited.get(bid, 0) + 1
						# Spectral Conduit: Phantom balls leave a trail for chain lightning
						if GameState and GameState.has_wall_break_upgrade(&"spectral_conduit"):
							_phantom_trail.append({ "position": peg.global_position, "tick": sim_tick })
						# Ghost Trail: mark peg as trailed (pegs in trail grant +1 energy)
						if GameState and GameState.has_wall_break_upgrade(&"ghost_trail"):
							_ghost_trail_pegs[pid] = sim_tick + Constants.SIM_TICKS_PER_SECOND * 3
							if peg.has_method("set_ghost_trail"):
								peg.set_ghost_trail(true)
					# Phantom skips apply_hit except Goblin Reset: that peg must take damage and enter recovery or Phantom overlap retriggers grab every few ticks.
					var ek: String = str(peg.get("peg_extra_kind")) if peg.get("peg_extra_kind") != null else ""
					var apply_peg_hit: bool = (ability_key != "Phantom") or (ek == "goblin_reset" or ek == "milestone_event" or ek == "treasure_chest" or ek == "buffet_table" or ek == "sticky_slime")
					if apply_peg_hit and peg.has_method("apply_hit"):
						var base_hit_dmg: int = 0 if is_energize else 1
						var gas_extra: int = 0
						if b.has_method("get_gas_damage_stack_count"):
							gas_extra = b.get_gas_damage_stack_count() * Constants.GAS_BUFF_DAMAGE_PER_CLOUD_STACK
						var peg_accepts_energize: bool = not Constants.peg_extra_kind_blocks_energize(ek)
						peg.apply_hit(not has_attribute, base_hit_dmg + gas_extra, (is_energize or apply_energize_from_fragment) and peg_accepts_energize)
					# Overclock Network: energized peg gains +1 durability per adjacent energized peg
					if (is_energize or apply_energize_from_fragment) and not Constants.peg_extra_kind_blocks_energize(ek) and GameState and GameState.has_wall_break_upgrade(&"overclock_network"):
						_apply_overclock_network_bonus(pid)
					# Storm of Fragments (boss): track energized pegs hit by split fragments
					if GameState and GameState.has_boss_upgrade(&"storm_of_fragments"):
						if b.has_method("is_split_twin") and b.is_split_twin():
							if peg.has_method("has_energized_stacks") and peg.has_energized_stacks():
								_ball_energized_pegs_hit[bid] = _ball_energized_pegs_hit.get(bid, 0) + 1
								if _ball_energized_pegs_hit[bid] == 3:
									_trigger_storm_of_fragments(bid, b, b.get_definition() as BallDefinition if b.has_method("get_definition") else null, sim_tick)
					if str(peg.get("peg_extra_kind")) == "trampoline":
						_spawn_trampoline_bounce_effect(peg.global_position)
						if b.has_method("schedule_trampoline_upward_boost"):
							b.schedule_trampoline_upward_boost()
					# Hyper Elastic: Rubbery balls bouncing strongly upward gain speed boost
					if ability_key == "Rubbery" and GameState and GameState.has_wall_break_upgrade(&"hyper_elastic"):
						if "linear_velocity" in b and b.linear_velocity.y < -150.0:
							b.linear_velocity *= Constants.HYPER_ELASTIC_SPEED_MULTIPLIER
					# Bomb peg: trigger primary explosion. Shrapnel Split: double radius for split twins.
					if peg.get("peg_extra_kind") == "bomb":
						var is_split_twin_ball: bool = b.has_method("is_split_twin") and b.is_split_twin()
						var shrapnel_active: bool = is_split_twin_ball and GameState != null and GameState.has_wall_break_upgrade(&"shrapnel_split")
						if shrapnel_active:
							GameState.explosion_radius_bonus += 4
						_apply_explosive_hits(pid, b, bdef, sim_tick, 0)
						_spawn_explosive_effect_at_ball(peg.global_position)
						if shrapnel_active:
							GameState.explosion_radius_bonus -= 4
						# Fragment Swarm (boss): fragments can re-split on bomb peg
						if is_split_twin_ball and GameState and GameState.has_boss_upgrade(&"fragment_swarm"):
							if b.has_method("has_split_triggered"):
								b._split_triggered = false
					# Goblin Reset: grab ball and send it back to the top
					if peg.get("peg_extra_kind") == "goblin_reset":
						_apply_goblin_reset_ball(b)
					# Wrench: repair nearby recovering pegs
					if peg.get("peg_extra_kind") == "wrench":
						_apply_wrench_repair(pid, peg)
					# Extreme Bouncer: strong velocity multiplication
					if peg.get("peg_extra_kind") == "extreme_bouncer":
						if "linear_velocity" in b:
							b.linear_velocity *= Constants.EXTREME_BOUNCER_SPEED_MULTIPLIER
					# Splitter Peg: split any ball that hits it (once per ball per visit)
					if peg.get("peg_extra_kind") == "splitter":
						if not _splitter_triggered_this_visit.get(bid, false):
							_splitter_triggered_this_visit[bid] = true
							var split_vel: Vector2 = b.linear_velocity if "linear_velocity" in b else Vector2.ZERO
							var split_total: int = b.get_total_energy() if b.has_method("get_total_energy") else Constants.legacy_display_energy_to_current(20)
							var half_e: int = split_total / 2
							b.set_total_energy_display(half_e)
							var frag: Node = _spawn_split_ball(b.global_position, split_vel.rotated(Constants.SPLITTER_PEG_SPLIT_ANGLE), bdef, half_e)
							if frag != null:
								_active_balls.append(frag)
								_ball_hit_count_this_visit[frag.get_ball_id()] = 0
								_splitter_triggered_this_visit[frag.get_ball_id()] = true
					# Supernova Peg (hard cap: 1 per peg per sim tick)
					if is_energize and GameState and GameState.has_wall_break_upgrade(&"supernova_peg") and peg.has_method("get_energized_durability") and peg.has_method("get_max_durability") and peg.get_energized_durability() >= peg.get_max_durability() and not _supernova_triggered_pegs_this_tick.get(pid, false):
						_trigger_supernova(pid, b, bdef, sim_tick)
					# Impact Burst: High-speed Rubbery hits trigger mini-explosions
					if ability_key == "Rubbery" and GameState and GameState.has_wall_break_upgrade(&"impact_burst"):
						if "linear_velocity" in b and b.linear_velocity.length() > Constants.MAX_BALL_SPEED * 0.7:
							if not _explosion_triggered_pegs_this_tick.get(pid, false):
								_apply_explosive_hits(pid, b, bdef, sim_tick, 1)
								_spawn_explosive_effect_at_ball(peg.global_position)
					# Static Bounce: Rubbery balls that hit 4+ pegs emit chain lightning from the 4th peg
					if ability_key == "Rubbery" and GameState and GameState.has_wall_break_upgrade(&"static_bounce"):
						var hits: int = _ball_hit_count_this_visit.get(bid, 0)
						if hits == 4:
							_chain_conduction_done_this_event = false
							_apply_chain_lightning_hits(pid, b, bdef, sim_tick)
					# Rubber Storm (boss): max speed Rubbery emits chain on every bounce
					if ability_key == "Rubbery" and GameState and GameState.has_boss_upgrade(&"rubber_storm"):
						if "linear_velocity" in b and b.linear_velocity.length() > Constants.MAX_BALL_SPEED * 0.85:
							_chain_conduction_done_this_event = false
							_apply_chain_lightning_hits(pid, b, bdef, sim_tick)
					# Ricochet Blast: plain ball after 6+ hits, next hit triggers explosion
					if ability_key.is_empty() and GameState and GameState.has_wall_break_upgrade(&"ricochet_blast"):
						var hits: int = _ball_hit_count_this_visit.get(bid, 0)
						if hits >= 6 and not _explosion_triggered_pegs_this_tick.get(pid, false):
							_apply_explosive_hits(pid, b, bdef, sim_tick, 1)
							_spawn_explosive_effect_at_ball(peg.global_position)
							_ball_hit_count_this_visit[bid] = 0
					# Overdrive Cascade (boss): trigger after any ball hits 5 pegs
					if GameState and GameState.has_boss_upgrade(&"overdrive_cascade"):
						var hits: int = _ball_hit_count_this_visit.get(bid, 0)
						if hits == 5:
							_overdrive_cascade_end_tick = sim_tick + Constants.SIM_TICKS_PER_SECOND * 3
					# Bloom: every 5 peg hits on this ball (same counter as visit hits). Spawn is at the
					# Bloom ball’s position; repeats at 10, 15, … (counter not zeroed). Spawns a random catalog ball.
					if ability_key == "Bloom":
						var hits_co: int = _ball_hit_count_this_visit.get(bid, 0)
						if hits_co >= 5 and hits_co % 5 == 0:
							_spawn_random_ball_from_bloom_at(b.global_position, b, sim_tick)
					_spawn_energy_popup(peg, energy_this_hit)
					if ability_key == "Volatile":
						_release_volatile_ball(b, peg.global_position, sim_tick)
						continue
					if bdef != null:
						if not bdef.status_effects.is_empty():
							ball_ability_on_peg_hit.emit(bdef.status_effects)
						var allow_split_effect: bool = (ability_key == "Split" and b.has_method("has_split_triggered") and not b.has_split_triggered())
						if ability_key != "Explosive" and ability_key != "Chain Lightning":
							_spawn_hit_effect(peg.global_position, bdef.status_effects, ability_key, allow_split_effect)
						# Split: spawn second ball. Fragment Swarm (boss): split into 3 instead of 2.
						if ability_key == "Split" and b.has_method("has_split_triggered") and not b.has_split_triggered():
							b.mark_split_triggered()
							var ball_vel: Vector2 = b.linear_velocity if "linear_velocity" in b else Vector2.ZERO
							var total: int = b.get_total_energy() if b.has_method("get_total_energy") else Constants.legacy_display_energy_to_current(20)
							var split_count: int = 3 if (GameState and GameState.has_boss_upgrade(&"fragment_swarm")) else 2
							var share: int = total / split_count
							b.set_total_energy_display(share)
							for split_i in range(split_count - 1):
								var angle_offset: float = (TAU / float(split_count)) * float(split_i + 1)
								var rotated_vel: Vector2 = ball_vel.rotated(angle_offset)
								var frag: Node = _spawn_split_ball(b.global_position, rotated_vel, bdef, share)
								if frag != null:
									_active_balls.append(frag)
									_ball_hit_count_this_visit[frag.get_ball_id()] = 0
									if frag.has_method("start_split_spin"):
										frag.start_split_spin()
							b.start_split_spin()
						if ability_key == "Explosive":
							_apply_explosive_hits(pid, b, bdef, sim_tick, 0)
							_spawn_explosive_effect_at_ball(b.global_position)
						elif ability_key == "Chain Lightning":
							_chain_conduction_done_this_event = false
							_apply_chain_lightning_hits(pid, b, bdef, sim_tick)
		# Polyomino module kinetic machinery interaction
		if not _placed_module_nodes.is_empty():
			for mod_node in _placed_module_nodes.values():
				if is_instance_valid(mod_node) and mod_node.has_method("check_ball_collision"):
					mod_node.check_ball_collision(b, sim_tick)
	_process_binary_ball_on_ball_splits(sim_tick)
	_check_peg_destruction_upgrades(sim_tick)
	_process_milestone_event_pegs(sim_tick)
	_process_treasure_chest_pegs(sim_tick)
	_process_ghost_states(sim_tick)

func flush_tick(sim_tick: int) -> void:
	_board_sim_tick = sim_tick
	_prune_expired_gas_clouds(sim_tick)
	_remove_freed_active_balls()
	_apply_constellation_laser_hits(sim_tick)
	_process_leech_drains(sim_tick)
	# Clean stale phantom trail entries (older than 3 seconds)
	_phantom_trail = _phantom_trail.filter(func(e): return (sim_tick - e.get("tick", 0)) < Constants.SIM_TICKS_PER_SECOND * 3)
	# Clean expired ghost trail pegs and remove their visual glow
	var expired_ghost: Array = []
	for gp_id in _ghost_trail_pegs:
		if sim_tick >= _ghost_trail_pegs[gp_id]:
			expired_ghost.append(gp_id)
	for gp_id in expired_ghost:
		_ghost_trail_pegs.erase(gp_id)
		var gp: Node = _peg_by_id.get(gp_id)
		if gp and gp.has_method("set_ghost_trail"):
			gp.set_ghost_trail(false)
	# Mass Cascade: two fragments near each other activate temporary energy bonus
	if GameState and GameState.has_wall_break_upgrade(&"mass_cascade"):
		var mc_twins: Array = []
		for ab in _active_balls:
			if ab.has_method("is_split_twin") and ab.is_split_twin():
				mc_twins.append(ab)
		for mc_i in range(mc_twins.size()):
			for mc_j in range(mc_i + 1, mc_twins.size()):
				if mc_twins[mc_i].global_position.distance_to(mc_twins[mc_j].global_position) <= Constants.MASS_CASCADE_PROXIMITY_PX:
					_mass_cascade_end_tick = sim_tick + Constants.MASS_CASCADE_DURATION_TICKS
	# Arc Twins: when both split fragments exist simultaneously, chain lightning arcs between them
	if GameState and GameState.has_wall_break_upgrade(&"arc_twins"):
		var twins: Array = []
		for ab in _active_balls:
			if ab.has_method("is_split_twin") and ab.is_split_twin():
				twins.append(ab)
		if twins.size() >= 2:
			var positions: Array = []
			for tw in twins:
				positions.append(tw.global_position)
			if positions.size() >= 2:
				_spawn_chain_lightning_arcs(positions)
	for b in _active_balls.duplicate():
		if not is_instance_valid(b):
			_active_balls.erase(b)
			continue
		var pos: Vector2 = b.get_global_sim_position() if b.has_method("get_global_sim_position") else b.global_position
		var ability_for_bottom: String = ""
		if b.has_method("get_definition"):
			var def_bottom = b.get_definition()
			if def_bottom is BallDefinition:
				ability_for_bottom = _ability_key(def_bottom as BallDefinition)
		if ability_for_bottom == "Volatile" and pos.y >= BOTTOM_ZONE_Y:
			_release_volatile_ball(b, pos, sim_tick)
			continue
		if pos.y >= BOTTOM_ZONE_Y:
			var ball_id: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
			var total: int = b.get_total_energy() if b.has_method("get_total_energy") else Constants.legacy_display_energy_to_current(20)
			var alignment: int = 0
			var status_effects: Dictionary = {}
			var ability_name: String = ""
			if b.has_method("get_definition"):
				var def = b.get_definition()
				if def is BallDefinition:
					var bd: BallDefinition = def as BallDefinition
					alignment = bd.alignment
					ability_name = _ability_key(bd)
					if bd.status_effects != null and not bd.status_effects.is_empty():
						status_effects = bd.status_effects
			# Phase Detonation: phantom ball passing through 5+ pegs triggers explosion at exit
			if ability_name == "Phantom" and GameState and GameState.has_wall_break_upgrade(&"phase_detonation"):
				if _phantom_pegs_visited.get(ball_id, 0) >= 5:
					var nearest_peg_id: int = get_nearest_normal_peg_id(pos, 200.0)
					if nearest_peg_id >= 0 and not _explosion_triggered_pegs_this_tick.get(nearest_peg_id, false):
						_apply_explosive_hits(nearest_peg_id, b, b.get_definition() as BallDefinition if b.has_method("get_definition") else null, sim_tick, 0)
						_spawn_explosive_effect_at_ball(pos)
			# Phase Instability: phantom with 0 peg hits re-enters top with bonus energy (once)
			if ability_name == "Phantom" and GameState and GameState.has_wall_break_upgrade(&"phase_instability"):
				if _phantom_pegs_visited.get(ball_id, 0) == 0:
					if b.has_method("add_peg_energy"):
						b.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT * 3)
					b.global_position = _spawn_position
					if "linear_velocity" in b:
						b.linear_velocity = Vector2.ZERO
					_phantom_pegs_visited[ball_id] = -1
					continue
			if b.has_method("clear_gas_buffs_on_score"):
				b.clear_gas_buffs_on_score()
			_spawn_hit_effect(pos, status_effects, ability_name, false)
			ball_reached_bottom.emit(ball_id, total, alignment, pos, status_effects)
			_active_balls.erase(b)
			_ball_hit_count_this_visit.erase(ball_id)
			_phantom_pegs_visited.erase(ball_id)
			_ball_energized_pegs_hit.erase(ball_id)
			_splitter_triggered_this_visit.erase(ball_id)
			ball_exited_board.emit(b, REASON_BOTTOM)
		elif pos.y > OFF_SCREEN_Y or pos.x < OFF_SCREEN_X_LEFT or pos.x > OFF_SCREEN_X_RIGHT:
			var ball_id: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
			_active_balls.erase(b)
			_ball_hit_count_this_visit.erase(ball_id)
			_phantom_pegs_visited.erase(ball_id)
			_ball_energized_pegs_hit.erase(ball_id)
			_splitter_triggered_this_visit.erase(ball_id)
			ball_exited_board.emit(b, REASON_OFF_SCREEN)
	_update_constellation_laser_visual_state()

func _update_constellation_laser_visual_state() -> void:
	var c: int = _count_constellation_balls_active()
	var has_links: bool = c >= 2
	if has_links or _had_constellation_laser_visual:
		queue_redraw()
	_had_constellation_laser_visual = has_links

func _count_constellation_balls_active() -> int:
	var n: int = 0
	for b in _active_balls:
		if not is_instance_valid(b):
			continue
		var bd: Resource = b.get_definition() if b.has_method("get_definition") else null
		if bd is BallDefinition and _ability_key(bd as BallDefinition) == "Constellation":
			n += 1
	return n

func _draw() -> void:
	# Straight segments between Constellation ball centers (not chain-lightning / jagged arcs).
	if not _had_constellation_laser_visual:
		return
	var local_pts: Array[Vector2] = []
	for b in _active_balls:
		if not is_instance_valid(b):
			continue
		var bd: Resource = b.get_definition() if b.has_method("get_definition") else null
		if not (bd is BallDefinition and _ability_key(bd as BallDefinition) == "Constellation"):
			continue
		var gp: Variant = b.get("global_position")
		var p: Vector2 = gp as Vector2 if gp is Vector2 else b.position
		local_pts.append(to_local(p))
	for i in range(local_pts.size()):
		for j in range(i + 1, local_pts.size()):
			var a: Vector2 = local_pts[i]
			var bpt: Vector2 = local_pts[j]
			var ch_out: Color = Constants.gameplay_chain_lightning_glow_outer()
			var ch_in: Color = Constants.gameplay_chain_lightning_glow_inner()
			draw_line(a, bpt, Color(ch_out.r, ch_out.g, ch_out.b, 0.42), 4.5)
			draw_line(a, bpt, Color(ch_in.r, ch_in.g, ch_in.b, 0.78), 1.6)

func explode_at(_peg_id: int) -> void:
	pass  # future: bomb peg or external trigger; ball-triggered explosive uses _apply_explosive_hits

## GDD: Explosive ball — apply hit to all pegs within radius. Hard cap: 1 explosion per peg per sim tick. Cluster depth cap = 1.
func _apply_explosive_hits(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int, cluster_depth: int = 0) -> void:
	if _explosion_triggered_pegs_this_tick.get(center_peg_id, false):
		return
	_explosion_triggered_pegs_this_tick[center_peg_id] = true
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var center_pos: Vector2 = center_peg.global_position
	var radius_px: float = Constants.EXPLOSIVE_RADIUS_PX
	if GameState:
		radius_px += float(GameState.explosion_radius_bonus) * 12.0
	var damage_per_hit: int = 1 + (GameState.explosion_peg_hit_count_bonus if GameState else 0)
	if GameState and GameState.has_wall_break_upgrade(&"fragmentation_tag"):
		damage_per_hit += GameState.get_wall_break_upgrade_stacks(&"fragmentation_tag")
	var add_energize: bool = GameState.has_wall_break_upgrade(&"explosions_apply_energize") if GameState else false
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	for other_id in _peg_by_id:
		if other_id == center_peg_id:
			continue
		var other_peg: Node = _peg_by_id[other_id]
		if not other_peg or not other_peg.get("global_position"):
			continue
		if center_pos.distance_to(other_peg.global_position) > radius_px:
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
		if other_peg.has_method("apply_hit"):
			var ek_expl: String = str(other_peg.get("peg_extra_kind")) if other_peg.get("peg_extra_kind") != null else ""
			other_peg.apply_hit(true, damage_per_hit, add_energize and not Constants.peg_extra_kind_blocks_energize(ek_expl))
		if other_peg.has_method("play_wobble"):
			other_peg.play_wobble()
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
	if center_peg.has_method("play_wobble"):
		center_peg.play_wobble()
	# Explosive Contagion (boss): all pegs hit by explosions gain 1 leech stack
	if GameState and GameState.has_boss_upgrade(&"explosive_contagion"):
		for other_id in _peg_by_id:
			if other_id == center_peg_id:
				continue
			var ep: Node = _peg_by_id[other_id]
			if not ep or not ep.get("global_position"):
				continue
			if center_pos.distance_to(ep.global_position) > radius_px:
				continue
			var _ldur_ec: int = GameState.get_leech_duration_sec() if GameState else Constants.LEECH_DURATION_SEC
			_leeched_pegs.append({ "peg_id": other_id, "alignment": bdef.alignment if bdef else 0, "drains_remaining": _ldur_ec })
			if ep.has_method("add_leech_stack"):
				ep.add_leech_stack()
	# Blast Launch: explosions near trampoline pegs launch ALL nearby balls upward
	if GameState and GameState.has_wall_break_upgrade(&"blast_launch"):
		var has_nearby_trampoline: bool = false
		for tp_id in _peg_by_id:
			var tp: Node = _peg_by_id[tp_id]
			if tp.get("peg_extra_kind") == "trampoline" and center_pos.distance_to(tp.global_position) <= radius_px * 1.5:
				has_nearby_trampoline = true
				break
		if has_nearby_trampoline:
			for active_ball in _active_balls:
				if "global_position" in active_ball and active_ball.has_method("schedule_trampoline_upward_boost"):
					if center_pos.distance_to(active_ball.global_position) <= radius_px * 2.0:
						active_ball.schedule_trampoline_upward_boost()
	# Blast Lift: any explosion pushes nearby balls upward (stackable)
	if GameState and GameState.has_wall_break_upgrade(&"blast_lift"):
		var lift_stacks: int = GameState.get_wall_break_upgrade_stacks(&"blast_lift")
		for active_ball in _active_balls:
			if "linear_velocity" in active_ball and "global_position" in active_ball:
				if center_pos.distance_to(active_ball.global_position) <= radius_px * 1.5:
					active_ball.linear_velocity.y -= 80.0 * float(lift_stacks)
	# Explosion Impulse: push nearby balls outward from explosion center
	if GameState and GameState.explosion_impulse_bonus > 0.0:
		for active_ball in _active_balls:
			if "linear_velocity" in active_ball and "global_position" in active_ball:
				var dist: float = center_pos.distance_to(active_ball.global_position)
				if dist <= radius_px * 1.5 and dist > 0.1:
					var dir: Vector2 = (active_ball.global_position - center_pos).normalized()
					active_ball.linear_velocity += dir * 100.0 * GameState.explosion_impulse_bonus
	# Cluster Grenade (depth cap = 1): primary only; secondary explosions do not spawn further clusters.
	if cluster_depth == 0 and GameState and GameState.has_wall_break_upgrade(&"cluster_grenade"):
		var nearest: Array = _get_nearest_pegs(center_peg_id, 2)
		var cluster_secondary_radius: float = Constants.EXPLOSIVE_RADIUS_PX * 0.55
		for i in range(mini(nearest.size(), 2)):
			var p: Node = nearest[i]
			var pid: int = p.peg_id if p.get("peg_id") != null else -1
			if pid >= 0 and not _explosion_triggered_pegs_this_tick.get(pid, false):
				_apply_explosive_hits(pid, ball, bdef, sim_tick, 1)
				_spawn_explosive_effect_at_ball(p.global_position, cluster_secondary_radius)

## GDD: Chain Lightning ball — apply hit to up to CHAIN_LIGHTNING_COUNT + bonus nearest pegs; conduction once per chain event.
func _apply_chain_lightning_hits(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var chain_count: int = Constants.CHAIN_LIGHTNING_COUNT + (GameState.chain_arc_bonus if GameState else 0)
	var nearest: Array = _get_nearest_pegs(center_peg_id, chain_count)
	if GameState and GameState.chain_range_bonus > 0:
		var center_pos: Vector2 = center_peg.global_position
		var max_dist: float = 200.0 + float(GameState.chain_range_bonus) * 30.0
		nearest = nearest.filter(func(p): return center_pos.distance_to(p.global_position) <= max_dist)
	var add_energize: bool = GameState.has_wall_break_upgrade(&"chain_hits_apply_energize") if GameState else false
	var lightning_status: Dictionary = { Constants.STATUS_LIGHTNING: 1 }
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	var chain_positions: Array = [center_peg.global_position]
	if center_peg.has_method("play_lightning_shock"):
		center_peg.play_lightning_shock()
	for other_peg in nearest:
		var other_id: int = other_peg.peg_id if other_peg.get("peg_id") != null else -1
		if other_id < 0:
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
		if other_peg.has_method("apply_hit"):
			var ek_chain: String = str(other_peg.get("peg_extra_kind")) if other_peg.get("peg_extra_kind") != null else ""
			other_peg.apply_hit(true, 1, add_energize and not Constants.peg_extra_kind_blocks_energize(ek_chain))
		if other_peg.has_method("play_lightning_shock"):
			other_peg.play_lightning_shock()
		ball_ability_on_peg_hit.emit(lightning_status)
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
		chain_positions.append(other_peg.global_position)
	# Track chain-hit pegs for phantom_resonance boss upgrade
	for cp in nearest:
		var cp_id: int = cp.peg_id if cp.get("peg_id") != null else -1
		if cp_id >= 0:
			# Overcurrent Surge: chain hitting already-chain-hit peg refreshes and generates extra energy
			if GameState and GameState.has_wall_break_upgrade(&"overcurrent_surge"):
				if _chain_hit_peg_ticks.get(cp_id, 0) == sim_tick:
					if cp.has_method("reset_to_full"):
						cp.reset_to_full()
					if ball.has_method("add_peg_energy"):
						ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
			_chain_hit_peg_ticks[cp_id] = sim_tick
	# Storm Feedback: chain arcing between 2+ energized pegs activates temporary energy boost
	if GameState and GameState.has_wall_break_upgrade(&"storm_feedback"):
		var energized_chain_count: int = 0
		for cp in nearest:
			if cp.has_method("has_energized_stacks") and cp.has_energized_stacks():
				energized_chain_count += 1
		if energized_chain_count >= 2:
			_storm_feedback_end_tick = sim_tick + Constants.STORM_FEEDBACK_DURATION_TICKS
	# Parasitic Arc: chain hitting a leeched peg spreads leech to all chain targets
	if GameState and GameState.has_wall_break_upgrade(&"parasitic_arc"):
		var has_leeched_target: bool = false
		for cp in nearest:
			var cp_leech: int = cp.get_leech_stack_count() if cp.has_method("get_leech_stack_count") else 0
			if cp_leech > 0:
				has_leeched_target = true
				break
		if has_leeched_target:
			for cp in nearest:
				var cp_id: int = cp.peg_id if cp.get("peg_id") != null else -1
				if cp_id >= 0:
					var _ldur_pa: int = GameState.get_leech_duration_sec() if GameState else Constants.LEECH_DURATION_SEC
					_leeched_pegs.append({ "peg_id": cp_id, "alignment": bdef.alignment if bdef else 0, "drains_remaining": _ldur_pa })
					if cp.has_method("add_leech_stack"):
						cp.add_leech_stack()
	# Final Arc Detonation: last chain target triggers mini explosion
	if GameState and GameState.has_wall_break_upgrade(&"final_arc_detonation") and nearest.size() > 0:
		var last_peg: Node = nearest[nearest.size() - 1]
		var last_pid: int = last_peg.peg_id if last_peg.get("peg_id") != null else -1
		if last_pid >= 0 and not _explosion_triggered_pegs_this_tick.get(last_pid, false):
			_apply_explosive_hits(last_pid, ball, bdef, sim_tick, 1)
			_spawn_explosive_effect_at_ball(last_peg.global_position)
	# Chain Conduction: once per chain event, arc to all energized pegs not already in this chain.
	var conduction_hit_nodes: Array = []
	if GameState and GameState.has_wall_break_upgrade(&"chain_conduction") and not _chain_conduction_done_this_event:
		var chain_peg_ids: Array = [center_peg_id]
		for other_peg in nearest:
			var oid: int = other_peg.peg_id if other_peg.get("peg_id") != null else -1
			if oid >= 0:
				chain_peg_ids.append(oid)
		var energized_pegs: Array = []
		for pid in _peg_by_id:
			var p: Node = _peg_by_id[pid]
			if p.has_method("has_energized_stacks") and p.has_energized_stacks() and pid not in chain_peg_ids:
				energized_pegs.append(p)
		if energized_pegs.size() > 0:
			_chain_conduction_done_this_event = true
			for other_peg in energized_pegs:
				var other_id: int = other_peg.peg_id if other_peg.get("peg_id") != null else -1
				if other_id < 0 or not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					continue
				_hit_cooldown.record_hit(bid, other_id, sim_tick)
				if ball.has_method("add_peg_energy"):
					ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
				if other_peg.has_method("apply_hit"):
					other_peg.apply_hit(true, 1, false)
				if other_peg.has_method("play_lightning_shock"):
					other_peg.play_lightning_shock()
				chain_positions.append(other_peg.global_position)
				conduction_hit_nodes.append(other_peg)
	# Spectral Conduit: chain lightning can arc to phantom trail positions as virtual pegs
	if GameState and GameState.has_wall_break_upgrade(&"spectral_conduit") and _phantom_trail.size() > 0:
		for trail_entry in _phantom_trail:
			if chain_positions.size() > 0:
				var trail_pos: Vector2 = trail_entry.get("position", Vector2.ZERO)
				var last_pos: Vector2 = chain_positions[chain_positions.size() - 1]
				if last_pos.distance_to(trail_pos) < 200.0:
					chain_positions.append(trail_pos)
	# Superconductor (boss): chain conduction triggers secondary chain from furthest energized peg
	if GameState and GameState.has_boss_upgrade(&"superconductor") and _chain_conduction_done_this_event:
		var furthest_pos: Vector2 = Vector2.ZERO
		var furthest_dist: float = 0.0
		var furthest_pid: int = -1
		var center_pos: Vector2 = center_peg.global_position
		for s_pid in _peg_by_id:
			var sp: Node = _peg_by_id[s_pid]
			if sp.has_method("has_energized_stacks") and sp.has_energized_stacks():
				var d: float = center_pos.distance_to(sp.global_position)
				if d > furthest_dist:
					furthest_dist = d
					furthest_pid = s_pid
					furthest_pos = sp.global_position
		if furthest_pid >= 0:
			var secondary_chain: Array = [furthest_pos]
			var secondary_nearest: Array = _get_nearest_pegs(furthest_pid, 3)
			for sn in secondary_nearest:
				var sn_id: int = sn.peg_id if sn.get("peg_id") != null else -1
				if sn_id >= 0 and _hit_cooldown.cooldown_ok(bid, sn_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					_hit_cooldown.record_hit(bid, sn_id, sim_tick)
					if ball.has_method("add_peg_energy"):
						ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
					if sn.has_method("apply_hit"):
						sn.apply_hit(true, 1, false)
					if sn.has_method("play_lightning_shock"):
						sn.play_lightning_shock()
					secondary_chain.append(sn.global_position)
			if secondary_chain.size() > 1:
				_spawn_chain_lightning_arcs(secondary_chain)
	_apply_chain_lightning_cross_link_effects(center_peg, nearest, conduction_hit_nodes)
	_spawn_chain_lightning_arcs(chain_positions)

## Supernova Peg: large explosion, release energy, hit nearby pegs, reset center peg. Hard cap: 1 per peg per sim tick.
func _trigger_supernova(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	_supernova_triggered_pegs_this_tick[center_peg_id] = true
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var center_pos: Vector2 = center_peg.global_position
	var radius_px: float = Constants.EXPLOSIVE_RADIUS_PX * 1.5
	if GameState:
		radius_px += float(GameState.explosion_radius_bonus) * 12.0
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	for other_id in _peg_by_id:
		var other_peg: Node = _peg_by_id[other_id]
		if not other_peg or not other_peg.get("global_position"):
			continue
		if center_pos.distance_to(other_peg.global_position) > radius_px:
			continue
		if other_id == center_peg_id:
			if other_peg.has_method("reset_to_full"):
				other_peg.reset_to_full()
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT * 2)
		if other_peg.has_method("apply_hit"):
			other_peg.apply_hit(true, 1, false)
		if other_peg.has_method("play_wobble"):
			other_peg.play_wobble()
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
	if center_peg.has_method("play_wobble"):
		center_peg.play_wobble()
	# Cascade Reactor (boss): supernova triggers chain lightning to ALL leeched pegs
	if GameState and GameState.has_boss_upgrade(&"cascade_reactor"):
		var leeched_peg_positions: Array = [center_peg.global_position]
		for lp_pid in _peg_by_id:
			var lp: Node = _peg_by_id[lp_pid]
			if not lp or not lp.get("global_position"):
				continue
			if not lp.has_method("get_leech_stack_count") or lp.get_leech_stack_count() <= 0:
				continue
			var lp_id: int = lp.peg_id if lp.get("peg_id") != null else -1
			if lp_id >= 0 and _hit_cooldown.cooldown_ok(bid, lp_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
				_hit_cooldown.record_hit(bid, lp_id, sim_tick)
				if ball.has_method("add_peg_energy"):
					ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
				if lp.has_method("apply_hit"):
					lp.apply_hit(true, 1, false)
				if lp.has_method("play_lightning_shock"):
					lp.play_lightning_shock()
				leeched_peg_positions.append(lp.global_position)
		if leeched_peg_positions.size() > 1:
			_spawn_chain_lightning_arcs(leeched_peg_positions)

## Wrench peg: restore all recovering pegs within radius to full durability, then reset the wrench peg itself.
func _apply_wrench_repair(center_peg_id: int, center_peg: Node) -> void:
	if not center_peg or not center_peg.get("global_position"):
		return
	var center_pos: Vector2 = center_peg.global_position
	var radius_px: float = Constants.WRENCH_REPAIR_RADIUS_PX
	var any_reset: bool = false
	for other_id in _peg_by_id:
		if other_id == center_peg_id:
			continue
		var other_peg: Node = _peg_by_id[other_id]
		if not other_peg or not other_peg.get("global_position"):
			continue
		if center_pos.distance_to(other_peg.global_position) > radius_px:
			continue
		if other_peg.get("_recovery_ticks_remaining") != null and other_peg._recovery_ticks_remaining > 0:
			if other_peg.has_method("reset_to_full"):
				other_peg.reset_to_full()
			if other_peg.has_method("play_wobble"):
				other_peg.play_wobble()
			any_reset = true
	if center_peg.has_method("reset_to_full"):
		center_peg.reset_to_full()
	if any_reset:
		_spawn_wrench_repair_effect(center_pos)

func _repair_random_damaged_pegs(count: int) -> void:
	var damaged: Array = []
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if not p:
			continue
		var rem: Variant = p.get("_recovery_ticks_remaining")
		if rem != null and int(rem) > 0:
			damaged.append(p)
	damaged.shuffle()
	var n: int = mini(count, damaged.size())
	for i in range(n):
		var peg: Node = damaged[i]
		if peg.has_method("reset_to_full"):
			peg.reset_to_full()
		if peg.has_method("play_wobble"):
			peg.play_wobble()

func _chain_lightning_touches_peg_kind(center_peg: Node, nearest: Array, conduction_nodes: Array, kind: String) -> bool:
	if center_peg and str(center_peg.get("peg_extra_kind")) == kind and _peg_extra_effects_active(center_peg):
		return true
	for p in nearest:
		if p and str(p.get("peg_extra_kind")) == kind and _peg_extra_effects_active(p):
			return true
	for p in conduction_nodes:
		if p and str(p.get("peg_extra_kind")) == kind and _peg_extra_effects_active(p):
			return true
	return false

func _first_peg_kind_in_chain(center_peg: Node, nearest: Array, conduction_nodes: Array, kind: String) -> Node:
	if center_peg and str(center_peg.get("peg_extra_kind")) == kind and _peg_extra_effects_active(center_peg):
		return center_peg
	for p in nearest:
		if p and str(p.get("peg_extra_kind")) == kind and _peg_extra_effects_active(p):
			return p
	for p in conduction_nodes:
		if p and str(p.get("peg_extra_kind")) == kind and _peg_extra_effects_active(p):
			return p
	return null

## Single hook for “chain lightning resolved” — each upgrade implements its own effect (may still require a magnet/trampoline/wrench in the arc).
func _apply_chain_lightning_cross_link_effects(center_peg: Node, nearest: Array, conduction_hit_nodes: Array) -> void:
	if not GameState:
		return
	if GameState.has_wall_break_upgrade(&"chain_surge_wrench"):
		if _chain_lightning_touches_peg_kind(center_peg, nearest, conduction_hit_nodes, "wrench"):
			var surge_n: int = 10
			if GameState.has_boss_upgrade(&"echoes_of_wrench"):
				surge_n += 5
			_repair_random_damaged_pegs(surge_n)
	if GameState.has_wall_break_upgrade(&"magnet_arc_snare"):
		var mag_peg: Node = _first_peg_kind_in_chain(center_peg, nearest, conduction_hit_nodes, "magnet")
		if mag_peg:
			var pull: float = 140.0
			if GameState.has_boss_upgrade(&"stormgrid_coupling"):
				pull *= 1.6
			_pull_active_balls_toward(mag_peg.global_position, pull)
			if GameState.has_boss_upgrade(&"stormgrid_coupling"):
				_damp_active_balls_spin(0.88)
	if GameState.has_wall_break_upgrade(&"spark_trampoline"):
		var tramp_peg: Node = _first_peg_kind_in_chain(center_peg, nearest, conduction_hit_nodes, "trampoline")
		if tramp_peg:
			_boost_balls_near_trampoline_spark(tramp_peg.global_position)

func _pull_active_balls_toward(target: Vector2, impulse: float) -> void:
	for b in _active_balls:
		if not b or not b.get("linear_velocity"):
			continue
		var d: Vector2 = target - b.global_position
		if d.length() < 1.0:
			continue
		b.linear_velocity += d.normalized() * impulse

func _damp_active_balls_spin(angular_factor: float) -> void:
	for b in _active_balls:
		if b and b.get("angular_velocity") != null:
			b.angular_velocity *= angular_factor

func _boost_balls_near_trampoline_spark(center: Vector2) -> void:
	for b in _active_balls:
		if not b or not b.get("linear_velocity"):
			continue
		if center.distance_to(b.global_position) < 220.0:
			b.linear_velocity.y -= 95.0

func _emit_ball_reset_to_top(ball: Node, reason: StringName) -> void:
	if not ball or not is_instance_valid(ball):
		return
	ball_reset_to_top.emit(ball, reason)
	_apply_ball_reset_to_top_upgrade_effects(ball, reason)

func _apply_ball_reset_to_top_upgrade_effects(_ball: Node, _reason: StringName) -> void:
	_trigger_goblin_hopper_pulse_if_upgraded()

func _trigger_goblin_hopper_pulse_if_upgraded() -> void:
	if not GameState:
		return
	var mult: float = 1.0
	var hold: float = 0.0
	if GameState.has_boss_upgrade(&"goblin_width_tempest"):
		mult = 1.45
		hold = 10.0
	elif GameState.has_wall_break_upgrade(&"goblin_width_pulse"):
		mult = 1.25
		hold = 6.0
	else:
		return
	var main: Node = get_parent()
	var hopper: Node = main.get_node_or_null("Hopper") if main else null
	if hopper and hopper.has_method("pulse_width_temporarily"):
		hopper.pulse_width_temporarily(mult, hold)

## Leech periodic drain: peg extras that only need the peg (not a ball). Skips goblin_reset, bomb, splitter, trampoline, etc.
func _apply_peg_extra_on_leech_tick(peg_id: int, peg: Node) -> void:
	if not peg or not is_instance_valid(peg) or not (peg is Node2D):
		return
	var kind_v: Variant = peg.get("peg_extra_kind")
	var kind: String = str(kind_v) if kind_v != null else ""
	match kind:
		"wrench":
			_apply_wrench_repair(peg_id, peg)
		_:
			pass

## Goblin Reset ball grab: freeze ball, create goblin hand, tween both to the top, then release.
func _apply_goblin_reset_ball(ball: Node) -> void:
	if not ball or not is_instance_valid(ball):
		return
	var gbid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	if _goblin_grab_in_progress.get(gbid, false):
		return
	_goblin_grab_in_progress[gbid] = true
	_active_balls.erase(ball)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "angular_velocity" in ball:
		ball.angular_velocity = 0.0
	if "freeze" in ball:
		ball.freeze = true
	var hand: Node2D = Node2D.new()
	if _goblin_grab_scene:
		hand.set_script(_goblin_grab_scene)
	hand.global_position = ball.global_position
	get_parent().add_child(hand)
	var exit_x: float = clampf(ball.global_position.x, 60.0, 900.0)
	var target_pos: Vector2 = Vector2(exit_x, _spawn_position.y)
	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(ball, "global_position", target_pos, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(hand, "global_position", target_pos, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finish_goblin_grab.bind(ball, hand))

func _finish_goblin_grab(ball: Node, hand: Node2D) -> void:
	var gbid: int = ball.get_ball_id() if ball and ball.has_method("get_ball_id") else 0
	_goblin_grab_in_progress.erase(gbid)
	# Avoid immediate re-grab when the ball is released on the hopper line overlapping a goblin_reset peg (short hit cooldown expires long before the tween ends).
	_goblin_reset_grace_until_tick[gbid] = _board_sim_tick + Constants.GOBLIN_RESET_POST_RELEASE_GRACE_TICKS
	if hand and is_instance_valid(hand) and hand.has_method("release_and_fade"):
		hand.release_and_fade()
	elif hand and is_instance_valid(hand):
		hand.queue_free()
	if not ball or not is_instance_valid(ball):
		return
	if "freeze" in ball:
		ball.freeze = false
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "lock_rotation" in ball:
		ball.lock_rotation = true
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	_ball_hit_count_this_visit[bid] = 0
	_splitter_triggered_this_visit[bid] = false
	_active_balls.erase(ball)
	_active_balls.append(ball)
	_emit_ball_reset_to_top(ball, BALL_RESET_REASON_GOBLIN_GRAB)

func _spawn_wrench_repair_effect(world_pos: Vector2) -> void:
	if not _hit_effect_scene:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = world_pos
	effect.z_index = 100
	effect.setup_effect(BallHitEffect.EffectType.TRAMPOLINE)
	effect.modulate = Constants.gameplay_board_popup_gold()
	get_parent().add_child(effect)

## k nearest pegs by distance — O(n·k) worst case, no full sort of the whole field (was O(n log n)).
func _get_nearest_pegs(center_peg_id: int, count: int) -> Array:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position") or count <= 0:
		return []
	var center_pos: Vector2 = center_peg.global_position
	var buf: Array = []
	for pid in _peg_by_id:
		if pid == center_peg_id:
			continue
		var p: Node = _peg_by_id[pid]
		if not p or not p.get("global_position"):
			continue
		var d: float = center_pos.distance_to(p.global_position)
		if buf.size() < count:
			buf.append({ "dist": d, "peg": p })
			continue
		var worst_i: int = 0
		var worst_d: float = buf[0].dist
		for bi in range(1, buf.size()):
			if buf[bi].dist > worst_d:
				worst_d = buf[bi].dist
				worst_i = bi
		if d < worst_d:
			buf[worst_i] = { "dist": d, "peg": p }
	buf.sort_custom(func(a, b): return a.dist < b.dist)
	var out: Array = []
	for item in buf:
		out.append(item.peg)
	return out

## Pegs within ADJACENT_PEG_RADIUS_PX, closest first (for Spreading Rot — avoids sorting the entire board).
func _get_adjacent_pegs_within_radius(center_peg_id: int, max_count: int) -> Array:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position") or max_count <= 0:
		return []
	var center_pos: Vector2 = center_peg.global_position
	var candidates: Array = []
	for pid in _peg_by_id:
		if pid == center_peg_id:
			continue
		var p: Node = _peg_by_id[pid]
		if not p or not p.get("global_position"):
			continue
		var d: float = center_pos.distance_to(p.global_position)
		if d <= Constants.ADJACENT_PEG_RADIUS_PX:
			candidates.append({ "dist": d, "peg": p })
	candidates.sort_custom(func(a, b): return a.dist < b.dist)
	var out: Array = []
	for i in range(mini(max_count, candidates.size())):
		out.append(candidates[i].peg)
	return out

## Spawn a real second ball when Split triggers; add to BallsContainer and return it. Caller adds to _active_balls.
func _spawn_split_ball(global_pos: Vector2, velocity: Vector2, definition: BallDefinition, energy_half: int) -> Node:
	if not _ball_scene or not _balls_container:
		return null
	var new_ball: Node = _ball_scene.instantiate()
	if not new_ball:
		return null
	_next_split_ball_id += 1
	new_ball.set_ball_id(_next_split_ball_id)
	var def_copy: BallDefinition = definition.duplicate(true) as BallDefinition
	if def_copy:
		new_ball.set_definition(def_copy)
	new_ball.mark_split_triggered()
	if new_ball.has_method("mark_as_split_twin"):
		new_ball.mark_as_split_twin()
	_balls_container.add_child(new_ball)
	new_ball.set_total_energy_display(energy_half)
	new_ball.global_position = global_pos
	new_ball.linear_velocity = velocity
	return new_ball

## Squared distance from point `p` to segment a–b (for Constellation laser vs peg circles).
func _segment_point_distance_squared(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 < 0.0001:
		return p.distance_squared_to(a)
	var t: float = clampf(((p - a).dot(ab)) / l2, 0.0, 1.0)
	var proj: Vector2 = a + ab * t
	return proj.distance_squared_to(p)

func _process_binary_ball_on_ball_splits(sim_tick: int) -> void:
	for attacker in _active_balls.duplicate():
		if not is_instance_valid(attacker):
			continue
		var adef: Resource = attacker.get_definition() if attacker.has_method("get_definition") else null
		if not adef is BallDefinition or _ability_key(adef as BallDefinition) != "Binary":
			continue
		if not attacker.has_method("get_colliding_bodies"):
			continue
		for body in attacker.get_colliding_bodies():
			if body == attacker or not (body is RigidBody2D):
				continue
			if not body.has_method("get_ball_id") or not body.has_method("get_definition"):
				continue
			_try_binary_split_victim_from_collision(attacker, body as Node, sim_tick)

func _try_binary_split_victim_from_collision(attacker: Node, victim: Node, sim_tick: int) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(victim):
		return
	if attacker.has_method("is_split_twin") and attacker.is_split_twin():
		return
	if victim.has_method("is_split_twin") and victim.is_split_twin():
		return
	var aid: int = attacker.get_ball_id() if attacker.has_method("get_ball_id") else 0
	var vid: int = victim.get_ball_id() if victim.has_method("get_ball_id") else 0
	var pair_key: Vector2i = Vector2i(mini(aid, vid), maxi(aid, vid))
	var last_t: int = int(_binary_ball_pair_last_split_tick.get(pair_key, -999999999))
	if sim_tick - last_t < Constants.BINARY_BALL_PAIR_COOLDOWN_SIM_TICKS:
		return
	var vdef: Resource = victim.get_definition() if victim.has_method("get_definition") else null
	if not vdef is BallDefinition:
		return
	var vbdef: BallDefinition = vdef as BallDefinition
	var split_vel: Vector2 = victim.linear_velocity if "linear_velocity" in victim else Vector2.ZERO
	var split_total: int = victim.get_total_energy() if victim.has_method("get_total_energy") else Constants.legacy_display_energy_to_current(20)
	var half_e: int = maxi(1, split_total / 2)
	victim.set_total_energy_display(half_e)
	var frag: Node = _spawn_split_ball(victim.global_position, split_vel.rotated(Constants.SPLITTER_PEG_SPLIT_ANGLE), vbdef, half_e)
	if frag != null:
		_active_balls.append(frag)
		_ball_hit_count_this_visit[frag.get_ball_id()] = 0
		_splitter_triggered_this_visit[frag.get_ball_id()] = true
	_binary_ball_pair_last_split_tick[pair_key] = sim_tick

func _pick_random_catalog_ball_definition_duplicate() -> BallDefinition:
	var main_n: Node = get_parent()
	if main_n:
		var rh: Node = main_n.get_node_or_null("RewardHandler")
		if rh and rh.has_method("get_catalog_ball_definitions"):
			var defs: Array = rh.get_catalog_ball_definitions()
			var pool: Array = []
			var city_id: int = GameState.current_city_id if GameState else 0
			var max_r: int = Constants.RARITY_UNCOMMON
			if city_id >= 0 and city_id < Constants.MAX_RARITY_BY_CITY.size():
				max_r = Constants.MAX_RARITY_BY_CITY[city_id]
			for d in defs:
				if d is BallDefinition and (d as BallDefinition).rarity <= max_r:
					pool.append(d)
			if pool.is_empty():
				for d2 in defs:
					if d2 is BallDefinition:
						pool.append(d2)
			if pool.size() > 0:
				var pick: BallDefinition = pool[randi() % pool.size()] as BallDefinition
				return pick.duplicate(true) as BallDefinition
	var fallback_abilities: Array[String] = ["Split", "Energize", "Leech", "Rubbery", "Phantom", "Volatile", "Constellation", "Binary", "Bloom"]
	return TestScenario.make_ball_definition(fallback_abilities[randi() % fallback_abilities.size()])

## `world_pos` is the Bloom ball's center.
func _spawn_random_ball_from_bloom_at(world_pos: Vector2, _source_ball: Node, _sim_tick: int) -> void:
	if get_active_ball_count() >= Constants.MAX_ACTIVE_BALLS:
		return
	if not _ball_scene or not _balls_container:
		return
	var def: BallDefinition = _pick_random_catalog_ball_definition_duplicate()
	if def == null:
		return
	_next_split_ball_id += 1
	var new_ball: Node = _ball_scene.instantiate()
	if new_ball.has_method("set_ball_id"):
		new_ball.set_ball_id(_next_split_ball_id)
	if new_ball.has_method("set_definition"):
		new_ball.set_definition(def)
	var ab_name: String = str(def.ability_name).strip_edges()
	GameState.record_ball_ability_in_run(ab_name if not ab_name.is_empty() else "Plain")
	_balls_container.add_child(new_ball)
	if "freeze" in new_ball:
		new_ball.freeze = false
	new_ball.global_position = world_pos
	if "linear_velocity" in new_ball:
		new_ball.linear_velocity = Vector2(randf_range(-55.0, 55.0), randf_range(60.0, 140.0))
	if new_ball.has_method("mark_as_bloom_spawn"):
		new_ball.mark_as_bloom_spawn()
	_active_balls.append(new_ball)
	_ball_hit_count_this_visit[new_ball.get_ball_id() if new_ball.has_method("get_ball_id") else 0] = 0

## Constellation: straight segment vs peg circles only. Ball–ball split is Binary; every-5-peg random spawn is Bloom.
func _apply_constellation_laser_hits(sim_tick: int) -> void:
	var constellation_balls: Array = []
	for b in _active_balls:
		if not is_instance_valid(b):
			continue
		var bd: Resource = b.get_definition() if b.has_method("get_definition") else null
		if bd is BallDefinition and _ability_key(bd as BallDefinition) == "Constellation":
			constellation_balls.append(b)
	if constellation_balls.size() < 2:
		return
	for i in range(constellation_balls.size()):
		for j in range(i + 1, constellation_balls.size()):
			var ba: Node = constellation_balls[i]
			var bb: Node = constellation_balls[j]
			if not is_instance_valid(ba) or not is_instance_valid(bb):
				continue
			var pa: Vector2 = ba.global_position
			var pb: Vector2 = bb.global_position
			_apply_constellation_laser_segment_hits(ba, bb, pa, pb, sim_tick)

func _apply_constellation_laser_segment_hits(ba: Node, bb: Node, pos_a: Vector2, pos_b: Vector2, sim_tick: int) -> void:
	var bid_a: int = ba.get_ball_id() if ba.has_method("get_ball_id") else 0
	var bid_b: int = bb.get_ball_id() if bb.has_method("get_ball_id") else 0
	var k1: int = mini(bid_a, bid_b)
	var k2: int = maxi(bid_a, bid_b)
	var hit_radius: float = Constants.PEG_RADIUS + Constants.BALL_RADIUS * 0.45
	var hit_r2: float = hit_radius * hit_radius
	var bdef_a: BallDefinition = ba.get_definition() as BallDefinition if ba.has_method("get_definition") else null
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		if not peg or not peg.get("global_position"):
			continue
		if not _peg_extra_effects_active(peg):
			continue
		var pc: Vector2 = peg.global_position
		if _segment_point_distance_squared(pos_a, pos_b, pc) > hit_r2:
			continue
		var ck: String = "%d|%d|%d" % [k1, k2, pid]
		var last_l: int = int(_constellation_laser_peg_last_tick.get(ck, -999999999))
		if sim_tick - last_l < Constants.CONSTELLATION_LASER_PEG_RETRIGGER_SIM_TICKS:
			continue
		_constellation_laser_peg_last_tick[ck] = sim_tick
		var e_half: int = PEG_DISPLAY_ENERGY_PER_HIT / 2
		var e_rem: int = PEG_DISPLAY_ENERGY_PER_HIT - e_half * 2
		if ba.has_method("add_peg_energy"):
			ba.add_peg_energy(e_half + e_rem)
		if bb.has_method("add_peg_energy"):
			bb.add_peg_energy(e_half)
		var ek_p: String = str(peg.get("peg_extra_kind")) if peg.get("peg_extra_kind") != null else ""
		if peg.has_method("apply_hit"):
			var has_attr: bool = bdef_a != null and (not bdef_a.status_effects.is_empty() or not _ability_key(bdef_a).is_empty())
			peg.apply_hit(not has_attr, 1, false)
		_spawn_energy_popup(peg, PEG_DISPLAY_ENERGY_PER_HIT)

## Phantom balls don't collide with pegs; use distance overlap to grant energy. Returns one peg within range or null.
func _get_peg_overlapping_phantom_ball(ball: Node) -> Node:
	var pos: Vector2 = ball.global_position if ball.get("global_position") != null else ball.position
	var limit: float = Constants.BALL_RADIUS + Constants.PEG_RADIUS
	var best: Node = null
	var best_dist: float = limit + 1.0
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if not p.get("global_position"):
			continue
		if not _peg_eligible_for_phantom_overlap(p):
			continue
		var d: float = pos.distance_to(p.global_position)
		if d <= limit and d < best_dist:
			best_dist = d
			best = p
	return best

## True when peg is not in recovery (broken / cooldown). Field effects and chain synergy peg-kinds use this.
func _peg_extra_effects_active(peg: Node) -> bool:
	if not peg:
		return false
	var rem: Variant = peg.get("_recovery_ticks_remaining")
	return rem == null or int(rem) <= 0

func _peg_eligible_for_phantom_overlap(p: Node) -> bool:
	if p.get("_recovery_ticks_remaining") != null and p._recovery_ticks_remaining > 0:
		return false
	if p.get("peg_extra_kind") == "phase" and p.has_method("is_phase_solid") and not p.is_phase_solid():
		return false
	return true

## Leech status: every second, each leeched peg drains LEECH_DRAIN_PER_SECOND energy (routed by alignment); 10 sec then expire.
func _process_leech_drains(sim_tick: int) -> void:
	if sim_tick <= 0 or (sim_tick % Constants.SIM_TICKS_PER_SECOND) != 0:
		return
	var to_remove: Array[int] = []
	var pending_rot_leeches: Array = []
	var leech_visual_budget: int = LEECH_VISUAL_BUDGET_PER_TICK
	for i in _leeched_pegs.size():
		var entry: Dictionary = _leeched_pegs[i]
		if entry.get("drains_remaining", 0) <= 0:
			to_remove.append(i)
			continue
		var pid: int = entry.get("peg_id", -1)
		var align: int = entry.get("alignment", Constants.ALIGNMENT_MAIN)
		var peg: Node = _peg_by_id.get(pid)
		var drain_amount: int = GameState.get_leech_drain_per_second_display() if GameState else Constants.LEECH_DRAIN_PER_SECOND
		# Blood Tithe (boss): leech ticks pay more display energy
		if GameState and GameState.has_boss_upgrade(&"blood_tithe"):
			drain_amount += Constants.legacy_display_energy_to_current(1)
		# Overcharged Drain: leech on energized peg generates double energy
		if GameState and GameState.has_wall_break_upgrade(&"overcharged_drain") and peg:
			if peg.has_method("has_energized_stacks") and peg.has_energized_stacks():
				drain_amount *= 2
		if peg:
			if leech_visual_budget > 0:
				_spawn_leech_popup(peg, drain_amount)
				if peg.has_method("play_leech_pulse"):
					peg.play_leech_pulse(drain_amount)
				leech_visual_budget -= 1
			_apply_peg_extra_on_leech_tick(pid, peg)
		leech_drain.emit(drain_amount, align, pid)
		# Leech Singularity (boss): peg with 3+ leech stacks AND energized implodes
		if GameState and GameState.has_boss_upgrade(&"leech_singularity") and peg:
			var leech_stack_count: int = peg.get_leech_stack_count() if peg.has_method("get_leech_stack_count") else 0
			if leech_stack_count >= 3 and peg.has_method("has_energized_stacks") and peg.has_energized_stacks():
				var nearest_pegs: Array = _get_nearest_pegs(pid, 4)
				for np in nearest_pegs:
					var np_id: int = np.peg_id if np.get("peg_id") != null else -1
					if np_id >= 0 and np.has_method("apply_hit"):
						np.apply_hit(true, 3, false)
					leech_drain.emit(drain_amount * 3, align, np_id)
				if peg.has_method("apply_hit"):
					peg.apply_hit(true, 10, false)
		entry["drains_remaining"] = entry["drains_remaining"] - 1
		if entry["drains_remaining"] <= 0:
			# Spreading Rot: expired leech spreads mini-leech to adjacent pegs
			if GameState and GameState.has_wall_break_upgrade(&"spreading_rot") and peg:
				var adj_pegs: Array = _get_adjacent_pegs_within_radius(pid, 3)
				for adj in adj_pegs:
					var adj_id: int = adj.peg_id if adj.get("peg_id") != null else -1
					if adj_id >= 0:
						var _ldur_rot: int = maxi(1, (GameState.get_leech_duration_sec() if GameState else Constants.LEECH_DURATION_SEC) / 3)
						pending_rot_leeches.append({ "peg_id": adj_id, "alignment": align, "drains_remaining": _ldur_rot })
						if adj.has_method("add_leech_stack"):
							adj.add_leech_stack()
			if peg and peg.has_method("remove_leech_stack"):
				peg.remove_leech_stack()
			to_remove.append(i)
	to_remove.sort()
	for i in range(to_remove.size() - 1, -1, -1):
		_leeched_pegs.remove_at(to_remove[i])
	if not pending_rot_leeches.is_empty():
		_leeched_pegs.append_array(pending_rot_leeches)

func _count_plain_balls_for_horde_bonus() -> int:
	if _game_coordinator and _game_coordinator.has_method("count_plain_balls_in_play"):
		return _game_coordinator.count_plain_balls_in_play()
	return 0

func _ability_key(bdef: BallDefinition) -> String:
	if bdef == null:
		return ""
	return str(bdef.ability_name).strip_edges()

func _spawn_hit_effect(world_pos: Vector2, status_effects: Dictionary, ability_name: String = "", allow_split_effect: bool = true) -> void:
	if not _hit_effect_scene:
		return
	var key: String = str(ability_name).strip_edges()
	var effect_type: int = BallHitEffect.EffectType.FIRE
	if key == "Energize":
		effect_type = BallHitEffect.EffectType.ENERGIZE
	elif key == "Split" and allow_split_effect:
		effect_type = BallHitEffect.EffectType.SPLIT
	elif key == "Split":
		return
	elif key == "Explosive":
		effect_type = BallHitEffect.EffectType.EXPLOSIVE
	elif key == "Chain Lightning":
		effect_type = BallHitEffect.EffectType.CHAIN_LIGHTNING
	elif key == "Leech":
		effect_type = BallHitEffect.EffectType.LEECH
	elif key == "Rubbery":
		effect_type = BallHitEffect.EffectType.RUBBERY
	elif key == "Phantom":
		effect_type = BallHitEffect.EffectType.PHANTOM
	elif key == "Volatile":
		effect_type = BallHitEffect.EffectType.VOLATILE
	elif key == "Constellation":
		effect_type = BallHitEffect.EffectType.CONSTELLATION
	elif key == "Binary":
		effect_type = BallHitEffect.EffectType.BINARY
	elif key == "Bloom":
		effect_type = BallHitEffect.EffectType.BLOOM
	elif status_effects.get(Constants.STATUS_FROZEN, 0) > 0 or status_effects.get("frozen", 0) > 0:
		effect_type = BallHitEffect.EffectType.ICE
	elif status_effects.get(Constants.STATUS_LIGHTNING, 0) > 0 or status_effects.get("lightning", 0) > 0:
		effect_type = BallHitEffect.EffectType.LIGHTNING
	elif status_effects.get(Constants.STATUS_FIRE, 0) > 0 or status_effects.get("fire", 0) > 0:
		effect_type = BallHitEffect.EffectType.FIRE
	else:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = world_pos
	effect.z_index = 100
	effect.setup_effect(effect_type)
	get_parent().add_child(effect)

func _spawn_treasure_chest_break_effect(world_pos: Vector2) -> void:
	if not _treasure_chest_break_scene:
		return
	var effect: Node2D = _treasure_chest_break_scene.instantiate() as Node2D
	if not effect:
		return
	effect.global_position = world_pos
	get_parent().add_child(effect)

func _spawn_explosive_effect_at_ball(ball_world_pos: Vector2, explosive_radius_px: float = -1.0) -> void:
	if not _hit_effect_scene:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = ball_world_pos
	effect.z_index = 100
	var r: float = explosive_radius_px if explosive_radius_px > 0.0 else Constants.EXPLOSIVE_RADIUS_PX
	effect.setup_effect(BallHitEffect.EffectType.EXPLOSIVE, r)
	get_parent().add_child(effect)

func _spawn_chain_lightning_arcs(global_positions: Array) -> void:
	if not _chain_lightning_arc_scene or global_positions.size() < 2:
		return
	var effect: Node2D = _chain_lightning_arc_scene.instantiate() as Node2D
	if not effect or not effect.has_method("setup_chain"):
		return
	effect.global_position = Vector2.ZERO
	effect.setup_chain(global_positions)
	get_parent().add_child(effect)

func _warm_energy_popup_pool() -> void:
	if not _energy_popup_scene:
		return
	var release_cb := Callable(self, "_release_energy_popup_to_pool")
	for i in ENERGY_POPUP_POOL_PREALLOC:
		var p: Node2D = _energy_popup_scene.instantiate() as Node2D
		if not p:
			continue
		if p.has_method("set_pool_release"):
			p.set_pool_release(release_cb)
		add_child(p)
		p.visible = false
		p.set_process(false)
		p.modulate = Color.WHITE
		_energy_popup_pool_idle.append(p)

func _acquire_energy_popup() -> Node2D:
	if not _energy_popup_scene:
		return null
	var popup: Node2D
	var release_cb := Callable(self, "_release_energy_popup_to_pool")
	if _energy_popup_pool_idle.is_empty():
		popup = _energy_popup_scene.instantiate() as Node2D
		if not popup:
			return null
		if popup.has_method("set_pool_release"):
			popup.set_pool_release(release_cb)
		add_child(popup)
	else:
		popup = _energy_popup_pool_idle.pop_back()
	popup.visible = true
	popup.set_process(true)
	return popup

func _release_energy_popup_to_pool(popup: Node) -> void:
	if not is_instance_valid(popup) or not (popup is Node2D):
		return
	var p2: Node2D = popup as Node2D
	p2.set_process(false)
	p2.visible = false
	p2.position = Vector2.ZERO
	p2.modulate = Color.WHITE
	if _energy_popup_pool_idle.size() >= ENERGY_POPUP_POOL_MAX_IDLE:
		p2.queue_free()
		return
	_energy_popup_pool_idle.append(p2)

func _spawn_energy_popup(peg: Node, amount_display: int) -> void:
	var popup: Node2D = _acquire_energy_popup()
	if not popup:
		return
	popup.setup("+%d" % amount_display)
	popup.position = peg.position + Vector2(0, -16)
	popup.modulate = Color.WHITE

func _spawn_energy_popup_at_pos(pos: Vector2, amount_display: int) -> void:
	var popup: Node2D = _acquire_energy_popup()
	if not popup:
		return
	popup.setup("+%d" % amount_display)
	popup.position = pos + Vector2(0, -16)
	popup.modulate = Color.WHITE

func _spawn_trampoline_bounce_effect(world_pos: Vector2) -> void:
	if not _hit_effect_scene:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = world_pos
	effect.z_index = 100
	effect.setup_effect(BallHitEffect.EffectType.TRAMPOLINE)
	get_parent().add_child(effect)

func _spawn_leech_popup(peg: Node, amount_display: int) -> void:
	var popup: Node2D = _acquire_energy_popup()
	if not popup:
		return
	popup.setup("+%d" % amount_display)
	popup.position = peg.position + Vector2(0, -16)
	popup.modulate = Constants.gameplay_board_energy_popup()

func begin_black_hole_event(board_local_center: Vector2, duration_sec: float) -> void:
	_black_hole_active = true
	_black_hole_center_global = to_global(board_local_center)
	_black_hole_deadline_ms = Time.get_ticks_msec() + int(duration_sec * 1000.0)
	if _black_hole_visual and is_instance_valid(_black_hole_visual):
		_black_hole_visual.queue_free()
	_black_hole_visual = null
	var scr: GDScript = load("res://scenes/board/black_hole_visual.gd") as GDScript
	var vis: Node2D = Node2D.new()
	if scr:
		vis.set_script(scr)
	add_child(vis)
	vis.position = board_local_center
	vis.z_index = 42
	_black_hole_visual = vis

func _tick_black_hole_event(sim_tick: int) -> void:
	if not _black_hole_active:
		return
	if Time.get_ticks_msec() >= _black_hole_deadline_ms:
		_end_black_hole_event()
		return
	_apply_black_hole_pull_and_consume(sim_tick)

func _end_black_hole_event() -> void:
	_black_hole_active = false
	if _black_hole_visual and is_instance_valid(_black_hole_visual):
		_black_hole_visual.queue_free()
	_black_hole_visual = null
	var bhc: Node = get_node_or_null("BlackHoleController")
	if bhc and bhc.has_method("on_black_hole_event_ended"):
		bhc.on_black_hole_event_ended()

func _detach_ball_from_sticky_slime_if_stuck(ball: Node) -> void:
	if not ball or not ball.has_method("get_ball_id"):
		return
	var bid: int = ball.get_ball_id()
	if not _ball_stuck_on_sticky_peg.has(bid):
		return
	var pid: int = int(_ball_stuck_on_sticky_peg[bid])
	_ball_stuck_on_sticky_peg.erase(bid)
	var arr: Array = _sticky_slime_stuck_balls.get(pid, [])
	var idx: int = arr.find(ball)
	if idx >= 0:
		arr.remove_at(idx)
	if arr.is_empty():
		_sticky_slime_stuck_balls.erase(pid)
	else:
		_sticky_slime_stuck_balls[pid] = arr
	if "freeze" in ball:
		ball.freeze = false

func _apply_black_hole_pull_and_consume(sim_tick: int) -> void:
	var center: Vector2 = _black_hole_center_global
	var pull_r: float = Constants.BLACK_HOLE_PULL_RADIUS_PX
	var consume_r: float = Constants.BLACK_HOLE_CONSUME_RADIUS_PX
	var to_consume: Array[Node] = []
	for ball in _active_balls:
		if not is_instance_valid(ball):
			continue
		var pos: Vector2 = ball.global_position
		var dist: float = pos.distance_to(center)
		if dist <= consume_r:
			to_consume.append(ball)
			continue
		if dist >= pull_r or dist < 0.001:
			continue
		if not "linear_velocity" in ball:
			continue
		var dir: Vector2 = (center - pos).normalized()
		var span: float = maxf(pull_r - consume_r, 1.0)
		var t: float = clampf((dist - consume_r) / span, 0.0, 1.0)
		var falloff: float = lerpf(1.0, 0.32, t)
		ball.linear_velocity += dir * (Constants.BLACK_HOLE_PULL_STRENGTH * falloff)
	for b in to_consume:
		if b in _active_balls and is_instance_valid(b):
			_release_black_hole_ball(b, sim_tick)

func _release_black_hole_ball(ball: Node, _sim_tick: int) -> void:
	_detach_ball_from_sticky_slime_if_stuck(ball)
	var bi: int = _buffet_affected_balls.find(ball)
	if bi >= 0:
		_buffet_affected_balls.remove_at(bi)
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	_goblin_grab_in_progress.erase(bid)
	_active_balls.erase(ball)
	_ball_hit_count_this_visit.erase(bid)
	_phantom_pegs_visited.erase(bid)
	_ball_energized_pegs_hit.erase(bid)
	_splitter_triggered_this_visit.erase(bid)
	ball_exited_board.emit(ball, REASON_BLACK_HOLE)

## Magnet pegs pull nearby balls; Gravity Well pegs slow nearby balls. Applied each sim tick.
func _apply_magnet_and_gravity_well_forces() -> void:
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		var kind: String = peg.get("peg_extra_kind") if peg.get("peg_extra_kind") != null else ""
		if kind != "magnet" and kind != "gravity_well":
			continue
		if not _peg_extra_effects_active(peg):
			continue
		var peg_pos: Vector2 = peg.global_position
		for ball in _active_balls:
			if not "linear_velocity" in ball or not "global_position" in ball:
				continue
			var dist: float = peg_pos.distance_to(ball.global_position)
			if kind == "magnet" and dist < Constants.MAGNET_PEG_RADIUS_PX and dist > 5.0:
				var dir: Vector2 = (peg_pos - ball.global_position).normalized()
				# Stronger pull mid-field, ~40% at outer radius so the whole disc feels active.
				var span: float = maxf(Constants.MAGNET_PEG_RADIUS_PX - 5.0, 1.0)
				var t: float = clampf((dist - 5.0) / span, 0.0, 1.0)
				var falloff: float = lerpf(1.0, 0.4, t)
				var pull_str: float = Constants.MAGNET_PEG_PULL_STRENGTH
				if GameState and GameState.has_boss_upgrade(&"iron_bloom"):
					pull_str *= 1.35
				ball.linear_velocity += dir * (pull_str * falloff)
			elif kind == "gravity_well" and dist < Constants.GRAVITY_WELL_RADIUS_PX:
				ball.linear_velocity *= Constants.GRAVITY_WELL_DRAG

func _spawn_peg_layout() -> void:
	if not _peg_scene:
		return
	var peg_id_counter: int = 0
	for row in range(BOARD_GRID_ROWS):
		for col in range(BOARD_GRID_COLS):
			if (row + col) % 2 != 0:
				continue
			var grid_cell := Vector2i(col, row)
			var pos: Vector2 = board_cell_to_world(grid_cell)
			var p: Node = _peg_scene.instantiate()
			p.position = pos
			p.peg_id = peg_id_counter
			p.set_meta("grid_cell", grid_cell)
			_peg_by_id[peg_id_counter] = p
			peg_id_counter += 1
			add_child(p)
	_layout_empty_slots.clear()
	_next_dynamic_peg_id = peg_id_counter + 100000
	var _ts_all_bombs: bool = TestScenario and TestScenario.enabled and TestScenario.all_pegs_bombs
	var _ts_all_tramps: bool = TestScenario and TestScenario.enabled and TestScenario.all_pegs_trampolines
	if _ts_all_bombs:
		for pid in _peg_by_id:
			var p: Node = _peg_by_id[pid]
			p.peg_extra_kind = "bomb"
			_tag_peg_as_explosion_source(p)
		_extra_pegs_spawned_count = _peg_by_id.size()
	elif _ts_all_tramps:
		for pid in _peg_by_id:
			var p: Node = _peg_by_id[pid]
			p.peg_extra_kind = "trampoline"
			if p.has_method("apply_trampoline_physics"):
				p.apply_trampoline_physics()
		_extra_pegs_spawned_count = _peg_by_id.size()
	else:
		var bomb_count: int = GameState.bomb_peg_count if GameState else 0
		var trampoline_count: int = GameState.trampoline_peg_count if GameState else 0
		var goblin_count: int = GameState.goblin_reset_node_count if GameState else 0
		var eternal_count: int = GameState.eternal_peg_count if GameState else 0
		var extreme_count: int = GameState.extreme_bouncer_peg_count if GameState else 0
		var magnet_count: int = GameState.magnet_peg_count if GameState else 0
		var splitter_count: int = GameState.splitter_peg_count if GameState else 0
		var gold_count: int = GameState.gold_peg_count if GameState else 0
		var lucky_gold_count: int = GameState.lucky_gold_peg_count if GameState else 0
		var grav_count: int = GameState.gravity_well_peg_count if GameState else 0
		var phase_count: int = GameState.phase_peg_count if GameState else 0
		var wrench_count: int = GameState.wrench_peg_count if GameState else 0
		var peg_ids: Array = []
		for pid in _peg_by_id:
			peg_ids.append(pid)
		peg_ids.shuffle()
		var idx: int = 0
		for i in range(bomb_count):
			if idx < peg_ids.size():
				var p: Node = _peg_by_id[peg_ids[idx]]
				p.peg_extra_kind = "bomb"
				_tag_peg_as_explosion_source(p)
				idx += 1
		for i in range(trampoline_count):
			if idx < peg_ids.size():
				var tramp_peg: Node = _peg_by_id[peg_ids[idx]]
				tramp_peg.peg_extra_kind = "trampoline"
				if tramp_peg.has_method("apply_trampoline_physics"):
					tramp_peg.apply_trampoline_physics()
				idx += 1
		for i in range(goblin_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "goblin_reset"
				idx += 1
		for i in range(eternal_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "eternal"
				idx += 1
		for i in range(extreme_count):
			if idx < peg_ids.size():
				var ep: Node = _peg_by_id[peg_ids[idx]]
				ep.peg_extra_kind = "extreme_bouncer"
				if ep.has_method("apply_extreme_bouncer_physics"):
					ep.apply_extreme_bouncer_physics()
				idx += 1
		for i in range(magnet_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "magnet"
				idx += 1
		for i in range(splitter_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "splitter"
				idx += 1
		for i in range(gold_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "gold"
				idx += 1
		for i in range(lucky_gold_count):
			if idx < peg_ids.size():
				var lgp: Node = _peg_by_id[peg_ids[idx]]
				lgp.peg_extra_kind = "lucky_gold"
				if lgp.has_method("refresh_stash_gold_for_current_kind"):
					lgp.refresh_stash_gold_for_current_kind()
				idx += 1
		for i in range(grav_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "gravity_well"
				idx += 1
		for i in range(phase_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "phase"
				idx += 1
		for i in range(wrench_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "wrench"
				idx += 1
		_extra_pegs_spawned_count = bomb_count + trampoline_count + goblin_count + eternal_count + extreme_count + magnet_count + splitter_count + gold_count + lucky_gold_count + grav_count + phase_count + wrench_count
	if TestScenario and TestScenario.enabled and TestScenario.all_pegs_start_leeched:
		_apply_test_scenario_leech_all_pegs()
	# peg_extra_kind is assigned after each peg's _ready(); redraw so visuals match (gold, bomb, etc.).
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		if peg and is_instance_valid(peg) and peg.has_method("queue_redraw"):
			peg.queue_redraw()

## TestScenario: leech on every peg at spawn (full-board leech stress test).
func _apply_test_scenario_leech_all_pegs() -> void:
	var align: int = Constants.ALIGNMENT_MAIN
	for pid in _peg_by_id:
		var _ldur_ts: int = GameState.get_leech_duration_sec() if GameState else Constants.LEECH_DURATION_SEC
		_leeched_pegs.append({ "peg_id": pid, "alignment": align, "drains_remaining": _ldur_ts })
		var peg: Node = _peg_by_id[pid]
		if peg.has_method("add_leech_stack"):
			peg.add_leech_stack()

## Find the nearest normal peg (peg_extra_kind == "") to the given position, within max_dist. Returns peg_id or -1.
## Undo one placed special peg of this shop kind (bomb, trampoline, …). Returns false if none found.
func revert_one_shop_peg_of_kind(kind: String) -> bool:
	if kind.is_empty():
		return false
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		var k: String = p.get("peg_extra_kind") if p.get("peg_extra_kind") != null else ""
		if k != kind:
			continue
		if k == "milestone_event" or k == "treasure_chest" or k == "buffet_table" or k == "sticky_slime":
			continue
		if p.has_method("revert_milestone_shop_kind_to_normal"):
			p.revert_milestone_shop_kind_to_normal()
		return true
	return false

func get_nearest_normal_peg_id(pos: Vector2, max_dist: float = 30.0) -> int:
	var best_id: int = -1
	var best_dist: float = max_dist
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if p.peg_extra_kind != "":
			continue
		var dist: float = pos.distance_to(p.global_position)
		if dist < best_dist:
			best_dist = dist
			best_id = pid
	return best_id

## Convert a specific peg to the given kind ("bomb", "trampoline", "goblin_reset"). Used by peg selection overlay.
func convert_specific_peg(peg_id: int, kind: String) -> void:
	var peg: Node = _peg_by_id.get(peg_id)
	if not peg:
		return
	peg.peg_extra_kind = kind
	match kind:
		"bomb":
			_tag_peg_as_explosion_source(peg)
		"trampoline":
			if peg.has_method("apply_trampoline_physics"):
				peg.apply_trampoline_physics()
		"extreme_bouncer":
			if peg.has_method("apply_extreme_bouncer_physics"):
				peg.apply_extreme_bouncer_physics()
		"goblin_reset":
			if peg.has_method("refresh_goblin_reset_durability"):
				peg.refresh_goblin_reset_durability()
		"lucky_gold":
			if peg.has_method("refresh_stash_gold_for_current_kind"):
				peg.refresh_stash_gold_for_current_kind()
	peg.queue_redraw()

## Call after wall break upgrades that add pegs (Add Bomb Peg, Add Trampoline Peg, Add Goblin Reset Node). Converts random normal pegs to the new type.
func add_extra_pegs_if_needed() -> void:
	if not GameState:
		return
	var want: Dictionary = {
		"bomb": GameState.bomb_peg_count,
		"trampoline": GameState.trampoline_peg_count,
		"goblin_reset": GameState.goblin_reset_node_count,
		"eternal": GameState.eternal_peg_count,
		"extreme_bouncer": GameState.extreme_bouncer_peg_count,
		"magnet": GameState.magnet_peg_count,
		"splitter": GameState.splitter_peg_count,
		"gold": GameState.gold_peg_count,
		"lucky_gold": GameState.lucky_gold_peg_count,
		"gravity_well": GameState.gravity_well_peg_count,
		"phase": GameState.phase_peg_count,
		"wrench": GameState.wrench_peg_count,
	}
	var normal_pegs: Array = []
	var current_counts: Dictionary = {}
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		var k: String = p.get("peg_extra_kind") if p.get("peg_extra_kind") != null else ""
		if k == "":
			normal_pegs.append(p)
		else:
			current_counts[k] = current_counts.get(k, 0) + 1
	var need: Dictionary = {}
	var total_convert: int = 0
	for kind in want:
		var n: int = maxi(0, want[kind] - current_counts.get(kind, 0))
		need[kind] = n
		total_convert += n
	if total_convert <= 0 or normal_pegs.size() < total_convert:
		return
	normal_pegs.shuffle()
	var idx: int = 0
	for kind in need:
		for i in range(need[kind]):
			var p: Node = normal_pegs[idx]
			p.peg_extra_kind = kind
			match kind:
				"bomb":
					_tag_peg_as_explosion_source(p)
				"trampoline":
					if p.has_method("apply_trampoline_physics"):
						p.apply_trampoline_physics()
				"extreme_bouncer":
					if p.has_method("apply_extreme_bouncer_physics"):
						p.apply_extreme_bouncer_physics()
				"goblin_reset":
					if p.has_method("refresh_goblin_reset_durability"):
						p.refresh_goblin_reset_durability()
				"lucky_gold":
					if p.has_method("refresh_stash_gold_for_current_kind"):
						p.refresh_stash_gold_for_current_kind()
			p.queue_redraw()
			idx += 1
	var total_special: int = 0
	for k in want:
		total_special += want[k]
	_extra_pegs_spawned_count = total_special

## Overclock Network: grant +1 energized durability per adjacent energized peg.
func _apply_overclock_network_bonus(center_peg_id: int) -> void:
	var center: Node = _peg_by_id.get(center_peg_id)
	if not center or not center.get("global_position"):
		return
	var pos: Vector2 = center.global_position
	var bonus: int = 0
	for other_id in _peg_by_id:
		if other_id == center_peg_id:
			continue
		var other: Node = _peg_by_id[other_id]
		if not other or not other.get("global_position"):
			continue
		if other.has_method("has_energized_stacks") and other.has_energized_stacks():
			if pos.distance_to(other.global_position) <= Constants.ADJACENT_PEG_RADIUS_PX:
				bonus += 1
	if bonus > 0 and center.has_method("add_overclock_durability"):
		center.add_overclock_durability(bonus)

## Check all pegs for destruction upgrades (energy_collapse, perpetual_engine).
func _check_peg_destruction_upgrades(sim_tick: int) -> void:
	var has_energy_collapse: bool = GameState != null and GameState.has_wall_break_upgrade(&"energy_collapse")
	var has_perpetual_engine: bool = GameState != null and GameState.has_boss_upgrade(&"perpetual_engine")
	if not has_energy_collapse and not has_perpetual_engine:
		return
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		var ek_chk: String = str(peg.get("peg_extra_kind")) if peg.get("peg_extra_kind") != null else ""
		if ek_chk == "milestone_event" or ek_chk == "treasure_chest" or ek_chk == "buffet_table" or ek_chk == "sticky_slime":
			continue
		if not peg.has_method("was_just_destroyed") or not peg.was_just_destroyed():
			continue
		if has_energy_collapse:
			var leech_count: int = peg.get_leech_stack_count() if peg.has_method("get_leech_stack_count") else 0
			if leech_count >= 3:
				_trigger_energy_collapse(pid, sim_tick)
		if has_perpetual_engine:
			if peg.has_method("had_energize_on_destroy") and peg.had_energize_on_destroy():
				_spawn_perpetual_engine_phantom(peg.global_position)

## Energy Collapse: peg with 3+ leech stacks destroyed triggers explosion at its location.
func _trigger_energy_collapse(peg_id: int, sim_tick: int) -> void:
	if _explosion_triggered_pegs_this_tick.get(peg_id, false):
		return
	_explosion_triggered_pegs_this_tick[peg_id] = true
	var peg: Node = _peg_by_id.get(peg_id)
	if not peg or not peg.get("global_position"):
		return
	var center_pos: Vector2 = peg.global_position
	var radius_px: float = Constants.EXPLOSIVE_RADIUS_PX
	if GameState:
		radius_px += float(GameState.explosion_radius_bonus) * 12.0
	for other_id in _peg_by_id:
		if other_id == peg_id:
			continue
		var other: Node = _peg_by_id[other_id]
		if not other or not other.get("global_position"):
			continue
		if center_pos.distance_to(other.global_position) > radius_px:
			continue
		if other.has_method("apply_hit"):
			other.apply_hit(true, 1, false)
		if other.has_method("play_wobble"):
			other.play_wobble()
		_spawn_energy_popup(other, PEG_DISPLAY_ENERGY_PER_HIT)
	_spawn_explosive_effect_at_ball(center_pos)

## Perpetual Engine (boss): energized peg destroyed spawns a temporary Phantom ball.
func _spawn_perpetual_engine_phantom(spawn_pos: Vector2) -> void:
	if not _ball_scene or not _balls_container:
		return
	var phantom_def: BallDefinition = BallDefinition.new()
	phantom_def.ability_name = "Phantom"
	phantom_def.alignment = Constants.ALIGNMENT_MAIN
	phantom_def.base_energy = Constants.legacy_display_energy_to_current(20)
	phantom_def.tier = 1
	phantom_def.rarity = Constants.RARITY_UNCOMMON
	phantom_def.city_weights = {}
	phantom_def.status_effects = {}
	phantom_def.shape_type = BallVisuals.ShapeType.HEXAGON
	var new_ball: Node = _ball_scene.instantiate()
	if not new_ball:
		return
	_next_split_ball_id += 1
	new_ball.set_ball_id(_next_split_ball_id)
	new_ball.set_definition(phantom_def)
	if new_ball.has_method("mark_as_split_twin"):
		new_ball.mark_as_split_twin()
	_balls_container.add_child(new_ball)
	new_ball.global_position = spawn_pos
	_active_balls.append(new_ball)
	_ball_hit_count_this_visit[new_ball.get_ball_id()] = 0
	_phantom_pegs_visited[new_ball.get_ball_id()] = 0

## Storm of Fragments (boss): split fragment hit 3+ energized pegs — chain lightning from all energized.
func _trigger_storm_of_fragments(ball_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	var energized_positions: Array = []
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if not p or not p.get("global_position"):
			continue
		if p.has_method("has_energized_stacks") and p.has_energized_stacks():
			energized_positions.append(p.global_position)
			var p_id: int = p.peg_id if p.get("peg_id") != null else -1
			if p_id >= 0 and _hit_cooldown.cooldown_ok(ball_id, p_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
				_hit_cooldown.record_hit(ball_id, p_id, sim_tick)
				if ball.has_method("add_peg_energy"):
					ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
				if p.has_method("apply_hit"):
					p.apply_hit(true, 1, false)
				if p.has_method("play_lightning_shock"):
					p.play_lightning_shock()
	if energized_positions.size() > 1:
		_spawn_chain_lightning_arcs(energized_positions)

# ==============================================================================
# POLYOMINO MODULE PLACEMENT & BOARD GRID SYSTEM (TASK-025)
# ==============================================================================

func set_drag_controller(controller: Node) -> void:
	_drag_controller = controller

func get_drag_controller() -> Node:
	if _drag_controller == null:
		_drag_controller = JunkBoxDragController.new()
		_drag_controller.name = "JunkBoxDragController"
		_drag_controller.board = self
		add_child(_drag_controller)
	return _drag_controller

func _input(event: InputEvent) -> void:
	var mouse_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouse:
		mouse_pos = (event as InputEventMouse).position
	elif is_inside_tree() and get_viewport():
		mouse_pos = get_global_mouse_position()

	if event is InputEventMouseMotion:
		_update_board_module_hover(mouse_pos)

	var controller: Node = get_drag_controller()
	if not controller:
		return
	if "dragging_item" in controller and controller.dragging_item != null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if "junk_box_panel" in controller and controller.junk_box_panel != null:
				if controller.junk_box_panel.is_visible_in_tree() and controller._is_mouse_over(controller.junk_box_panel):
					return
			if mouse_pos.x < 0.0 or mouse_pos.x > 960.0 or mouse_pos.y < 80.0 or mouse_pos.y > 720.0:
				return
			var cell := world_to_board_cell(mouse_pos)
			var item: Resource = get_module_at_cell(cell)
			if item and item.has_method("get_occupied_cells"):
				var origin_cell: Vector2i = item.grid_position if "grid_position" in item else cell
				var grab_offset: Vector2i = cell - origin_cell
				unslot_module(item.instance_id if "instance_id" in item else &"")
				KeywordDatabase.hide_flyout()
				controller.start_drag(item, 1, origin_cell, grab_offset) # DragSource.BOARD = 1
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	_input(event)

func _update_board_module_hover(mouse_pos: Vector2) -> void:
	if _drag_controller and "dragging_item" in _drag_controller and _drag_controller.dragging_item != null:
		if _hovered_module_instance_id != &"":
			_hovered_module_instance_id = &""
			KeywordDatabase.hide_flyout()
		return

	var cell := world_to_board_cell(mouse_pos)
	var item: Resource = get_module_at_cell(cell)
	if item != null and item is JunkBoxItem:
		var inst_id: StringName = item.instance_id
		if inst_id != _hovered_module_instance_id:
			_hovered_module_instance_id = inst_id
			var title_str: String = item.display_name
			var body_str: String = _format_module_tooltip_body(item)
			KeywordDatabase.show_flyout_custom(title_str, body_str, mouse_pos)
	else:
		if _hovered_module_instance_id != &"":
			_hovered_module_instance_id = &""
			KeywordDatabase.hide_flyout()

func _format_module_tooltip_body(item: JunkBoxItem) -> String:
	var body: String = ""
	var relic_id: StringName = StringName(item.custom_payload.get("relic_id", "")) if ("custom_payload" in item and item.custom_payload is Dictionary) else (item.module_data.module_id if item.module_data != null else &"")
	var goal_desc: String = item.module_data.activation_requirement if (item.module_data != null and not item.module_data.activation_requirement.is_empty()) else (PolyominoRelicDatabase.get_relic_activation_requirement(relic_id) if relic_id != &"" else "")
	var reward_desc: String = item.module_data.reward_description if (item.module_data != null and not item.module_data.reward_description.is_empty()) else (PolyominoRelicDatabase.get_relic_reward_description(relic_id) if relic_id != &"" else "")
	if not goal_desc.is_empty():
		body += "[u]Activation Requirement[/u]\n%s" % goal_desc
	if not reward_desc.is_empty():
		body += ("\n\n" if not body.is_empty() else "") + "[u]Relic Effect[/u]\n%s" % reward_desc
	var inst_id: StringName = item.instance_id if "instance_id" in item else &""
	if _placed_module_nodes.has(inst_id):
		var node: PolyominoModuleNode = _placed_module_nodes[inst_id] as PolyominoModuleNode
		var prog: String = node.get_progress_string() if (node and node.has_method("get_progress_string")) else ""
		if not prog.is_empty():
			body += "\n\n[u]Charge Progress[/u]: %s" % prog
	return body

## Converts a global/board world position into integer board grid coordinates (col, row).
func world_to_board_cell(world_pos: Vector2) -> Vector2i:
	var local_x: float = world_pos.x - BOARD_GRID_START_X
	var local_y: float = world_pos.y - BOARD_GRID_START_Y
	var col: int = int(round(local_x / BOARD_GRID_COL_SPACING))
	var row: int = int(round(local_y / BOARD_GRID_ROW_SPACING))
	return Vector2i(col, row)

## Converts board grid coordinates (col, row) into world pixel position (cell top-left center).
func board_cell_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		BOARD_GRID_START_X + float(grid_pos.x) * BOARD_GRID_COL_SPACING,
		BOARD_GRID_START_Y + float(grid_pos.y) * BOARD_GRID_ROW_SPACING
	)

## Returns true if the specified grid coordinates fall within board bounds.
func is_cell_in_bounds(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < BOARD_GRID_COLS and grid_pos.y >= 0 and grid_pos.y < BOARD_GRID_ROWS

## Returns the peg occupying the specified grid cell, or null if no peg exists or if currently suppressed by a relic.
func get_peg_at_cell(grid_pos: Vector2i) -> Node:
	if not is_cell_in_bounds(grid_pos):
		return null
	if _suppressed_pegs_by_cell.has(grid_pos):
		return null
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		if peg and is_instance_valid(peg):
			if world_to_board_cell(peg.position) == grid_pos:
				return peg
	return null

## Returns any peg located at grid_pos, regardless of whether it is active or suppressed by a relic.
func _get_raw_peg_at_cell(grid_pos: Vector2i) -> Node:
	if not is_cell_in_bounds(grid_pos):
		return null
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		if peg and is_instance_valid(peg):
			if world_to_board_cell(peg.position) == grid_pos:
				return peg
	return null

func _suppress_peg(peg: Node, cell: Vector2i) -> void:
	if peg == null or not is_instance_valid(peg):
		return
	_suppressed_pegs_by_cell[cell] = peg
	peg.visible = false
	if peg.has_method("_set_collision_enabled"):
		peg._set_collision_enabled(false)
	else:
		peg.collision_layer = 0
		var col: CollisionShape2D = peg.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col:
			col.disabled = true
	peg.set_process(false)

func _unsuppress_peg(peg: Node, cell: Vector2i) -> void:
	_suppressed_pegs_by_cell.erase(cell)
	if peg == null or not is_instance_valid(peg):
		return
	peg.visible = true
	if peg.has_method("_set_collision_enabled"):
		var solid: bool = peg.get("_phase_peg_solid") if "_phase_peg_solid" in peg else true
		var rec: int = peg.get("_recovery_ticks_remaining") if "_recovery_ticks_remaining" in peg else 0
		var ghost: bool = peg.get("_is_ghost_placement") if "_is_ghost_placement" in peg else false
		peg._set_collision_enabled(not ghost and solid and rec <= 0)
	else:
		peg.collision_layer = 1
		var col: CollisionShape2D = peg.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col:
			col.disabled = false
	peg.set_process(true)
	peg.queue_redraw()

## Returns true if the cell is within bounds and has neither a peg nor a placed module.
func is_cell_empty(grid_pos: Vector2i) -> bool:
	if not is_cell_in_bounds(grid_pos):
		return false
	if _occupied_board_cells.has(grid_pos):
		return false
	if get_peg_at_cell(grid_pos) != null:
		return false
	return true

## Returns all valid board grid coordinates that currently contain no pegs and no modules.
func get_empty_grid_cells() -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	for r in range(BOARD_GRID_ROWS):
		for c in range(BOARD_GRID_COLS):
			var cell := Vector2i(c, r)
			if is_cell_empty(cell):
				empty.append(cell)
	return empty

## Checks whether an item can be legally placed on the board grid at target grid_pos.
func can_place_module(item: Resource, grid_pos: Vector2i, rotation: int = -1, ignore_instance_id: StringName = &"") -> bool:
	if item == null:
		return false
	var rot: int = item.rotation_step if rotation < 0 else posmod(rotation, 4)
	var local_cells: Array[Vector2i] = []
	if "module_data" in item and item.module_data != null and not item.module_data.cells.is_empty():
		local_cells = item.module_data.get_anchored_rotated_cells(rot)
	elif "get_local_cells" in item:
		local_cells = item.get_local_cells()
	else:
		local_cells = [Vector2i.ZERO]

	for c in local_cells:
		var cell: Vector2i = grid_pos + c
		if cell.x < 0 or cell.x >= BOARD_GRID_COLS:
			return false
		if cell.y < 0 or cell.y >= BOARD_GRID_ROWS:
			return false
		if _occupied_board_cells.has(cell):
			var occ_id: StringName = _occupied_board_cells[cell]
			if ignore_instance_id == &"" or occ_id != ignore_instance_id:
				return false
	return true

## Attempts to place a module given a global/world coordinate.
func try_place_module(item: Resource, world_pos: Vector2, rotation: int = -1) -> bool:
	if item == null:
		return false
	var grid_pos: Vector2i = world_to_board_cell(world_pos)
	return place_module(item, grid_pos, rotation)

## Places a module on the board grid at target grid_pos with specified rotation.
func place_module(item: Resource, grid_pos: Vector2i, rotation: int = -1) -> bool:
	if item == null:
		return false
	var inst_id: StringName = item.instance_id if "instance_id" in item else StringName(str(item.get_instance_id()))
	if not can_place_module(item, grid_pos, rotation, inst_id):
		return false

	# Clear previous occupied cells and unsuppress previous pegs if already placed on board
	if _placed_modules.has(inst_id):
		unslot_module(inst_id)

	item.grid_position = grid_pos
	if rotation >= 0:
		item.rotation_step = posmod(rotation, 4)

	_placed_modules[inst_id] = item
	var occupied: Array = item.get_occupied_cells() if "get_occupied_cells" in item else [grid_pos]
	var suppressed_list: Array[Node] = []
	for cell in occupied:
		_occupied_board_cells[cell] = inst_id
		var peg_node: Node = _get_raw_peg_at_cell(cell)
		if peg_node and is_instance_valid(peg_node):
			_suppress_peg(peg_node, cell)
			suppressed_list.append(peg_node)
	_suppressed_pegs_by_module[inst_id] = suppressed_list

	_update_placed_module_visual(item)
	var is_clear: bool = is_module_area_clear_of_balls(item)
	var node: Node = _placed_module_nodes.get(inst_id)
	if not is_clear:
		_ghost_placed_modules[inst_id] = true
		if node and node.has_method("set_ghost_state"):
			node.set_ghost_state(true)
		ghost_state_changed.emit(item, true)
	else:
		_ghost_placed_modules.erase(inst_id)
		if node and node.has_method("set_ghost_state"):
			node.set_ghost_state(false)
		ghost_state_changed.emit(item, false)
		module_solidified.emit(item)

	var relic_id: StringName = &""
	if "custom_payload" in item and item.custom_payload is Dictionary:
		relic_id = StringName(item.custom_payload.get("relic_id", ""))
	if relic_id == &"" and "module_data" in item and item.module_data != null:
		relic_id = item.module_data.module_id
	if relic_id != &"":
		PolyominoRelicDatabase.apply_relic_effects_to_game_state(relic_id)

	module_placed_on_board.emit(item, grid_pos, item.rotation_step)
	return true

## Unslots and removes a placed module by instance_id, returning the removed item.
func unslot_module(instance_id: StringName) -> Resource:
	if not _placed_modules.has(instance_id):
		return null
	var item: Resource = _placed_modules[instance_id]
	var occupied: Array = item.get_occupied_cells() if "get_occupied_cells" in item else []
	for cell in occupied:
		if _occupied_board_cells.get(cell) == instance_id:
			_occupied_board_cells.erase(cell)
	_placed_modules.erase(instance_id)
	_ghost_placed_modules.erase(instance_id)

	# Restore any pegs that were suppressed under this module's footprint
	if _suppressed_pegs_by_module.has(instance_id):
		var suppressed_list: Array = _suppressed_pegs_by_module[instance_id]
		for peg_node in suppressed_list:
			if peg_node and is_instance_valid(peg_node):
				var cell: Vector2i = world_to_board_cell(peg_node.position)
				_unsuppress_peg(peg_node, cell)
		_suppressed_pegs_by_module.erase(instance_id)

	if _hovered_module_instance_id == instance_id:
		_hovered_module_instance_id = &""
		KeywordDatabase.hide_flyout()

	if _placed_module_nodes.has(instance_id):
		var node: Node = _placed_module_nodes[instance_id]
		if is_instance_valid(node):
			node.queue_free()
		_placed_module_nodes.erase(instance_id)

	var relic_id: StringName = &""
	if item != null:
		if "custom_payload" in item and item.custom_payload is Dictionary:
			relic_id = StringName(item.custom_payload.get("relic_id", ""))
		if relic_id == &"" and "module_data" in item and item.module_data != null:
			relic_id = item.module_data.module_id
	if relic_id != &"":
		PolyominoRelicDatabase.remove_relic_effects_from_game_state(relic_id)

	module_unslotted_from_board.emit(item)
	return item

## Unslots a module from the board and returns it to the Junk Box inventory.
## If target_cell is specified (x >= 0, y >= 0), attempts to place it at target_cell.
## Otherwise, automatically finds the first available slot in the junk box.
## Returns true if successfully returned to the junk box, false if transfer failed.
func return_module_to_junk_box(instance_id: StringName, junk_box: JunkBoxData = null, target_cell: Vector2i = Vector2i(-1, -1)) -> bool:
	if not _placed_modules.has(instance_id):
		return false
	var jb: JunkBoxData = junk_box if junk_box != null else (GameState.junk_box if GameState and GameState.junk_box != null else null)
	if jb == null:
		return false
	var item: Resource = _placed_modules[instance_id]
	var orig_grid_pos: Vector2i = item.grid_position if "grid_position" in item else Vector2i.ZERO
	var orig_rot: int = item.rotation_step if "rotation_step" in item else 0

	unslot_module(instance_id)

	var success: bool = false
	if target_cell.x >= 0 and target_cell.y >= 0:
		success = jb.place_item(item, target_cell, orig_rot)
	if not success:
		success = jb.add_item_auto(item)

	if not success:
		place_module(item, orig_grid_pos, orig_rot)
		return false
	return true

## Returns the placed module occupying grid_pos, or null.
func get_module_at_cell(grid_pos: Vector2i) -> Resource:
	if _occupied_board_cells.has(grid_pos):
		var id: StringName = _occupied_board_cells[grid_pos]
		return _placed_modules.get(id, null)
	return null

## Returns an array of all modules currently placed on the board.
func get_all_placed_modules() -> Array:
	var result: Array = []
	for it in _placed_modules.values():
		result.append(it)
	return result

## Clears all placed modules from the board.
func clear_all_placed_modules() -> void:
	for inst_id in _placed_modules.keys().duplicate():
		unslot_module(inst_id)
	_occupied_board_cells.clear()
	_ghost_placed_modules.clear()

## Toggles the ghost state of a placed module.
func set_module_ghost_state(instance_id: StringName, ghost: bool) -> void:
	if ghost:
		_ghost_placed_modules[instance_id] = true
	else:
		_ghost_placed_modules.erase(instance_id)

	var node: Node = _placed_module_nodes.get(instance_id)
	if node and is_instance_valid(node) and node.has_method("set_ghost_state"):
		node.set_ghost_state(ghost)

	var item: Resource = _placed_modules.get(instance_id)
	if item:
		ghost_state_changed.emit(item, ghost)
		if not ghost:
			module_solidified.emit(item)

## Returns true if the placed module is currently in non-colliding ghost state.
func is_module_in_ghost_state(instance_id: StringName) -> bool:
	return _ghost_placed_modules.has(instance_id)

## Returns true if the peg is currently in non-colliding ghost state.
func is_peg_in_ghost_state(peg_id: int) -> bool:
	return _ghost_placed_pegs.has(peg_id)

## Returns an array of all modules currently in ghost state.
func get_ghost_modules() -> Array:
	var result: Array = []
	for id in _ghost_placed_modules.keys():
		var item: Resource = _placed_modules.get(id)
		if item:
			result.append(item)
	return result

## Returns an array of all pegs currently in ghost state.
func get_ghost_pegs() -> Array:
	var result: Array = []
	for p in _ghost_placed_pegs.values():
		if is_instance_valid(p):
			result.append(p)
	return result

## Returns true if no active balls overlap the footprint of the given module item.
func is_module_area_clear_of_balls(item: Resource) -> bool:
	if item == null:
		return true
	var inst_id: StringName = item.instance_id if "instance_id" in item else StringName(str(item.get_instance_id()))
	var node: Node = _placed_module_nodes.get(inst_id)
	if node and is_instance_valid(node) and node.has_method("is_area_clear_of_balls"):
		return node.is_area_clear_of_balls(_active_balls)

	var occupied: Array = item.get_occupied_cells() if "get_occupied_cells" in item else [item.grid_position]
	for grid_c in occupied:
		var world_c: Vector2 = board_cell_to_world(grid_c)
		var cell_rect := Rect2(world_c.x - BOARD_GRID_COL_SPACING * 0.5, world_c.y - BOARD_GRID_ROW_SPACING * 0.5, BOARD_GRID_COL_SPACING, BOARD_GRID_ROW_SPACING)
		var check_rect: Rect2 = cell_rect.grow(Constants.BALL_RADIUS + 2.0)
		for ball in _active_balls:
			if not is_instance_valid(ball):
				continue
			var b_pos: Vector2 = ball.global_position if (ball.is_inside_tree() and "global_position" in ball) else (ball.position if "position" in ball else Vector2.ZERO)
			if check_rect.has_point(b_pos):
				return false
	return true

## Returns true if no active balls overlap the given peg's collision area.
func is_peg_area_clear_of_balls(peg: Node) -> bool:
	if not is_instance_valid(peg):
		return true
	if peg.has_method("is_area_clear_of_balls"):
		return peg.is_area_clear_of_balls(_active_balls)
	var peg_pos: Vector2 = peg.global_position if peg.is_inside_tree() else peg.position
	var clear_dist: float = Constants.PEG_RADIUS + Constants.BALL_RADIUS + 2.0
	var clear_dist_sq: float = clear_dist * clear_dist
	for ball in _active_balls:
		if not is_instance_valid(ball):
			continue
		var b_pos: Vector2 = ball.global_position if (ball.is_inside_tree() and "global_position" in ball) else (ball.position if "position" in ball else Vector2.ZERO)
		if peg_pos.distance_squared_to(b_pos) <= clear_dist_sq:
			return false
	return true

## Places a peg at target grid_pos, entering ghost state if balls overlap.
func place_peg_at_cell(grid_pos: Vector2i, config: PegConfig = null, extra_kind: String = "") -> Node:
	var world_pos: Vector2 = board_cell_to_world(grid_pos)
	var p: Node = null
	if _peg_scene:
		p = _peg_scene.instantiate()
	else:
		var p_script: GDScript = preload("res://scenes/board/peg.gd")
		p = StaticBody2D.new()
		p.set_script(p_script)
	p.position = world_pos
	p.peg_id = _next_dynamic_peg_id
	p.set_meta("grid_cell", grid_pos)
	_next_dynamic_peg_id += 1
	if config:
		p.peg_config = config
	if extra_kind != "":
		p.peg_extra_kind = extra_kind
	_peg_by_id[p.peg_id] = p
	add_child(p)

	if not is_peg_area_clear_of_balls(p):
		_ghost_placed_pegs[p.peg_id] = p
		if p.has_method("set_ghost_placement"):
			p.set_ghost_placement(true)
		ghost_state_changed.emit(p, true)
	else:
		if p.has_method("set_ghost_placement"):
			p.set_ghost_placement(false)
		ghost_state_changed.emit(p, false)
		peg_solidified.emit(p)
	return p

## Unslots and removes a peg occupying target grid_pos.
func unslot_peg_at_cell(grid_pos: Vector2i) -> Node:
	var world_pos: Vector2 = board_cell_to_world(grid_pos)
	for pid in _ghost_placed_pegs.keys():
		var p: Node = _ghost_placed_pegs.get(pid)
		if p and is_instance_valid(p) and p.position.distance_to(world_pos) < 16.0:
			_ghost_placed_pegs.erase(pid)
			_peg_by_id.erase(pid)
			return p
	for pid in _peg_by_id.keys():
		var p: Node = _peg_by_id.get(pid)
		if p and is_instance_valid(p):
			if p.position.distance_to(world_pos) < 16.0:
				_peg_by_id.erase(pid)
				_ghost_placed_pegs.erase(pid)
				return p
	return null

## Updates ghost-state modules and pegs, solidifying them once active balls clear.
func _process_ghost_states(_sim_tick: int) -> void:
	for inst_id in _ghost_placed_modules.keys().duplicate():
		var item: Resource = _placed_modules.get(inst_id)
		if item and is_module_area_clear_of_balls(item):
			set_module_ghost_state(inst_id, false)

	for pid in _ghost_placed_pegs.keys().duplicate():
		var peg: Node = _peg_by_id.get(pid)
		if peg and is_instance_valid(peg):
			if is_peg_area_clear_of_balls(peg):
				if peg.has_method("set_ghost_placement"):
					peg.set_ghost_placement(false)
				_ghost_placed_pegs.erase(pid)
				ghost_state_changed.emit(peg, false)
				peg_solidified.emit(peg)
		else:
			_ghost_placed_pegs.erase(pid)

## Visual and kinetic machinery representation node for placed modules on the board.
func _update_placed_module_visual(item: Resource) -> void:
	if not _modules_container:
		_modules_container = Node2D.new()
		_modules_container.name = "PlacedModules"
		_modules_container.z_index = 2
		add_child(_modules_container)
	var inst_id: StringName = item.instance_id if "instance_id" in item else StringName(str(item.get_instance_id()))
	if _placed_module_nodes.has(inst_id):
		var old_node: Node = _placed_module_nodes[inst_id]
		if is_instance_valid(old_node):
			old_node.queue_free()
		_placed_module_nodes.erase(inst_id)
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.name = "Module_%s" % str(inst_id)
	node.position = board_cell_to_world(item.grid_position)
	node.setup_module(item, item.grid_position, item.rotation_step)
	node.machinery_triggered.connect(_on_module_machinery_triggered)
	node.goal_completed.connect(_on_module_goal_completed)
	_modules_container.add_child(node)
	_placed_module_nodes[inst_id] = node

func _on_module_machinery_triggered(comp: Node, ball: Node, energy: int, impulse: Vector2) -> void:
	module_machinery_activated.emit(comp, ball, energy, impulse)
	if energy > 0 and comp:
		_spawn_energy_popup_at_pos(comp.global_position, energy)
	if _hit_effect_scene and comp:
		var fx: Node2D = _hit_effect_scene.instantiate() as Node2D
		if fx and fx is BallHitEffect:
			fx.global_position = comp.global_position
			fx.z_index = 100
			var eff_type: BallHitEffect.EffectType = BallHitEffect.EffectType.EXPLOSIVE
			if "cell_type" in comp:
				match comp.cell_type:
					PolyominoModuleData.CellType.ACCELERATOR, PolyominoModuleData.CellType.ROTARY_BOOSTER:
						eff_type = BallHitEffect.EffectType.LIGHTNING
					PolyominoModuleData.CellType.MANA_SIPHON:
						eff_type = BallHitEffect.EffectType.LEECH
					PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR, PolyominoModuleData.CellType.FUNNEL, PolyominoModuleData.CellType.GUIDE_RAIL:
						eff_type = BallHitEffect.EffectType.RUBBERY
					_:
						eff_type = BallHitEffect.EffectType.EXPLOSIVE
			fx.setup_effect(eff_type)
			(get_parent() if get_parent() else self).add_child(fx)

func _on_module_goal_completed(module_node: Node, goal_type: int, reward_type: int, ball: Node, reward_data: Dictionary) -> void:
	PolyominoGoalRewardHandler.handle_goal_reward(self, module_node, goal_type, reward_type, ball, reward_data)
