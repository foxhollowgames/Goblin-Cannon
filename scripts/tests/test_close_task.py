"""Check verified closure, rejected evidence, repeat calls, and rollback."""
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from close_task import close_task


class ClosureTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.tasks = self.root / 'docs/tasks'
        self.tasks.mkdir(parents=True)
        self.packet = self.tasks / 'TASK-118-example.md'
        self.packet.write_text('# Example\n- **Status:** IN_PROGRESS\n\n## Description\nExample\n')
        self.index = self.tasks / 'README.md'
        self.index.write_text('| [TASK-118](TASK-118-example.md) | Example | DevOps | P1 | IN_PROGRESS | `fix/example` |\n')
        self.evidence = dict(state='MERGED', mergedAt='2026-09-27T00:00:00Z',
                             mergeCommit={'oid': 'a' * 40}, url='https://github.com/a/b/pull/94')

    def test_closes_all_surfaces_and_repeats_without_duplicate_evidence(self):
        for _ in range(2):
            close_task(self.root, 'TASK-118', self.evidence, 'Focused checks passed')
        text = self.packet.read_text(encoding='utf-8')
        self.assertIn('**Status:** DONE', text)
        self.assertEqual(text.count('## Verified completion'), 1)
        self.assertIn('a' * 40, text)
        self.assertIn('| DONE |', self.index.read_text())
        self.assertIn('"status": "DONE"', (self.tasks / 'dashboard.html').read_text(encoding='utf-8'))

    def test_invalid_evidence_does_not_change_files(self):
        before = self.packet.read_bytes(), self.index.read_bytes()
        for change in ({'state': 'OPEN'}, {'mergeCommit': None}, {'mergedAt': None}):
            with self.assertRaises(ValueError):
                close_task(self.root, 'TASK-118', self.evidence | change, 'passed')
        self.assertEqual(before, (self.packet.read_bytes(), self.index.read_bytes()))

    def test_missing_index_and_invalid_id_are_rejected(self):
        for task in ('../TASK-118', 'TASK-119'):
            with self.assertRaises(ValueError):
                close_task(self.root, task, self.evidence, 'passed')
        self.index.write_text('No row')
        with self.assertRaises(ValueError):
            close_task(self.root, 'TASK-118', self.evidence, 'passed')
        self.assertIn('IN_PROGRESS', self.packet.read_text())

    def test_dashboard_failure_restores_records(self):
        before = self.packet.read_bytes(), self.index.read_bytes()
        with patch('close_task.build_html', side_effect=RuntimeError('render failed')):
            with self.assertRaises(RuntimeError):
                close_task(self.root, 'TASK-118', self.evidence, 'passed')
        self.assertEqual(before, (self.packet.read_bytes(), self.index.read_bytes()))


if __name__ == '__main__':
    unittest.main()
