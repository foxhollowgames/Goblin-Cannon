# TASK-109: Relic name review

The title uses exactly two words: a reward adjective and a physical device name.
The adjective replaces the lower-output word. Exact counts remain in Effect text.

| Ball type | Lower output | Middle output | Higher output |
|---|---|---|---|
| Plain | Iron (3) | Teeming (6) | Swarming (12) |
| Rubbery | Bouncy (1) | Springy (4) | Irrepressible (10) |
| Energize | Charged (1) | Surging (3) | No current relic |
| Explosive | Explosive (1) | Cataclysmic (3) | No other current count |
| Chain Lightning | Crackling (1) | Thundering (3) | No other current count |
| Split | Splitting (1) | Splintering (2) | Shattering (4) |
| Binary | Binary (1) | No current relic | No current relic |

Retired relics have no ball reward. Their two-word names describe the retained physical device instead. They do not use active reward words to promise an unavailable reward.

The first six active rows form the bumper-family implementation slice. It passed 54 assertions before the naming pass expanded.

## Active catalog

| Stable ID | Tier | Old name | New name | Trigger | Effect |
|---|---|---|---|---|---|
| fragment_swarm | 3 | Grand Wire Reservoir | Shattering Reservoir | Hold 3 balls, then release. Partial fills drain after 6 seconds without the bonus. | Release 4 Split balls through the device outlet. Lasts one visit, up to 12 seconds. |
| blood_tithe | 3 | Colossus War Effigy | Binary Effigy | Strike war effigy 8 times. | Release 1 Binary ball through the device outlet. Lasts one visit, up to 12 seconds. |
| resonant_well | 3 | Resonant Well | Thundering Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Release 3 Chain Lightning balls through the device outlet. Lasts one visit, up to 12 seconds. |
| gilded_covenant | 3 | Dragon Treasure Chest | Swarming Chest | Strike treasure chest 8 times. | Release 12 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |
| mega_pop_bumper | 3 | Mega Bumper Citadel | Thundering Bumper | Hit mega pop bumper 5 times. | Release 3 Chain Lightning balls through the device outlet. Lasts one visit, up to 12 seconds. |
| abyssal_maw | 2 | Abyssal Holding Well | Splintering Well | Catch 3 balls in abyssal maw. | Release 2 Split balls through the device outlet. Lasts one visit, up to 12 seconds. |
| golem_effigy | 2 | Golem Effigy | Explosive Effigy | Strike golem effigy 5 times. | Release 1 Explosive ball through the device outlet. Lasts one visit, up to 12 seconds. |
| corner_slingshot | 2 | Crackling Detonation Triangle | Surging Slingshot | Rebound from slingshot 3 times. | Release 3 Energize balls through the device outlet. Lasts one visit, up to 12 seconds. |
| bumper_vessel_twin | 1 | Twin Core Bumper Vessel | Bouncy Bumpers | Make 4 bumper hits. Balls leave through the open drain. | Release 1 Rubbery ball through the device outlet. Lasts one visit, up to 12 seconds. |
| bumper_vessel_stagger | 1 | Staggered Bumper Chute | Charged Bumpers | Make 5 bumper hits. Balls leave through the open drain. | Release 1 Energize ball through the device outlet. Lasts one visit, up to 12 seconds. |
| pachinko_bumper_vessel | 2 | Pachinko Bumper Vessel | Springy Bumpers | Make 8 bumper hits. Balls leave through the open drain. | Release 4 Rubbery balls through the device outlet. Lasts one visit, up to 12 seconds. |
| bumper_vessel_pinball | 2 | Pinball Bounce Chamber | Splintering Bumpers | Make 8 bumper hits. Balls leave through the open drain. | Release 2 Split balls through the device outlet. Lasts one visit, up to 12 seconds. |
| cyclone_bounce_vault | 3 | Cyclone Bounce Vault | Irrepressible Bumpers | Make 10 bumper hits. Balls leave through the open drain. | Release 10 Rubbery balls through the device outlet. Lasts one visit, up to 12 seconds. |
| word_bank_gob | 1 | G-O-B Word Bank | Charged Letters | Spell G-O-B by lighting each letter in its open lane. | Release 1 Energize ball through the device outlet. Lasts one visit, up to 12 seconds. |
| word_bank_pop | 1 | P-O-P Word Bank | Iron Letters | Spell P-O-P by lighting each letter in its open lane. | Release 3 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |
| word_bank_win | 2 | W-I-N Word Bank | Crackling Letters | Spell W-I-N by lighting each letter in its open lane. | Release 1 Chain Lightning ball through the device outlet. Lasts one visit, up to 12 seconds. |
| word_bank_bam | 2 | B-A-M Word Bank | Explosive Letters | Spell B-A-M by lighting each letter in its open lane. | Release 1 Explosive ball through the device outlet. Lasts one visit, up to 12 seconds. |
| word_bank_boom | 3 | B-O-O-M Word Bank | Cataclysmic Letters | Spell B-O-O-M by lighting each letter in its open lane. | Release 3 Explosive balls through the device outlet. Lasts one visit, up to 12 seconds. |
| word_bank_loot | 3 | L-O-O-T Word Bank | Swarming Letters | Spell L-O-O-T by lighting each letter in its open lane. | Release 12 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |
| wire_gate_cup | 1 | Retention Catch Cup | Charged Cup | Hold 2 balls, then release. Partial fills drain after 6 seconds without the bonus. | Release 1 Energize ball through the device outlet. Lasts one visit, up to 12 seconds. |
| wire_gate_funnel | 1 | Funnel Retention Chute | Iron Funnel | Hold 3 balls, then release. Partial fills drain after 6 seconds without the bonus. | Release 3 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |
| wire_gate_reservoir | 2 | Wire Gate Retention Reservoir | Teeming Reservoir | Hold 4 balls, then release. Partial fills drain after 6 seconds without the bonus. | Release 6 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |
| wire_gate_armory | 3 | Armory Ball Vault | Cataclysmic Vault | Hold 5 balls, then release. Partial fills drain after 6 seconds without the bonus. | Release 3 Explosive balls through the device outlet. Lasts one visit, up to 12 seconds. |
| detonation_triangle_wedge | 1 | Crackling Wedge Kicker | Splitting Wedge | Deflect off wedge 2 times. | Release 1 Split ball through the device outlet. Lasts one visit, up to 12 seconds. |
| detonation_triangle_acute | 1 | Acute Slingshot Triangle | Bouncy Slingshot | Deflect off triangle 3 times. | Release 1 Rubbery ball through the device outlet. Lasts one visit, up to 12 seconds. |
| detonation_triangle_twin | 2 | Dual Slingshot Pincer | Explosive Slingshot | Deflect off pincers 4 times. | Release 1 Explosive ball through the device outlet. Lasts one visit, up to 12 seconds. |
| detonation_triangle_bastion | 3 | Storm Slingshot Bastion | Cataclysmic Slingshot | Deflect off bastion 5 times. | Release 3 Explosive balls through the device outlet. Lasts one visit, up to 12 seconds. |
| detonation_triangle_apex | 3 | Apex Overcharge Wedge | Irrepressible Slingshot | Deflect off wedge 5 times. | Release 10 Rubbery balls through the device outlet. Lasts one visit, up to 12 seconds. |
| bash_toy_idol | 1 | Lesser Goblin Idol | Bouncy Idol | Strike idol 4 times. | Release 1 Rubbery ball through the device outlet. Lasts one visit, up to 12 seconds. |
| bash_toy_anvil | 1 | Blacksmith Anvil | Splitting Anvil | Strike anvil 4 times. | Release 1 Split ball through the device outlet. Lasts one visit, up to 12 seconds. |
| bash_toy_bell | 2 | Gilded Temple Bell | Surging Bell | Strike temple bell 6 times. | Release 3 Energize balls through the device outlet. Lasts one visit, up to 12 seconds. |
| funneled_spinner_chute | 1 | Funneled Chute Spinner | Splitting Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Release 1 Split ball through the device outlet. Lasts one visit, up to 12 seconds. |
| funneled_spinner_v | 1 | V-Funnel Pocket Spinner | Charged Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Release 1 Energize ball through the device outlet. Lasts one visit, up to 12 seconds. |
| funneled_spinner | 2 | Funneled Kinetic Spinner | Splintering Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Release 2 Split balls through the device outlet. Lasts one visit, up to 12 seconds. |
| funneled_spinner_dual | 2 | Pulse Spinner | Teeming Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Release 6 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |
| funneled_spinner_vortex | 3 | Overdrive Vortex Spinner | Irrepressible Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Release 10 Rubbery balls through the device outlet. Lasts one visit, up to 12 seconds. |
| track_stairs_step | 1 | Staircase Speed Rail | Charged Stairs | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Release 1 Energize ball through the device outlet. Lasts one visit, up to 12 seconds. |
| track_right_angle | 1 | Right-Angle Elbow Chute | Splitting Elbow | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Release 1 Split ball through the device outlet. Lasts one visit, up to 12 seconds. |
| track_u_turn | 2 | U-Turn Momentum Loop | Springy Loop | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Release 4 Rubbery balls through the device outlet. Lasts one visit, up to 12 seconds. |
| track_zigzag_chute | 2 | Zigzag Switchback Track | Surging Switchback | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Release 3 Energize balls through the device outlet. Lasts one visit, up to 12 seconds. |
| track_grand_orbit | 3 | Grand Orbit Loop Track | Shattering Orbit | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Release 4 Split balls through the device outlet. Lasts one visit, up to 12 seconds. |
| track_cascade_switchback | 3 | Grand Switchback Pipeline | Swarming Switchback | One ball must enter the arrowed mouth, follow the whole track, and leave the outlet. | Release 12 Plain balls through the device outlet. Lasts one visit, up to 12 seconds. |

## Retired catalog

| Stable ID | Tier | Old name | New name | Physical trigger | Effect |
|---|---|---|---|---|---|
| cascade_reactor | 3 | Cascade Reactor | Scrap Bumpers | Hit all 4 corner boosters and center bumper. | Retired; no activation reward. |
| perpetual_engine | 3 | Perpetual Engine | Endless Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| storm_of_fragments | 3 | Storm of Fragments | Jagged Bumpers | Hit all 3 pop bumpers. | Retired; no activation reward. |
| explosive_contagion | 3 | Explosive Contagion | Sooty Slingshots | Deflect across slingshots 3 times. | Retired; no activation reward. |
| superconductor | 3 | Superconductor | Copper Target | Knock down drop target within 4s. | Retired; no activation reward. |
| rubber_storm | 3 | Rubber Storm | Padded Bumpers | Hit pop bumpers. | Retired; no activation reward. |
| overdrive_cascade | 3 | Overdrive Cascade | Winding Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| goblin_width_tempest | 3 | Goblin Width Tempest | Goblin Kicker | Enter vertical up kicker. | Retired; no activation reward. |
| crown_ricochet | 3 | Crown Ricochet | Crowned Bumpers | Hit pop bumpers. | Retired; no activation reward. |
| twin_mandate | 3 | Twin Mandate | Forked Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| velocity_dividend | 3 | Velocity Dividend | Dented Vault | Smash vault bash toy 3 times. | Retired; no activation reward. |
| phase_sovereign | 3 | Phase Sovereign | Crooked Diverter | Trip mechanical diverter gate. | Retired; no activation reward. |
| renewal_pact | 3 | Renewal Pact | Patched Slingshots | Deflect off slingshots 3 times. | Retired; no activation reward. |
| iron_bloom | 3 | Iron Bloom | Iron Targets | Strike 4 corner bash targets. | Retired; no activation reward. |
| echoes_of_wrench | 3 | Echoes of the Wrench | Wrench Targets | Knock down targets. | Retired; no activation reward. |
| stormgrid_coupling | 3 | Stormgrid Coupling | Copper Effigy | Strike storm bash toy 3 times. | Retired; no activation reward. |
| leech_singularity | 3 | Leech Singularity | Leech Knocker | Strike captive ball 2 times. | Retired; no activation reward. |
| phantom_resonance | 3 | Phantom Resonance | Ghostly Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| supernova_peg | 2 | Supernova Peg | Scorched Targets | Knock down targets. | Retired; no activation reward. |
| chain_conduction | 2 | Chain Conduction | Copper Bumpers | Hit pop bumpers. | Retired; no activation reward. |
| overcharged_drain | 2 | Overcharged Drain | Copper Reservoir | Hold 2 balls, then release. Partial fills drain after 6 seconds without the bonus. | Retired; no activation reward. |
| final_arc_detonation | 2 | Final Arc Detonation | Copper Kicker | Enter vertical up kicker. | Retired; no activation reward. |
| energy_collapse | 2 | Energy Collapse | Sunken Targets | Knock down targets. | Retired; no activation reward. |
| shrapnel_split | 2 | Shrapnel Split | Jagged Diverter | Trip mechanical diverter gate. | Retired; no activation reward. |
| energized_fragments | 2 | Energized Fragments | Copper Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Retired; no activation reward. |
| arc_twins | 2 | Arc Twins | Paired Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| phase_siphon | 2 | Phase Siphon | Faded Letters | Spell W-I-N by lighting each letter in its open lane. | Retired; no activation reward. |
| phase_detonation | 2 | Phase Detonation | Scorched Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| spectral_conduit | 2 | Spectral Conduit | Spectral Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| impact_burst | 2 | Impact Burst | Dented Bumpers | Hit pop bumpers. | Retired; no activation reward. |
| kinetic_charge | 2 | Kinetic Charge | Clockwork Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Retired; no activation reward. |
| static_bounce | 2 | Static Bounce | Copper Letters | Spell P-O-P by lighting each letter in its open lane. | Retired; no activation reward. |
| parasitic_arc | 2 | Parasitic Arc | Leech Diverter | Trip diverter gate. | Retired; no activation reward. |
| draining_fragments | 2 | Draining Fragments | Leech Slingshot | Deflect off slingshot. | Retired; no activation reward. |
| resonant_bounce | 2 | Resonant Bounce | Ringing Targets | Knock down targets. | Retired; no activation reward. |
| ricochet_blast | 2 | Ricochet Blast | Dented Targets | Knock down targets. | Retired; no activation reward. |
| blast_launch | 2 | Blast Launch | Sooty Kicker | Enter vertical up kicker. | Retired; no activation reward. |
| arc_surge_wrench | 2 | Arc Surge Wrench | Wrench Slingshot | Deflect off slingshot. | Retired; no activation reward. |
| goblin_width_pulse | 2 | Goblin Surge Chute | Goblin Sinkhole | Catch ball in ball trap. | Retired; no activation reward. |
| magnet_arc_snare | 2 | Magnet Arc Snare | Magnetic Lock | Lock ball in snare lock. | Retired; no activation reward. |
| spark_trampoline | 2 | Spark Trampoline | Copper Knocker | Strike captive ball 2 times. | Retired; no activation reward. |
| hyper_elastic | 1 | Hyper Elastic | Coiled Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| overdrive_hits | 1 | Overdrive Hits | Clockwork Bumper | Hit pop bumper. | Retired; no activation reward. |
| overclock_network | 1 | Overclock Network | Clockwork Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| spreading_rot | 1 | Spreading Rot | Rotten Target | Knock down drop target. | Retired; no activation reward. |
| cluster_grenade | 1 | Cluster Grenade | Sooty Bumpers | Hit pop bumpers. | Retired; no activation reward. |
| blast_lift | 1 | Blast Lift | Scorched Kicker | Enter vertical up kicker. | Retired; no activation reward. |
| fragmentation_tag | 1 | Fragmentation Tag | Jagged Bumper | Hit pop bumper. | Retired; no activation reward. |
| storm_feedback | 1 | Storm Feedback | Copper Slingshot | Deflect off slingshot. | Retired; no activation reward. |
| overcurrent_surge | 1 | Overcurrent Surge | Tarnished Letters | Spell G-O-B by lighting each letter in its open lane. | Retired; no activation reward. |
| fragment_echo | 1 | Fragment Echo | Jagged Sinkhole | Catch ball in ball trap. | Retired; no activation reward. |
| mass_cascade | 1 | Mass Cascade | Heavy Knocker | Strike captive ball. | Retired; no activation reward. |
| ghost_trail | 1 | Ghost Trail | Haunted Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| phase_instability | 1 | Phase Instability | Warped Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| chest_random_ball | 1 | Plunderer's Cut | Stolen Knocker | Strike captive ball. | Retired; no activation reward. |
| plain_surge | 1 | Plain Surge | Scrap Diverter | Hit all components in module. | Retired; no activation reward. |
| plain_horde | 1 | Plain Horde | Scrap Bumper | Hit pop bumper. | Retired; no activation reward. |
| plain_momentum | 1 | Plain Momentum | Scrap Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| volt_primer | 1 | Volt Primer | Etched Letters | Spell G-O-B by lighting each letter in its open lane. | Retired; no activation reward. |
| explosion_radius | 1 | Bigger Blasts | Sooty Slingshot | Deflect off slingshot. | Retired; no activation reward. |
| explosion_peg_hit_count | 1 | More Explosion Hits | Sooty Lock | Lock ball in chamber. | Retired; no activation reward. |
| explosion_impulse | 1 | Stronger Blast Push | Dented Kicker | Enter vertical up kicker. | Retired; no activation reward. |
| chain_arc | 1 | +1 Chain Jump | Linked Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| chain_range | 1 | Longer Chains | Copper Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| max_energize_stacks | 1 | Deeper Energize | Tarnished Reservoir | Hold 2 balls, then release. Partial fills drain after 6 seconds without the bonus. | Retired; no activation reward. |
| energize_decays_slower | 1 | Slower Energize Fade | Tarnished Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| energized_pegs_repair_faster | 1 | Fast Heal (Energized) | Patched Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| global_peg_durability | 1 | Tough Pegs | Armored Bumpers | Hit pop bumpers. | Retired; no activation reward. |
| peg_recovery_speed | 1 | Faster Peg Recovery | Clockwork Slingshots | Deflect off slingshot. | Retired; no activation reward. |
| devastating_barrage | 1 | Devastating Barrage | Sooty Letters | Spell B-A-M by lighting each letter in its open lane. | Retired; no activation reward. |
| compressed_charge | 1 | Compressed Charge | Dented Locks | Charge locks and collect. | Retired; no activation reward. |
| chest_leech_drain | 1 | Leech Drain Up | Rusty Slingshot | Deflect off slingshot. | Retired; no activation reward. |
| chest_leech_duration | 1 | Longer Leech | Leech Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| chest_phantom_energy | 1 | Phantom Energy | Pale Rail | Guide one ball from the entrance through the complete rail to its outlet. | Retired; no activation reward. |
| chest_rubbery_energy | 1 | Rubbery Energy | Coiled Spinner | Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds. | Retired; no activation reward. |
| chest_bounce_energy | 1 | Plain Energy | Dented Bumper | Hit pop bumper. | Retired; no activation reward. |
| chest_split_energy | 1 | Split Energy | Rusty Diverter | Trip diverter gate. | Retired; no activation reward. |
| apex_orbit_loop | 1 | Apex Orbit Loop | Crested Orbit | Traverse apex orbit loop. | Retired; no activation reward. |
| cyclone_orbit_loop | 2 | Cyclone Orbit Loop | Spiraling Orbit | Traverse cyclone orbit loop. | Retired; no activation reward. |
| grand_orbit_circuit | 3 | Grand Orbit Circuit | Grand Orbit | Traverse grand orbit circuit. | Retired; no activation reward. |

## Aliases and generated items

- The saved alias `chain_surge_wrench` continues to resolve to `arc_surge_wrench`, now Wrench Slingshot. No ID is renamed.
- Generated fusion outputs use Fused Device. They have no authored ball reward. Their IDs, tiers, cells, and recipes stay unchanged.
- Unknown custom names remain unchanged. Debug showcase item titles remain unchanged.
- The runtime catalog contains 122 distinct IDs: 42 active and 80 retired. Duplicate definitions shadowed by the active catalog are not additional variants.
- Before-and-after runtime module snapshots match for every field except display_name across all 122 IDs.
