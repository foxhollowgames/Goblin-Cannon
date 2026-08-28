extends Node
## Autoload: milestone shop fixed text colors + display strings (same source as `reward_draft_panel` + headless tests).

## Lospec palette via Constants (Monsters Also Die).
var TITLE_TEXT_COLOR: Color:
	get:
		return Constants.ui_milestone_shop_title_text()
var DESC_TEXT_COLOR: Color:
	get:
		return Constants.ui_milestone_shop_desc_text()
## Stat/peg row icons: neutral (not rarity / border color).
var SHOP_ICON_NEUTRAL_TINT: Color:
	get:
		return Constants.ui_shop_icon_neutral_tint()

const STAT_DISPLAY: Dictionary = {
	"main_charge": {"name": "Main Charge", "desc": "Main Cannon: +5% Energy gained per ball."},
	"door_interval": {"name": "Faster Waves", "desc": "Gate: 10% less wait time between waves."},
	"door_duration": {"name": "Longer Gate", "desc": "Gate: Stays open 10% longer per wave."},
	"cannon_damage": {"name": "Cannon Damage", "desc": "Main Cannon: +5 damage per shot."},
	"cannon_energy": {"name": "Cannon Energy", "desc": "Main Cannon: Requires less Energy to fire."},
	"hopper_width": {"name": "Wider Hopper", "desc": "Hopper: +10% width (up to 2× max)."}
}

const PEG_SHOP_DISPLAY: Dictionary = {
	"bomb": {"name": "Bomb Peg", "desc": "Explodes on hit, damaging nearby pegs for bonus Energy. Place on any peg."},
	"trampoline": {"name": "Trampoline Peg", "desc": "Launches balls upward with high force on hit. Place on any peg."},
	"goblin_reset": {"name": "Goblin Reset", "desc": "Catches balls and returns them to the hopper. Place on any peg."},
	"gold": {"name": "Gold Peg", "desc": "Grants 3× Energy when hit by a ball. Place on any peg."},
	"splitter": {"name": "Splitter Peg", "desc": "Splits any ball that hits it into two balls. Place on any peg."},
	"eternal": {"name": "Eternal Peg", "desc": "Instantly repairs its durability to full when broken. Place on any peg."},
	"extreme_bouncer": {"name": "Extreme Bouncer", "desc": "Bounces balls with high speed. Place on any peg."},
	"magnet": {"name": "Magnet Peg", "desc": "Pulls nearby balls toward itself. Place on any peg."},
	"lucky_gold": {"name": "Lucky Gold Peg", "desc": "Grants +1 or +5 Gold when hit. Place on any peg."},
	"phase": {"name": "Phase Peg", "desc": "Alternates between solid and ghost states on a timer. Place on any peg."},
	"wrench": {"name": "Wrench Peg", "desc": "Instantly repairs nearby broken pegs when hit. Place on any peg."},
	"gravity_well": {"name": "Gravity Well Peg", "desc": "Slows down balls that pass through its field. Place on any peg."}
}

## Peg kinds offered in the merchant shop pool (keep aligned with `RewardHandler._build_peg_shop_candidates`).
const PEG_SHOP_KINDS: Array[String] = [
	"bomb", "trampoline", "goblin_reset", "gold", "splitter", "eternal",
	"extreme_bouncer", "magnet", "lucky_gold", "phase", "wrench", "gravity_well"
]

## One-line blurbs under ball cards (title/icon colors stay independent of this copy).
const BALL_SHOP_BLURB: Dictionary = {
	"Plain": "Standard ball. Generates Energy on peg hits and at the bottom.",
	"Split": "Splits into two balls on its first peg hit during a drop.",
	"Energize": "Applies Energize to pegs. Energized pegs grant bonus Energy.",
	"Explosive": "Triggers a blast on hit that damages nearby pegs.",
	"Chain Lightning": "Discharges lightning that jumps to nearby pegs on hit.",
	"Leech": "Applies Drain to pegs.",
	"Rubbery": "High-bouncing ball that keeps speed across peg hits.",
	"Phantom": "Intangible.",
	"Volatile": "Releases gas clouds that accelerate balls on contact.",
	"Constellation": "Fires laser beams between active balls on the board.",
	"Binary": "Splits when it collides with another Binary ball.",
	"Bloom": "Creates energy blooms on pegs that burst for bonus Energy."
}

func shop_blurb_for_ball_ability(ability: String) -> String:
	var k: String = ability.strip_edges()
	if k.is_empty() or k == "Ball":
		k = "Plain"
	var got: Variant = BALL_SHOP_BLURB.get(k, null)
	if got != null:
		var s: String = str(got).strip_edges()
		if not s.is_empty():
			return s
	return "Merchant ball upgrade."
