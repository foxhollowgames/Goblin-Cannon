extends Node
## Autoload: milestone shop fixed text colors + display strings (same source as `reward_draft_panel` + headless tests).

const TITLE_TEXT_COLOR: Color = Color(0.92, 0.92, 0.96, 1)
const DESC_TEXT_COLOR: Color = Color(0.78, 0.78, 0.82, 1)
## Stat/peg row icons: neutral (not rarity / border color).
const SHOP_ICON_NEUTRAL_TINT: Color = Color(0.88, 0.88, 0.92, 1)

const STAT_DISPLAY: Dictionary = {
	"main_charge": {"name": "Main Charge", "desc": "+5% energy to the main cannon per ball"},
	"door_interval": {"name": "Faster Waves", "desc": "10% less wait between waves"},
	"door_duration": {"name": "Longer Gate", "desc": "Gate stays open 10% longer"},
	"cannon_damage": {"name": "Cannon Damage", "desc": "+5 damage per wall shot"},
	"cannon_energy": {"name": "Cannon Energy", "desc": "Main cannon needs less energy to fire"},
	"hopper_width": {"name": "Wider Hopper", "desc": "+10% hopper width (max 2×)"}
}

const PEG_SHOP_DISPLAY: Dictionary = {
	"bomb": {"name": "Bomb Peg", "desc": "Blasts on hit. Place on an empty peg."},
	"trampoline": {"name": "Trampoline Peg", "desc": "Launches balls upward hard."},
	"goblin_reset": {"name": "Goblin Reset", "desc": "Catches balls and sends them to the top."},
	"gold": {"name": "Gold Peg", "desc": "3× energy when hit."},
	"splitter": {"name": "Splitter Peg", "desc": "Splits any ball into two."},
	"eternal": {"name": "Eternal Peg", "desc": "At 0 HP: refills at once (no rest)."},
	"extreme_bouncer": {"name": "Extreme Bouncer", "desc": "Very strong bounce."},
	"magnet": {"name": "Magnet Peg", "desc": "Pulls nearby balls in."},
	"lucky_gold": {"name": "Lucky Gold Peg", "desc": "Extra gold (1 or 5; better odds for 5)."},
	"phase": {"name": "Phase Peg", "desc": "Turns solid and ghost on a timer."},
	"wrench": {"name": "Wrench Peg", "desc": "Fixes nearby broken pegs when hit."},
	"gravity_well": {"name": "Gravity Well Peg", "desc": "Slows balls near it."}
}

## Peg kinds offered in the milestone shop pool (keep aligned with `RewardHandler._build_peg_shop_candidates`).
const PEG_SHOP_KINDS: Array[String] = [
	"bomb", "trampoline", "goblin_reset", "gold", "splitter", "eternal",
	"extreme_bouncer", "magnet", "lucky_gold", "phase", "wrench", "gravity_well"
]

## One-line blurbs under ball cards (title/icon colors stay independent of this copy).
const BALL_SHOP_BLURB: Dictionary = {
	"Plain": "Standard ball; hit pegs to send energy to the main cannon.",
	"Split": "Splits into two balls when it hits pegs (once per peg visit).",
	"Energize": "Pegs you hit charge faster for the main cannon.",
	"Explosive": "Damages pegs in a radius on impact.",
	"Chain Lightning": "Chains lightning to nearby pegs.",
	"Leech": "Applies a draining status to pegs you hit.",
	"Rubbery": "Extra bouncy; keeps speed across hits.",
	"Phantom": "Passes through pegs while phasing.",
	"Volatile": "Leaves buff gas clouds when you score.",
	"Constellation": "Beams energy along lines between your balls.",
	"Binary": "Splits paired balls when they collide.",
	"Bloom": "Bloom-themed bonus interactions on peg hits."
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
	return "Milestone shop ball upgrade."
