# Core ground depth

Version: 0.2.7-core-depth (Android Vulkan, code 18).

The footprint-centered Sprite3D offset is 14% of image height. With a
camera-facing quad, the lower 36% consequently extended below the paving.
Depth testing removed much of the Core pedestal, including with walls hidden.

`assets/rendering/core_grounded.gdshader` moves below-floor quad vertices
along the orthographic camera ray to y=0.185 (paving y=0.175). This preserves
screen-space alignment while keeping the geometry above the floor. Normal
depth testing and alpha-scissor depth writing remain enabled. The shader is
shared; each sprite retains its own cached material and texture/tint parameters.
It is specifically for the mobile orthographic camera, not perspective views.

Both placement preview and placed Core use the correction. Health still selects
the dedicated healthy, damaged and destroyed images without darkening them.
No simulation, collision, save or wall-toggle behavior changes.

## Verification

Run `tools/probe_core_depth.gd` with the Vulkan mobile renderer, not headless.
It compares GPU captures with and without paving for three health states and
four camera orientations. Before the fix, 18,575 to 21,022 Core pixels were
replaced by floor pixels per view; after the fix, zero. It also compares the
corrected silhouette with the original and checks front/back opaque occlusion.

`tools/capture_free_start.gd` checks placement/confirmation alignment and saves
the actual room with walls visible and hidden. Device validation is still needed.
