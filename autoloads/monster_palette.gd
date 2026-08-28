extends RefCounted
class_name MonsterPalette
## Semantic UI + theme colors — RGB from Lospec "Monsters Also Die" via Constants (single hex source).
## https://lospec.com/palette-list/monsters-also-die

const _CONSTANTS = preload("res://autoloads/constants.gd")

static func _C():
	return _CONSTANTS

static func VOID() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_BG_DEEP)

static func WARM_BROWN() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_SURFACE_WARM)

static func INDIGO() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_INDIGO)

static func SLATE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_SLATE)

static func FOREST() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_MUTED_GREEN)

static func OLIVE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_OLIVE)

static func MINT() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_TEAL)

static func SWATCH_CREAM() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_CREAM)

static func TAN() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_TAN)

static func DUSTY_ROSE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_DUST)

static func RUST() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_RUST)

static func DARK_OLIVE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_MUD)

static func ALIGN_MAIN() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_CREAM)

static func ALIGN_SIDEARM() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_RUST)

static func ALIGN_DEFENSE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_TEAL)

static func UI_PANEL_BG() -> Color:
	var c = _C()
	var base: Color = c.monsters_also_die_color(c.MAD_IDX_INDIGO)
	return Color(base.r, base.g, base.b, 0.98)

static func UI_PANEL_BORDER() -> Color:
	var c = _C()
	var f: Color = c.monsters_also_die_color(c.MAD_IDX_MUTED_GREEN)
	return Color(clampf(f.r * 1.05, 0.0, 1.0), clampf(f.g * 1.05, 0.0, 1.0), clampf(f.b * 1.05, 0.0, 1.0), 1.0)

static func UI_DIM() -> Color:
	var c = _C()
	var v: Color = c.monsters_also_die_color(c.MAD_IDX_BG_DEEP)
	return Color(v.r, v.g, v.b, 0.85)

static func UI_TEXT_PRIMARY() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_CREAM)

static func UI_TEXT_SECONDARY() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_TAN)

static func UI_TEXT_MUTED() -> Color:
	var c = _C()
	var d: Color = c.monsters_also_die_color(c.MAD_IDX_DUST)
	return Color(d.r * 0.85, d.g * 0.85, d.b * 0.85, 1.0)

static func UI_ACCENT_GOLD() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_CREAM)

static func UI_SUCCESS() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_OLIVE)

static func UI_SUCCESS_BRIGHT() -> Color:
	var c = _C()
	var m: Color = c.monsters_also_die_color(c.MAD_IDX_TEAL)
	return Color(clampf(m.r * 1.05, 0.0, 1.0), clampf(m.g * 1.08, 0.0, 1.0), clampf(m.b * 1.02, 0.0, 1.0), 1.0)

static func UI_DANGER() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_RUST)

static func UI_GOLD_DIM() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_MUD)

static func CONQUEST_CURRENT() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_RUST)

static func CONQUEST_CURRENT_HIGHLIGHT() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_TAN)

static func CONQUEST_INACTIVE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_SURFACE_WARM)

static func CONQUEST_INACTIVE_HIGHLIGHT() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_DUST)

static func TITLE_CARD_BAND() -> Color:
	var c = _C()
	var v: Color = c.monsters_also_die_color(c.MAD_IDX_BG_DEEP)
	return Color(v.r, v.g, v.b, 0.88)

static func TITLE_CARD_LINE() -> Color:
	var c = _C()
	var t: Color = c.monsters_also_die_color(c.MAD_IDX_TAN)
	return Color(t.r, t.g, t.b, 0.5)

static func TITLE_CARD_TITLE() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_CREAM)

static func TITLE_CARD_SUB() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_TAN)

static func DEBUG_BTN_BG() -> Color:
	var c = _C()
	var w: Color = c.monsters_also_die_color(c.MAD_IDX_SURFACE_WARM)
	return Color(w.r * 1.15, w.g * 1.1, w.b * 1.1, 0.92)

static func DEBUG_BTN_BORDER() -> Color:
	var c = _C()
	return c.monsters_also_die_color(c.MAD_IDX_DUST)

static func DEBUG_BTN_HOVER() -> Color:
	var c = _C()
	var r: Color = c.monsters_also_die_color(c.MAD_IDX_RUST)
	return Color(r.r * 0.55, r.g * 0.45, r.b * 0.42, 0.95)

static func ALMANAC_BTN_BG() -> Color:
	var c = _C()
	var s: Color = c.monsters_also_die_color(c.MAD_IDX_SLATE)
	return Color(s.r, s.g, s.b, 0.95)

static func ALMANAC_BTN_BORDER() -> Color:
	var c = _C()
	var m: Color = c.monsters_also_die_color(c.MAD_IDX_TEAL)
	return Color(m.r * 0.65, m.g * 0.75, m.b * 0.7, 1.0)

static func BAG_BTN_BG() -> Color:
	var c = _C()
	var i: Color = c.monsters_also_die_color(c.MAD_IDX_INDIGO)
	return Color(i.r * 1.05, i.g * 1.02, i.b * 1.08, 0.95)

static func BAG_BTN_BORDER() -> Color:
	var c = _C()
	var t: Color = c.monsters_also_die_color(c.MAD_IDX_TAN)
	return Color(t.r * 0.75, t.g * 0.7, t.b * 0.65, 1.0)
