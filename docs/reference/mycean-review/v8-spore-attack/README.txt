MYCEAN - SPORE BURST CORE ATTACK - 2026-11-02

User request: make a Core attack animation using a different spell from door
unlocking. Selected implementation: cyan/green gathering spores, a detached
orb cast with a forward staff thrust, and a spreading burst on the vortex.
The selection is an implementation proposal, not a recorded user art approval.

Open scenes/MyceanCoreAttack.tscn in Godot. Four real isometric views use the
same original painted/equipped Mycean. Pause, frame step,0.5x/1x/1.5x/2x and
optional Repeat use unchanged paladin_action_preview.gd controls. No game
session, damage calculation, raid integration, player saves or APK changes.

SOURCE AND CHOREOGRAPHY

Input: ../v2-meshy-inspection/mycean-equipped-review.blend, original GLBs in
../source. rig.py retains35bones, mesh/UV/weights/materials and all6textures.
Staff, grip lattice and hidden contact envelope remain children of Bone_031.
The complete evaluated body, including hands, is checked against the staff.
No mirrored images, body-part assembly, 2D painting or deformation.

Twelve held slots/1400ms. Wind-up leans backward6degrees with12degree twist;
release leans forward8degrees and pitches the staff68degrees. Feet use actual
sole meanX/Y plus minZ support. The first pilot's inward staff tilt crossed
the cap; an outward tilt then crossed the boot. Keeping the charged staff
axially neutral and tilted20degrees forward clears both; original grip and
attachment transforms remain unchanged. Final first/last evaluated geometry
matches exactly. Holds use CONSTANT keys. No continuous3D animation required.

Durations100,100,120,130,200,100,100,100,100,100,130,120ms.
Slots3/4 share the complete charge image; slot11 reuses neutral0. Ten unique
poses per direction,40native640px masters uniformly reduced to320px. Four
1600x640atlases:1,891,722PNG bytes,16,384,000RGBA bytes (15.625MiB).
Ortho3.25, targetZ.72, ground reference(0,-.20,0),30degree elevation. Shared
anchor(160,221.394539...), scale.9404255319148935 preserves gait pixel density.
metadata/ground_anchor and registration.json record projection and durations.

SPELL

Release650ms (pose5),320ms flight, impact970ms, burst ends1290ms.
Staff-cap emitter is measured from the actual mesh in every saved pose and
camera. Charge follows the current held pose, then the projectile starts at
the measured release emitter and detaches. Path ends at the production Core's
vortex centre, with a12px upward arc. Hero roots stay on their incoming axes,
two cells from the Core. Real Core painting, self-shadow, glow and vortex used.

mycean_spore_burst.gd / mycean_spore_orb.gdshader reuse the existing falloff
texture; no new effect PNG. A procedural mist surface, curling charge strands,
short trailing spores and expanding impact fragments use explicit action time,
never shader TIME. Vertex tint is passed separately so the fallback texture's
falloff does not multiply and shrink the procedural orb. Charge uses caster
depth. Free flight and target bloom use an aerial overlay in this floor-only
test stage; obstacle clipping would require integration work in real raids.
Layout reserves34px at emitters and78px at the impact. Shader has no vertex
displacement, avoiding the old arcane strip culling issue.

REPRODUCTION (from repository root, dedicated background Blender)

1. Blender5.2.1:
   blender --background --python-exit-code 1 --python
     docs/reference/mycean-review/v8-spore-attack/render_attack.py
   -- --pilot renders charge/cast SE/NW; -- --poses-only skips rendering.
2. blender --background --python-exit-code 1 --python
     docs/reference/mycean-review/v8-spore-attack/verify_saved_attack.py
   Optional -- <original equipped blend> runs the standing negative control.
3. NODE_PATH must contain sharp. Run node
     docs/reference/mycean-review/v8-spore-attack/prepare.cjs
4. godot --headless --path . --editor --import
5. Run native checks sequentially (not headless for screenshots):
   godot --path . --script res://tools/verify_mycean_attack.gd
   godot --path . --script res://tools/verify_mycean_spores.gd
6. node docs/reference/mycean-review/v8-spore-attack/assemble_review.cjs
7. Optional suite: powershell -File tools/run-probes.ps1
     -Report artifacts/mycean-attack/probes.json

Windows: quote executable paths with spaces; use Start-Process -WindowStyle
Hidden -Wait -PassThru with separate stdout/stderr. Check stderr as well as
exit code. Do not touch the user's open Blender or player save data.

VALIDATION

Missing native scene fails first; original standing source fails5choreography
checks. Final saved blend354checks pass, native preview704checks pass and
effect17checks pass. Seven headless gameplay probe scenarios pass. All final
native/import stderr logs empty. Evidence in artifacts/mycean-attack.
Source checks verify actual saved emitter, full staff/body surface crossings,
fixed sole supports, exact neutral recovery, four camera margins, immutable
GLBs/equipped scene, meshes/UV/weights and six packed original textures.
Native tests cover release/impact boundaries, large2xtick, pause/seek/replay,
planted actor/shadow, sprite/effect bounds and48px controls in desktop,
portrait and short landscape. Effect readback tests prove clock determinism,
animated flow, bright nucleus and no persistent beam at the caster in flight.
Independent read-only review:154asset/hash/repack/timeline checks and15saved
source-preservation comparisons pass; no actionable finding. Evaluated neutral
body differs from original static source by max.001673modelunit(~.155nativepx),
while base mesh data is identical and first/last attack geometry matches.
Actual mean-sole support maximum error.000030764modelunit.

Native WebPs sample0..1400ms every40ms; last endpoint held1s, total2400/3800ms
for normal/slow. Body-only WebPs include1.2s neutral pause. Identical adjacent
pages coalesce without changing delays. Both native and body sources retained.

LIMITS

Large original cap hides the face in isometric views; no facial morphs.
Mean sole support is fixed, not every original weighted boot vertex rigid.
Held-pose surface tests are not exhaustive self/contained-volume collision
tests or continuous3D motion validation. Impact is a visual2D alignment.
Physical-phone GPU profiling remains undone. docs/.gdignore excludes all
source/masters/review files from exports. Only preview assets are runtime art.
