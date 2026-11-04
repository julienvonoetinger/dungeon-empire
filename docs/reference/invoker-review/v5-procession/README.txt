Invocation staging - 2026-11-04

User sequence: invoker and Oculins enter from bottom, walk up to altar, stop;
invoker chants; master appears only after chant; followers kneel afterward.
Four followers chosen for this version. Invoker bows his hooded head while
keeping the staff held; the four followers lower onto their knees.

Timeline: 0-9.5 approach (staggered entrances), 9.5-10 settle, 10-20 gestural
incantation, 20-22 manifestation, 22-23.8 staggered kneeling, hold to28.
The existing introduction uses Film.DURATION for the subsequent dungeon entry.
No new spoken audio. Approved scenery and Wraith six-second levitation retained.

bake.py runs in dedicated background Blender with -- invoker / -- oculin.
It loads unchanged v4-grip-correction/invoker-equipped.blend or immutable
Grumgaze GLB, preserves original materials/painting and the invoker's wrist
attachment/contact modifiers. Every pose renders the complete model.
384px masters are reduced uniformly to256px by pack.py. Seven atlases include
idle/walk/chant/bow (105 invoker masters), idle/walk/kneel (57 Oculin masters).
Native playback: walk and kneeling24fps, chant48frames looping at24fps.
Saved blends retain pose keys and camera-ground correction for reproduction.
Model source SHA256 checked unchanged. pack.py verifies alpha margins, hashes
and exact frame inventory. No mirrored body art or cutout body assembly.

Runtime: scripts/game/invocation_sanctuary.gd and invocation_actor.gd.
Master uses real skeletal GLB via transparent viewport; all timing comes from
present(time), no independent elapsed clocks. Depth insertion ignores authored
shadow layers. Released scene remains hidden and stops 3D viewport updates
even when layout changes. Entrances recalculated below each current viewport.

Preview: scenes/previews/SanctuaryProcession.tscn; pause, scrub and replay.
artifacts/sanctuary-procession/check.gd reproduces missing staging before change,
then verifies ordering, arrivals, master visibility, kneeling, replay, release,
depth and three screen sizes. Native test/import stderr empty. Captures reviewed.

Limits: first staging, artistic timing still subject to feedback. Ground uses
evaluated body minimum Z, not rigid support-foot IK. No exhaustive self/staff
collision analysis over motion or physical-phone profiling. No APK/save edits,
commit or push. Source/review excluded by docs/.gdignore.
