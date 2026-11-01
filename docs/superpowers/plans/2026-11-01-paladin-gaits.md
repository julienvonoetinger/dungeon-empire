# Paladin walk and run implementation plan

> **For agentic workers:** Execute inline with `superpowers:executing-plans`; obtain one focused review at the end.

**Goal:** Create whole-character walk/run sprites from the supplied Lithide GLBs and inspect them in four-direction corridor scenes.

**Architecture:** Use the approved equipped v3 Blender scene as the pose source. Hold eight explicit poses per gait, render four 30-degree orthographic views, pack 256px frames, and reuse the existing corridor playback with configurable sprite registration.

**Tech Stack:** Blender 5.2.1, Python, Sharp, Godot 4.7.2.

**Spec:** User request in this chat; `docs/production/hero-animation-pipeline.md`; approved equipment in `docs/reference/lithide-review/v3-equipment-grips`.

## Constraints and decisions

- Original GLBs/materials unchanged. Hammer strike direction remains forward/back and props follow the closed hands.
- Walk 8 poses at12fps, run 8 at16fps, matching displacement to the planted stride. Heavy armored motion; course uses a distinct lean, stride and airborne phases.
- Sources/review in `docs/reference/lithide-review/v4-locomotion`; only packed sheets/resources in `assets/previews/paladin-walk` and `paladin-run`.
- No raid roster/gameplay changes, saves, APK, commit or push. Keep the current authorized feature checkout because this task continues its uncommitted approved GLBs/pose work.
- Existing Vulpin cadence, resources and default registration must remain unchanged.

## Review focus

- Equipment/armor intersections and grip drift across all16 poses.
- Planted boots, raised recovery foot, loop seam and run suspension.
- Common camera scale/anchor in all views, unclipped hammer/shield.
- Travel synchronized with cadence at1x/2x; four directions reached on reversal.
- Portrait/landscape controls and foreground masonry ordering.

## Task 1 — held 3D poses and renders

- [x] Create `v4-locomotion/render_gaits.py`, source registration/report and saved-scene checker.
- [x] Render pilot poses, inspect front/rear and contacts; refine only from evidence.
- [x] Render all64 transparent masters, save16 constant poses in one packed blend.
- [x] Reload and verify bounds, weights, source hashes, grips, equipment clearance, sole contacts and camera frame.

## Task 2 — sprites and corridor scenes

- [x] Add `tools/verify_paladin_gaits.gd`; first run must report absent new scenes.
- [x] Create `v4-locomotion/prepare.cjs` and compact atlases/SpriteFrames, preview loops and manifest.
- [x] Parameterize sprite registration in the existing two corridor scripts with unchanged Vulpin defaults.
- [x] Create `scenes/PaladinWalk.tscn` and `scenes/PaladinRun.tscn`.
- [x] Run native tests for both gaits and the existing Vulpin walk/run regression fixtures, serially.

## Task 3 — review and preservation

- [x] Inspect review pose sequences and actual native corridor captures at landscape/portrait sizes; animated WebP timing and frames verified.
- [x] Document exact commands, sources, rates, sizes and known limitations. Update only intentional shared-script entries in the Vulpin preservation manifest.
- [x] Focused independent review; resolve actionable issues; final diff/source checks.

## Execution ledger

- Started from `codex/2d-foundation`, with AGENTS and Lithide source/reference work already pending. No other pending runtime edits.
- Task scope is isolated animation scenes; live raids remain Vulpin-only until other paladin actions exist.
- Pilot: original ankle-based lifts dipped boot toes into the floor (up to .058 model units). Correct each leg iteratively against evaluated boot soles, including recovery/flight poses. All16 poses now have expected sole heights and0 nonhand equipment crossings.
- Native red check: both new scenes absent,2 expected failures. Godot GUI executable must be launched with Start-Process/WaitForExit to capture the real exit code.
- Task1complete:64masters,16pose replay,12support intervals. Recomputed collision tests after saved-scene reload also pass.
- Task2complete: native708checks/0failures, Vulpin walk/run regression0failures, empty final stderr. Three native viewport sizes inspected.
- Task3complete: independent review no actionable defect; strengthened saved checker per validation-scope observation. Only2intentional Vulpin manifest hashes updated;6preexisting differences verified identical to HEAD, no unexpected mismatch.
