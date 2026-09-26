"""Export the SQLite records into bounded, linked reference pages."""
import json
import re
from pathlib import Path


def render_entry(row):
    return '\n'.join([
        f'## <a id="{row["id"].lower()}"></a> {row["id"]}: {row["topic"]}',
        f'- **Task:** {row["task_id"]}', f'- **Category:** {row["category"]}',
        f'- **Created:** {row["created_at"]}', f'- **Tags:** {row.get("tags", "")}', '',
        '### Context', row['context'], '', '### Learning', row['learning'], '',
        '### Guideline', row['guideline'], '',
    ])


def export_learnings(rows, knowledge_dir):
    root = Path(knowledge_dir)
    folder = root / 'learnings'
    manifest = folder / '.manifest.json'
    outputs, locations, groups = {}, {}, {}
    for row in sorted(rows, key=lambda item: item['id']):
        slug = re.sub('[^a-z0-9]+', '-', row['category'].lower()).strip('-') or 'general'
        groups.setdefault(slug, []).append(row)
    for slug, entries in sorted(groups.items()):
        part = 1
        content = f'# {slug}\n\n[Learning index](../LEARNINGS.md)\n\n'
        for row in entries:
            entry = render_entry(row) + '\n'
            if len(entry.splitlines()) > 440:
                raise ValueError(f'{row["id"]} exceeds the entry limit; shorten it before export')
            if len((content + entry).splitlines()) > 450:
                outputs[f'{slug}-{part:03d}.md'] = content
                part += 1
                content = f'# {slug} (part {part})\n\n[Learning index](../LEARNINGS.md)\n\n'
            locations[row['id']] = f'learnings/{slug}-{part:03d}.md#{row["id"].lower()}'
            content += entry
        outputs[f'{slug}-{part:03d}.md'] = content
    index = [
        '# Agent learning index', '',
        'SQLite is the source of truth. Read only the categories needed for the current task.',
        'Use `python scripts/learnings.py query TOPIC` for short results.',
        'Use `python scripts/learnings.py show LRN-001` for one full record.', '',
        '## Categories', '',
    ]
    index.extend(f'- [{name[:-3]}](learnings/{name})' for name in outputs)
    index.extend(['', '## Previous entry links', '', 'These anchors preserve links made before the category split.', ''])
    for number in range(1, 151):
        key = f'LRN-{number:03d}'
        if key in locations:
            index.append(f'- <a id="{key.lower()}"></a> [{key}]({locations[key]})')
    index_text = '\n'.join(index) + '\n'
    if len(index_text.splitlines()) >= 500:
        raise ValueError('Learning index needs another level before export')
    targets = [root / 'LEARNINGS.md', folder, manifest, *(folder / name for name in outputs)]
    if any(path.is_symlink() for path in targets):
        raise ValueError('Generated learning paths must not be symlinks')
    previous = json.loads(manifest.read_text(encoding='utf-8')) if manifest.exists() else []
    if not isinstance(previous, list):
        raise ValueError('Invalid learning manifest')
    folder.mkdir(parents=True, exist_ok=True)
    for name, content in outputs.items():
        (folder / name).write_text(content, encoding='utf-8')
    (root / 'LEARNINGS.md').write_text(index_text, encoding='utf-8')
    for name in previous:
        if isinstance(name, str) and re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*-[0-9]{3,}\.md', name):
            stale = folder / name
            if name not in outputs and stale.is_file() and not stale.is_symlink():
                stale.unlink()
    manifest.write_text(json.dumps(list(outputs), indent=2) + '\n', encoding='utf-8')
    return ['LEARNINGS.md', *(f'learnings/{name}' for name in outputs)]
