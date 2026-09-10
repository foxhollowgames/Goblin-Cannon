extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const CellType = PolyominoModuleData.CellType
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const GuideTrackScript = preload("res://scenes/board/machinery/guide_track.gd")
const BallTrapScript = preload("res://scenes/board/machinery/ball_trap.gd")
const ScoopSinkholeScript = BallTrapScript
const BallLockScript = preload("res://scenes/board/machinery/ball_lock.gd")
const PopBumperScript = preload("res://scenes/board/machinery/pop_bumper.gd")
const BallScript = preload("res://scenes/balls/ball.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

func _init() -> void:
	suite_name = "RelicMachineryTriggerSafeguards"

func run() -> void:
	test_continuous_contact_debounce_in_module_node()
	test_guide_track_active_guiding_suppression()
	test_guide_track_reentry_cooldown_on_fall_down()
	test_ball_trap_capture_and_ejection_debounce()
	test_ball_lock_held_suppression_and_release_debounce()
	test_contact_exit_and_cooldown_allows_subsequent_hit()

var _next_mock_ball_id: int = 400

func _create_mock_ball(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO, start_energy: int = 10) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.set_script(BallScript)
	ball._ready()
	_next_mock_ball_id += 1
	ball.set_ball_id(_next_mock_ball_id)
	ball.position = pos
	ball.linear_velocity = vel
	ball.set_total_energy_display(start_energy)
	return ball

func _create_test_module(cell_type_to_spawn: int) -> PolyominoModuleNode:
	var mdata := PolyominoModuleData.new()
	mdata.cells = [Vector2i(0, 0)]
	mdata.cell_types[Vector2i(0, 0)] = cell_type_to_spawn
	var item := JunkBoxItem.new()
	item.module_data = mdata
	var node: PolyominoModuleNode = PolyominoModuleNodeScript.new()
	node.setup_module(item, Vector2i.ZERO, 0)
	return node

func test_continuous_contact_debounce_in_module_node() -> void:
	begin("Continuous contact triggers only once until ball exits contact")
	var node := _create_test_module(CellType.POP_BUMPER)
	autofree(node)
	node.position = Vector2(100, 100)

	var target_pos: Vector2 = node.position + node._components[0].position
	var ball := _create_mock_ball(target_pos, Vector2.ZERO, 0)
	autofree(ball)

	# First contact tick: activates
	var res1: Dictionary = node.check_ball_collision(ball, 10)
	assert_true(res1.get("activated", false), "First contact tick activates pop bumper")
	assert_eq(res1.get("energy_granted", 0), 1, "Pop bumper awards 1 energy")

	# Subsequent tick in continuous contact (tick 11): must NOT activate
	var res2: Dictionary = node.check_ball_collision(ball, 11)
	assert_false(res2.get("activated", false), "Tick 11 in continuous contact is rejected")

	# Subsequent tick > 3 ticks later in continuous contact (tick 14): must NOT activate
	var res3: Dictionary = node.check_ball_collision(ball, 14)
	assert_false(res3.get("activated", false), "Tick 14 in continuous contact is rejected")

	# Subsequent tick 20 ticks later in continuous contact (tick 30): must NOT activate
	var res4: Dictionary = node.check_ball_collision(ball, 30)
	assert_false(res4.get("activated", false), "Tick 30 in continuous contact is rejected")

func test_guide_track_active_guiding_suppression() -> void:
	begin("GuideTrack suppresses activations while ball is being guided")
	var track: GuideTrack = autofree(GuideTrackScript.new())
	track.position = Vector2(50, 50)
	var ball := autofree(_create_mock_ball(Vector2(50, 50), Vector2(0, 50), 0))

	var res1: Dictionary = track.trigger_activation(ball, 10)
	assert_true(res1.get("activated", false), "GuideTrack initial activation succeeds")
	assert_eq(res1.get("energy_granted", 0), 8, "GuideTrack grants 8 energy")

	# While actively guided, repeat activation must be rejected
	var res2: Dictionary = track.trigger_activation(ball, 11)
	assert_false(res2.get("activated", false), "Tick 11 rejected while ball is guided")

	var res3: Dictionary = track.trigger_activation(ball, 14)
	assert_false(res3.get("activated", false), "Tick 14 rejected while ball is guided")

func test_guide_track_reentry_cooldown_on_fall_down() -> void:
	begin("GuideTrack exit cooldown prevents re-activation when ball falls back down")
	var track: GuideTrack = autofree(GuideTrackScript.new())
	track.position = Vector2(0, 0)
	var ball := autofree(_create_mock_ball(Vector2(0, 0), Vector2(0, -100), 0))
	var bid: int = ball.get_ball_id()

	# Enter track at tick 10
	var res1: Dictionary = track.trigger_activation(ball, 10)
	assert_true(res1.get("activated", false), "Ball enters track")

	# Simulate ball reaching exit at tick 30
	track.record_ball_exit(bid, 30)

	# Ball shoots up, peaks, and falls back down through track origin at tick 50 (diff = 20 < 75)
	var res_fall: Dictionary = track.trigger_activation(ball, 50)
	assert_false(res_fall.get("activated", false), "Falling back down through rail is blocked by exit cooldown")

	# At tick 110 (diff = 80 > 75), new hit is accepted
	var res_later: Dictionary = track.trigger_activation(ball, 110)
	assert_true(res_later.get("activated", false), "Ball can re-enter track after exit cooldown expires")

func test_ball_trap_capture_and_ejection_debounce() -> void:
	begin("BallTrap suppresses repeat activations while ball is captured")
	var trap: BallTrap = autofree(BallTrapScript.new())
	trap.position = Vector2(0, 0)
	var ball := autofree(_create_mock_ball(Vector2(0, 0), Vector2.ZERO, 0))
	var bid: int = ball.get_ball_id()

	var res1: Dictionary = trap.trigger_activation(ball, 10)
	assert_true(res1.get("activated", false), "BallTrap captures ball at tick 10")

	# While held in trap at tick 15 and tick 25
	var res2: Dictionary = trap.trigger_activation(ball, 15)
	assert_false(res2.get("activated", false), "BallTrap blocks tick 15 while held")

	var res3: Dictionary = trap.trigger_activation(ball, 25)
	assert_false(res3.get("activated", false), "BallTrap blocks tick 25 while held")

	# Eject ball and record exit at tick 40
	trap.record_ball_exit(bid, 40)

	# Immediate re-entry attempt at tick 50 (diff = 10 < 45)
	var res_reentry: Dictionary = trap.trigger_activation(ball, 50)
	assert_false(res_reentry.get("activated", false), "Immediate re-entry after ejection is blocked")

	# After cooldown at tick 90 (diff = 50 > 45)
	var res_after: Dictionary = trap.trigger_activation(ball, 90)
	assert_true(res_after.get("activated", false), "Re-capture accepted after cooldown expires")

func test_ball_lock_held_suppression_and_release_debounce() -> void:
	begin("BallLock suppresses repeat activations while ball is locked")
	var lock: BallLock = autofree(BallLockScript.new())
	lock.position = Vector2(0, 0)
	var ball := autofree(_create_mock_ball(Vector2(0, 0), Vector2.ZERO, 0))
	var bid: int = ball.get_ball_id()

	var res1: Dictionary = lock.trigger_activation(ball, 10)
	assert_true(res1.get("activated", false), "Ball locked at tick 10")

	var res2: Dictionary = lock.trigger_activation(ball, 15)
	assert_false(res2.get("activated", false), "Ball lock blocks repeat activation while locked")

	# Release ball at tick 30
	lock.record_ball_exit(bid, 30)

	# Ejected ball passing through at tick 40 (diff = 10 < 45)
	var res3: Dictionary = lock.trigger_activation(ball, 40)
	assert_false(res3.get("activated", false), "Immediate re-locking is blocked by release cooldown")

	# After cooldown at tick 80 (diff = 50 > 45)
	var res4: Dictionary = lock.trigger_activation(ball, 80)
	assert_true(res4.get("activated", false), "Lock accepts ball after release cooldown expires")

func test_contact_exit_and_cooldown_allows_subsequent_hit() -> void:
	begin("Ball that exits contact can trigger component again after cooldown")
	var node := _create_test_module(CellType.POP_BUMPER)
	autofree(node)
	node.position = Vector2(0, 0)

	var target_pos: Vector2 = node.position + node._components[0].position
	var ball := _create_mock_ball(target_pos, Vector2.ZERO, 0)
	autofree(ball)

	# First hit at tick 10
	var res1: Dictionary = node.check_ball_collision(ball, 10)
	assert_true(res1.get("activated", false), "Hit 1 at tick 10 succeeds")

	# Ball moves away from module to (200, 200) at tick 12
	ball.position = Vector2(200, 200)
	var res_exit: Dictionary = node.check_ball_collision(ball, 12)
	assert_false(res_exit.get("activated", false), "Ball outside module does not hit")

	# Ball returns to module at tick 15 (diff = 5 ticks >= 3)
	ball.position = target_pos
	var res2: Dictionary = node.check_ball_collision(ball, 15)
	assert_true(res2.get("activated", false), "Hit 2 succeeds after clean contact exit and cooldown expiry")
