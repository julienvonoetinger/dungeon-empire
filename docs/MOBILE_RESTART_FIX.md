# Mobile defeat restart

## Current behavior (0.2.0)

The starter-population workaround below is superseded by free placement.
New runs render the all-ROCK field and a movable Core preview. The player
anchors the Core, excavates, and places the entrance and storage manually.
Existing saves, including intentionally empty grids, are no longer populated.
Restart still restores viewport processing and preserves progression and raid IDs.
The updated capture asserts an unbuilt dungeon with a visible placement preview.

## Historical workaround (0.1.8)

Reproduced on Vulkan PC: the defeat button called Main._new_map(), which
creates an all-ROCK grid without a Core. MobileStarter.populate() only ran
during initial startup. The no-Core world has no visible room geometry, so
the viewport remained blank even though rendering was enabled.

MobileSession now repopulates the starter on a new run when starter_enabled
is true, resets selection/follow/camera/modal state, synchronizes the world,
recenters the Core, and saves. Progression and monotonic raid IDs are retained.
The desktop/manual anchoring path with starter_enabled=false is unchanged.

Startup also repairs a restored all-ROCK mobile save, preserving progression.
Any non-ROCK tile prevents this recovery from replacing a nonempty dungeon.
The production save path is never touched by the regression capture.

tools/capture_restart.gd reproduces the actual button signal at 960x540.
--before captures the old blank result; the default mode asserts Core and
entrance exist after restart. Artifacts restart-before.png/restart-after.png
record the Vulkan reproduction and corrected result on the development PC.

APK 0.1.8-restart uses Vulkan. Device confirmation remains necessary.
