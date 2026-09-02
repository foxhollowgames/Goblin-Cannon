extends "res://tests/test_base.gd"

const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const GuideTrackScript = preload("res://scenes/board/machinery/guide_track.gd")
const VerticalUpKickerScript = preload("res://scenes/board/machinery/vertical_up_kicker.gd")
const OutlaneKickbackScript = preload("res://scenes/board/machinery/outlane_kickback.gd")
const ScoopSinkholeScript = preload("res://scenes/board/machinery/scoop_sinkhole.gd")
const BallLockScript = preload("res://scenes/board/machinery/ball_lock.gd")
const MechanicalDiverterScript = preload("res://scenes/board/machinery/mechanical_diverter.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

func _init() -> void:
	suite_name = "RelicMachineryRotation"

func run() -> void:
	test_guide_track_rotation()
	test_kicker_rotation()
	test_outlane_kickback_rotation()
	test_scoop_sinkhole_rotation()
	test_ball_lock_rotation()
	test_mechanical_diverter_rotation()
	test_polyomino_module_node_rebuild_rotations()

func test_guide_track_rotation() -> void:
	begin("GuideTrack exit_offset transforms across 0, 90, 180, and 270 degree rotation steps")
	var track = autofree(GuideTrackScript.new()) as GuideTrack
	
	track.direction = Vector2(0, -1) # 0 deg (UP)
	assert_eq(track.exit_offset, Vector2(0, -80), "Rotation 0: exit_offset is Vector2(0, -80)")
	
	track.direction = Vector2(1, 0) # 90 deg (RIGHT)
	assert_eq(track.exit_offset, Vector2(80, 0), "Rotation 1: exit_offset is Vector2(80, 0)")
	
	track.direction = Vector2(0, 1) # 180 deg (DOWN)
	assert_eq(track.exit_offset, Vector2(0, 80), "Rotation 2: exit_offset is Vector2(0, 80)")
	
	track.direction = Vector2(-1, 0) # 270 deg (LEFT)
	assert_eq(track.exit_offset, Vector2(-80, 0), "Rotation 3: exit_offset is Vector2(-80, 0)")

func test_kicker_rotation() -> void:
	begin("VerticalUpKicker launch_direction and impulse vector match component direction")
	var kicker = autofree(VerticalUpKickerScript.new()) as VerticalUpKicker
	
	var dirs: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	for d in dirs:
		kicker.direction = d
		assert_eq(kicker.launch_direction, d, "Launch direction matches component direction %s" % str(d))
		var impulse: Vector2 = kicker._compute_impulse(null)
		assert_eq(impulse, d * kicker.impulse_strength, "Impulse vector matches rotated direction")

func test_outlane_kickback_rotation() -> void:
	begin("OutlaneKickback impulse vector transforms across 0, 90, 180, and 270 degree rotation steps")
	var kickback = autofree(OutlaneKickbackScript.new()) as OutlaneKickback
	
	var dirs: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	for d in dirs:
		kickback.direction = d
		var impulse: Vector2 = kickback._compute_impulse(null)
		assert_eq(impulse, d * kickback.impulse_strength, "Outlane kickback impulse matches rotated direction %s" % str(d))

func test_scoop_sinkhole_rotation() -> void:
	begin("ScoopSinkhole eject_direction transforms across rotation steps")
	var scoop = autofree(ScoopSinkholeScript.new()) as ScoopSinkhole
	
	var dirs: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	for d in dirs:
		scoop.direction = d
		assert_eq(scoop.eject_direction, d, "Eject direction matches rotated direction %s" % str(d))

func test_ball_lock_rotation() -> void:
	begin("BallLock impulse vector transforms across rotation steps")
	var lock = autofree(BallLockScript.new()) as BallLock
	
	var dirs: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	for d in dirs:
		lock.direction = d
		var impulse: Vector2 = lock._compute_impulse(null)
		assert_eq(impulse, d * lock.eject_impulse_strength, "Ball lock impulse matches rotated direction %s" % str(d))

func test_mechanical_diverter_rotation() -> void:
	begin("MechanicalDiverter impulse vector transforms perpendicularly relative to component direction")
	var diverter = autofree(MechanicalDiverterScript.new()) as MechanicalDiverter
	
	# DOWN direction (0, 1) -> open diverts left (1, 0), closed diverts right (-1, 0)
	diverter.direction = Vector2(0, 1)
	diverter.is_open = true
	assert_eq(diverter._compute_impulse(null), Vector2(1, 0) * diverter.impulse_strength, "Diverter open impulse for DOWN direction")
	diverter.is_open = false
	assert_eq(diverter._compute_impulse(null), Vector2(-1, 0) * diverter.impulse_strength, "Diverter closed impulse for DOWN direction")
	
	# RIGHT direction (1, 0) -> open diverts up (0, -1), closed diverts down (0, 1)
	diverter.direction = Vector2(1, 0)
	diverter.is_open = true
	assert_eq(diverter._compute_impulse(null), Vector2(0, -1) * diverter.impulse_strength, "Diverter open impulse for RIGHT direction")
	diverter.is_open = false
	assert_eq(diverter._compute_impulse(null), Vector2(0, 1) * diverter.impulse_strength, "Diverter closed impulse for RIGHT direction")

func test_polyomino_module_node_rebuild_rotations() -> void:
	begin("PolyominoModuleNode setup_module instantiates components with rotated direction vectors")
	var mod_data = PolyominoModuleData.new()
	mod_data.cells = [Vector2i.ZERO]
	mod_data.cell_types[Vector2i.ZERO] = PolyominoModuleData.CellType.GUIDE_TRACK
	mod_data.cell_directions[Vector2i.ZERO] = Vector2i(0, -1) # UP
	
	var item = JunkBoxItem.new(&"test_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data
	
	var node = autofree(PolyominoModuleNodeScript.new()) as PolyominoModuleNode
	
	# Rotation 0 (0 deg) -> (0, -1)
	node.setup_module(item, Vector2i.ZERO, 0)
	var comps: Array = node.get_all_components()
	assert_eq(comps.size(), 1, "Module has 1 component")
	assert_eq(comps[0].direction, Vector2(0, -1), "Rotation 0: direction is (0, -1)")
	
	# Rotation 1 (90 deg CW) -> (1, 0)
	node.setup_module(item, Vector2i.ZERO, 1)
	comps = node.get_all_components()
	assert_eq(comps[0].direction, Vector2(1, 0), "Rotation 1: direction is (1, 0)")
	
	# Rotation 2 (180 deg CW) -> (0, 1)
	node.setup_module(item, Vector2i.ZERO, 2)
	comps = node.get_all_components()
	assert_eq(comps[0].direction, Vector2(0, 1), "Rotation 2: direction is (0, 1)")
	
	# Rotation 3 (270 deg CW) -> (-1, 0)
	node.setup_module(item, Vector2i.ZERO, 3)
	comps = node.get_all_components()
	assert_eq(comps[0].direction, Vector2(-1, 0), "Rotation 3: direction is (-1, 0)")
