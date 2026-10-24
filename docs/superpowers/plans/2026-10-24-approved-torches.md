# Approved torches integration

> Execute inline with superpowers:executing-plans. User's "continuons" continues the approved appearance into Godot integration.

**Goal:** Place the approved round-base torches and local light in the mobile kit and MobileReference.

**Architecture:** Adopt the two prepared PNGs unchanged into the common atlas. The renderer places them on existing north/west wall faces using the shared support order. A shared prepared 128px falloff supplies optional static PointLight2D lighting.

**Tech stack:** Node/Sharp offline packing, Godot GDScript, prepared AtlasTextures.

**Spec:** `docs/reference/mobile-light-review/painted-v2/selection.json`, its `prepared.json`, and the latest user approval/integration request.

## Constraints and decisions

- Preserve selected source/recipe/capture hashes, native alpha, both offsets and bounds; never regenerate the artwork.
- Fixed .75 zoom, 256 source px/cell, integer grid, existing layouts and approved heart/doors unchanged.
- Expose north/west mounting cell arrays and a light toggle; skip missing walls, openings, special cells and duplicates. Other facing artwork is not approved.
- Default examples: north (1,0), west (0,1) in MobileReference. Existing other layouts remain undecorated; DungeonTorch uses the same atlas.
- Light sprite itself receives no additive light. Shared falloff is a separate small texture, refreshed with the atlas in the editor. Static light and no shadows retain the approved review's scope; no animation or mobile profiling claim.
- No automated tests, commits or pushes requested. Use export/import and visual captures. Preserve the user's live editor/cache. Existing working changes belong to this same task; work in place.

## Task 1: Adopt approved assets

- [x] Snapshot the pre-integration atlas/catalogue under the integration review.
- [x] Add `tools/mobile_approved_torches.cjs`: verify approval hashes, return two unchanged packed items and light metadata; retain falloff bytes.
- [x] Extend `tools/export_mobile_kit.cjs` for the two regions, metadata and source provenance.

## Task 2: Place torches and lights

- [x] Extend `scripts/mobile_dungeon_renderer.gd` with placement validation, common support ordering, optional local lights and falloff refresh.
- [x] Expose north/west arrays and the light toggle in `wireframe_cell_study.gd`; populate MobileReference.
- [x] Migrate DungeonTorch through a small standalone renderer script; include it and its dependencies in the resource export.

## Task 3: Review the integration

- [x] Export atlas, import resources and capture MobileReference, each standalone orientation, and a room matching the approved art review, with lights on/off.
- [x] Inspect actual-size screenshots and the approved artwork in the new atlas; record retained-region pixel/placement comparisons as export evidence.
- [x] Capture the editor preview without touching the user's editor. Stage/export current resources.
- [x] Review the patch, document outcome and any limitations, show the finished MobileReference image.

## Review focus

- Repacking preserves the prior 48 sprite pixels/placements and approved torch pixels.
- The wall exists at each mount; no torch floats at an opening or covers a door/stair.
- Refresh/toggling rebuilds without accumulating lights or stale textures.
- Foreground architecture occludes the torch through the common ordering.
- Export depends on active assets only, never the authoring review sources.

## Execution record

- Approval includes appearance; the subsequent "continuons" authorizes integration. No further approval gate is needed.
- Generic skill TDD/commit steps are superseded by project/user restrictions: no automated tests or commit/push in this task.
- Task 1: 50 regions, 48 retained regions and both adopted sprites match approved pixels/placements; atlas remains 1024x2048.
- Task 2: 7 focused captures show both orientations and light toggle; same image after toggling. Production imports/captures exit0, empty stderr.
- Task 3: 63 runtime captures/21 scenes; 3 editor views match runtime. Editor process has native shutdown diagnostics, documented. Fresh package has 45 dependencies/23 scenes, 726759 bytes, starts with exit0/empty stderr.
- Independent final review: no actionable code findings. Reviewer requested final staging refresh; completed with the new dependencies. No deferred minor findings.
- Existing no-shadow/static-light scope is retained; it does not establish light blocking between rooms or device performance.
