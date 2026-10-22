# Dungeon heart implementation plan

> Execute inline with superpowers:executing-plans in the current feature checkout.

**Goal:** Add the already-approved square stone pedestal and floating dark vortex
to the static six-room scene, preserving the approved masonry.

**Architecture:** A reusable `DungeonHeart.tscn` samples the exact approved image
with native-sized contours. A local violet light and soft contact shadow integrate
it with the current floor. Instance it in the upper-right room at (2368, 784).

**Tech stack:** Godot 4.7, Polygon2D, GradientTexture2D, GL Compatibility.

**Spec:** User request and approved heart in clipboard image
`252b152a-68fc-429f-af48-2b88834cf839`; current GAME_DESIGN.md static scene scope.

## Constraints and decisions

- Preserve the exact square base, four short corner stones and floating sphere.
- Native pixel proportions and orientation; no metal rings or new art direction.
- Static visual addition only. No health, interactions, animation or gameplay.
- Keep all 255 floor cells and existing walls; isolate the heart from the masonry
  renderer so rebuilding the editor preview preserves the authored instance.
- Placement is an implementation choice following the reference's right room.
- Keep the existing feature checkout and uncommitted work, as this is the same
  scene the user opens in Godot. No commit or publication in this step.

## Task: integrate the approved heart

- [x] Add `tools/verify_heart.gd`; confirm it fails while the scene has no heart.
- [x] Add source reference and native-contour `scenes/DungeonHeart.tscn`;
  instance it under Dungeon in `SixRoomPreview.tscn` with z-index 4.
- [x] Add close-up capture and real GPU checks: source fidelity, sphere
  silhouette, clear surrounding floor, local light, and unchanged masonry.
- [x] Keep substrate checks on the floor with the heart hidden temporarily;
  verify the visible complete scene separately with the heart enabled.
- [x] Extend the isolated editor fixture dependency copy and test entry point.
- [x] Update GAME_DESIGN.md/README; run `tools/test-mobile.ps1 -All -Capture`,
  inspect the actual complete scene and heart close-up, and review the change.

## Review focus

- No rectangular patch of source floor or foreign artwork around the heart.
- Sphere, base and room share the same camera and native scale.
- Heart survives editor rebuild without duplication or losing local light.
- Runtime asset paths stay within the repository.
- Existing masonry and passages remain unchanged.

## Execution record

- Initial regression failed because F5 did not contain a heart. Then added the
  authored reusable scene, without changing the existing masonry renderer.
- Source file SHA256 matches the approved attachment exactly:
  `08A7E0C077B668460D0F5424C55BAD826B5D434BBAFDF6984F2E896694823639`.
- Ruling: sample the original reference contours directly rather than generate
  new art. This preserves the approved drawing; the full source image remains
  an authoring atlas until production packing, as documented for the masonry.
- Ruling: the close-up uses a uniform 1.8× camera zoom for inspection. Runtime
  heart geometry stays at native scale 1; no individual texture is stretched.
- Full `tools/test-mobile.ps1 -All -Capture` passes. Eight heart source samples
  have maximum error 0/255; nine surrounding points preserve the current floor.
  Four exterior image regions remain pixel-identical with the heart hidden or
  visible. Editor checks preserve the same instance and its six children.
- All three wall detail panels are unchanged: before/after PNG SHA256 both
  `258649A48D7108F0BE7DF5A42F8B90C03D692326350069AB43E816C2256B8969`.
- Inspected the actual complete scene and heart detail. Artistic approval of
  the new integration remains the user's judgment.
- Independent read-only review found no actionable issue. Reviewed exclusions:
  arbitrary layouts, gameplay, production atlas packing and mobile profiling
  remain outside this static addition; these limits are documented.
