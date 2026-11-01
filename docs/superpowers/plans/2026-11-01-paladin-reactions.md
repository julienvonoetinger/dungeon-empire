# Paladin damage and death implementation plan

> **For agentic workers:** Use superpowers:executing-plans for this continuation.

**Goal:** Render whole-character damage and death sprites from the equipped Paladin and provide native four-direction review scenes.
**Architecture:** Keep the approved v3 model/materials and v4 camera/physical scale. Pose the rig offline in Blender, render 512px masters, uniformly reduce and pack 256px frames. An isolated one-shot Godot preview exposes replay, pause, step and speed controls.
**Tech stack:** Existing Blender 5.2, Node/Sharp and Godot tooling.
**Spec:** User requests the two next animations in the established four-direction sprite workflow. Assistant's initial artistic choice: planted-foot recoil; knees buckle before a sideways armoured collapse with a held final corpse.

## Constraints
- Existing equipment grips/orientation and original GLB hashes are authoritative.
- No runtime 3D, repaint, raid integration, player saves, APK, commit or push.
- Work in the ongoing checkout; previous approved uncommitted sources must remain intact.
- English preview UI. Four actual rendered directions, no mirroring.
- Damage ends at neutral; death ends on the ground and never loops automatically.

## Review focus
- Heavy equipment must not cross the body or ground; inspect real deformed geometry and all directions.
- Knee flexion must precede torso collapse; final contact must not float or resemble a rigid tree fall.
- Fixed camera scale/anchor and no clipped boots, shield or hammer across all poses.
- One-shot timing, pause, replay, step, x2 and final holds must work in native scenes.
- Layout must fit landscape and portrait; existing Vulpin and Paladin gait resources remain untouched.

## Task 1 — source poses and native renders
- [x] Read existing rig/action recipes, record source hashes, inspect equipment and skeleton.
- [x] Create v5-reactions/render_actions.py and geometry checks; pilot representative impact, kneeling and grounded poses before full render.
- [x] Render all four directions; save packed poses and machine-readable contact/registration reports.

## Task 2 — assets and test scenes
- [x] Add tools/verify_paladin_reactions.gd and observe missing-scene failures first.
- [x] Create v5-reactions/prepare.cjs, paladin-hurt/death atlases, metadata and scenes/PaladinHurt.tscn plus PaladinDeath.tscn.
- [x] Add isolated scripts/paladin_action_preview.gd; verify real one-shot playback, fixed anchors, controls and three viewport sizes.

## Task 3 — validation and documentation
- [x] Reload the saved Blender pose file independently and validate contacts/grips/bounds.
- [x] Inspect native captures and animated reviews, run focused independent review and resolve findings.
- [x] Document pose choices, exact timings, dimensions, commands, byte counts and limitations. Check source preservation and final diff.

## Execution ledger
- Continued from existing gait work; no new worktree because these uncommitted approved assets are the input.
- No new brainstorming approval required: the user directly requests the next two animations using the established pipeline. Artistic timing/pose details are reviewable implementation choices.
- First pilot showed held hammer supporting the corpse and frame clipping. Explicit release of props plus folding the arms resolves support; hammer lies flat by rotating about Y. Death uses320px/ortho3.25, preserving exactly the256px/2.6 pixel density and hero scale.
- Native red:2missing scenes. One later fixture error expected repeat while deliberately paused; corrected test to resume before measuring repeat. No change to correct pause semantics.
- Final native350checks/0failures, import and native stderr empty. Real screenshots inspected in three sizes; short landscape now4columns and48px controls.
- Reloaded18held poses,4cameras, floor/grips, full equipment/body intersections after release, equipment/equipment intersections and original hashes pass. No gameplay changes or regression edits to Vulpin.
- Independent review (review_paladin_reactions) found no actionable issue in code, recorded checks or final native/master views. Remaining artistic/phone/continuous-geometry limits are explicit. Final diff check clean.

## User correction — forward fall instead of side roll
- User rejects v5 choreography. Follow the approved Vulpin kneel/reach/prone recipe, adapted to Paladin bone lengths. This supersedes the initial artistic choice; v5 remains historical.
- [x] Reproduce the mismatch: choreography fixture fails7criteria on the old source.
- [x] Build v6 independent chest/leg/arm/head poses, preserve original materials and other action hashes, inspect pilot views, correct head height and prop release path.
- [x] Render40death frames, re-pack only death, update the ground anchor and native shadow direction.
- [x] Reload18poses/fourcameras;10choreography checks and354native checks pass. Independent review found the hurt-shadow side effect, reproduced4redchecks and fixed it.
- [x] Record source/commands/limits and mark v5 death as superseded. v5 packer now handles hurt only, preventing accidental reinstallation of rejected death art.
