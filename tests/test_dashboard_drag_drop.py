#!/usr/bin/env python3
"""
Unit tests for visual task dashboard drag-and-drop and task status updater server.
"""

import os
import re
import json
import threading
import http.client
import time
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(REPO_ROOT, "scripts"))
import task_server


def test_dashboard_html_drag_drop_elements():
    dash_path = os.path.join(REPO_ROOT, "docs", "tasks", "dashboard.html")
    assert os.path.exists(dash_path), "dashboard.html does not exist"
    with open(dash_path, "r", encoding="utf-8") as f:
        html = f.read()

    # Check required drag-and-drop functions
    required_js_fns = [
        "handleDragStart", "handleDragEnd", "handleDragOver",
        "handleDragLeave", "handleDrop", "changeTaskStatus",
        "showToast", "updateTopMetrics"
    ]
    for fn in required_js_fns:
        assert fn in html, f"Missing JS function: {fn}"

    # Check card draggable attribute
    assert 'draggable="true"' in html, "Cards are missing draggable attribute"
    assert "handleDragStart(event" in html, "Cards missing handleDragStart"
    assert "handleDragEnd(event" in html, "Cards missing handleDragEnd"

    # Check column drop targets
    assert "handleDrop(event, 'BACKLOG')" in html, "Missing Backlog drop handler"
    assert "handleDrop(event, 'READY')" in html, "Missing Ready drop handler"
    assert "handleDrop(event, 'IN_PROGRESS')" in html, "Missing In Progress drop handler"
    assert "handleDrop(event, 'DONE')" in html, "Missing Done drop handler"

    # Check toast container
    assert 'id="toast-container"' in html, "Missing toast-container element"

    print("PASS: test_dashboard_html_drag_drop_elements")


def test_update_task_status_file_modification():
    task_id = "TASK-061"
    task_file = os.path.join(REPO_ROOT, "docs", "tasks", "TASK-061-dashboard-drag-drop-task-status.md")
    readme_file = os.path.join(REPO_ROOT, "docs", "tasks", "README.md")
    assert os.path.exists(task_file), f"{task_file} does not exist"

    # 1. Update to READY
    res1 = task_server.update_task_status(task_id, "READY")
    assert res1.get("success") is True, f"Failed to update to READY: {res1}"

    with open(task_file, "r", encoding="utf-8") as f:
        tf_content = f.read()
    assert "- **Status:** READY" in tf_content, f"Expected READY in {task_file}"

    with open(readme_file, "r", encoding="utf-8") as f:
        rm_content = f.read()
    assert re.search(r'\[TASK-061\].*?\|\s*READY\s*\|', rm_content), "README row missing READY status"

    # 2. Update to IN_PROGRESS
    res2 = task_server.update_task_status(task_id, "IN_PROGRESS")
    assert res2.get("success") is True, f"Failed to update to IN_PROGRESS: {res2}"

    with open(task_file, "r", encoding="utf-8") as f:
        tf_content2 = f.read()
    assert "- **Status:** IN_PROGRESS" in tf_content2, f"Expected IN_PROGRESS in {task_file}"

    # 3. Test invalid status rejected
    res_bad = task_server.update_task_status(task_id, "INVALID_STATUS")
    assert res_bad.get("success") is False, "Invalid status should fail"

    print("PASS: test_update_task_status_file_modification")


def test_task_server_http_endpoints():
    test_port = 8789
    server = http.server.HTTPServer(("127.0.0.1", test_port), task_server.TaskRequestHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(0.3)

    try:
        # Test 1: GET /api/health
        conn = http.client.HTTPConnection("127.0.0.1", test_port, timeout=5)
        conn.request("GET", "/api/health")
        resp = conn.getresponse()
        assert resp.status == 200, f"Health check failed with {resp.status}"
        assert resp.getheader("Access-Control-Allow-Origin") == "*", "Missing CORS origin header"
        health_data = json.loads(resp.read().decode("utf-8"))
        assert health_data.get("status") == "ok", "Health status not ok"

        # Test 2: OPTIONS preflight
        conn.request("OPTIONS", "/api/task/update")
        resp_opt = conn.getresponse()
        assert resp_opt.status == 204, f"OPTIONS failed with {resp_opt.status}"
        assert resp_opt.getheader("Access-Control-Allow-Methods") is not None, "Missing CORS methods"

        # Test 3: POST /api/task/update
        payload = json.dumps({"id": "TASK-061", "status": "READY"}).encode("utf-8")
        headers = {"Content-Type": "application/json", "Content-Length": str(len(payload))}
        conn.request("POST", "/api/task/update", body=payload, headers=headers)
        resp_post = conn.getresponse()
        assert resp_post.status == 200, f"POST /api/task/update failed with {resp_post.status}"
        post_data = json.loads(resp_post.read().decode("utf-8"))
        assert post_data.get("success") is True, f"Update failed: {post_data}"
        assert post_data.get("status") == "READY"

        # Revert back to IN_PROGRESS
        payload_rev = json.dumps({"id": "TASK-061", "status": "IN_PROGRESS"}).encode("utf-8")
        conn.request("POST", "/api/task/update", body=payload_rev, headers={"Content-Type": "application/json", "Content-Length": str(len(payload_rev))})
        resp_rev = conn.getresponse()
        assert resp_rev.status == 200

        conn.close()
        print("PASS: test_task_server_http_endpoints")
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    test_dashboard_html_drag_drop_elements()
    test_update_task_status_file_modification()
    test_task_server_http_endpoints()
    print("ALL TESTS PASSED SUCCESSFULLY!")
