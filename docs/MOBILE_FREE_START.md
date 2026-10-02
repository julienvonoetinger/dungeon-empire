# Mobile free start

New games and defeat restarts begin with an all-ROCK playable grid, surrounded
by the existing decorative rock backdrop. MobileStarter remains an explicit
test/demo fixture, not part of normal startup or save restoration.

Before anchoring, a cached translucent Core sprite and a 2x2 outline follow
the selected valid position. The compact action bar confirms with Ancrer.
No entrance, storage or rooms are automatically created. After anchoring,
normal construction tools become available. Raid readiness retains the
existing Core, entrance and storage prerequisites.

Save loading preserves the player's existing layout, even when empty. New
runs preserve profile progression and monotonic raid IDs. Rendering remains
Vulkan in the Android release; this change does not diagnose the OpenGL crash.

tools/capture_free_start.gd exercises actual confirmation and captures before,
moved-preview and after-placement images without touching production saves.
tools/capture_restart.gd exercises the defeat modal button.

## Room preview (0.2.2)

The placement preview now includes the shared mobile floor, four masonry
walls and corner pillars. It temporarily hides only the four covered rock
render nodes; the simulation grid, economy and save remain untouched.
The geometry is cached and moved, not regenerated on every selection.
Cancellation and confirmation restore covered renderer nodes. Perimeter
walls move inside the map at boundary positions, as in the constructed room.
The wall visibility toggle is available during anchoring and previews the
same preference used after confirmation. The placed Core uses the same
footprint-centered artwork anchor as its preview.
