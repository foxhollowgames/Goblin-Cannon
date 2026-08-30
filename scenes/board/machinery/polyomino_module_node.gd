extends Node2D
class_name PolyominoModuleNode
## Compound multi-cell polyomino module node on the board.
## Scales and spawns internal kinetic machinery components matching module shape and rotation.

signal machinery_triggered(component: PolyominoMachineryComponent, ball: Node, energy_granted: int, impulse: Vector2)

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoMachineryComponentScript = preload("res://scenes/board/machinery/polyomino_machinery_component.gd")
const PinballBumperScript = preload("res://scenes/board/machinery/pinball_bumper.gd")
const SpeedBoostWheelScript = preload("res://scenes/board/machinery/speed_boost_wheel.gd")
const ManaSiphonScript = preload("res://scenes/board/machinery/mana_siphon.gd")
const DirectionalDeflectorScript = preload("res://scenes/board/machinery/directional_deflector.gd")

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

	_rebuild_components()
	queue_redraw()

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
		_:
			# Default Bumper for general interactive cells
			return PinballBumperScript.new()

func _on_component_activated(comp: PolyominoMachineryComponent, ball: Node, energy: int, impulse: Vector2) -> void:
	machinery_triggered.emit(comp, ball, energy, impulse)

var is_ghost: bool = false

func set_ghost_state(p_ghost: bool) -> void:
	is_ghost = p_ghost
	modulate.a = 0.5 if is_ghost else 1.0
	queue_redraw()

func is_ghost_state_active() -> bool:
	return is_ghost

## Checks and triggers interaction if a ball contacts any machinery component in this module.
func check_ball_collision(ball: Node, sim_tick: int) -> Dictionary:
	if is_ghost:
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }
	if not is_instance_valid(ball):
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }

	var ball_pos: Vector2 = ball.global_position if "global_position" in ball else (ball.position if "position" in ball else Vector2.ZERO)
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

func _draw() -> void:
	# Draw module background chassis connecting cells
	var half_w: float = (CELL_WIDTH - 4.0) * 0.5
	var half_h: float = (CELL_HEIGHT - 4.0) * 0.5
	var bg_col: Color = _accent_color.darkened(0.85)
	var border_col: Color = _accent_color.darkened(0.3)

	for c in _anchored_cells:
		var center := Vector2(float(c.x) * CELL_WIDTH, float(c.y) * CELL_HEIGHT)
		var cell_rect := Rect2(center.x - half_w, center.y - half_h, half_w * 2.0, half_h * 2.0)
		draw_rect(cell_rect, bg_col)
		draw_rect(cell_rect, border_col, false, 2.0)

	# Draw connection struts between adjacent cells in module
	for i in range(_anchored_cells.size()):
		for j in range(i + 1, _anchored_cells.size()):
			var c1: Vector2i = _anchored_cells[i]
			var c2: Vector2i = _anchored_cells[j]
			var dist: int = abs(c1.x - c2.x) + abs(c1.y - c2.y)
			if dist == 1:
				var p1 := Vector2(float(c1.x) * CELL_WIDTH, float(c1.y) * CELL_HEIGHT)
				var p2 := Vector2(float(c2.x) * CELL_WIDTH, float(c2.y) * CELL_HEIGHT)
				draw_line(p1, p2, border_col.lightened(0.2), 6.0)
