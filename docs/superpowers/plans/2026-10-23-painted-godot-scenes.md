# Painted Godot Scenes Implementation Plan

> Execute inline with superpowers:executing-plans, continuing the user-authorized
> scene migration in the current workspace. Preserve existing uncommitted work.

**Goal:** Make every dungeon demonstration scene display the shared painted kit.

**Architecture:** Export connected structural PNGs offline using the existing
wireframe port geometry and the same shared materials. Godot places a prepared
floor and at most one structural PNG per cell; no generated geometry, tint,
clipping or nonuniform scaling. Shared grid rules and camera fitting stay intact.

**Tech Stack:** Node.js, sharp/SVG offline compositor; Godot GDScript/Sprite2D.

**Spec:** User request to update all Godot scenes; MATERIAL_WORKFLOW.md and
WIREFRAME_WORKFLOW.md for the accepted geometry and texture workflow.

## Constraints

- Keep 1x1 square cells, 256 screen pixels per cell, projection (-.18,-.9).
- Wall thickness 1/6, height 1.88/6, course joint .94/6.
- Native PNGs are x4; Godot uses uniform scale .25 and logical anchors.
- Preserve all 16 current grid study layouts, corridor widths, doors and stairs.
- Also update four older architecture demos; torch/heart standalone prop scenes
  have no replacements in this architecture kit and retain their assets.
- No new gameplay, tests, commits or pushes requested. Use asset export checks,
  Godot import and existing visual capture helpers for review.

## Tasks

- [x] Export connected floor/wall/stair/door PNGs and a Godot preload catalogue.
  Source: connected wireframe geometry; appearance: existing isolated masks and
  shared material IDs. Omit internal end faces before runtime.
- [x] Update shared scene renderer for PNG scale/anchors and floor-first layers.
  Keep inspector refresh getter, grid resolver and existing scene parameters.
- [x] Migrate legacy DungeonPreview, PerspectiveRoom, ReferenceCalibration and
  EntranceVariants to the prepared assets; keep current scene paths usable.
- [x] Import assets, inspect actual scene captures, and synchronize documentation.

## Review focus

Door/stair ports, concave pillars, double-width connections, editor refresh and
F6 visibility; no doubled end contours, opaque floor covering a previous wall,
camera-scale changes or flipped perspective.

## Execution record

- Export: 96 unique connected structural PNGs for 128 IDs, 16 empty states,
  plus one connected floor. Source joints unchanged; independent alpha comparison
  reports zero differences, zero holes and zero excess pixels for each PNG.
- Shared renderer: prepared PNGs, uniform .25 scale, all floors below structures.
- All 16 existing grid-scene parameters retained. Four legacy demonstrations
  migrated as listed in PAINTED_GODOT.md. F5 unchanged.
- Visual review found the isolated floor's three closing contours made a strong
  cell border. Exported its connected version with exactly 19 source joints.
  Reimported and recaptured all scenes after this correction.
- Godot 4.7.2 import completed with empty stderr. Existing capture helper rendered
  all 20 architecture scenes at 1280x960 and 2560x1920. Four door details, four
  entrance details and five SixRoom details captured without stderr errors.
  SixRoom reports 256 occupied cells and one entrance; closed study has four stairs.
- Inspected room, corridor, door, stair and SixRoom captures; 20-scene contact sheet
  saved as artifacts/painted-godot-scenes-overview.png. Artistic approval remains
  with the user. Floor material/motif repetition remains the existing design.
- Fresh-context review by review_painted_integration: no additional concrete
  finding beyond the isolated-floor issue already corrected. No test suite run.
- Ruling: use existing workspace and visual capture helpers, without new tests,
  commits or pushes, per current scope and developer instructions. Preserve prior
  uncommitted work. Legacy demos now illustrate the current grid kit instead of
  retaining obsolete traced compositions; inventory documents their new content.
- Documentation synchronized: AGENTS.md, GAME_DESIGN.md, MATERIAL_WORKFLOW.md,
  WIREFRAME_WORKFLOW.md and new PAINTED_GODOT.md.
