# Chest anchor correction

Android Vulkan 0.2.10-chest-anchor, version code 21.

The old vertical offset (42.5% of texture height) anchored the sprite close to
its front foot instead of its footprint center, displacing the visible chest
toward the rear of its cell. Both existing full/empty images share a footprint
center at approximately (48%, 76%) of the canvas. The new offset is (2%, 26%)
with the node remaining at the cell center and paving height.

Chests reuse the Core's existing grounded billboard shader. Below-floor quad
corners move along the orthographic view ray, preserving the image projection
while preventing floor clipping. Wall/hero depth testing remains enabled.
The helper is now named `_sync_grounded_sprite_material`; Core behavior is
unchanged. Artwork, capacity, gold distribution and saves are unchanged.

Verification: full suite 54/54; `tools/probe_core_depth.gd -- --chest` reports
zero clipped pixels for full/empty states at all four yaws, unchanged silhouette
and correct front/back occlusion. The same probe still passes for the Core.
`tools/capture_chest.gd` captures full/empty chests with walls shown/hidden
at four camera orientations. Validation was performed on PC Vulkan, not Pixel.
