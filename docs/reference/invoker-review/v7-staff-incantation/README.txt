Invoker staff gesture - 2026-11-04

User requests staff movement distinct from the raised arms. The original free
arm / four followers keep their synchronized48-frame chant. The staff arm now
uses a separate delayed sin-squared gesture: starts after10% of the cycle,
lifts wrist .18 model units, advances .035 toward altar, moves .015 outward,
and inclines staff9degrees. Returns exactly to the corrected equipped rest.
Same2-second loop and timeline; distinct amplitude, articulation and phase.

Whole-model renders, no2D detached prop or independent staff translation.
Original staff and GripContactEnvelope remain attached to Bone_020. Arm bones
022/021 solve a two-link chain to the moving wrist; wrist orientation carries
the existing palm/finger pose. Original source painting, topology, weights,
contact modifiers and staff attachment preserved. Free arm gesture unchanged.

bake.py loads v4-grip-correction/invoker-equipped.blend, renders48 complete
384px poses and stores the packed keyed source. Attachment transforms verified
for all48 poses, exact neutral endpoints. pack.py uniformly reduces to256px
and replaces only the runtime invoker-chant atlas (same2048x1536 dimensions).

verify.py reloads saved blend: seven poses checked with full-body/staff BVH
candidate triangles plus edge/surface casts, zero crossings. Finger-to-handle
nearest surface distances remain below.0052 model units; minimum staff/floor
clearance about.0222. Endpoint evaluated geometry matches, source hash unchanged.
These sampled surface checks do not prove continuous or contained-volume
self-collision avoidance. No foot/leg changes or new sound.

Source and sampled verification logs/reports retained. Runtime choreography,
navigation, handoff, controls and other actor assets unchanged. No APK/save
edits, commit or push. Existing native procession checks rerun after import.
