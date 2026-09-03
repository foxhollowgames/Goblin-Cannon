extends Node2D
## Visual effects manager for the Board scene. Handles popup pooling, hit VFX, and arc rendering.

#region Config and Scenes
@export var energy_popup_scene: PackedScene = preload("res://scenes/board/energy_popup.tscn")
@export var ball_hit_effect_scene: PackedScene = preload("res://scenes/board/ball_hit_effect.tscn")
@export var treasure_chest_break_effect_scene: PackedScene = preload("res://scenes/board/treasure_chest_break_effect.tscn")
@export var chain_lightning_arc_effect_scene: PackedScene = preload("res://scenes/board/chain_lightning_arc_effect.tscn")

var _energy_popup_pool_idle: Array[Node2D] = []
const ENERGY_POPUP_POOL_PREALLOC: int = 48
const ENERGY_POPUP_POOL_MAX_IDLE: int = 96
#endregion

#region Lifecycle
func _ready() -> void:
	preallocate_energy_popups()

## Preallocates a pool of energy popups for zero runtime allocation lag.
func preallocate_energy_popups() -> void:
	if not energy_popup_scene:
		return
	var release_cb := Callable(self, "_release_energy_popup_to_pool")
	for i in range(ENERGY_POPUP_POOL_PREALLOC):
		var popup: Node2D = energy_popup_scene.instantiate() as Node2D
		if popup:
			if popup.has_method("set_pool_release"):
				popup.set_pool_release(release_cb)
			add_child(popup)
			popup.visible = false
			popup.set_process(false)
			popup.modulate = Color.WHITE
			_energy_popup_pool_idle.append(popup)

func _release_energy_popup_to_pool(popup: Node) -> void:
	if not is_instance_valid(popup) or not (popup is Node2D):
		return
	var p2: Node2D = popup as Node2D
	p2.set_process(false)
	p2.visible = false
	p2.position = Vector2.ZERO
	p2.modulate = Color.WHITE
	if _energy_popup_pool_idle.size() >= ENERGY_POPUP_POOL_MAX_IDLE:
		p2.queue_free()
		return
	_energy_popup_pool_idle.append(p2)
#endregion

#region Public API
## Spawns an energy popup over the specified peg.
func spawn_energy_popup(peg: Node, amount_display: int) -> void:
	if not peg:
		return
	spawn_energy_popup_at_pos(peg.position + Vector2(0, -16), amount_display)

## Spawns an energy popup at the specified position.
func spawn_energy_popup_at_pos(pos: Vector2, amount_display: int) -> void:
	var popup: Node2D = get_from_pool()
	if popup:
		if popup.has_method("setup"):
			popup.setup("+%d" % amount_display)
		popup.position = pos
		popup.modulate = Color.WHITE
		popup.visible = true

## Spawns a leech popup with custom color formatting.
func spawn_leech_popup(peg: Node, amount_display: int) -> void:
	if not peg:
		return
	var popup: Node2D = get_from_pool()
	if popup:
		if popup.has_method("setup"):
			popup.setup("+%d" % amount_display)
		popup.position = peg.position + Vector2(0, -16)
		popup.visible = true
		popup.modulate = Constants.gameplay_board_energy_popup()

## Spawns a trampoline bounce effect at the specified position.
func spawn_trampoline_bounce_effect(world_pos: Vector2) -> void:
	if not ball_hit_effect_scene:
		return
	var effect: Node2D = ball_hit_effect_scene.instantiate() as Node2D
	if effect:
		add_child(effect)
		effect.global_position = world_pos
		effect.z_index = 100
		if effect.has_method("setup_effect"):
			effect.setup_effect(BallHitEffect.EffectType.TRAMPOLINE)

## Spawns a hit effect at the specified position with a given effect type.
func spawn_hit_effect(world_pos: Vector2, effect_type: int) -> void:
	if not ball_hit_effect_scene:
		return
	var effect: Node2D = ball_hit_effect_scene.instantiate() as Node2D
	if effect:
		add_child(effect)
		effect.global_position = world_pos
		if effect.has_method("setup_effect"):
			effect.setup_effect(effect_type as BallHitEffect.EffectType)

## Spawns a chain lightning arc from one position to another.
func spawn_chain_lightning_arc(from_pos: Vector2, to_pos: Vector2) -> void:
	if not chain_lightning_arc_effect_scene:
		return
	var effect: Node2D = chain_lightning_arc_effect_scene.instantiate() as Node2D
	if effect:
		add_child(effect)
		effect.global_position = Vector2.ZERO
		if effect.has_method("setup_chain"):
			effect.setup_chain([from_pos, to_pos])

## Spawns a treasure chest break effect at the specified position.
func spawn_treasure_chest_break_effect(world_pos: Vector2) -> void:
	if not treasure_chest_break_effect_scene:
		return
	var effect: Node2D = treasure_chest_break_effect_scene.instantiate() as Node2D
	if effect:
		add_child(effect)
		effect.global_position = world_pos
		effect.visible = true

## Retrieves a popup instance from the pool or creates a new one.
func get_from_pool() -> Node2D:
	var popup: Node2D = null
	if not _energy_popup_pool_idle.is_empty():
		popup = _energy_popup_pool_idle.pop_back()
	elif energy_popup_scene:
		var release_cb := Callable(self, "_release_energy_popup_to_pool")
		popup = energy_popup_scene.instantiate() as Node2D
		if popup and popup.has_method("set_pool_release"):
			popup.set_pool_release(release_cb)
		if popup:
			add_child(popup)
	if popup:
		popup.visible = true
		popup.set_process(true)
		popup.modulate = Color.WHITE
	return popup
#endregion


