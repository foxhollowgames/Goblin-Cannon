extends Control
## DebugOverlay (§6). set_energy, set_stats_cached; status effect alerts (source, reason, target).

var _energy_label: Label
var _status_alert_label: Label

func _ready() -> void:
	visible = false  # Shown only when user presses D (GameCoordinator toggles)
	_energy_label = get_node_or_null("EnergyLabel") as Label
	if _energy_label:
		_energy_label.visible = true  # Show when overlay is visible
		_update_energy_display(0, 0, 0)
	_status_alert_label = get_node_or_null("StatusAlertLabel") as Label
	if _status_alert_label == null:
		_status_alert_label = Label.new()
		_status_alert_label.name = "StatusAlertLabel"
		_status_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_alert_label.add_theme_font_size_override("font_size", 11)
		_status_alert_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.9, 1))
		_status_alert_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_status_alert_label.position = Vector2(960, 390)
		_status_alert_label.custom_minimum_size = Vector2(400, 0)
		_status_alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_status_alert_label)
	_status_alert_label.text = ""

func set_energy(main: int, sidearm: int, shield: int) -> void:
	_update_energy_display(main, sidearm, shield)

func _update_energy_display(main: int, sidearm: int, shield: int) -> void:
	if _energy_label:
		# main/sidearm are internal (÷100 for display); shield is already in points
		_energy_label.text = "Energy: %d | Sidearm: %d | Shield: %d" % [main / 100, sidearm / 100, shield]

## Called when status effects are applied. Shows what applied it, why, and what is affected (overlay + console).
func add_status_alert(source: String, reason: String, target: String, status_effects: Dictionary) -> void:
	var parts: PackedStringArray = []
	for id in status_effects:
		var stacks: int = int(status_effects[id])
		if stacks > 0:
			parts.append("%s x%d" % [str(id), stacks])
	var effects_str: String = ", ".join(parts)
	var msg: String = "[Status] %s (%s) → %s: %s" % [source, reason, target, effects_str]
	print(msg)
	if _status_alert_label != null:
		_status_alert_label.text = msg

func set_stats_cached(_stats: Dictionary) -> void:
	pass
