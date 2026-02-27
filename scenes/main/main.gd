extends Node2D
## Main root (§3). Entry point; GameCoordinator (child) does all wiring and sim drive.
## Children do not hold refs to Main; they emit signals and expose call-down methods.

func _ready() -> void:
	pass
