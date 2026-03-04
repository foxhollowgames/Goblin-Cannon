@tool
extends Resource
class_name MajorUpgradeDefinition
## GDD: wall break / conquest = major upgrades (not same as milestone balls+stats).
## Categories: 1 Sidearm, 1 Ball Enhancement, 1 Board (including Tag) per draft.

enum Category {
	SIDEARM,
	BALL_ENHANCEMENT,
	BOARD_UPGRADE
}

@export var display_name: String = ""
@export var description: String = ""
@export var upgrade_id: StringName = &""  # used by RewardHandler.apply_major_upgrade to apply effect
@export var category: Category = Category.BOARD_UPGRADE
## For BALL_ENHANCEMENT: only offered if this ability_name exists in run (e.g. "Rubbery", "Energizer"). Empty = generic (all balls).
@export var ball_type: String = ""
