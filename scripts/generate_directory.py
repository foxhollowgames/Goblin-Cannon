#!/usr/bin/env python3
"""
AI Codebase Directory Generator for Goblin Cannon.
Scans GDScript files, resources, simulation modules, tests, and scripts to generate docs/DIRECTORY.md.
"""

import os
import re
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DIRECTORY_MD_PATH = os.path.join(PROJECT_ROOT, "docs", "DIRECTORY.md")

AUTOLOADS = [
    ("GameState", "autoloads/game_state.gd", "Run state, sim speed, pause, gold, upgrades, ball abilities. Single source of truth for run-wide data."),
    ("Constants", "autoloads/constants.gd", "Physics constants, energy scaling, economy rules, color palette."),
    ("TestScenario", "autoloads/test_scenario.gd", "Debug gameplay configuration. Set enabled = true and configure fields to test specific setups."),
    ("MilestoneShopData", "autoloads/milestone_shop_data.gd", "Milestone shop pool definitions, peg kinds, and ball blurbs."),
    ("KeywordDatabase", "autoloads/keyword_database.gd", "In-game keyword tooltips and flyout system."),
    ("AudioPitchRandomizer", "autoloads/audio_pitch_randomizer.gd", "Pitch-randomized SFX playback to avoid repetitive audio."),
    ("MonsterPalette", "autoloads/monster_palette.gd", "Semantic color palette from 'Monsters Also Die' Lospec."),
]

SIMULATION_MODULES = [
    ("simulation/energy_routing.gd", "Energy split pure functions (x100 internal units)"),
    ("simulation/hit_cooldown.gd", "Per-ball per-peg cooldown tracker"),
    ("simulation/milestone_curve.gd", "Threshold lookup and curve logic"),
    ("simulation/reward_generation.gd", "Candidate list shuffle and pick (only RNG source)"),
]

PYTHON_SCRIPTS = [
    ("scripts/lint_file_lengths.py", "Audit source files against 500-line limit", "python scripts/lint_file_lengths.py"),
    ("scripts/learnings.py", "Query and add to the agent knowledge base", "python scripts/learnings.py query <topic>"),
    ("scripts/ollama_coder.py", "Local Ollama code generation with Qwen 2.5", "python scripts/ollama_coder.py [generate|edit|test]"),
    ("scripts/generate_directory.py", "Auto-generate docs/DIRECTORY.md from source", "python scripts/generate_directory.py"),
    ("scripts/lint_gdscript.py", "Multi-pass GDScript lint runner", "python scripts/lint_gdscript.py"),
]


def parse_gdscript_header(file_path):
    """Extract top-level docstring and extends line from a GDScript file."""
    docstring = ""
    extends_cls = ""

    if not os.path.exists(file_path):
        return extends_cls, docstring

    with open(file_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("extends "):
                extends_cls = stripped.split("extends ")[1].strip()
            elif stripped.startswith("## "):
                if not docstring:
                    docstring = stripped[3:].strip()
            elif stripped.startswith("func ") or stripped.startswith("var ") or stripped.startswith("const "):
                break

    return extends_cls, docstring


def scan_tests():
    """Scan tests/ for test files."""
    tests_dir = os.path.join(PROJECT_ROOT, "tests")
    test_files = []
    if os.path.exists(tests_dir):
        for f in sorted(os.listdir(tests_dir)):
            if f.startswith("test_") and f.endswith(".gd"):
                rel_path = os.path.join("tests", f).replace("\\", "/")
                full_path = os.path.join(tests_dir, f)
                suite_name = ""
                with open(full_path, "r", encoding="utf-8", errors="replace") as tf:
                    for line in tf:
                        if "suite_name" in line and "=" in line:
                            suite_name = line.split("=")[1].strip().strip('"').strip("'")
                            break
                test_files.append((f, rel_path, suite_name))
    return test_files


def generate_directory_markdown():
    """Build the markdown content for docs/DIRECTORY.md."""
    lines = []
    lines.append("# AI Codebase Directory")
    lines.append("")
    lines.append("> [!NOTE]")
    lines.append("> Auto-generated file. Run `python scripts/generate_directory.py` to update after code changes.")
    lines.append("")
    lines.append("## 1. Autoloads (Global Singletons)")
    lines.append("")
    lines.append("| Autoload | File | Purpose |")
    lines.append("|:---|:---|:---|")
    for name, rel_path, desc in AUTOLOADS:
        lines.append(f"| `{name}` | [{rel_path}](file:///{PROJECT_ROOT.replace('\\', '/')}/{rel_path}) | {desc} |")
    lines.append("")

    lines.append("## 2. Simulation Modules (Pure Logic)")
    lines.append("")
    lines.append("| File | Purpose |")
    lines.append("|:---|:---|")
    for rel_path, desc in SIMULATION_MODULES:
        lines.append(f"| [{rel_path}](file:///{PROJECT_ROOT.replace('\\', '/')}/{rel_path}) | {desc} |")
    lines.append("")

    lines.append("## 3. Tooling Scripts")
    lines.append("")
    lines.append("| Script | Purpose | Usage |")
    lines.append("|:---|:---|:---|")
    for rel_path, desc, usage in PYTHON_SCRIPTS:
        lines.append(f"| [{rel_path}](file:///{PROJECT_ROOT.replace('\\', '/')}/{rel_path}) | {desc} | `{usage}` |")
    lines.append("")

    lines.append("## 4. Test Suite")
    lines.append("")
    lines.append("| Test File | Suite Name | Link |")
    lines.append("|:---|:---|:---|")
    for fname, rel_path, suite in scan_tests():
        lines.append(f"| `{fname}` | `{suite}` | [{rel_path}](file:///{PROJECT_ROOT.replace('\\', '/')}/{rel_path}) |")
    lines.append("")

    lines.append("## 5. Quick Reference: Where Do I Find...?")
    lines.append("")
    lines.append("| I need to... | Look in... |")
    lines.append("|:---|:---|")
    lines.append("| Change energy math or routing | `simulation/energy_routing.gd`, `scenes/energy/energy_router.gd` |")
    lines.append("| Add a new ball ability | `resources/balls/ball_definition.gd`, `scenes/balls/ball.gd`, `scenes/board/board.gd` |")
    lines.append("| Add a new peg type | `scenes/board/peg.gd`, `autoloads/constants.gd` |")
    lines.append("| Add a new relic | `resources/polyomino/polyomino_relic_database.gd`, `resources/polyomino/polyomino_module_data.gd` |")
    lines.append("| Add a machinery device | `scenes/board/machinery/` (extend `polyomino_machinery_component.gd`) |")
    lines.append("| Change wall HP or timer | `scenes/main/combat_manager.gd`, `resources/cities/city_definition.gd` |")
    lines.append("| Add a new reward type | `scenes/rewards/reward_handler.gd`, `scenes/rewards/reward_draft_panel.gd` |")
    lines.append("| Add a new board event | `scenes/board/` (extend `base_board_event_controller.gd`) |")
    lines.append("| Change milestone thresholds | `simulation/milestone_curve.gd`, `resources/milestones/milestone_definition.gd` |")
    lines.append("| Add a new sidearm | `scenes/systems/sidearms/` (extend `sidearm_base.gd`) |")
    lines.append("| Change hopper or conduit | `scenes/hopper/hopper.gd`, `scenes/conduit/conduit.gd` |")
    lines.append("| Add a new test | `tests/test_<system>.gd` |")
    lines.append("| Add a debug tool | `scenes/main/game_coordinator.gd`, `scenes/ui/debug_*.gd` |")
    lines.append("| Change color palette | `autoloads/constants.gd`, `autoloads/monster_palette.gd` |")
    lines.append("| Change conquest/campaign flow | `scenes/main/game_coordinator.gd`, `scenes/main/combat_manager.gd` |")
    lines.append("| Change junk box / inventory | `resources/inventory/junk_box_data.gd`, `scenes/ui/junk_box/` |")
    lines.append("")

    return "\n".join(lines)


def main():
    os.makedirs(os.path.dirname(DIRECTORY_MD_PATH), exist_ok=True)
    content = generate_directory_markdown()
    with open(DIRECTORY_MD_PATH, "w", encoding="utf-8") as f:
        f.write(content + "\n")
    print(f"Successfully generated {DIRECTORY_MD_PATH}")


if __name__ == "__main__":
    main()
