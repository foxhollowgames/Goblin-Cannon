extends Node
## Central repository for game terminology and BBCode keyword tooltips.

const HIGHLIGHT_COLOR: String = "#f3c642"

## Canonical glossary of keywords and their descriptive definitions.
const KEYWORDS: Dictionary = {
	"Chain Lightning": "Arcs electricity to nearby valid pegs.",
	"Lucky Gold Pegs": "Grants run Gold on hit.",
	"Lucky Gold Peg": "Grants run Gold on hit.",
	"Gravity Well Peg": "Slows nearby balls.",
	"Gravity Well": "Slows nearby balls.",
	"Extreme Bouncer": "Bounces balls at high speed.",
	"Trampoline Peg": "Launches balls.",
	"Splitter Peg": "Splits striking ball into two.",
	"Goblin Reset": "Catches balls and returns them to top.",
	"Eternal Peg": "Restores durability to full when broken.",
	"Main Cannon": "Attacks enemy fortification walls.",
	"Phase Peg": "Alternates between solid and ghost states.",
	"Wrench Peg": "Repairs broken pegs on hit.",
	"Magnet Peg": "Pulls nearby balls toward itself.",
	"Gold Pegs": "Generates 3× Energy on hit.",
	"Gold Peg": "Generates 3× Energy on hit.",
	"Bomb Peg": "Explodes on hit to damage nearby pegs.",
	"Plain Balls": "Standard balls that generate Energy.",
	"Constellation": "Fires lasers between active balls.",
	"Explosions": "Damages nearby pegs and pushes balls.",
	"Explosion": "Damages nearby pegs and pushes balls.",
	"Supernova": "Massive explosion at maximum Energize (3 stacks).",
	"Energize": "Adds peg stacks to boost Energy and repair speed.",
	"Drop End": "Triggers when a ball reaches the bottom.",
	"On Expiry": "Triggers when status duration ends.",
	"On Break": "Triggers when a peg breaks.",
	"On Hit": "Triggers when a ball strikes a peg.",
	"Overdrive": "Triggers at target peg hit count.",
	"Volatile": "Releases gas clouds that speed up balls.",
	"Fragments": "Small ball pieces created by Split balls.",
	"Fragment": "Small ball piece created by a Split ball.",
	"Phantom": "Phases through pegs to collect Energy.",
	"Intangible": "Phases through pegs to collect Energy.",
	"Rubbery": "Extra bouncy ball that gains speed.",
	"Binary": "Splits when colliding with another Binary ball.",
	"Cannon": "Attacks enemy fortification walls.",
	"Hopper": "Feeds balls onto the board from top.",
	"Leech": "Applies Drain to generate Energy over time.",
	"Drain": "Drains Energy from pegs over time.",
	"Phase": "Phases through pegs to collect Energy.",
	"Blast": "Damages nearby pegs and pushes balls.",
	"Split": "Divides into bouncing ball fragments.",
	"Bloom": "Creates flora multipliers that burst for Energy.",
	"Gate": "Board door that opens to drop balls.",
	"Plain": "Standard ball that generates Energy.",
	"Energy": "Power used to charge the Main Cannon."
}

var _flyout_layer: CanvasLayer = null
var _flyout_panel: PanelContainer = null
var _flyout_title: Label = null
var _flyout_body: Label = null

func _ready() -> void:
	_setup_flyout()

func _setup_flyout() -> void:
	if _flyout_layer != null:
		return
	_flyout_layer = CanvasLayer.new()
	_flyout_layer.name = "KeywordFlyoutLayer"
	_flyout_layer.layer = 125
	_flyout_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_flyout_layer)

	_flyout_panel = PanelContainer.new()
	_flyout_panel.visible = false
	_flyout_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flyout_panel.z_index = 100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.12, 0.98)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.78, 0.26, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_flyout_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	_flyout_panel.add_child(vbox)

	_flyout_title = Label.new()
	_flyout_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flyout_title.add_theme_font_size_override("font_size", 14)
	_flyout_title.add_theme_color_override("font_color", Color(0.96, 0.84, 0.4, 1.0))
	vbox.add_child(_flyout_title)

	var sep := ColorRect.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.custom_minimum_size = Vector2(180, 1)
	sep.color = Color(0.4, 0.35, 0.48, 0.8)
	vbox.add_child(sep)

	_flyout_body = Label.new()
	_flyout_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flyout_body.add_theme_font_size_override("font_size", 12)
	_flyout_body.add_theme_color_override("font_color", Color(0.92, 0.9, 0.94, 1.0))
	_flyout_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flyout_body.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(_flyout_body)

	_flyout_layer.add_child(_flyout_panel)

## Updates a RichTextLabel's BBCode text with optional keyword hover styling.
func update_rtl_text(rtl: RichTextLabel, hovered_key: String = "") -> void:
	if not rtl or not is_instance_valid(rtl) or not rtl.has_meta("plain_text"):
		return
	var raw: String = String(rtl.get_meta("plain_text"))
	var prefix: String = String(rtl.get_meta("bbcode_prefix", ""))
	var suffix: String = String(rtl.get_meta("bbcode_suffix", ""))
	var color: String = String(rtl.get_meta("highlight_color", HIGHLIGHT_COLOR))
	rtl.text = prefix + format_bbcode(raw, color, hovered_key) + suffix

## Attaches hover listeners on a RichTextLabel to trigger instant flyout tooltips on mouse over.
func attach_rich_text_label(rtl: RichTextLabel, plain_text: String = "", prefix: String = "", suffix: String = "", color: String = HIGHLIGHT_COLOR) -> void:
	if not rtl or not is_instance_valid(rtl):
		return
	if not plain_text.is_empty():
		rtl.set_meta("plain_text", plain_text)
	if not prefix.is_empty():
		rtl.set_meta("bbcode_prefix", prefix)
	if not suffix.is_empty():
		rtl.set_meta("bbcode_suffix", suffix)
	if color != HIGHLIGHT_COLOR:
		rtl.set_meta("highlight_color", color)

	rtl.meta_underlined = false
	rtl.hint_underlined = false

	# Ensure bold font size matches normal font size exactly so bolding never changes text scale
	var font_sz: int = 14
	if rtl.has_theme_font_size_override("normal_font_size"):
		font_sz = rtl.get_theme_font_size("normal_font_size")
	rtl.add_theme_font_size_override("normal_font_size", font_sz)
	rtl.add_theme_font_size_override("bold_font_size", font_sz)
	rtl.add_theme_font_size_override("italics_font_size", font_sz)
	rtl.add_theme_font_size_override("bold_italics_font_size", font_sz)

	if not rtl.has_meta("keyword_db_connected"):
		rtl.set_meta("keyword_db_connected", true)
		rtl.meta_hover_started.connect(func(meta: Variant) -> void:
			_on_rtl_meta_hover_started(rtl, meta)
		)
		rtl.meta_hover_ended.connect(func(meta: Variant) -> void:
			_on_rtl_meta_hover_ended(rtl, meta)
		)

	if rtl.has_meta("plain_text"):
		update_rtl_text(rtl, "")

## Convenience helper that formats text and attaches hover signals in one call.
func format_and_attach(rtl: RichTextLabel, plain_text: String, highlight_color: String = HIGHLIGHT_COLOR, prefix: String = "", suffix: String = "") -> void:
	if not rtl:
		return
	attach_rich_text_label(rtl, plain_text, prefix, suffix, highlight_color)

## Shows the instant flyout tooltip for a keyword adjacent to global_pos.
func show_flyout(keyword_key: String, global_pos: Vector2) -> void:
	var def: String = get_definition(keyword_key)
	if def.is_empty():
		return
	show_flyout_custom(keyword_key, def, global_pos)

## Shows a custom instant flyout tooltip with arbitrary title and body text adjacent to global_pos.
func show_flyout_custom(title_text: String, body_text: String, global_pos: Vector2) -> void:
	if not _flyout_panel:
		_setup_flyout()

	_flyout_title.text = title_text
	_flyout_body.text = body_text
	_flyout_panel.visible = true

	var vp_size: Vector2 = Vector2(1280, 720)
	var vp: Viewport = get_viewport()
	if vp:
		vp_size = vp.get_visible_rect().size
	var panel_size: Vector2 = _flyout_panel.get_combined_minimum_size()
	var pos: Vector2 = global_pos + Vector2(16, 16)
	if pos.x + panel_size.x > vp_size.x - 10:
		pos.x = global_pos.x - panel_size.x - 16
	if pos.y + panel_size.y > vp_size.y - 10:
		pos.y = global_pos.y - panel_size.y - 16
	pos.x = max(10, pos.x)
	pos.y = max(10, pos.y)
	_flyout_panel.global_position = pos

## Hides the instant flyout tooltip.
func hide_flyout() -> void:
	if _flyout_panel:
		_flyout_panel.visible = false

func _on_rtl_meta_hover_started(rtl: RichTextLabel, meta: Variant) -> void:
	var m_str: String = String(meta)
	var mouse_pos: Vector2 = Vector2.ZERO
	var vp: Viewport = get_viewport()
	if vp:
		mouse_pos = vp.get_mouse_position()
	show_flyout(m_str, mouse_pos)
	update_rtl_text(rtl, m_str)

func _on_rtl_meta_hover_ended(rtl: RichTextLabel, _meta: Variant) -> void:
	hide_flyout()
	update_rtl_text(rtl, "")

## Returns the definition for a given keyword, or empty string if not found.
static func get_definition(keyword: String) -> String:
	var k: String = keyword.strip_edges()
	if KEYWORDS.has(k):
		return KEYWORDS[k]
	for key in KEYWORDS.keys():
		if key.nocasecmp_to(k) == 0:
			return KEYWORDS[key]
	return ""

## Formats plain text by wrapping recognized keywords in BBCode with [url] and [color].
static func format_bbcode(plain_text: String, highlight_color: String = HIGHLIGHT_COLOR, hovered_key: String = "") -> String:
	if plain_text.is_empty():
		return ""

	# Build sorted keyword list by descending length to match longest phrases first.
	var sorted_keys: Array = KEYWORDS.keys()
	sorted_keys.sort_custom(func(a: String, b: String) -> bool:
		return a.length() > b.length()
	)

	# Special regex for Overdrive N (e.g. Overdrive 6, Overdrive 4)
	var overdrive_def: String = KEYWORDS.get("Overdrive", "")

	# Identify all non-overlapping match intervals in plain_text.
	var matches: Array = [] # Array of Dictionary { "start": int, "end": int, "text": String, "def": String, "key": String }

	# 1. First find Overdrive \d+ occurrences
	var regex_overdrive := RegEx.new()
	regex_overdrive.compile("(?i)\\bOverdrive(?:\\s+\\d+)?\\b")
	for r_match in regex_overdrive.search_all(plain_text):
		var start: int = r_match.get_start()
		var end: int = r_match.get_end()
		var matched_kw: String = plain_text.substr(start, end - start)
		matches.append({
			"start": start,
			"end": end,
			"text": matched_kw,
			"def": overdrive_def,
			"key": matched_kw
		})

	# 2. Match remaining keywords
	for key in sorted_keys:
		if key == "Overdrive":
			continue # handled above
		var key_def: String = KEYWORDS[key]
		var regex := RegEx.new()
		regex.compile("(?i)\\b" + key + "\\b")
		for r_match in regex.search_all(plain_text):
			var start: int = r_match.get_start()
			var end: int = r_match.get_end()

			# Verify no overlap with existing matches
			var overlaps: bool = false
			for m in matches:
				if not (end <= m["start"] or start >= m["end"]):
					overlaps = true
					break
			if not overlaps:
				matches.append({
					"start": start,
					"end": end,
					"text": plain_text.substr(start, end - start),
					"def": key_def,
					"key": key
				})

	# Sort matches by start index
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["start"] < b["start"]
	)

	# Reconstruct string with BBCode
	var result: String = ""
	var last_idx: int = 0
	for m in matches:
		var start: int = m["start"]
		var end: int = m["end"]
		var matched_text: String = m["text"]
		var key_name: String = m["key"]

		result += plain_text.substr(last_idx, start - last_idx)
		var is_hovered: bool = false
		if not hovered_key.is_empty():
			if key_name.nocasecmp_to(hovered_key) == 0 or matched_text.nocasecmp_to(hovered_key) == 0:
				is_hovered = true

		if is_hovered:
			result += "[url=%s][color=#ffffff][b]%s[/b][/color][/url]" % [key_name, matched_text]
		else:
			result += "[url=%s][color=%s]%s[/color][/url]" % [key_name, highlight_color, matched_text]
		last_idx = end

	result += plain_text.substr(last_idx)
	return result
