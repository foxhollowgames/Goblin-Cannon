# Ball bounce debug plan – why it slides instead of bouncing

## Problem
The ball slides from peg to peg with no visible bounce, despite deterministic bounce code (reflect normal, restitution, tangential friction).

## Hypotheses

### 1. Coordinate space mismatch
- **Velocity** is in the ball’s local space (used by `move_and_collide(motion)`).
- **Normal** `n` is from `global_position - peg_global`, so it’s in **global** space.
- If the ball’s parent (BallsContainer) has any rotation or we ever mix spaces, `velocity.dot(n)` is wrong and the reflected velocity can be incorrect (e.g. no upward component).
- **Fix**: Do all bounce math in global space: transform velocity to global, compute reflection, transform new velocity back to local.

### 2. Normal or impact condition wrong
- Geometric normal (peg→ball) might not match the actual contact normal when the ball is grazing, so we might treat the impact as “moving away” (`v_dot_n > 0`) and skip the bounce.
- **Fix**: Use Rapier’s contact normal `col.get_normal()` for the bounce direction (with geometric fallback). Apply a minimum outward speed whenever we’re in contact and moving into the peg.

### 3. Bounce too weak or cancelled
- Minimum bounce speed might be too low, or tangential friction might be so high that the horizontal component dominates and it looks like sliding.
- **Fix**: Tune for Peglin-like feel: stronger minimum bounce, restitution ~0.75–0.82, moderate tangential friction (~0.2–0.3) so the ball clearly pops off pegs but doesn’t slide forever.

### 4. Debug to confirm
- Add optional debug (e.g. first collision per second) to log: `v_dot_n`, `outward_speed`, velocity before/after. Confirms whether the bounce block runs and with what numbers.

## Target behavior (Peglin-like)
- Clear reflection off each peg (angle of incidence → angle of reflection).
- Bounciness scales with impact speed (restitution).
- Some energy loss each bounce so the ball eventually settles.
- Not “sticky” and not pure sliding – visible arc and pop off pegs.

## Execution
1. Do bounce in global space (transform velocity ↔ global).
2. Use collision normal from `col.get_normal()` with geometric fallback.
3. Guarantee minimum outward speed on impact; tune constants.
4. Add optional `DEBUG_BOUNCE` print to verify values at runtime.
