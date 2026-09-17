# TASK-097: Relic Visual Tiles on Modals and Description Updates

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** UI / Visuals / Relics
- **Target Branch:** `feature/relic-visual-tiles-and-description-updates`
- **Related Tasks:** [TASK-035](TASK-035-relic-selection-screen-layout.md), [TASK-068](TASK-068-relic-tier-visual-styling.md), [TASK-082](TASK-082-simplify-relic-tooltip-terminology.md), [TASK-093](TASK-093-rework-relics-into-deliberate-pinball-devices.md), [TASK-096](TASK-096-archive-ball-upgrades-in-merchant-and-refocus-shop.md)

## Description

Add visual tiles (polyomino shape cells, tier borders, and machinery component glyphs) to relic cards in reward modals and merchant storefronts. Standardize and update relic descriptions across the interface so that players can clearly see the kinetic machinery behavior, activation trigger, and reward effect.

---

## Requirements

### 1. Visual Tiles on Modal Relic Cards
- Integrate RelicLayoutPreview into RewardDraftPanel._make_relic_card via RewardCardBuilder.make_relic_shop_preview.
- Render the polyomino footprint with tier-colored cell borders and kinetic machinery component glyphs.
- Center the visual preview between the title/tier banner and the description text.
- Adjust card frame height and container spacing to prevent text clipping or overflow.

### 2. Standardized Relic Description Rework
- Standardize relic description formatting across RewardDraftPanel, DebugFullStoreModal, and MajorUpgradeDraftPanel.
- Present descriptions with three clear elements:
  1. Kinetic Device Behavior (how the machinery functions on the board).
  2. Trigger Condition (the hit count or widget event required).
  3. Effect / Reward (the gameplay effect when activated).
- Make sure PolyominoRelicDatabase.format_relic_tooltip and related description helpers supply complete, current text.

### 3. File Length and Coding Standards (Rule 7)
- Maintain all modified files strictly <= 500 lines:
  - `scenes/rewards/reward_card_builder.gd`
  - `scenes/rewards/reward_draft_panel.gd`
  - `scenes/ui/debug_full_store_modal.gd`
  - `resources/polyomino/polyomino_relic_database.gd`
- Run `python scripts/lint_gdscript.py` and `python scripts/lint_file_lengths.py`.

### 4. Verification and Headless Tests
- Author tests in `tests/test_relic_visual_tiles.gd` verifying:
  - Relic cards in RewardDraftPanel contain a non-null RelicLayoutPreview control with valid cell bounds.
  - Relic description labels contain kinetic machinery, trigger, and effect text.
  - All modified files pass linting and headless test suites cleanly.
- Make sure all tests pass under `godot --headless -s tests/run_tests.gd`.

---

## Acceptance Criteria

- [x] Relic shop cards in RewardDraftPanel display visual polyomino tiles with machinery glyphs.
- [x] Relic descriptions across modal dialogs show kinetic behavior, trigger condition, and reward effect.
- [x] Card heights and layout containers prevent text clipping.
- [x] All modified files stay strictly <= 500 lines.
- [x] Automated tests pass cleanly with zero regressions.
