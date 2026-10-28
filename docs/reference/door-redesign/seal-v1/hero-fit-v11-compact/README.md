# Compact door — validated wireframe

User approved with “oui ça à l'air beaucoup mieux” on 2026-10-28. Production
integration now uses the byte-identical geometry in hero-fit-v12-integrated.
The following notes preserve the pre-approval review and rejected trials.

User rejected the oversized v9/v10 door, v25's high lock and hidden hands,
then requested thinner posts. The first thinning moved the posts away from
the wall; that was rejected too. Final v11 retains the exterior post plane,
depth, and exact lower junction faces. Material is removed toward the passage.
Height 1.445 -> 1.16 (-19.72%), opening .96 high / .63 wide. The upper crown
is shallower, not a uniform squeeze of the entire doorway. Hero scale stays .85.
The original outer column face remains at -T/2; main post width is .1+T/2
instead of .17+T/2. Only its inner side moves. Base junctions remain exact.

The user explicitly asks to see and validate this wireframe before continuing.
Do not treat technical checks or this page as approval. No new painting or
production integration is authorized until that validation. V10's production
asset trial and v25 active sprite replacement were reverted to HEAD; their
sources remain archived. Shared scene behavior is unchanged; two overridable
resource getters let this isolated fixture load local review sprites.

V26 lowers the lock from .49 to .32, advances wrists .10 model unit and opens
them laterally .035. Original mesh/materials, feet and camera remain intact.
The lock lies between hinges at .16/.64; it is not their exact midpoint.
Gold native marks indicate those future painted details, not modeled hardware.

## Reproduce

1. `node tools/prepare_compact_door.cjs`
2. `node tools/prepare_compact_door_preview.cjs`
3. Blender `--background --factory-startup --python-exit-code 1 --python tools/verify_compact_door_passage.py`
4. Godot `--path . --script res://tools/capture_compact_door_wireframe.gd --rendering-method gl_compatibility`

The v26 source uses render_lockpick.py, prepare.cjs and verify_saved_poses.py.
Its prepare script writes local native-resources, not active hero assets.
32 unique unclipped frames, fixed feet, source hash and saved-pose replay pass.
17 held full meshes fit the new convex opening, all fail the original tiny
opening. Eight lockpick meshes are XZ-disjoint from every masonry face box;
there is no minimum contact distance to report for those disjoint projections.
Native captures have zero registration failures. No continuous collision,
self-intersection, facial animation, physical phone, or swinging hinge claim.
No player save, APK, commit or push.
