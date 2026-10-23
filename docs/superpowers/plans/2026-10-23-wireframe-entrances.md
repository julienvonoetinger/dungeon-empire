# Four wireframe entrances — implementation plan

> **For agentic workers:** Execute inline with superpowers:executing-plans. Preserve the existing user work in this checkout.

**Goal:** Add the three other stair directions and update the closed-corridor Godot test scene to show all four.

**Architecture:** Offline export produces four complete neutral wireframe textures from the reviewed stair geometry. Godot selects one prepared image for a closed terminal cell when the scene opts into entrances; it does not build geometry or rotate images.

**Tech Stack:** Node.js vector export, Godot 4 GDScript/Sprite2D.

**Spec:** User request of 2026-10-23 and `docs/reference/ENTRANCE_STAIRS.md`.

## Constraints and review focus

- Square 1x1 grid; T=1/6, H=1.88/6, J=.94/6; projection (x-.18z,y-.9z).
- Five equal .05 risers, original .84 landing boundary; rotate world coordinates only.
- Complete prepared images, white modulation, no runtime clipping or geometry.
- Remove internal end faces; preserve the shared 256px pitch and (24,88) anchor.
- Preserve local 19-slab paving orientation and neutral style in each terminal.
- Inspect all four ends in Godot, especially north-facing stairs behind the south wall.
- Other scenes default to their existing ordinary terminal cells.

## Steps

- [x] Export `assets/dungeon/wireframe-entrances/{north,east,south,west}.svg`, manifest and `scripts/wireframe_entrance_catalog.gd` using `tools/export_wireframe_entrances.cjs`. Names identify the OPEN/downhill side.
- [x] Add `entrance_at_closed_ends=false` to the shared study renderer. Map only w14/w13/w11/w07, p00/e00 to complete entrance sprites. Skip the separate floor and wall sprite for these cells.
- [x] Enable the setting in `WireframeClosedCorridors.tscn` (same 17 cells). Import with mipmaps.
- [x] Capture actual Godot views at 1x/2x and inspect all directions and a scene without entrances.
- [x] Update current repository guidance, workflow and GAME_DESIGN section 0.

## Execution record

- Ruling: continue in the current feature checkout — the preceding approved staircase work is uncommitted here and is the input for this requested integration.
- Ruling: verification targets the requested appearance through import and actual GPU captures; do not add unrelated gameplay/unit tests or change gameplay.
- No commit or push requested in this turn.
- Completed: offline export/import and actual GPU captures returned exit 0. `artifacts/entrances-details.log` reports four complete entrance sprites. `WireframeClosedCorridors` and `2x2CellRoom` captured at 1x/2x; all four enlarged endpoint images inspected.
- Visual correction: omit hidden/internal fill faces; restore the standard north/west port cap and upper-course masonry joints. The rotated isolated source omitted those shared joints, leaving a faint partial alpha boundary. Final images have the same joint ownership as ordinary wall cells.
- Fresh read-only review `/root/review_four_entrances`: no remaining Critical/Important findings after the joint correction; documentation follow-up completed. Artistic acceptance remains the user's review.
