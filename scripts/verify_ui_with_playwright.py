import os
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

def run_playwright_verification() -> None:
    html_path = Path("docs/tasks/dashboard.html").resolve()
    artifact_dir = Path(r"C:\Users\josep\.gemini\antigravity\brain\531c46cb-8072-4f87-b5f7-0dbc38a43bbf")
    artifact_dir.mkdir(parents=True, exist_ok=True)
    target_img = artifact_dir / "playwright_dashboard_capture.png"

    print(f"Launching Playwright Chromium to capture {html_path}...")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 720})
        page = context.new_page()
        page.goto(f"file:///{html_path.as_posix()}")
        page.wait_for_timeout(1000)
        page.screenshot(path=str(target_img), full_page=True)
        browser.close()
        print(f"SUCCESS: Playwright captured dashboard screenshot to {target_img}")

if __name__ == "__main__":
    run_playwright_verification()
