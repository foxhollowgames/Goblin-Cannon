extends Node2D
## Board (§6.3). Single authority for hit detection and per-ball energy. Flush once per sim tick.

signal ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2, status_effects: Dictionary)
signal ball_ability_on_peg_hit(status_effects: Dictionary)  ## GDD §8: ball ability triggered on peg hit; apply status to minions.
signal ball_exited_board(ball: Node, reason: int)

const REASON_BOTTOM: int = 0
const REASON_STALL: int = 1
const REASON_OFF_SCREEN: int = 2

## Bottom 10px of viewport (720 - 10): balls that enter this band turn into energy.
const BOTTOM_ZONE_Y: float = 710.0
const OFF_SCREEN_Y: float = 730.0
## Horizontal bounds: match play area (board 0..960) so balls that bounce out left/right are returned to hopper instead of staying in _active_balls.
const OFF_SCREEN_X_LEFT: float = -20.0
const OFF_SCREEN_X_RIGHT: float = 980.0
const PEG_DISPLAY_ENERGY_PER_HIT: int = 10  # display units (§1.7)

var _active_balls: Array[Node] = []
var _hit_cooldown: HitCooldown
var _spawn_position: Vector2 = Vector2(480, 80)  # At gate height so ball falls naturally from hopper
var _peg_by_id: Dictionary = {}
var _balls_container: Node2D
var _peg_scene: PackedScene
var _energy_popup_scene: PackedScene

func _ready() -> void:
	_hit_cooldown = HitCooldown.new()
	var main: Node = get_parent()
	_balls_container = main.get_node_or_null("BallsContainer") as Node2D
	if not _balls_container:
		_balls_container = self
	_peg_scene = load("res://scenes/board/peg.tscn") as PackedScene
	_energy_popup_scene = load("res://scenes/board/energy_popup.tscn") as PackedScene
	_spawn_peg_layout()

func get_active_ball_count() -> int:
	return _active_balls.size()

func spawn_ball_at_start(ball: Node) -> void:
	if not ball:
		return
	# Ball may already be in the world (fell out of hopper); only reparent/place if not
	if ball.get_parent() == _balls_container:
		_active_balls.append(ball)
		return
	if "freeze" in ball:
		ball.freeze = false
	ball.global_position = _spawn_position
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	_balls_container.add_child(ball)
	_active_balls.append(ball)

func get_peg_by_id(id: int) -> Node:
	return _peg_by_id.get(id)

func run_ball_steps(sim_tick: int) -> void:
	for p in get_children():
		if p.has_method("sim_tick"):
			p.sim_tick(sim_tick)
	for b in _active_balls:
		if b.has_method("step_one_sim_tick"):
			var peg: Node = b.step_one_sim_tick(sim_tick)
			if peg and peg.get("peg_id") != null:
				var pid: int = peg.peg_id
				var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
				if _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					_hit_cooldown.record_hit(bid, pid, sim_tick)
					if b.has_method("add_peg_energy"):
						b.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
					if peg.has_method("apply_hit"):
						peg.apply_hit()
					_spawn_energy_popup(peg, PEG_DISPLAY_ENERGY_PER_HIT)
					# GDD §8: ball ability on peg hit — apply status to minions
					if b.has_method("get_definition"):
						var def = b.get_definition()
						if def is BallDefinition and not def.status_effects.is_empty():
							ball_ability_on_peg_hit.emit(def.status_effects)

func flush_tick(sim_tick: int) -> void:
	for b in _active_balls.duplicate():
		var pos: Vector2 = b.get_global_sim_position() if b.has_method("get_global_sim_position") else b.global_position
		if pos.y >= BOTTOM_ZONE_Y:
			var ball_id: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
			var total: int = b.get_total_energy() if b.has_method("get_total_energy") else 20
			var alignment: int = 0
			var status_effects: Dictionary = {}
			if b.has_method("get_definition"):
				var def = b.get_definition()
				if def is BallDefinition:
					alignment = def.alignment
					if def.status_effects != null and not def.status_effects.is_empty():
						status_effects = def.status_effects
			ball_reached_bottom.emit(ball_id, total, alignment, pos, status_effects)
			_active_balls.erase(b)
			ball_exited_board.emit(b, REASON_BOTTOM)
		elif pos.y > OFF_SCREEN_Y or pos.x < OFF_SCREEN_X_LEFT or pos.x > OFF_SCREEN_X_RIGHT:
			_active_balls.erase(b)
			ball_exited_board.emit(b, REASON_OFF_SCREEN)

func explode_at(_peg_id: int) -> void:
	pass  # future

func _spawn_energy_popup(peg: Node, amount_display: int) -> void:
	if not _energy_popup_scene:
		return
	var popup: Node2D = _energy_popup_scene.instantiate() as Node2D
	if not popup:
		return
	popup.setup("+%d" % amount_display)
	popup.position = peg.position + Vector2(0, -16)
	add_child(popup)

func _spawn_peg_layout() -> void:
	if not _peg_scene:
		return
	# Full-width offset rows: each row has the same number of pegs across the board; odd rows offset by half spacing.
	var peg_id_counter: int = 0
	var row_spacing: float = 56.0
	var col_spacing: float = 52.0
	var center_x: float = 480.0
	var top: float = 200.0  # Well below hopper exit
	var num_rows: int = 8
	var peg_field_width: float = 800.0  # Total width to fill
	var cols_per_row: int = ceili(peg_field_width / col_spacing)
	var row_width: float = (cols_per_row - 1) * col_spacing
	var start_x: float = center_x - row_width * 0.5
	for row in range(num_rows):
		var row_offset_x: float = (col_spacing * 0.5) if (row % 2 == 1) else 0.0
		for col in range(cols_per_row):
			if (row + col) % 2 != 0:
				continue  # Skip every other peg (checkerboard)
			var p: Node = _peg_scene.instantiate()
			p.position = Vector2(start_x + row_offset_x + col * col_spacing, top + row * row_spacing)
			p.peg_id = peg_id_counter
			_peg_by_id[peg_id_counter] = p
			peg_id_counter += 1
			add_child(p)
