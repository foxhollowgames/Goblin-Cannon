# TASK-007: Git Branch and Pull Request Protocol

- **Status:** DONE
- **Priority:** P0
- **Category:** DevOps
- **Target Branch:** `feature/roadmap-and-task-management`

## Description

Establish tight version control standards for all repository changes.
Require dedicated feature branches, passing unit tests, and GitHub Pull Requests for every modification.

## Rules and Procedures

1. **Branch Naming:**
   - Use `feature/<task-name>` for new features.
   - Use `fix/<issue-name>` for bug fixes.
   - Use `docs/<doc-name>` for pure documentation updates.

2. **Pre-Commit Verification:**
   - Run headless tests before committing:
     ```powershell
     & "C:\Users\josep\Desktop\Games\Godot_v4.6.1-stable_win64.exe" --headless -s tests/run_tests.gd
     ```
   - All tests must pass before opening a Pull Request.

3. **Pull Request Requirements:**
   - Create PR using GitHub CLI (`gh pr create`).
   - Write clear summary of changes, motivation, and verification results.
   - Link relevant task files from `docs/tasks/`.

4. **Sub-Agent Blind Review Protocol:**
   - Launch an independent sub-agent without conversational context to inspect the PR diff.
   - The sub-agent examines code quality, tests, and documentation.
   - If the sub-agent finds major issues, resolve the findings and request a new review.
   - Repeat the review cycle until zero major findings remain.
   - Merge the pull request into `main` only after the sub-agent approves the changes.

## Acceptance Criteria

- [x] Branch and PR workflow is documented and active.
- [x] Sub-agent blind review protocol is defined.
- [x] Feature branch created for initial task and roadmap baseline.
- [x] Pull Request created and linked to repository on GitHub.

