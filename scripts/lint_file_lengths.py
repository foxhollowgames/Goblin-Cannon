import os
import sys
import json
from argparse import ArgumentParser

def is_binary_file(file_path: str) -> bool:
    """Check if a file is binary."""
    try:
        with open(file_path, "rb") as f:
            return b"\0" in f.read(1024)
    except Exception:
        return True

def normalize_path(root_dir: str, file_path: str) -> str:
    """Normalize path to forward slashes relative to root_dir."""
    return os.path.relpath(file_path, root_dir).replace(os.sep, "/")

BASELINE_LIMITS = {
    "scenes/board/board.gd": 3237,
    "scenes/main/game_coordinator.gd": 1531,
    "scenes/board/peg.gd": 1180,
    "scenes/rewards/reward_draft_panel.gd": 886,
    "scenes/rewards/reward_handler.gd": 729,
    "resources/polyomino/polyomino_relic_database.gd": 654,
    "autoloads/constants.gd": 575,
    "scenes/ui/debug_full_store_modal.gd": 546,
    "orchestration/client/main.ts": 1086,
    "orchestration/client/style.css": 672,
    "orchestration/src/server/index.ts": 663,
    "orchestration/src/lib/task-merge.ts": 515,
    "docs/ARCHITECTURE.md": 558,
    "docs/knowledge/LEARNINGS.md": 1150,
    "scenes/main/main.tscn": 508,
}

IGNORE_DIRS = {
    ".git",
    ".godot",
    "assets",
    "addons",
    "node_modules",
    "dist",
    "exports",
    "goblin-cannon-agent-task",
}

IGNORE_FILES = {
    "package-lock.json",
}

SOURCE_EXTENSIONS = (
    ".gd",
    ".py",
    ".ts",
    ".js",
    ".css",
    ".html",
    ".tscn",
    ".tres",
    ".md",
    ".json",
    ".sh",
    ".ps1",
)

def audit_files(root_dir: str, max_lines: int, baseline: dict, gd_only: bool, strict: bool):
    """Audit source files for line count violations."""
    issues = []
    checked_files = 0
    baseline_files = 0

    for dirpath, dirs, filenames in os.walk(root_dir):
        # Skip ignored directories in place
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not any(ign in d for ign in ["node_modules", "goblin-cannon-agent-task"])]

        for filename in filenames:
            if filename in IGNORE_FILES or filename.startswith("."):
                continue

            file_path = os.path.join(dirpath, filename)
            normalized_path = normalize_path(root_dir, file_path)

            if gd_only and not filename.endswith(".gd"):
                continue
            if not gd_only and not any(filename.endswith(ext) for ext in SOURCE_EXTENSIONS):
                continue
            if is_binary_file(file_path):
                continue

            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    line_count = sum(1 for _ in f)
            except Exception:
                continue

            allowed_max_lines = max_lines if (strict or normalized_path not in baseline) else baseline[normalized_path]
            checked_files += 1

            if normalized_path in baseline:
                baseline_files += 1

            if line_count > allowed_max_lines:
                issues.append((normalized_path, line_count, allowed_max_lines))

    return issues, checked_files, baseline_files

def main():
    parser = ArgumentParser(description="Audit source code file line counts against a 500-line limit.")
    parser.add_argument("--max-lines", type=int, default=500, help="Default maximum line limit (default: 500)")
    parser.add_argument("--strict", action="store_true", help="Disallow baseline exceptions and enforce max limit on all files")
    parser.add_argument("--gd-only", action="store_true", help="Only audit GDScript (.gd) source files")
    parser.add_argument("--path", type=str, default=".", help="Root directory to audit")
    parser.add_argument("--json", action="store_true", help="Output audit results as JSON")
    args = parser.parse_args()

    issues, checked_files, baseline_files = audit_files(
        args.path,
        args.max_lines,
        BASELINE_LIMITS,
        args.gd_only,
        args.strict,
    )

    if args.json:
        print(json.dumps({
            "checked_files": checked_files,
            "baseline_files": baseline_files,
            "issues_count": len(issues),
            "issues": [
                {"file": path, "lines": count, "allowed": allowed}
                for path, count, allowed in issues
            ]
        }, indent=2))
    else:
        print("==================================================")
        print("         PROJECT FILE LENGTH LINT AUDIT           ")
        print("==================================================")
        if issues:
            print("\nViolations Found:")
            for issue in issues:
                print(f"  [FAIL] {issue[0]}: {issue[1]} lines (limit: {issue[2]})")
        else:
            print("\nAll files comply with line limits!")

        print("\nSummary:")
        print(f"  Checked Files:  {checked_files}")
        print(f"  Baseline Files: {baseline_files}")
        print(f"  Violations:     {len(issues)}")
        print("==================================================")

    if issues:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()

