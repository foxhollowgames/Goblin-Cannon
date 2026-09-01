extends Node2D
## Peg grid spawning, staggered lattice coordinate math, and peg spatial queries for the Board scene.

#region State and Constants
const BOARD_GRID_COLS: int = 16
const BOARD_GRID_ROWS: int = 8
const BOARD_GRID_START_X: float = 90.0
const BOARD_GRID_START_Y: float = 200.0
const BOARD_GRID_COL_SPACING: float = 52.0
const BOARD_GRID_ROW_SPACING: float = 56.0

var _peg_by_id: Dictionary = {}  ## int -> Node
var _layout_empty_slots: Array = []  ## Vector2i
var _next_dynamic_peg_id: int = 500000
var _board_root: Node2D = null
#endregion

#region Initialization
## Sets up the board peg layout manager with a reference to the board root node.
func setup(board_root: Node2D) -> void:
	_board_root = board_root

## Returns all pegs currently registered on the board.
func get_all_pegs() -> Array[Node]:
	var pegs: Array[Node] = []
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		if peg and is_instance_valid(peg):
			pegs.append(peg)
	return pegs

## Returns a peg by its unique peg ID.
func get_peg_by_id(peg_id: int) -> Node:
	return _peg_by_id.get(peg_id, null) as Node

## Returns the peg positioned at the target grid cell, if any.
func get_peg_at_cell(cell: Vector2i) -> Node:
	for pid in _peg_by_id:
		var peg: Node = _peg_by_id[pid]
		if peg and is_instance_valid(peg):
			if _board_root and _board_root.has_method("world_to_board_cell"):
				if _board_root.world_to_board_cell(peg.position) == cell:
					return peg
	return null

## Resolves event position constrained within horizontal bounds.
func resolve_event_position(local_pos: Vector2, x_min: float = 100.0, x_max: float = 860.0) -> Vector2:
	var preferred_cell: Vector2i = Vector2i.ZERO
	if _board_root and _board_root.has_method("world_to_board_cell"):
		preferred_cell = _board_root.world_to_board_cell(local_pos)

	var clamped_col: int = clampi(preferred_cell.x, 0, BOARD_GRID_COLS - 1)
	var clamped_row: int = clampi(preferred_cell.y, 0, BOARD_GRID_ROWS - 1)
	var pos: Vector2 = local_pos
	if _board_root and _board_root.has_method("board_cell_to_world"):
		pos = _board_root.board_cell_to_world(Vector2i(clamped_col, clamped_row))
	pos.x = clampf(pos.x, x_min, x_max)
	return pos


## Picks distinct normal peg IDs for event application.
func pick_random_normal_peg_ids(count: int) -> Array[int]:
	var out: Array[int] = []
	var candidates: Array[int] = []
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if p and is_instance_valid(p) and str(p.get("peg_extra_kind")) == "":
			candidates.append(int(pid))
	if candidates.is_empty():
		return out
	candidates.shuffle()
	var n: int = mini(count, candidates.size())
	for i in range(n):
		out.append(candidates[i])
	return out
#endregion

