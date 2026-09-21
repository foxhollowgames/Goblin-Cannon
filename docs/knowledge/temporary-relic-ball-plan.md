# Temporary relic balls: implementation proposal

Task: TASK-100. Status: proposal for user discussion. No gameplay authorization.
Baseline: main 91e596a. Runtime inventory: 122 unique relic IDs, including 42 deliberate relics.
TASK-101 removes passives independently. TASK-102 repairs acquisition independently.
All values below are candidates for TASK-104, not final balance.

## Proposed contract

Use new temporary balls. Do not replace permanent balls or their abilities.
An activation creates one special ball by default. Tier 2 creates two and Tier 3 creates three.
The exceptions in the variant table override this count. All spawned balls use the same lifetime.
Each special ball lasts one board visit, with a maximum of 720 simulation ticks (12 seconds).
Its age advances while captured. Pause stops age; slow motion uses the same simulation clock.
At the bottom, collect its earned energy once, then delete it. It never returns to the hopper.
At timeout, delete it without collection. Remove it from capture ownership before deletion.
Wall and city transitions discard temporary balls without payout. Reset discards all transient state.
Moving or removing a device releases captured balls with restored physics. Spawned balls keep their age.
Do not save temporary balls or pending reward emissions. Old saves retain permanent inventory only.

Reward dispatch uses a unique key: run ID, module instance ID, activation sequence.
Consume the key before spawning. Repeated contacts or signals cannot award the same completion twice.
Spawn outside the rotated outlet, one radius plus a small clearance beyond its boundary.
Impact devices use the open side nearest the triggering contact, facing away from their solid body.
Initial velocity follows the physical outlet direction at the device release speed. Do not redirect the triggering ball.
A word bank uses the lane that completed the word. A reservoir uses its release outlet.
A spinner uses its lower outlet. A track emits only after the completing ball leaves its outlet.
If the outlet is blocked, queue emission for up to 60 simulation ticks. Then cancel it without payout.
Release queued balls six ticks apart. These intervals are candidates, not final tuning.

Limit reward balls to 24 active or reserved slots per board. Allocate in module-instance order per tick.
Overflow cancels only the new emission. Never delete a permanent ball to make room.
Temporary balls may operate machinery, but their contacts do not advance reward goals.
They can complete a physical route, open a gate, or turn a spinner without producing more reward balls.
For shared counters, only permanent-ball contacts count. Spinner reward charge uses a separate speed accumulator fed only by permanent-ball impulses. Temporary contacts can turn the visible rotor but cannot raise this reward accumulator.
All children of temporary balls inherit temporary status, expiration, and the population budget.
The proposed types below do not split. Future splitting requires a separate bounded design change.
A ball has only one capture owner. Retention and transfer use the existing relic_ball_flow contract.

## Small ball vocabulary

| Type | Proposed behavior | Routing decision | Visible cue |
| --- | --- | --- | --- |
| Bounce | Higher restitution for its first four physical impacts, then ordinary motion | Stay in a dense chamber or cross to an adjacent device | Ring outline with four marks |
| Charge | Adds one Energize stack to each of its first three distinct ordinary peg contacts | Prepare a lane for later permanent balls | Lightning outline with three marks |
| Blast | On first ordinary peg contact, hit pegs in a two-cell radius once, then become ordinary | Aim at dense pegs; do not fire inside the source | Star outline; remove star after burst |
| Drive | At its first free flight after emission, use a fixed launch speed for that direction | Reach a distant inlet; collision then uses normal physics | Arrow outline |
| Volley | Ordinary-energy ball, emitted as a timed pair instead of a single ball | Feed a spinner or fill a reservoir with a short pulse | Paired dots |

All five types use baseline ball energy and ordinary peg energy. No global cannon multiplier applies.
Charge honors existing peg exclusions and stack limits. Blast uses Board hit resolution and cooldowns.
Blast does not synthesize machinery contacts or reward completions. Drive does not override capture motion.
Volley uses two slots per count shown in the table. If fewer slots remain, emit only the available number.
No old direct surge, global knock, supercharge, or compound blast reward accompanies these balls.
Normal component hit energy and ordinary ball abilities remain unchanged.
Energy belongs to the reward ball. Only bottom collection routes it to the cannon through Board.

## Family roles and same-tier choices

All pairs retain their existing normalized geometry unless a later playtest rejects a variant.
Prices start equal within each tier. Test opportunity cost before adding a price difference.
Chambers have upper entry and lower drain. Banks have parallel open lanes.
Reservoirs have upper entry and gated outlet. Spinners have a funnel and lower outlet.
Wedges and bash toys have exposed impact faces and open bypass space.
Tracks use the runtime ordered path and rotated arrowed ports.
The inventory appendix gives exact runtime cells, triggers, and tiers for each ID.
For all rows, life is one visit / 720 ticks. Counts follow the tier rule unless stated.

| Family / tier | First variant | Second variant | Choice and cost |
| --- | --- | --- | --- |
| Chamber 1 | bumper_vessel_twin: Bounce | bumper_vessel_stagger: Charge | Same 2x3 frame; four versus five hits. Recirculate a ball or prepare a downstream peg lane. |
| Chamber 2 | pachinko_bumper_vessel: Bounce | bumper_vessel_pinball: Drive | Same 3x3 frame and eight hits. Local residence or a longer outlet shot. |
| Chamber 3 | mega_pop_bumper: Drive | cyclone_bounce_vault: Bounce | Compact 2x2 impact core versus 4x3 chamber. Save space or collect broad traffic. |
| Bank 1 | word_bank_gob: Charge | word_bank_pop: Volley, one pair | Identical 3x2 lanes and three switches. Prepare pegs or produce a short traffic pulse. |
| Bank 2 | word_bank_win: Drive | word_bank_bam: Blast | Identical 3x2 lanes. Feed a remote device or target nearby peg clusters. |
| Bank 3 | word_bank_boom: Blast | word_bank_loot: Volley, two pairs | Identical 4x3 lanes. Burst against pegs or fill downstream retention. |
| Reservoir 1 | wire_gate_cup: Charge | wire_gate_funnel: Volley, one pair | Same 2x2 cup; needs two versus three balls. Earlier preparation or denser release. |
| Reservoir 2 | wire_gate_reservoir: Volley, two pairs | abyssal_maw: Drive | 3x2 four-ball cup versus compact 2x2 three-ball trap. Timed burst or focused exit. |
| Reservoir 3 | wire_gate_armory: Blast | fragment_swarm: Volley, three pairs | Same 3x3 frame; five versus three retained balls. Dense peg burst or downstream traffic. |
| Wedge 1 | detonation_triangle_wedge: Drive | detonation_triangle_acute: Blast | Mirrored three-cell faces; two versus three contacts. Remote feed or local burst. |
| Wedge 2 | detonation_triangle_twin: Blast | corner_slingshot: Drive | Six-cell pincers versus three-cell corner. Catch wider traffic or fit a tight turn. |
| Wedge 3 | detonation_triangle_bastion: Blast | detonation_triangle_apex: Bounce | Nine-cell faces, five hits. Clear a peg cluster or sustain local bouncing. |
| Bash 1 | bash_toy_idol: Blast | bash_toy_anvil: Drive | Four versus six cells, four hits. Cluster attack or launch toward another inlet. |
| Bash 2 | bash_toy_bell: Charge | golem_effigy: Blast | Seven versus four cells; six versus five hits. Prepare survivors or immediate area hits. |
| Bash 3 | blood_tithe: Blast | gilded_covenant: Volley, two pairs | Ten versus eleven cells; eight hits. Burst on pegs or a traffic pulse. |
| Spinner 1 | funneled_spinner_chute: Drive | funneled_spinner_v: Charge | Same 3x2 runtime funnel, one spinner, speed goal and cooldown. Remote inlet or peg preparation. |
| Spinner 2 | funneled_spinner: Drive | funneled_spinner_dual: Volley, two pairs | Same 3x3 runtime geometry; dual name does not imply two blades. Rename second to Pulse Spinner. |
| Spinner 3 | resonant_well: Charge | funneled_spinner_vortex: Bounce | Same 4x3 funnel and speed goal. Feed a charged lane or a nearby bounce chamber. |
| Track 1 | track_stairs_step: Charge | track_right_angle: Drive | Four-cell paths with different bends. Prepare a lower lane or extend the exit reach. |
| Track 2 | track_u_turn: Bounce | track_zigzag_chute: Charge | Five-cell return versus descending route. Return traffic upward or prepare lower pegs. |
| Track 3 | track_grand_orbit: Drive | track_cascade_switchback: Volley, two pairs | Ten-cell outer circuit versus eight-cell stepped route. Long shot or timed downstream pulse. |

If matched tests find no useful choice for a pair, merge the second ID into the first at inventory load.
Preserve item instance ID and position; require manual placement if the replacement footprint does not fit.
Do not silently expand placed geometry. Keep a visible retired-item label until it is moved.
The table proposes distinct jobs; it does not claim that all pairs have passed playtesting.

## Chains and competing layouts

1. Early G-O-B above an ordinary peg lane: Charge prepares three pegs for following permanent balls.
   P-O-P in the same space instead sends a pair into a nearby spinner. It sacrifices preparation for traffic.
2. A full reservoir releases its permanent contents, then emits a Volley into a spinner.
   Temporary contacts turn the spinner but cannot award a second reward. Permanent contents can still award it once.
3. A Drive track points at a remote reservoir inlet. A Bounce track points back into a chamber.
   The first uses a short flight; the second risks expiration during recirculation.
4. A Blast wedge sits above a dense peg cluster. A Drive wedge instead feeds a Charge bank above the same cluster. That layout preserves the cluster for later hits but needs more space.
   Compare cannon output and retained peg value, not just the first burst.
5. A Charge spinner above a chamber supports sustained output. A Volley spinner above a trap supports a timed release.
   Captured temporary balls still expire. A full trap must never keep a stale ownership reference.

## Known reward defects: explicit disposition

| Current defect | Proposed disposition | Required outcome test |
| --- | --- | --- |
| B-O-O-M advertises knock but dispatches surge only | Replace both promises with Blast balls | Ball contacts produce the documented local peg hits, exactly once |
| Armory advertises energy absent from knock dispatch | Replace compound reward with Blast balls | Correct count, outlet direction, peg results, bottom energy |
| Grand Switchback advertises energy absent from multiball dispatch | Replace with two Volley pairs | Four temporary balls, one collection each, no hopper growth |
| Bastion promises an unclear board blast | Replace with explicit Blast behavior | No immediate board-wide hit; one local burst per emitted ball |
| Global Knock calls nonexistent GameState.add_energy | Remove old dispatch after all callers migrate | No remaining call; Board routes actual collected energy to cannon |

## Implementation sequence after design approval

1. Freeze the 42-entry production roster and legacy decisions. Review this proposal with the user.
2. Add a typed special-ball reward definition beside polyomino_module_data.gd.
   Store ball type, count, emission spacing, life ticks, and source identity. Version serialization.
3. Add a Board-owned temporary-ball controller with spawn reservations, activation keys, expiry, and cleanup.
   Integrate scenes/balls/ball.gd, scenes/main/game_ball_manager.gd, and the bottom collection path.
   Keep each new source file under 500 lines. Use the existing local Ollama authoring workflow.
4. Replace polyomino_goal_reward_handler.gd dispatch. Carry the real rotated outlet and completing ball.
   Integrate relic_ball_flow.gd ownership and module removal. Preserve physical paths and component rewards.
5. Add the five effects through Board hit resolution. Separate physical machinery motion from reward-goal credit.
   Use deterministic event order and fixed simulation ticks. Never use global random emission directions.
6. Apply the mapping in deliberate_relic_catalog.gd. Remove obsolete direct-reward branches only after all IDs migrate.
   Reconcile reward_card_catalog.gd and acquisition with TASK-101 and TASK-102 without restoring passives.
7. Update shared Trigger/Effect descriptions, glossary, ball visuals, and inventory/shop previews.
   Reuse the physical preview renderer from TASK-099. Add outlet arrows and small ball-type/count badges.
8. Run outcome and real-physics tests, the quality audit, independent PR review, and merge after design approval.

## UI wording

Example Trigger: Light each G-O-B lane once.
Example Effect: Release 1 Charge ball. It charges the next 3 different pegs. Lasts one fall, up to 12 seconds.
Show remaining life as a shrinking outline. Use shape as well as color to distinguish types.
Show blocked or population-limited emission on the source device with a short neutral indicator.
Preview the physical device and its outlet. Do not show an energy promise that ignores route or expiration.

## Verification and balance handoff

Test actual peg state, ball counts, lifetime, cannon energy, and inventory conservation.
Cover duplicate activation callbacks, simultaneous goals, 24-slot overflow, blocked outlets, and invalid recipients.
Cover pause, slow motion, wall/city transition, reset, occupied removal, and save/load.
Inject legacy passive IDs and verify they grant no effect. Keep ordinary abilities and peg mechanics covered.
Run real physics with all four rotations and fast entry for each representative chain above.
Assert one owner, restored gravity, no permanent-ball loss, and no reward recursion.
Test the full production roster against the mapping, acquisition tier, nonempty text, and output type.

TASK-104 should compare matched seeds and identical permanent balls for each same-tier pair.
Record time to activation, temporary survival, bottom energy, cannon shots, lost peg opportunities,
blocked emissions, cap pressure, city completion, and purchase timing. Include a no-relic control.
Vary sparse/dense pegs, slow/fast feeds, and high/low device placements.
Proposed tuning inputs: 720-tick life, 24 slots, six-tick spacing, counts above, equal same-tier prices.
Do not declare the variants balanced from equal energy totals. Physical reliability and occupied space matter.

## Decisions for discussion

- Are new disposable balls preferable to temporary changes on the triggering permanent ball?
- Should temporary balls contribute to reward goals? This proposal says no to prevent reproduction loops.
- Is a one-fall lifetime with a time cap readable enough? Should timeout collect energy instead?
- Are five ball types enough? Begin with these before adding unique types for every relic.
- Retire legacy IDs from new offers, or preserve more as distinct physical devices?

The appendix proposes retiring all non-deliberate IDs from new offers in the later redesign.
Existing legacy items remain physical devices until converted by an explicit migration.
TASK-101 may preserve those physical items and active rewards while removing their passive effects.
This plan does not authorize retiring them now. TASK-103 and TASK-105 remain pending user review.

## Runtime inventory appendix

Each row records the current runtime definition, not only the authored shape name.
Deliberate IDs use the mapping above. Legacy IDs have an explicit proposed retire decision.
Current reward text is a recorded promise; the defect table identifies known mismatches.
Tier is the data tier, not proof of current normal reachability. TASK-102 audits routes separately.

| ID | Tier | Runtime cells | Current trigger | Current reward | Proposed decision |
| --- | --- | --- | --- | --- | --- |
| cascade_reactor | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Hit all 4 corner boosters and center bumper. | Board Supercharge (+3 Energize to all pegs) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| perpetual_engine | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | Multiball Cascade (4 extra balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| storm_of_fragments | 3 | [(1, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (0, 3), (1, 3), (2, 3)] | Hit all 3 pop bumpers. | Multiball Cascade (5 fragment balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| explosive_contagion | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2)] | Deflect across slingshots 3 times. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| superconductor | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (3, 2), (3, 1)] | Knock down drop target within 4s. | +200 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| rubber_storm | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Hit pop bumpers. | +180 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| fragment_swarm | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Hold 3 balls, then release. Partial fills drain after 6 seconds without the bonus. | Multiball Cascade (4 balls) | Retain; family/variant mapping above |
| overdrive_cascade | 3 | [(1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | Board Supercharge (+3 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| goblin_width_tempest | 3 | [(1, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (0, 3), (1, 3), (2, 3), (0, 0)] | Enter vertical up kicker. | +180 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| blood_tithe | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Strike war effigy 8 times. | +150 Energy Surge to ball | Retain; family/variant mapping above |
| crown_ricochet | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Hit pop bumpers. | +150 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| twin_mandate | 3 | [(0, 0), (1, 0), (0, 1), (1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (0, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +160 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| velocity_dividend | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (1, 3), (2, 3)] | Smash vault bash toy 3 times. | +220 Jackpot Energy Surge | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| phase_sovereign | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Trip mechanical diverter gate. | Board Supercharge (+3 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| resonant_well | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +140 Energy Surge to ball | Retain; family/variant mapping above |
| renewal_pact | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Deflect off slingshots 3 times. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| gilded_covenant | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Strike treasure chest 8 times. | Multiball Cascade (3 balls) | Retain; family/variant mapping above |
| iron_bloom | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Strike 4 corner bash targets. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| echoes_of_wrench | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (1, 2), (2, 2)] | Knock down targets. | +175 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| stormgrid_coupling | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Strike storm bash toy 3 times. | Multiball Cascade (3 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| leech_singularity | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Strike captive ball 2 times. | +200 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| phantom_resonance | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | Board Supercharge (+3 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| supernova_peg | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)] | Knock down targets. | +130 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chain_conduction | 2 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (2, 1), (3, 1)] | Hit pop bumpers. | +120 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| overcharged_drain | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Hold 2 balls, then release. Partial fills drain after 6 seconds without the bonus. | +130 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| final_arc_detonation | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (2, 2)] | Enter vertical up kicker. | +125 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| energy_collapse | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)] | Knock down targets. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| shrapnel_split | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)] | Trip mechanical diverter gate. | Multiball Cascade (3 split balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| energized_fragments | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +110 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| arc_twins | 2 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (3, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | +125 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| phase_siphon | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell W-I-N by lighting each letter in its open lane. | +100 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| phase_detonation | 2 | [(0, 0), (1, 0), (2, 0), (2, 1), (0, 2), (1, 2), (2, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +115 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| spectral_conduit | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (2, 1), (0, 2), (2, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +115 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| impact_burst | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)] | Hit pop bumpers. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| kinetic_charge | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +140 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| static_bounce | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell P-O-P by lighting each letter in its open lane. | +105 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| parasitic_arc | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (2, 2)] | Trip diverter gate. | +110 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| draining_fragments | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (2, 1), (2, 2)] | Deflect off slingshot. | Multiball Cascade (3 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| resonant_bounce | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Knock down targets. | +120 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| ricochet_blast | 2 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2), (2, 2)] | Knock down targets. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| blast_launch | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (2, 2)] | Enter vertical up kicker. | +135 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| arc_surge_wrench | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Deflect off slingshot. | Board Supercharge (+2 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| goblin_width_pulse | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (2, 1), (2, 2)] | Catch ball in ball trap. | +110 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| magnet_arc_snare | 2 | [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (2, 2)] | Lock ball in snare lock. | +120 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| spark_trampoline | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Strike captive ball 2 times. | +130 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| hyper_elastic | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +80 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| overdrive_hits | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hit pop bumper. | +75 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| overclock_network | 1 | [(0, 0), (1, 0), (2, 0), (1, 1), (2, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | +70 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| spreading_rot | 1 | [(0, 0), (1, 0), (0, 1), (0, 2), (1, 2)] | Knock down drop target. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| cluster_grenade | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Hit pop bumpers. | Multiball Cascade (3 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| blast_lift | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Enter vertical up kicker. | +85 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| fragmentation_tag | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hit pop bumper. | +65 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| storm_feedback | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Deflect off slingshot. | +70 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| overcurrent_surge | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell G-O-B by lighting each letter in its open lane. | +75 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| fragment_echo | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Catch ball in ball trap. | Multiball Cascade (2 echo balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| mass_cascade | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Strike captive ball. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| ghost_trail | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +60 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| phase_instability | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | +65 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_random_ball | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Strike captive ball. | Multiball Cascade (2 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| plain_surge | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Hit all components in module. | +60 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| plain_horde | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hit pop bumper. | Multiball Cascade (3 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| plain_momentum | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +70 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| volt_primer | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell G-O-B by lighting each letter in its open lane. | +75 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| explosion_radius | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Deflect off slingshot. | +70 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| explosion_peg_hit_count | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Lock ball in chamber. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| explosion_impulse | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Enter vertical up kicker. | +60 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chain_arc | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | Board Supercharge (+2 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chain_range | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | +65 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| max_energize_stacks | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hold 2 balls, then release. Partial fills drain after 6 seconds without the bonus. | Board Supercharge (+2 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| energize_decays_slower | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | Board Supercharge (+2 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| energized_pegs_repair_faster | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | Board Supercharge (+2 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| global_peg_durability | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Hit pop bumpers. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| peg_recovery_speed | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (2, 1)] | Deflect off slingshot. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| devastating_barrage | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell B-A-M by lighting each letter in its open lane. | Global Board Knock (All pegs hit once) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| compressed_charge | 1 | [(0, 0), (1, 0), (0, 1), (0, 2), (1, 2)] | Charge locks and collect. | +100 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_leech_drain | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Deflect off slingshot. | +55 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_leech_duration | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Guide one ball from the entrance through the complete rail to its outlet. | +55 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_phantom_energy | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Guide one ball from the entrance through the complete rail to its outlet. | +55 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_rubbery_energy | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +60 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_bounce_energy | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hit pop bumper. | +50 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| chest_split_energy | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)] | Trip diverter gate. | Multiball Cascade (2 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| mega_pop_bumper | 3 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hit mega pop bumper 5 times. | +120 Energy Surge to ball | Retain; family/variant mapping above |
| abyssal_maw | 2 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Catch 3 balls in abyssal maw. | Multiball Cascade (3 balls) | Retain; family/variant mapping above |
| golem_effigy | 2 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Strike golem effigy 5 times. | Global Board Knock (All pegs hit once) | Retain; family/variant mapping above |
| corner_slingshot | 2 | [(0, 0), (1, 0), (0, 1)] | Rebound from slingshot 3 times. | +75 Energy Surge to ball | Retain; family/variant mapping above |
| apex_orbit_loop | 1 | [(0, 1), (1, 0), (2, 1)] | Traverse apex orbit loop. | +80 Energy Surge to ball | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| cyclone_orbit_loop | 2 | [(0, 0), (0, 1), (1, 1), (2, 1), (2, 0)] | Traverse cyclone orbit loop. | Board Supercharge (+2 Energize stacks) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| grand_orbit_circuit | 3 | [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2), (2, 1), (2, 0)] | Traverse grand orbit circuit. | Multiball Cascade (3 balls) | Retire from new offers after approval; preserve physical legacy item until explicit migration |
| bumper_vessel_twin | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2)] | Make 4 bumper hits. Balls leave through the open drain. | +30 Energy Surge to ball | Retain; family/variant mapping above |
| bumper_vessel_stagger | 1 | [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2)] | Make 5 bumper hits. Balls leave through the open drain. | +35 Energy Surge to ball | Retain; family/variant mapping above |
| pachinko_bumper_vessel | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Make 8 bumper hits. Balls leave through the open drain. | +60 Energy Surge to ball | Retain; family/variant mapping above |
| bumper_vessel_pinball | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Make 8 bumper hits. Balls leave through the open drain. | +70 Energy Surge to ball | Retain; family/variant mapping above |
| cyclone_bounce_vault | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Make 10 bumper hits. Balls leave through the open drain. | +150 Energy Surge to ball | Retain; family/variant mapping above |
| word_bank_gob | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell G-O-B by lighting each letter in its open lane. | +40 Energy Surge to ball | Retain; family/variant mapping above |
| word_bank_pop | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell P-O-P by lighting each letter in its open lane. | +45 Energy Surge to ball | Retain; family/variant mapping above |
| word_bank_win | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell W-I-N by lighting each letter in its open lane. | +80 Energy Surge to ball | Retain; family/variant mapping above |
| word_bank_bam | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Spell B-A-M by lighting each letter in its open lane. | Global Board Knock (All pegs hit once) | Retain; family/variant mapping above |
| word_bank_boom | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Spell B-O-O-M by lighting each letter in its open lane. | +150 Energy Surge + Global Knock | Retain; family/variant mapping above |
| word_bank_loot | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Spell L-O-O-T by lighting each letter in its open lane. | Multiball Cascade (3 balls) | Retain; family/variant mapping above |
| wire_gate_cup | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hold 2 balls, then release. Partial fills drain after 6 seconds without the bonus. | +40 Energy Surge to ball | Retain; family/variant mapping above |
| wire_gate_funnel | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Hold 3 balls, then release. Partial fills drain after 6 seconds without the bonus. | +50 Energy Surge to ball | Retain; family/variant mapping above |
| wire_gate_reservoir | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Hold 4 balls, then release. Partial fills drain after 6 seconds without the bonus. | +90 Energy Surge to ball | Retain; family/variant mapping above |
| wire_gate_armory | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Hold 5 balls, then release. Partial fills drain after 6 seconds without the bonus. | Global Board Knock + 130 Energy | Retain; family/variant mapping above |
| detonation_triangle_wedge | 1 | [(0, 0), (1, 0), (0, 1)] | Deflect off wedge 2 times. | +35 Energy Surge to ball | Retain; family/variant mapping above |
| detonation_triangle_acute | 1 | [(0, 0), (1, 0), (1, 1)] | Deflect off triangle 3 times. | +40 Energy Surge to ball | Retain; family/variant mapping above |
| detonation_triangle_twin | 2 | [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (1, 2)] | Deflect off pincers 4 times. | +85 Energy Surge to ball | Retain; family/variant mapping above |
| detonation_triangle_bastion | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2)] | Deflect off bastion 5 times. | +130 Energy Surge + Board Blast | Retain; family/variant mapping above |
| detonation_triangle_apex | 3 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (0, 2), (3, 0), (2, 1), (1, 2)] | Deflect off wedge 5 times. | Global Board Knock (All pegs hit once) | Retain; family/variant mapping above |
| bash_toy_idol | 1 | [(0, 0), (1, 0), (0, 1), (1, 1)] | Strike idol 4 times. | +45 Energy Surge to ball | Retain; family/variant mapping above |
| bash_toy_anvil | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Strike anvil 4 times. | +50 Energy Surge to ball | Retain; family/variant mapping above |
| bash_toy_bell | 2 | [(1, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Strike temple bell 6 times. | +85 Energy Surge to ball | Retain; family/variant mapping above |
| funneled_spinner_chute | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +35 Energy Surge to ball | Retain; family/variant mapping above |
| funneled_spinner_v | 1 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +40 Energy Surge to ball | Retain; family/variant mapping above |
| funneled_spinner | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +80 Energy Surge to ball | Retain; family/variant mapping above |
| funneled_spinner_dual | 2 | [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | +90 Energy Surge to ball | Retain; family/variant mapping above |
| funneled_spinner_vortex | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Global Board Knock (All pegs hit once) | Retain; family/variant mapping above |
| track_stairs_step | 1 | [(0, 0), (0, 1), (1, 1), (1, 2)] | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | +35 Energy Surge to ball | Retain; family/variant mapping above |
| track_right_angle | 1 | [(0, 0), (0, 1), (0, 2), (1, 2)] | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | +40 Energy Surge to ball | Retain; family/variant mapping above |
| track_u_turn | 2 | [(0, 0), (0, 1), (1, 1), (2, 1), (2, 0)] | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | +75 Energy Surge to ball | Retain; family/variant mapping above |
| track_zigzag_chute | 2 | [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2)] | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | +80 Energy Surge to ball | Retain; family/variant mapping above |
| track_grand_orbit | 3 | [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)] | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | +140 Energy Surge to ball | Retain; family/variant mapping above |
| track_cascade_switchback | 3 | [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2), (3, 2), (3, 1), (3, 0)] | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Multiball Cascade (3 balls) + 150 Energy | Retain; family/variant mapping above |


Spinner regression: one permanent contact followed by temporary contacts may rotate the rotor, but must not complete reward charge. A later sufficient permanent-only contribution may complete it once.

