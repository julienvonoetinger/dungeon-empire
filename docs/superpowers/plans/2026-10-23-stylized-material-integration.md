# Stylized material integration plan

> Execution: use superpowers:executing-plans inline in the existing user workspace.

**Goal:** Apply the texture family the user approved to the existing dungeon kit.
**Architecture:** Promote the exact approved source atlas, crop regions and render
profiles into the active shared-material recipe. Re-export prepared PNGs for
isolated review and connected Godot scenes using the unchanged compositor.
**Stack:** Node.js, sharp, existing offline exporters, Godot import.
**Spec:** `docs/reference/stylized-material-review/recipe.json` and the user's
approval: "oui utilise cette nouvelle gamme de texture".

## Constraints

- Exact approved material pixels and profiles; existing iron retained.
- Preserve 1x1 cells, projection, outlines, alpha masks, paving, anchors and aliases.
- Godot continues selecting complete prepared sprites, with white modulation.
- Keep older proposals historical; new default preparation must use this family.
- No new tests or test suites requested. Use built-in export diagnostics and
  normal Godot resource import; present an updated scene image for the user.
- No commit/push requested in this turn.

## Steps

- [x] Save a durable active recipe, atlas/reference copies and generation provenance.
  Update `tools/prepare_shared_stone_materials.cjs` to read that recipe and reproduce
  the active root material files, correct hashes/statistics and material board.
- [x] Run preparation and both existing painted exporters. Their built-in reports
  record unchanged source joints and model alpha. All 57 isolated and 96 connected
  structural images plus floor are re-exported.
- [x] Update AGENTS, material workflow, Godot guide and game design's implemented
  visual state. Record the reviewed family as accepted, not all future appearances.
- [x] Import the changed textures into Godot and produce an updated preview image.
  Report actual results and any limitations without claiming tests were run.

## Results

- Ten prepared crops match the exact approved hashes. Both approved NW and north
  door sprites reproduce byte-identically in the refreshed isolated catalogue.
- Both exporters exited 0: 57 isolated sprites, 96 connected structural sprites,
  128 connected IDs, 16 empty states and one floor. Built-in reports retain all
  source joints with zero model-alpha differences. Floor frame remains 1024x1024,
  anchor (0,0), 26 source segments.
- Godot import exited 0 with empty stderr. Updated preview images were produced
  for 3x3CellRoom, WireframeDoorCross, WireframeClosedCorridors and SixRoomPreview.
  Preview capture exited 0 with empty stderr; no test suite was run.
- Read-only final review found one stale active-library paragraph; its former
  quarter-atlas instructions were replaced with the exact active recipe.
- Runtime code, geometry sources and scene files remain unchanged. Existing
  shared texture paths supply the new family to all 20 architecture scenes.
- Logs and screenshots: `artifacts/stylized-*`, `artifacts/wireframe-*.png`.
