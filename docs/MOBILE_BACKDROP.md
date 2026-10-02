# Continuous rock backdrop

Mobile dungeon scenery now extends 20 cells beyond each edge of the 16x16
playable grid. These cells are visual only: they do not enter simulation,
save data, pathfinding or excavation picking.

The border uses 2,880 instances in 8x8-cell MultiMesh sectors, four shared
rock meshes, deterministic varied rotations/heights, and one rock underlay.
The existing bedrock texture is reused. Shadows are disabled for these
batches. Offscreen sectors can be culled; scene nodes are bounded at 65.
The border is built once and retained across world syncs and run resets.

Camera look position is constrained to the playable map. Minimum zoom is
computed from viewport aspect, yaw and pitch so the projected ground
footprint fits within the scenery margin, with two cells of safety for rock
height and the underlay. This applies to panning, zoom, rotation, recentering,
hero following and world synchronization; desktop cameras are unchanged.

Validation: tools/capture_backdrop.gd captures eight extreme pan/yaw states,
counts non-background pixel samples, and records landscape/portrait views.
Headless tests cover finite limits, transformed footprints, batching and
deterministic placement. Vulkan screenshots use the development PC, not a
Pixel; device frame rate and long-session memory need confirmation.

APK 0.1.9-backdrop remains on Vulkan. No new bitmap assets were generated.
