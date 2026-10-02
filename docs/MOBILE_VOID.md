# Mobile Void

## V3 inset revision (0.2.9)

Approved comparison: `exec-67349b0c-5c0f-4f10-a40f-6dfbc167d02c.png`.
New built-in ImageGen assets: `assets/mobile/floor-pavers-v3.png` and
`void-armed-v3.png`, `void-active-v3.png`, `void-broken-v3.png`.
The production prompts request top-down neutral worn gray paving, then a thin
flush circular seal in the same stone. Active and broken images edit that seal:
recessed black throat with inward violet energy, or collapsed unlit fragments.
No raised plinth, outside shadow or change of footprint between states.

The three textures use cached lit shader materials, the same albedo/roughness
response as the floor, and isolated violet emission. Alpha is scissored to make
the near-opaque generated interior opaque while preserving transparent exterior.
Depth testing remains enabled. Import limits are 512px per trap state and 1024px
for the floor, with mipmaps; desktop floor and simulation rules are unchanged.

Vulkan capture verifies all states at four yaws, actual final-charge absorption,
and warm-light response sampled directly from the 3D viewport (not the scaled
window screenshot). The sealed center's red channel rises from 0.322 to 0.647
under the test light. Existing playtest unlocks and compact tray remain enabled.
This is still a painted depth illusion, not a geometric hole. Phone validation
is required; desktop Vulkan captures do not establish Pixel performance.

The following sections document the superseded V2 implementation.

## Approved design and assets

A circular trap inset in the dungeon floor, with four inward-pointing stone
ornaments. States: a closed stone seal, an open violet abyss, and collapsed
stone rubble with extinguished magic. No upright portal or raised square plinth.

Built-in image generation adapted the approved isometric concepts to aligned
top-down transparent textures. The active prompt requested the same circular
annulus and four ornaments, no surrounding floor, an opaque black abyss and
restrained inward violet energy. The sealed and collapsed edits retained that
footprint and replaced only the state-specific center/stone damage. No image
is darkened by the code as a substitute for destruction.

Production files are `assets/mobile/void-armed-v2.png`, `void-active-v2.png`,
and `void-broken-v2.png`. Each imports at 512px with mipmaps. The UI reuses the
active texture instead of the old upright portal illustration.

## Integration

`scripts/world/mobile_void.gd` adds one horizontal, non-billboard, depth-tested
Sprite3D at floor height. The existing camera supplies perspective and rotation.
Three preloaded shared textures provide the states without per-frame allocation.
The painted abyss supplies an illusion of depth, not an actual geometry hole;
the energy pattern is static artwork. Existing hero absorption animation and
banishment rules are unchanged.

The sprung state takes priority over depleted charges, keeping the abyss open
until absorption finishes. Once the hero is removed, the collapsed image appears.

## Verification

- `tests/mobile_void_test.gd`: horizontal orientation, consistent footprint,
  distinct images, depth testing, texture size/reuse and last-charge priority.
- `tests/mobile_render_test.gd`: actual world routing into active/collapsed states.
- `tools/capture_void.gd`: three states at four camera angles, 960x540 capture,
  real final-charge banishment, shrinking hero and collapsed state after exit.
- `tools/android/configure-void.gd`: resource selection and Vulkan version code
  6 / `0.1.5-void`. Other export backends remain unchanged.

Desktop Vulkan checks do not establish long-session Pixel stability.
