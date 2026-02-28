extends Node
## CombatManager (§6.11). Owns wall HP, waves, target selection. Receives main_fired, sidearm_fired.
## When current wall HP hits 0, advances to next wall (if any) and resets HP.

signal wall_destroyed

var _wall_hp: int = 100
var _wall_hp_max: int = 100
var _wall_destroyed_emitted: bool = false
var _current_wave: int = 0
var _wall_names: Array = []  # Ordered wall names from city
var _city_display_name: String = ""  # e.g. "Halfling Shire" for conquest goal label
var _current_wall_index: int = 0
var _cannon_hp: int = 100
var _cannon_hp_max: int = 100
var _battlefield: Node
var _shield_pool: Node

## Initialize from current city (Halfling Shire etc). Call at run start.
func init_from_city(city: CityDefinition) -> void:
	if city == null:
		return
	_wall_hp_max = city.wall_hp_max
	_wall_names = city.get_effective_wall_names()
	_city_display_name = city.display_name if not city.display_name.is_empty() else ""
	_current_wall_index = 0
	_wall_hp = _wall_hp_max
	_wall_destroyed_emitted = false

func _ready() -> void:
	var main: Node = get_parent()
	_battlefield = main.get_node_or_null("CombatContainer/BattlefieldView")
	if _battlefield and _battlefield.has_signal("cannon_damaged"):
		_battlefield.cannon_damaged.connect(_on_cannon_damaged)
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		_shield_pool = sys.get_node_or_null("ShieldPool")
		var mc: Node = sys.get_node_or_null("MainCannon")
		if mc and mc.has_signal("main_fired"):
			mc.main_fired.connect(_on_main_fired)
		var sidearms: Node = sys.get_node_or_null("Sidearms")
		if sidearms:
			var rf: Node = sidearms.get_node_or_null("RapidFire")
			if rf and rf.has_signal("sidearm_fired"):
				rf.sidearm_fired.connect(_on_sidearm_fired)

func _exit_tree() -> void:
	if _battlefield and _battlefield.has_signal("cannon_damaged") and _battlefield.cannon_damaged.is_connected(_on_cannon_damaged):
		_battlefield.cannon_damaged.disconnect(_on_cannon_damaged)
	var main: Node = get_parent()
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		var mc: Node = sys.get_node_or_null("MainCannon")
		if mc and mc.has_signal("main_fired") and mc.main_fired.is_connected(_on_main_fired):
			mc.main_fired.disconnect(_on_main_fired)
		var sidearms: Node = sys.get_node_or_null("Sidearms")
		if sidearms:
			var rf: Node = sidearms.get_node_or_null("RapidFire")
			if rf and rf.has_signal("sidearm_fired") and rf.sidearm_fired.is_connected(_on_sidearm_fired):
				rf.sidearm_fired.disconnect(_on_sidearm_fired)

func _on_cannon_damaged(amount: int) -> void:
	var shield_damage: int = 0
	if _shield_pool and _shield_pool.has_method("get_current_shield_points") and _shield_pool.has_method("consume_shield_points"):
		var points: int = _shield_pool.get_current_shield_points()
		shield_damage = mini(amount, points)
		if shield_damage > 0:
			_shield_pool.consume_shield_points(shield_damage)
	var cannon_damage: int = amount - shield_damage
	_cannon_hp -= cannon_damage
	if _cannon_hp < 0:
		_cannon_hp = 0

func sim_tick(tick: int) -> void:
	if _battlefield:
		if _battlefield.has_method("spawn_minion_if_due"):
			_battlefield.spawn_minion_if_due(tick)
		if _battlefield.has_method("fortification_tick"):
			_battlefield.fortification_tick(tick)

func _emit_wall_destroyed_once() -> void:
	if _wall_hp == 0 and not _wall_destroyed_emitted:
		_wall_destroyed_emitted = true
		wall_destroyed.emit()
		# Do NOT advance here — advance when player completes the wall-break reward (RewardsManager signals, then coordinator calls advance_to_next_wall).

func _on_main_fired(damage: int) -> void:
	_wall_hp -= damage
	if _wall_hp < 0:
		_wall_hp = 0
	_emit_wall_destroyed_once()

func _on_sidearm_fired(damage: int, _energy_cost_display: int, status_effects: Dictionary = {}) -> void:
	# Sidearms only ever target minions; they never damage the wall. No status by default (GDD); upgrades/sidearm config can add.
	if _battlefield and _battlefield.has_method("damage_frontmost_minion"):
		_battlefield.damage_frontmost_minion(damage, status_effects)

func get_wall_hp() -> int:
	return _wall_hp

func get_wall_hp_max() -> int:
	return _wall_hp_max

func get_cannon_hp() -> int:
	return _cannon_hp

func get_cannon_hp_max() -> int:
	return _cannon_hp_max

func _advance_to_next_wall() -> void:
	_current_wall_index += 1
	if _current_wall_index < _wall_names.size():
		_wall_hp = _wall_hp_max
		_wall_destroyed_emitted = false

## Call when the player has finished the wall-break reward. Advances to next wall and resets HP so damage applies to the new wall.
func advance_to_next_wall() -> void:
	_advance_to_next_wall()

## City display name for conquest goal label (e.g. "Halflings" or "Halfling Shire").
func get_city_display_name() -> String:
	return _city_display_name

func get_wall_names() -> Array:
	return _wall_names.duplicate()

func get_current_wall_index() -> int:
	return _current_wall_index

## Current gate/wall name for UI. Empty if city conquered (no more walls).
func get_current_gate_name() -> String:
	if _current_wall_index >= 0 and _current_wall_index < _wall_names.size():
		return str(_wall_names[_current_wall_index])
	return ""

func get_target_for(_source_id: StringName) -> Node:
	return null  # Slice: frontmost unit or wall

## GDD §8: Apply status from ball abilities. reason: "peg_hit" or "ball_reached_bottom" for alerts.
func apply_ball_status(status_effects: Dictionary, reason: String = "unknown") -> void:
	if status_effects.is_empty() or _battlefield == null:
		return
	if _battlefield.has_method("apply_status_to_frontmost_minion"):
		_battlefield.apply_status_to_frontmost_minion(status_effects, "ball_ability", reason)
