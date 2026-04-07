extends Node2D
## Ensures `class_name MonsterPalette` is registered before gameplay scripts parse.
const _monster_palette_script = preload("res://autoloads/monster_palette.gd")
## Main root (§3). Entry point; GameCoordinator (child) does all wiring and sim drive.
## Children do not hold refs to Main; they emit signals and expose call-down methods.

func _ready() -> void:
	pass
