#!/usr/bin/env python3
"""
Generate an interactive HTML visual task dashboard for Goblin Cannon.
Parses tasks from docs/tasks/README.md and docs/tasks/TASK-*.md files.
Outputs:
  - docs/tasks/dashboard.html (under 500 lines for project linter)
  - Artifact HTML in current conversation artifact folder
"""

import os
import re
import json
import sys

def parse_tasks(repo_root):
    readme_path = os.path.join(repo_root, "docs", "tasks", "README.md")
    if not os.path.exists(readme_path):
        print(f"Error: {readme_path} not found.")
        return []
    
    with open(readme_path, "r", encoding="utf-8") as f:
        readme_content = f.read()

    table_matches = re.findall(
        r'\|\s*\[(TASK-\d+)\]\(([^)]+)\)\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|',
        readme_content
    )

    tasks = []
    task_dir = os.path.join(repo_root, "docs", "tasks")

    for m in table_matches:
        task_id = m[0].strip()
        title = m[2].strip()
        category = m[3].strip()
        priority = m[4].strip()
        status = m[5].strip()
        branch = m[6].strip()

        summary = ""
        for fname in os.listdir(task_dir):
            if fname.startswith(task_id) and fname.endswith(".md"):
                file_path = os.path.join(task_dir, fname)
                try:
                    with open(file_path, "r", encoding="utf-8") as tf:
                        tcontent = tf.read()
                        obj_m = re.search(r'##\s*Description\s*\n+([^#\n]+)', tcontent, re.IGNORECASE)
                        if not obj_m:
                            obj_m = re.search(r'##\s*1?\.\s*Objective\s*\n+([^#\n]+)', tcontent, re.IGNORECASE)
                        if obj_m:
                            summary = obj_m.group(1).strip()
                except Exception:
                    pass
                break

        domain = "Gameplay & Systems"
        cat_lower = category.lower()
        if any(x in cat_lower for x in ["art", "ui", "cinematic", "narrative", "typography"]):
            domain = "UI, Art & Narrative"
        elif any(x in cat_lower for x in ["audio", "sound", "sfx"]):
            domain = "Audio & Polish"
        elif "devops" in cat_lower:
            domain = "DevOps & Tooling"
        elif any(x in cat_lower for x in ["control", "steering"]):
            domain = "Controls & Input"

        tasks.append({
            "id": task_id,
            "title": title,
            "category": category,
            "domain": domain,
            "priority": priority,
            "status": status,
            "branch": branch,
            "summary": summary
        })

    return tasks

def build_html(tasks):
    tasks_json = json.dumps(tasks)
    
    total = len(tasks)
    done_count = sum(1 for t in tasks if t["status"] == "DONE")
    ready_count = sum(1 for t in tasks if t["status"] == "READY")
    backlog_count = sum(1 for t in tasks if t["status"] == "BACKLOG")
    in_prog_count = sum(1 for t in tasks if t["status"] == "IN_PROGRESS")
    pct_done = round((done_count / total * 100), 1) if total > 0 else 0
    pct_ready = round((ready_count / total * 100), 1) if total > 0 else 0
    pct_backlog = round((backlog_count / total * 100), 1) if total > 0 else 0

    js_template = """const ALL_TASKS = __TASKS_JSON__;
let viewMode = 'kanban';

function setViewMode(mode) {
  viewMode = mode;
  ['kanban','matrix','list'].forEach(m => {
    const btn = document.getElementById('btn-view-' + m);
    if (btn) btn.className = m === mode ? 'px-3 py-1.5 text-xs font-medium rounded-md bg-indigo-600 text-white cursor-pointer' : 'px-3 py-1.5 text-xs font-medium rounded-md text-slate-400 hover:text-white cursor-pointer';
    const c = document.getElementById('container-' + m);
    if (c) c.classList.toggle('hidden', m !== mode);
  });
  render();
}

function getFilteredTasks() {
  const query = (document.getElementById('input-search').value || '').trim().toLowerCase();
  const st = document.getElementById('filter-status').value;
  const dom = document.getElementById('filter-domain').value;
  const prio = document.getElementById('filter-priority').value;

  return ALL_TASKS.filter(t => {
    if (st !== 'ALL' && t.status !== st) return false;
    if (dom !== 'ALL' && t.domain !== dom) return false;
    if (prio !== 'ALL' && t.priority !== prio) return false;
    if (query && !(t.id + ' ' + t.title + ' ' + t.category + ' ' + t.branch + ' ' + t.summary).toLowerCase().includes(query)) return false;
    return true;
  });
}

function renderCard(t) {
  const prioClass = t.priority === 'P0' ? 'badge-p0' : t.priority === 'P1' ? 'badge-p1' : 'badge-p2';
  return `<div class="bg-slate-900/90 border border-slate-700/80 rounded-lg p-3 space-y-2 hover:border-slate-500 transition shadow-sm">
    <div class="flex items-center justify-between"><span class="font-mono text-[11px] text-indigo-300 font-bold">${t.id}</span><span class="text-[10px] font-bold px-1.5 py-0.5 rounded ${prioClass}">${t.priority}</span></div>
    <h4 class="text-xs font-semibold text-white leading-snug">${t.title}</h4>
    ${t.summary ? `<p class="text-[11px] text-slate-400 line-clamp-2">${t.summary}</p>` : ''}
    <div class="pt-2 border-t border-slate-800 flex items-center justify-between text-[10px] text-slate-400"><span class="bg-slate-800 px-2 py-0.5 rounded text-slate-300">${t.category}</span><span class="font-mono text-[9px] text-slate-500 truncate max-w-[110px]">${t.branch}</span></div>
  </div>`;
}

function renderKanban(tasks) {
  const cols = {'BACKLOG': document.getElementById('cards-backlog'), 'READY': document.getElementById('cards-ready'), 'IN_PROGRESS': document.getElementById('cards-in_progress'), 'DONE': document.getElementById('cards-done')};
  const cnts = {'BACKLOG': document.getElementById('cnt-backlog'), 'READY': document.getElementById('cnt-ready'), 'IN_PROGRESS': document.getElementById('cnt-in_progress'), 'DONE': document.getElementById('cnt-done')};
  Object.values(cols).forEach(c => c.innerHTML = '');
  const counts = {'BACKLOG': 0, 'READY': 0, 'IN_PROGRESS': 0, 'DONE': 0};
  tasks.forEach(t => { const st = cols[t.status] ? t.status : 'BACKLOG'; cols[st].innerHTML += renderCard(t); counts[st]++; });
  Object.keys(counts).forEach(k => cnts[k].innerText = counts[k]);
}

function renderMatrix(tasks) {
  const c = document.getElementById('container-matrix');
  c.innerHTML = '';
  ['Gameplay & Systems', 'UI, Art & Narrative', 'Controls & Input', 'Audio & Polish', 'DevOps & Tooling'].forEach(dom => {
    const domTasks = tasks.filter(t => t.domain === dom);
    if (!domTasks.length) return;
    const done = domTasks.filter(t => t.status === 'DONE').length, ready = domTasks.filter(t => t.status === 'READY').length, backlog = domTasks.filter(t => t.status === 'BACKLOG').length;
    const pct = Math.round((done / domTasks.length) * 100);
    c.innerHTML += `<div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-5 space-y-4 shadow-sm">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-2 border-b border-[var(--border,#334155)] pb-3">
        <h3 class="text-base font-bold text-white flex items-center gap-2"><span>📂 ${dom}</span><span class="text-xs font-normal text-slate-400">(${domTasks.length} tasks)</span></h3>
        <div class="flex items-center gap-3 text-xs"><span class="text-emerald-400 font-semibold">${pct}% Done (${done}/${domTasks.length})</span><span class="text-indigo-400 font-medium">${ready} Ready</span><span class="text-amber-400 font-medium">${backlog} Backlog</span></div>
      </div>
      <div class="w-full h-2 bg-slate-800 rounded-full overflow-hidden flex"><div style="width:${pct}%" class="bg-emerald-500 h-full"></div><div style="width:${Math.round(ready/domTasks.length*100)}%" class="bg-indigo-500 h-full"></div><div style="width:${Math.round(backlog/domTasks.length*100)}%" class="bg-slate-600 h-full"></div></div>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-3 pt-2">${domTasks.map(t => renderCard(t)).join('')}</div>
    </div>`;
  });
}

function renderList(tasks) {
  const tbody = document.getElementById('list-table-body');
  tbody.innerHTML = tasks.map(t => `<tr class="hover:bg-slate-800/50 transition border-b border-slate-800"><td class="px-4 py-3 font-mono font-bold text-indigo-300">${t.id}</td><td class="px-4 py-3 font-semibold text-white">${t.title}</td><td class="px-4 py-3 text-slate-300">${t.domain}</td><td class="px-4 py-3 text-slate-400">${t.category}</td><td class="px-4 py-3"><span class="text-[10px] font-bold px-2 py-0.5 rounded badge-${t.priority.toLowerCase()}">${t.priority}</span></td><td class="px-4 py-3"><span class="text-[10px] font-bold px-2 py-0.5 rounded badge-${t.status.toLowerCase()}">${t.status}</span></td><td class="px-4 py-3 font-mono text-[10px] text-slate-400">${t.branch}</td></tr>`).join('');
}

function render() {
  const filtered = getFilteredTasks();
  if (viewMode === 'kanban') renderKanban(filtered);
  else if (viewMode === 'matrix') renderMatrix(filtered);
  else if (viewMode === 'list') renderList(filtered);
}
render();
""".replace("__TASKS_JSON__", tasks_json)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Goblin Cannon — Visual Task Matrix</title>
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
  <style>
    .kanban-col {{ min-height: 380px; }}
    .badge-p0 {{ background-color: #ef4444; color: #fff; }} .badge-p1 {{ background-color: #f59e0b; color: #fff; }} .badge-p2 {{ background-color: #3b82f6; color: #fff; }}
    .badge-done {{ background-color: #10b981; color: #fff; }} .badge-ready {{ background-color: #6366f1; color: #fff; }} .badge-backlog {{ background-color: #6b7280; color: #fff; }} .badge-in_progress {{ background-color: #ec4899; color: #fff; }}
  </style>
</head>
<body class="bg-[var(--background,#0f172a)] text-[var(--foreground,#f8fafc)] p-6 font-sans antialiased min-h-screen">
  <div class="max-w-7xl mx-auto space-y-6">
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-[var(--border,#334155)] pb-5">
      <div>
        <h1 class="text-2xl md:text-3xl font-bold tracking-tight text-white flex items-center gap-3">🏴‍☠️ Goblin Cannon Task Matrix</h1>
        <p class="text-sm text-slate-400 mt-1">Interactive visual task board, status breakdown, and category matrix</p>
      </div>
      <span class="text-xs font-semibold px-3 py-1.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">Overall Progress: {pct_done}% ({done_count}/{total} Tasks Completed)</span>
    </div>

    <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 shadow-sm"><div class="text-xs font-medium text-slate-400">Total Tasks</div><div class="text-2xl font-bold mt-1 text-white">{total}</div><div class="text-[11px] text-slate-500 mt-1">Canonical packets</div></div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 shadow-sm"><div class="text-xs font-medium text-emerald-400">Completed (DONE)</div><div class="text-2xl font-bold mt-1 text-emerald-400">{done_count}</div><div class="text-[11px] text-emerald-400/80 mt-1">{pct_done}% of total</div></div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 shadow-sm"><div class="text-xs font-medium text-indigo-400">Ready for Dev</div><div class="text-2xl font-bold mt-1 text-indigo-400">{ready_count}</div><div class="text-[11px] text-indigo-400/80 mt-1">{pct_ready}% of total</div></div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 shadow-sm"><div class="text-xs font-medium text-amber-400">In Backlog</div><div class="text-2xl font-bold mt-1 text-amber-400">{backlog_count}</div><div class="text-[11px] text-amber-400/80 mt-1">{pct_backlog}% of total</div></div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 shadow-sm"><div class="text-xs font-medium text-pink-400">Active (In Progress)</div><div class="text-2xl font-bold mt-1 text-pink-400">{in_prog_count}</div><div class="text-[11px] text-pink-400/80 mt-1">Active branch</div></div>
    </div>

    <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4">
      <div class="flex justify-between text-xs font-semibold mb-2"><span class="text-white">Completion Breakdown</span><span class="text-slate-400">{done_count} Done · {ready_count} Ready · {backlog_count} Backlog</span></div>
      <div class="w-full h-3 bg-slate-700 rounded-full overflow-hidden flex">
        <div style="width: {pct_done}%" class="bg-emerald-500 h-full" title="Done: {pct_done}%"></div>
        <div style="width: {pct_ready}%" class="bg-indigo-500 h-full" title="Ready: {pct_ready}%"></div>
        <div style="width: {pct_backlog}%" class="bg-slate-500 h-full" title="Backlog: {pct_backlog}%"></div>
      </div>
    </div>

    <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 space-y-4">
      <div class="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
        <div class="flex items-center gap-1 bg-slate-900/60 p-1 rounded-lg border border-[var(--border,#334155)]">
          <button id="btn-view-kanban" onclick="setViewMode('kanban')" class="px-3 py-1.5 text-xs font-medium rounded-md bg-indigo-600 text-white cursor-pointer">Kanban Board</button>
          <button id="btn-view-matrix" onclick="setViewMode('matrix')" class="px-3 py-1.5 text-xs font-medium rounded-md text-slate-400 hover:text-white cursor-pointer">Category Matrix</button>
          <button id="btn-view-list" onclick="setViewMode('list')" class="px-3 py-1.5 text-xs font-medium rounded-md text-slate-400 hover:text-white cursor-pointer">Detailed List</button>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <input type="text" id="input-search" oninput="render()" placeholder="Search title, ID, branch..." class="bg-slate-900/80 border border-slate-700 text-xs rounded-lg px-3 py-2 text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 w-48 md:w-64">
          <select id="filter-status" onchange="render()" class="bg-slate-900/80 border border-slate-700 text-xs rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="ALL">All Statuses</option><option value="DONE">DONE</option><option value="READY">READY</option><option value="BACKLOG">BACKLOG</option><option value="IN_PROGRESS">IN_PROGRESS</option>
          </select>
          <select id="filter-domain" onchange="render()" class="bg-slate-900/80 border border-slate-700 text-xs rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="ALL">All Domains</option><option value="Gameplay & Systems">Gameplay & Systems</option><option value="UI, Art & Narrative">UI, Art & Narrative</option><option value="Controls & Input">Controls & Input</option><option value="Audio & Polish">Audio & Polish</option><option value="DevOps & Tooling">DevOps & Tooling</option>
          </select>
          <select id="filter-priority" onchange="render()" class="bg-slate-900/80 border border-slate-700 text-xs rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="ALL">All Priorities</option><option value="P0">P0 (Critical)</option><option value="P1">P1 (High)</option><option value="P2">P2 (Normal)</option>
          </select>
        </div>
      </div>
    </div>

    <div id="container-kanban" class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 flex flex-col">
        <div class="flex items-center justify-between pb-3 border-b border-slate-700 mb-3"><span class="font-semibold text-xs text-amber-400 uppercase tracking-wider flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-amber-400"></span> Backlog</span><span id="cnt-backlog" class="text-xs font-bold bg-slate-800 text-amber-400 px-2 py-0.5 rounded-full border border-amber-500/20">0</span></div>
        <div id="cards-backlog" class="kanban-col space-y-3 flex-1 overflow-y-auto"></div>
      </div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 flex flex-col">
        <div class="flex items-center justify-between pb-3 border-b border-slate-700 mb-3"><span class="font-semibold text-xs text-indigo-400 uppercase tracking-wider flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-indigo-400"></span> Ready</span><span id="cnt-ready" class="text-xs font-bold bg-slate-800 text-indigo-400 px-2 py-0.5 rounded-full border border-indigo-500/20">0</span></div>
        <div id="cards-ready" class="kanban-col space-y-3 flex-1 overflow-y-auto"></div>
      </div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 flex flex-col">
        <div class="flex items-center justify-between pb-3 border-b border-slate-700 mb-3"><span class="font-semibold text-xs text-pink-400 uppercase tracking-wider flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-pink-400"></span> In Progress</span><span id="cnt-in_progress" class="text-xs font-bold bg-slate-800 text-pink-400 px-2 py-0.5 rounded-full border border-pink-500/20">0</span></div>
        <div id="cards-in_progress" class="kanban-col space-y-3 flex-1 overflow-y-auto"></div>
      </div>
      <div class="bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl p-4 flex flex-col">
        <div class="flex items-center justify-between pb-3 border-b border-slate-700 mb-3"><span class="font-semibold text-xs text-emerald-400 uppercase tracking-wider flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-emerald-400"></span> Done</span><span id="cnt-done" class="text-xs font-bold bg-slate-800 text-emerald-400 px-2 py-0.5 rounded-full border border-emerald-500/20">0</span></div>
        <div id="cards-done" class="kanban-col space-y-3 flex-1 overflow-y-auto"></div>
      </div>
    </div>

    <div id="container-matrix" class="hidden space-y-6"></div>

    <div id="container-list" class="hidden bg-[var(--card,#1e293b)] border border-[var(--border,#334155)] rounded-xl overflow-hidden shadow-sm">
      <table class="w-full text-left text-xs text-slate-200">
        <thead class="bg-slate-900/80 text-slate-400 uppercase text-[10px] tracking-wider border-b border-slate-700">
          <tr><th class="px-4 py-3">Task ID</th><th class="px-4 py-3">Title</th><th class="px-4 py-3">Domain</th><th class="px-4 py-3">Category</th><th class="px-4 py-3">Priority</th><th class="px-4 py-3">Status</th><th class="px-4 py-3">Branch</th></tr>
        </thead>
        <tbody id="list-table-body" class="divide-y divide-slate-800"></tbody>
      </table>
    </div>
  </div>

  <script>
    {js_template}
  </script>
</body>
</html>
"""
    return html

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    tasks = parse_tasks(repo_root)
    if not tasks:
        print("No tasks found.")
        sys.exit(1)

    html_content = build_html(tasks)

    out_file = os.path.join(repo_root, "docs", "tasks", "dashboard.html")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"Generated standalone task dashboard at {out_file}")

    artifact_dir = r"C:\Users\josep\.gemini\antigravity\brain\f5a782f9-f227-4588-9c94-6f1d472a580a"
    if os.path.exists(artifact_dir):
        artifact_file = os.path.join(artifact_dir, "task_dashboard.html")
        with open(artifact_file, "w", encoding="utf-8") as f:
            f.write(html_content)
        print(f"Generated conversation artifact dashboard at {artifact_file}")

if __name__ == "__main__":
    main()
