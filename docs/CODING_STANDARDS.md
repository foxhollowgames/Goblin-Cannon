# GDScript Coding Standards & AI-Friendly Guidelines

## 1. File Structure Order

Every `.gd` file must follow this section order:

```gdscript
extends Node2D
## File-level docstring: one line that states the single responsibility.

# 1. Signals
signal something_happened(arg: int)

# 2. Constants and enums
const MAX_VALUE: int = 100
enum State { IDLE, ACTIVE, DONE }

# 3. Exports
@export var speed: float = 100.0

# 4. Public variables
var health: int = 100

# 5. Private variables (underscore prefix)
var _internal_counter: int = 0

# 6. Lifecycle methods (_ready, _process, _physics_process, _draw, _input, _exit_tree)

# 7. Public methods

# 8. Private methods (underscore prefix)
```

---

## 2. Type Annotations on All Signatures

Every function parameter, return type, and variable declaration must have an explicit type annotation.

```gdscript
# CORRECT
func apply_damage(amount: int, source: Node) -> void:
    var remaining: int = _health - amount

# WRONG — missing types
func apply_damage(amount, source):
    var remaining = _health - amount
```

---

## 3. Function Length Limit (45 lines)

No function body may exceed **45 lines** (excluding blank lines and comments). Extract helper functions when a function grows past this limit.

---

## 4. Docstrings on Public Functions

Every public function (no underscore prefix) must have a `##` docstring on the line before `func`.

```gdscript
## Applies damage to this peg. Returns true if the peg was destroyed.
func apply_hit(amount: int) -> bool:
```

---

## 5. Region Tags for Navigation

Use `#region` / `#endregion` tags (Godot 4.2+) to group related code inside a file. Name each region after its responsibility.

```gdscript
#region Peg Suppression
func _suppress_peg(peg: Node, cell: Vector2i) -> void:
    pass
#endregion
```

---

## 6. Inline Dictionary Type Comments

Every `Dictionary` variable must have a type comment:

```gdscript
var _hit_cooldown: Dictionary = {}  ## (int, int) -> int  # (ball_id, peg_id) -> last_hit_tick
```

---

## 7. No Magic Numbers

All gameplay numeric values must be named constants in `Constants` or as local `const` declarations.

---

## 8. Signal Naming Convention

Signals use **past tense** for events that already occurred, and **present tense** for requests:

```gdscript
signal ball_reached_bottom(...)   # Past tense: it already happened
signal damage_requested(...)      # Present tense: a request to do something
```

---

## 9. Call-Down, Signal-Up Architecture

Scripts must not call `get_node()` or `$` to reach nodes in unrelated scene-tree branches. Use:
- Signals (up)
- Method calls from parent (down)

---

## 10. Automated Quality & Directory Checks

Before submitting a PR:
1. Run `python scripts/generate_directory.py` if file structure or signatures changed.
2. Run `python scripts/lint_gdscript.py`.
3. Run `godot --headless -s tests/run_tests.gd`.
