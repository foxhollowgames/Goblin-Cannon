class_name GameCoordinatorSignals
extends Node
## Signal wiring and event dispatcher helper for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
#endregion

#region Initialization
## Initializes signals manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root

## Wires GameCoordinator child signals to event handler methods on coordinator.
static func wire_signals(c: Node) -> void:
	if c._hopper and c._hopper.has_signal("ball_entered_board"):
		c._hopper.ball_entered_board.connect(c._on_ball_entered_board)
	if c._board:
		if c._board.has_signal("ball_reached_bottom"):
			c._board.ball_reached_bottom.connect(c._on_ball_reached_bottom)
		if c._board.has_signal("ball_ability_on_peg_hit"):
			c._board.ball_ability_on_peg_hit.connect(c._on_ball_ability_on_peg_hit)
		if c._board.has_signal("ball_exited_board"):
			c._board.ball_exited_board.connect(c._on_ball_exited_board)
		if c._board.has_signal("leech_drain"):
			c._board.leech_drain.connect(c._on_leech_drain)
		if c._board.has_signal("gold_gained"):
			c._board.gold_gained.connect(c._on_gold_gained)
	if c._milestone_tracker and c._milestone_tracker.has_signal("milestone_reached"):
		c._milestone_tracker.milestone_reached.connect(c._on_milestone_reached)
	if c._combat_manager:
		if c._combat_manager.has_signal("wall_destroyed"):
			c._combat_manager.wall_destroyed.connect(c._on_wall_destroyed)
		if c._combat_manager.has_signal("time_expired"):
			c._combat_manager.time_expired.connect(c._on_time_expired)
	if c._rewards_manager and c._rewards_manager.has_signal("wall_break_reward_completed"):
		c._rewards_manager.wall_break_reward_completed.connect(c._on_wall_break_reward_completed)
	if c._rewards_manager and c._rewards_manager.has_signal("boss_reward_completed"):
		c._rewards_manager.boss_reward_completed.connect(c._on_boss_reward_completed)
	if c._energy_router and c._energy_router.has_signal("energy_allocated"):
		c._energy_router.energy_allocated.connect(c._on_energy_allocated_vfx)
	if c._battlefield and c._battlefield.has_method("set_main_cannon"):
		var mc: Node = c._systems_container.get_node_or_null("MainCannon") if c._systems_container else null
		c._battlefield.set_main_cannon(mc)

## Disconnects GameCoordinator child signals.
static func disconnect_signals(c: Node) -> void:
	if c._hopper and c._hopper.has_signal("ball_entered_board") and c._hopper.ball_entered_board.is_connected(c._on_ball_entered_board):
		c._hopper.ball_entered_board.disconnect(c._on_ball_entered_board)
	if c._board:
		if c._board.has_signal("ball_reached_bottom") and c._board.ball_reached_bottom.is_connected(c._on_ball_reached_bottom):
			c._board.ball_reached_bottom.disconnect(c._on_ball_reached_bottom)
		if c._board.has_signal("ball_ability_on_peg_hit") and c._board.ball_ability_on_peg_hit.is_connected(c._on_ball_ability_on_peg_hit):
			c._board.ball_ability_on_peg_hit.disconnect(c._on_ball_ability_on_peg_hit)
		if c._board.has_signal("ball_exited_board") and c._board.ball_exited_board.is_connected(c._on_ball_exited_board):
			c._board.ball_exited_board.disconnect(c._on_ball_exited_board)
		if c._board.has_signal("leech_drain") and c._board.leech_drain.is_connected(c._on_leech_drain):
			c._board.leech_drain.disconnect(c._on_leech_drain)
		if c._board.has_signal("gold_gained") and c._board.gold_gained.is_connected(c._on_gold_gained):
			c._board.gold_gained.disconnect(c._on_gold_gained)
	if c._milestone_tracker and c._milestone_tracker.has_signal("milestone_reached") and c._milestone_tracker.milestone_reached.is_connected(c._on_milestone_reached):
		c._milestone_tracker.milestone_reached.disconnect(c._on_milestone_reached)
	if c._combat_manager:
		if c._combat_manager.has_signal("wall_destroyed") and c._combat_manager.wall_destroyed.is_connected(c._on_wall_destroyed):
			c._combat_manager.wall_destroyed.disconnect(c._on_wall_destroyed)
		if c._combat_manager.has_signal("time_expired") and c._combat_manager.time_expired.is_connected(c._on_time_expired):
			c._combat_manager.time_expired.disconnect(c._on_time_expired)
	if c._rewards_manager and c._rewards_manager.has_signal("wall_break_reward_completed") and c._rewards_manager.wall_break_reward_completed.is_connected(c._on_wall_break_reward_completed):
		c._rewards_manager.wall_break_reward_completed.disconnect(c._on_wall_break_reward_completed)
	if c._rewards_manager and c._rewards_manager.has_signal("boss_reward_completed") and c._rewards_manager.boss_reward_completed.is_connected(c._on_boss_reward_completed):
		c._rewards_manager.boss_reward_completed.disconnect(c._on_boss_reward_completed)
	if c._energy_router and c._energy_router.has_signal("energy_allocated") and c._energy_router.energy_allocated.is_connected(c._on_energy_allocated_vfx):
		c._energy_router.energy_allocated.disconnect(c._on_energy_allocated_vfx)

