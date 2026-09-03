extends Node2D
## Grid coordinates, module placement validation, and peg suppression for the Board scene.

#region Signals
signal module_placed_on_board(item: Resource, grid_pos: Vector2i, rotation: int)
signal module_unslotted_from_board(item: Resource)
signal ghost_state_changed(component: Variant, is_ghost: bool)
signal module_solidified(item: Resource)
#endregion

#region Constants
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")

const BOARD_GRID_COLS: int = 15
const BOARD_GRID_ROWS: int = 8
const BOARD_GRID_START_X: float = 116.0
const BOARD_GRID_START_Y: float = 200.0
const BOARD_GRID_COL_SPACING: float = 52.0
const BOARD_GRID_ROW_SPACING: float = 56.0
#endregion

#region State Dictionaries
var _placed_modules: Dictionary = {}  ## StringName -> JunkBoxItem
var _occupied_board_cells: Dictionary = {}  ## Vector2i -> StringName
var _placed_module_nodes: Dictionary = {}  ## StringName -> Node2D
var _ghost_placed_modules: Dictionary = {}  ## StringName -> bool
var _suppressed_pegs_by_cell: Dictionary = {}  ## Vector2i -> Node
var _suppressed_pegs_by_module: Dictionary = {}  ## StringName -> Array[Node]
var _hovered_module_instance_id: StringName = &""
var _board_root: Node2D = null
#endregion

#region Initialization
## Sets up the grid modules manager with reference to the root Board node.
func setup(board_root: Node2D) -> void:
	_board_root = board_root
#endregion

#region Grid Coordinate Conversions
## Converts board grid cell coordinates to world position.
func board_cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		BOARD_GRID_START_X + cell.x * BOARD_GRID_COL_SPACING,
		BOARD_GRID_START_Y + cell.y * BOARD_GRID_ROW_SPACING
	)

## Converts world position to board grid cell coordinates.
func world_to_board_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(round((world_pos.x - BOARD_GRID_START_X) / BOARD_GRID_COL_SPACING)),
		int(round((world_pos.y - BOARD_GRID_START_Y) / BOARD_GRID_ROW_SPACING))
	)

## Returns true if cell coordinates lie within board grid boundaries.
func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < BOARD_GRID_COLS and cell.y >= 0 and cell.y < BOARD_GRID_ROWS

## Returns true if target cell is within bounds and has no placed modules or pegs.
func is_cell_empty(grid_pos: Vector2i) -> bool:
	if not is_cell_in_bounds(grid_pos):
		return false
	if _occupied_board_cells.has(grid_pos):
		return false
	if _board_root and _board_root.has_method("get_peg_at_cell"):
		if _board_root.get_peg_at_cell(grid_pos) != null:
			return false
	return true

## Returns all valid board grid coordinates that contain no pegs and no modules.
func get_empty_grid_cells() -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	for r in range(BOARD_GRID_ROWS):
		for c in range(BOARD_GRID_COLS):
			var cell := Vector2i(c, r)
			if is_cell_empty(cell):
				empty.append(cell)
	return empty
#endregion

#region Peg Suppression
## Suppresses a peg visually and physically when covered by a module.
func suppress_peg(peg: Node, cell: Vector2i) -> void:
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

## Restores a suppressed peg when a module is unslotted.
func unsuppress_peg(peg: Node, cell: Vector2i) -> void:
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
#endregion

#region Module Placement API
## Checks whether an item can be legally placed on the board grid.
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

## Retrieves the node of a placed module by instance ID.
func get_placed_module_node(instance_id: StringName) -> Node2D:
	return _placed_module_nodes.get(instance_id, null) as Node2D
#endregion

