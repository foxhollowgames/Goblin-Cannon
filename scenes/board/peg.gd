extends StaticBody2D
## Peg (§6.4). Durability, recovery, vibrancy. apply_hit() called by Board after sort.

var peg_id: int = -1
var _durability: int = 3
var _config: Resource

func apply_hit() -> void:
	_subtract_durability(1)
	_update_vibrancy()

func _subtract_durability(amount: int) -> void:
	_durability -= amount
	if _durability <= 0:
		_start_recovery_timer()

func _start_recovery_timer() -> void:
	pass  # sim-tick based; §6.4

func _update_vibrancy() -> void:
	pass  # VFX/audio local

func _draw() -> void:
	draw_circle(Vector2.ZERO, Constants.PEG_RADIUS, Color(0.72, 0.68, 0.55, 1))
