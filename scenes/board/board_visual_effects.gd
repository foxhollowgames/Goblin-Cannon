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
	for i in range(ENERGY_POPUP_POOL_PREALLOC):
		var popup: Node2D = energy_popup_scene.instantiate() as Node2D
		if popup:
			add_child(popup)
			popup.visible = false
			_energy_popup_pool_idle.append(popup)
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
		effect.visible = true

## Spawns a hit effect at the specified position with a given effect type.
func spawn_hit_effect(world_pos: Vector2, effect_type: int) -> void:
	if not ball_hit_effect_scene:
		return
	var effect: Node2D = ball_hit_effect_scene.instantiate() as Node2D
	if effect:
		add_child(effect)
		effect.global_position = world_pos
		effect.visible = true
		if "effect_type" in effect:
			effect.effect_type = effect_type

## Spawns a chain lightning arc from one position to another.
func spawn_chain_lightning_arc(from_pos: Vector2, to_pos: Vector2) -> void:
	if not chain_lightning_arc_effect_scene:
		return
	var effect: Node2D = chain_lightning_arc_effect_scene.instantiate() as Node2D
	if effect:
		add_child(effect)
		effect.global_position = from_pos
		effect.visible = true
		if "to_pos" in effect:
			effect.to_pos = to_pos

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
	if not _energy_popup_pool_idle.is_empty():
		var popup: Node2D = _energy_popup_pool_idle.pop_back()
		return popup
	if energy_popup_scene:
		var new_popup: Node2D = energy_popup_scene.instantiate() as Node2D
		if new_popup:
			add_child(new_popup)
			return new_popup
	return null
#endregion

