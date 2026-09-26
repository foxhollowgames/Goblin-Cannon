import contextlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import audit_quality as audit


class AuditTests(unittest.TestCase):
    def test_modes_and_failure_propagation(self):
        cases = [({}, True, True, 1, 0), ({'skip_tests': True}, True, True, 0, 0),
                 ({'baseline': True}, True, True, 0, 0), ({}, False, True, 0, 1),
                 ({}, True, False, 1, 1)]
        for options, static_ok, godot_ok, calls, exit_code in cases:
            with self.subTest(options=options, static=static_ok, godot=godot_ok), tempfile.TemporaryDirectory() as folder:
                result = dict(name='mock', passed=static_ok, returncode=0 if static_ok else 1, stdout='', stderr='')
                with patch.object(audit, 'PROJECT_ROOT', Path(folder)), patch.object(audit, 'run_step', return_value=result), patch.object(audit, 'run_tests', return_value=dict(passed=godot_ok)) as runner, patch.object(audit.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'abc', '')), contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(audit.audit_quality(**options), exit_code)
                    self.assertEqual(runner.call_count, calls)
                logs = Path(folder) / '.godot' / 'audit'
                self.assertTrue((logs / 'audit.json').is_file())
                if options.get('baseline'):
                    baseline = json.loads((logs / 'baseline.json').read_text())
                    self.assertEqual(baseline['revision'], 'abc')
                    self.assertEqual(len(baseline['results']), 3)

    @patch.object(audit.subprocess, 'run')
    def test_static_process_failure_and_timeout(self, process):
        process.return_value = subprocess.CompletedProcess([], 3, 'earlier pass', 'failure')
        self.assertFalse(audit.run_step('test', ['script.py'])['passed'])
        self.assertFalse(process.call_args.kwargs['shell'])
        process.side_effect = subprocess.TimeoutExpired('test', 1)
        self.assertFalse(audit.run_step('test', ['script.py'])['passed'])


if __name__ == '__main__':
    unittest.main()
