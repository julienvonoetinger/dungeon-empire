# Six-room perspective implementation plan

> **For agentic workers:** Use superpowers:executing-plans.

**Goal:** Restore the previous six-room layout using the original reference's stone volumes and native-proportion elements.

**Spec:** User explicitly selected the six rooms connected by corridors, rather than the two-room illustration. Keep the corrected entrance available and integrate it at the north of the first room. Static scenery only.

**Architecture:** New `SixRoomPreview.tscn` and renderer reuse the existing layout topology, with 96 px logical cells and a 160 px margin. Sample native-sized floor slabs, full wall facades, side courses and piers from the original atlas. Merge exposed edges into continuous wall runs; draw floors over exterior wall overhangs to preserve open corridors. Place the validated entrance elements as one consistently translated group. Keep the earlier 560 × 510 reference study and its pixel regression intact.

**Constraints:** No full-scene backdrop, no individual nonuniform scaling or rotation of facade sprites, no new gameplay, no six-room screenshot substituted for geometry. Preserve unrelated uncommitted work.

## Task 1 — Map and material reconstruction

- [x] Add a failing six-room scene regression: original occupancy, 255 cells, two-cell corridors, source-proportion geometry, full facades.
- [x] Add `assets/layouts/six_rooms.tres`, `scripts/six_room_view.gd`, `scripts/six_room_preview.gd`, `scenes/SixRoomPreview.tscn`.
- [x] Render natural-sized floor fragments and merged directional boundaries, then native piers and the entrance.

## Task 2 — Visual iteration and integration

- [x] Capture the complete composition and enlarged room/junction details with Godot; correct seams, occlusion and wall joins.
- [x] Set F5 to the complete scene; keep F6 for the faithful entrance study.
- [x] Verify actual GPU rendering, corridor visibility, independent materials and landscape/portrait framing.
- [x] Update design/README and request an independent read-only review.

## Review focus

- T and cross junctions remain visibly passable.
- Wall facades retain native depth, and piers are never stretched to fit a cell.
- Low walls or wrongly oriented entry experiments do not reappear.
- Comparisons distinguish the preserved floor plan from the changed wall style; the original six-room image is not a pixel oracle for the new art.
- The reference study's 99.9% pixel metric is not attributed to the recomposed full map.

## Execution notes

- Started with a failing check for the missing complete scene, then implemented native atlas fragments and the preserved floor plan.
- Replaced rectangular source-floor lighting patches beneath the entrance with two floor-only static lights to remove visible cutout boundaries.
- Corrected the overlap order of north and south piers, trimmed the south pier to its actual silhouette and shortened vertical-wall extensions to its foot.
- Merged adjacent floor regions before clipping, reducing the assembly from 1330 to 740 surfaces while preserving the 471 visible-floor probes and their GPU pixels.
- `tools/test-mobile.ps1 -All -Capture` passes: complete scene launch, original topology, four viewport sizes, 471 floor/corridor probes, two lights, hidden-elements check and separate reference-study regression.
- Actual complete-map captures inspected at 1692 × 1152, 1280 × 720 and 720 × 1280; entrance and junction close-ups inspected at native scale.
- Portrait uses uniform whole-map fitting and therefore leaves large vertical margins. Touch navigation and mobile profiling remain outside this static-scene task.
- Independent read-only review found no actionable issues. Accepted scope exclusions: arbitrary layouts, side entrances, editor-time rebuilding, null-layout handling, mobile performance, touch controls, collision and gameplay. Repeated stones, baked highlights and the source entrance pier are documented visual constraints of this fixed assembly.

### Follow-up — entrance wall joins

- User reported incorrect walls on either side of the entrance. Investigation found seven repeated strips sampling part of the west torch, plus the original room's height-change return and projecting east pier superimposed on a flat facade. These issues were missed by the previous floor-focused verification and review.
- Added a regression before fixing; it failed on the fixture fragments and on the floor concealed beside the east torch (`artifacts/entry-red.*.log`).
- Replaced those strips with four stone courses, retained the entire cap over the east torch, and removed the old perpendicular return from this composition. Source geometry and the separate reference study remain intact.
- Extended the existing torch lighting to the new facade pieces instead of repeating baked illumination. The assembly now contains 747 surfaces.
- Added 24 GPU wall samples, cap-continuity and clear-floor checks. The full suite and actual close-up capture verify this correction; the earlier reference-study pixel score remains separate.

### Follow-up — vertical wall assembly

- User supplied a close-up of the west walls. The 87 px crops cut stones mid-block, repeated a baked purple edge and omitted the outside wall face. Starting the repetition above the north pier also exposed a partial first stone below it.
- Added a regression before changing the renderer. It failed at all three checked starting blocks and at ten west exterior-face points (`artifacts/vertical-red.*.log`).
- Replaced the crops with whole native west/east modules and anchored their visible stack at the foot of the north pier. Kept its backing separate. An enlarged source inspection identified the adjacent corner's bevel in a second west candidate; that candidate is excluded.
- The assembly now has 806 surfaces. Added 120 side-wall GPU samples and `tools/capture_vertical_walls.gd` to the capture suite. Its three panels show west entrance, west lower room and east right room at native scale.
- The floor plan, entrance layout and separate reference study retain their existing checks. Baked stone highlights and repeated source material remain limitations; no dynamic global lighting or new artwork was introduced.

### Follow-up — stale editor preview

- User still saw the old side walls in the editor. The main scene on disk was already `SixRoomPreview.tscn`, but its tool renderer generated children only in `_ready()`. Reloading code did not rebuild those existing children.
- Added a failing regression for the missing refresh entry point. Added editor-only fingerprint checks every 0.5 seconds and a manual inspector button. Rebuilds are deferred and coalesced, replace generated nodes and preserve authored children. Runtime polling stays disabled.
- The regression runs in a normal headless editor main loop against an isolated minimal project. This avoids the resource leaks observed when using a custom `SceneTree` script with `--editor`, and avoids changing the user's editor tabs. It changes the live layout and reloads the renderer script in place.
- `tools/test-mobile.ps1 -All -Capture` passed, including the editor regression and the existing GPU checks. Inspected the full map, vertical walls, entrance/junction details and reference comparison. No art or layout changes in this follow-up.
- An editor tab retaining the old tool instance can be closed and reopened once to load the new refresh mechanism. F5 creates the current scene directly.

### Follow-up — actual sidewall volume and corner joints

- The user's restarted editor and F5 captures matched our current render. The stale-preview explanation did not explain their visual complaint and was incorrect as a diagnosis of it. The user explicitly confirmed both insufficient volume and bad block/pier joins.
- A native-scale source inspection identified fuller foreground cap stones, exterior faces and raised piers. Added failing regressions for missing exterior masonry, missing upright pier faces and rectangular corner cutouts before changing the renderer.
- Reassembled the sides as separate cap/face layers: west 64+24 px, east 52+28 px. Complete projecting piers interrupt long runs, with new cap runs beginning at their feet. An initial wider west crop included a neighboring horizontal wall; split that face from the cap to remove the repeated bright fragments.
- Kept native contoured corners. A close-up exposed overlapping decorative heads where opposing corner projections meet; added a failing two-point regression, then joined those columns with one head and continuous face masonry.
- The current assembly has 948 surfaces. All 255 floor cells and 471 floor/corridor probes remain valid. The original 55-piece reference study is unchanged. Added 8 explicit volume/join GPU probes alongside the existing 24 entrance-wall and 120 side-wall samples.
- `artifacts/sidewalls-before-after.png` compares the same west wall with identical camera and scale. The full-map and junction captures are also inspected. Technical checks cover geometry, provenance and sampled rendering; they do not substitute for the user's artistic validation.

### Follow-up — approved west walls, east blocks still too narrow

- The user explicitly approved the west walls and rejected the right walls. The east cap still used a narrow 52 × 73 px stone beside 68 px projecting piers, creating a 16 px width jump and a different mortar rhythm.
- Added a failing regression before the fix: eight hand-checked points at the outer edge of the east cap in both right rooms, plus checks that the dark face remains outside it. The former renderer failed these checks (`artifacts/east-red.*.log`).
- Reused the approved 64 × 61 / 64 × 69 px cap stones on the east, without scaling or mirroring. The existing 28 px exterior face moves outward with the wider cap. West assembly and all pier geometry are unchanged. East total width is now 92 px; the cap-to-pier step is 4 px. The map contains 960 surfaces.
- `tools/test-mobile.ps1 -All -Capture` passes, including all 255 floor cells, 471 floor/corridor probes, the existing masonry checks and eight new east GPU probes (maximum source error 0/255). Inspected the complete map, native wall/entrance/junction details and the separate reference study.
- `tools/capture_sidewall_comparison.gd -- --east` compares the right wall before/after at identical camera and scale. It also confirms both approved west-wall panels are byte-identical between captures. Local comparison: `artifacts/east-wall-before-after.png`; baseline: `artifacts/east-before-detail.png`. These snapshots are ignored review artifacts, not required by the repeatable test suite.
- Updated the current design, README and atlas notes. The user's artistic review of the corrected east wall remains separate from these technical checks.
