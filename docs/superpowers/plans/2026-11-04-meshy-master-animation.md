# Meshy master animation implementation plan

> Execute inline with superpowers:executing-plans. Preserve unrelated work; no commits or gameplay integration.

**Goal:** Animate the supplied textured eye and volute as actual 3D models in a controllable native preview.
**Architecture:** A Blender recipe bakes two independent object-control tracks into a packed blend and animated GLB. Godot plays that asset with one explicit seekable clock. The eye grows at a fixed centre, while the separate volute expands and orbits, then settles into slow motion.
**Tech stack:** Blender 5.2.1, glTF, Godot 4.7.2 Compatibility.
**Spec:** User authorizes animation of the supplied eye/volute after static assembly, retaining in-place eye growth and original art. Existing sources: dungeon-master-review/source; static inspection v12.

## Constraints / decisions

- Keep supplied GLB bytes, source geometry, UVs, texture bytes unchanged.
- Use object transform controls for this first animation, not an invented humanoid skeleton. Internal eyelid deformation is not part of this pass.
- 18-second clip: volute appears 0-3 s; eye grows 3-8 s at fixed origin; motion slows and remains present 8-18 s. End holds until replay.
- No opaque eye visible before 3 s. The genuine eye model replaces the earlier procedural black disk.
- Volute rotates around the eye centre. Establish conservative spherical clearance from actual source geometry, valid throughout all sampled frames and rotations.
- Native preview is isolated: no sanctuary, characters, save, APK or production changes.

## Review focus

- Source fidelity after export/reimport; both meshes and all six maps present.
- Growth must not translate the eye or show it at the start.
- Pause, arbitrary seeks, replay and end hold must use the same time source.
- Real 3D depth and physical volute/core clearance during orbit, not only endpoint fitting.
- Entire model and controls fit portrait and landscape; original GLBs remain untouched.

## Tasks

- [ ] 1. Create a negative native fixture for absent MeshyMasterPreview, run and observe failure. Build Blender recipe under v13-model-animation, archive animated blend/GLB, check source hashes and clearance for complete timeline.
- [ ] 2. Add assets/previews/master-meshy/master-invocation.glb, scripts/previews/meshy_master.gd, meshy_master_preview.gd and MeshyMasterPreview.tscn. Play imported Invocation through explicit AnimationPlayer.seek; preview ends paused and supports replay/scrub/rotation.
- [ ] 3. Run native import and fixture: actual meshes, 18-second animation, fixed eye centre, hidden initial eye, changing volute orientation, deterministic seek, pause/replay/end and three viewport sizes. Inspect captures and animation.
- [ ] 4. Fresh independent review of these files and evidence. Resolve important findings; save sources/recipe/review limits and relaunch the native preview.

## Execution ledger

Ruling: retain current workspace and additive preview files; required user assets are uncommitted here, so no worktree migration or automatic commits.
Ruling: object-control animation is sufficient for growth, gaze and orbital motion; anatomical blinking would need a separate deformation design. Communicated as this pass's scope.
