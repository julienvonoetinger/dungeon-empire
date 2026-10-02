# Masonry Core (0.2.13-core)

Approved concept: `exec-877a33cc-6e0d-4758-955f-91725f9a940a.png`.
Three images generated using the built-in image tool, saved in assets/mobile:
`core-monument-v2.png`, `core-damaged-v2.png`, `core-destroyed-v2.png`.

Prompt brief: isolate the approved gray masonry monument with four squat stone
anchors, aged iron orbital rings and a black-violet orb on transparent alpha.
Preserve square canvas and footprint center (50%, 64%). Derive damage by chipping
pillars and cracking rings; derive destruction by collapsing rings and removing
the orb. Keep stone brightness, base position and scale, with no global tint.

Core and placement preview use core_masonry.gdshader: lit matte stone, selective
violet emission and world-up lighting normal stable under camera rotation. The
previous grounded billboard projection is retained. Chests retain their original
shader. No gameplay, health thresholds, collisions or save formats are changed.
Images are capped at 1024px with mipmaps; health images are cached by resource path.

Verification:
- Full mobile suite: 56 tests, including state/repair paths and real alpha.
- Depth probe: 12 Core and eight chest state/view combinations, floor clipping,
  projected silhouette alignment and foreground/background occlusion.
- Isolated torch response verifies the Core receives scene lighting.
- capture_core_masonry.gd: three health states, four views, walls on/off and the
  smaller initial chamber. Captures use Vulkan on desktop, not a Pixel device.

The depth probe uses a white alpha silhouette to isolate geometry from lighting;
it separately checks the production shader's response to a warm light.
