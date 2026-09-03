import os
import re
import json

def test_dashboard_modal():
    dashboard_path = os.path.join("docs", "tasks", "dashboard.html")
    assert os.path.exists(dashboard_path), "dashboard.html does not exist"

    with open(dashboard_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    assert len(lines) <= 500, f"dashboard.html line count {len(lines)} exceeds 500"

    generator_path = os.path.join("scripts", "generate_task_dashboard.py")
    with open(generator_path, "r", encoding="utf-8") as f:
        gen_lines = f.readlines()
    assert len(gen_lines) <= 500, f"generator line count {len(gen_lines)} exceeds 500"

    required_ids = [
        "task-modal-backdrop", "task-modal-card", "modal-id", "modal-title",
        "modal-prio", "modal-status", "modal-cat", "modal-domain", "modal-branch",
        "modal-mtime", "modal-file-link", "modal-body", "modal-btn-prev",
        "modal-btn-next", "modal-nav-idx", "btn-copy-branch"
    ]
    for req_id in required_ids:
        assert f'id="{req_id}"' in content, f"Missing required ID: {req_id}"

    required_fns = [
        "openTaskModal", "closeTaskModal", "formatMarkdown", "updateModalNav",
        "navTaskModal", "copyBranch"
    ]
    for req_fn in required_fns:
        assert req_fn in content, f"Missing required JS function: {req_fn}"

    assert "openTaskModal(" in content, "openTaskModal not called on elements"
    assert "Escape" in content, "Escape key handler missing"
    assert "ArrowLeft" in content and "ArrowRight" in content, "Arrow navigation missing"

    match = re.search(r"const ALL_TASKS = (\[.*?\]);", content, re.DOTALL)
    assert match, "ALL_TASKS JSON not found"
    tasks = json.loads(match.group(1))
    assert len(tasks) >= 50, f"Expected at least 50 tasks, got {len(tasks)}"

    t56 = next((t for t in tasks if t["id"] == "TASK-056"), None)
    assert t56 is not None, "TASK-056 not found in ALL_TASKS"
    assert "Expandable Task Details Modal" in t56["title"], "TASK-056 title mismatch"
    assert t56["body"], "TASK-056 body is empty"
    assert "Acceptance Criteria" in t56["body"], "TASK-056 body missing Acceptance Criteria"

    print(f"PASS: Dashboard modal verified successfully across {len(tasks)} tasks.")
    print(f"Line counts: generator={len(gen_lines)}, dashboard={len(lines)}")

if __name__ == "__main__":
    test_dashboard_modal()
