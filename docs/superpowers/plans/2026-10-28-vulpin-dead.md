# Vulpin static death implementation plan

> **For agentic workers:** Use superpowers:executing-plans for inline execution.

**Goal:** Give the current Meshy Vulpin a knee-first forward collapse and a
persistent final dead pose in four directions.

**Architecture:** Pose the existing full mesh offline in Blender, then render
ten held sprites per direction. Keep the same projection, pixel density and
ground registration as other actions. Provide a native four-view review scene.

**Tech Stack:** Blender 5.2/Python, Sharp, Godot 4.7.

**Spec:** User now explicitly supersedes the earlier no-fall simplification:
fall to knees, then face first, arms extended forward at the end. A further
correction requests the torso down and head turned sideways to avoid a push-up.
Ten whole-mesh
held poses, a one-shot fall followed by one static corpse per direction.
No runtime 3D rig.
The pose is a new visual proposal; it does not imply artistic approval.

## Constraints and review focus

- Keep the original Meshy GLB/paint unchanged and hands unarmed.
- Bent asymmetric limbs, body grounded; avoid a rigid straight standing model
  simply tipped over. No anatomical/self-collision guarantee from bounds checks.
- Same 30-degree camera, orthographic pixel scale, .85 native hero scale.
  If prone silhouette needs canvas padding, preserve pixel density and anchor.
- Grounding must consider the whole body, not the old boot-only masks.
- Forty unclipped sprites, one-shot fall, dead state reuses final pixels.
- No player saves, gameplay state machine, APK, source commit or push.

## Tasks

- [x] Pose and inspect a Blender pilot, then render all four directions.
  Save an editable packed pose and source/bounds/contact metadata in
  docs/reference/vulpin-review/v24-meshy-dead/. Check GLB SHA, finite vertices,
  body contact, alpha extents and reload of the saved pose.
- [x] Prepare forty frames, resource and registration in
  assets/previews/vulpin-death/. No historical puppet sprites. Measure PNG and
  decoded RGBA size, preserve previous texture hashes.
- [x] Create scenes/VulpinDeath.tscn and scripts/vulpin_death_preview.gd.
  Display four synchronized falls on paving, with pause/step/replay/rate and
  optional repeat; default final pose persists. No separate side-roll sequence.
  Import, capture at desktop/short/portrait sizes, inspect visuals. Fresh
  focused review, fix important findings, record evidence in AGENTS.md.

## Execution notes

- Work in the current checkout to retain the uncommitted Meshy dependencies.
- Render/capture checks cover the actual assets; no implementation-mirroring
  unit tests for this reversible art preview.
- Scope changed while preparing the side-lying pilot: user explicitly requests
  knees then face-first fall. Side pilot retained as unaccepted exploration.
- First review and user feedback identify a push-up appearance. Final fix
  advances hands from .184/.185 to .261/.263 model units ahead of shoulders;
  elbows retain 171.45 degrees. Chest bends independently; head turns sideways.
  Final-arm support regression fails old pose, passes revised saved Blender.
  Ten pose bounds replay exactly; original GLB and24 prior sheet hashes intact.
- Final art remains a proposal, not a naturalness guarantee. Source eyes are
  open; no facial rig is invented. No game/save integration or APK.
- User chooses former2x as new base: all10 durations halved to550ms total.
  Source timing, runtime resource and both WebP previews updated; atlas SHA
  unchanged. Native controls remain relative to the new base, final hold intact.
