@tool
extends Resource
class_name MajorUpgradeDefinition
## GDD: wall break / conquest = major upgrades (not same as milestone balls+stats).
## Categories: 1 Sidearm, 1 Ball Enhancement, 1 Board (including Tag) per draft.
## ONBOARD_PASSIVE = treasure chest rewards (global/tag scaling, not synergy cross-links).

enum Category {
	SIDEARM,
	BALL_ENHANCEMENT,
	BOARD_UPGRADE,
	BOSS_AMPLIFIER,
	## Passive tag / global board scaling from treasure chest (onboard), not conquest synergies.
	ONBOARD_PASSIVE
}

@export var display_name: String = ""
@export var description: String = ""
@export var upgrade_id: StringName = &""
@export var category: Category = Category.BOARD_UPGRADE
## For BALL_ENHANCEMENT: targets this ability_name; heavily down-weighted if not in run. Empty = generic (all balls).
@export var ball_type: String = ""
## Cross-link / boss synergy: preferred when ALL listed ball types are in the run; otherwise heavily down-weighted (not excluded).
@export var required_ball_types: Array[String] = []
