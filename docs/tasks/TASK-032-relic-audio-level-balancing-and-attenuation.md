# TASK-032: Relic Audio Level Balancing and Volume Attenuation

- **Status:** READY
- **Priority:** P1
- **Category:** Audio / Balance
- **Target Branch:** `feature/relic-audio-balancing`
- **Related Tasks:** [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md)

## Description

Reduce audio playback volume levels on all polyomino relic machinery components.
Add concurrency throttling to prevent loud sound spikes during heavy ball collisions.

---

## Requirements

### 1. Base Volume Reduction
- Reduce the default volume level (`volume_db`) on all kinetic machinery components:
  - `PinballBumper`
  - `ManaSiphon`
  - `SpeedBoostWheel`
  - `DirectionalDeflector`
- Lower standard baseline target decibel levels from `-6.0 dB` to a range between `-14.0 dB` and `-18.0 dB`.

### 2. Dedicated Audio Bus Routing
- Route machinery sound effects through a dedicated audio bus (`SFX` or `Machinery`) rather than the `Master` bus.
- Allow centralized volume adjustment for all relic machinery components.

### 3. Concurrency Limiting and Sound Throttling
- Add a global or component audio throttle to prevent sound stacking when many balls collide simultaneously.
- Set a minimum time interval between identical audio triggers across the board.

### 4. Pitch Modulation
- Apply slight random pitch modulation (`pitch_scale` between `0.95` and `1.05`) on each activation.
- Prevent acoustic repetition and audio fatigue during high ball volumes.

### 5. Automated Tests
- Add headless unit tests in `tests/test_relic_audio_levels.gd`.
- Verify that default component volume levels remain below `-12.0 dB`.
- Verify that audio players assign to the correct audio bus.

---

## Acceptance Criteria

- [ ] Relic machinery component sound effects play at comfortable, reduced volume levels.
- [ ] Sound effects route through a dedicated machinery audio bus.
- [ ] Multiple simultaneous collisions do not cause audio clipping or harsh volume spikes.
- [ ] Pitch modulation varies sound playback naturally.
- [ ] Headless unit tests verify audio configuration and volume limits.
