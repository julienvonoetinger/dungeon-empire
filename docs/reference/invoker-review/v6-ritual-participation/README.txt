Ritual participation and clipping corrections - 2026-11-04

User feedback: clipping between actors and scenery, master's tail cut by altar,
Oculins walking through a stone, followers should raise arms with invoker,
invoker body too large relative to followers.

prepare.py projects actual Z=0 ground vertices from the approved sanctuary
wireframe (v1/geometry.json), takes convex hulls and translates them to the
current InvocationSanctuary Sprite2D positions. 42 footprint polygons are saved
to assets/game/introduction/procession/obstacles.json. Art is not moved/edited.
invocation_paths.gd inflates the projected polygons38px horizontally/19px in
depth, routes with AStarGrid2D and removes unnecessary waypoints only if the
whole segment retains clearance. Navigation anchors connect to exact start/end
points without rounding them into an obstacle. Never falls back to straight
travel through scenery. Actor widths are represented by conservative ground
clearance, not by image bounding boxes including head/arms.

Formation: invoker (0,235), two followers (+/-105,420), two (+/-105,555).
Follower scale .9, invoker .95: comparable body stature with taller staff.
Landscape focus moved to y100 to retain whole formation. Portrait zoom kept.
Preview reserves64px outside film for controls. Master depth55 is now in front
of Dalle depth54.4; forward menhirs still retain normal foreground occlusion.

bake.py generates48 whole-model Oculin chant poses from unchanged source GLB.
Both arms follow the same lift/hold/lower envelope as the invoker. Native alpha
384px masters -> uniform256px atlas. Original existing poses/atlases unchanged.
All five actors use same chant frame10-20s; final frame returns to neutral before
appearance20-22s and kneeling22s onward. No new spoken audio.

Native regression before fixes: three actual footprint crossings
(RocheApproche5,4,3), followers not chanting, master below Dalle;16 failures.
Updated native fixture passes, empty stderr. Checks sampled foot clearance,
actor-to-actor ground clearance, same chant phase, initial full offscreen entry,
master depth, timeline ordering/reset/release, comparable invoker scale and
actual visible sprite bounds above controls in three window sizes. Native
screenshots inspected. Independent review identified offscreen spawns inside
Eboulis11 at narrower portrait ratios. Spawns now scan down to a clear area,
retaining160px spacing within each lane. Added360x640 and390x720 alongside
1280x720,390x844,844x390, including real preview bounds minus64px controls.
All five sizes and complete path-segment clearance pass. Conservative
footprint checks are not full 3D animated
self-collision or foot IK validation. No APK/save edits/commit/push.
