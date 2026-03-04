extends Node
## Sidearms container (§6.8). Forwards sim_tick to each sidearm so they can decrement cooldown and try_fire.
## Spawns sidearm nodes for GameState.owned_sidearm_ids (except rapid_fire, which is already in the scene).
## Pool (SidearmPool) does not receive sim_tick; only sidearm weapons do.
##
## Sidearms (all have graphical representation via BattlefieldView + CannonVisual):
## - rapid_fire: Starting pistol; always present in scene (main.tscn). Single-target, rapid fire.
## - sniper: Unlock via draft. High single-target damage. Spawned when owned.
## - aoe_cannon: Unlock via draft. Area damage around frontmost minion. Spawned when owned.
## Each gets: cannon barrel (CannonVisual), muzzle/shot VFX, floating energy cost, cooldown dimming.

signal sidearms_updated

## sidearm_id (StringName) -> [node_name: String, script_path: String]. Must match reward_handler upgrade_id.
const SIDEARM_SPAWN_INFO: Dictionary = {
	&"sniper": ["Sniper", "res://scenes/systems/sidearms/sniper/sniper.gd"],
	&"aoe_cannon": ["AoeCannon", "res://scenes/systems/sidearms/aoe_cannon/aoe_cannon.gd"],
}

func _ready() -> void:
	if GameState:
		GameState.owned_sidearm_added.connect(_on_owned_sidearm_added)
	_ensure_owned_sidearms_spawned()

func _exit_tree() -> void:
	if GameState and GameState.owned_sidearm_added.is_connected(_on_owned_sidearm_added):
		GameState.owned_sidearm_added.disconnect(_on_owned_sidearm_added)

func _on_owned_sidearm_added(_sidearm_id: StringName) -> void:
	_ensure_owned_sidearms_spawned()

func _ensure_owned_sidearms_spawned() -> void:
	if not GameState:
		return
	for id in GameState.owned_sidearm_ids:
		if id == &"rapid_fire":
			continue
		var info: Array = SIDEARM_SPAWN_INFO.get(id, [])
		if info.is_empty():
			continue
		var node_name: String = info[0]
		var script_path: String = info[1]
		if get_node_or_null(node_name) != null:
			continue
		var script_res: GDScript = load(script_path) as GDScript
		if script_res == null:
			continue
		var node: Node = Node.new()
		node.name = node_name
		node.set_script(script_res)
		add_child(node)
		sidearms_updated.emit()

func sim_tick(tick: int) -> void:
	for child in get_children():
		if child.has_method("sim_tick"):
			child.sim_tick(tick)
