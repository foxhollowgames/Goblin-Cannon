extends Node
## Ball inventory tracking, ability assignment, and catalog lookups for GameCoordinator.

#region Signals
signal ball_ability_converted(ball: Node, new_ability: StringName)
#endregion

#region State and References
var _ball_catalog: Dictionary = {}  ## StringName -> BallDefinition
var _starting_balls: Array = []  ## Array[BallDefinition]
var _coordinator_root: Node = null
#endregion

#region Initialization
## Sets up ball manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

#region Ball Counts and Catalog API
## Returns key for catalog dictionary (e.g. Split|2).
static func catalog_key_from_def(def: BallDefinition) -> String:
	var ab: String = def.ability_name if not def.ability_name.is_empty() else "Plain"
	return "%s|%d" % [ab, def.tier]

## Counts balls in hopper, on board, and in bag queue by ability_name + tier.
static func get_ball_definition_counts(parent_node: Node, hopper: Node, bag_queue: Array) -> Dictionary:
	var counts: Dictionary = {}
	if hopper and hopper.has_method("get_stored_balls"):
		for ball in hopper.get_stored_balls():
			if not is_instance_valid(ball):
				continue
			var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			_accumulate_def_count(counts, def)
	var balls_container: Node = parent_node.get_node_or_null("BallsContainer") if parent_node else null
	if balls_container:
		for ball in balls_container.get_children():
			if not is_instance_valid(ball):
				continue
			if ball.has_method("is_split_twin") and ball.is_split_twin():
				continue
			var def2: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			_accumulate_def_count(counts, def2)
	for def3 in bag_queue:
		_accumulate_def_count(counts, def3)
	return counts

static func _accumulate_def_count(counts: Dictionary, def: Resource) -> void:
	if not def is BallDefinition:
		return
	var d: BallDefinition = def as BallDefinition
	var key: String = catalog_key_from_def(d)
	counts[key] = counts.get(key, 0) + 1
#endregion


#region Ball Catalog API
## Returns the BallDefinition resource for the specified ability name.
func get_ball_definition(ability_name: StringName) -> Resource:
	return _ball_catalog.get(ability_name, null) as Resource

## Returns the starting ball inventory array.
func get_starting_ball_inventory() -> Array:
	return _starting_balls

## Returns all registered ability names in the catalog.
func get_all_ability_names() -> Array:
	return _ball_catalog.keys()

## Converts a ball instance to use a new ability definition.
func convert_ball_ability(ball: Node, new_ability: StringName) -> void:
	if not ball or not is_instance_valid(ball):
		return
	var bdef: Resource = get_ball_definition(new_ability)
	if bdef and ball.has_method("set_ball_definition"):
		ball.set_ball_definition(bdef)
		ball_ability_converted.emit(ball, new_ability)
#region Plain Ball Factories
## Returns a plain ball definition resource for alignment.
static func plain_ball_def(alignment: int) -> BallDefinition:
	var def: BallDefinition = BallDefinition.new()
	def.ability_name = ""
	def.display_name = "Plain Ball"
	def.description = "Standard pinball."
	def.tier = 1
	def.alignment = alignment
	return def

## Returns true if the definition is a plain ball (no ability or "Plain").
## Returns count of active balls grouped by ability.
static func get_ball_inventory(parent_node: Node) -> Dictionary:
	var counts: Dictionary = {}
	var balls_container: Node = parent_node.get_node_or_null("BallsContainer") if parent_node else null
	if not balls_container:
		return counts
	for ball in balls_container.get_children():
		if not is_instance_valid(ball):
			continue
		if ball.has_method("is_split_twin") and ball.is_split_twin():
			continue
		var ball_def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
		var ability: String = "Plain"
		if ball_def is BallDefinition:
			var name_str: String = (ball_def as BallDefinition).ability_name
			ability = name_str if not name_str.is_empty() else "Plain"
		counts[ability] = counts.get(ability, 0) + 1
	return counts

## Removes one ball matching template definition from bag queue, hopper, or board.
static func remove_one_ball_matching_definition(parent_node: Node, hopper: Node, bag_queue: Array, template: BallDefinition) -> bool:
	if not template:
		return false
	var key: String = catalog_key_from_def(template)
	for i in range(bag_queue.size()):
		var d: Variant = bag_queue[i]
		if d is BallDefinition and catalog_key_from_def(d as BallDefinition) == key:
			bag_queue.remove_at(i)
			prune_ball_ability_record_after_remove(parent_node, hopper, bag_queue, key)
			return true
	var match_pred: Callable = func(ball: Node) -> bool:
		var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
		if not def is BallDefinition:
			return false
		return catalog_key_from_def(def as BallDefinition) == key
	if hopper and hopper.has_method("remove_and_destroy_one_stored_ball_if"):
		if hopper.remove_and_destroy_one_stored_ball_if(match_pred):
			prune_ball_ability_record_after_remove(parent_node, hopper, bag_queue, key)
			return true
	var board: Node = parent_node.get_node_or_null("Board") if parent_node else null
	if board and board.has_method("remove_and_destroy_one_ball_if"):
		if board.remove_and_destroy_one_ball_if(match_pred):
			prune_ball_ability_record_after_remove(parent_node, hopper, bag_queue, key)
			return true
	return false

## Removes one ball matching ability key from bag queue, hopper, or board.
static func remove_one_ball_for_ability(parent_node: Node, hopper: Node, bag_queue: Array, ability_ledger_key: String) -> bool:
	var lk: String = ability_ledger_key
	var match_same_ability := func(d: BallDefinition) -> bool:
		var ab: String = d.ability_name if not d.ability_name.is_empty() else "Plain"
		return ab == lk
	for i in range(bag_queue.size()):
		var d: Variant = bag_queue[i]
		if d is BallDefinition and match_same_ability.call(d):
			bag_queue.remove_at(i)
			prune_ball_ability_record_after_remove(parent_node, hopper, bag_queue, lk + "|1")
			return true
	var match_pred: Callable = func(ball: Node) -> bool:
		var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
		if not def is BallDefinition:
			return false
		return match_same_ability.call(def as BallDefinition)
	if hopper and hopper.has_method("remove_and_destroy_one_stored_ball_if"):
		if hopper.remove_and_destroy_one_stored_ball_if(match_pred):
			prune_ball_ability_record_after_remove(parent_node, hopper, bag_queue, lk + "|1")
			return true
	var board: Node = parent_node.get_node_or_null("Board") if parent_node else null
	if board and board.has_method("remove_and_destroy_one_ball_if"):
		if board.remove_and_destroy_one_ball_if(match_pred):
			prune_ball_ability_record_after_remove(parent_node, hopper, bag_queue, lk + "|1")
			return true
	return false

## Erases ability name from GameState run record if no remaining balls of that ability exist.
static func prune_ball_ability_record_after_remove(parent_node: Node, hopper: Node, bag_queue: Array, catalog_key: String) -> void:
	var ability: String = catalog_key.get_slice("|", 0)
	if ability == "Plain":
		return
	var counts: Dictionary = get_ball_definition_counts(parent_node, hopper, bag_queue)
	for k in counts.keys():
		if String(k).begins_with(ability + "|") and int(counts[k]) > 0:
			return
	if GameState and ability in GameState.ball_ability_names_in_run:
		GameState.ball_ability_names_in_run.erase(ability)

## Returns true if the definition is a plain ball (no ability or "Plain").
static func is_plain_ball_def(def: Resource) -> bool:
	if def == null:
		return true
	if def is BallDefinition:
		var bd: BallDefinition = def as BallDefinition
		return bd.ability_name.is_empty() or bd.ability_name == "Plain"
	return false

## Adds plain balls (hopper first, rest queued for bag).
static func add_basic_balls(hopper: Node, bag_queue: Array, start_balls: int, max_balls: int) -> void:
	if start_balls <= 0:
		return
	if GameState:
		GameState.record_ball_ability_in_run("Plain")
	var main_def: BallDefinition = plain_ball_def(Constants.ALIGNMENT_MAIN)
	var in_hopper: int = hopper.get_stored_ball_count() if hopper and hopper.has_method("get_stored_ball_count") else 0
	var room: int = max_balls - in_hopper
	var to_hopper: int = mini(start_balls, room)
	if to_hopper > 0 and hopper and hopper.has_method("add_balls_with_definition"):
		for _i in to_hopper:
			hopper.add_balls_with_definition(1, main_def.duplicate(true))
	for _i in range(start_balls - to_hopper):
		bag_queue.append(main_def.duplicate(true))

## Counts plain balls in hopper, on board, and in bag queue.
static func count_plain_balls_in_play(parent_node: Node, hopper: Node, bag_queue: Array) -> int:
	var n: int = 0
	if hopper and hopper.has_method("get_stored_balls"):
		for ball in hopper.get_stored_balls():
			if not is_instance_valid(ball):
				continue
			var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			if is_plain_ball_def(def):
				n += 1
	var balls_container: Node = parent_node.get_node_or_null("BallsContainer") if parent_node else null
	if balls_container:
		for ball in balls_container.get_children():
			if not is_instance_valid(ball):
				continue
			if ball.has_method("is_split_twin") and ball.is_split_twin():
				continue
			var def2: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			if is_plain_ball_def(def2):
				n += 1
	for def in bag_queue:
		if def is BallDefinition and is_plain_ball_def(def):
			n += 1
	return n

## Converts one plain ball to upgraded definition across hopper, board, or bag queue.
static func apply_ball_upgrade_conversion(parent_node: Node, hopper: Node, bag_queue: Array, def: BallDefinition) -> bool:
	if def == null:
		return false
	var up: BallDefinition = def.duplicate(true)
	if hopper and hopper.has_method("get_stored_balls"):
		for ball in hopper.get_stored_balls():
			if not is_instance_valid(ball):
				continue
			if not ball.has_method("get_definition") or not ball.has_method("set_definition"):
				continue
			var bdef: Resource = ball.get_definition()
			if is_plain_ball_def(bdef):
				ball.set_definition(up.duplicate(true))
				GameState.record_ball_ability_in_run(up.ability_name)
				return true
	var balls_container: Node = parent_node.get_node_or_null("BallsContainer") if parent_node else null
	if balls_container:
		for ball in balls_container.get_children():
			if not is_instance_valid(ball):
				continue
			if ball.has_method("is_split_twin") and ball.is_split_twin():
				continue
			if not ball.has_method("get_definition") or not ball.has_method("set_definition"):
				continue
			var bdef: Resource = ball.get_definition()
			if is_plain_ball_def(bdef):
				ball.set_definition(up.duplicate(true))
				GameState.record_ball_ability_in_run(up.ability_name)
				return true
	var i: int = 0
	while i < bag_queue.size():
		var qdef: Variant = bag_queue[i]
		if qdef is BallDefinition and is_plain_ball_def(qdef):
			bag_queue[i] = up.duplicate(true)
			GameState.record_ball_ability_in_run(up.ability_name)
			return true
		i += 1
	return false

## Handles ball exiting board (return to hopper or queue into bag).
static func on_ball_exited_board(c: Node, ball: Node, reason: int) -> void:
	if reason == 1:
		return
	if reason == 4:
		on_ball_exited_black_hole(c, ball)
		return
	if ball.has_method("is_split_twin") and ball.is_split_twin():
		if GameState and GameState.has_wall_break_upgrade(&"fragment_echo") and ball.has_method("has_fragment_echo_used") and not ball.has_fragment_echo_used():
			ball.mark_fragment_echo_used()
			if c._board and c._board.has_method("respawn_fragment_at_top"):
				c._board.respawn_fragment_at_top(ball)
			return
		ball.queue_free()
		return
	if ball.has_method("is_bloom_spawn") and ball.is_bloom_spawn():
		ball.queue_free()
		return
	var gate_open: bool = c._hopper.is_gate_open() if c._hopper and c._hopper.has_method("is_gate_open") else false
	if not gate_open and c._hopper and c._hopper.has_method("return_ball"):
		c._hopper.return_ball(ball)
		return
	var plain: BallDefinition = plain_ball_def(Constants.ALIGNMENT_MAIN)
	var def_to_store: BallDefinition = plain.duplicate(true)
	if ball.has_method("get_definition"):
		var bd: Resource = ball.get_definition()
		if bd is BallDefinition:
			def_to_store = (bd as BallDefinition).duplicate(true)
	c._bag_queue.append(def_to_store)
	ball.queue_free()

## Handles ball destroyed by black hole with delayed respawn timer.
static func on_ball_exited_black_hole(c: Node, ball: Node) -> void:
	if not ball or not is_instance_valid(ball):
		return
	if ball.has_method("is_bloom_spawn") and ball.is_bloom_spawn():
		ball.queue_free()
		return
	if ball.has_method("is_split_twin") and ball.is_split_twin():
		ball.queue_free()
		return
	var plain: BallDefinition = plain_ball_def(Constants.ALIGNMENT_MAIN)
	var def_to_store: BallDefinition = plain.duplicate(true)
	if ball.has_method("get_definition"):
		var bd: Resource = ball.get_definition()
		if bd is BallDefinition:
			def_to_store = (bd as BallDefinition).duplicate(true)
	ball.queue_free()
	var delay: float = Constants.BLACK_HOLE_RESPAWN_DELAY_SEC
	c.get_tree().create_timer(delay).timeout.connect(c._finish_black_hole_delayed_return.bind(def_to_store))

## Adds balls to reserve (hopper first, then bag queue).
static func add_balls_to_reserve(c: Node, count: int) -> void:
	if count <= 0:
		return
	var plain: BallDefinition = plain_ball_def(Constants.ALIGNMENT_MAIN)
	var in_hopper: int = c._hopper.get_stored_ball_count() if c._hopper and c._hopper.has_method("get_stored_ball_count") else 0
	var room: int = c.HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(count, room)
	if to_hopper > 0 and c._hopper and c._hopper.has_method("add_balls_with_definition"):
		for _i in to_hopper:
			c._hopper.add_balls_with_definition(1, plain.duplicate(true))
## Spawns initial starting balls or test scenario balls.
static func spawn_initial_balls(c: Node) -> void:
	if TestScenario and TestScenario.enabled and not TestScenario.starting_balls.is_empty():
		spawn_test_scenario_balls(c)
		return
	var main_def: BallDefinition = plain_ball_def(Constants.ALIGNMENT_MAIN)
	main_def.base_energy = Constants.legacy_display_energy_to_current(20)
	main_def.city_weights = {0: 100}
	main_def.rarity = Constants.RARITY_COMMON
	main_def.tier = 1
	main_def.shape_type = -1
	main_def.status_effects = {}
	var total: int = c.START_BALLS
	var in_hopper: int = c._hopper.get_stored_ball_count() if c._hopper and c._hopper.has_method("get_stored_ball_count") else 0
	var room: int = c.HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(total, room)
	if to_hopper > 0 and c._hopper and c._hopper.has_method("add_balls_with_definition"):
		for _i in to_hopper:
			c._hopper.add_balls_with_definition(1, main_def.duplicate(true))
	for _i in range(total - to_hopper):
		c._bag_queue.append(main_def.duplicate(true))
	if GameState:
		GameState.record_ball_ability_in_run("Plain")

## Spawns starting balls defined in active TestScenario.
static func spawn_test_scenario_balls(c: Node) -> void:
	for entry in TestScenario.starting_balls:
		if not entry is Dictionary:
			continue
		var ability: String = entry.get("ability", "")
		var count: int = entry.get("count", 1)
		var ball_def: BallDefinition = TestScenario.make_ball_definition(ability)
		if not ability.is_empty():
			GameState.record_ball_ability_in_run(ability)
		elif count > 0:
			GameState.record_ball_ability_in_run("Plain")
		var in_hopper: int = c._hopper.get_stored_ball_count() if c._hopper and c._hopper.has_method("get_stored_ball_count") else 0
		var room: int = c.HOPPER_MAX_BALLS - in_hopper
		var to_hopper: int = mini(count, room)
		if to_hopper > 0 and c._hopper and c._hopper.has_method("add_balls_with_definition"):
			for _i in to_hopper:
				c._hopper.add_balls_with_definition(1, ball_def.duplicate(true))
		for _i in range(count - to_hopper):
			c._bag_queue.append(ball_def.duplicate(true))

## Clears bag queue and hopper and re-spawns initial starting balls.
static func reset_starting_ball_pool(c: Node) -> void:
	c._bag_queue.clear()
	if c._hopper and c._hopper.has_method("clear_stored_balls"):
		c._hopper.clear_stored_balls()
	spawn_initial_balls(c)
#endregion


