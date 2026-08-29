# TASK-034: Repetitive Sound Effect Pitch Randomization

- **Status:** READY
- **Priority:** P1
- **Category:** Audio / Polish
- **Target Branch:** `feature/repetitive-sfx-pitch-randomization`
- **Related Tasks:** [TASK-032](TASK-032-relic-audio-level-balancing-and-attenuation.md)

## Description

Apply random pitch modulation on a narrow band to all repetitive sound effects.
This prevents acoustic fatigue and gives natural audio variation during gameplay.

---

## Requirements

### 1. Central Pitch Randomizer Utility
- Create a reusable audio utility to play sound effects with random pitch modulation.
- Define a standard narrow pitch band (for example: between 0.95 and 1.05).
- Allow configuration of the pitch range for different sound categories when necessary.

### 2. Gameplay Sound Effect Integration
- Apply narrow band pitch randomization to frequent sound effects:
  - Peg collision and bounce sounds.
  - Polyomino kinetic machinery activations.
  - Cannon firing and ball launch cues.
  - Wall impact and damage tick sounds.
  - Frequent user interface interaction sounds.

### 3. Concurrency Throttling and Limits
- Keep timestamp-based concurrency throttling to prevent sound stacking during fast collisions.
- Calculate pitch modulation independently on each sound activation.

### 4. Audio Bus Routing and Volume Limits
- Route all repetitive sound effects through dedicated audio buses (`SFX`, `Machinery`, `UI`).
- Keep balanced volume levels to prevent loud sound spikes.

### 5. Automated Tests
- Add headless unit tests in `tests/test_audio_pitch_randomizer.gd`.
- Verify that pitch randomizer values stay within the narrow band.
- Verify that repeated sound activations produce varied pitch values.
- Verify that audio players assign to the correct audio bus.

---

## Acceptance Criteria

- [ ] A shared utility applies narrow band pitch randomization to sound effects.
- [ ] Repetitive sound effects across gameplay use randomized pitch modulation.
- [ ] Pitch values stay strictly within the narrow band to prevent sound distortion.
- [ ] Concurrency throttling prevents audio clipping during simultaneous collisions.
- [ ] Headless unit tests verify pitch ranges and bus assignments.
