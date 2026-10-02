# Single-trap jump motion (0.2.4)

The simulation already lands on the cell immediately beyond one known trap:
two cell-center units traveled, one intervening trap cell skipped.
The imported thief and ranger jump clips also moved Hips forward. The node
probe measured local Z from 0.189 to 2.690 (thief) and 0.025 to 2.703 (ranger).
At character scale 0.4 and mobile scale 1.4, this added roughly 1.40 and 1.50
cells to the grid movement. The renderer also completed grid travel in the
normal 0.48-second walking interval while the jump lasted one second.

jump_motion.gd caches private animation libraries with constant Hips X/Z,
preserving vertical motion, rotations and limb poses. Source GLBs are not
modified. Clip playback is scaled to the shared TRAP_JUMP_TIME. The world
uses jump_from and remaining jump_t to interpolate only between the two
valid cell centers, then snaps exactly to the landing center on completion.
Non-cardinal or non-adjacent trap requests are rejected.

tools/probe_jump_motion.gd uses tests/probes/node_probes.gd to sample imported
tracks and world-space Hips positions. --verify checks horizontal drift.
tools/capture_jump.gd exercises the real world renderer in Vulkan, checking
five positions for each hero and capturing the takeoff, crossing and landing.
Diagnostics use persistence_enabled=false and never alter a user save.

This does not shorten the jump to land on the trap itself. It prevents the
animation from moving beyond the intended landing cell.
