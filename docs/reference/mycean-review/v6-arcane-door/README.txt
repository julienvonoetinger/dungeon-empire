Mycean — staff-channelled arcane opening, 2026-11-01

User request: use the staff to cast at a magically locked door, rather than
reusing the thief's hand lockpicking. Follow-up confirms a special door leaf
with a magic seal. Both are shown together in MyceanArcaneDoor.tscn.

Scope: isolated four-direction preview, no RaidDirector/actor integration,
player saves, APK, commit or push. Mage gameplay still uses the existing
MAGE_ARCANE_OPEN_HOLD=1.5 seconds. The clip resolves at that time and has350ms
visual recovery (total1850ms). Channel begins450ms after raising/aiming.

Source and geometry
-------------------
Immutable v2-meshy-inspection/mycean-equipped-review.blend; original source
GLBs and hashes in ../source/provenance.json. Reuse35bones and all original
body/staff meshes, UVs, weights, materials and six packed2048px images.
The approved hand corrections and THREE Bone_031 children (staff, grip
lattice, hidden contact envelope) remain mounted and enabled throughout.
No live Blender session, repainting, body compositing, mirroring or mesh cuts.

rig.py retains v3/v5 mapping and original forearm roll. See v3-locomotion
and v2-meshy-inspection recipes for imported rig/grip diagnostics. render_unlock
solves legs against actual sole meanX/Y and minZ, raises staff wrist by .13,
moves it forward .12 and outward .04, with pitch45deg/outward-15deg at peak.
Root compresses .035 and leans3deg. Original cap stays intact.

Twelve timing slots use strengths[0,.3,.65,1,1,.98,1,.98,1,.65,.25,0].
Durations ms[100,100,120,130,210,210,210,210,210,100,120,130].
Only six distinct poses per view need rendering: source indices0,1,2,3,5,10.
All twelve held bone states are keyed CONSTANT in mycean-unlock-poses.blend.
Identical whole poses share atlas regions. End is exactly the initial image.

Four actual30deg orthographic cameras, ortho3.25, target(0,-.20,.72),640px
masters uniformly reduced to320px. Pixel density and scale.9404255319148935
match gaits. Anchor160,221.394539. prepare.cjs verifies actual projected anchor.
24master images -> four1920x320atlases,1,099,923PNGbytes/9,830,400RGBAbytes.
Review WebPs coalesce identical adjacent frames and preserve duration, with
1200ms final hold. Native review is captured at40ms intervals and has1s pause.

Emitter / beam / door
---------------------
Local staff cap emitter averages vertices in its top .025 localZ and uses
maxZ+.012. Each saved pose reprojects that actual point; registration.json
records per-direction runtime sprite pixels, not guessed screen offsets.
Spell receiver is the new painted seal at world height .64, on door plane
cell+(.5,.5)+outward normal*.025. The older mechanical keyhole remains at .32.
Hero stays1.05cells from that plane. Thin native violet/cyan beam, traveling
light motes, source glow and short release ring use the same action_time as
the sprite. No independent timer, random frame jitter or baked effect sprites.
Spell shares actor's physical sort layer. The far-side closed door correctly
occludes its ray and target, rather than the effect painting over stone.

Magic leaf is built-in ImageGen native painting, prepared via the existing
smooth leaf mapping. Recipe, exact prompt, provenance, accepted source and
rejected initial image: ../../door-redesign/seal-v1/arcane-v1/README.txt.
tools/prepare_arcane_door_review.cjs writes16 closed sortedparts under
assets/previews/mycean-unlock/door:302,805PNGbytes/987,936RGBAbytes.
Do not replace only the legacy '-leaf' ID: it is LEFT JAMB; '-panel' is the
actual battant. Stage duplicates production catalogue and overlays all16parts.
No active kit selection or shared Resource is mutated. On release, all closed
parts hide and the three production open masonry pieces remain visible.

Reproduction from repository root, PowerShell
--------------------------------------------
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
& $blender -b -t 8 --python docs/reference/mycean-review/v6-arcane-door/render_unlock.py
& $blender -b -t 8 --python docs/reference/mycean-review/v6-arcane-door/verify_saved_unlock.py

$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
& $node docs/reference/mycean-review/v6-arcane-door/prepare.cjs
& $node tools/prepare_arcane_door_review.cjs

$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
Start-Process $godot -ArgumentList '--headless --path . --editor --import' -WindowStyle Hidden -Wait
Start-Process $godot -ArgumentList '--path . --script tools/verify_mycean_unlock.gd' -WindowStyle Hidden -Wait
& $node docs/reference/mycean-review/v6-arcane-door/assemble_review.cjs

Use --poses-only for model diagnostics, --pilot for two-view representative
renders. Run graphical fixture processes sequentially on Windows. docs/.gdignore
excludes raw source/review data; runtime preview files are small prepared assets.

Evidence / limits
-----------------
Missing-scene fixture failed initially. Saved-source352checks pass, full
body/staff surface crossings0 (including hands), max sole supporterror.0000223.
Source verifier independently reloads packed scene, checks mesh/UV/weights,
all attachments/texture hashes, cameras, actual emitter and exact recovery.
Native fixture738checks pass with empty stderr: controls/phase boundaries/1.5s unlock/pausing/stepping/
0.5x–2x/large ticks/Repeat/manual-seek inertness, fixed root, all four emitter
positions, prepared magic painting, depth order, open frame and three viewports.
Native logs/captures: artifacts/mycean-unlock. Independent review found no
important issue and passed206fresh asset assertions. Door231preparation and
134independent invariant checks preserve geometry/masonry/openparts/30inputs.

The cap still hides much of the face. Original shin weights flex boots; mean
sole support is stable, not every vertex rigid. Held surface checks do not
prove every self/contained-volume collision or arbitrary continuous3D motion.
No physical-phone profiling, interactive raid outcome or traversal validation.
