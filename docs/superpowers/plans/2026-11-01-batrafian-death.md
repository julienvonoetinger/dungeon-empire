# Batrafian death implementation plan

Execute inline with the established whole-mesh sprite pipeline and one final
independent review. User request: make the Batrafian death animation. Earlier
hero feedback requires knees first, forward fall, arms extended/chest grounded,
head turned, a brisk cadence, and a held final corpse rather than looping.

## Decisions and scope

- v3 equipped source remains immutable. Four real iso views, ten held poses,
 650ms total. Render320px frames at unchanged physical hero scale; compensate
  camera/anchor for the extended body. No repainting or runtime body assembly.
- Drop bow beside the body before palms receive weight. Quiver remains attached
  to torso; spare arrow stays hidden. Preserve corrected forearm roll while bow
  is held, then open grouped fingers and orient palms/forearms toward the ground.
- New v6-death source/review, assets/previews/batrafian-death, BatrafianDeath.tscn
  and native verifier. Reuse common action controls without changing prior heroes.
- No raid integration, player saves, APK, commit or push. Continue current
  feature checkout because the source model and prior animations are uncommitted.

## Steps

- [x] Build independent choreography checks; standing source fails corpse criteria.
- [x] Pose/review kneeling, catching and final corpse; validate floor, equipment,
  source preservation and actual saved-pose replay before final40renders.
- [x] Pack four1600x640 atlases and non-looping SpriteFrames; scene with four
  directions, replay/pause/frame-step/slow/x2, final pose held until explicit replay.
- [x] Native validation at three sizes, artistic inspection of all pose boards,
  final review, recipe/AGENTS/evidence updates, deliver preview and scene.

## Review focus

Avoid rigid body rotation, push-up arms, floating chest, giant head driving body
above floor, bow clipping hand/ground after release, quiver intersecting prone
body/head, accidental return to standing and sprite-scale changes.

## Ledger

- Inspected approved Vulpin v24 and Paladin v6 forward-fall recipes. Adapt bone
  lengths and hand bases to the26bone Batrafian instead of copying indices.
- Choreography source standing:9failures/12; revised saved poses:12pass.
- Initial pilot quiver crossings on last4poses. Retained torso parenting with
  gradual strap sway(-.12,+.055,0); orientations/scale/rest pose unchanged. All
  ten revised poses have0body/equipment edge crossings; bow stays landed from4.
- Saved reload:10poses,4camera frames,4GLB/source hashes/12packed textures pass.
-40renders produced, uniform320px packing:1,470,407bytes PNG/15.625MiB RGBA.
- Import/native exit0, empty stderr;303checks at3sizes including every frame's
  visible alpha fit. Inspected pose board and3native sizes. Recipe/review ready.
- Final independent review: no actionable implementation finding. Independently
  verified40master/reduction hashes,4byte-identical atlas repacks,1850/2500ms
  WebP timings, source hashes, fresh Blender reload/choreography and native views.
