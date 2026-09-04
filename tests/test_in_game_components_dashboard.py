import os
import re
import json

def test_in_game_components_dashboard_file():
    path = os.path.join("docs", "knowledge", "in-game-components-dashboard.html")
    assert os.path.exists(path), f"{path} does not exist"

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    assert len(lines) <= 500, f"in-game-components-dashboard.html length {len(lines)} exceeds 500 lines"
    assert "<!DOCTYPE html>" in content, "Missing HTML5 doctype"
    assert "TASK-069" in content, "Missing TASK-069 badge or reference"
    assert "pinball-research-dashboard.html" in content, "Missing link to physical dashboard"

def test_pinball_research_dashboard_link():
    phys_path = os.path.join("docs", "knowledge", "pinball-research-dashboard.html")
    assert os.path.exists(phys_path), f"{phys_path} does not exist"

    with open(phys_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "in-game-components-dashboard.html" in content, "pinball-research-dashboard.html missing link to in-game components dashboard"

def test_components_data_integrity():
    path = os.path.join("docs", "knowledge", "in-game-components-dashboard.html")
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    match = re.search(r"const COMPONENTS = (\[.*?\]);", content, re.DOTALL)
    assert match, "COMPONENTS array not found in script"

    raw_json = match.group(1)
    # Sanitize js keys for json parsing if needed
    items = re.findall(r'\{\s*id:\s*"([^"]+)",\s*name:\s*"([^"]+)",\s*cat:\s*"([^"]+)"', raw_json)
    assert len(items) >= 15, f"Expected at least 15 components, got {len(items)}"

    expected_ids = [
        "POP_BUMPER", "DROP_TARGET", "STANDUP_TARGET", "SPINNER",
        "SCOOP_SINKHOLE", "BALL_LOCK", "GUIDE_TRACK", "ORBIT_LOOP",
        "SLINGSHOT", "ROLLOVER_SWITCH", "CAPTIVE_BALL", "MECHANICAL_DIVERTER",
        "VERTICAL_UP_KICKER", "BASH_TOY", "OUTLANE_KICKBACK"
    ]
    found_ids = [item[0] for item in items]
    for exp_id in expected_ids:
        assert exp_id in found_ids, f"Expected widget {exp_id} missing from components roster"

def test_ui_and_lightbox_elements():
    path = os.path.join("docs", "knowledge", "in-game-components-dashboard.html")
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    required_elements = [
        'id="component-search"', 'id="category-filters"', 'id="component-rows"',
        'id="lightbox"', 'id="lb-title"', 'id="lb-badge"', 'id="lb-art"',
        'id="lb-desc"', 'id="lb-energy"', 'id="lb-impulse"'
    ]
    for el in required_elements:
        assert el in content, f"Required UI element {el} missing from HTML"

    required_functions = [
        "renderTable", "filterComponents", "setCategory", "openLightbox", "closeLightbox"
    ]
    for fn in required_functions:
        assert fn in content, f"Required function {fn} missing from JS"

import unittest

class TestInGameComponentsDashboard(unittest.TestCase):
    def test_in_game_components_dashboard_file(self):
        test_in_game_components_dashboard_file()

    def test_pinball_research_dashboard_link(self):
        test_pinball_research_dashboard_link()

    def test_components_data_integrity(self):
        test_components_data_integrity()

    def test_ui_and_lightbox_elements(self):
        test_ui_and_lightbox_elements()

if __name__ == "__main__":
    unittest.main()
