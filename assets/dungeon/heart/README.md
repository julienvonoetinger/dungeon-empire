# Approved dungeon heart

`reference.png` is an unchanged copy of the user-approved image
`codex-clipboard-252b152a-68fc-429f-af48-2b88834cf839.png` (1672 × 941 px).
The heart has a square blue-stone pedestal, four short corner stones and a
floating dark violet sphere. Its orientation and proportions are preserved.

`scenes/DungeonHeart.tscn` samples only the native contours of the pedestal,
energy link and sphere. The local origin is source pixel (1316, 546); the sphere
is centered at (1316, 453), with a 49 px contour radius. No source floor rectangle,
HUD, hero or other object is drawn. No bitmap is regenerated or rescaled.

The scene adds a soft contact shadow, a small additive halo and one static
floor-only violet light. The imported reference is lossless, without mipmaps
or size reduction. Like the masonry atlas, it remains a full authoring reference;
packing the sampled art into a compact production atlas is future work.

Run `tools/test-mobile.ps1 -All -Capture`: the heart probe checks eight exact
source pixels, nine clear points outside its contours, local illumination and
unchanged rendering outside its local area. Inspect `artifacts/heart-detail.png`
and the complete `artifacts/dungeon-2d.png`. These checks do not replace artistic
approval of the integrated scene.
