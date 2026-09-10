@tool
extends RefCounted
class_name BoardMachineryShowcase
## Builder and layout controller for debug machinery showcase on the Board.

#region Constants and Enums
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

const CellType = PolyominoModuleData.CellType
const MachineryLayoutMode = PolyominoModuleData.MachineryLayoutMode
#endregion

#region Showcase Item Definitions
## Returns dictionary definition list of all machinery permutations and sizes.
static func get_all_showcase_definitions() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	defs.append_array(_get_multi_cell_definitions())
	defs.append_array(_get_impulser_definitions())
	defs.append_array(_get_directional_definitions())
	defs.append_array(_get_target_trap_definitions())
	defs.append_array(_get_sensor_route_definitions())
	return defs

static func _get_multi_cell_definitions() -> Array[Dictionary]:
	var giga: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)
	]
	var box: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	var corner: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	return [
		_item_def(&"debug_giga_pop_bumper", "Giga Pop Bumper (3x3)", Vector2i(0, 0), giga, MachineryLayoutMode.UNIFIED, CellType.POP_BUMPER, {}, {}, "Active Impulser", "Massive 3x3 kinetic dome. Repels balls with tremendous radial velocity across the playfield upon contact, emitting concussive shockwaves and granting heavy energy.", {"Classification": "Active Impulser", "Footprint": "3x3 (9 Cells)", "Energy": "+50 Energy", "Impulse": "850 px/s (Radial)", "Radius": "76px"}),
		_item_def(&"debug_mega_pop_bumper", "Mega Pop Bumper (2x2)", Vector2i(3, 0), box, MachineryLayoutMode.UNIFIED, CellType.POP_BUMPER, {}, {}, "Active Impulser", "Unified 4-peg heavy pop bumper. Repels balls with strong 360-degree radial impulse on impact, triggering spring compression and awarding 20 energy.", {"Classification": "Active Impulser", "Footprint": "2x2 (4 Cells)", "Energy": "+20 Energy", "Impulse": "650 px/s (Radial)", "Radius": "48px"}),
		_item_def(&"debug_abyssal_maw", "Abyssal Maw Sinkhole (2x2)", Vector2i(3, 2), box, MachineryLayoutMode.UNIFIED, CellType.SCOOP_SINKHOLE, {}, {}, "Trap", "Multi-ball vortex sinkhole. Traps multiple passing balls simultaneously, holds them for charging, then ejects them in a violent outward volley.", {"Classification": "Trap", "Footprint": "2x2 (4 Cells)", "Energy": "+25 Energy", "Impulse": "480 px/s (Volley Eject)", "Hold Time": "0.85s"}),
		_item_def(&"debug_golem_effigy", "Golem Effigy Bash Toy (2x2)", Vector2i(0, 3), box, MachineryLayoutMode.UNIFIED, CellType.BASH_TOY, {}, {}, "Target", "Unified 4-peg stone boss statue. Takes 8 hits with progressive comic wobble and crack VFX before shattering in a massive shockwave.", {"Classification": "Target", "Footprint": "2x2 (4 Cells)", "Energy": "+15 Hit / +40 Shatter", "Impulse": "350 px/s (Wobble)", "Hits to Shatter": "8"}),
		_item_def(&"debug_corner_slingshot", "Corner Slingshot Kicker (3-Peg L)", Vector2i(0, 5), corner, MachineryLayoutMode.UNIFIED, CellType.SLINGSHOT, {}, {}, "Active Impulser", "Unified diagonal corner kicker rubber. Detects lateral ball contact along its angled band and punches balls away with high normal-vector impulse.", {"Classification": "Active Impulser", "Footprint": "3-Peg L-Shape", "Energy": "+12 Energy", "Impulse": "550 px/s (Normal Band)"})
	]

static func _get_impulser_definitions() -> Array[Dictionary]:
	return [
		_single_def(&"debug_pop_bumper_1x1", "Pop Bumper (1x1)", Vector2i(5, 0), CellType.POP_BUMPER, Vector2i.ZERO, "Active Impulser", "Repels steel ball with high velocity in 360-degree radial directions upon collision. Triggers comic spring compression and radial spark bursts.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+1 Energy", "Impulse": "450 px/s (Radial)", "Radius": "20px"}),
		_single_def(&"debug_pinball_bumper_1x1", "Pinball Bumper (1x1)", Vector2i(5, 1), CellType.BUMPER, Vector2i.ZERO, "Active Impulser", "Solid circular contact bumper. Knocks colliding balls away with elastic rebound velocity upon impact.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+3 Energy", "Impulse": "400 px/s (Radial)", "Radius": "18px"}),
		_single_def(&"debug_slingshot_1x1", "Slingshot Kicker (1x1)", Vector2i(5, 2), CellType.SLINGSHOT, Vector2i.ZERO, "Active Impulser", "Triangular elastic kicker rubber backed by powerful solenoid arm. Kicks ball violently across playfield at sharp rebound angles.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+6 Energy", "Impulse": "420 px/s (Angled)"}),
		_single_def(&"debug_vertical_up_kicker_1x1", "Vertical Up Kicker (1x1)", Vector2i(5, 3), CellType.VERTICAL_UP_KICKER, Vector2i.UP, "Active Impulser", "Subterranean solenoid cup beneath board. Traps ball from lower level, then launches it straight upward against gravity into upper playfields.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+10 Energy", "Impulse": "520 px/s (Vertical Up)"})
	]

static func _get_directional_definitions() -> Array[Dictionary]:
	return [
		_single_def(&"debug_speed_wheel_down", "Speed Boost Wheel (Down)", Vector2i(6, 0), CellType.ACCELERATOR, Vector2i.DOWN, "Active Impulser", "Dual motorized flywheels spinning at high RPM. Grips incoming balls and accelerates them downward with immediate velocity boost.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+5 Energy", "Impulse": "400 px/s (Accelerate)", "Direction": "DOWN"}),
		_single_def(&"debug_speed_wheel_up", "Speed Boost Wheel (Up)", Vector2i(6, 1), CellType.ACCELERATOR, Vector2i.UP, "Active Impulser", "Dual motorized flywheels spinning at high RPM. Grips incoming balls and launches them upward with immediate velocity boost.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+5 Energy", "Impulse": "400 px/s (Accelerate)", "Direction": "UP"}),
		_single_def(&"debug_speed_wheel_left", "Speed Boost Wheel (Left)", Vector2i(6, 2), CellType.ACCELERATOR, Vector2i.LEFT, "Active Impulser", "Dual motorized flywheels spinning at high RPM. Grips incoming balls and propels them westward across the lane with immediate velocity boost.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+5 Energy", "Impulse": "400 px/s (Accelerate)", "Direction": "LEFT"}),
		_single_def(&"debug_speed_wheel_right", "Speed Boost Wheel (Right)", Vector2i(6, 3), CellType.ACCELERATOR, Vector2i.RIGHT, "Active Impulser", "Dual motorized flywheels spinning at high RPM. Grips incoming balls and propels them eastward across the lane with immediate velocity boost.", {"Classification": "Active Impulser", "Footprint": "1x1 (1 Cell)", "Energy": "+5 Energy", "Impulse": "400 px/s (Accelerate)", "Direction": "RIGHT"})
	]

static func _get_target_trap_definitions() -> Array[Dictionary]:
	return [
		_single_def(&"debug_drop_target_1x1", "Drop Target (1x1)", Vector2i(8, 0), CellType.DROP_TARGET, Vector2i.ZERO, "Target", "Solid rectangular target plate that retracts flush into board on impact. Becomes permeable until entire bank drops.", {"Classification": "Target", "Footprint": "1x1 (1 Cell)", "Energy": "+5 Energy", "Impulse": "0 px/s (Retracts Flush)"}),
		_single_def(&"debug_captive_ball_1x1", "Captive Ball (1x1)", Vector2i(8, 2), CellType.CAPTIVE_BALL, Vector2i.ZERO, "Target", "Trapped chrome ball in short linear channel. Impact transfers kinetic momentum through trapped sphere into internal target switch.", {"Classification": "Target", "Footprint": "1x1 (1 Cell)", "Energy": "+7 Energy", "Impulse": "Momentum Transfer"}),
		_single_def(&"debug_bash_toy_1x1", "Bash Toy (1x1)", Vector2i(8, 3), CellType.BASH_TOY, Vector2i.ZERO, "Target", "Durable mechanical sculpture (Goblin Totem). Takes multiple hits with progressive comic wobble and crack VFX before triggering shockwave.", {"Classification": "Target", "Footprint": "1x1 (1 Cell)", "Energy": "+10 Energy", "Impulse": "300 px/s (Wobble)"}),
		_single_def(&"debug_scoop_sinkhole_1x1", "Scoop Sinkhole (1x1)", Vector2i(9, 0), CellType.SCOOP_SINKHOLE, Vector2i.ZERO, "Trap", "Recessed circular hole bordered by steel rim. Captures ball, stops physics temporarily for 0.85s, charges energy, then violently ejects ball outward.", {"Classification": "Trap", "Footprint": "1x1 (1 Cell)", "Energy": "+10 Energy", "Impulse": "420 px/s (Eject)", "Hold Time": "0.85s"}),
		_single_def(&"debug_ball_lock_1x1", "Ball Lock (1x1)", Vector2i(9, 1), CellType.BALL_LOCK, Vector2i.ZERO, "Trap", "Subterranean mechanical magazine capable of storing up to 3 balls. Traps successive balls from play until 3 locks release a multiball cascade.", {"Classification": "Trap", "Footprint": "1x1 (1 Cell)", "Energy": "+12 Energy", "Impulse": "450 px/s (Cascade Release)", "Capacity": "3 Balls"}),
		_single_def(&"debug_orbit_loop_1x1", "Orbit Loop (1x1)", Vector2i(9, 2), CellType.ORBIT_LOOP, Vector2i.ZERO, "Route", "Curved outer perimeter channel. High-velocity shots enter loop, sweep 180 degrees around outer curve, and exit with 25% amplified momentum.", {"Classification": "Route", "Footprint": "1x1 (1 Cell)", "Energy": "+6 Energy", "Impulse": "1.25x Speed Multiplier"})
	]

static func _get_sensor_route_definitions() -> Array[Dictionary]:
	return [
		_single_def(&"debug_spinner_1x1", "Spinner (1x1)", Vector2i(10, 0), CellType.SPINNER, Vector2i.ZERO, "Sensor", "Hinged axle plate suspended across playfield lane. Balls pass through without stopping, launching spinner into high-rpm rotation.", {"Classification": "Sensor", "Footprint": "1x1 (1 Cell)", "Energy": "+3 per spin", "Impulse": "0 px/s (Pass-Through)"}),
		_single_def(&"debug_rollover_switch_1x1", "Rollover Switch (1x1)", Vector2i(10, 1), CellType.ROLLOVER_SWITCH, Vector2i.ZERO, "Sensor", "Recessed wire switch arm extending through floor. Ball rolls over switch without deceleration, registering lane contact.", {"Classification": "Sensor", "Footprint": "1x1 (1 Cell)", "Energy": "+2 Energy", "Impulse": "0 px/s (Pass-Through)"}),
		_single_def(&"debug_wire_gate_1x1", "Wire Gate (1x1)", Vector2i(10, 3), CellType.WIRE_GATE, Vector2i.ZERO, "Sensor", "Hinged wire gate hanging across ramps. Allows forward passage smoothly, then drops down to prevent backward drainage.", {"Classification": "Sensor", "Footprint": "1x1 (1 Cell)", "Energy": "+2 Energy", "Impulse": "One-Way Pass"}),
		_single_def(&"debug_diverter_left", "Mechanical Diverter (Left)", Vector2i(10, 4), CellType.MECHANICAL_DIVERTER, Vector2i.LEFT, "Route", "Solenoid-actuated gate flapper situated at track splits. Routes balls left and alternates orientation after every contact.", {"Classification": "Route", "Footprint": "1x1 (1 Cell)", "Energy": "+4 Energy", "Impulse": "Directional Deflect", "Direction": "LEFT"}),
		_single_def(&"debug_diverter_right", "Mechanical Diverter (Right)", Vector2i(10, 5), CellType.MECHANICAL_DIVERTER, Vector2i.RIGHT, "Route", "Solenoid-actuated gate flapper situated at track splits. Routes balls right and alternates orientation after every contact.", {"Classification": "Route", "Footprint": "1x1 (1 Cell)", "Energy": "+4 Energy", "Impulse": "Directional Deflect", "Direction": "RIGHT"}),
		_single_def(&"debug_guide_track_vert", "Guide Track (Vertical)", Vector2i(10, 6), CellType.GUIDE_TRACK, Vector2i.DOWN, "Route", "Parallel stainless steel wire rails. Constrains incoming balls to linear vertical trajectory with zero lateral drift and boosted speed.", {"Classification": "Route", "Footprint": "1x1 (1 Cell)", "Energy": "+4 Energy", "Impulse": "380 px/s (Constrained)", "Direction": "VERTICAL"}),
		_single_def(&"debug_guide_track_horiz", "Guide Track (Horizontal)", Vector2i(10, 7), CellType.GUIDE_TRACK, Vector2i.RIGHT, "Route", "Parallel stainless steel wire rails. Constrains incoming balls to linear horizontal trajectory with zero lateral drift and boosted speed.", {"Classification": "Route", "Footprint": "1x1 (1 Cell)", "Energy": "+4 Energy", "Impulse": "380 px/s (Constrained)", "Direction": "HORIZONTAL"})
	]

static func _item_def(id: StringName, name: String, pos: Vector2i, cells: Array[Vector2i], layout: int, u_type: int, c_types: Dictionary, c_dirs: Dictionary, cat: String, beh: String, stats: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"grid_pos": pos,
		"cells": cells,
		"layout_mode": layout,
		"unified_type": u_type,
		"cell_types": c_types,
		"cell_dirs": c_dirs,
		"category": cat,
		"behavior": beh,
		"stats": stats
	}

static func _single_def(id: StringName, name: String, pos: Vector2i, type: int, dir: Vector2i, cat: String, beh: String, stats: Dictionary) -> Dictionary:
	var single: Array[Vector2i] = [Vector2i.ZERO]
	var c_types: Dictionary = {Vector2i.ZERO: type}
	var c_dirs: Dictionary = {Vector2i.ZERO: dir} if dir != Vector2i.ZERO else {}
	return _item_def(id, name, pos, single, MachineryLayoutMode.PER_CELL, CellType.EMPTY, c_types, c_dirs, cat, beh, stats)
#endregion

#region Item Construction & Tooltips
## Builds a JunkBoxItem instance configured for the specified showcase definition.
static func create_showcase_item(def: Dictionary) -> JunkBoxItem:
	var mod := PolyominoModuleData.new()
	mod.module_id = StringName(str(def["id"]))
	mod.display_name = str(def["name"])
	mod.tier = 3
	mod.cells = def["cells"]
	mod.layout_mode = int(def.get("layout_mode", MachineryLayoutMode.PER_CELL))
	mod.unified_component_type = int(def.get("unified_type", CellType.EMPTY))
	mod.cell_types = def.get("cell_types", {})
	mod.cell_directions = def.get("cell_dirs", {})

	var item := JunkBoxItem.new(mod.module_id, JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = mod.display_name
	item.module_data = mod
	item.custom_payload = {
		"is_debug_showcase": true,
		"relic_id": str(def["id"]),
		"category": str(def["category"]),
		"behavior": str(def["behavior"]),
		"stats": def["stats"]
	}
	return item

## Formats detailed mouse-over tooltip body for debug showcase items.
static func format_tooltip(item: JunkBoxItem) -> String:
	var body: String = ""
	var behavior: String = str(item.custom_payload.get("behavior", ""))
	if not behavior.is_empty():
		body += "[u]Behavior[/u]\n%s" % behavior

	var stats: Dictionary = item.custom_payload.get("stats", {})
	if not stats.is_empty():
		if not body.is_empty():
			body += "\n\n"
		body += "[u]Stats[/u]"
		for key in stats:
			body += "\n• [b]%s[/b]: %s" % [str(key), str(stats[key])]
	return body
#endregion

#region Board Population
## Clears current modules and populates the board with all showcase machinery items.
static func populate_showcase_on_board(board: Node) -> int:
	if board == null:
		return 0
	if board.has_method("clear_all_placed_modules"):
		board.clear_all_placed_modules()

	var defs: Array[Dictionary] = get_all_showcase_definitions()
	var placed_count: int = 0
	for def in defs:
		var item: JunkBoxItem = create_showcase_item(def)
		var target_pos: Vector2i = def["grid_pos"]
		var success: bool = false
		if board.has_method("place_module"):
			success = board.place_module(item, target_pos, 0)
		if success:
			placed_count += 1
		else:
			push_warning("BoardMachineryShowcase: Failed to place %s at %s" % [item.display_name, str(target_pos)])
	return placed_count
#endregion
