extends Node
## EnergyManager (§6). Small API: receive allocation, feed MainCannon + SidearmPool + ShieldPool.
## Connects to EnergyRouter.energy_allocated; passes display×100 to router on ball_reached_bottom.
## Updates DebugOverlay at 1 Hz from cached pool values.

var _energy_router: Node
var _main_cannon: Node
var _sidearm_pool: Node
var _shield_pool: Node
var _debug_overlay: Control
var _overlay_timer: Timer
var _last_ball_id: int = -1
var _last_total_display: int = 0

func _ready() -> void:
	var main: Node = get_parent()
	_energy_router = main.get_node_or_null("EnergyRouter")
	_debug_overlay = main.get_node_or_null("UI/DebugOverlay") as Control
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		_main_cannon = sys.get_node_or_null("MainCannon")
		var sidearms: Node = sys.get_node_or_null("Sidearms")
		if sidearms:
			_sidearm_pool = sidearms.get_node_or_null("SidearmPool")
		_shield_pool = sys.get_node_or_null("ShieldPool")
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.connect(_on_energy_allocated)
	if _debug_overlay and _debug_overlay.has_method("set_energy"):
		_overlay_timer = Timer.new()
		_overlay_timer.wait_time = 1.0
		_overlay_timer.one_shot = false
		add_child(_overlay_timer)
		_overlay_timer.timeout.connect(_update_debug_overlay)
		_overlay_timer.start()
		_update_debug_overlay()

func _exit_tree() -> void:
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.disconnect(_on_energy_allocated)
	if _overlay_timer and _overlay_timer.timeout.is_connected(_update_debug_overlay):
		_overlay_timer.timeout.disconnect(_update_debug_overlay)

func on_ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int) -> void:
	if not _energy_router or not _energy_router.has_method("route_energy"):
		return
	_last_ball_id = ball_id
	_last_total_display = total_energy_display
	var internal: int = total_energy_display * Constants.ENERGY_SCALE
	_energy_router.route_energy(internal, alignment)

## Route display energy (e.g. Leech peg drain) into pools by alignment. Does not update last_ball_id.
func add_display_energy(amount_display: int, alignment: int) -> void:
	if not _energy_router or not _energy_router.has_method("route_energy"):
		return
	var internal: int = amount_display * Constants.ENERGY_SCALE
	_energy_router.route_energy(internal, alignment)

func _on_energy_allocated(main: int, sidearm: int, shield: int) -> void:
	# GDD §12: milestone stat upgrade main_charge_bonus adds % to main energy per ball
	var main_effective: int = main
	if GameState:
		main_effective = int(main * (1.0 + GameState.main_charge_bonus))
	if _main_cannon and _main_cannon.has_method("add_energy"):
		_main_cannon.add_energy(main_effective)
	if _sidearm_pool and _sidearm_pool.has_method("add_energy"):
		_sidearm_pool.add_energy(sidearm)
	if _shield_pool and _shield_pool.has_method("add_energy"):
		_shield_pool.add_energy(shield)

func _update_debug_overlay() -> void:
	if not _debug_overlay or not _debug_overlay.has_method("set_energy"):
		return
	var main: int = _main_cannon.get_current_energy() if _main_cannon and _main_cannon.has_method("get_current_energy") else 0
	var sidearm: int = _sidearm_pool.get_current_energy() if _sidearm_pool and _sidearm_pool.has_method("get_current_energy") else 0
	var shield: int = _shield_pool.get_current_shield_points() if _shield_pool and _shield_pool.has_method("get_current_shield_points") else 0
	_debug_overlay.set_energy(main, sidearm, shield)
