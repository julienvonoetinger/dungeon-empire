# Mobile Spines

## Approved art

Nine dark faceted spikes in a 3x3 grid, each emerging from a flush floor opening.
Three approved states: short retracted tips, extended spikes with violet roots,
and broken stumps/fragments without magic. No raised platform or state tinting.

The built-in image generator extracted one transparent element per state from
the approved concepts. Prompts preserved the charcoal material, pale edges,
isometric view and subtle warm lighting, removed all floor/backing, and requested
exactly one reusable spike. The broken prompt retained one adjacent snapped tip.
The full-grid icon is rendered from the actual runtime construction.

## Implementation

`scripts/world/mobile_spines.gd` places nine depth-tested Sprite3D elements at
fixed grid coordinates, sharing one imported texture per state. As with the
mobile claw, these are camera-facing 2.5D sprites, not rotating 3D objects.
A cached mesh draws all nine floor openings in one surface. This replaces the
old 18 mesh nodes with ten visual nodes per trap. Textures import at 512px with
mipmaps; the icon is 256px. Resources are not recreated each frame.

Existing trap activation and damage rules are unchanged. The final charge
displays the active artwork before the spent state; the charge counter clears
the taller artwork. Other trap families and desktop models are unchanged.

Assets live in `assets/mobile/spike-armed-v2.png`, `spike-active-v2.png`,
`spike-broken-v2.png`, and `spikes-icon-v2.png`.

## Verification

- `tests/mobile_spines_test.gd`: exactly nine unique grid positions, state images,
  shared textures/socket mesh, import size, floor height, depth testing and final charge.
- `tools/capture_spines.gd`: all states at four camera angles, 960x540 capture,
  and a hero triggering the final charge through the raid code.
- `tools/android/configure-spines.gd`: selects resources and sets Vulkan version
  code 5 / `0.1.4-spines`, leaving the project backend default unchanged.

Desktop Vulkan validation is not a substitute for Pixel performance testing.
