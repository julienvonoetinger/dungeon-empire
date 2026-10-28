# Vulpin door lockpick implementation plan

> For agentic workers: use superpowers:executing-plans for inline execution.

**Goal:** A looping lockpick sprite animation and a native four-door positioning review scene.
**Architecture:** Keep the Meshy whole-mesh held-pose pipeline; render eight fixed poses from four cameras. Reuse the native dungeon renderer and accepted door art. Register a fixed tool tip to the door's painted lock position.
**Tech stack:** Blender Python, Node/sharp asset preparation, Godot GDScript.
**Spec:** Current user requests: animate attempting to pick a door; make a scene with a door in all four directions to test relative position. Existing approved workflow: held 3D poses rendered as pure 2D sprites, same Meshy paint/camera, native review scenes.

## Constraints

- Preserve GLB/materials, earlier animations and unrelated working-tree edits.
- Authoring choice: eight poses, one-second loop, small wrist motion, planted feet, slight forward lean. Tool tip stays on a fixed lock target; no automatic opening/success animation.
- Preview only; no gameplay/saves/APK/commit/push requested.
- Work in this checkout because existing animation inputs are uncommitted here.

## Review focus

- Tool registration must match all four door orientations and every pose.
- Preserve real wall/door occlusion; optional ghost mode is inspection only.
- Small wrist motion must remain readable without body jerks or foot sliding.
- Loop wrap, pause, stepping and speed controls must remain synchronized.
- Four views and controls must fit landscape and portrait.

## Tasks

- [x] Render eight whole-mesh poses with two small tools and fixed tip; verify distinct/unclipped frames, feet, loop continuity and packed Blender replay.
- [x] Prepare four sprite sheets/SpriteFrames/registration data and animated review.
- [x] Create VulpinLockpick.tscn, a native four-door renderer and playback/position review controls.
- [x] Capture native scene with default/ghost/guides, every pose, landscape/portrait; verify timing, positioning, isolation and source preservation.
- [x] Inspect visuals and perform focused read-only review; record evidence and limitations.

## Execution notes

The user's direct request authorizes implementation within the established preview workflow; no additional design-approval round or source-control operation is needed. Validation is focused on this reversible animation review, not a new gameplay test suite.

- Rendering/export: 32 distinct unclipped frames, 890,913 PNG bytes, 8 MiB RGBA; original GLB unchanged. Packed Blender replay matches all eight body bounds exactly and keeps the tool tip fixed.
- Native harness: missing-scene RED, then final exit0/0 failures/empty stderr; controls, 32 tool/lock projections, four viewport sizes, all eight opaque/ghost poses captured.
- Independent read-only review found P2 head/crown intersection at original contact distance. Reproduced against accepted masonry; source tool target moved from -.86 to -1.06 model Y, preserving lock height/contact. Final conservative triangle separation checks lower jamb and upper crown tiers:16 checks, minimum .0094485 case clearance at zero offset. Earlier failing evidence retained; final Blender check exit0.
- Reviewer found no further important mapping/playback/control defects. Editor asset hot reload remains unverified, as in previous isolated scenes. Reopening/running the scene loads the current assets; no gameplay integration is promised.
- Native overview, ghost view, portrait and short landscape inspected. Twelve prior walk/run/hurt sheet hashes match their existing source exports. Visual naturalness, facial expression and physical-device performance are not automatically validated.
