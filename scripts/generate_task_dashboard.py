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
import datetime


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

        summary, body, file_name = "", "", ""
        mtime = os.path.getmtime(readme_path)
        for fname in os.listdir(task_dir):
            if fname.startswith(task_id) and fname.endswith(".md"):
                file_path = os.path.join(task_dir, fname)
                file_name = fname
                try:
                    mtime = os.path.getmtime(file_path)
                    with open(file_path, "r", encoding="utf-8") as tf:
                        body = tf.read()
                        obj_m = re.search(r'##\s*(?:Description|1?\.\s*Objective)\s*\n+([^#\n]+)', body, re.IGNORECASE)
                        if obj_m:
                            summary = obj_m.group(1).strip()
                except Exception:
                    pass
                break

        num_match = re.search(r'\d+', task_id)
        task_num = int(num_match.group()) if num_match else 0
        mtime_str = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")

        domain = "Gameplay & Systems"
        cat_lower = category.lower()
        if any(x in cat_lower for x in ["art", "ui", "cinematic", "narrative", "typography"]): domain = "UI, Art & Narrative"
        elif any(x in cat_lower for x in ["audio", "sound", "sfx"]): domain = "Audio & Polish"
        elif "devops" in cat_lower: domain = "DevOps & Tooling"
        elif any(x in cat_lower for x in ["control", "steering"]): domain = "Controls & Input"


        tasks.append({
            "id": task_id,
            "num": task_num,
            "mtime": mtime,
            "mtime_str": mtime_str,
            "file_name": file_name,
            "title": title,
            "category": category,
            "domain": domain,
            "priority": priority,
            "status": status,
            "branch": branch,
            "summary": summary,
            "body": body
        })

    tasks.sort(key=lambda t: (t.get("mtime", 0.0), t.get("num", 0)), reverse=True)
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
let viewMode = 'kanban', currentModalId = null;

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
  const sort = document.getElementById('filter-sort') ? document.getElementById('filter-sort').value : 'recent';

  let list = ALL_TASKS.filter(t => {
    if (st !== 'ALL' && t.status !== st) return false;
    if (dom !== 'ALL' && t.domain !== dom) return false;
    if (prio !== 'ALL' && t.priority !== prio) return false;
    if (query && !(t.id + ' ' + t.title + ' ' + t.category + ' ' + t.branch + ' ' + t.summary).toLowerCase().includes(query)) return false;
    return true;
  });

  if (sort === 'recent') list.sort((a, b) => (b.mtime || 0) - (a.mtime || 0) || (b.num || 0) - (a.num || 0));
  else if (sort === 'oldest') list.sort((a, b) => (a.mtime || 0) - (b.mtime || 0) || (a.num || 0) - (b.num || 0));
  else if (sort === 'id_desc') list.sort((a, b) => (b.num || 0) - (a.num || 0));
  else if (sort === 'id_asc') list.sort((a, b) => (a.num || 0) - (b.num || 0));
  else if (sort === 'priority') {
    const pMap = {'P0': 0, 'P1': 1, 'P2': 2};
    list.sort((a, b) => (pMap[a.priority] ?? 9) - (pMap[b.priority] ?? 9) || (b.mtime || 0) - (a.mtime || 0));
  }
  return list;
}

function renderCard(t) {
  const prioClass = t.priority === 'P0' ? 'badge-p0' : t.priority === 'P1' ? 'badge-p1' : 'badge-p2';
  return `<div onclick="openTaskModal('${t.id}')" class="group bg-slate-900/90 border border-slate-700/80 hover:border-indigo-500 rounded-lg p-3 space-y-2 hover:bg-slate-800/60 transition cursor-pointer shadow-sm">
    <div class="flex items-center justify-between">
      <span class="font-mono text-[11px] text-indigo-300 font-bold flex items-center gap-1">${t.id} <span class="opacity-0 group-hover:opacity-100 text-indigo-400 text-[10px] transition">⤢</span></span>
      <span class="text-[10px] font-bold px-1.5 py-0.5 rounded ${prioClass}">${t.priority}</span>
    </div>
    <h4 class="text-xs font-semibold text-white leading-snug group-hover:text-indigo-200">${t.title}</h4>
    ${t.summary ? `<p class="text-[11px] text-slate-400 line-clamp-2">${t.summary}</p>` : ''}
    <div class="pt-2 border-t border-slate-800 flex items-center justify-between text-[10px] text-slate-400">
      <span class="bg-slate-800 px-2 py-0.5 rounded text-slate-300">${t.category}</span>
      <span class="font-mono text-[9px] text-slate-500 truncate max-w-[110px]">${t.branch}</span>
    </div>
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
  tbody.innerHTML = tasks.map(t => `<tr onclick="openTaskModal('${t.id}')" class="hover:bg-slate-800/60 transition border-b border-slate-800 cursor-pointer group">
    <td class="px-4 py-3 font-mono font-bold text-indigo-300 flex items-center gap-1">${t.id} <span class="opacity-0 group-hover:opacity-100 text-[10px] text-indigo-400">⤢</span></td>
    <td class="px-4 py-3 font-semibold text-white group-hover:text-indigo-200">${t.title}</td>
    <td class="px-4 py-3 text-slate-300">${t.domain}</td>
    <td class="px-4 py-3 text-slate-400">${t.category}</td>
    <td class="px-4 py-3"><span class="text-[10px] font-bold px-2 py-0.5 rounded badge-${t.priority.toLowerCase()}">${t.priority}</span></td>
    <td class="px-4 py-3"><span class="text-[10px] font-bold px-2 py-0.5 rounded badge-${t.status.toLowerCase()}">${t.status}</span></td>
    <td class="px-4 py-3 font-mono text-[10px] text-slate-400">${t.branch}</td>
  </tr>`).join('');
}

function render() {
  const filtered = getFilteredTasks();
  if (viewMode === 'kanban') renderKanban(filtered);
  else if (viewMode === 'matrix') renderMatrix(filtered);
  else if (viewMode === 'list') renderList(filtered);
}

function formatMarkdown(md) {
  if (!md) return '<p class="text-slate-400 italic text-xs">No task specification content found.</p>';
  let text = md.replace(/^#[^\\n]+\\n+/, '').replace(/^(-\\s+\\*\\*[^*]+:\\*\\*.*\\n*)+/gm, '').trim();
  const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const fmtInline = s => s.replace(/`([^`]+)`/g, '<code class="bg-slate-800 border border-slate-700 text-indigo-300 px-1 py-0.5 rounded font-mono text-[10px]">$1</code>').replace(/\\*\\*([^*]+)\\*\\*/g, '<strong class="text-white font-semibold">$1</strong>').replace(/\\[([^\\]]+)\\]\\(([^)]+)\\)/g, '<a href="$2" target="_blank" class="text-indigo-400 hover:underline">$1</a>');
  const lines = text.split('\\n');
  let out = [], inUl = false, inTbl = false, tblRows = [];
  const endUl = () => { if (inUl) { out.push('</ul>'); inUl = false; } };
  const endTbl = () => { if (inTbl) { out.push('<div class="overflow-x-auto my-2"><table class="w-full text-xs text-left border border-slate-700/80 rounded">' + tblRows.join('') + '</table></div>'); inTbl = false; tblRows = []; } };

  for (let raw of lines) {
    let l = raw.trim();
    if (!l) { endUl(); endTbl(); continue; }
    if (l === '---') { endUl(); endTbl(); out.push('<hr class="border-slate-800 my-3" />'); continue; }
    if (l.startsWith('### ')) { endUl(); endTbl(); out.push(`<h4 class="text-xs font-bold uppercase text-indigo-400 mt-3 mb-1.5">${esc(l.slice(4))}</h4>`); continue; }
    if (l.startsWith('## ')) { endUl(); endTbl(); out.push(`<h3 class="text-sm font-bold text-white border-b border-slate-800 pb-1 mt-4 mb-2 flex items-center gap-1.5"><span>📌</span><span>${esc(l.slice(3))}</span></h3>`); continue; }
    const chk = l.match(/^-\\s*\\[([ xX])\\]\\s*(.*)$/);
    if (chk) {
      endUl(); endTbl();
      const done = chk[1].toLowerCase() === 'x';
      const badge = done ? '<span class="text-emerald-400 font-bold">✓</span>' : '<span class="text-slate-500 font-bold">○</span>';
      out.push(`<div class="flex items-start gap-2 py-0.5 text-xs"><span class="w-4 flex-shrink-0 text-center">${badge}</span><span class="${done ? 'text-slate-200' : 'text-slate-400'}">${fmtInline(esc(chk[2]))}</span></div>`);
      continue;
    }
    if (l.startsWith('- ') || l.startsWith('* ')) {
      endTbl();
      if (!inUl) { out.push('<ul class="space-y-1 my-1.5">'); inUl = true; }
      out.push(`<li class="text-xs text-slate-300 flex items-start gap-2"><span class="text-indigo-400">•</span><span>${fmtInline(esc(l.slice(2)))}</span></li>`);
      continue;
    }
    if (l.startsWith('|') && l.endsWith('|')) {
      endUl();
      if (l.includes('---')) continue;
      const isHead = !inTbl; inTbl = true;
      const tag = isHead ? 'th' : 'td';
      const cls = isHead ? 'bg-slate-800 text-slate-300 font-semibold px-2.5 py-1 text-[11px]' : 'border-t border-slate-800 px-2.5 py-1 text-[11px] text-slate-300';
      tblRows.push(`<tr>${l.split('|').slice(1, -1).map(c => `<${tag} class="${cls}">${fmtInline(esc(c.trim()))}</${tag}>`).join('')}</tr>`);
      continue;
    }
    endUl(); endTbl();
    out.push(`<p class="text-xs text-slate-300 leading-relaxed my-1">${fmtInline(esc(l))}</p>`);
  }
  endUl(); endTbl();
  return out.join('');
}

function openTaskModal(taskId) {
  const task = ALL_TASKS.find(t => t.id === taskId);
  if (!task) return;
  currentModalId = taskId;
  document.getElementById('modal-id').innerText = task.id;
  document.getElementById('modal-title').innerText = task.title;
  const pEl = document.getElementById('modal-prio');
  pEl.innerText = task.priority;
  pEl.className = 'text-[10px] font-bold px-2 py-0.5 rounded badge-' + task.priority.toLowerCase();
  const sEl = document.getElementById('modal-status');
  sEl.innerText = task.status;
  sEl.className = 'text-[10px] font-bold px-2 py-0.5 rounded badge-' + task.status.toLowerCase();
  document.getElementById('modal-cat').innerText = task.category;
  document.getElementById('modal-domain').innerText = task.domain;
  document.getElementById('modal-branch').innerText = task.branch;
  document.getElementById('modal-mtime').innerText = task.mtime_str || '';
  const fLink = document.getElementById('modal-file-link');
  if (task.file_name) { fLink.href = task.file_name; fLink.classList.remove('hidden'); }
  else { fLink.classList.add('hidden'); }
  document.getElementById('modal-body').innerHTML = formatMarkdown(task.body || task.summary);
  updateModalNav();
  document.getElementById('task-modal-backdrop').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}

function closeTaskModal() {
  currentModalId = null;
  document.getElementById('task-modal-backdrop').classList.add('hidden');
  document.body.style.overflow = '';
}

function updateModalNav() {
  const list = getFilteredTasks();
  const idx = list.findIndex(t => t.id === currentModalId);
  const pBtn = document.getElementById('modal-btn-prev');
  const nBtn = document.getElementById('modal-btn-next');
  if (idx === -1) { pBtn.disabled = true; nBtn.disabled = true; return; }
  pBtn.disabled = idx <= 0; nBtn.disabled = idx >= list.length - 1;
  pBtn.classList.toggle('opacity-30', pBtn.disabled);
  nBtn.classList.toggle('opacity-30', nBtn.disabled);
  document.getElementById('modal-nav-idx').innerText = `${idx + 1} of ${list.length}`;
}

function navTaskModal(delta) {
  const list = getFilteredTasks();
  const idx = list.findIndex(t => t.id === currentModalId);
  if (idx !== -1 && list[idx + delta]) openTaskModal(list[idx + delta].id);
}

function copyBranch() {
  const t = ALL_TASKS.find(x => x.id === currentModalId);
  if (!t || !t.branch) return;
  navigator.clipboard.writeText(`git checkout ${t.branch}`);
  const b = document.getElementById('btn-copy-branch');
  b.innerText = 'Copied!';
  setTimeout(() => b.innerText = 'Copy', 1500);
}

window.addEventListener('keydown', e => {
  if (currentModalId) {
    if (e.key === 'Escape') closeTaskModal();
    else if (e.key === 'ArrowLeft') navTaskModal(-1);
    else if (e.key === 'ArrowRight') navTaskModal(1);
  }
});

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
          <input type="text" id="input-search" oninput="render()" placeholder="Search title, ID, branch..." class="bg-slate-900/80 border border-slate-700 text-xs rounded-lg px-3 py-2 text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 w-44 md:w-56">
          <select id="filter-sort" onchange="render()" class="bg-slate-900/80 border border-slate-700 text-xs rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 font-medium">
            <option value="recent">Sort: Most Recently Edited (Default)</option>
            <option value="oldest">Sort: Oldest First</option>
            <option value="id_desc">Sort: Task ID (High &rarr; Low)</option>
            <option value="id_asc">Sort: Task ID (Low &rarr; High)</option>
            <option value="priority">Sort: Priority (P0 &rarr; P2)</option>
          </select>
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

  <div id="task-modal-backdrop" onclick="if(event.target.id==='task-modal-backdrop')closeTaskModal()" class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 hidden flex items-center justify-center p-4">
    <div id="task-modal-card" class="bg-slate-900 border border-slate-700 rounded-2xl shadow-2xl max-w-3xl w-full max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
      <div class="p-5 border-b border-slate-800 bg-slate-900/90 flex flex-col gap-3">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-2 flex-wrap">
            <span id="modal-id" class="font-mono text-xs font-bold text-indigo-300 bg-indigo-950/80 border border-indigo-700/50 px-2 py-0.5 rounded"></span>
            <span id="modal-prio" class="text-[10px] font-bold px-2 py-0.5 rounded"></span>
            <span id="modal-status" class="text-[10px] font-bold px-2 py-0.5 rounded"></span>
            <span id="modal-cat" class="text-[10px] font-medium px-2 py-0.5 rounded bg-slate-800 text-slate-300 border border-slate-700"></span>
            <span id="modal-domain" class="text-[10px] font-medium px-2 py-0.5 rounded bg-slate-800 text-slate-400 border border-slate-700"></span>
          </div>
          <button onclick="closeTaskModal()" class="text-slate-400 hover:text-white bg-slate-800 rounded-lg w-7 h-7 flex items-center justify-center cursor-pointer text-sm font-bold transition" title="Close (Esc)">✕</button>
        </div>
        <h2 id="modal-title" class="text-lg md:text-xl font-bold text-white leading-snug"></h2>
        <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-400 pt-1 border-t border-slate-800/60">
          <div class="flex items-center gap-1.5 font-mono text-[11px]"><span class="text-slate-500">Branch:</span><span id="modal-branch" class="text-indigo-300 font-semibold"></span><button id="btn-copy-branch" onclick="copyBranch()" class="text-[10px] text-slate-400 hover:text-white bg-slate-800 px-1.5 py-0.5 rounded border border-slate-700 cursor-pointer">Copy</button></div>
          <div class="flex items-center gap-1 text-[11px]"><span class="text-slate-500">Modified:</span><span id="modal-mtime" class="text-slate-300"></span></div>
          <a id="modal-file-link" href="#" target="_blank" class="text-[11px] text-indigo-400 hover:text-indigo-300 underline">📄 View Markdown File</a>
        </div>
      </div>
      <div id="modal-body" class="p-6 overflow-y-auto flex-1 space-y-2 bg-slate-900/50"></div>
      <div class="p-4 border-t border-slate-800 bg-slate-900/90 flex items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2">
          <button id="modal-btn-prev" onclick="navTaskModal(-1)" class="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700 cursor-pointer transition">← Prev</button>
          <button id="modal-btn-next" onclick="navTaskModal(1)" class="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700 cursor-pointer transition">Next →</button>
          <span id="modal-nav-idx" class="text-slate-500 text-[11px] ml-1"></span>
        </div>
        <button onclick="closeTaskModal()" class="px-4 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white font-medium cursor-pointer transition">Close</button>
      </div>
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

    brain_root = r"C:\Users\josep\.gemini\antigravity\brain"
    if os.path.exists(brain_root):
        conv_id = os.environ.get("ANTIGRAVITY_CONVERSATION_ID", "")
        target_dirs = [os.path.join(brain_root, conv_id)] if conv_id and os.path.exists(os.path.join(brain_root, conv_id)) else []
        if not target_dirs:
            dirs = sorted([os.path.join(brain_root, d) for d in os.listdir(brain_root) if os.path.isdir(os.path.join(brain_root, d))], key=os.path.getmtime, reverse=True)
            target_dirs = dirs[:1] if dirs else []
        for tdir in target_dirs:
            artifact_file = os.path.join(tdir, "task_dashboard.html")
            with open(artifact_file, "w", encoding="utf-8") as f:
                f.write(html_content)
            print(f"Generated conversation artifact dashboard at {artifact_file}")

if __name__ == "__main__":
    main()
