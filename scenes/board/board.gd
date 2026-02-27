extends Node2D
## Board (§6.3). Single authority for hit detection and per-ball energy. Flush once per sim tick.

signal ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int)
signal ball_exited_board(ball: Node, reason: int)

const REASON_BOTTOM: int = 0
const REASON_STALL: int = 1
const PEG_DISPLAY_ENERGY_PER_HIT: int = 10  # display units (§1.7)

var _active_balls: Array[Node] = []
var _hit_cooldown: HitCooldown
var _spawn_position: Vector2 = Vector2(480, 55)  # Above first peg row (y=120); ball falls immediately
var _peg_by_id: Dictionary = {}
var _balls_container: Node2D
var _peg_scene: PackedScene

func _ready() -> void:
	_hit_cooldown = HitCooldown.new()
	var main: Node = get_parent()
	_balls_container = main.get_node_or_null("BallsContainer") as Node2D
	if not _balls_container:
		_balls_container = self
	_peg_scene = load("res://scenes/board/peg.tscn") as PackedScene
	_spawn_peg_layout()

func get_active_ball_count() -> int:
	return _active_balls.size()

func spawn_ball_at_start(ball: Node) -> void:
	if ball:
		ball.global_position = _spawn_position
		# Ensure ball has downward velocity so it falls on first tick (avoids stuck-on-peg)
		if "velocity" in ball:
			ball.velocity = Vector2(0, 5.0)
		_active_balls.append(ball)
		_balls_container.add_child(ball)

func get_peg_by_id(id: int) -> Node:
	return _peg_by_id.get(id)

func run_ball_steps(sim_tick: int) -> void:
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

func flush_tick(sim_tick: int) -> void:
	# Placeholder: no hit resolution yet; just emit bottom for any ball that reached bottom zone
	for b in _active_balls.duplicate():
		var check_y: float = b.get_global_sim_position().y if b.has_method("get_global_sim_position") else b.global_position.y
		if check_y > 600:  # simple bottom zone (use sim position so flush matches logic, not interpolated display)
			var ball_id: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
			var total: int = b.get_total_energy() if b.has_method("get_total_energy") else 20
			ball_reached_bottom.emit(ball_id, total, 0)  # 0 = MAIN alignment
			_active_balls.erase(b)
			b.queue_free()

func explode_at(_peg_id: int) -> void:
	pass  # future

func _spawn_peg_layout() -> void:
	if not _peg_scene:
		return
	# Plinko triangle: spacing so ball (diameter 16) can pass between pegs (diameter 24).
	# Center-to-center >= 2*PEG_RADIUS + 2*BALL_RADIUS + margin => ~52+ for comfortable bounce
	var peg_id_counter: int = 0
	var row_spacing: float = 56.0
	var col_spacing: float = 52.0
	var center_x: float = 480.0
	var top: float = 100.0
	for row in range(10):
		var cols_in_row: int = 4 + row
		var row_width: float = (cols_in_row - 1) * col_spacing
		var start_x: float = center_x - row_width * 0.5
		for col in range(cols_in_row):
			var p: Node = _peg_scene.instantiate()
			p.position = Vector2(start_x + col * col_spacing, top + row * row_spacing)
			p.peg_id = peg_id_counter
			_peg_by_id[peg_id_counter] = p
			peg_id_counter += 1
			add_child(p)
