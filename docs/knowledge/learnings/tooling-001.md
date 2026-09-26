# tooling

[Learning index](../LEARNINGS.md)

## <a id="lrn-011"></a> LRN-011: Windows GUI Godot Binary Console Redirection
- **Task:** TASK-028
- **Category:** tooling
- **Created:** 2026-08-28T22:12:30.338547
- **Tags:** 

### Context
On Windows, running Godot GUI binary directly in PowerShell with ampersand does not pipe stdout, masking GDScript parse errors.

### Learning
Executing Godot headless commands through cmd.exe /c attaches standard I/O streams and reveals all compilation errors and test suite logs.

### Guideline
Always run headless Godot tests via cmd.exe /c on Windows to prevent silent test failures.

## <a id="lrn-020"></a> LRN-020: Zero-Dependency Local Ollama Code Generation CLI
- **Task:** TASK-034
- **Category:** tooling
- **Created:** 2026-08-29T10:42:56.937507
- **Tags:** 

### Context
Connecting Antigravity to local Qwen 2.5 Coder for offline zero-cost code generation.

### Learning
Using a standalone standard-library Python CLI script (urllib) avoids external dependencies and enables Antigravity to generate, edit, and test GDScript through local Ollama.

### Guideline
Use python scripts/ollama_coder.py [generate|edit|test] to produce GDScript with local Qwen at zero cost.

## <a id="lrn-026"></a> LRN-026: File Length Limit (500 lines) and Baseline Allowlist
- **Task:** TASK-LINT-01
- **Category:** tooling
- **Created:** 2026-08-29T18:21:15.131579
- **Tags:** 

### Context
Files were growing too large without an automated check, requiring an audit and lint rule.

### Learning
A Python lint tool and a Godot headless test ensure all new files stay under 500 lines while pinning legacy files to baseline limits.

### Guideline
Run python scripts/lint_file_lengths.py or headless tests to audit file lengths before merging.

## <a id="lrn-030"></a> LRN-030: AI Codebase Directory and Automated Quality Tooling
- **Task:** TASK-DIRECTORY-01
- **Category:** tooling
- **Created:** 2026-08-31T21:44:23.298306
- **Tags:** 

### Context
AI agents needed a single reference for repo file locations, signal wiring, and GDScript standards without doing expensive grep passes.

### Learning
Generating docs/DIRECTORY.md via python scripts/generate_directory.py and verifying freshness in python scripts/lint_gdscript.py keeps AI navigation accurate and prevents drift.

### Guideline
Run python scripts/generate_directory.py whenever creating, renaming, or refactoring files, and run python scripts/lint_gdscript.py before opening PRs.

## <a id="lrn-091"></a> LRN-091: Dashboard Task Chronological Sorting
- **Task:** TASK-TOOLING
- **Category:** tooling
- **Created:** 2026-09-02T18:45:13.077114
- **Tags:** 

### Context
Users expect kanban boards and task matrix columns to display the most recently updated tasks at the top rather than requiring scrolling down past older completed tasks.

### Learning
Tracking task file mtime with task index/number fallback allows automatic chronological ordering in both generated static HTML and interactive browser client views without manual reordering in master markdown tables.

### Guideline
In visual task boards, default to descending sort by modification timestamp and task ID so newly created and updated tasks are immediately visible at the top of each column.

## <a id="lrn-092"></a> LRN-092: Interactive Task Details Modal and Branch Command Sanitization
- **Task:** TASK-056
- **Category:** tooling
- **Created:** 2026-09-02T19:09:50.762025
- **Tags:** 

### Context
When adding interactive task modals to the HTML visual task board that display packet details and allow copying checkout commands, raw markdown backticks around branch names break terminal shell execution in bash/zsh command substitution.

### Learning
Always strip markdown formatting backticks from parsed branch names before generating clipboard shell commands and displaying branch labels, and provide graceful clipboard promise error handling for non-secure contexts.

### Guideline
When parsing tabular metadata from markdown files for dashboard shell integrations, sanitize command strings by stripping backticks and wrapping clipboard write calls with error handlers.

## <a id="lrn-099"></a> LRN-099: Dashboard Kanban Drag and Drop Task Progression
- **Task:** TASK-061
- **Category:** tooling
- **Created:** 2026-09-03T10:57:54.669944
- **Tags:** 

### Context
Adding interactive drag-and-drop to the dashboard to update task status in TASK-*.md and README.md

### Learning
Using HTML5 drag events on cards with drop zones on Kanban columns connected to a local Python HTTP server allows browser-based task updates with zero dependencies and instant visual feedback.

### Guideline
When adding local file write actions from a web dashboard, provide a lightweight localhost HTTP server with CORS headers so direct file:/// and localhost browser sessions can update project markdown files safely.

## <a id="lrn-100"></a> LRN-100: Dashboard Parked Ideas Status and Kanban Column
- **Task:** TASK-062
- **Category:** tooling
- **Created:** 2026-09-03T11:05:57.964263
- **Tags:** 

### Context
Adding a dedicated Parked Ideas column to the task matrix dashboard

### Learning
Adding a dedicated PARKED column to the 5-column Kanban grid with a distinct purple color scheme gives a clear area for ideas on hold, distinct from the active backlog.

### Guideline
When expanding Kanban workflow states, update VALID_STATUSES in the updater server, the HTML template grid, the filter dropdowns, and modal transition controls so all interaction paths stay aligned.

## <a id="lrn-101"></a> LRN-101: Dashboard Task Card Category Chips and Clutter Reduction
- **Task:** TASK-064
- **Category:** tooling
- **Created:** 2026-09-03T11:13:20.033747
- **Tags:** 

### Context
Removing truncated branch paths from small task cards and simplifying verbose categories into standardized color chips

### Learning
Displaying truncated branch strings on compact cards creates visual clutter without providing utility; mapping raw subcategories into high-level colored discipline chips (UX, UI, Art, Design, Coding, Planning) improves card legibility and scannability while keeping full branch details in the modal.

### Guideline
On compact Kanban cards, omit long technical metadata like branch names that get truncated; use clear color-coded discipline badges and provide detailed technical paths inside an inspection modal.

## <a id="lrn-111"></a> LRN-111: in_game_machinery_components_dashboard
- **Task:** TASK-069
- **Category:** tooling
- **Created:** 2026-09-03T21:56:46.074981
- **Tags:** 

### Context
Creating a companion dashboard to the physical pinball research board to document in-game component art and behavioral physics.

### Learning
Pairing in-game vector art illustrations and precise collision and impulse statistics with direct links to physical pinball machine counterparts creates an intuitive bridge between design research and gameplay mechanics.

### Guideline
When building research and tooling companion dashboards, maintain consistent visual branding and cross-navigation links while keeping HTML source files strictly under the 500-line project threshold.

## <a id="lrn-114"></a> LRN-114: debug_board_machinery_showcase
- **Task:** TASK-073
- **Category:** tooling
- **Created:** 2026-09-08T13:06:57.019031
- **Tags:** 

### Context
Showcase all 33 machinery variants and permutations on the 15x8 board grid with detailed tooltips without bloating board.gd or leaking debug metadata to campaign relics.

### Learning
Extracting showcase definitions, layout calculation, and tooltip formatting into an isolated helper class (BoardMachineryShowcase) isolates debug inspection logic and keeps board.gd well under baseline limits.

### Guideline
Use dedicated showcase helper classes to build debug playfield configurations and format specialized inspection tooltips without modifying core game logic or leaking metadata to standard campaign items.

## <a id="lrn-136"></a> LRN-136: Workspace Skills and Progressive Disclosure Architecture
- **Task:** TASK-095
- **Category:** tooling
- **Created:** 2026-09-13T20:52:11.980930
- **Tags:** 

### Context
Agents authoring repetitive ad-hoc scripts across tasks for task packets and multi-pass quality audits

### Learning
Antigravity discovers workspace skills in .agents/skills/ and progressively discloses full skill contents only when activated, keeping the initial prompt small

### Guideline
Keep YAML frontmatter descriptions concise in SKILL.md and encapsulate multi-pass pipelines into reusable scripts under scripts/

## <a id="lrn-142"></a> LRN-142: Runtime relic variant audit
- **Task:** TASK-100
- **Category:** tooling
- **Created:** 2026-09-20T21:58:35.624216
- **Tags:** 

### Context
Authored catalog shapes differ from normalized runtime layouts.

### Learning
G-O-B and P-O-P share runtime lanes; spinner pairs also share normalized layouts. The design draft compares runtime definitions.

### Guideline
Audit create_module_for_relic output when comparing variant geometry; keep proposed reward changes separate from gameplay approval.

