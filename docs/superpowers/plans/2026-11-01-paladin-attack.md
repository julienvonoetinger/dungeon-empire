# Paladin hammer attack implementation plan

> Execution: native, established approved whole-mesh sprite pipeline.

**Goal:** Four-direction hammer attack with anticipation, impact and return to guard, plus an isolated native target preview.
**Architecture:** Reuse the approved v3 rig and rigid equipment grips. Offline Blender held poses, uniform sprite packing, one-shot SpriteFrames. Extend the action review through a dedicated subclass; no simulator changes.
**Spec:** User request of 2026-11-01 and `docs/reference/lithide-review/v3-equipment-grips/README.txt`.
**Constraints:** No runtime 3D/puppet, no changes to previous actions, player saves, raid roster, APK or git publication. English preview controls.

- [x] Generate and inspect keyed wind-up/strike/recovery poses in `v7-hammer-attack/render_attack.py`; check planted soles, rigid grips, equipment/body intersections and camera margins.
- [x] Save/reload the pose scene, render four actual camera views, pack new `assets/previews/paladin-attack` resources and animated review. Keep neutral endpoints identical and image scale consistent with prior actions.
- [x] Add `PaladinAttack.tscn` and its target preview using projected physical hammer contact. Verify one impact per playback, pause/step/replay/speeds, native layout and four directions in `tools/verify_paladin_attack.gd`.
- [x] Re-run existing reaction checks if the shared preview changes; verify preservation hashes. Inspect native screenshots, request independent review, document exact reproduction and validation limits.

Review focus: contact on all camera views; returning guard without a jump; no foot sliding; impact not repeated at slow playback or skipped at 2x; native preview does not touch gameplay.
