extends Control
## Updates Village Gate fortification, Goblin Cannon health/balls/charge from game state.

var _fort_label: Label
var _fort_bar: ProgressBar
var _health_label: Label
var _balls_label: Label
var _charge_label: Label
var _charge_progress: ProgressBar

func _ready() -> void:
	var vg: PanelContainer = get_node_or_null("CannonColumn/VillageGate") as PanelContainer
	if vg:
		var vbox: VBoxContainer = vg.get_node_or_null("VBox") as VBoxContainer
		if vbox:
			_fort_label = vbox.get_node_or_null("FortificationLabel") as Label
			_fort_bar = vbox.get_node_or_null("FortificationBar") as ProgressBar
	var gc: PanelContainer = get_node_or_null("CannonColumn/GoblinCannon") as PanelContainer
	if gc:
		var vbox: VBoxContainer = gc.get_node_or_null("VBox") as VBoxContainer
		if vbox:
			_health_label = vbox.get_node_or_null("HealthBar/HealthValue") as Label
			_balls_label = vbox.get_node_or_null("BallsLabel") as Label
			_charge_label = vbox.get_node_or_null("ChargeBar/ChargeValue") as Label

func set_fortification(current: int, maximum: int) -> void:
	if _fort_label:
		_fort_label.text = "Fortification %d/%d" % [current, maximum]
	if _fort_bar:
		_fort_bar.max_value = float(maximum)
		_fort_bar.value = float(current)

func set_health(current: int, maximum: int) -> void:
	if _health_label:
		_health_label.text = "%d/%d" % [current, maximum]

func set_balls(current: int, maximum: int) -> void:
	if _balls_label:
		_balls_label.text = "BALLS: %d/%d" % [current, maximum]

func set_charge(current: int, threshold: int) -> void:
	if _charge_label:
		_charge_label.text = "%d/%d" % [current / 100, threshold / 100]
	if _charge_progress:
		_charge_progress.max_value = float(threshold)
		_charge_progress.value = float(current)
