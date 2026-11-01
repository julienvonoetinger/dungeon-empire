# Batrafian jump implementation plan

> Execute inline with superpowers:executing-plans; final fresh-context review.

**Goal:** render an equipped Batrafian forward jump in four directions and
provide an isolated Godot scene showing it clearing a trap.

**Architecture:** same immutable v3 equipped Blender source and whole-mesh
renders as locomotion. Twelve held poses, including identical rest endpoints,
in one second. Ground translation and airborne height are separate continuous
preview motion, not baked twice into the sprites. Reuse existing action-preview
controls; new Batrafian-specific stage supplies real floor/trap and shadow.

**Spec:** user's request to make the jump animation, established whole-sprite
workflow and current ranger trap-jump rule (two cells, TRAP_JUMP_TIME=1.0).
Creative choices: anticipation, thrust, tucked flight, extended landing and
recovery. 0.20s launch, 0.67s touchdown, .55 model-unit root apex. Preview only.

## Constraints

- Work in current feature workspace with uncommitted source assets; preserve
  gait files, four original GLBs, equipped v3 attachments and forearm roll.
- No raid behavior changes, player saves, APK, commit or push.
- Shared256px registration and physical hero scale; four actual iso views.
- English scene UI, French review/documentation. Original arrow stays hidden.

## Tasks

- [x] Generate v5-jump render_jump.py and independent verify_saved_jump.py.
  Pilot deepest crouch/tuck/landing; verify soles and nonhand equipment clearance
  before full renders. Preserve root-local poses and root-height metadata.
- [x] Pack48 rendered frames (44 unique atlas regions, reused rest endpoint)
  into assets/previews/batrafian-jump. Native frames have variable duration,
  loop=false. Build review animations with actual vertical motion and shadow.
- [x] Add BatrafianJump.tscn, batrafian_jump_preview.gd and batrafian_jump_stage.gd,
  reusing paladin_action_preview controls without modifying shared scripts.
  Four stages show jumping over ready spikes; shadow remains on floor.
- [x] Native verify_batrafian_jump.gd: missing scene fails first, then timing,
  phases, ground motion only during flight, peak/touchdown, pause/step/x2,
  replay/repeat and final resting pose at landing; fit landscape and portrait.
- [x] Inspect actual sprites and native captures, write recipe and AGENTS note,
  complete one independent review and report the available preview/scene.

## Review focus

Avoid double altitude, sliding during wind-up/reception, bowed long toes through
the floor, quiver/tunic clipping in tuck, lost bow-hand forearm roll, and a
loop restarting without a deliberate replay. Check start/end root-local equality.

## Evidence ledger

- Existing gait source and scripts inspected. Ranger already skips a known live
  trap with a1s jump over2cells; this work supplies the dedicated visual proposal.
- Pilot deepest crouch/tuck/landing inspected; all12poses pass independent
  reload, soles/props, geometry replay, original hashes and identical endpoints.
- Complete48master renders/44unique sprites,4atlas1536x512,1,556,616PNG bytes.
  Atlas width stays below2048 without shrinking the256px character images.
- Review timing initially failed: WebP10msframes decoded at100ms. Fixed by
  sampling review at20ms; exact native phase durations unchanged. Normal1800ms,
  slow2800ms including800ms rest. This preview is in-place; native shows travel.
- Native fixture first failed for missing scene, then363checks pass at3sizes;
  import and native stderr empty. Actual crouch/apex/reception captures inspected.
- Recipe and AGENTS note written; original/shared scripts remain unchanged.
- Final independent review: no important issue. All48master/sprite hashes,
  four byte-identical atlas repacks, original source hashes and decoded WebP
  durations checked. Desktop/short landscape/portrait images inspected.
- Complete within isolated-preview scope. No APK, commit or push.
