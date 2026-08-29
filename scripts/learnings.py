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
    cursor = conn.execute("SELECT * FROM learnings ORDER BY id ASC")
    rows = cursor.fetchall()

    lines = [
        "# Goblin Cannon — Agent Knowledge Base & Learnings",
        "",
        "This canonical knowledge base stores lessons, patterns, and optimization rules learned by agents during task execution.",
        "**All agents must review this document or query `python scripts/learnings.py query <topic>` before starting complex tasks.**",
        "",
        "---",
        "",
        "## Quick Index",
        "",
        "| ID | Task | Category | Topic | Created |",
        "| :--- | :--- | :--- | :--- | :--- |",
    ]

    for row in rows:
        lines.append(f"| [`{row['id']}`](#{row['id'].lower()}) | {row['task_id']} | `{row['category']}` | {row['topic']} | {row['created_at'][:10]} |")

    lines.extend(["", "---", "", "## Detailed Learnings", ""])

    for row in rows:
        lines.extend([
            f"### <a id=\"{row['id'].lower()}\"></a> {row['id']}: {row['topic']}",
            f"- **Task:** `{row['task_id']}`",
            f"- **Category:** `{row['category']}`",
            f"- **Created:** `{row['created_at']}`",
            "",
            "#### Context & Problem",
            row["context"].strip(),
            "",
            "#### Key Insight & Learning",
            row["learning"].strip(),
            "",
            "#### Actionable Guideline for Future Agents",
            row["guideline"].strip(),
            "",
            "---",
            ""
        ])

    with open(MD_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines).strip() + "\n")


def add_learning(task_id: str, category: str, topic: str, context: str, learning: str, guideline: str) -> str:
    conn = get_db_connection()
    new_id = get_next_id(conn)
    now = datetime.now().isoformat()
    with conn:
        conn.execute("""
            INSERT INTO learnings (id, task_id, category, topic, context, learning, guideline, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (new_id, task_id, category, topic, context, learning, guideline, now))
    sync_to_markdown(conn)
    conn.close()
    return new_id


def query_learnings(query_str: str = "", category: str = "") -> None:
    conn = get_db_connection()
    sql = "SELECT * FROM learnings WHERE 1=1"
    params = []
    if category:
        sql += " AND category LIKE ?"
        params.append(f"%{category}%")
    if query_str:
        sql += " AND (topic LIKE ? OR learning LIKE ? OR context LIKE ? OR guideline LIKE ?)"
        term = f"%{query_str}%"
        params.extend([term, term, term, term])
    sql += " ORDER BY id ASC"

    cursor = conn.execute(sql, params)
    rows = cursor.fetchall()
    conn.close()

    if not rows:
        print(f"No learnings found matching '{query_str}' (category: '{category}').")
        return

    print(f"Found {len(rows)} matching learning(s):\n")
    for r in rows:
        print(f"[{r['id']}] ({r['category']}) {r['topic']} (Task: {r['task_id']})")
        print(f"  Guideline: {r['guideline']}")
        print()


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

    # Query command
    q_p = subparsers.add_parser("query", help="Query learnings")
    q_p.add_argument("query", nargs="?", default="", help="Search query string")
    q_p.add_argument("--category", default="", help="Filter by category")

    # List command
    subparsers.add_parser("list", help="List all learnings")

    # Sync command
    subparsers.add_parser("sync", help="Re-sync SQLite DB to docs/knowledge/LEARNINGS.md")

    args = parser.parse_args()

    if args.command == "add":
        entry_id = add_learning(args.task, args.category, args.topic, args.context, args.learning, args.guideline)
        print(f"Successfully recorded learning: {entry_id}")
    elif args.command == "query":
        query_learnings(args.query, args.category)
    elif args.command == "list":
        list_all()
    elif args.command == "sync":
        conn = get_db_connection()
        sync_to_markdown(conn)
        conn.close()
        print("Synchronized learnings to docs/knowledge/LEARNINGS.md")


if __name__ == "__main__":
    main()
