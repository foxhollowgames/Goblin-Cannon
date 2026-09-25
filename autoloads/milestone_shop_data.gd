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
	"bomb": {"name": "Bomb Peg", "desc": "Explodes."},
	"trampoline": {"name": "Trampoline Peg", "desc": "Launches balls upwards."},
	"goblin_reset": {"name": "Goblin Reset", "desc": "Catches balls and returns them to the hopper."},
	"gold": {"name": "Gold Peg", "desc": "Grants 3× Energy."},
	"splitter": {"name": "Splitter Peg", "desc": "Splits balls that hit it."},
	"eternal": {"name": "Eternal Peg", "desc": "Repairs itself when broken."},
	"extreme_bouncer": {"name": "Extreme Bouncer", "desc": "Bounces balls at high speed."},
	"magnet": {"name": "Magnet Peg", "desc": "Pulls nearby balls toward itself."},
	"lucky_gold": {"name": "Lucky Gold Peg", "desc": "Grants 1 or 5 Gold."},
	"phase": {"name": "Phase Peg", "desc": "Alternates between solid and ghost states."},
	"wrench": {"name": "Wrench Peg", "desc": "Repairs nearby broken pegs."},
	"gravity_well": {"name": "Gravity Well Peg", "desc": "Slows nearby balls."}
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
