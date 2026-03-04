---
name: bug-fix
description: Fix bugs by evaluating context, diving into the code, reproducing the bug, determining root cause, forming a plan, executing it, verifying the fix, and summarizing. Use when the user reports a bug, says something isn't working, or asks to fix or debug.
---

# Bug Fix

## When to apply

- User reports a bug or unexpected behavior
- User says "not working", "broken", "wrong", "same behavior", "still seeing..."
- User asks to "fix", "debug", or "figure out why"

## Workflow (follow in order)

### 1. Evaluate context

- Gather what the user said: symptoms, steps, what they expected vs what they see.
- Note which area of the product is affected (e.g. ball physics, UI, save/load).
- State any assumptions if details are missing.

### 2. Dive into the code

- Open and read the relevant files (scenes, scripts, resources).
- Trace the code path: where is the behavior implemented? Who calls it? What data flows in and out?
- Search for related logic (e.g. same node type, same signal, same constant).
- Do not change code yet; only read and trace until the bug is understood.

### 3. Reproduce the bug (in code / logic)

- Use the code and context to reason through how the bug can occur (e.g. "when X is true and Y runs, Z never gets set").
- If the project can be run or tested, consider what would need to happen to trigger the bug.
- Confirm you can explain the faulty behavior from the code path you found.

### 4. Determine root cause

- Identify the single cause (wrong condition, wrong API, missing init, wrong coordinate space, etc.).
- If multiple possibilities remain, pick the most likely and note that you are fixing that first.
- Do not form the fix plan until you have a clear root cause.

### 5. Form a plan

- Write a short, concrete plan: what will be changed and in which files.
- Keep the plan minimal (no unrelated refactors).
- Example: "In `ball.gd`, use global velocity for the bounce dot product; in `ball.tscn`, no change."

### 6. Execute the plan

- Make the planned code (or config) changes.
- Do not add extra "improvements" unless they are required for the fix.

### 7. Verify the fix

- Run the linter on changed files if applicable.
- Run the game or tests if possible, or state how the user can verify (e.g. "Run the game and drop a ball; it should bounce off pegs").
- If verification fails, return to step 4 (re-evaluate root cause) and repeat.

### 8. Summarize

- Provide a short summary for the user:
  - **What was wrong** – The root cause in plain language.
  - **What was changed** – Which files and what was done.
  - **How to verify** – What they should do or see to confirm the fix.

## Summary template (use at the end)

```markdown
**Root cause:** [One sentence]

**Changes:** [Files and what was done]

**Verify:** [How to confirm the fix]
```

## Guidelines

- Do not skip to coding before reproducing and identifying root cause.
- One root cause per fix cycle; if the bug persists, start again from step 2.
- No unrelated edits or refactors unless the user asks.
