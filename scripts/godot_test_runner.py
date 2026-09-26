"""Run Godot once and retain the raw process evidence."""
import argparse
import json
import os
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def evaluate_result(returncode, stdout, stderr):
    summaries = re.findall(r'^\s*Total:\s*(\d+) passed,\s*(\d+) failed\s*$', stdout, re.MULTILINE)
    passed_count, failed_count = map(int, summaries[-1]) if summaries else (0, 0)
    if returncode != 0:
        reason = f'Process exited {returncode}'
    elif 'SCRIPT ERROR' in stdout or 'SCRIPT ERROR' in stderr:
        reason = 'Script error'
    elif not summaries:
        reason = 'Missing final summary'
    elif failed_count or not passed_count:
        reason = 'Failed assertions or no assertions'
    else:
        reason = 'Passed'
    return dict(passed=reason == 'Passed', returncode=returncode,
                passed_assertions=passed_count, failed_assertions=failed_count, reason=reason)


def resolve_godot():
    if os.environ.get('GODOT_BIN'):
        return os.environ['GODOT_BIN']
    located = shutil.which('godot')
    if located:
        return located
    for candidate in (
        'C:/Users/josep/Desktop/Games/Godot_v4.6.1-stable_win64.exe',
        'C:/Users/josep/Desktop/Coding Projects/Godot_v4.6.2-stable_win64.exe',
    ):
        if Path(candidate).is_file():
            return candidate
    return 'godot'


def _text(value):
    return value.decode('utf-8', errors='replace') if isinstance(value, bytes) else value or ''


def run_tests(project_root, godot=None, timeout=120, log_dir=None):
    root = Path(project_root).resolve()
    logs = Path(log_dir).resolve() if log_dir else root / '.godot' / 'audit'
    logs.mkdir(parents=True, exist_ok=True)
    command = [godot or resolve_godot(), '--headless', '--path', str(root),
               '--log-file', str(logs / 'engine.log'), '--script', 'tests/run_tests.gd']
    try:
        process = subprocess.run(command, cwd=root, capture_output=True, text=True,
                                 encoding='utf-8', errors='replace', timeout=timeout, shell=False)
        stdout, stderr = process.stdout, process.stderr
        result = evaluate_result(process.returncode, stdout, stderr)
    except subprocess.TimeoutExpired as error:
        stdout, stderr = _text(error.stdout), _text(error.stderr)
        result = evaluate_result(-1, stdout, stderr)
        result['reason'] = f'Timed out after {timeout} seconds'
    except OSError as error:
        stdout, stderr = '', str(error)
        result = evaluate_result(-1, stdout, stderr)
    result.update(command=command, timestamp=datetime.now(timezone.utc).isoformat(), log_dir=str(logs))
    (logs / 'stdout.txt').write_text(stdout, encoding='utf-8')
    (logs / 'stderr.txt').write_text(stderr, encoding='utf-8')
    (logs / 'result.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-root', default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--godot')
    parser.add_argument('--timeout', type=int, default=120)
    args = parser.parse_args()
    result = run_tests(args.project_root, args.godot, args.timeout)
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
