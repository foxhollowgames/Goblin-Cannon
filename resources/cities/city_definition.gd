@tool
extends Resource
class_name CityDefinition
## GDD §11: City 1 Halfling Shire (slice), City 2 Human Kingdom, City 3 Elf Palace.
## §7: waves, rewards, boss. Slice: City 1 = Discovery (readable, stable, identity forming).

@export var city_id: StringName = &"city_1"
## Display name for UI (e.g. "Halfling Shire").
@export var display_name: String = "Halfling Shire"
## Gate/fortification label for the first wall (e.g. "Village Gate"). Used when wall_names is empty.
@export var gate_name: String = "Village Gate"
## All wall names in order for this city. Conquest sidebar lists these; when one breaks, we advance to the next.
@export var wall_names: Array = []  # e.g. ["Village Gate", "Mill Gate", "Town Hall"]
## Base wall HP for wall 1. Later walls scale exponentially (normal curve): Wall 1 = 50, 2 = 100, 3 = 300, etc.
@export var wall_hp_max: int = 50
## Milestone thresholds in display units (GDD §12: ~3 per wall, 200 scale). Stored as ints in Array for .tres.
@export var milestone_thresholds: Array = [200, 400, 600]
@export var waves: Array = []
@export var rewards: Array = []
@export var boss: Resource

## Returns milestone_thresholds as Array[int] for MilestoneTracker.
func get_milestone_thresholds_int() -> Array[int]:
	var out: Array[int] = []
	for v in milestone_thresholds:
		out.append(int(v))
	return out

## Wall names for Conquest UI and CombatManager. If wall_names is empty, returns [gate_name].
func get_effective_wall_names() -> Array:
	if wall_names.size() > 0:
		return wall_names
	return [gate_name]

## Max HP for a given wall index (0 = first wall). Follows exponential curve: 50, 100, 300, 650, ...
## Formula: base - 25*w + 75*w^2 (fits Wall 1=50, 2=100, 3=300).
func get_wall_hp_max_for_index(wall_index: int) -> int:
	if wall_index < 0:
		return wall_hp_max
	var w: int = wall_index
	return int(wall_hp_max - 25 * w + 75 * w * w)
