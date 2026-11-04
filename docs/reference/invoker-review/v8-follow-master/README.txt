Invoker follows master — 2026-11-04

User correction: invoker too small in dungeon, appears near Core magically,
does not follow master. Replaced the .48 static sprite/fade with the equipped
animated Actor at .95 on both scenes' identical256px grid pitch.

render.py opens unchanged v5-procession/invoker-poses.blend and changes only
camera azimuth to NE45/SE135/SW225/NW315, elevation30deg, ortho3, same ground
registration. Original equipped rig, corrected grip, staff and painting remain.
100 whole384px masters (idle+24walk perview); pack.py uniformly reduces256px
and writes eight atlases to assets/game/introduction/invoker-follow. No body
assembly, image mirroring or repainted textures. Original rear view remains in
the procession assets. Source hash and recorded angles in render.json;
runtime hashes/bytes in packed.json. Existing gait/contact limitations remain:
no new exhaustive3D collision or support-foot IK proof is claimed.

Dedicated background Blender:
  blender --background --python docs/reference/invoker-review/v8-follow-master/render.py
  python docs/reference/invoker-review/v8-follow-master/pack.py

Surface: invoker rises from bow28.5–29.3s, walks around altar/scenery29.3–35.7s,
descends actual stairs35.7–37.9s, enters tunnel by38.7s. Camera holds through
40.4s before covered dungeon cut. Master's accepted trajectory remains intact;
four other Oculins stay kneeling. Departure-only navigation expands to northern
scenery, excludes destroyed rock, includes moved footprints and altar.
Independent invoker occlusion material maps atlas UVs to local frame before
sampling actual stair masks/ground clipping; master material stays separate.

Dungeon: invoker walks from behind the remote stair endpoint to existing lesson
destination .8–8.4s, behind master. Opacity transition only at remote stair entry;
no mid-room fade-in. Arrival and lesson use same actor, scale and destination.
Core timing unchanged: master arrives6.5s; sphere awakens6.6–8.6s.

Missing-follow regression failed twice before implementation. Native follow,
procession, magic, physical-entry, transition and dungeon-handoff checks pass.
Evidence: artifacts/sanctuary-procession/invoker-follow* and follow-*.
Native captures reviewed1280x720,390x844,844x390. Independent review found no
actionable issue and verified source hash,100 unclipped masters and exact
decoded pixel buffers for all eight repacked atlases. No phone profiling,
player saves, APK, commit or push. docs/.gdignore excludes render sources.
