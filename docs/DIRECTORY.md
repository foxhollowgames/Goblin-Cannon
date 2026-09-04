# AI Codebase Directory

> [!NOTE]
> Auto-generated file. Run `python scripts/generate_directory.py` to update after code changes.

## 1. Autoloads (Global Singletons)

| Autoload | File | Purpose |
|:---|:---|:---|
| `GameState` | [autoloads/game_state.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/game_state.gd) | Run state, sim speed, pause, gold, upgrades, ball abilities. Single source of truth for run-wide data. |
| `Constants` | [autoloads/constants.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/constants.gd) | Physics constants, energy scaling, economy rules, color palette. |
| `TestScenario` | [autoloads/test_scenario.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/test_scenario.gd) | Debug gameplay configuration. Set enabled = true and configure fields to test specific setups. |
| `MilestoneShopData` | [autoloads/milestone_shop_data.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/milestone_shop_data.gd) | Milestone shop pool definitions, peg kinds, and ball blurbs. |
| `KeywordDatabase` | [autoloads/keyword_database.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/keyword_database.gd) | In-game keyword tooltips and flyout system. |
| `AudioPitchRandomizer` | [autoloads/audio_pitch_randomizer.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/audio_pitch_randomizer.gd) | Pitch-randomized SFX playback to avoid repetitive audio. |
| `MonsterPalette` | [autoloads/monster_palette.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/autoloads/monster_palette.gd) | Semantic color palette from 'Monsters Also Die' Lospec. |

## 2. Simulation Modules (Pure Logic)

| File | Purpose |
|:---|:---|
| [simulation/energy_routing.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/simulation/energy_routing.gd) | Energy split pure functions (x100 internal units) |
| [simulation/hit_cooldown.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/simulation/hit_cooldown.gd) | Per-ball per-peg cooldown tracker |
| [simulation/milestone_curve.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/simulation/milestone_curve.gd) | Threshold lookup and curve logic |
| [simulation/reward_generation.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/simulation/reward_generation.gd) | Candidate list shuffle and pick (only RNG source) |

## 3. Tooling Scripts

| Script | Purpose | Usage |
|:---|:---|:---|
| [scripts/lint_file_lengths.py](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/scripts/lint_file_lengths.py) | Audit source files against 500-line limit | `python scripts/lint_file_lengths.py` |
| [scripts/learnings.py](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/scripts/learnings.py) | Query and add to the agent knowledge base | `python scripts/learnings.py query <topic>` |
| [scripts/ollama_coder.py](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/scripts/ollama_coder.py) | Local Ollama code generation with Qwen 2.5 | `python scripts/ollama_coder.py [generate|edit|test]` |
| [scripts/generate_directory.py](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/scripts/generate_directory.py) | Auto-generate docs/DIRECTORY.md from source | `python scripts/generate_directory.py` |
| [scripts/lint_gdscript.py](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/scripts/lint_gdscript.py) | Multi-pass GDScript lint runner | `python scripts/lint_gdscript.py` |

## 4. Test Suite

| Test File | Suite Name | Link |
|:---|:---|:---|
| `test_asset_pack_sprites.gd` | `AssetPackSprites` | [tests/test_asset_pack_sprites.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_asset_pack_sprites.gd) |
| `test_audio_pitch_randomizer.gd` | `AudioPitchRandomizer` | [tests/test_audio_pitch_randomizer.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_audio_pitch_randomizer.gd) |
| `test_ball_visuals.gd` | `BallVisuals` | [tests/test_ball_visuals.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_ball_visuals.gd) |
| `test_base.gd` | `UnnamedTest` | [tests/test_base.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_base.gd) |
| `test_binary_ball.gd` | `BinaryBall` | [tests/test_binary_ball.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_binary_ball.gd) |
| `test_black_hole_event.gd` | `BlackHoleEvent` | [tests/test_black_hole_event.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_black_hole_event.gd) |
| `test_bloom_ball.gd` | `BloomBall` | [tests/test_bloom_ball.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_bloom_ball.gd) |
| `test_board_relic_repositioning.gd` | `BoardRelicRepositioning` | [tests/test_board_relic_repositioning.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_board_relic_repositioning.gd) |
| `test_build_archetypes_and_synergies.gd` | `BuildArchetypesAndSynergies` | [tests/test_build_archetypes_and_synergies.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_build_archetypes_and_synergies.gd) |
| `test_cannon_scrolling_terrain.gd` | `CannonScrollingTerrain` | [tests/test_cannon_scrolling_terrain.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_cannon_scrolling_terrain.gd) |
| `test_cannon_sprite_visuals.gd` | `CannonSpriteVisuals` | [tests/test_cannon_sprite_visuals.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_cannon_sprite_visuals.gd) |
| `test_character_progression_mechanics.gd` | `CharacterProgressionMechanics` | [tests/test_character_progression_mechanics.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_character_progression_mechanics.gd) |
| `test_circular_cannon_widget.gd` | `CircularCannonWidgetAndTakeover` | [tests/test_circular_cannon_widget.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_circular_cannon_widget.gd) |
| `test_city_progression.gd` | `CityProgression` | [tests/test_city_progression.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_city_progression.gd) |
| `test_combat_manager.gd` | `CombatManager` | [tests/test_combat_manager.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_combat_manager.gd) |
| `test_comic_vignette_panel.gd` | `ComicVignettePanel` | [tests/test_comic_vignette_panel.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_comic_vignette_panel.gd) |
| `test_constellation_laser.gd` | `ConstellationLaser` | [tests/test_constellation_laser.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_constellation_laser.gd) |
| `test_corner_cannon_terrain.gd` | `CornerCannonTerrain` | [tests/test_corner_cannon_terrain.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_corner_cannon_terrain.gd) |
| `test_energize_event_pegs.gd` | `EnergizeEventPegs` | [tests/test_energize_event_pegs.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_energize_event_pegs.gd) |
| `test_energy_router.gd` | `EnergyRouter` | [tests/test_energy_router.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_energy_router.gd) |
| `test_energy_routing.gd` | `EnergyRouting` | [tests/test_energy_routing.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_energy_routing.gd) |
| `test_file_lengths.gd` | `FileLengthLint` | [tests/test_file_lengths.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_file_lengths.gd) |
| `test_game_state.gd` | `GameState` | [tests/test_game_state.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_game_state.gd) |
| `test_hit_cooldown.gd` | `HitCooldown` | [tests/test_hit_cooldown.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_hit_cooldown.gd) |
| `test_hopper_ball_cascade.gd` | `HopperBallCascade` | [tests/test_hopper_ball_cascade.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_hopper_ball_cascade.gd) |
| `test_hopper_steering.gd` | `HopperSteering` | [tests/test_hopper_steering.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_hopper_steering.gd) |
| `test_hopper_top_bar_debug_menu.gd` | `HopperTopBarDebugMenu` | [tests/test_hopper_top_bar_debug_menu.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_hopper_top_bar_debug_menu.gd) |
| `test_junk_box_dynamic_scroll.gd` | `JunkBoxDynamicScroll` | [tests/test_junk_box_dynamic_scroll.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_junk_box_dynamic_scroll.gd) |
| `test_junk_box_inventory.gd` | `JunkBoxInventory` | [tests/test_junk_box_inventory.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_junk_box_inventory.gd) |
| `test_junk_box_manual_placement.gd` | `JunkBoxManualPlacement` | [tests/test_junk_box_manual_placement.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_junk_box_manual_placement.gd) |
| `test_junk_box_relic_display_and_tooltips.gd` | `JunkBoxRelicDisplayAndTooltips` | [tests/test_junk_box_relic_display_and_tooltips.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_junk_box_relic_display_and_tooltips.gd) |
| `test_junk_box_sidebar_display.gd` | `JunkBoxSidebarDisplay` | [tests/test_junk_box_sidebar_display.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_junk_box_sidebar_display.gd) |
| `test_junk_box_ui_and_board_transfer.gd` | `JunkBoxUIAndBoardTransfer` | [tests/test_junk_box_ui_and_board_transfer.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_junk_box_ui_and_board_transfer.gd) |
| `test_keyword_database.gd` | `KeywordDatabase` | [tests/test_keyword_database.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_keyword_database.gd) |
| `test_keyword_flyout_tooltip.gd` | `KeywordFlyoutTooltip` | [tests/test_keyword_flyout_tooltip.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_keyword_flyout_tooltip.gd) |
| `test_kingdom_board_events.gd` | `KingdomBoardEvents` | [tests/test_kingdom_board_events.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_kingdom_board_events.gd) |
| `test_live_board_ghost_placement.gd` | `LiveBoardGhostPlacement` | [tests/test_live_board_ghost_placement.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_live_board_ghost_placement.gd) |
| `test_lucky_gold_peg.gd` | `LuckyGoldPeg` | [tests/test_lucky_gold_peg.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_lucky_gold_peg.gd) |
| `test_magnet_peg.gd` | `MagnetPeg` | [tests/test_magnet_peg.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_magnet_peg.gd) |
| `test_main_cannon.gd` | `MainCannon` | [tests/test_main_cannon.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_main_cannon.gd) |
| `test_milestone_curve.gd` | `MilestoneCurve` | [tests/test_milestone_curve.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_milestone_curve.gd) |
| `test_milestone_shop_data.gd` | `MilestoneShopData` | [tests/test_milestone_shop_data.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_milestone_shop_data.gd) |
| `test_milestone_tracker_events.gd` | `MilestoneTrackerEvents` | [tests/test_milestone_tracker_events.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_milestone_tracker_events.gd) |
| `test_monsters_also_die_palette.gd` | `MonstersAlsoDiePalette` | [tests/test_monsters_also_die_palette.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_monsters_also_die_palette.gd) |
| `test_multi_peg_machinery.gd` | `MultiPegMachinery` | [tests/test_multi_peg_machinery.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_multi_peg_machinery.gd) |
| `test_on_board_relic_tooltips.gd` | `OnBoardRelicTooltips` | [tests/test_on_board_relic_tooltips.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_on_board_relic_tooltips.gd) |
| `test_pause_game_comic_overlays.gd` | `PauseGameComicOverlays` | [tests/test_pause_game_comic_overlays.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_pause_game_comic_overlays.gd) |
| `test_peg_grid_alignment.gd` | `PegGridAlignment` | [tests/test_peg_grid_alignment.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_peg_grid_alignment.gd) |
| `test_phantom_trail.gd` | `PhantomTrail` | [tests/test_phantom_trail.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_phantom_trail.gd) |
| `test_pinball_components.gd` | `PinballComponents` | [tests/test_pinball_components.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_pinball_components.gd) |
| `test_pinball_machinery.gd` | `PinballMachinery` | [tests/test_pinball_machinery.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_pinball_machinery.gd) |
| `test_polyomino_drag_drop.gd` | `PolyominoDragDrop` | [tests/test_polyomino_drag_drop.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_polyomino_drag_drop.gd) |
| `test_polyomino_machinery.gd` | `PolyominoMachinery` | [tests/test_polyomino_machinery.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_polyomino_machinery.gd) |
| `test_polyomino_relic_shapes.gd` | `PolyominoRelicShapes` | [tests/test_polyomino_relic_shapes.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_polyomino_relic_shapes.gd) |
| `test_relic_audio_levels.gd` | `RelicAudioLevels` | [tests/test_relic_audio_levels.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_audio_levels.gd) |
| `test_relic_board_triggers.gd` | `RelicBoardTriggers` | [tests/test_relic_board_triggers.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_board_triggers.gd) |
| `test_relic_enclosures.gd` | `Relic Enclosures` | [tests/test_relic_enclosures.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_enclosures.gd) |
| `test_relic_junk_box_return.gd` | `RelicJunkBoxReturn` | [tests/test_relic_junk_box_return.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_junk_box_return.gd) |
| `test_relic_machinery_rotation.gd` | `RelicMachineryRotation` | [tests/test_relic_machinery_rotation.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_machinery_rotation.gd) |
| `test_relic_pinball_activation.gd` | `RelicPinballActivation` | [tests/test_relic_pinball_activation.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_pinball_activation.gd) |
| `test_relic_pinball_goals.gd` | `RelicPinballGoals` | [tests/test_relic_pinball_goals.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_pinball_goals.gd) |
| `test_relic_selection_preview.gd` | `RelicSelectionPreview` | [tests/test_relic_selection_preview.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_selection_preview.gd) |
| `test_relic_widget_distribution.gd` | `RelicWidgetDistribution` | [tests/test_relic_widget_distribution.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_relic_widget_distribution.gd) |
| `test_reward_generation.gd` | `RewardGeneration` | [tests/test_reward_generation.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_reward_generation.gd) |
| `test_reward_handler.gd` | `RewardHandler` | [tests/test_reward_handler.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_reward_handler.gd) |
| `test_script_parse_smoke.gd` | `ScriptParseSmoke` | [tests/test_script_parse_smoke.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_script_parse_smoke.gd) |
| `test_shop_ball_prices.gd` | `ShopBallPrices` | [tests/test_shop_ball_prices.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_shop_ball_prices.gd) |
| `test_slotted_relic_effects.gd` | `SlottedRelicEffects` | [tests/test_slotted_relic_effects.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_slotted_relic_effects.gd) |
| `test_sticky_slime_event.gd` | `StickySlimeEvent` | [tests/test_sticky_slime_event.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_sticky_slime_event.gd) |
| `test_story_campaign_architecture.gd` | `StoryCampaignArchitecture` | [tests/test_story_campaign_architecture.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_story_campaign_architecture.gd) |
| `test_test_scenario.gd` | `TestScenario` | [tests/test_test_scenario.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_test_scenario.gd) |
| `test_tetromino_module_fusion.gd` | `TetrominoModuleFusion` | [tests/test_tetromino_module_fusion.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_tetromino_module_fusion.gd) |
| `test_tooltip_text_refinement.gd` | `TooltipTextRefinement` | [tests/test_tooltip_text_refinement.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_tooltip_text_refinement.gd) |
| `test_top_gold_counter_ui.gd` | `TopGoldCounterUI` | [tests/test_top_gold_counter_ui.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_top_gold_counter_ui.gd) |
| `test_ui_buttons_audit.gd` | `UIButtonAudit` | [tests/test_ui_buttons_audit.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_ui_buttons_audit.gd) |
| `test_ui_wireframe_and_screen_layout.gd` | `UIWireframeAndScreenLayout` | [tests/test_ui_wireframe_and_screen_layout.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_ui_wireframe_and_screen_layout.gd) |
| `test_volatile_gas.gd` | `VolatileGas` | [tests/test_volatile_gas.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_volatile_gas.gd) |
| `test_wall_health_scaling.gd` | `WallHealthScaling` | [tests/test_wall_health_scaling.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_wall_health_scaling.gd) |
| `test_wall_siege.gd` | `WallSiege` | [tests/test_wall_siege.gd](file:///C:/Users/josep/Desktop/Games/Goblin-Cannon/tests/test_wall_siege.gd) |

## 5. Quick Reference: Where Do I Find...?

| I need to... | Look in... |
|:---|:---|
| Change energy math or routing | `simulation/energy_routing.gd`, `scenes/energy/energy_router.gd` |
| Add a new ball ability | `resources/balls/ball_definition.gd`, `scenes/balls/ball.gd`, `scenes/board/board.gd` |
| Add a new peg type | `scenes/board/peg.gd`, `autoloads/constants.gd` |
| Add a new relic | `resources/polyomino/polyomino_relic_database.gd`, `resources/polyomino/polyomino_module_data.gd` |
| Add a machinery device | `scenes/board/machinery/` (extend `polyomino_machinery_component.gd`) |
| Change wall HP or timer | `scenes/main/combat_manager.gd`, `resources/cities/city_definition.gd` |
| Add a new reward type | `scenes/rewards/reward_handler.gd`, `scenes/rewards/reward_draft_panel.gd` |
| Add a new board event | `scenes/board/` (extend `base_board_event_controller.gd`) |
| Change milestone thresholds | `simulation/milestone_curve.gd`, `resources/milestones/milestone_definition.gd` |
| Add a new sidearm | `scenes/systems/sidearms/` (extend `sidearm_base.gd`) |
| Change hopper or conduit | `scenes/hopper/hopper.gd`, `scenes/conduit/conduit.gd` |
| Add a new test | `tests/test_<system>.gd` |
| Add a debug tool | `scenes/main/game_coordinator.gd`, `scenes/ui/debug_*.gd` |
| Change color palette | `autoloads/constants.gd`, `autoloads/monster_palette.gd` |
| Change conquest/campaign flow | `scenes/main/game_coordinator.gd`, `scenes/main/combat_manager.gd` |
| Change junk box / inventory | `resources/inventory/junk_box_data.gd`, `scenes/ui/junk_box/` |

