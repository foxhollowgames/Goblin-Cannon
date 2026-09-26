# audio-and-mechanics

[Learning index](../LEARNINGS.md)

## <a id="lrn-015"></a> LRN-015: Relic Audio Attenuation and Boundary Wall Physics Architecture
- **Task:** TASK-032
- **Category:** audio_and_mechanics
- **Created:** 2026-08-29T08:18:05.426562
- **Tags:** 

### Context
Defining requirements for reducing loud sound playback on kinetic components and adding perimeter boundary walls with internal lane dividers to polyomino relics.

### Learning
Kinetic polyomino machinery produces rapid audio triggers during high ball volume, requiring dedicated bus attenuation and edge collision segment specifications.

### Guideline
Always route machinery audio to dedicated sub-buses with volume limits, and define perimeter walls and internal dividers as explicit edge segment shapes.

## <a id="lrn-019"></a> LRN-019: Relic Machinery Audio Attenuation and Concurrency Throttling
- **Task:** TASK-032
- **Category:** audio_and_mechanics
- **Created:** 2026-08-29T09:42:05.941172
- **Tags:** 

### Context
Kinetic polyomino machinery caused rapid audio triggers and harsh volume spikes during multi-ball collisions.

### Learning
Setting default component volume to -16 dB, routing to a dedicated Machinery bus, applying slight pitch modulation [0.95, 1.05], and throttling duplicate triggers within 50ms produces clean acoustic mixing.

### Guideline
Always route kinetic machinery audio through dedicated sub-buses with decibel levels below -12 dB, apply pitch variation, and enforce timestamp-based concurrency throttling.

