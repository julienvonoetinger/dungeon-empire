# Isometric wall variants implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline. Steps use checkboxes for tracking. User explicitly requested implementation of the shown nine concepts; no additional approval round is needed.

**Goal:** Integrate A1–A3, C1–C3 and F1–F3 in production layouts, with stable varied placement and compatible isometric wall/pillar joins.

**Architecture:** Offline project the accepted art onto the common wall geometry, with explicit source-plane calibration, revised joint layouts and shallow physical relief for C. Prepare both orientations and all four pillar-end profiles. Corruption remains an optional prepared surface layer with its masonry backing, placed on a bare structural wall; preserve source drawings and earlier approved snapshots.

**Tech Stack:** Existing Node/Sharp offline preparation, Godot 4 prepared atlas renderer, GDScript static distribution.

**Spec:** `docs/reference/isometric-wall-variation-review/v2-subvariants/README.md`, user: “ok implémente ces murs”. The nine displayed appearances are selected as directions; the common geometry adaptation is necessary for production joins.

## Global constraints

- Keep 2:1 projection, 256 source pixels per logical cell, .75 camera zoom, free pan and layouts.
- Keep two wall courses, original wall height/thickness and pillar terminal coordinates. Relief may extend locally toward the visible wall face, away from endpoints.
- No regenerated accepted art, runtime rasterization, per-frame random selection, or destructive history changes.
- Preserve the ongoing work in this feature checkout; moving only HEAD would omit the uncommitted isometric migration and its ignored source evidence. No commit or push requested.
- Repository instruction prohibits automated tests without a user request. Use offline geometry/pixel assertions and Godot visual captures/import/export, not a new test suite.

## Review focus

- All end profiles and mixed variants must remain connected to pillars and adjacent walls.
- Both visible orientations must sample source planes consistently; relief must not create ordering holes.
- Torch mounts and doors must retain quiet supporting walls; avoid stacking damage on raised/corrupted art.
- Negative coordinates, seed restoration and different Dictionary iteration orders must retain stable choices.
- Packed pixel regions and unrelated assets must remain valid after atlas repacking; export must include the new selector.

### Task 1: Freeze and prepare selected artwork

- [x] Record selection of nine sources, comparison and prompts; snapshot active catalogue/atlas and relevant implementation.
- [x] Create `tools/isometric_wall_variants.cjs`: explicit source calibration and joint/relief definitions; prepare both wall axes × four endpoint profiles, guides and geometry. Preserve all old snapshots.
- [x] Produce prepared comparison/overlay/join boards; inspect at .75 and enlarged scale, check source hashes and terminal bounds.

### Task 2: Integrate and distribute

- [x] Extend `tools/export_isometric_painted_kit.cjs` to pack prepared variants/layers with metadata, without changing old prepared pixels.
- [x] Add `scripts/dungeon_wall_variants.gd` with deterministic coordinate/seed choices, neighbour exclusions for accents and quiet special/torch supports.
- [x] Add inspector properties and explicit scene opt-in, preserve review defaults off. Apply structural variants before ordering; draw corruption layer immediately after its host. Keep old damage on compatible bare hosts only.
- [x] Verify import and focused renders: all variants/orientations/endpoints, seed restoration, small room, corridors, specials and torches.

### Task 3: Review and deliver

- [x] Capture all production scenes and representative editor scenes with existing capture tools; inspect selected joins and accents.
- [x] Fresh resource stage/import/export/startup; record atlas size and package size honestly.
- [x] Focused independent read-only code/visual review per requesting-code-review; resolve concrete findings and update evidence/docs/AGENTS.
- [x] Deliver actual Godot preview and measured asset impact; leave commit/push to a separate request.

## Execution record

Implemented in the existing feature checkout to preserve the active uncommitted migration. User's later colour correction supersedes the initial source palette: common per-plane stone grading is applied offline. No source regeneration, test suite, commit or push. Focused independent review found no actionable issue. Integrity/capture/export evidence is in the integration directory; final adapted appearance remains for user judgment.
