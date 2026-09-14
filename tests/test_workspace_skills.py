#!/usr/bin/env python3
"""
Unit tests for workspace agent skills, task creator, and quality audit scripts.
"""

import os
import re
import sys
import unittest

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(PROJECT_ROOT, "scripts"))

import create_task
import audit_quality


class TestWorkspaceSkills(unittest.TestCase):
    def test_slugify(self):
        self.assertEqual(create_task.slugify("Fix Ball Bounce Bug!"), "fix-ball-bounce-bug")
        self.assertEqual(create_task.slugify("TASK-001: Implement Core Loop"), "task-001-implement-core-loop")
        self.assertEqual(create_task.slugify("Special #$% Characters & Spaces"), "special-characters-spaces")

    def test_find_next_task_id(self):
        next_id = create_task.find_next_task_id()
        self.assertGreaterEqual(next_id, 95)

    def test_build_task_markdown(self):
        md = create_task.build_task_markdown(
            task_id=999,
            title="Test Task Title",
            category="Testing",
            priority="P2",
            status="READY",
            branch="feature/test-task",
        )
        self.assertIn("# TASK-999: Test Task Title", md)
        self.assertIn("- **Status:** READY", md)
        self.assertIn("- **Priority:** P2", md)
        self.assertIn("- **Category:** Testing", md)
        self.assertIn("- **Target Branch:** `feature/test-task`", md)
        self.assertIn("## Acceptance Criteria", md)

    def test_resolve_godot_path(self):
        path = audit_quality.resolve_godot_path()
        self.assertTrue(os.path.exists(path) or path == "godot")

    def test_skill_files_exist_and_have_frontmatter(self):
        skills = [
            "godot-task-manager",
            "godot-quality-audit",
            "godot-learnings-loop",
        ]
        frontmatter_pattern = re.compile(r"^---\s*\nname:\s*([\w-]+)\s*\ndescription:\s*(.*?)\n---\s*\n", re.DOTALL)

        for skill_name in skills:
            skill_path = os.path.join(PROJECT_ROOT, ".agents", "skills", skill_name, "SKILL.md")
            self.assertTrue(os.path.exists(skill_path), f"Missing skill file: {skill_path}")

            with open(skill_path, "r", encoding="utf-8") as f:
                content = f.read()

            match = frontmatter_pattern.match(content)
            self.assertIsNotNone(match, f"Skill {skill_name} is missing valid YAML frontmatter")
            self.assertEqual(match.group(1), skill_name)
            self.assertTrue(len(match.group(2).strip()) > 10, f"Skill {skill_name} has empty description")


if __name__ == "__main__":
    unittest.main()
