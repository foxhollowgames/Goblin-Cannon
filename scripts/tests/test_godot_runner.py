import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import godot_test_runner as runner


class RunnerTests(unittest.TestCase):
    def test_false_pass_cases(self):
        good = 'Total: 5 passed, 0 failed\n'
        cases = [(1, good, ''), (0, good, 'SCRIPT ERROR: broken'),
                 (0, 'SCRIPT ERROR: broken\n' + good, ''), (0, '', ''),
                 (0, 'suite: 0 failed', ''), (0, 'Total: 0 passed, 0 failed', ''),
                 (0, good + 'Total: 4 passed, 1 failed', '')]
        for args in cases:
            with self.subTest(args=args):
                self.assertFalse(runner.evaluate_result(*args)['passed'])
        self.assertTrue(runner.evaluate_result(0, good, '')['passed'])
        self.assertEqual(runner.evaluate_result(1, good, '')['passed_assertions'], 5)

    @patch.object(runner.subprocess, 'run')
    def test_raw_logs_and_one_process(self, run):
        with tempfile.TemporaryDirectory() as folder:
            run.return_value = subprocess.CompletedProcess([], 0, 'Total: 5 passed, 0 failed\n', 'warning')
            result = runner.run_tests(folder, godot='test-godot')
            self.assertTrue(result['passed'])
            run.assert_called_once()
            self.assertFalse(run.call_args.kwargs['shell'])
            self.assertIsInstance(run.call_args.args[0], list)
            logs = Path(result['log_dir'])
            self.assertEqual((logs / 'stderr.txt').read_text(), 'warning')
            self.assertEqual((logs / 'stdout.txt').read_text(), run.return_value.stdout)
            for error in [subprocess.TimeoutExpired('godot', 1, output=b'partial', stderr=b'error'), OSError('missing')]:
                run.side_effect = error
                result = runner.run_tests(folder, godot='test-godot')
                saved = json.loads((logs / 'result.json').read_text())
                self.assertFalse(saved['passed'])
                self.assertIn('timestamp', saved)
                if isinstance(error, subprocess.TimeoutExpired):
                    self.assertEqual((logs / 'stdout.txt').read_text(), 'partial')
                else:
                    self.assertEqual((logs / 'stdout.txt').read_text(), '')


if __name__ == '__main__':
    unittest.main()
