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
#endregion


