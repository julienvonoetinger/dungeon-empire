# Isometric kit migration implementation plan

> **For agentic workers:** Use superpowers:executing-plans for inline execution.

**Goal:** Migrate the complete existing kit and Godot visual scenes to the
approved 2:1 projection, retaining logical 1x1 occupancy and offline sprites.

**Architecture:** Reusable XYZ geometry supplies a separate prepared isometric
catalogue. Catalogue projection metadata drives placement, depth priority and
coordinate conversion in the common renderer. Existing layouts use that renderer.

**Tech stack:** Node.js/Sharp offline SVG/PNG preparation; Godot GDScript atlas
placement; frozen JSON geometry and reviewed PNG references.

**Spec:** `docs/reference/isometric-review/wireframe-v1/selection.json` and
`README.md`; user explicitly requested migration after accepting that view.

## Global constraints

- Projection `256*((x-y)/2,(x+y)/4-sqrt(3/8)*z)`, logical 1x1, fixed zoom .75.
- Preserve layouts, including SixRoomPreview's two-cell corridors, two wall courses,
  nested door arches and smooth recessed infill, four stair directions.
- Preserve approval snapshots and source art. Never alter frozen hashes to pass checks.
- Export prepared sprites only. Runtime computes positions/order, not images/meshes.
- No automatic tests added/run, per developer instruction. Use rendering/import and
  visual captures to deliver this visual migration; do not call these test suites.
- No commit or push requested. Work in the existing `codex/2d-foundation` checkout
  containing the uncommitted approved references; leave attachment/cache files alone.
- User explicitly chose wireframes first in the async reply. Painted exports are
  a later phase; retain approved painted sources without reusing their old camera.

## Review focus

- Floor diamonds meet without doubled outlines or transparent seams.
- Horizontal/vertical walls, exposed endpoints and concave corner pillars join.
- All four nested doors preserve both arches and smooth infill without extra rings.
- Stairs, heart support and torch mounts share the approved coordinate system.
- Native/editor framing, special-location captures and foreground sorting use the
  new projection; old frozen review catalogues retain their own metadata defaults.

## Tasks

- [x] 1. Add shared offline isometric geometry/projection and hidden-line export;
      produce floor, walls, pillar, four doors, four stairs and prop wireframes.
- [x] 2. Pack the prepared catalogue, retain geometry/guides, document source hashes.
- [x] 3. Migrate common runtime placement, light positions, camera centering and
      coordinate conversion; select the new catalogue for all active scenes.
- [x] 4. Import and capture active scenes at fixed scale plus overviews; inspect
      key joins, props and all four special orientations. Repair concrete issues.
- [x] 5. Update source/export graph, docs and migration scope; request one independent
      read-only review per executing-plans, resolve findings and report evidence.

## Execution ledger

- Setup: existing branch is codex/2d-foundation; work remains uncommitted.
- Ruling: execute the user-authorized migration here, without a second plan approval
  or a new checkout that would omit the approved uncommitted geometry.
- Ruling: TDD/automatic commit steps in skills yield to developer/user constraints.
- Pre-flight: new catalogue must expose the same sprite IDs/companions/bounds used
  by mobile_dungeon_renderer, plus projection vectors. Capture cameras must use
  the same coordinate conversion as scene camera centering.
- Task 1/2: complete. Source camera approval hashes preserved; 25 prepared sprites,
  matching guides/geometry, 1024-square atlas 99844 bytes. Original painted kit
  unchanged. Heart schematic and rigid torches only, as explicitly selected.
- Task 3: complete. Shared projection/inverse, positions, support depth and native
  cameras updated. Layouts unchanged. Editor reload targets isometric assets.
- Ruling: split door into upper/lower composites at H after mutual hidden-line
  removal. Original eight interlocking parts had an observed sorting artifact in
  the first capture. No shape change; cost is different texture-region grouping
  to retain when preparing paint. Four final door orientations inspected.
- Task 4: 68 runtime captures / 23 scenes; 21 editor captures / five scenes.
  Runtime import/capture clean, editor has documented native shutdown diagnostics.
- Task 5: 45 source dependencies / 23 scenes; staging import/export/startup exit 0,
  empty stderr. Resource ZIP 138791 bytes. Docs and logs saved under migration-v1.
- Final review: one stale authored SingleCellRoom camera. Regraded as necessary
  to the requested all-scene preview migration; corrected and visually inspected
  in a fresh editor capture. No further findings or deferred minors. No tests
  added/run, and no second review, commit, push or cache reset performed.
