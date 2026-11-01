# Batrafian ranged bow attack implementation plan

Execute inline using the existing whole-model Blender sprite pipeline; one
fresh final reviewer. User requests shooting the Core at range. This continues
the approved animation workflow and equipment, not new gameplay/combat rules.

## Scope and chosen defaults

- Immutable v3 equipped source and original four GLBs. New v7-bow-attack source.
- Four actual iso directions, whole body/equipment render, approximately12
  held poses, draw/release/recovery. Left hand holds bow, right hand nocks/draws.
  Corde visibly follows the nock then returns on release. Original bow materials
  retained; local deformation/rigging of copied geometry allowed for string.
- Arrow supplied by user: visible while nocked, separate projectile sprite
  after release. No painted substitute or 2D character assembly. Avoid duplicating
  arrow during hand-off; trajectory starts at actual rendered nock/shaft anchor.
- Scene BatrafianCoreAttack: four actual Core/floor views, hero at a clear ranged
  distance, playback pause/step/x2/Repeat, impact only after projectile arrives.
  Aim at Core, not sideways. One shared animation clock and frame-skip-safe events.
- No gameplay integration, saves, APK, commit/push. Keep existing checkout because
  v3/v4/v5/v6 inputs are uncommitted. Leave preceding work unchanged.

## Tasks

- [x] Pose/render/pack: inspect bow string and arrow axes; independent failing
  choreography check; pilot drawn/release poses; verify grip, nock alignment,
  ground and equipment clearance. Save packed source, reload actual keyframes,
  four-view final renders. Compact atlas/nonlooping SpriteFrames/registration,
  arrow projectile texture and exact camera-derived anchors/timing.
- [x] Native ranged scene and tests: write failing fixture; implement stage/
  preview only, real Core and arrow flight. Test no premature/duplicate impact,
  pause/seek/replay/Repeat/x2, aiming/registration, three viewport sizes. Inspect
  captures and pose boards; reproducible docs/AGENTS.
- [x] Fresh final review, resolve actionable findings and record evidence.

## Shared interface

Pose pipeline produces registration.json: anchor, scale, variable frame timings,
release time, projected arrow nock/tip per view and projectile anchor. Native
scene consumes those exact values, with one flight duration chosen for preview.
Do not bake flight into body atlas or reapply camera scaling to projected values.

## Review focus

Bow hand/forearm roll, giant head clearance, visible drawn string and arrow,
no doubled/static string, nock stays in drawing hand, correct arrow tip direction,
same physical size as gaits, held feet, no jump at projectile handoff, target in
front, Core occlusion, impact crossing at high speed, final return and no saves.

## Ledger

- Existing PaladinCoreAttack establishes isolated target-stage architecture.
- Ranger simulation currently explores, not ranged combat. This task supplies
  animation and test scene only; no implicit redesign of raid rules.
- Choreography source red6/8 then green8; packed source independently reloaded
  at12poses. Raised nock and bow lift solve arm/head crossings. Early unreachable
  nock corrected with true carried-arrow poses before string contact.
- Four full renders,44unique320px regions +4projectiles,1,510,998PNG bytes.
  Last guard aliases first. Repacked only after renderer completion.
- Native red missing scene then475checks pass, import/native exit0/empty stderr.
  Three viewport sizes and pose board inspected. Actual captures packaged at
  normal/half speed; decoded images/timing checked despite merged WebP frames.
- Documentation and sources retained. Fresh reviewer found no actionable issue:
  475native checks/empty stderr,294asset/hash/repack/timeline checks, preserved
  source geometry/UV/weights/materials/images/rest skeleton, fresh choreography
  and12pose reload. Reports in artifacts/batrafian-attack/review. No gameplay,
  saves, APK, commit/push, physical-phone or exhaustive collision validation.
