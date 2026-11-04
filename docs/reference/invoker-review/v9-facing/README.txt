Departure depth and invoker facing correction — 2026-11-04

User sees flying master cut by altar and invoker moving sideways. Native
check_departure_facing.gd reproduces seven failures before correction.

Master's ground anchor moves behind Dalle before his hovering image clears it.
invocation_sanctuary.gd now keeps him after Dalle while their projected bounds
intersect, then returns to existing scenery depth and physical stair masks.
Scenery order, images and motion are unchanged.

The v8 camera labels had left/right reversed: camera45 rendered NW, not NE.
render.py now records actual projected forward(0,-1,0) using Blender's evaluated
camera projection. Correct azimuths: N0 NE315 E270 SE225 S180 SW135 W90 NW45.
Original v5 N and opposite-labelled v8 diagonal masters reused byte-for-byte;
75 additional384px whole masters render E/W/S from unchanged packed v5 blend.
No mirrored art or model painting changes. pack.py uniformly reduces256px and
prepares16runtime atlases; source and original v8 outputs remain archived.
directions.json records physical heading, source hash and master provenance.

Runtime inverse-squashes screenY and chooses nearest of eight headings. Walk
phase accumulates along path segments, so a direction change no longer jumps
to a different fraction of the gait. Per-camera ankle excursion scales cadence
relative to the previously used90px diagonal cycle; direct raw excursion gave
an undesired five cycles/second. This retains a stylized gait, NOT a new rigid
foot-plant/IK or no-skid proof. Existing equipped pose/contact limits remain.
Dungeon walk and final idle both face SE toward the Core.

Reproduce in dedicated background Blender:
  blender --background --python docs/reference/invoker-review/v9-facing/render.py
  python docs/reference/invoker-review/v9-facing/pack.py

Evidence: artifacts/sanctuary-procession/facing-red.log, facing-*.log/.err,
facing-*.png and refreshed follow-surface/dungeon captures. Native heading
checks compare against projected Blender vectors; phase is monotonic across
all route segments. Physical entry/follow/dungeon handoff verified three sizes.
No player saves, APK, commit or push. Source/review excluded by docs/.gdignore.
