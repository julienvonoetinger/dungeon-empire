# Mobile Implementation Plan

Spec: ../specs/2026-09-28-mobile-2-5d-vertical-slice-design.md

User authorized unattended implementation on 2026-09-28, including one quota reset when needed.

## Delivery

- [x] Progression: CoreProgression owns cumulative XP (0/60/150/280), rewards and duplicate protection. RaidDirector captures results before clearing hero and emits afterward. Keep cumulative raid IDs across map resets.
- [x] Persistence: MobileSave stores validated Variant dictionaries without object decoding, rotating a previous valid backup. Save preparation and completed results atomically; never serialize live raids. Isolate tests from player saves.
- [x] Placement: MobileBuild previews commands on an isolated DungeonSim copy, checks unlocks, commits only after confirmation. Revalidate on confirmation. Preserve existing raid rules and storage overflow.
- [x] Touch: MobileInputRouter emits gestures; MobileCameraController bounds zoom and discrete yaw. Cancel on focus loss, second finger and HUD capture.
- [x] HUD: responsive scene with resources, categorized build tray, selected tile cost and confirm/cancel, explicit collection, raid portrait, result/restart and save error feedback.
- [x] Presentation: cut away foreground walls, remove development preview lineup, four shadowless practical lights, generated 2D assets in the 3D world.
- [x] Android build: reproducible signed debug APK, landscape, SDK verification and payload audit. No phone connected for installation.
- [x] Desktop verification: 38/38 tests, baseline desktop fixture isolated from mobile UI, Compatibility captures at 960x540, 1280x720 and 1560x720, independent review.
- [ ] Hardware acceptance: install on a real phone, touch/notch checks and sustained 30 FPS. Requires a connected or user-tested device.

## Interfaces

CoreProgression.claim(result:Dictionary)->Dictionary returns xp, gold, before_level, level; empty on duplicate. allows(tool:int)->bool.
MobileSave.capture/apply(sim, raid, profile), write_save(path, data)->bool and read_save(path)->Dictionary. Main.persistence_enabled disables persistence for tests.
MobileBuild.preview(sim,profile,tool,cell)->Dictionary returns valid, cost, reason. commit(sim,profile,tool,cell)->bool.
MobileInputRouter.handle_event(event:InputEvent,over_ui:bool=false); signals tapped, panned, pinched, rotated, cancelled.
MobileCameraController owns zoom/yaw/pan/follow_enabled; Main adapts existing world picking math.

## Checks And Decisions

Test new domain behavior before implementation and run focused tests after changes. Android agent owns export tooling only; input agent owns standalone input/camera files only; main agent owns integration.
Use typed engine APIs and existing enums; keep UI out of domain classes. No paid asset generation unless needed. No publishing or shared-branch merge.
Ruling: complete the concise execution plan here, without another approval gate, because the user explicitly requested implementation unattended.
Ruling: retain profile XP across new maps; use monotonic profile raid index to avoid collision with reward receipts.

## Progress

Worktree: C:/Users/A/.codex/worktrees/mobile-25d/dungeon-empire
Branch: codex/mobile-25d
Initial quota: 98 percent weekly remaining; one reset explicitly authorized.

2026-09-28: user clarified that the mockups are the visual source of truth and
legacy assets are not a priority. Generated a transparent command atlas, Core
monument and four hero portraits with the built-in image tool. Runtime Core,
vaults and traps now use camera-facing 2D art inside the interactive 3D world.
Sources live in assets/mobile, not only in the generation output directory.
Cinzel font is distributed under its bundled OFL license.

First mobile launch uses a small authored, fully simulated starter dungeon so
raids can be tested immediately. Blank Core placement remains available after
defeat and by disabling Main.starter_enabled. XP persists across maps.

Independent review found loot intercepting explicit tool selection and missing
mage-pressure persistence. Added a failing UI regression before separating
collection into its own command; persistence fix delegated to save owner.

Domain end-to-end verification: 20 completed deterministic raids covering thief,
paladin, ranger and mage; every resulting snapshot validates and restores with
duplicate-reward protection. Native captures exercised 1280x720, 1560x720 and
960x540; these are desktop Compatibility-renderer evidence, not device FPS.

Initial APK exported successfully but was 940 MB. Final texture import budget
reduces the APK to about 206 MB; original images remain full-resolution. No phone is
connected, so installation, touch on hardware and sustained 30 FPS are pending.
Final quota check: 86 percent weekly remaining; no reset consumed.

Final verification: 38/38 suites passed. Independent review fixes verified.
Final APK rebuilt after UI/rendering changes; payload audit and Android v2/v3
signature checks passed. Package org.dungeonempire.prototype, arm64-v8a,
minimum Android API 24, landscape manifest, no requested permissions.
APK SHA256: 978393C482333476A9179B6926DDD694621F3E121FFAC072698465EC05E8154C.
No merge or push performed; keep codex/mobile-25d and the attached worktree for
the user's morning review. Logs/APK/captures remain local ignored artifacts.
