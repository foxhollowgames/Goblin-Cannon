extends Node
## EnergyManager. Receives ball energy, routes it all to the main cannon.

var _energy_router: Node
var _main_cannon: Node
var _debug_overlay: Control
var _overlay_timer: Timer

func _ready() -> void:
	var main: Node = get_parent()
	_energy_router = main.get_node_or_null("EnergyRouter")
	_debug_overlay = main.get_node_or_null("UI/DebugOverlay") as Control
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		_main_cannon = sys.get_node_or_null("MainCannon")
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

func on_ball_reached_bottom(_ball_id: int, total_energy_display: int, _alignment: int) -> void:
	if not _energy_router or not _energy_router.has_method("route_energy"):
		return
	var internal: int = total_energy_display * Constants.ENERGY_SCALE
	_energy_router.route_energy(internal, 0)

func add_display_energy(amount_display: int, _alignment: int) -> void:
	if not _energy_router or not _energy_router.has_method("route_energy"):
		return
	var internal: int = amount_display * Constants.ENERGY_SCALE
	_energy_router.route_energy(internal, 0)

func _on_energy_allocated(main: int, _sidearm: int, _shield: int) -> void:
	var main_effective: int = main
	if GameState:
		main_effective = int(main * (1.0 + GameState.main_charge_bonus))
	if _main_cannon and _main_cannon.has_method("add_energy"):
		_main_cannon.add_energy(main_effective)

func _update_debug_overlay() -> void:
	if not _debug_overlay or not _debug_overlay.has_method("set_energy"):
		return
	var main: int = _main_cannon.get_current_energy() if _main_cannon and _main_cannon.has_method("get_current_energy") else 0
	_debug_overlay.set_energy(main, 0, 0)
