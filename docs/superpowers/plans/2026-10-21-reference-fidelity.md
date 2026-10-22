# Reference fidelity implementation plan

> **For agentic workers:** Use superpowers:executing-plans for this correction.

**Goal:** Rebuild the original entrance, surrounding masonry, floor and foreground corner at their original proportions in Godot, and compare the actual GPU capture with the same reference frame.

**Architecture:** Individually movable textured polygons sample the existing reference atlas. Their vertices and UV coordinates share the source image's pixel scale. A fixed composition places these architectural pieces; a camera alone scales the entire composition uniformly. No complete-scene image is used as a backdrop.

**Tech stack:** Godot 4, GDScript, the existing lossless reference PNG.

**Spec:** The user's approved comparison and instruction to implement and iterate until the images agree. Reference: `assets/dungeon/perspective/reference-atlas.png`.

## Constraints and review focus

- Reuse the existing branch and preserve unrelated edits, especially `project.godot`.
- Frame: source pixels `(0, 120)` to `(560, 630)`. This contains the entrance and adjoining corner, without HUD or hero.
- Preserve source proportions; never stretch a pier or normalize differently shaped slabs to squares.
- Separate architecture and floor elements; no whole-frame textured rectangle or screenshot hidden under the elements.
- Preserve original highlights, silhouettes, occlusion and the embedded violet illumination.
- Scope is a static reference composition, not a complete procedural tileset or four approved door orientations.
- Checks must catch distortion, missing elements, source/target misalignment, seams and clipping at mobile viewport sizes.

## Task 1 — Capture the visual regression

- [x] Add `tools/verify_reference.gd`: load `PerspectiveRoom.tscn`, require a source frame and independently movable pieces, compare a real GPU render with the reference region.
- [x] Run against the rejected room and record the failure.

## Task 2 — Rebuild the entrance at source proportions

- [x] Replace `scripts/perspective_room.gd` with an assembly of named polygon elements defined in `scripts/reference_pieces.gd`.
- [x] Capture the scene, inspect the source comparison and correct silhouette/UV/overlap defects.
- [x] Require a native-size comparison, separate geometry validation and uniform camera framing.

## Task 3 — Make the corrected scene the current preview

- [x] Point the main scene at the corrected composition; retain the old map only as an unapproved earlier experiment.
- [x] Update README, GAME_DESIGN, asset notes and AGENTS to distinguish implemented scope, visual evidence and missing reusable variants.
- [x] Run the complete existing checks plus GPU reference comparisons, inspect final capture, and request one independent code review.

## Execution notes

- The specification is already approved in chat; no new design choice is needed.
- Native Polygon2D UV sampling is used instead of generating or repainting raster assets.
- Reference comparison proves this fixed composition's fidelity; it does not prove arbitrary tile adjacency or independently relightable art.
- Regression RED: the rejected room lacked source-preserving element geometry; the initial replacement then failed its independent reference pixel comparison (4,176 missing pixels). Corrected arch joins and pier outlines across two further captures.
- Regression GREEN: 55 elements, 234,026 source-mask pixels, mean max-channel error 0.0032/255, 20 pixels above 3/255, 17 missing silhouette pixels. Whole-frame error 0.9261/255 includes the deliberately uniform exterior.
- Ruling: classify reference pixels at max-channel >= 48/255 for the architecture score, after measuring empty exterior haze at <= 47/255. Also report whole-frame error; do not claim the exterior haze is reconstructed.
- Ruling: preserve prior uncommitted entrance experiments and unrelated editor configuration. The corrected scene becomes F5; these earlier experiments remain clearly labeled and are not silently represented as fixed.
- Complete suite `tools/test-mobile.ps1 -All -Capture` passed. Actual 1280 × 720 and 720 × 1280 GPU captures were also inspected: framing and proportions are preserved.
- Independent review approved the agreed static reference reconstruction, with no Critical/Important findings. The single minor documentation path issue had already been corrected during review.
- Review limitations accepted: this work does not establish arbitrary room assembly, side-door variants, mobile performance, or exhaustive scaled-image seam equivalence. These are future work; actual native-size fidelity and selected landscape/portrait captures are established here.
