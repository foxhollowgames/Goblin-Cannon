class_name BallHitEffect
extends Node2D
## Short burst VFX when a ball hits a peg or reaches the bottom. Type: fire (flame explosion), ice (frost burst), lightning (spark).

enum EffectType { FIRE, ICE, LIGHTNING, ENERGIZE, SPLIT, EXPLOSIVE, CHAIN_LIGHTNING, LEECH, RUBBERY, PHANTOM, TRAMPOLINE }

const DURATION_SEC: float = 0.4
const BASE_RADIUS: float = 18.0
const MAX_RADIUS: float = 48.0

var _effect_type: EffectType = EffectType.FIRE
var _elapsed: float = 0.0
var _explosive_fixed_radius: float = -1.0  ## When > 0, explosion uses this radius and a clear circle outline

func _ready() -> void:
	pass

func setup_effect(effect_type: EffectType, explosive_fixed_radius: float = -1.0) -> void:
	_effect_type = effect_type
	_explosive_fixed_radius = explosive_fixed_radius
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= DURATION_SEC:
		queue_free()

func _draw() -> void:
	var t: float = clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	var radius: float
	if _effect_type == EffectType.EXPLOSIVE and _explosive_fixed_radius > 0.0:
		radius = _explosive_fixed_radius
	else:
		radius = lerpf(BASE_RADIUS, MAX_RADIUS, t)
	var alpha: float = (1.0 - t) * (1.0 - t * 0.5)
	match _effect_type:
		EffectType.FIRE:
			_draw_fire_burst(radius, alpha)
		EffectType.ICE:
			_draw_ice_burst(radius, alpha)
		EffectType.LIGHTNING:
			_draw_lightning_burst(radius, alpha)
		EffectType.ENERGIZE:
			_draw_energize_burst(radius, alpha)
		EffectType.SPLIT:
			_draw_split_burst(radius, alpha)
		EffectType.EXPLOSIVE:
			_draw_explosive_burst(radius, alpha)
		EffectType.CHAIN_LIGHTNING:
			_draw_chain_lightning_burst(radius, alpha)
		EffectType.LEECH:
			_draw_leech_burst(radius, alpha)
		EffectType.RUBBERY:
			_draw_rubbery_burst(radius, alpha)
		EffectType.PHANTOM:
			_draw_phantom_burst(radius, alpha)
		EffectType.TRAMPOLINE:
			_draw_trampoline_burst(radius, alpha)

func _draw_fire_burst(radius: float, alpha: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.35, 0.05, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.5, 0.1, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.42, Color(1.0, 0.75, 0.25, alpha * 0.7))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(1.0, 0.95, 0.6, alpha * 0.8))

func _draw_ice_burst(radius: float, alpha: float) -> void:
	# Frost: icy blue–cyan with bright white core (no yellow)
	draw_circle(Vector2.ZERO, radius, Color(0.25, 0.6, 0.95, alpha * 0.55))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0.4, 0.78, 1.0, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.7, 0.92, 1.0, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(0.95, 1.0, 1.0, alpha * 0.9))

func _draw_lightning_burst(radius: float, alpha: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.7, 1.0, alpha * 0.45))
	draw_circle(Vector2.ZERO, radius * 0.68, Color(0.7, 0.88, 1.0, alpha * 0.6))
	draw_circle(Vector2.ZERO, radius * 0.38, Color(0.9, 0.96, 1.0, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.16, Color(1.0, 1.0, 0.98, alpha * 0.85))

func _draw_energize_burst(radius: float, alpha: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.9, 0.6, 0.1, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.68, Color(1.0, 0.82, 0.3, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.38, Color(1.0, 0.95, 0.5, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.16, Color(1.0, 1.0, 0.9, alpha * 0.85))

func _draw_split_burst(radius: float, alpha: float) -> void:
	# Split: double-ring “divide” burst (magenta/white)
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.5, 0.9, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.65, Color(0.95, 0.75, 1.0, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.32, Color(1.0, 0.95, 1.0, alpha * 0.8))
	draw_circle(Vector2.ZERO, radius * 0.14, Color(1.0, 1.0, 1.0, alpha * 0.9))

func _draw_explosive_burst(radius: float, alpha: float) -> void:
	# Explosive: large explosion centered on ball; clearly defined circle radius
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.12, 0.02, alpha * 0.55))
	draw_circle(Vector2.ZERO, radius * 0.78, Color(0.85, 0.25, 0.05, alpha * 0.6))
	draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 0.45, 0.12, alpha * 0.7))
	draw_circle(Vector2.ZERO, radius * 0.22, Color(1.0, 0.75, 0.3, alpha * 0.85))
	# Clear defined circle boundary at full radius
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.6, 0.2, alpha * 0.9), 3.0)

func _draw_chain_lightning_burst(radius: float, alpha: float) -> void:
	# Chain Lightning: electric blue-white burst (GDD chain lightning ball)
	draw_circle(Vector2.ZERO, radius, Color(0.35, 0.55, 1.0, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0.6, 0.8, 1.0, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.85, 0.95, 1.0, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.15, Color(1.0, 1.0, 1.0, alpha * 0.9))

func _draw_leech_burst(radius: float, alpha: float) -> void:
	# Leech: green siphon/drain burst
	draw_circle(Vector2.ZERO, radius, Color(0.15, 0.5, 0.25, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0.25, 0.65, 0.35, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.45, 0.85, 0.5, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.15, Color(0.7, 1.0, 0.75, alpha * 0.9))

func _draw_rubbery_burst(radius: float, alpha: float) -> void:
	# Rubbery: soft bouncy white-gray burst
	draw_circle(Vector2.ZERO, radius, Color(0.75, 0.78, 0.82, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.72, Color(0.88, 0.9, 0.92, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.95, 0.96, 0.98, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(1.0, 1.0, 1.0, alpha * 0.9))

func _draw_phantom_burst(radius: float, alpha: float) -> void:
	# Phantom: ghostly translucent purple-white (no physical impact)
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.45, 0.7, alpha * 0.4))
	draw_circle(Vector2.ZERO, radius * 0.72, Color(0.65, 0.6, 0.85, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.82, 0.78, 0.95, alpha * 0.55))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(0.95, 0.93, 1.0, alpha * 0.6))

func _draw_trampoline_burst(radius: float, alpha: float) -> void:
	# Trampoline: upward bounce burst – green/teal rings expanding up
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.65, 0.45, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius * 0.72, Color(0.35, 0.82, 0.55, alpha * 0.65))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.55, 0.95, 0.7, alpha * 0.75))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(0.85, 1.0, 0.9, alpha * 0.9))
