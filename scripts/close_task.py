"""Close a task from verified GitHub merge evidence and refresh its dashboard."""
import argparse
import json
import re
import subprocess
from pathlib import Path

from generate_task_dashboard import build_html, parse_tasks

ROOT = Path(__file__).resolve().parent.parent


def close_task(root, task_id, evidence, validation):
    """Validate all inputs before updating the task and its index. Safe to repeat."""
    root = Path(root)
    if not re.fullmatch(r'TASK-\d{3,}', task_id):
        raise ValueError('Expected TASK-XXX')
    commit = (evidence.get('mergeCommit') or {}).get('oid', '')
    url = evidence.get('url', '')
    merged_at = evidence.get('mergedAt', '')
    if (evidence.get('state') != 'MERGED' or not merged_at
            or not re.fullmatch(r'[0-9a-f]{40}', commit)
            or not re.fullmatch(r'https://[^\s]+/pull/\d+', url)):
        raise ValueError('PR must have verified merge evidence')
    if not validation.strip():
        raise ValueError('Validation evidence is required')
    packets = list((root / 'docs/tasks').glob(task_id + '-*.md'))
    if len(packets) != 1:
        raise ValueError('Expected exactly one matching task packet')
    packet = packets[0]
    text = packet.read_text(encoding='utf-8')
    text, count = re.subn(r'(?m)^- \*\*Status:\*\* \w+\s*$',
                          '- **Status:** DONE', text)
    if count != 1:
        raise ValueError('Expected exactly one task status')
    index = root / 'docs/tasks/README.md'
    lines = index.read_text(encoding='utf-8').splitlines(keepends=True)
    matched = 0
    for number, line in enumerate(lines):
        if f'[{task_id}](' not in line:
            continue
        fields = line.split('|')
        if len(fields) != 8 or fields[1].strip() != f'[{task_id}]({packet.name})':
            raise ValueError('Unexpected task index row')
        fields[5] = ' DONE '
        lines[number] = '|'.join(fields)
        matched += 1
    if matched != 1:
        raise ValueError('Expected exactly one task index row')
    start, end = '<!-- verified-closure -->', '<!-- /verified-closure -->'
    if text.count(start) != text.count(end) or text.count(start) > 1:
        raise ValueError('Malformed closure record')
    text = re.sub(re.escape(start) + r'.*?' + re.escape(end), '', text, flags=re.S)
    note = ('\n\n' + start + '\n## Verified completion\n\n'
            f'- Merged PR: {url}\n- Merge commit: `{commit}`\n'
            f'- Merged at: {merged_at}\n'
            f'- Validation: {" ".join(validation.split())}\n' + end + '\n')
    old_packet = packet.read_bytes()
    old_index = index.read_bytes()
    dashboard = root / 'docs/tasks/dashboard.html'
    old_dashboard = dashboard.read_bytes() if dashboard.exists() else None
    try:
        packet.write_text(text.rstrip() + note, encoding='utf-8')
        index.write_text(''.join(lines), encoding='utf-8')
        dashboard.write_text(build_html(parse_tasks(str(root))), encoding='utf-8')
    except Exception:
        packet.write_bytes(old_packet)
        index.write_bytes(old_index)
        if old_dashboard is not None:
            dashboard.write_bytes(old_dashboard)
        elif dashboard.exists():
            dashboard.unlink()
        raise
    return packet


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('task_id')
    parser.add_argument('--pr', required=True, type=int)
    parser.add_argument('--validation', required=True)
    args = parser.parse_args()
    try:
        result = subprocess.run(
            ['gh', 'pr', 'view', str(args.pr), '--json',
             'state,mergedAt,mergeCommit,url'], cwd=ROOT, check=True,
            capture_output=True, text=True, encoding='utf-8', timeout=30)
        packet = close_task(ROOT, args.task_id, json.loads(result.stdout), args.validation)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f'Closure failed: {error}\n')
    print(f'Closed {args.task_id}: {packet.name}; index and dashboard refreshed.')


if __name__ == '__main__':
    main()
