import contextlib
import io
import json
import re
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import learnings
from learning_export import export_learnings


def records(count=60):
    return [dict(id=f'LRN-{i:03d}', task_id=f'TASK-{i:03d}', category='tooling',
                 topic=f'Topic {i}', context=f'Context {i}\nsecond line',
                 learning=f'Finding {i}', guideline=f'Action {i}',
                 created_at='2026-09-26T00:00:00', tags='tests,workflow')
            for i in range(1, count + 1)]


class LearningTests(unittest.TestCase):
    def test_export_retains_records_links_and_page_limits(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            rows = records()
            paths = export_learnings(rows, root)
            before = {name: (root / name).read_bytes() for name in paths}
            pages = [(root / name).read_text(encoding='utf-8') for name in paths[1:]]
            self.assertGreater(len(pages), 1)
            for row in rows:
                anchor = f'<a id="{row["id"].lower()}"></a>'
                self.assertEqual(sum(page.count(anchor) for page in pages), 1)
                page = next(page for page in pages if anchor in page)
                for value in row.values():
                    self.assertIn(value, page)
            for name in paths:
                content = (root / name).read_text(encoding='utf-8')
                self.assertLess(len(content.splitlines()), 500)
                for link in re.findall(r'\]\(([^)]+)\)', content):
                    target, _, anchor = link.partition('#')
                    destination = (root / name).parent / target
                    self.assertTrue(destination.is_file(), link)
                    if anchor:
                        self.assertIn(f'id="{anchor}"', destination.read_text(encoding='utf-8'))
            export_learnings(rows, root)
            self.assertEqual(before, {name: (root / name).read_bytes() for name in paths})
            rows[0]['context'] = '\n' * 500
            with self.assertRaises(ValueError):
                export_learnings(rows, root)
            self.assertEqual(before, {name: (root / name).read_bytes() for name in paths})

    def test_cleanup_is_limited_to_generated_basenames(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            paths = export_learnings(records(), root)
            custom = root / 'learnings' / 'custom.md'
            outside = root / 'outside-001.md'
            custom.write_text('keep')
            outside.write_text('keep')
            manifest = root / 'learnings' / '.manifest.json'
            previous = json.loads(manifest.read_text())
            manifest.write_text(json.dumps(previous + ['../outside-001.md', str(outside), 'custom.md']))
            export_learnings(records(1), root)
            self.assertEqual(custom.read_text(), 'keep')
            self.assertEqual(outside.read_text(), 'keep')
            self.assertFalse((root / paths[-1]).exists())

    def test_legacy_database_migration_and_targeted_queries(self):
        with tempfile.TemporaryDirectory() as folder:
            db = Path(folder) / 'learnings.db'
            rows = records(12)
            columns = [key for key in rows[0] if key != 'tags']
            with sqlite3.connect(db) as conn:
                conn.execute('CREATE TABLE learnings (' + ', '.join(key + ' TEXT' for key in columns) + ')')
                conn.executemany('INSERT INTO learnings VALUES (' + ','.join('?' for _ in columns) + ')',
                                 [tuple(row[key] for key in columns) for row in rows])
                before = conn.execute('SELECT * FROM learnings ORDER BY id').fetchall()
            conn.close()
            with patch.object(learnings, 'DB_PATH', str(db)), patch.object(learnings, 'KNOWLEDGE_DIR', folder):
                conn = learnings.get_db_connection()
                after = [tuple(row) for row in conn.execute('SELECT ' + ','.join(columns) + ' FROM learnings ORDER BY id')]
                conn.execute("UPDATE learnings SET tags='unique-tag' WHERE id='LRN-012'")
                conn.commit()
                conn.close()
                self.assertEqual(before, after)
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    learnings.query_learnings()
                self.assertIn('Showing 10 of 12', output.getvalue())
                self.assertNotIn('[LRN-011]', output.getvalue())
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    learnings.query_learnings(offset=10)
                    learnings.query_learnings('unique-tag')
                    learnings.show_learning('LRN-012')
                self.assertIn('Showing 2 of 12', output.getvalue())
                self.assertIn('Showing 1 of 1', output.getvalue())
                self.assertIn(rows[-1]['context'], output.getvalue())
                with self.assertRaises(ValueError):
                    learnings.query_learnings(limit=0)
                with self.assertRaises(ValueError):
                    learnings.show_learning('LRN-999')


if __name__ == '__main__':
    unittest.main()
