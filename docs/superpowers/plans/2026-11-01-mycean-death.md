# Mycean fall and death implementation plan

> Execute inline using executing-plans, followed by one independent review.

**Goal:** Whole-model death sprites and an isolated four-direction native scene.

**Architecture:** Preserve the equipped Mycean source and original painting; create ten held Blender poses, render four true isometric directions, pack nonlooping SpriteFrames and reuse paladin_action_preview.gd without changing it.

**Tech Stack:** Background Blender 5.2.1, Node/Sharp, Godot 4.7.2.

**Spec:** User requests Mycean death after walk/run. Established death direction from prior heroes: knees first, forward collapse, relaxed extended arms and resting torso, not a rigid sideways fall or a push-up. Mycean staff must release and settle beside him; large original cap requires its own head orientation/contact inspection.

## Constraints

- Continue existing feature checkout; uncommitted Mycean source/gaits are dependencies. Preserve all prior work, no commit/push/APK/raid/save changes.
- Original meshes/UV/textures; animation poses and offline hand-release modifier strengths only. Preserve corrected grip while held; fade correction after release, retaining the original source unchanged.
- Ten poses, initially650ms matching Batrafian; four actual cameras, no image mirroring/cutout body animation. Final pose held until explicit replay.
- Source/masters excluded by docs/.gdignore. Dedicated background Blender; native fixtures serial/hidden.

## Review focus

Knee-first weight transfer; cap lifting torso off floor; hand/staff penetration during release; staff floor/body contacts; native size/anchor, final hold, same speed clock and mobile viewport fit.

## Tasks

- [x] 1. Adapt tools/verify_mycean_death.gd and observe missing scene failure. Add v4-death rig/render/independent choreography and saved-source checks. Generate pilot poses, inspect knee/torso/hand/cap contacts and release, correct geometry before full rendering.
- [x] 2. Render40masters, prepare320px sprites/four atlases plus MyceanDeath.tscn, animated normal/slow review and pose boards. Preserve source hashes and reproducible pose bundle.
- [x] 3. Run saved-source, packing and native checks; inspect desktop/landscape/portrait. Document recipe/measurements/limits in README and AGENTS; independent final review and resolve important findings.

## Progress

2026-11-01: Scope continues the established hero workflow. Choreography follows the user's earlier death corrections; exact Mycean joint/contact positions are implementation choices to validate from pilots.

2026-11-01 complete: Native missing-scene failure confirmed. Standing source fails10/12 choreography checks. Pilots found source-preserving pose0 must remain exact (new leg pose crossed staff near boot), and boot folding caused a .263→.311 pelvis rebound. Original standing pose and revised boot orientations fix both; maximum remaining upward settling<.006. Ruling: Mycean short legs require anatomical lower-by.11/knee<.12 thresholds rather than inherited taller-hero thresholds. The large cap follows a separate head orientation; it still obscures front views.

Full40masters generated, nonlooping650ms pack and isolated native scene complete. Twelve choreography checks, ten saved poses, import and303native checks pass; stderr empty. Fresh independent review77source and222asset checks plus native three-size visual inspection found no important issue. Shared runtime scripts unchanged. Recipe documents modifiers/releases/contacts/size/limitations. No APK, raid integration, saves, commit or push.
