# TASK-106: Implement approved temporary relic ball rewards

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Systems / Gameplay / Relics
- **Target Branch:** `feature/temporary-relic-ball-rewards`
- **Related Tasks:** TASK-100, TASK-103, TASK-104, TASK-105

## Description

Implement the user-approved [temporary relic ball plan](../knowledge/temporary-relic-ball-plan.md). The user approved execution on 2026-09-23. TASK-101 and TASK-102 are already merged.

---

## Requirements

### 1. Scope and Implementation
- Use the exact 42-entry mapping and tier budgets. Binary is Tier 3 only. Selected Tier 3 relics grant ten Rubbery balls.
- Replace all activation-time energy, knock, supercharge, and compound rewards with the authored temporary balls.
- Keep ordinary ball abilities. Reserve Leech, Phantom, Constellation, Bloom, and Volatile for future class rewards.
- Enforce one visit, 720 simulation ticks, bottom collection once, no hopper return, inherited expiration, and no temporary reward progress.
- Implement deterministic allocation, 24 active or reserved slots, six-tick emission spacing, and 60-tick blocked-outlet cancellation.
- Preserve capture ownership and energy when Split or Binary creates fragments. Clear temporary state on transitions and reset.
- Offer only the 42 deliberate relics. Preserve legacy physical inventory and label it as retired. Do not change its placed footprint.
- Show exact reward count and type, lifetime, outlet, and canceled emissions in shared UI.

---

## Acceptance Criteria

- [ ] All 42 authored rewards match the approved type, count, and acquisition tier.
- [ ] No activation energy injection or permanent inventory growth occurs.
- [ ] Lifecycle, capture cleanup, duplicate callbacks, emission caps, blocked outlets, and transitions pass outcome tests.
- [ ] Split and Binary conserve energy and inherit lifetime without bypassing population limits.
- [ ] Temporary machinery contacts cannot advance shared goals, including word banks and spinner charge.
- [ ] Existing ball effects and rotated device flows pass regression tests.
- [ ] Tests pass cleanly.
- [ ] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Authoring record

Local Qwen was tried first. Three consecutive reviews of the reward definition failed. Review 1 found invalid budget data and mutation during validation. Review 2 found invalid Godot syntax, the wrong Explosive tier, and continued mutation. Review 3 found invalid ternary syntax, incorrect count validation, and missing typed signatures. The user-authorized lower-grade Codex fallback is active for this implementation. No paid API fallback is authorized.

## Included-allowance checkpoint — 2026-09-23 evening

Branch: `feature/temporary-relic-ball-rewards`. Main was pulled before work. All changes are uncommitted. Preserve the approved design edits and all runtime work. No PR exists for TASK-106 yet.

The first implementation pass added the 42-entry reward resource, TEMPORARY_BALLS enum, deliberate catalog mapping, ball lifetime markers, a Board queue, split inheritance, temporary contact guards, and wall/city cleanup. Its unit run reported 18,021 passed and zero failed. This does not verify the full approved plan. The parent rejected that handoff as incomplete. Subsequent extraction work has not had a full audit.

Local Qwen failed three consecutive reviewed attempts before the lower-grade Codex fallback began. Do not repeat those attempts as a prerequisite. The fallback is authorized for this work. Use a lower-grade model for code changes; the primary agent handles review, documentation, and tools. Included usage must be available. No API credits, reset redemption, purchases, or paid fallback are authorized.

Outstanding work and review findings:

1. Finish and validate the new `scenes/board/temporary_relic_ball_controller.gd` extraction. The first controller added about 180 lines to Board. Keep controller and geometry helpers under 500 lines. Check Board wrappers and removed-field references carefully after the interrupted extraction.
2. Review actual emission geometry. Impact devices have no flow ports, so the initial implementation canceled all wedge and bash rewards. Use the nearest open side outside the actual body. Snapshot the completing word-bank lane at activation; do not follow the triggering ball as it moves. Use device release velocity and solid-collider obstruction checks. Allocate simultaneous requests in module-instance order. Keep six-tick spacing and a 60-tick blocked limit.
3. Detach expired or discarded balls from capture owners and their retained/traveler lists before deletion. Marker removal alone is insufficient. Age balls outside Board active lists. Reset must clear pending keys, reservations, and balls. Do not let pending rewards survive a removed source device.
4. Independent draft review found a cap bypass when permanent Binary splits a temporary victim. Check capacity when either side causes a temporary child. All three split paths lost odd energy: assign the original the total minus the child share, only after successful creation. Do not use a minimum-one share that creates energy from zero or one. Full-cap temporary Split consumes its trigger but keeps its original energy. Test repeated splitter and goblin-reset paths.
5. Temporary Rubbery material must be applied after the ball enters the tree; `_ready` previously replaced its material. Preserve ordinary ability behavior. Add a shrinking lifetime outline.
6. `GameBallManager` currently guards exit only. All inventory counts, removals, conversions, and direct black-hole return paths must exclude temporary balls.
7. Delete the old energy surge, supercharge, global knock, concussive, and permanent multiball dispatch branches from `polyomino_goal_reward_handler.gd`. They still exist in the first handoff. Retained rewards must not inject energy. Preserve normal component contact energy.
8. Integrate the typed reward into module data and serialization, including old-save migration. Keep existing physical legacy geometry but label it retired. Limit every normal acquisition source to the 42 deliberate IDs, preserving city gates and all 14 Tier 3 free wall routes. The catalog/UI agent was interrupted before a completed handoff; inspect its current diff before resuming. Rename Dual Spinner to Pulse Spinner.
9. Add real UI output: count/type badges, lifetime cue, and actual emitted/canceled source feedback. An unconnected status signal is not visible feedback. Reuse shared previews and physical outlet arrows.
10. The new test suite initially covered only mappings, markers, and direct spawn calls. Add outcome tests for queued exact 10/12 counts, reservations, duplicate callbacks, blocked cancellation, captured expiry, collection once/no hopper growth, energy conservation, cap inheritance, mixed temporary/permanent word-bank/spinner/reservoir contacts, reset/transitions, old saves, and acquisition. Ensure all fake balls are freed. Run separate real-physics chain/rotation tests, then the full elevated quality audit.
11. Open PR, run independent final review, fix findings, merge, stop agents, and record learning. Do not infer final approval from the preliminary review or the first green unit run.

Agents used: `/root/relic_implementation` owns runtime/controller/tests; `/root/relic_catalog_ui` owns data/acquisition/UI; `/root/pr_reviewer_relic_draft` finished its read-only review and was stopped. Resume only the needed work. Avoid conflicting file ownership. The user Godot editor PID 26388 must not be stopped. No test processes remained at checkpoint.

Design packets TASK-100, TASK-103, and TASK-105 are DONE for user-approved design only. TASK-104 remains BACKLOG for balance measurements. TASK-106 remains IN_PROGRESS. Existing test and audit results are not proof of the unfinished implementation.

Final parser checkpoint: the runtime agent restored Board state fields and reports a passing parser check. Board still uses the embedded queue. The new helper is initialized but not the active controller. No full test run followed extraction. Both implementation agents were stopped before the allowance limit.


## Night checkpoint — 2026-09-23, resume at 02:30 Mountain

All agents are stopped. No commit or PR. Main was pulled and was current. Included usage was 89% five-hour and 86% weekly before final checkpoint tools. Credit balance remained 1468.2998360000 throughout this resumed run.

Data/acquisition/UI agent completed its source changes: typed module reward and canonical save migration; 42-entry offer roster for merchant/wall/boss/chest; all14 deliberate Tier3 routes; retired physical items; Pulse Spinner name; shared exact-count badge/text. It did NOT add required data tests. Its sandbox test launch failed before execution. Inspect these changes rather than assuming they are approved.

Runtime ownership moved from the earlier Luna agent to `/root/relic_runtime_finish` using lower-grade Sol. It changed controller, Board, Ball, and GameBallManager. Controller is now active, reserves requests on the next tick in sorted module/sequence order, snapshots ports, counts actual releases, checks solid collisions, updates captured age, and detaches ownership. Board uses controller collection and registers split children; temporary split state survives goblin reset. Ball has a lifetime ring and material correction. GameBallManager excludes temporary balls in count/remove/convert/direct black-hole paths. These changes are NOT outcome-tested. No tests were authored in this pass.

Parent ran a synchronous raw Godot test process after stopping edits: exit1, 18,048 assertions passed,140failed. Full diagnostic is `task106-test-output.log` in repo root. Failing suites: TemporaryRelicBallRewards12, ThirdCityRelics38, RewardHandler5, RelicPinballGoals80, OnBoardRelicTooltips1, RelicPinballActivation4. Many assertions expect retired legacy rewards. Update them to verify the new production roster and explicit retirement behavior; do not simply suppress them. Temporary population smoke uses uninitialized controller/direct private spawn and must be replaced with real queued outcome tests. Tests also leaked objects; clean fixtures.

Audit_quality reported lint failure, file-length pass, and a misleading final Godot pass. Its wrapper treats any occurrence of zero-failed text as success even when the total fails. Require raw process exit0, no SCRIPT ERROR, and final total zero failures. Do not change audit infrastructure as part of this feature unless necessary; report real results.

On Windows, direct PowerShell invocation of the GUI Godot executable detached and produced an empty log. Use Python subprocess.run with argument list, capture_output=True, text=True, timeout=60 or120, write stdout+stderr to the log, print returncode. Run elevated due user:// log restrictions. Only user editor PID26388 remained at final process check; do not stop it.

Still required: review all runtime contracts against plan; remove any remaining old reward branches; verify visible status signal consumers and exact emitted/canceled semantics; complete tests for all queued/cap/expiry/ownership/split/collection/transition/mixed-goal behavior, old saves and acquisition; real physics with rotations; full audit; independent PR review and merge. Inspect collect_ball ordering and capture detach property handling. Existing tracked Rapier tilde-DLL deletion is test/editor cleanup and must be restored before committing. Remove task106-test-output.log from final changes after preserving necessary evidence in the packet.
