import os
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

def run_playwright_verification() -> None:
    html_path = Path("docs/tasks/dashboard.html").resolve()
    conv_id = os.environ.get("ANTIGRAVITY_CONVERSATION_ID", "4ae3c293-2f09-46ba-a308-6cfc5485d424")
    artifact_dir = Path(os.path.expanduser(f"~/.gemini/antigravity/brain/{conv_id}"))
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
