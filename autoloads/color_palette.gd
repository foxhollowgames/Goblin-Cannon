extends Node
## Global color source: Lospec palette **Monsters Also Die** (12 colors).
## https://lospec.com/palette-list/monsters-also-die

# --- Raw palette (indexed lightest accents last) ---
const VOID := Color("#061217")
const WARM_BROWN := Color("#301c10")
const INDIGO := Color("#222640")
const SLATE := Color("#22343d")
const FOREST := Color("#364f48")
const OLIVE := Color("#5d7545")
const MINT := Color("#4e997f")
const CREAM := Color("#ffec99")
const TAN := Color("#d1a990")
const DUSTY_ROSE := Color("#9e7368")
const RUST := Color("#a1422d")
const DARK_OLIVE := Color("#403920")

# --- Ball alignment (Main / Sidearm / Defense) ---
const ALIGN_MAIN := CREAM
const ALIGN_SIDEARM := RUST
const ALIGN_DEFENSE := MINT

# --- UI chrome (common panels / overlays) ---
const UI_PANEL_BG := Color(INDIGO.r, INDIGO.g, INDIGO.b, 0.98)
const UI_PANEL_BORDER := Color(FOREST.r * 1.05, FOREST.g * 1.05, FOREST.b * 1.05, 1.0)
const UI_DIM := Color(VOID.r, VOID.g, VOID.b, 0.85)
const UI_TEXT_PRIMARY := CREAM
const UI_TEXT_SECONDARY := TAN
const UI_TEXT_MUTED := Color(DUSTY_ROSE.r * 0.85, DUSTY_ROSE.g * 0.85, DUSTY_ROSE.b * 0.85, 1.0)
const UI_ACCENT_GOLD := CREAM
const UI_SUCCESS := OLIVE
const UI_SUCCESS_BRIGHT := Color(MINT.r * 1.05, minf(MINT.g * 1.08, 1.0), MINT.b * 1.02, 1.0)
const UI_DANGER := RUST
const UI_GOLD_DIM := DARK_OLIVE

# --- Conquest / timers ---
const CONQUEST_CURRENT := RUST
const CONQUEST_CURRENT_HIGHLIGHT := TAN
const CONQUEST_INACTIVE := WARM_BROWN
const CONQUEST_INACTIVE_HIGHLIGHT := DUSTY_ROSE

# --- Title cards ---
const TITLE_CARD_BAND := Color(VOID.r, VOID.g, VOID.b, 0.88)
const TITLE_CARD_LINE := Color(TAN.r, TAN.g, TAN.b, 0.5)
const TITLE_CARD_TITLE := CREAM
const TITLE_CARD_SUB := TAN

# --- Debug / misc buttons ---
const DEBUG_BTN_BG := Color(WARM_BROWN.r * 1.15, WARM_BROWN.g * 1.1, WARM_BROWN.b * 1.1, 0.92)
const DEBUG_BTN_BORDER := Color(DUSTY_ROSE.r, DUSTY_ROSE.g, DUSTY_ROSE.b, 1.0)
const DEBUG_BTN_HOVER := Color(RUST.r * 0.55, RUST.g * 0.45, RUST.b * 0.42, 0.95)
const ALMANAC_BTN_BG := Color(SLATE.r, SLATE.g, SLATE.b, 0.95)
const ALMANAC_BTN_BORDER := Color(MINT.r * 0.65, MINT.g * 0.75, MINT.b * 0.7, 1.0)
const BAG_BTN_BG := Color(INDIGO.r * 1.05, INDIGO.g * 1.02, INDIGO.b * 1.08, 0.95)
const BAG_BTN_BORDER := Color(TAN.r * 0.75, TAN.g * 0.7, TAN.b * 0.65, 1.0)
