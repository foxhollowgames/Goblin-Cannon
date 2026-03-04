extends Node2D
## Visual battlefield: wall at top, cannon at bottom. Spawns minions and drives fortification timers.
## CombatManager calls spawn_minion_if_due() and fortification_tick() from sim_tick.

signal cannon_damaged(amount: int)
## Emitted when status effects are applied. source=what applied it, reason=why, target=what is affected, status_effects=dict.
signal status_effect_applied(source: String, reason: String, target: String, status_effects: Dictionary)

const BATTLEFIELD_WIDTH: float = 320.0
const BATTLEFIELD_HEIGHT: float = 720.0
const WALL_HEIGHT: float = 72.0
## Vertical offset so cannon zone, projectiles, and minion targets match the raised cannon visual (positive = down, negative = up).
const CANNON_OVERLAY_OFFSET_Y: float = -180.0
const CANNON_ZONE_TOP: float = 600.0 + CANNON_OVERLAY_OFFSET_Y
const MINION_SPAWN_Y: float = 68.0
const MINION_DAMAGE: int = 2
const SPAWN_INTERVAL_TICKS: int = 240  # 4 seconds at 60 ticks/s
const CANNON_MUZZLE_POS: Vector2 = Vector2(160.0, 616.0 + CANNON_OVERLAY_OFFSET_Y)
const WALL_IMPACT_POS: Vector2 = Vector2(160.0, 36.0)
const CANNON_BLAST_CENTER: Vector2 = Vector2(160.0, 640.0 + CANNON_OVERLAY_OFFSET_Y)
const MUZZLE_BLAST_RADIUS: float = 85.0
const MUZZLE_BLAST_DAMAGE: int = 999  # kills 1-HP melee minions on wall 1
## Muzzle positions for sidearms (slot order = Sidearms container child order). First matches original pistol; spacing matches CannonVisual.
const SIDEARM_MUZZLE_POS: Vector2 = Vector2(188.0, 618.0 + CANNON_OVERLAY_OFFSET_Y)
const SIDEARM_MUZZLE_SPACING: float = 30.0
const MAX_SIDEARM_SLOTS: int = 6

func _get_sidearm_muzzle_pos(slot: int) -> Vector2:
	return SIDEARM_MUZZLE_POS + Vector2(clampi(slot, 0, MAX_SIDEARM_SLOTS - 1) * SIDEARM_MUZZLE_SPACING, 0.0)
const SIDEARM_ENERGY_LABEL_FADE_DURATION: float = 1.0
const SIDEARM_ENERGY_LABEL_FLOAT_OFFSET: float = -28.0  # pixels to move up
const COLOR_SIDEARM_ENERGY: Color = Color(0.95, 0.35, 0.3, 1)
## Staging: cannon and minions cycle through fire → frozen → lightning so you can verify status visuals. Set true to test.
@export var staging_status_demo: bool = false
const STAGING_MINION_CYCLE_TICKS: int = 180  # 3 seconds at 60 ticks/s

var _minions_container: Node2D
var _projectiles_container: Node2D
var _wall_visual: Node2D
var _cannon_visual: Node2D
var _fortifications: Array[Node] = []  # Up to 3; only first (wall_index+1) are active per wall.
var _current_wall_index: int = 0  # 0=Wall 1 (1 fort), 1=Wall 2 (2 forts), 2=Boss (3 forts)
var _spawn_ticks_until_next: int = 120  # first spawn after 2 seconds
var _minion_scene: PackedScene
var _main_cannon: Node
## Sidearm nodes in slot order (children of Sidearms that have sidearm_fired signal).
var _sidearms: Array[Node] = []
var _sidearm_connections: Array[Callable] = []
var _sidearms_container: Node = null
var _cannon_shot_scene: PackedScene
var _wall_impact_scene: PackedScene
var _muzzle_blast_scene: PackedScene
var _sidearm_shot_scene: PackedScene
var _sidearm_muzzle_scene: PackedScene
var _vfx_container: Node2D
var _staging_cannon_cycle: int = 0   # 0=fire, 1=frozen, 2=lightning
var _staging_minion_cycle: int = 0
var _staging_minion_ticks: int = 0
## When cannon is reparented to CannonOverlay, we keep it in sync with battlefield position.
var _cannon_overlay_local_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_minions_container = get_node_or_null("MinionsContainer") as Node2D
	if _minions_container == null:
		_minions_container = Node2D.new()
		_minions_container.name = "MinionsContainer"
		add_child(_minions_container)
	_projectiles_container = get_node_or_null("ProjectilesContainer") as Node2D
	if _projectiles_container == null:
		_projectiles_container = Node2D.new()
		_projectiles_container.name = "ProjectilesContainer"
		add_child(_projectiles_container)
	_wall_visual = get_node_or_null("WallVisual") as Node2D
	_cannon_visual = get_node_or_null("CannonVisual") as Node2D
	# Reparent cannon to overlay layer so it draws on top of the energy buckets UI
	if _cannon_visual:
		_cannon_overlay_local_pos = _cannon_visual.position
		var main: Node = get_tree().current_scene
		if main:
			var overlay: CanvasLayer = main.get_node_or_null("CannonOverlay") as CanvasLayer
			if overlay:
				_cannon_visual.reparent(overlay)
	# Fortifications are children of WallVisual (Fortification1, Fortification2, Fortification3)
	if _wall_visual:
		for child in _wall_visual.get_children():
			if child.name.begins_with("Fortification"):
				_fortifications.append(child)
		# Sort by name so Fortification1, Fortification2, Fortification3 order
		_fortifications.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
		_update_fortification_visibility()
	_minion_scene = load("res://scenes/combat/minion.tscn") as PackedScene
	_cannon_shot_scene = load("res://scenes/combat/cannon_shot_vfx.tscn") as PackedScene
	_wall_impact_scene = load("res://scenes/combat/wall_impact_vfx.tscn") as PackedScene
	_muzzle_blast_scene = load("res://scenes/combat/muzzle_blast_vfx.tscn") as PackedScene
	_sidearm_shot_scene = load("res://scenes/combat/sidearm_shot_vfx.tscn") as PackedScene
	_sidearm_muzzle_scene = load("res://scenes/combat/sidearm_muzzle_vfx.tscn") as PackedScene
	_vfx_container = get_node_or_null("VFXContainer") as Node2D
	if _vfx_container == null:
		_vfx_container = Node2D.new()
		_vfx_container.name = "VFXContainer"
		add_child(_vfx_container)
	_connect_main_cannon()
	_connect_sidearm()

func _process(_delta: float) -> void:
	if _cannon_visual and _cannon_visual.get_parent() != self:
		_cannon_visual.global_position = global_position + _cannon_overlay_local_pos + Vector2(0.0, CANNON_OVERLAY_OFFSET_Y)
	if _cannon_visual and _cannon_visual.has_method("set_sidearm_cooldowns") and _sidearms.size() > 0:
		var cooldowns: Array = []
		for s in _sidearms:
			cooldowns.append(s.has_method("is_on_cooldown") and s.is_on_cooldown())
		_cannon_visual.set_sidearm_cooldowns(cooldowns)

func get_wall_center_y() -> float:
	return WALL_HEIGHT * 0.5

func get_cannon_center_y() -> float:
	return CANNON_ZONE_TOP + (BATTLEFIELD_HEIGHT - CANNON_ZONE_TOP) * 0.5

## Position (in battlefield/local space) that fortification projectiles should aim at.
func get_cannon_target_position() -> Vector2:
	return CANNON_BLAST_CENTER

func get_battlefield_width() -> float:
	return BATTLEFIELD_WIDTH

## Called by CombatManager each sim tick. Returns true if a minion was spawned.
func spawn_minion_if_due(sim_tick: int) -> bool:
	_spawn_ticks_until_next -= 1
	if _spawn_ticks_until_next > 0:
		return false
	_spawn_ticks_until_next = SPAWN_INTERVAL_TICKS
	spawn_minion(sim_tick)
	return true

func spawn_minion(jitter_seed: int = 0) -> void:
	if _minion_scene == null or _minions_container == null:
		return
	var minion: Node2D = _minion_scene.instantiate() as Node2D
	if minion == null:
		return
	# Deterministic jitter (no RNG in nodes per GDD §1.11)
	var jitter: int = (jitter_seed * 13) % 121 - 60
	var spawn_x: float = BATTLEFIELD_WIDTH * 0.5 + float(jitter)
	minion.position = Vector2(spawn_x, MINION_SPAWN_Y)
	if minion.has_method("set_target_y"):
		minion.set_target_y(CANNON_ZONE_TOP + 40.0)
	_minions_container.add_child(minion)
	if minion.has_signal("deal_damage"):
		minion.deal_damage.connect(_on_minion_deal_damage)

func _on_minion_deal_damage(amount: int) -> void:
	_on_cannon_hit(amount)

func _on_cannon_hit(damage: int) -> void:
	cannon_damaged.emit(damage)

## Wall 1 = 1 fort, Wall 2 = 2 forts, Boss = 3 forts. Call after init and when advancing wall.
func set_wall_index(wall_index: int) -> void:
	_current_wall_index = clampi(wall_index, 0, 2)
	_update_fortification_visibility()

func _update_fortification_visibility() -> void:
	var count: int = _current_wall_index + 1  # 1, 2, or 3
	for i in _fortifications.size():
		var node: Node = _fortifications[i]
		var active: bool = (i < count)
		node.visible = active
		node.set_process(active)
		node.set_physics_process(active)

## Call once per sim tick; fortifications with timers will shoot when ready.
## repair_scale: 1.0 at wall 0, lower at later walls so disabled fortifications repair faster.
func fortification_tick(sim_tick: int) -> void:
	var count: int = mini(_current_wall_index + 1, _fortifications.size())
	var repair_scale: float = 1.0 - _current_wall_index * 0.15  # wall 0 = 10s, wall 1 = 8.5s, wall 2 = 7s
	repair_scale = clampf(repair_scale, 0.5, 1.0)
	for i in count:
		var node: Node = _fortifications[i]
		if node.has_method("sim_tick"):
			node.sim_tick(sim_tick, repair_scale)
	# Status tick for all minions (decay stacks, fire DoT)
	for child in _minions_container.get_children():
		if child.has_method("status_tick"):
			child.status_tick(sim_tick)
	# Status tick for cannon and fortifications (decay stacks)
	if _cannon_visual and _cannon_visual.has_method("status_tick"):
		_cannon_visual.status_tick(sim_tick)
	for i in count:
		var node: Node = _fortifications[i]
		if node.has_method("status_tick"):
			node.status_tick(sim_tick)
	# Staging: periodically apply cycling status to minions, cannon, and fortifications
	if staging_status_demo:
		_staging_minion_ticks += 1
		if _staging_minion_ticks >= STAGING_MINION_CYCLE_TICKS:
			_staging_minion_ticks = 0
			var effects: Dictionary = _staging_minion_status_effects()
			var center: Vector2 = Vector2(BATTLEFIELD_WIDTH * 0.5, BATTLEFIELD_HEIGHT * 0.5)
			var radius: float = BATTLEFIELD_HEIGHT * 0.6
			apply_status_to_minions_in_radius(center, radius, effects, "staging", "demo")
			if _cannon_visual and _cannon_visual.has_method("apply_status"):
				_apply_status_effects_to_node(_cannon_visual, effects, "staging", "demo")
			for node in _fortifications:
				if node.has_method("apply_status"):
					_apply_status_effects_to_node(node, effects, "staging", "demo")
			_staging_minion_cycle = (_staging_minion_cycle + 1) % 3

func get_minions_container() -> Node2D:
	return _minions_container

func get_projectiles_container() -> Node2D:
	return _projectiles_container

func _connect_main_cannon() -> void:
	var main: Node = get_parent()
	if main:
		main = main.get_parent()
	if main:
		_main_cannon = main.get_node_or_null("SystemsContainer/MainCannon")
		if _main_cannon and _main_cannon.has_signal("main_fired"):
			_main_cannon.main_fired.connect(_on_main_fired)

func _connect_sidearm() -> void:
	_disconnect_sidearms()
	var main: Node = get_parent()
	if main:
		main = main.get_parent()
	if main:
		var sidearms: Node = main.get_node_or_null("SystemsContainer/Sidearms")
		if sidearms:
			for child in sidearms.get_children():
				if child.has_signal("sidearm_fired"):
					var slot: int = _sidearms.size()
					_sidearms.append(child)
					var callable_bound: Callable = _on_sidearm_fired.bind(slot)
					_sidearm_connections.append(callable_bound)
					child.sidearm_fired.connect(callable_bound)
			# Re-connect when new sidearms are added at runtime (e.g. after drafting Sniper)
			if sidearms.has_signal("sidearms_updated"):
				if _sidearms_container != null and _sidearms_container != sidearms and _sidearms_container.sidearms_updated.is_connected(_on_sidearms_updated):
					_sidearms_container.sidearms_updated.disconnect(_on_sidearms_updated)
				if _sidearms_container != sidearms or not sidearms.sidearms_updated.is_connected(_on_sidearms_updated):
					_sidearms_container = sidearms
					sidearms.sidearms_updated.connect(_on_sidearms_updated)

func _on_sidearms_updated() -> void:
	_connect_sidearm()

func _disconnect_sidearms() -> void:
	for i in range(_sidearms.size()):
		if i < _sidearm_connections.size():
			var s: Node = _sidearms[i]
			if is_instance_valid(s) and s.has_signal("sidearm_fired"):
				s.sidearm_fired.disconnect(_sidearm_connections[i])
	_sidearms.clear()
	_sidearm_connections.clear()

func _exit_tree() -> void:
	if _main_cannon and _main_cannon.has_signal("main_fired") and _main_cannon.main_fired.is_connected(_on_main_fired):
		_main_cannon.main_fired.disconnect(_on_main_fired)
	if _sidearms_container and _sidearms_container.has_signal("sidearms_updated") and _sidearms_container.sidearms_updated.is_connected(_on_sidearms_updated):
		_sidearms_container.sidearms_updated.disconnect(_on_sidearms_updated)
	_sidearms_container = null
	_disconnect_sidearms()

func _on_main_fired(damage: int) -> void:
	# Main shot damages fortifications only 15%; rest comes from sidearms, status, or abilities.
	var fort_damage: int = ceili(damage * 0.15)
	damage_fortifications(fort_damage)
	# Muzzle blast damages/kills melee minions near cannon (wall 1 = 1 HP, so they die). No status by default (GDD); upgrades can add via config.
	var status_effects: Dictionary = {}
	if staging_status_demo:
		status_effects = _staging_cannon_status_effects()
		_staging_cannon_cycle = (_staging_cannon_cycle + 1) % 3
	elif _main_cannon and _main_cannon.has_method("get_status_effects_on_fire"):
		status_effects = _main_cannon.get_status_effects_on_fire()
	# Staging: use 0 damage so minions survive and show status; otherwise normal muzzle blast damage
	var blast_damage: int = 0 if staging_status_demo else MUZZLE_BLAST_DAMAGE
	damage_minions_near_cannon(MUZZLE_BLAST_RADIUS, blast_damage, status_effects)
	# Muzzle blast VFX
	if _muzzle_blast_scene and _vfx_container:
		var blast: Node2D = _muzzle_blast_scene.instantiate() as Node2D
		if blast and blast.has_method("setup"):
			blast.setup(CANNON_BLAST_CENTER)
			_vfx_container.add_child(blast)
	# Ball travels to wall, then wall impact VFX
	if _cannon_shot_scene and _wall_impact_scene and _vfx_container:
		var shot: Node2D = _cannon_shot_scene.instantiate() as Node2D
		if shot and shot.has_method("setup"):
			shot.setup(CANNON_MUZZLE_POS, WALL_IMPACT_POS, _spawn_wall_impact)
			_vfx_container.add_child(shot)

func _on_sidearm_fired(_damage: int, energy_cost_display: int, _status_effects: Dictionary = {}, _is_aoe: bool = false, _aoe_radius: float = 0.0, slot: int = 0) -> void:
	# Each sidearm fires at minions from its slot muzzle. Status is applied by CombatManager via damage_frontmost_minion(damage, status_effects).
	var muzzle_pos: Vector2 = _get_sidearm_muzzle_pos(slot)
	_show_sidearm_energy_cost(muzzle_pos, energy_cost_display)
	# Muzzle burst VFX (red-orange so player sees sidearm firing)
	if _sidearm_muzzle_scene and _vfx_container:
		var burst: Node2D = _sidearm_muzzle_scene.instantiate() as Node2D
		if burst and burst.has_method("setup"):
			burst.setup(muzzle_pos)
			_vfx_container.add_child(burst)
	# Projectile only when there is a minion to hit; shot goes to frontmost minion, not the wall.
	var target_pos: Vector2 = _get_frontmost_minion_position()
	if target_pos != Vector2.INF and _sidearm_shot_scene and _vfx_container:
		var shot: Node2D = _sidearm_shot_scene.instantiate() as Node2D
		if shot and shot.has_method("setup"):
			shot.setup(muzzle_pos, target_pos, _spawn_minion_impact)
			_vfx_container.add_child(shot)

func _spawn_wall_impact(impact_pos: Vector2) -> void:
	if _wall_impact_scene and _vfx_container:
		var impact: Node2D = _wall_impact_scene.instantiate() as Node2D
		if impact and impact.has_method("setup"):
			impact.setup(impact_pos)
			_vfx_container.add_child(impact)

func _show_sidearm_energy_cost(muzzle_pos: Vector2, energy_cost_display: int) -> void:
	if _vfx_container == null or energy_cost_display <= 0:
		return
	var label: Label = Label.new()
	label.text = "-%d" % energy_cost_display
	label.position = muzzle_pos + Vector2(6, -12)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_SIDEARM_ENERGY)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vfx_container.add_child(label)
	var end_pos: Vector2 = label.position + Vector2(0, SIDEARM_ENERGY_LABEL_FLOAT_OFFSET)
	var t: Tween = label.create_tween()
	t.tween_property(label, "position", end_pos, SIDEARM_ENERGY_LABEL_FADE_DURATION * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(label, "modulate:a", 0.0, SIDEARM_ENERGY_LABEL_FADE_DURATION).set_delay(0.2).set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(label.queue_free)

func _spawn_minion_impact(impact_pos: Vector2) -> void:
	# Small impact at minion position (sidearm hit); reuse wall impact scene for a quick burst.
	if _wall_impact_scene and _vfx_container:
		var impact: Node2D = _wall_impact_scene.instantiate() as Node2D
		if impact and impact.has_method("setup"):
			impact.setup(impact_pos)
			_vfx_container.add_child(impact)

## Staging: one status per cycle (fire → frozen → lightning). Cannon uses this on each main_fired.
func _staging_cannon_status_effects() -> Dictionary:
	match _staging_cannon_cycle:
		0: return { Constants.STATUS_FIRE: 2 }
		1: return { Constants.STATUS_FROZEN: 2 }
		2: return { Constants.STATUS_LIGHTNING: 2 }
	return {}

## Staging: one status per cycle applied to all minions periodically.
func _staging_minion_status_effects() -> Dictionary:
	match _staging_minion_cycle:
		0: return { Constants.STATUS_FIRE: 2 }
		1: return { Constants.STATUS_FROZEN: 2 }
		2: return { Constants.STATUS_LIGHTNING: 2 }
	return {}

## Returns position of frontmost minion (closest to cannon = largest Y) in local space, or Vector2.INF if none. Public for CombatManager AOE targeting.
func get_frontmost_minion_position() -> Vector2:
	return _get_frontmost_minion_position()

func _get_frontmost_minion_position() -> Vector2:
	if _minions_container == null:
		return Vector2.INF
	var frontmost: Node2D = null
	var best_y: float = -INF
	for child in _minions_container.get_children():
		if not child is Node2D or not child.has_method("take_damage"):
			continue
		if child.position.y > best_y:
			best_y = child.position.y
			frontmost = child as Node2D
	if frontmost != null:
		return frontmost.position
	return Vector2.INF

## Apply a status_effects Dictionary to one node and emit status_effect_applied for alerts. source/reason describe what applied it and why.
func _apply_status_effects_to_node(node: Node, status_effects: Dictionary, source: String = "unknown", reason: String = "unknown") -> void:
	if status_effects.is_empty() or not node.has_method("apply_status"):
		return
	for status_id in status_effects:
		var stacks: int = int(status_effects[status_id])
		if stacks > 0:
			var id_key: StringName = status_id as StringName if status_id is StringName else StringName(str(status_id))
			node.apply_status(id_key, stacks)
	var target_desc: String = node.name if node.name else node.get_class()
	status_effect_applied.emit(source, reason, target_desc, status_effects)

## Cannon and sidearm do NOT apply status by default (GDD). Status comes from balls or upgrades.
## status_effects: optional dict (e.g. { "fire": 1 }) from cannon/sidearm config or upgrades; default {}.
func damage_minions_near_cannon(radius: float, damage: int, status_effects: Dictionary = {}) -> void:
	if _minions_container == null:
		return
	var to_damage: Array[Node] = []
	for child in _minions_container.get_children():
		if not child.has_method("take_damage"):
			continue
		var dist: float = child.position.distance_to(CANNON_BLAST_CENTER)
		if dist <= radius:
			to_damage.append(child)
	for node in to_damage:
		node.take_damage(damage)
		_apply_status_effects_to_node(node, status_effects, "main_cannon", "muzzle_blast")

## Damage all minions within radius of center (e.g. AOE sidearm). Applies status_effects to each. Returns count damaged.
func damage_minions_in_radius(center: Vector2, radius: float, damage: int, status_effects: Dictionary = {}) -> int:
	if _minions_container == null or damage <= 0 or radius <= 0:
		return 0
	var count: int = 0
	for child in _minions_container.get_children():
		if not child is Node2D or not child.has_method("take_damage"):
			continue
		if child.position.distance_to(center) <= radius:
			child.take_damage(damage)
			_apply_status_effects_to_node(child, status_effects, "sidearm", "aoe_shot")
			count += 1
	return count

## Sidearm target: frontmost minion. Returns true if a minion was damaged.
## Cannon/sidearm do NOT apply status by default; pass status_effects from config/upgrades (or from ball abilities) to apply.
func damage_frontmost_minion(damage: int, status_effects: Dictionary = {}) -> bool:
	if _minions_container == null or damage <= 0:
		return false
	var frontmost: Node2D = null
	var best_y: float = -INF
	for child in _minions_container.get_children():
		if not child is Node2D or not child.has_method("take_damage"):
			continue
		if child.position.y > best_y:
			best_y = child.position.y
			frontmost = child as Node2D
	if frontmost != null:
		frontmost.take_damage(damage)
		_apply_status_effects_to_node(frontmost, status_effects, "sidearm", "shot")
		return true
	return false

## GDD: Status effects come from balls or upgrades, not cannon/sidearm by default.
## Apply status to the frontmost minion (no damage). source/reason for alerts (e.g. "ball_ability", "peg_hit"). Returns true if a minion was found.
func apply_status_to_frontmost_minion(status_effects: Dictionary, source: String = "ball_ability", reason: String = "unknown") -> bool:
	if _minions_container == null or status_effects.is_empty():
		return false
	var frontmost: Node2D = null
	var best_y: float = -INF
	for child in _minions_container.get_children():
		if not child is Node2D or not child.has_method("apply_status"):
			continue
		if child.position.y > best_y:
			best_y = child.position.y
			frontmost = child as Node2D
	if frontmost != null:
		_apply_status_effects_to_node(frontmost, status_effects, source, reason)
		return true
	return false

## Apply status to all minions within radius of center (no damage). source/reason for alerts.
func apply_status_to_minions_in_radius(center: Vector2, radius: float, status_effects: Dictionary, source: String = "unknown", reason: String = "unknown") -> void:
	if _minions_container == null or status_effects.is_empty():
		return
	for child in _minions_container.get_children():
		if not child.has_method("apply_status"):
			continue
		if child.position.distance_to(center) <= radius:
			_apply_status_effects_to_node(child, status_effects, source, reason)

## Apply status to all active fortifications (wall turrets). source/reason for alerts.
func apply_status_to_active_fortifications(status_effects: Dictionary, source: String = "unknown", reason: String = "unknown") -> void:
	if status_effects.is_empty():
		return
	var count: int = mini(_current_wall_index + 1, _fortifications.size())
	for i in count:
		var node: Node = _fortifications[i]
		if node.has_method("apply_status"):
			_apply_status_effects_to_node(node, status_effects, source, reason)

## Damage all active fortifications (same damage to each). Called when main cannon hits the wall.
func damage_fortifications(damage: int) -> void:
	if damage <= 0:
		return
	var count: int = mini(_current_wall_index + 1, _fortifications.size())
	for i in count:
		var node: Node = _fortifications[i]
		if node.has_method("take_damage"):
			node.take_damage(damage)

## Called from GameCoordinator when center UI is updated. Passes shield (display units) to cannon visual.
func set_cannon_shield(display_value: int) -> void:
	if _cannon_visual and _cannon_visual.has_method("set_shield"):
		_cannon_visual.set_shield(display_value)
