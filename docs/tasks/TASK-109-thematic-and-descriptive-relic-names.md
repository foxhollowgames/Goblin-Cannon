# TASK-109: Thematic and Descriptive Relic Names

- **Status:** IN_PROGRESS
- **Priority:** P2
- **Category:** Design / Relics
- **Target Branch:** `feature/thematic-and-descriptive-relic-names`
- **Related Tasks:** TASK-082, TASK-100, TASK-103

## Description

Rename all relics to feel more like objects from the Goblin Cannon world and less like dry mechanical labels. Each name must still help the player understand the relic's main effect or physical action.

---

## Requirements

### 1. Complete Naming Review
- Use exactly two words: `<ball adjective> <device name>`.
- The first word identifies the ball reward. The second word identifies the physical device or action, such as Bumpers or Sinkhole.
- Reuse each ball adjective across device families so players can recognize the reward at a glance.
- Use a short adjective progression for each ball type to suggest increasing output. Replace the adjective at each level; do not add a third word or an intensity modifier.
- Keep exact ball counts in Effect text. Do not imply stronger balls when only the number of balls changes.
- Approved naming pattern examples: Bouncy Bumpers and Crackling Sinkhole. Bouncy, Springy, and Irrepressible are draft progression words, not an approved final vocabulary.
- Inventory all current relic names, including every tier and variant.
- Record each relic's stable ID, old name, proposed name, and main effect in a review table.
- Use goblin craft, scavenged objects, unstable magic, and the game's comic tone where they fit the actual relic.
- Prefer short, distinct names with a clear link to the relic's effect or physical action. Avoid generic stat labels and vague fantasy names.
- Make related tiers and variants recognizable without giving different relics confusingly similar names.

### 2. Consistent Display Names
- Apply the final names to all player-facing relic displays, including shops, rewards, inventory, board tooltips, and debug catalogs.
- Keep Trigger and Effect text clear and mechanically accurate. Change that text only where it references an old name.
- Preserve stable IDs, save compatibility, effects, balance, geometry, and acquisition rules. This task changes names only.

### 3. Verification
- Review one representative relic family across its tiers and variants before expanding the naming pass to the full catalog.
- Check the complete old-to-new name table against the catalog so no relic is missed.
- Check that names fit existing cards and tooltips and do not create ambiguous duplicates.
- Verify that all display paths use the new names and that relic lookup still uses stable IDs.

---

## Acceptance Criteria

- [ ] Every relic, tier, and variant has an entry in the old-to-new name table.
- [ ] All relics have thematic names that still suggest their effect or physical action.
- [ ] Titles contain exactly two words, with consistent ball adjectives across device families and reviewed progressions for output volume.
- [ ] Names are distinct, readable, and consistent across all player-facing displays.
- [ ] Trigger and Effect text remains accurate and contains no stale name references.
- [ ] Stable IDs, saved relic references, and gameplay behavior are unchanged.
- [ ] Relevant checks and the required quality audit pass before implementation is merged.

## Implementation Handoff

- Branch: `feature/thematic-and-descriptive-relic-names`. Main is up to date. No commit or PR yet.
- Name table: [Relic name review](relic-name-review-109.md). Covers 122 IDs: 42 active and 80 retired, plus the saved alias and generated fusion items.
- Implemented canonical names, saved item/module title refresh, old reward-card factory names, two-word fusion names, and old fusion-title migration.
- Changed production files: `resources/polyomino/relic_names.gd`, `deliberate_relic_catalog.gd`, `polyomino_relic_database.gd`, `polyomino_module_data.gd`, `polyomino_fusion_system.gd`, `resources/inventory/junk_box_item.gd`, and `scenes/rewards/reward_card_catalog.gd`.
- Added and registered `tests/test_relic_names.gd` and `tests/test_relic_name_paths.gd`. Updated old-name assertions in `test_junk_box_inventory.gd` and `test_slotted_relic_effects.gd`.
- Verification: focused name suite 1841 passed; display/fusion suite 578 passed. Final raw Godot process (`--headless --path . --script tests/run_tests.gd`) exited 0 with 20613 passed, 0 failed, and no script errors. Used Start-Process -Wait -PassThru to obtain the actual Windows GUI executable exit code.
- Rendered actual Merchant and reward cards at 1280x720. Long titles fit without layout changes. The renderer exited after saving the image.
- Initial before/after runtime module snapshots matched in every field except display_name across all 122 IDs.
- Required quality audit ran. Directory sync passes. File length audit is blocked by an unchanged main-branch file: `docs/knowledge/LEARNINGS.md`, 2565 lines against its 2500-line baseline. Custom rule warnings are existing debt. gdlint is not installed. Follow-up: TASK-114.
- Do not trust the audit wrapper's test PASS: it can override a failed process when any suite prints `0 failed`. The final raw process result above is authoritative.
- Known remaining naming gap: completion banners use goal_title. Four goal titles exactly match old relic names: `crown_ricochet` (Crown Ricochet), `ghost_trail` (Ghost Trail), `word_bank_bam` (B-A-M Word Bank), and `funneled_spinner_dual` (Pulse Spinner). Update only these name references, including old saves, without changing unrelated goal titles or Trigger/Effect text. Add a focused assertion, then rerun affected checks.
- Remaining workflow: finish banner references; review new-file style; run final affected checks; obtain independent PR review; resolve the audit baseline blocker before merge; record post-merge learning. Do not mark the task done yet.
- Stopped at the project usage checkpoint. Latest included usage: 62% of the five-hour window, 10% weekly; ordinary usage allowed. No reset or paid-credit request made.
- Local audit evidence and reusable Qwen inputs were moved outside the checkout to `C:/Users/josep/.codex/visualizations/2026/09/25/01a0d8da-8a18-7190-a753-55b82653520c/task109-evidence/`. Key files: `card_review.png`, `before.json`, `after.json`, `full-stdout.txt`, and `full-stderr.txt`. Scratch files must not be committed.
- All launched Godot and generation processes have exited. No review agents were started.

## Resumed checkpoint — 2026-09-26

- Updated branch to main revision 2ff43dc (TASK-114 merged). The old audit-baseline blocker is resolved.
- Completed the four known old goal-title references in database factories and module deserialization. Custom and unrelated goal titles remain unchanged.
- Added tests/test_relic_goal_names.gd and registered it in tests/run_tests.gd. It checks fresh and saved titles, actual completion-banner text, preserved module fields, and fallback titles.
- Latest focused command: Godot --headless --path . --script .godot/task109_focused.gd. Raw process exit 0; 2456 passed, 0 failed; no SCRIPT ERROR. Existing ObjectDB exit warning remains. Logs: .godot/task109-focused-out.txt and task109-focused-err.txt.
- Local Qwen source attempt 1 used the wrong file; attempt 2 introduced mixed indentation. Both generated test candidates were invalid. Used the bounded direct-edit fallback from docs/AGENT_WORKFLOW.md to correct indentation and write the focused test.
- Baseline static check initially found the nested task 116 worktree as source. Moved that checkout to goblin-cannon-agent-task_116, the standard ignored location. The main checkout needs a fresh final audit.
- Changed source files remain those listed above, plus the goal-title helper and wiring in relic_names.gd, polyomino_relic_database.gd, and polyomino_module_data.gd. tests/run_tests.gd now registers three naming suites.
- Preserved all pre-sync local changes in stash `Preserve task 109 and local task records before main sync`. Restored only task 109 files. Do not apply the whole stash: it contains stale TASK-114, TASK-115, knowledge, and task 116 records. Check any unrelated records before dropping it.
- Remaining: review new-file style, final full audit, PR creation, independent review, merge, post-merge learning, and DONE status. Prior card rendering evidence remains valid because title text and layouts did not change in this resumed pass.
- Usage checkpoint: 54% five-hour usage; reset timestamp 1790474412. The 50% gate is handled for this window. User continuation may resume without repeating that gate; next gate is 70%.
- No task-owned test or generation process remains. Reviewer 116 was completed and interrupted. No task 109 reviewer has started.

## Final verification — 2026-09-26

- Full audit passed: python scripts/audit_quality.py. Raw Godot exit 0, 20710 passed, 0 failed, no SCRIPT ERROR. Static checks, file lengths, and 11 tooling tests passed. Existing advisory warnings and optional missing gdlint remain.
- Naming changes do not alter physics or ball ownership; separate physics tests are not needed. The full suite includes the existing gameplay checks.
- All four old completion titles are now covered by saved-data and visible-banner assertions. The prior completion-title gap and TASK-114 audit blocker are resolved.
- Ready for independent PR review. Acceptance checks will be closed after review and merge.

## Independent review

- PR #93: https://github.com/foxhollowgames/Goblin-Cannon/pull/93.
- Independent reviewer approved source revision 31a6bac with no actionable findings. Review covered catalog completeness, saved data, cards, goal-title migration, and unchanged gameplay fields. Reviewer completed and was interrupted.
- Integrated the independently tested task 116 merge. Task 109 source is unchanged from the reviewed revision.
