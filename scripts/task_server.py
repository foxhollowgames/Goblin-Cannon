#!/usr/bin/env python3
"""
Task Management Local Server and Updater for Goblin Cannon.
Provides a local HTTP API to update task status from docs/tasks/dashboard.html,
and updates both TASK-*.md and docs/tasks/README.md files.
"""

import argparse
import http.server
import json
import os
import re
import sys
import urllib.parse
import webbrowser

VALID_STATUSES = ["BACKLOG", "READY", "IN_PROGRESS", "IN_REVIEW", "DONE"]


def get_repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def update_task_status(task_id: str, new_status: str, repo_root: str = None) -> dict:
    if repo_root is None:
        repo_root = get_repo_root()

    clean_status = new_status.strip().upper()
    if clean_status not in VALID_STATUSES:
        return {"success": False, "error": f"Invalid status: {new_status}. Allowed: {VALID_STATUSES}"}

    task_dir = os.path.join(repo_root, "docs", "tasks")
    readme_path = os.path.join(task_dir, "README.md")
    if not os.path.exists(readme_path):
        return {"success": False, "error": f"README not found: {readme_path}"}

    # 1. Update task markdown file
    target_file = None
    file_name = None
    for fname in os.listdir(task_dir):
        if fname.startswith(task_id) and fname.endswith(".md") and fname != "README.md":
            target_file = os.path.join(task_dir, fname)
            file_name = fname
            break

    if target_file and os.path.exists(target_file):
        with open(target_file, "r", encoding="utf-8") as f:
            content = f.read()

        updated_content = re.sub(
            r'(-\s*\*\*Status:\*\*\s*)([^\n]+)',
            rf'\g<1>{clean_status}',
            content,
            count=1,
            flags=re.IGNORECASE
        )
        with open(target_file, "w", encoding="utf-8") as f:
            f.write(updated_content)

    # 2. Update README.md master task index
    with open(readme_path, "r", encoding="utf-8") as f:
        readme_content = f.read()

    pattern = re.compile(
        r'(\|\s*\[' + re.escape(task_id) + r'\]\([^)]+\)\s*\|[^|]+\|[^|]+\|[^|]+\|)\s*([^|]+)\s*(\|)',
        re.IGNORECASE
    )

    if not pattern.search(readme_content):
        return {"success": False, "error": f"Task {task_id} not found in {readme_path}"}

    updated_readme = pattern.sub(rf'\g<1> {clean_status} \g<3>', readme_content, count=1)
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(updated_readme)

    # 3. Regenerate dashboard
    try:
        sys.path.insert(0, os.path.dirname(__file__))
        import generate_task_dashboard
        tasks = generate_task_dashboard.parse_tasks(repo_root)
        html_content = generate_task_dashboard.build_html(tasks)
        out_file = os.path.join(task_dir, "dashboard.html")
        with open(out_file, "w", encoding="utf-8") as f:
            f.write(html_content)
    except Exception as e:
        print(f"Warning: Failed to regenerate dashboard.html: {e}")

    return {
        "success": True,
        "id": task_id,
        "status": clean_status,
        "file": file_name
    }


class TaskRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        repo_root = get_repo_root()
        super().__init__(*args, directory=repo_root, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "service": "goblin-task-server"}).encode("utf-8"))
            return
        if parsed.path in ["", "/", "/dashboard"]:
            self.send_response(302)
            self.send_header("Location", "/docs/tasks/dashboard.html")
            self.end_headers()
            return
        super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/task/update":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length).decode("utf-8")
            try:
                data = json.loads(body)
            except Exception:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "error": "Invalid JSON"}).encode("utf-8"))
                return

            task_id = data.get("id", "").strip().upper()
            status = data.get("status", "").strip().upper()
            if not task_id or not status:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "error": "Missing 'id' or 'status'"}).encode("utf-8"))
                return

            result = update_task_status(task_id, status)
            status_code = 200 if result.get("success") else 400
            self.send_response(status_code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(result).encode("utf-8"))
            return

        self.send_response(404)
        self.end_headers()


def run_server(port: int = 8765, open_browser: bool = False):
    server_address = ("127.0.0.1", port)
    httpd = http.server.HTTPServer(server_address, TaskRequestHandler)
    url = f"http://127.0.0.1:{port}/docs/tasks/dashboard.html"
    print(f"Goblin Cannon Task Server running on {url}")
    print("Press Ctrl+C to stop.")
    if open_browser:
        webbrowser.open(url)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping task server.")
        httpd.server_close()


def main():
    parser = argparse.ArgumentParser(description="Goblin Cannon Task Server and Updater")
    subparsers = parser.add_subparsers(dest="command")

    # update command
    update_cmd = subparsers.add_parser("update", help="Update task status directly")
    update_cmd.add_argument("task_id", help="Task ID (e.g. TASK-001)")
    update_cmd.add_argument("status", choices=VALID_STATUSES, help="New status")

    # serve command
    serve_cmd = subparsers.add_parser("serve", help="Start local HTTP task server")
    serve_cmd.add_argument("--port", type=int, default=8765, help="Port to listen on (default: 8765)")
    serve_cmd.add_argument("--open", action="store_true", help="Open browser automatically")

    args = parser.parse_args()

    if args.command == "update":
        res = update_task_status(args.task_id, args.status)
        if res.get("success"):
            print(f"Successfully updated {args.task_id} to {args.status}.")
            sys.exit(0)
        else:
            print(f"Error: {res.get('error')}")
            sys.exit(1)
    else:
        port = getattr(args, "port", 8765)
        open_b = getattr(args, "open", False)
        run_server(port=port, open_browser=open_b)


if __name__ == "__main__":
    main()
