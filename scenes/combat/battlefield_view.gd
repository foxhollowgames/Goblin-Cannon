extends Node2D
## Visual battlefield: wall at top, cannon at bottom. Main cannon fires at wall with VFX.

const BATTLEFIELD_WIDTH: float = 320.0
const BATTLEFIELD_HEIGHT: float = 720.0
const WALL_HEIGHT: float = 72.0
const CANNON_OVERLAY_OFFSET_Y: float = -180.0
const CANNON_ZONE_TOP: float = 600.0 + CANNON_OVERLAY_OFFSET_Y
const CANNON_MUZZLE_POS: Vector2 = Vector2(160.0, 616.0 + CANNON_OVERLAY_OFFSET_Y)
const WALL_IMPACT_POS: Vector2 = Vector2(160.0, 36.0)
const CANNON_BLAST_CENTER: Vector2 = Vector2(160.0, 640.0 + CANNON_OVERLAY_OFFSET_Y)

signal wall_break_transition_finished
signal next_wall_intro_finished

const CANNON_ROLL_DISTANCE: float = 200.0
const CANNON_ROLL_FORWARD_DURATION: float = 1.4
const CANNON_ROLL_BACK_DURATION: float = 1.0

var _wall_visual: Node2D
var _cannon_visual: Node2D
var _main_cannon: Node
var _cannon_shot_scene: PackedScene
var _wall_impact_scene: PackedScene
var _muzzle_blast_scene: PackedScene
var _vfx_container: Node2D
var _cannon_overlay_local_pos: Vector2 = Vector2.ZERO
var _cannon_roll_offset_y: float = 0.0
var _roll_tween: Tween

func _ready() -> void:
	_wall_visual = get_node_or_null("WallVisual") as Node2D
	_cannon_visual = get_node_or_null("CannonVisual") as Node2D
	if _cannon_visual:
		_cannon_overlay_local_pos = _cannon_visual.position
		var main: Node = get_tree().current_scene
		if main:
			var overlay: CanvasLayer = main.get_node_or_null("CannonOverlay") as CanvasLayer
			if overlay:
				_cannon_visual.reparent(overlay)
	# Hide fortifications if present in the scene
	if _wall_visual:
		for child in _wall_visual.get_children():
			if child.name.begins_with("Fortification"):
				child.visible = false
				child.set_process(false)
				child.set_physics_process(false)
	_cannon_shot_scene = load("res://scenes/combat/cannon_shot_vfx.tscn") as PackedScene
	_wall_impact_scene = load("res://scenes/combat/wall_impact_vfx.tscn") as PackedScene
	_muzzle_blast_scene = load("res://scenes/combat/muzzle_blast_vfx.tscn") as PackedScene
	_vfx_container = get_node_or_null("VFXContainer") as Node2D
	if _vfx_container == null:
		_vfx_container = Node2D.new()
		_vfx_container.name = "VFXContainer"
		add_child(_vfx_container)

func _process(_delta: float) -> void:
	if _cannon_visual and _cannon_visual.get_parent() != self:
		_cannon_visual.global_position = global_position + _cannon_overlay_local_pos + Vector2(0.0, CANNON_OVERLAY_OFFSET_Y + _cannon_roll_offset_y)

func set_main_cannon(cannon: Node) -> void:
	if _main_cannon and _main_cannon.has_signal("main_fired") and _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.disconnect(_on_main_fired)
	_main_cannon = cannon
	if _main_cannon and _main_cannon.has_signal("main_fired") and not _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.connect(_on_main_fired)

func _exit_tree() -> void:
	if _main_cannon and _main_cannon.has_signal("main_fired") and _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.disconnect(_on_main_fired)

func _on_main_fired(_damage: int) -> void:
	# Muzzle blast VFX
	if _muzzle_blast_scene and _vfx_container:
		var blast: Node2D = _muzzle_blast_scene.instantiate() as Node2D
		if blast and blast.has_method("setup"):
			blast.setup(CANNON_BLAST_CENTER)
			_vfx_container.add_child(blast)
	# Cannon shot projectile travels to wall, then wall impact VFX
	if _cannon_shot_scene and _wall_impact_scene and _vfx_container:
		var shot: Node2D = _cannon_shot_scene.instantiate() as Node2D
		if shot and shot.has_method("setup"):
			shot.setup(CANNON_MUZZLE_POS, WALL_IMPACT_POS, _spawn_wall_impact)
			_vfx_container.add_child(shot)

func _spawn_wall_impact(impact_pos: Vector2) -> void:
	if _wall_impact_scene and _vfx_container:
		var impact: Node2D = _wall_impact_scene.instantiate() as Node2D
		if impact and impact.has_method("setup"):
			impact.setup(impact_pos)
			_vfx_container.add_child(impact)

func set_wall_index(_wall_index: int) -> void:
	pass

func play_wall_destroyed_transition() -> void:
	if _wall_visual and _wall_visual.has_method("play_explosion"):
		_wall_visual.play_explosion()
	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.tween_property(self, "_cannon_roll_offset_y", -CANNON_ROLL_DISTANCE, CANNON_ROLL_FORWARD_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.3)

func play_next_wall_intro() -> void:
	if _wall_visual and _wall_visual.has_method("play_rebuild"):
		_wall_visual.play_rebuild()
	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.tween_property(self, "_cannon_roll_offset_y", 0.0, CANNON_ROLL_BACK_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
