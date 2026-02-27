extends Node
## RapidFire (§6.8). Cooldown-based; consume from pool; emit sidearm_fired.

signal sidearm_fired(damage: int)

var _cooldown_ticks_remaining: int = 0
var _pool: Node
var _cooldown_ticks: int = 30

func _ready() -> void:
	var sidearms: Node = get_parent()
	_pool = sidearms.get_node_or_null("SidearmPool")

func try_fire() -> bool:
	if _cooldown_ticks_remaining > 0:
		return false
	if not _pool or not _pool.has_method("consume"):
		return false
	var cost: int = 20000  # internal
	if not _pool.consume(cost):
		return false
	_cooldown_ticks_remaining = _cooldown_ticks
	sidearm_fired.emit(5)  # slice damage
	return true

func sim_tick(_tick: int) -> void:
	if _cooldown_ticks_remaining > 0:
		_cooldown_ticks_remaining -= 1
	else:
		try_fire()
