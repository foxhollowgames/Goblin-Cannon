extends Node2D
## Dynamic board event pegs, milestone event triggers, sticky slime, and black hole vortex handling for Board.

#region State & References
var _black_hole_active: bool = false
var _black_hole_center_global: Vector2 = Vector2.ZERO
var _black_hole_deadline_ms: int = 0
var _black_hole_visual: Node2D = null
var _board_root: Node2D = null
#endregion

#region Initialization
## Sets up event mechanics manager with root Board reference.
func setup(board_root: Node2D) -> void:
	_board_root = board_root
#endregion

#region Black Hole Event
## Initiates a black hole event centered at local position for the specified duration.
func begin_black_hole_event(board_local_center: Vector2, duration_sec: float) -> void:
	_black_hole_active = true
	if _board_root:
		_black_hole_center_global = _board_root.to_global(board_local_center)
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

## Advances black hole vortex logic per sim tick.
func tick_black_hole_event(sim_tick: int) -> void:
	if not _black_hole_active:
		return
	if Time.get_ticks_msec() >= _black_hole_deadline_ms:
		end_black_hole_event()

## Concludes the active black hole event and cleans up visuals.
func end_black_hole_event() -> void:
	_black_hole_active = false
	if _black_hole_visual and is_instance_valid(_black_hole_visual):
		_black_hole_visual.queue_free()
	_black_hole_visual = null

## Returns true if a black hole event is currently active.
func is_black_hole_active() -> bool:
	return _black_hole_active
#endregion

