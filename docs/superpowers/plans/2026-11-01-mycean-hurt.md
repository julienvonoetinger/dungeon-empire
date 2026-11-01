# Mycean hit reaction implementation plan

> Execute inline using executing-plans, followed by one fresh independent review.

**Goal:** Whole-model hurt sprites and an isolated four-direction MyceanHurt scene.

**Architecture:** Load corrected equipped Mycean, preserve all three wrist attachments, pose backward recoil with fixed feet and exact recovery, render32whole-model images and reuse unchanged paladin_action_preview.gd.

**Tech stack:** Dedicated background Blender5.2.1, Node/Sharp, Godot4.7.2.

**Spec:** User requests Mycean damage animation after walk/run/death. Prior Vulpin feedback rejects sneeze-like forward snaps. Use eight held poses/720ms, backward recoil, restrained staff motion held throughout and a slower recovery. No new facial painting.

## Constraints

- Current feature checkout retains uncommitted Mycean sources/dependencies. No APK, commit, push, raid or player-save changes.
- Preserve mesh/UV/weights/textures, corrected grip lattice and contact envelope; no hand exclusions in equipment/body checks.
- Fixed feet and native root; verify actual sole contacts and support motion. Root can compress inside the sprite but feet must not travel.
-512px masters uniformly reduced to256px, ortho2.6/30degree camera, four actual directions, gait anchor/scale unchanged. Exact first/last pose, resource nonlooping.

## Review focus

Backward reaction readability instead of sneeze; boot support sliding; staff/cap/hand crossings; recovery discontinuity; viewport cropping/timing/native pause/replay/2x.

## Tasks

- [x] 1. Add native fixture and observe missing scene failure. Implement v5-hurt rig/render and independent saved-pose validation. Inspect pilots and resolve contact/registration issues.
- [x] 2. Render32masters, pack four atlases/SpriteFrames/MyceanHurt.tscn, animated normal/slow review and pose board. Validate dimensions, exact recovery and timing.
- [x] 3. Run native import/fixture and visual checks at three sizes. Document reproduction/results/limits and update AGENTS. Independent source/asset/native review; resolve important findings.

## Progress

2026-11-01: Established whole-model hero workflow reused. Exact recoil/staff offsets are implementation choices validated from geometry and pilot images.

2026-11-01 complete: Missing native scene failed first; standing source fails3recoil criteria. Pilots and full saved source pass200checks, zero staff/body crossings with hands included, mean-support error max.0000231. Ruling: original shin/foot weights create minor boot flex (~1.35nativepx horizontal for remaining floor vertices); document it rather than alter source weights. No root travel.

Strict endpoint image check initially failed because32raw renders include a few +/-1/255 channels despite exact first/last geometry. Allmasters retained; preparation verifies<=1channel difference then aliases the complete neutral image, recording both raw/runtime hashes. No body compositing. Independent review also caught nonexistent generated script path; corrected to existing shared paladin_action_preview.gd plus existence guard.

Final pack1,330,149PNGbytes,8MiB RGBA; normal/slow review, reproducible blend/scripts and MyceanHurt scene complete. Import and275native checks pass, stderr empty. Independent87source/292asset checks and three-size inspection pass; no important finding. README/AGENTS document recipe/limits. No raids/save/APK/commit/push.
