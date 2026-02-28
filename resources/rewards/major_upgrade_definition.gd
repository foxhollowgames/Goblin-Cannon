@tool
extends Resource
class_name MajorUpgradeDefinition
## GDD: wall break / conquest = major upgrades (not same as milestone balls+stats). Slice: placeholder set.

@export var display_name: String = ""
@export var description: String = ""
@export var upgrade_id: StringName = &""  # used by RewardHandler.apply_major_upgrade to apply effect
