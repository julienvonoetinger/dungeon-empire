# Android portrait and rotation implementation plan

> **Execution:** superpowers:executing-plans inline; focused review at the end.

**Goal:** Rotate the current Android game between landscape and portrait without
resetting the dungeon, camera centre or current tool/menu.
**Architecture:** Enable Godot's SENSOR orientation in project.godot (the Android
4.7.2 exporter reads display/window/handheld/orientation). Reuse the responsive
HUD and existing fixed-scale portrait compensation. Cancel active gestures when
the viewport changes, preserving armed tools and menu state.
**Spec:** User asks to implement orientation changes and support portrait.
**Stack:** Godot 4.7.2, GDScript, Android test APK 0.1.2 / code3.

## Constraints

- No game rules, save schema, new artwork, camera zoom controls or UI redesign.
- Preserve unrelated uncommitted changes and the previous APKs.
- Use isolated capture/test saves; never access the player's normal save.
- Same Android package and signing certificate; publish a new downloadable test.
- Desktop resize tests and manifest validation are not physical sensor tests.

## Tasks and validation

- [x] Baseline rotation checks: project sensor setting; same session/state/camera;
  portrait header/catalogue/radial/selection/pause/raid within visible bounds;
  a gesture crossing rotation cannot place an item or buy from the radial.
- [x] Enable SENSOR; handle resize cancellation without canceling tool/menu.
  Fix only reproduced portrait regressions if found.
- [x] Run focused transitions, native portrait screenshots and existing mobile
  interaction harness. Fresh read-only review.
- [x] Build APK; inspect orientation manifest, configChanges, version,
  signature and packaged startup; publish and verify public download link.

The request and established responsive design are sufficient; no new visual
direction or user decision is needed. No commit/push requested.

## Evidence and adjustments

- Native baseline: 220 checks, 6 failures (orientation setting, three gesture
  states and two transient panel overflows). Wrapped text/minimum-size changes
  now queue a layout, fixing first-open catalogue and placement panels.
- Existing mobile harness caught unconditional 500ms mouse suppression on
  resize; limited that suppression to a live touch. Regression now passes.
- Review suggested actual post-rotation releases. Real viewport events reproduced
  a retained ordinary-button capture. Reset enabled BaseButtons' pending press
  through their disabled setter; disabled actions and selected toggles retained.
- Final native harness: 227 checks, 0 failures, 51 captures. Includes old-world
  touch release, fresh touch, mouse and touch button cancellation/fresh activation.
- Godot SENSOR exports Android **fullUser (13)**, not fullSensor (10): respects
  the user's auto-rotation lock, enables all orientations when unlocked. Verified
  in the APK manifest (`configChanges=0x3ff4`, including orientation/screenSize/
  screenLayout). Android reference:
  https://developer.android.com/guide/topics/manifest/activity-element#screen
- Read-only reviewer confirmed the reproduced button fix and no remaining
  actionable finding. Final packed-resource smoke and 227 rotation checks pass;
  all Godot import/export/test stderr empty. Same package/signing certificate.
- Published prerelease android-test-0.1.2, anonymous download HTTP200, remote
  digest equals local SHA256:
  125e53a19fe27b942233acb168946d872187364364269b27d020060150e09356.
  APK61,076,174 bytes. Physical phone validation remains outstanding.
