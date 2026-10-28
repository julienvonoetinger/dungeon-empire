# Vulpin chest lockpicking

> Execute inline with superpowers:executing-plans; focused fresh review before completion.

**Goal:** A distinct crouched lockpicking attempt on a locked chest, rendered in four directions from the unchanged Meshy model.
**Spec:** User asks for chest lockpicking after correcting the unlocked chest interaction. Closed artwork means locked; unlocked is already ajar. Do not confuse these states.
**Architecture:** Eight fixed whole-mesh Blender poses, original paint, two rendered lockpick tools, shared camera/ground anchor/.85 scale. One-second looping attempt with fixed tool tip at chest lock height. A native inspection scene keeps the closed chest and its shadow throughout.
**Stack:** Blender5.2, Python, sharp, Godot4.7.

- [x] Author crouched poses and export32 sprites with calibrated tool/contact metadata; verify source hash, fixed feet, reach, bounds, loop and saved-pose replay.
- [x] Add VulpinChestLockpick.tscn with four native chest directions, pause/step/restart, .5x–2x, guides and optional ghost chest. The attempt never automatically unlocks/opens the chest.
- [x] Inspect real native views; validate timing, state preservation, projected tool contact, ordering and layouts. Preserve20 previous sprite sheets. Final focused review.

## Constraints and review focus

- Preview only: no gameplay/save access, APK, commit or push.
- Keep current checkout, which contains uncommitted dependencies and user work.
- Do not change the door lockpick or unlocked chest animations.
- Chest artwork is not reconstructed3D; lock points and collision checks are calibrated proxies.
- Check that the lower posture has no unreachable wrists, sliding feet or chest penetration.
- All loop poses and controls must keep exactly one CLOSED chest illustration, including restart.
- Ghost mode may aid inspection but normal mode must keep chest/actor depth ordering.

## Evidence

Native import/capture exit0, empty stderr,394 checks/0 failures.21 captures/4 sizes, normal/ghost contacts and source board inspected. Saved8 poses replay with0 bounds/tool-tip error.32 unique unclipped frames,847196PNG bytes/8MiB RGBA. Original GLB hash and20 previous sprite sheets unchanged. Independent review found no important actionable issue.

Initial generic infinite-plane guard rejected the head overhang above the low chest. Inspection established its height, then replaced the guard with triangle separation against each chest's catalogue height/front bound.32 checks pass; minimum .0068831case. Painted keyholes were slightly offset from a uniform theoretical plane: measured visible east/south centres, inferred opposite rear contacts and extended tool reach to-1.0Y. This is calibrated artwork placement, not physical reconstruction. No gameplay/save/APK/commit/push.
