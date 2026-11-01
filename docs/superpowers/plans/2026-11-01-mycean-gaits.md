# Mycean walk and run implementation plan

> **For agentic workers:** Use executing-plans inline; complete one independent review at the end.

**Goal:** Render whole-character Mycean walk/run sprites from the corrected equipped source and provide native four-direction corridor previews.

**Architecture:** Reuse the established Batrafian/Vulpin offline held-pose pipeline and unchanged Godot corridor implementation. Preserve the Mycean wrist-attached grip lattice and contact envelope. Each gait has eight poses in four real isometric directions, packed into four atlases.

**Tech Stack:** Blender 5.2.1 background Python, Node/Sharp, Godot 4.7.2.

**Spec:** User's request to make walking/running; existing hero-animation production recipes; mycean-review/v2-meshy-inspection/README.md supplies this rig's anatomy and corrected staff grip.

## Constraints and decisions

- Continue the current feature checkout: the uncommitted equipped Mycean source is a direct dependency; preserve all existing changes. No commit/push/APK or raid integration requested.
- Whole-mesh renders, original textures, no 2D body assembly or mirrored directions.
- Eight poses, walk15fps/run16fps, actual registered foot supports and matching travel. Start with compact strides suitable for short legs; choose final distances from verified geometry.
- The left hand keeps the approved relative staff/lattice/envelope transforms. Raise the carried wrist enough to keep the staff off the floor, with restrained arm swing.
- Original large cap is preserved. Its existing face occlusion is a stated visual limitation.
- Runtime receives only256px sprites/atlases, not the detailed3D models or render modifiers.
- Isolated MyceanWalk/Run scenes reuse native two-corridor controls, pause, step and speed options including2x; no saves.

## Review focus

Hand/staff penetration including the formerly excluded grip; staff floor penetration during bobbing; foot sliding and loop seam; camera clipping/scale drift across four directions; native playback and displacement sharing one clock at2x.

## Tasks

- [x] 1. Add `tools/verify_mycean_gaits.gd`, observe missing-scene failure. Create `docs/reference/mycean-review/v3-locomotion/{render_gaits.py,mesh_checks.py,verify_saved_gaits.py}`. Adapt actual35-bone chains, preserve complete wrist/forearm orientations, register soles and verify16 held poses plus loop repeat. Source hashes and all3 grip attachments must remain invariant.
- [x] 2. Render pilots and inspect, then64masters512px. Add `prepare.cjs`, uniformly reduce/pack `assets/previews/mycean-{walk,run}` and write `scenes/Mycean{Walk,Run}.tscn`. Produce animated review, pose boards, source metadata and packed blend.
- [x] 3. Run independent packed-source validation and native fixture at desktop/landscape/portrait; inspect captures and motion previews. Document reproduction, measurements and limitations; update AGENTS. Run fresh independent review and resolve important findings.

## Progress

2026-11-01: Existing Mycean static source and Batrafian gait workflow inspected. User requests execution; no further design decision is needed. Existing checkout retained to build on the corrected uncommitted source.

2026-11-01 complete: Initial native fixture failed for both missing scenes. Pilot surface checks exposed staff/cap then staff/boot intersections; diagonal run carry resolves both while preserving the three grip attachments. Independent saved-source validation caught a short support interval (.0736765 versus .1); deeper root compression and actual sole Y/Z registration fix it. All64masters regenerated after the shared solver correction. Final16poses and12mandatory support intervals pass (maximum error .000049942), no detected staff/body surface crossings, source hashes unchanged.

Fresh Godot import and708native checks pass, empty stderr; desktop/short landscape/portrait reviewed. Independent reviewer confirms22source preservation comparisons,64master/reduction pairs,8atlas repacks, WebP timelines and native shadow/contact placement. No important findings remain. Reproduction and limitations recorded in v3-locomotion/README.txt and AGENTS. Two isolated preview scenes, no raid integration/APK/commit/push.
