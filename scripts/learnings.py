"""
learnings.py — Goblin Cannon Agent Learning & Knowledge Base Database CLI.

Manages SQLite storage and automatic markdown synchronization for agent learnings.
Future agents can query this database before starting tasks to execute quickly and cheaply.
"""

import sys
import os
import sqlite3
import argparse
from datetime import datetime
from learning_export import export_learnings, render_entry

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KNOWLEDGE_DIR = os.path.join(REPO_ROOT, "docs", "knowledge")
DB_PATH = os.path.join(KNOWLEDGE_DIR, "learnings.db")
MD_PATH = os.path.join(KNOWLEDGE_DIR, "LEARNINGS.md")


def get_db_connection() -> sqlite3.Connection:
    os.makedirs(KNOWLEDGE_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    with conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS learnings (
                id TEXT PRIMARY KEY,
                task_id TEXT NOT NULL,
                category TEXT NOT NULL,
                topic TEXT NOT NULL,
                context TEXT NOT NULL,
                learning TEXT NOT NULL,
                guideline TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_category ON learnings (category)
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_task ON learnings (task_id)
        """)
        columns = {row['name'] for row in conn.execute('PRAGMA table_info(learnings)')}
        if 'tags' not in columns:
            conn.execute("ALTER TABLE learnings ADD COLUMN tags TEXT NOT NULL DEFAULT ''")
    return conn


def get_next_id(conn: sqlite3.Connection) -> str:
    cursor = conn.execute("SELECT id FROM learnings ORDER BY id DESC")
    rows = cursor.fetchall()
    highest = 0
    for row in rows:
        val = row["id"]
        if val.startswith("LRN-"):
            try:
                num = int(val[4:])
                if num > highest:
                    highest = num
            except ValueError:
                pass
    return f"LRN-{highest + 1:03d}"


def sync_to_markdown(conn: sqlite3.Connection) -> None:
    export_learnings([dict(row) for row in conn.execute('SELECT * FROM learnings ORDER BY id')], KNOWLEDGE_DIR)


def add_learning(task_id: str, category: str, topic: str, context: str, learning: str, guideline: str, tags: str = '') -> str:
    conn = get_db_connection()
    new_id = get_next_id(conn)
    now = datetime.now().isoformat()
    with conn:
        conn.execute("""
            INSERT INTO learnings (id, task_id, category, topic, context, learning, guideline, created_at, tags)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (new_id, task_id, category, topic, context, learning, guideline, now, tags))
    sync_to_markdown(conn)
    conn.close()
    return new_id


def query_learnings(query_str: str = "", category: str = "", limit: int = 10, offset: int = 0) -> None:
    if limit < 1 or offset < 0:
        raise ValueError('limit must be positive and offset must be nonnegative')
    conn = get_db_connection()
    sql = "SELECT * FROM learnings WHERE 1=1"
    params = []
    if category:
        sql += " AND category LIKE ?"
        params.append(f"%{category}%")
    if query_str:
        sql += " AND (topic LIKE ? OR learning LIKE ? OR context LIKE ? OR guideline LIKE ? OR id LIKE ? OR task_id LIKE ? OR category LIKE ? OR tags LIKE ?)"
        term = f"%{query_str}%"
        params.extend([term] * 8)
    total = conn.execute(sql.replace('SELECT *', 'SELECT COUNT(*)'), params).fetchone()[0]
    sql += " ORDER BY id ASC LIMIT ? OFFSET ?"
    params.extend([limit, offset])

    cursor = conn.execute(sql, params)
    rows = cursor.fetchall()
    conn.close()

    if not rows:
        print(f"No learnings found matching '{query_str}' (category: '{category}').")
        return

    print(f"Showing {len(rows)} of {total} matching learning(s), offset {offset}:\n")
    for r in rows:
        print(f"[{r['id']}] ({r['category']}) {r['topic']} (Task: {r['task_id']})")
        guideline = ' '.join(r['guideline'].split())
        print(f"  Guideline: {guideline[:240]}{'...' if len(guideline) > 240 else ''}")
        print()


def show_learning(entry_id: str) -> None:
    conn = get_db_connection()
    row = conn.execute('SELECT * FROM learnings WHERE id = ?', (entry_id,)).fetchone()
    conn.close()
    if row is None:
        raise ValueError(f'Learning not found: {entry_id}')
    print(render_entry(dict(row)))


def list_all() -> None:
    conn = get_db_connection()
    cursor = conn.execute("SELECT id, task_id, category, topic, created_at FROM learnings ORDER BY id ASC")
    rows = cursor.fetchall()
    conn.close()
    print(f"Total Learnings: {len(rows)}\n")
    for r in rows:
        print(f"  {r['id']}: [{r['category']}] {r['topic']} (Task: {r['task_id']})")


def main():
    parser = argparse.ArgumentParser(description="Agent Learnings Database Manager")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Add command
    add_p = subparsers.add_parser("add", help="Add a new learning entry")
    add_p.add_argument("--task", required=True, help="Task ID (e.g. TASK-027)")
    add_p.add_argument("--category", required=True, help="Category (e.g. godot_engine, subagents, worktrees, testing)")
    add_p.add_argument("--topic", required=True, help="Short summary of the topic")
    add_p.add_argument("--context", required=True, help="Problem or context encountered")
    add_p.add_argument("--learning", required=True, help="The insight or underlying mechanic")
    add_p.add_argument("--guideline", required=True, help="Concrete guideline for future agents")
    add_p.add_argument('--tags', default='', help='Comma-separated related topics')

    # Query command
    q_p = subparsers.add_parser("query", help="Query learnings")
    q_p.add_argument("query", nargs="?", default="", help="Search query string")
    q_p.add_argument("--category", default="", help="Filter by category")
    q_p.add_argument('--limit', type=int, default=10)
    q_p.add_argument('--offset', type=int, default=0)
    show_p = subparsers.add_parser('show', help='Read one full learning')
    show_p.add_argument('id')

    # List command
    subparsers.add_parser("list", help="List all learnings")

    # Sync command
    subparsers.add_parser("sync", help="Re-sync SQLite DB to docs/knowledge/LEARNINGS.md")

    args = parser.parse_args()

    if args.command == "add":
        entry_id = add_learning(args.task, args.category, args.topic, args.context, args.learning, args.guideline, args.tags)
        print(f"Successfully recorded learning: {entry_id}")
    elif args.command == "query":
        if args.limit < 1 or args.offset < 0:
            parser.error('limit must be positive and offset must be nonnegative')
        query_learnings(args.query, args.category, args.limit, args.offset)
    elif args.command == 'show':
        try:
            show_learning(args.id)
        except ValueError as error:
            parser.error(str(error))
    elif args.command == "list":
        list_all()
    elif args.command == "sync":
        conn = get_db_connection()
        sync_to_markdown(conn)
        conn.close()
        print("Synchronized learnings to docs/knowledge/LEARNINGS.md")


if __name__ == "__main__":
    main()
