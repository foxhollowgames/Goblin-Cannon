# TASK-016: Typography and Comic Text Effect Specifications

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Direction / UI
- **Target Branch:** `feature/comic-typography`

## Description

Define and implement the typography palette, comic sound effect lettering, and combat floating text.

## Core Requirements

1. **Font Hierarchy:**
   - Primary Header Font: Bold, punchy comic title font.
   - Body & Stats Font: High-legibility technical font for descriptions and numerical stats.
   - Dialogue & Narrative Font: Comic dialogue font for cutscene text bubbles.
2. **Onomatopoeia Sound Effect Overlays:**
   - Stylized action lettering for weapon impacts and explosions ("BOOM!", "KAPOW!", "ZAP!", "CLANG!").
3. **Floating Combat Text:**
   - Comic-styled floating damage numbers, critical hit popups, and status alerts (Burn, Freeze, Shock).

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Font Selection:** Use open-source comic fonts (e.g. Bangers, Komika, Anime Ace) paired with crisp sans-serif fonts for UI data tables.
> - **Text Bounce Animation:** Implement scale-punch animations with rotation jitter on damage popups.

---

## Acceptance Criteria

- [ ] Font assets licensed, imported, and configured in Godot theme resources.
- [ ] Onomatopoeia sprite overlays trigger dynamically during cannon impacts and wall hits.
- [ ] Floating combat text displays legibly across all supported screen resolutions.
