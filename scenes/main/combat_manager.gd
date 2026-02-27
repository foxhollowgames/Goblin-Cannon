extends Node
## CombatManager (§6.11). Owns wall HP, waves, target selection. Receives main_fired, sidearm_fired.

var _wall_hp: int = 100
var _current_wave: int = 0

func _ready() -> void:
	# Connect to MainCannon and Sidearms when available
	var main: Node = get_parent()
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		var mc: Node = sys.get_node_or_null("MainCannon")
		if mc and mc.has_signal("main_fired"):
			mc.main_fired.connect(_on_main_fired)
		var sidearms: Node = sys.get_node_or_null("Sidearms")
		if sidearms:
			var rf: Node = sidearms.get_node_or_null("RapidFire")
			if rf and rf.has_signal("sidearm_fired"):
				rf.sidearm_fired.connect(_on_sidearm_fired)

func _exit_tree() -> void:
	var main: Node = get_parent()
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		var mc: Node = sys.get_node_or_null("MainCannon")
		if mc and mc.has_signal("main_fired") and mc.main_fired.is_connected(_on_main_fired):
			mc.main_fired.disconnect(_on_main_fired)
		var sidearms: Node = sys.get_node_or_null("Sidearms")
		if sidearms:
			var rf: Node = sidearms.get_node_or_null("RapidFire")
			if rf and rf.has_signal("sidearm_fired") and rf.sidearm_fired.is_connected(_on_sidearm_fired):
				rf.sidearm_fired.disconnect(_on_sidearm_fired)

func sim_tick(_tick: int) -> void:
	pass  # Advance waves, spawn units (slice: minimal)

func _on_main_fired(damage: int) -> void:
	_wall_hp -= damage
	if _wall_hp < 0:
		_wall_hp = 0

func _on_sidearm_fired(damage: int) -> void:
	_wall_hp -= damage
	if _wall_hp < 0:
		_wall_hp = 0

func get_wall_hp() -> int:
	return _wall_hp

func get_target_for(_source_id: StringName) -> Node:
	return null  # Slice: frontmost unit or wall
