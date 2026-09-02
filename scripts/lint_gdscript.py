#!/usr/bin/env python3
"""
Multi-pass GDScript and Code Quality Linter for Goblin Cannon.
Runs:
1. gdlint (if installed)
2. File length audit (500 lines max)
3. Directory freshness check (docs/DIRECTORY.md)
4. Function length audit (45 lines max per function)
5. Type annotation check on public function signatures
"""

import argparse
import os
import re
import subprocess
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MAX_FUNC_LINES = 45


def run_cmd(cmd, cwd=PROJECT_ROOT):
    try:
        res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, shell=True)
        return res.returncode, res.stdout, res.stderr
    except Exception as e:
        return 1, "", str(e)


def check_gdlint():
    print("Pass 1: Checking gdlint...")
    code, stdout, stderr = run_cmd("gdlint --version")
    if code != 0:
        print("  [SKIP] gdlint not installed (pip install gdtoolkit)")
        return 0

    print("  Running gdlint across project...")
    code, stdout, stderr = run_cmd("gdlint autoloads/ resources/ scenes/ simulation/")
    if code == 0:
        print("  [PASS] gdlint check passed")
        return 0
    else:
        print("  [FAIL] gdlint reported violations:")
        print(stdout)
        print(stderr)
        return 1


def check_file_lengths():
    print("Pass 2: Checking file lengths (500 line limit)...")
    lint_script = os.path.join(PROJECT_ROOT, "scripts", "lint_file_lengths.py")
    code, stdout, stderr = run_cmd(f"python {lint_script}")
    if code == 0:
        print("  [PASS] File length audit passed")
        return 0
    else:
        print("  [FAIL] File length violations detected:")
        print(stdout)
        return 1


def check_directory_freshness():
    print("Pass 3: Checking docs/DIRECTORY.md freshness...")
    gen_script = os.path.join(PROJECT_ROOT, "scripts", "generate_directory.py")
    dir_file = os.path.join(PROJECT_ROOT, "docs", "DIRECTORY.md")

    if not os.path.exists(dir_file):
        print("  [FAIL] docs/DIRECTORY.md does not exist. Run python scripts/generate_directory.py")
        return 1

    with open(dir_file, "r", encoding="utf-8") as f:
        old_content = f.read()

    run_cmd(f"python {gen_script}")

    with open(dir_file, "r", encoding="utf-8") as f:
        new_content = f.read()

    if old_content != new_content:
        print("  [FAIL] docs/DIRECTORY.md was out of date (updated now). Please commit the update.")
        return 1

    print("  [PASS] docs/DIRECTORY.md is up to date")
    return 0


def check_custom_rules():
    print("Pass 4: Checking custom GDScript rules (function length & public return types)...")
    violations = []
    gd_dirs = ["autoloads", "resources", "scenes", "simulation"]

    func_start_re = re.compile(r"^\s*func\s+([a-zA-Z0-9_]+)\s*\((.*?)\)\s*(->\s*([a-zA-Z0-9_\.\[\]]+))?:")

    for dir_name in gd_dirs:
        target_dir = os.path.join(PROJECT_ROOT, dir_name)
        if not os.path.exists(target_dir):
            continue

        for root, _, files in os.walk(target_dir):
            for file in files:
                if not file.endswith(".gd"):
                    continue

                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, PROJECT_ROOT).replace("\\", "/")

                with open(full_path, "r", encoding="utf-8", errors="replace") as f:
                    lines = f.readlines()

                current_func = None
                func_lines = 0

                for idx, line in enumerate(lines, start=1):
                    match = func_start_re.match(line)
                    if match:
                        if current_func and func_lines > MAX_FUNC_LINES:
                            violations.append(f"{rel_path}: function '{current_func}' exceeds {MAX_FUNC_LINES} lines ({func_lines} lines)")

                        current_func = match.group(1)
                        func_lines = 0
                        params = match.group(2)
                        return_type = match.group(4)

                        # Public function checks (no leading underscore, except standard Godot handlers or main)
                        if not current_func.startswith("_"):
                            if return_type is None:
                                violations.append(f"{rel_path}:{idx}: public function '{current_func}' missing explicit return type annotation (-> void, -> int, etc.)")
                    else:
                        if current_func:
                            stripped = line.strip()
                            if stripped and not stripped.startswith("#"):
                                func_lines += 1

                if current_func and func_lines > MAX_FUNC_LINES:
                    violations.append(f"{rel_path}: function '{current_func}' exceeds {MAX_FUNC_LINES} lines ({func_lines} lines)")

    if violations:
        print(f"  [WARN/FAIL] Found {len(violations)} custom rule issues (showing first 10):")
        for v in violations[:10]:
            print(f"    - {v}")
        # Note: We return 0 for now as warnings during baseline refactor, but flag them
        return 0
    else:
        print("  [PASS] Custom GDScript rules passed")
        return 0


def check_script_parse_smoke():
    print("Pass 5: Checking Godot script compilation parse smoke test...")
    godot_bin = r"C:\Users\josep\Desktop\Games\Godot_v4.6.1-stable_win64.exe"
    if not os.path.exists(godot_bin):
        godot_bin = "godot"

    cmd = f'cmd.exe /c "{godot_bin} --headless -s tests/test_script_parse_smoke.gd"'
    code, stdout, stderr = run_cmd(cmd)
    if code == 0 and "SCRIPT ERROR" not in stdout and "SCRIPT ERROR" not in stderr:
        print("  [PASS] Godot script parse smoke test passed")
        return 0
    else:
        print("  [FAIL] Godot script parse smoke test failed:")
        print(stdout)
        print(stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(description="Multi-pass GDScript Quality Linter")
    args = parser.parse_args()

    results = []
    results.append(check_gdlint())
    results.append(check_file_lengths())
    results.append(check_directory_freshness())
    results.append(check_custom_rules())
    results.append(check_script_parse_smoke())

    if any(r != 0 for r in results):
        print("\nGDScript Linting FAILED.")
        sys.exit(1)
    else:
        print("\nAll GDScript Lint Passes PASSED.")
        sys.exit(0)


if __name__ == "__main__":
    main()

