extends RefCounted
class_name MonsterPalette
## Semantic UI + theme colors — RGB from Lospec "Monsters Also Die" via Constants autoload (single hex source).
## https://lospec.com/palette-list/monsters-also-die
## Uses Engine.get_singleton("Constants") so this global class compiles before autoloads finish registering.

static func _C():
	return Engine.get_singleton("Constants")

static var VOID: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_BG_DEEP)
static var WARM_BROWN: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_SURFACE_WARM)
static var INDIGO: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_INDIGO)
static var SLATE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_SLATE)
static var FOREST: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_MUTED_GREEN)
static var OLIVE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_OLIVE)
static var MINT: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_TEAL)
static var SWATCH_CREAM: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_CREAM)
static var TAN: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_TAN)
static var DUSTY_ROSE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_DUST)
static var RUST: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_RUST)
static var DARK_OLIVE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_MUD)

static var ALIGN_MAIN: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_CREAM)
static var ALIGN_SIDEARM: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_RUST)
static var ALIGN_DEFENSE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_TEAL)

static var UI_PANEL_BG: Color:
	get:
		var c = _C()
		var base: Color = c.monsters_also_die_color(c.MAD_IDX_INDIGO)
		return Color(base.r, base.g, base.b, 0.98)
static var UI_PANEL_BORDER: Color:
	get:
		var c = _C()
		var f: Color = c.monsters_also_die_color(c.MAD_IDX_MUTED_GREEN)
		return Color(clampf(f.r * 1.05, 0.0, 1.0), clampf(f.g * 1.05, 0.0, 1.0), clampf(f.b * 1.05, 0.0, 1.0), 1.0)
static var UI_DIM: Color:
	get:
		var c = _C()
		var v: Color = c.monsters_also_die_color(c.MAD_IDX_BG_DEEP)
		return Color(v.r, v.g, v.b, 0.85)
static var UI_TEXT_PRIMARY: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_CREAM)
static var UI_TEXT_SECONDARY: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_TAN)
static var UI_TEXT_MUTED: Color:
	get:
		var c = _C()
		var d: Color = c.monsters_also_die_color(c.MAD_IDX_DUST)
		return Color(d.r * 0.85, d.g * 0.85, d.b * 0.85, 1.0)
static var UI_ACCENT_GOLD: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_CREAM)
static var UI_SUCCESS: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_OLIVE)
static var UI_SUCCESS_BRIGHT: Color:
	get:
		var c = _C()
		var m: Color = c.monsters_also_die_color(c.MAD_IDX_TEAL)
		return Color(clampf(m.r * 1.05, 0.0, 1.0), clampf(m.g * 1.08, 0.0, 1.0), clampf(m.b * 1.02, 0.0, 1.0), 1.0)
static var UI_DANGER: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_RUST)
static var UI_GOLD_DIM: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_MUD)

static var CONQUEST_CURRENT: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_RUST)
static var CONQUEST_CURRENT_HIGHLIGHT: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_TAN)
static var CONQUEST_INACTIVE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_SURFACE_WARM)
static var CONQUEST_INACTIVE_HIGHLIGHT: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_DUST)

static var TITLE_CARD_BAND: Color:
	get:
		var c = _C()
		var v: Color = c.monsters_also_die_color(c.MAD_IDX_BG_DEEP)
		return Color(v.r, v.g, v.b, 0.88)
static var TITLE_CARD_LINE: Color:
	get:
		var c = _C()
		var t: Color = c.monsters_also_die_color(c.MAD_IDX_TAN)
		return Color(t.r, t.g, t.b, 0.5)
static var TITLE_CARD_TITLE: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_CREAM)
static var TITLE_CARD_SUB: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_TAN)

static var DEBUG_BTN_BG: Color:
	get:
		var c = _C()
		var w: Color = c.monsters_also_die_color(c.MAD_IDX_SURFACE_WARM)
		return Color(w.r * 1.15, w.g * 1.1, w.b * 1.1, 0.92)
static var DEBUG_BTN_BORDER: Color:
	get:
		var c = _C()
		return c.monsters_also_die_color(c.MAD_IDX_DUST)
static var DEBUG_BTN_HOVER: Color:
	get:
		var c = _C()
		var r: Color = c.monsters_also_die_color(c.MAD_IDX_RUST)
		return Color(r.r * 0.55, r.g * 0.45, r.b * 0.42, 0.95)
static var ALMANAC_BTN_BG: Color:
	get:
		var c = _C()
		var s: Color = c.monsters_also_die_color(c.MAD_IDX_SLATE)
		return Color(s.r, s.g, s.b, 0.95)
static var ALMANAC_BTN_BORDER: Color:
	get:
		var c = _C()
		var m: Color = c.monsters_also_die_color(c.MAD_IDX_TEAL)
		return Color(m.r * 0.65, m.g * 0.75, m.b * 0.7, 1.0)
static var BAG_BTN_BG: Color:
	get:
		var c = _C()
		var i: Color = c.monsters_also_die_color(c.MAD_IDX_INDIGO)
		return Color(i.r * 1.05, i.g * 1.02, i.b * 1.08, 0.95)
static var BAG_BTN_BORDER: Color:
	get:
		var c = _C()
		var t: Color = c.monsters_also_die_color(c.MAD_IDX_TAN)
		return Color(t.r * 0.75, t.g * 0.7, t.b * 0.65, 1.0)
