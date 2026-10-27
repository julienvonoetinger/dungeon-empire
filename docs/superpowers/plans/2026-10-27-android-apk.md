# Playable Android APK implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline. Preserve the current uncommitted artwork and HUD changes.

**Goal:** Produce a downloadable, debug-signed APK of the current playable game.
**Architecture:** Fresh ignored staging project containing game dependencies and explicitly included dynamic HUD/terrain assets; preserve the old visual-kit preset. Use installed Godot 4.7.2 and its matching Android templates.
**Tech Stack:** Godot, Node.js, Android SDK 35, Java, apksigner.
**Spec:** User request: « Est-ce que tu peux faire un apk téléchargeable ».

## Constraints and review focus

- Include current working files, not only HEAD; do not commit or push.
- Preserve live editor/cache, game behavior and normal player save.
- Include dynamically loaded textures, fonts and global GDScript classes.
- Exclude authoring sources, historical previews, attachments and credentials.
- ARM64 and ARMv7 test APK, landscape as in the existing Android preset.
- Verify packaged startup, manifest and signature; do not claim phone testing.

## Tasks

- [x] Inspect installed Godot/templates, SDK/JDK and old kit-only preset.
- [x] Add reproducible game staging and dedicated APK preset; import and export.
- [x] Verify APK signature/manifest/content and startup from packaged resources.
- [x] Fresh read-only review, document result and give the APK link.

No implementation unit tests for this reversible packaging change. Actual import,
export, APK inspection and packaged startup are the acceptance checks.

## Results

- Initial export correctly refused missing ETC2/ASTC import support. Enabled it
  only in the staged project; final import/export exit 0, empty stderr.
- 90 source dependencies (3,190,477 bytes); APK 61,076,174 bytes, ARM64 + ARMv7.
  Android API 24 minimum / 36 target, package `org.dungeonempire.preview`.
- apksigner exit 0: APK v2/v3 verified. Launcher alias MAIN/LAUNCHER confirmed.
  No requested permissions, credentials, saves or authoring directories in APK.
- Exact assets extracted from APK into a resource ZIP: native GPU startup exit 0,
  empty stderr; initial state, prepared dungeon, four catalogue families and raid
  exercised with an isolated artifact save. Prepared screenshot inspected.
- Independent read-only review found no actionable issue; all 90 source hashes
  match working files. Original project/preset unchanged.
- SDK35 tools signed the SDK36 template successfully. Java25 emits a native-access
  warning in apksigner; signature verification succeeds. No Android device or
  emulator connected, so phone installation, touch and performance remain untested.
- APK SHA256: A2E69951CA392239A42FB3FCAEB388800AB7CB1EC8E847E80FE41CB629827283.
