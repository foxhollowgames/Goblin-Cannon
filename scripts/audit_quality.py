"""Run static checks, tooling tests, and one authoritative Godot suite."""
import argparse
import json
import platform
import subprocess
import sys
from pathlib import Path
from godot_test_runner import run_tests

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def run_step(name, args):
    try:
        process = subprocess.run([sys.executable, *args], cwd=PROJECT_ROOT, shell=False,
                                 capture_output=True, text=True, encoding='utf-8',
                                 errors='replace', timeout=120)
        return dict(name=name, passed=process.returncode == 0, returncode=process.returncode,
                    stdout=process.stdout, stderr=process.stderr)
    except (subprocess.TimeoutExpired, OSError) as error:
        return dict(name=name, passed=False, returncode=-1, stdout='', stderr=str(error))


def audit_quality(skip_tests=False, skip_directory=False, baseline=False):
    results = []
    steps = [] if skip_directory else [('Directory', ['scripts/generate_directory.py'])]
    lint_args = ['scripts/lint_gdscript.py']
    if not skip_directory:
        lint_args.append('--skip-directory')
    steps.extend([('Static lint and lengths', lint_args),
                  ('Tooling tests', ['-m', 'unittest', 'discover', '-s', 'scripts/tests'])])
    for name, args in steps:
        result = run_step(name, args)
        results.append(result)
        print(f'[{"PASS" if result["passed"] else "FAIL"}] {name}', flush=True)
        print(result['stdout'] + result['stderr'], flush=True)
    static_passed = all(result['passed'] for result in results)
    logs = PROJECT_ROOT / '.godot' / 'audit'
    logs.mkdir(parents=True, exist_ok=True)
    if baseline:
        revision = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=PROJECT_ROOT,
                                  capture_output=True, text=True, timeout=10)
        (logs / 'baseline.json').write_text(json.dumps(dict(
            revision=revision.stdout.strip(), platform=platform.platform(),
            python=sys.version, results=results), indent=2), encoding='utf-8')
    if static_passed and not skip_tests and not baseline:
        result = run_tests(PROJECT_ROOT)
        results.append(dict(name='Godot', **result))
        print(json.dumps(result, indent=2), flush=True)
    passed = all(result['passed'] for result in results)
    (logs / 'audit.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    mode = 'STATIC ONLY' if skip_tests or baseline else 'FULL AUDIT'
    print(f'{mode}: {"PASS" if passed else "FAIL"}', flush=True)
    return 0 if passed else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', action='store_true')
    parser.add_argument('--skip-tests', action='store_true')
    parser.add_argument('--skip-directory', action='store_true')
    return audit_quality(**vars(parser.parse_args()))


if __name__ == '__main__':
    raise SystemExit(main())
