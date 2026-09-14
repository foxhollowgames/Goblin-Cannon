#!/usr/bin/env python3
"""
Automated Task Packet Creator for Goblin Cannon.

Creates a standardized task packet in docs/tasks/TASK-XXX-<slug>.md,
registers it in docs/tasks/README.md, and regenerates docs/tasks/dashboard.html.
"""

import argparse
import os
import re
import subprocess
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TASKS_DIR = os.path.join(PROJECT_ROOT, "docs", "tasks")
README_PATH = os.path.join(TASKS_DIR, "README.md")
DASHBOARD_SCRIPT = os.path.join(PROJECT_ROOT, "scripts", "generate_task_dashboard.py")


def find_next_task_id(tasks_dir: str = TASKS_DIR) -> int:
    """Scan docs/tasks/ to determine the next sequential TASK ID."""
    max_id = 0
    if not os.path.exists(tasks_dir):
        return 1

    pattern = re.compile(r"^TASK-(\d+)", re.IGNORECASE)
    for fname in os.listdir(tasks_dir):
        match = pattern.match(fname)
        if match:
            num = int(match.group(1))
            if num > max_id:
                max_id = num
    return max_id + 1


def slugify(text: str) -> str:
    """Convert text into a kebab-case filesystem slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    slug = text.strip("-")
    return slug[:50].rstrip("-")


def build_task_markdown(
    task_id: int,
    title: str,
    category: str,
    priority: str,
    status: str,
    branch: str,
) -> str:
    """Generate canonical task packet content."""
    formatted_id = f"TASK-{task_id:03d}"
    return f"""# {formatted_id}: {title}

- **Status:** {status}
- **Priority:** {priority}
- **Category:** {category}
- **Target Branch:** `{branch}`
- **Related Tasks:** 

## Description

{title}

---

## Requirements

### 1. Scope and Implementation
- Implement specifications for {title}.

---

## Acceptance Criteria

- [ ] Requirements implemented and verified.
- [ ] Tests pass cleanly.
- [ ] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.
"""


def register_in_readme(
    task_id: int,
    title: str,
    category: str,
    priority: str,
    status: str,
    branch: str,
    filename: str,
    readme_path: str = README_PATH,
) -> bool:
    """Append the new task row to the master index table in docs/tasks/README.md."""
    if not os.path.exists(readme_path):
        return False

    with open(readme_path, "r", encoding="utf-8") as f:
        content = f.read()

    formatted_id = f"TASK-{task_id:03d}"
    new_row = f"| [{formatted_id}]({filename}) | {title} | {category} | {priority} | {status} | `{branch}` |"

    # Match the last table row before the dividing rule
    table_split = re.split(r"(\n---|\n## 3\.)", content, maxsplit=1)
    if len(table_split) >= 2:
        prefix = table_split[0].rstrip()
        suffix = table_split[1] + "".join(table_split[2:])
        updated = f"{prefix}\n{new_row}\n\n{suffix.lstrip()}"
    else:
        updated = f"{content.rstrip()}\n{new_row}\n"

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(updated)
    return True


def regenerate_dashboard(script_path: str = DASHBOARD_SCRIPT) -> int:
    """Run generate_task_dashboard.py to update docs/tasks/dashboard.html."""
    if not os.path.exists(script_path):
        return 1
    res = subprocess.run([sys.executable, script_path], capture_output=True, text=True)
    if res.returncode == 0:
        print("Successfully regenerated docs/tasks/dashboard.html", flush=True)
    else:
        print(f"Error regenerating dashboard:\n{res.stderr}", flush=True)
    return res.returncode


def create_task(
    title: str,
    category: str = "Systems / Gameplay",
    priority: str = "P1",
    status: str = "READY",
    branch: str = "",
    tasks_dir: str = TASKS_DIR,
    readme_path: str = README_PATH,
    skip_dashboard: bool = False,
) -> str:
    """Execute complete automated task creation pipeline."""
    task_id = find_next_task_id(tasks_dir)
    formatted_id = f"TASK-{task_id:03d}"
    slug = slugify(title)
    filename = f"{formatted_id}-{slug}.md"
    filepath = os.path.join(tasks_dir, filename)

    if not branch:
        prefix = "fix" if title.lower().startswith("fix") else "feature"
        branch = f"{prefix}/{slug}"

    content = build_task_markdown(task_id, title, category, priority, status, branch)
    os.makedirs(tasks_dir, exist_ok=True)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"Created task packet: {filepath}", flush=True)

    register_in_readme(
        task_id=task_id,
        title=title,
        category=category,
        priority=priority,
        status=status,
        branch=branch,
        filename=filename,
        readme_path=readme_path,
    )
    print(f"Registered {formatted_id} in {readme_path}", flush=True)

    if not skip_dashboard:
        regenerate_dashboard()

    return filepath


def main():
    parser = argparse.ArgumentParser(description="Create a canonical Goblin Cannon task packet.")
    parser.add_argument("title", help="Title of the task")
    parser.add_argument("--category", default="Systems / Gameplay", help="Task category")
    parser.add_argument("--priority", default="P1", choices=["P0", "P1", "P2", "P3"], help="Priority")
    parser.add_argument(
        "--status",
        default="READY",
        choices=["PARKED", "BACKLOG", "READY", "IN_PROGRESS", "IN_REVIEW", "DONE"],
        help="Initial workflow status",
    )
    parser.add_argument("--branch", default="", help="Target Git branch name")
    parser.add_argument("--skip-dashboard", action="store_true", help="Skip dashboard regeneration")

    args = parser.parse_args()
    create_task(
        title=args.title,
        category=args.category,
        priority=args.priority,
        status=args.status,
        branch=args.branch,
        skip_dashboard=args.skip_dashboard,
    )


if __name__ == "__main__":
    main()
