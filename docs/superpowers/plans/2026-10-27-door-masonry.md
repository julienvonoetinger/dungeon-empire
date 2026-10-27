# Door masonry correction

> **For agentic workers:** Use superpowers:executing-plans. Preserve prior uncommitted HUD and trap work.

**Goal:** Correct the wall/door masonry continuity and restore the dark stone joints requested in the user's 2026-10-27 screenshot.

**Architecture:** Retain the Sceau interdit silhouette, leaf, hardware and seals. Divide the lower jambs into the same two courses as the walls. Use the shared soft-stone B finish on complete masonry faces, with XYZ depth ownership; retain the runtime segmented wall sorting.

**Tech stack:** Node/Sharp, existing XYZ rasterizer, Godot native capture tools.

**Spec:** User's two reported defects; immutable original door geometry and painted-v3 evidence. New review is painted-v4-masonry. The earlier successful ownership checks did not approve the masonry appearance.

## Constraints and review focus

- No image generation, source painting changes, gameplay/save/HUD changes, commit or push.
- Keep fixed 2:1 camera, logical size, four directions and wall junction span .365..635.
- Preserve every non-door prepared sprite (including the newly approved traps).
- Inspect both rails, foreground actors, removal/restoration and the split at wall height.
- Dark mortar must separate actual stones, not the triangulation or the smooth recessed band.

## Task 1: Masonry and native integration

- [ ] Record before images, per-region hashes and current generator; add a check exposing missing jamb courses.
- [ ] Adapt masonry faces to the wall's planar stone treatment; align jamb courses at H/2. Reuse stone_edge_finish.cjs with depth-owned sampling. Keep smooth recessed band unjointed.
- [ ] Render flat-volume/wireframe and painted comparisons; inspect at gameplay size and enlarged.
- [ ] Export; verify source preservation, non-door pixel identity, footprint and memory budget.
- [ ] Capture all four directions and game actor/removal/restoration states to a new output path; check mathematical contact ownership.
- [ ] Fresh read-only review and final evidence; update AGENTS and this ledger.

## Execution notes

- Completed by the user-approved v6/v7 integration in 2026-10-27-clean-door-integration.md. The earlier v4 approach below is superseded; final evidence is painted-v8-integrated.

- Existing feature branch reused: the current work depends on approved uncommitted trap/HUD assets. Native execution, no additional worktree and no automatic commits.
- Confirmed root causes: monolithic lower jamb faces omit the wall's H/2 joint; custom edge tint is not the shared rounded stone/mortar finish. Prior v3 segmentation remains necessary for depth ordering.
- In-progress v4: two jamb courses, shared stone finish, continuous slope grading and stone keystone exported. 143 non-door regions unchanged; export/import and initial four-direction captures passed. Final revised keystone has not received the complete native review. No claim of visual approval.
- User's subsequent screenshots reject the remaining tiny wall fragments and explicitly request wireframes. Texture work is suspended. Read-only wireframe-v5-junctions exposes the underlying mismatch: upper wall joints at 1/3 and 2/3, but cuts at .365 and .635 leave four fragments .0316667 long (9.5% of an upper brick). No correction to these cut positions has been made. Resume from geometry feedback, not from v4 technical checks.
- Following feedback: isolated wireframe-v6-clean-leaf moves jambs/cuts to 1/3..2/3 and removes leaf hardware geometry (133 faces), preserving a smooth front/back and the opening contour. Generates shared magenta frontal/isometric guides plus a leaf mask. Twelve coincident contact checks, zero tiny fragments, thirteen source/runtime hashes unchanged. Board visually checked. No production integration/painting in this step; v6 geometry review now precedes resuming this plan. Historical painting used the colored guide with hardware, not the magenta inspection export.
