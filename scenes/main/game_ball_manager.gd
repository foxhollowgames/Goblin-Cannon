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

#region Catalog Registration
## Registers a ball definition under the specified ability name.
func register_ball_definition(ability_name: StringName, definition: Resource) -> void:
	_ball_catalog[ability_name] = definition

## Registers many ball definitions from a dictionary of ability names to resources.
func register_ball_definitions(definitions: Dictionary) -> void:
	for key in definitions:
		_ball_catalog[key] = definitions[key]

## Sets the starting ball inventory for new runs.
func set_starting_balls(balls: Array) -> void:
	_starting_balls = balls

## Clears the entire ball catalog and starting inventory.
func clear_catalog() -> void:
	_ball_catalog.clear()
	_starting_balls.clear()
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


