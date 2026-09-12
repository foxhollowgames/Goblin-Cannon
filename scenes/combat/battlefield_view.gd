extends Node2D
## Visual battlefield: horizontal combat arena across the top of the screen (1280x110).
## Cannon on left fires at wall on right; city mob marches from wall to cannon over the timer duration.

#region Signals
signal wall_break_transition_finished
signal next_wall_intro_finished
signal terrain_advance_started(duration: float, max_speed: float)
signal terrain_advance_stopped(duration: float)
signal cannon_exploded
#endregion

#region Constants
const BATTLEFIELD_WIDTH: float = 1280.0
const BATTLEFIELD_HEIGHT: float = 110.0
const WALL_HEIGHT: float = 100.0
const CANNON_OVERLAY_OFFSET_Y: float = 0.0
const CANNON_ZONE_TOP: float = 0.0
const CANNON_MUZZLE_POS: Vector2 = Vector2(105.0, 58.0)
const WALL_IMPACT_POS: Vector2 = Vector2(1175.0, 58.0)
const CANNON_BLAST_CENTER: Vector2 = Vector2(105.0, 58.0)

const CANNON_ROLL_DISTANCE: float = 200.0
const CANNON_ROLL_FORWARD_DURATION: float = 1.4
const CANNON_ROLL_BACK_DURATION: float = 1.0
const CANNON_ROLL_FORWARD_DELAY: float = 0.3
const CANNON_ROLL_BACK_DELAY: float = 0.2
const TERRAIN_ADVANCE_SPEED: float = 320.0
const FIRING_RUMBLE_INTENSITY: float = 2.5
#endregion

#region Variables
var _terrain: Node2D = null
var _wall_visual: Node2D = null
var _cannon_visual: Node2D = null
var _city_mob_visual: Node2D = null
var _main_cannon: Node = null
var _cannon_shot_scene: PackedScene = null
var _wall_impact_scene: PackedScene = null
var _muzzle_blast_scene: PackedScene = null
var _vfx_container: Node2D = null
var _cannon_overlay_local_pos: Vector2 = Vector2.ZERO
var _wall_overlay_local_pos: Vector2 = Vector2.ZERO
var _mob_overlay_local_pos: Vector2 = Vector2.ZERO
var _cannon_roll_offset_x: float = 0.0
var _cannon_roll_offset_y: float = 0.0
var _roll_tween: Tween = null
#endregion

#region Lifecycle Methods
func _ready() -> void:
	_init_terrain()
	_init_wall_and_cannon()
	_load_vfx_scenes()

func _process(_delta: float) -> void:
	var target_offset := Vector2(_cannon_roll_offset_x, CANNON_OVERLAY_OFFSET_Y + _cannon_roll_offset_y)
	if _cannon_visual:
		if _cannon_visual.get_parent() != self:
			_cannon_visual.global_position = global_position + _cannon_overlay_local_pos + target_offset
		else:
			_cannon_visual.position = _cannon_overlay_local_pos + target_offset
	if _wall_visual:
		if _wall_visual.get_parent() != self:
			_wall_visual.global_position = global_position + _wall_overlay_local_pos
		else:
			_wall_visual.position = _wall_overlay_local_pos
	if _city_mob_visual and _city_mob_visual.get_parent() != self:
		_city_mob_visual.global_position = global_position + _city_mob_visual.position
	if _vfx_container and _vfx_container.get_parent() != self:
		_vfx_container.global_position = global_position

func _exit_tree() -> void:
	if _main_cannon and _main_cannon.has_signal("main_fired") and _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.disconnect(_on_main_fired)
#endregion

#region Public Methods
## Connects main cannon firing signal to battlefield visuals.
func set_main_cannon(cannon: Node) -> void:
	if _main_cannon and _main_cannon.has_signal("main_fired") and _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.disconnect(_on_main_fired)
	_main_cannon = cannon
	if _main_cannon and _main_cannon.has_signal("main_fired") and not _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.connect(_on_main_fired)

## Returns the ScrollingTerrain node reference.
func get_scrolling_terrain() -> Node2D:
	return _terrain

## Returns the CityMobVisual node reference.
func get_city_mob() -> Node2D:
	return _city_mob_visual

## Returns cannon target coordinates for enemy projectiles.
func get_cannon_target_position() -> Vector2:
	return Vector2(75.0, 58.0)

## Returns projectile container for fortifications or effects.
func get_projectiles_container() -> Node2D:
	var cont: Node2D = get_node_or_null("ProjectilesContainer") as Node2D
	return cont if cont else self

## Updates siege timer countdown on the city mob visual.
func set_timer_progress(seconds_remaining: float, total_seconds: float = 120.0) -> void:
	if _city_mob_visual and _city_mob_visual.has_method("set_timer_progress"):
		_city_mob_visual.set_timer_progress(seconds_remaining, total_seconds)

## Convenience helper for setting timer seconds.
func set_timer(seconds_remaining: float) -> void:
	set_timer_progress(seconds_remaining, 120.0)

## Updates city theme styling on the mob visual.
func set_city(city_id: int) -> void:
	if _city_mob_visual and _city_mob_visual.has_method("apply_city_theme"):
		_city_mob_visual.apply_city_theme(city_id)

## Triggers catastrophic explosion on the cannon when breached.
func trigger_cannon_explosion() -> void:
	if _cannon_visual and _cannon_visual.has_method("trigger_catastrophic_explosion"):
		_cannon_visual.trigger_catastrophic_explosion()
	if _wall_impact_scene and _vfx_container:
		var blast: Node2D = _wall_impact_scene.instantiate() as Node2D
		if blast and blast.has_method("setup"):
			blast.setup(CANNON_BLAST_CENTER)
			_vfx_container.add_child(blast)
	cannon_exploded.emit()

## Stub for wall indexing.
func set_wall_index(_wall_index: int) -> void:
	if GameState:
		set_city(GameState.current_city_id)

## Initiates wall destroyed sequence: explosion, mob defeat, cannon advance, and terrain advance.
func play_wall_destroyed_transition() -> void:
	if _wall_visual and _wall_visual.has_method("play_explosion"):
		_wall_visual.play_explosion()
	if _city_mob_visual and _city_mob_visual.has_method("play_defeat"):
		_city_mob_visual.play_defeat()
	if _terrain and _terrain.has_method("start_advancing"):
		_terrain.start_advancing(CANNON_ROLL_FORWARD_DURATION, TERRAIN_ADVANCE_SPEED)
	terrain_advance_started.emit(CANNON_ROLL_FORWARD_DURATION, TERRAIN_ADVANCE_SPEED)
	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.set_parallel(true)
	_roll_tween.tween_property(self, "_cannon_roll_offset_x", CANNON_ROLL_DISTANCE, CANNON_ROLL_FORWARD_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(CANNON_ROLL_FORWARD_DELAY)
	_roll_tween.tween_property(self, "_cannon_roll_offset_y", -CANNON_ROLL_DISTANCE, CANNON_ROLL_FORWARD_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(CANNON_ROLL_FORWARD_DELAY)
	_roll_tween.chain().tween_callback(func():
		wall_break_transition_finished.emit()
	)

## Initiates next wall entrance: rebuild visual, terrain halt, reset mob, and cannon return to ready stance.
func play_next_wall_intro() -> void:
	if _wall_visual and _wall_visual.has_method("play_rebuild"):
		_wall_visual.play_rebuild()
	if _city_mob_visual and _city_mob_visual.has_method("reset_mob"):
		_city_mob_visual.reset_mob()
		if GameState:
			set_city(GameState.current_city_id)
	if _cannon_visual and _cannon_visual.has_method("reset_cannon"):
		_cannon_visual.reset_cannon()
	if _terrain and _terrain.has_method("stop_advancing"):
		_terrain.stop_advancing(CANNON_ROLL_BACK_DURATION)
	terrain_advance_stopped.emit(CANNON_ROLL_BACK_DURATION)
	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.set_parallel(true)
	_roll_tween.tween_property(self, "_cannon_roll_offset_x", 0.0, CANNON_ROLL_BACK_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(CANNON_ROLL_BACK_DELAY)
	_roll_tween.tween_property(self, "_cannon_roll_offset_y", 0.0, CANNON_ROLL_BACK_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(CANNON_ROLL_BACK_DELAY)
	_roll_tween.chain().tween_callback(func():
		next_wall_intro_finished.emit()
	)
#endregion

#region Private Methods
func _init_terrain() -> void:
	_terrain = get_node_or_null("ScrollingTerrain") as Node2D
	if _terrain == null:
		var terrain_script: Script = load("res://scenes/combat/scrolling_terrain.gd") as Script
		if terrain_script:
			_terrain = terrain_script.new() as Node2D
			_terrain.name = "ScrollingTerrain"
			_terrain.set("terrain_width", BATTLEFIELD_WIDTH)
			_terrain.set("terrain_height", BATTLEFIELD_HEIGHT)
			add_child(_terrain)
			move_child(_terrain, 0)

func _init_wall_and_cannon() -> void:
	_wall_visual = get_node_or_null("WallVisual") as Node2D
	_cannon_visual = get_node_or_null("CannonVisual") as Node2D
	_city_mob_visual = get_node_or_null("CityMobVisual") as Node2D
	if _city_mob_visual and _city_mob_visual.has_signal("mob_reached_cannon"):
		if not _city_mob_visual.mob_reached_cannon.is_connected(_on_mob_reached_cannon):
			_city_mob_visual.mob_reached_cannon.connect(_on_mob_reached_cannon)
	var main: Node = get_tree().current_scene if is_inside_tree() and get_tree() else null
	var overlay: CanvasLayer = main.get_node_or_null("CannonOverlay") as CanvasLayer if main else null
	if _cannon_visual:
		_cannon_overlay_local_pos = _cannon_visual.position
		if overlay:
			_cannon_visual.reparent(overlay)
	if _wall_visual:
		_wall_overlay_local_pos = _wall_visual.position
		if overlay:
			_wall_visual.reparent(overlay)
		for child in _wall_visual.get_children():
			if child.name.begins_with("Fortification"):
				child.visible = false
				child.set_process(false)
				child.set_physics_process(false)
	if _city_mob_visual:
		_mob_overlay_local_pos = _city_mob_visual.position
		if overlay:
			_city_mob_visual.reparent(overlay)

func _load_vfx_scenes() -> void:
	_cannon_shot_scene = load("res://scenes/combat/cannon_shot_vfx.tscn") as PackedScene
	_wall_impact_scene = load("res://scenes/combat/wall_impact_vfx.tscn") as PackedScene
	_muzzle_blast_scene = load("res://scenes/combat/muzzle_blast_vfx.tscn") as PackedScene
	_vfx_container = get_node_or_null("VFXContainer") as Node2D
	if _vfx_container == null:
		_vfx_container = Node2D.new()
		_vfx_container.name = "VFXContainer"
		var main: Node = get_tree().current_scene if is_inside_tree() and get_tree() else null
		var overlay: CanvasLayer = main.get_node_or_null("CannonOverlay") as CanvasLayer if main else null
		if overlay:
			overlay.add_child(_vfx_container)
			_vfx_container.global_position = global_position
		else:
			add_child(_vfx_container)

## Triggers firing sequence with horizontal projectile flight and wall impact.
func fire_cannon_shot(start_pos: Vector2 = CANNON_MUZZLE_POS, end_pos: Vector2 = WALL_IMPACT_POS) -> void:
	if _cannon_visual and _cannon_visual.has_method("trigger_firing_anim"):
		_cannon_visual.trigger_firing_anim()
	if _terrain and _terrain.has_method("trigger_recoil_rumble"):
		_terrain.trigger_recoil_rumble(FIRING_RUMBLE_INTENSITY)
	if _muzzle_blast_scene and _vfx_container:
		var blast: Node2D = _muzzle_blast_scene.instantiate() as Node2D
		if blast and blast.has_method("setup"):
			blast.setup(CANNON_BLAST_CENTER)
			_vfx_container.add_child(blast)
	if _cannon_shot_scene and _wall_impact_scene and _vfx_container:
		var shot: Node2D = _cannon_shot_scene.instantiate() as Node2D
		if shot and shot.has_method("setup"):
			shot.setup(start_pos, end_pos, _spawn_wall_impact)
			_vfx_container.add_child(shot)

func _on_main_fired(_damage: int) -> void:
	fire_cannon_shot(CANNON_MUZZLE_POS, WALL_IMPACT_POS)

func _spawn_wall_impact(impact_pos: Vector2) -> void:
	if _wall_visual and _wall_visual.has_method("trigger_hit_reaction"):
		_wall_visual.trigger_hit_reaction()
	if _wall_impact_scene and _vfx_container:
		var impact: Node2D = _wall_impact_scene.instantiate() as Node2D
		if impact and impact.has_method("setup"):
			impact.setup(impact_pos)
			_vfx_container.add_child(impact)

func _on_mob_reached_cannon() -> void:
	trigger_cannon_explosion()
#endregion
