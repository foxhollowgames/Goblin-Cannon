# Task 93: Ball Flow Review and Implementation Contract

## Design goal

The player builds a readable energy machine. Each passage device has an entrance, an internal action, a reward condition, and an exit. Solid impact devices remain open to external hits. Space between devices is part of the design.

## Confirmed findings

- Divided lanes generate a closed perimeter. The existing enclosure test requires this behavior.
- Default funnel geometry is rebuilt against screen axes after rotation, so openings do not follow the original device.
- Custom wall edges can add walls but cannot remove them.
- Several catalog chambers use an open frame without guiding walls.
- Cyclone Bounce Vault assigns two bumpers outside its footprint.
- Generic hit thresholds run before route and spinner goal logic.
- Guide rails instantiate a guided track rather than a physical deflection wall.
- Reservoir capacity and the module hit threshold can disagree.
- Reservoirs have no underfilled recovery release.
- Energy surge rewards overwrite ball velocity with an upward launch. This can undo a device's intended exit direction.
- The complete relic ID list omits new catalog-only IDs.
- Placement checks occupied cells, but not directly obstructed ports.
- Tests activate components directly and do not prove full physical routes.

## Physical contracts

| Family | Path | Completion |
| --- | --- | --- |
| Word bank | Open parallel lanes with accessible switches | Each distinct switch is lit; reset after reward |
| Bumper chamber | Side rails, spaced bumpers, lower drain | Defined bounce count; preserve ball circulation |
| Reservoir | Open catch area and gated outlet | Capacity release; timeout release has no completion bonus |
| Spinner | Entrance feeds blade area; outlet stays clear | Actual speed threshold with a cooldown |
| Wedge | Exposed angled impact face | Defined charge followed by one detonation |
| Bash toy | Exposed target with bypass space | Defined hit count followed by one break reward |
| Track | Ordered path with entrance and exit | The same ball completes the path and leaves |

## Validation requirements

- Audit both catalogs and serialized module definitions.
- Check rotated entrance and exit geometry and explicit wall removal.
- Check that every component belongs to its reserved footprint.
- Check every required letter can be reached from outside.
- Check ball passage with actual physics bodies, including crowding and fast entry.
- Check reservoir conservation, timeout recovery, and removal while occupied.
- Check route completion cannot occur from one intermediate contact.
- Check rewards do not reverse intended exit velocity.
- Check port visibility during placement and directly blocked connections.
- Exercise a reservoir, spinner, and chamber chain.
- Complete repository quality checks and independent PR review.

## Baseline

The pre-change headless suite reports 12,562 passed assertions and zero failed assertions. It also reports leaked physics/rendering objects and resources at exit. These warnings predate this iteration.

## Implementation status

The user authorized direct implementation after the final Qwen retry failed. The implementation covers both catalogs (122 unique relic IDs), shared rotated walls and ports, open lanes, chamber drains, reservoir recovery, speed-based spinner rewards, and completed track traversal.

Real physics tests cover all four lane rotations, five chamber entry positions, two shaped tracks, both orbit entrances, full and partial reservoirs, and a reservoir/spinner/chamber chain. The synchronous suite passes 16,350 assertions. Quality checks pass with the existing repository baseline exceptions. Independent review is pending.

Catalog layouts change at item creation. Placing an existing item does not silently expand its stored footprint. Existing serialized custom layouts retain their cells; start a new run to use the revised catalog layouts.

Compact tier variants retain their existing footprints where those were intentionally smaller than the original tier size bands. Tests now include these catalog entries instead of excluding them from the roster.

Visual reference: [live devices and shop previews](relic-flow-preview.png).
