extends Node
## EnergyManager (§6). Small API: receive allocation, feed MainCannon + SidearmPool.
## Connects to EnergyRouter.energy_allocated; passes display×100 to router on ball_reached_bottom.

var _energy_router: Node
var _main_cannon: Node
var _sidearm_pool: Node

func _ready() -> void:
	var main: Node = get_parent()
	_energy_router = main.get_node_or_null("EnergyRouter")
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		_main_cannon = sys.get_node_or_null("MainCannon")
		var sidearms: Node = sys.get_node_or_null("Sidearms")
		if sidearms:
			_sidearm_pool = sidearms.get_node_or_null("SidearmPool")
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.connect(_on_energy_allocated)

func _exit_tree() -> void:
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.disconnect(_on_energy_allocated)

func on_ball_reached_bottom(_ball_id: int, total_energy_display: int, alignment: int) -> void:
	if not _energy_router or not _energy_router.has_method("route_energy"):
		return
	var internal: int = total_energy_display * Constants.ENERGY_SCALE
	_energy_router.route_energy(internal, alignment)

func _on_energy_allocated(main: int, sidearm: int, _shield: int) -> void:
	if _main_cannon and _main_cannon.has_method("add_energy"):
		_main_cannon.add_energy(main)
	if _sidearm_pool and _sidearm_pool.has_method("add_energy"):
		_sidearm_pool.add_energy(sidearm)
