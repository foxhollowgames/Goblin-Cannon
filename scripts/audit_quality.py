#!/usr/bin/env python3
"""
Comprehensive Code Quality and Verification Auditor for Goblin Cannon.

Executes all pre-PR verification steps in a single automated command:
1. Codebase directory generation (scripts/generate_directory.py)
2. GDScript quality linting (scripts/lint_gdscript.py)
3. 500-line maximum file length audit (scripts/lint_file_lengths.py)
4. Headless Godot unit test suite execution (tests/run_tests.gd)
"""

import argparse
import os
import subprocess
import sys
import time

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

GODOT_CANDIDATES = [
    r"C:\Users\josep\Desktop\Games\Godot_v4.6.1-stable_win64.exe",
    r"C:\Users\josep\Desktop\Coding Projects\Godot_v4.6.2-stable_win64.exe",
]


def resolve_godot_path() -> str:
    """Find the valid Godot executable on the local system."""
    for path in GODOT_CANDIDATES:
        if os.path.exists(path):
            return path

    # Check if godot is in PATH
    try:
        res = subprocess.run(["where.exe" if os.name == "nt" else "which", "godot"], capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip().splitlines()[0]
    except Exception:
        pass

    return "godot"


def run_step(name: str, cmd: list, timeout: int = 60) -> tuple[bool, str, float]:
    """Execute a verification command and measure elapsed time."""
    print(f"\n[AUDIT] Step: {name}...", flush=True)
    t0 = time.time()
    try:
        res = subprocess.run(
            cmd,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        elapsed = time.time() - t0
        output = (res.stdout + "\n" + res.stderr).strip()
        passed = (res.returncode == 0)
        return passed, output, elapsed
    except subprocess.TimeoutExpired:
        elapsed = time.time() - t0
        return False, f"Timed out after {timeout} seconds.", elapsed
    except Exception as e:
        elapsed = time.time() - t0
        return False, str(e), elapsed


def audit_quality(skip_tests: bool = False, skip_directory: bool = False) -> int:
    """Run all verification passes and print a unified report."""
    results = []

    # Step 1: AI Codebase Directory Generation
    if not skip_directory:
        script = os.path.join(PROJECT_ROOT, "scripts", "generate_directory.py")
        passed, out, elapsed = run_step(
            "1. Codebase Directory Sync (generate_directory.py)",
            [sys.executable, script],
            timeout=30,
        )
        results.append(("Directory Sync", passed, out, elapsed))
        status_str = "PASS" if passed else "FAIL"
        print(f"  [{status_str}] Completed in {elapsed:.2f}s", flush=True)
        if not passed:
            print(f"  Output:\n{out}", flush=True)

    # Step 2: GDScript Multi-Pass Linter
    script = os.path.join(PROJECT_ROOT, "scripts", "lint_gdscript.py")
    passed, out, elapsed = run_step(
        "2. GDScript Linter (lint_gdscript.py)",
        [sys.executable, script],
        timeout=60,
    )
    results.append(("GDScript Lint", passed, out, elapsed))
    status_str = "PASS" if passed else "FAIL"
    print(f"  [{status_str}] Completed in {elapsed:.2f}s", flush=True)
    if not passed:
        print(f"  Output:\n{out}", flush=True)

    # Step 3: File Length Audit (500-line limit)
    script = os.path.join(PROJECT_ROOT, "scripts", "lint_file_lengths.py")
    passed, out, elapsed = run_step(
        "3. File Length Audit (lint_file_lengths.py)",
        [sys.executable, script],
        timeout=30,
    )
    results.append(("File Lengths", passed, out, elapsed))
    status_str = "PASS" if passed else "FAIL"
    print(f"  [{status_str}] Completed in {elapsed:.2f}s", flush=True)
    if not passed:
        print(f"  Output:\n{out}", flush=True)

    # Step 4: Headless Godot Test Suite
    if not skip_tests:
        godot_bin = resolve_godot_path()
        if os.name == "nt":
            test_cmd = f'cmd.exe /c ""{godot_bin}" --headless -s tests/run_tests.gd"'
            use_shell = True
        else:
            test_cmd = [godot_bin, "--headless", "-s", "tests/run_tests.gd"]
            use_shell = False

        print(f"\n[AUDIT] Step: 4. Headless Godot Tests ({os.path.basename(godot_bin)})...", flush=True)
        t0 = time.time()
        try:
            res = subprocess.run(
                test_cmd,
                cwd=PROJECT_ROOT,
                capture_output=True,
                text=True,
                shell=use_shell,
                timeout=120,
            )
            elapsed = time.time() - t0
            out = (res.stdout + "\n" + res.stderr).strip()
            passed = (res.returncode == 0)
            if "SCRIPT ERROR" in out:
                passed = False
            elif "0 failed" in out:
                passed = True
        except subprocess.TimeoutExpired:
            elapsed = time.time() - t0
            passed = False
            out = "Timed out after 120 seconds."
        except Exception as e:
            elapsed = time.time() - t0
            passed = False
            out = str(e)

        results.append(("Godot Tests", passed, out, elapsed))
        status_str = "PASS" if passed else "FAIL"
        print(f"  [{status_str}] Completed in {elapsed:.2f}s", flush=True)
        if not passed:
            print(f"  Output:\n{out}", flush=True)


    # Consolidated Report
    print("\n" + "=" * 50, flush=True)
    print("           AUDIT QUALITY REPORT", flush=True)
    print("=" * 50, flush=True)
    all_passed = True
    for name, passed, _, elapsed in results:
        status_badge = "[PASS]" if passed else "[FAIL]"
        print(f"  {status_badge} {name:<25} ({elapsed:.2f}s)", flush=True)
        if not passed:
            all_passed = False
    print("=" * 50, flush=True)

    if all_passed:
        print(">> ALL AUDIT PASSES SUCCEEDED. Ready for Pull Request. <<\n", flush=True)
        return 0
    else:
        print(">> AUDIT FAILED. Resolve the issues before opening a PR. <<\n", flush=True)
        return 1


def main():
    parser = argparse.ArgumentParser(description="Run complete Goblin Cannon quality audit suite.")
    parser.add_argument("--skip-tests", action="store_true", help="Skip headless Godot test suite")
    parser.add_argument("--skip-directory", action="store_true", help="Skip directory regeneration")
    args = parser.parse_args()

    exit_code = audit_quality(
        skip_tests=args.skip_tests,
        skip_directory=args.skip_directory,
    )
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
