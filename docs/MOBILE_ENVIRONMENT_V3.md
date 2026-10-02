# Continuous stone environment

Approved comparison: exec-1f3e337f-55de-4e12-921b-027c88da0492.png.
Android version: 0.2.15-environment.

The previous two blocks per tile and four repeated backdrop variants are replaced
by deterministic world-space fractured formations. Jittered Voronoi regions are
split into smaller angular pieces with independent heights and slopes. Real
fracture edges are beveled before their faces are clipped to tile boundaries.
Excavation clips the same field rather than rerandomizing its neighbors.
There is still a continuous lower rock bed beneath gaps.

The surrounding 20-tile margin uses one mesh per 8x8 chunk, with a shared material.
It contains no playable cells or new collision rules. The existing wall toggle
lowers all rocks uniformly for visibility and picking, including the distant
backdrop, so cutaway does not make a depressed ring around the passages.
Camera limits and raid behavior remain.

Walls have five staggered courses with chipped bevels beneath the existing coping height; door
and entrance geometry remain compatible. Warm torch pools are localized (range
2.8, energy 1.7) rather than washing the entire room orange.

New generated bitmap: assets/mobile/floor-pavers-v4.png, 1024px import with mipmaps.
Built-in image generation source: exec-c244e061-4ff8-40e3-b8b1-c9a8ec74baf5.png.
Prompt brief: seamless overhead neutral gray ashlar paving, varied rectangular
proportions, staggered thin joints, worn edges, occasional cracks, diffuse albedo,
no orange illumination or props. World UV scale 0.4 gives finer paving; desktop
keeps its previous texture and UV scale.

Verification covers deterministic rock geometry, cross-cell continuity, trimmed
bounds, chunk coverage outside the map, camera picking and existing mobile tests.
tools/capture_environment.gd captures the corridor with four chests, four camera
orientations, both wall modes and a 960x540 viewport using Vulkan.
These are desktop checks; Pixel performance still needs device verification.
The approved comparison is concept art, not an exact screenshot guarantee.

## October 2 visual iterations (not yet packaged as a new APK)

The first procedural implementation still read as flat polygon plates. In-engine
captures drove the following revisions, rather than a new concept image:

- Smaller world-space masses, chipped contour samples, stepped side faces and
  two height bands (low fragments and taller formations).
- Broad top relief instead of high-frequency triangular fans.
- New bedrock-v2.png surface albedo and a triplanar shallow-relief shader, also
  used for the mobile paving without adding floor geometry or changing picking.
- Wall grain at a larger scale and stronger stone bevels; existing entrance,
  doors and gameplay proportions retained.
- Decorative geometry clipped at chunk/map boundaries rather than every tile.
  Final backdrop: 292738 triangles versus 724175 before optimization. Degenerate
  triangles are discarded. The playable grid still uses per-cell clipping.

Generated using the built-in image tool, source
exec-23324d57-4fa8-484f-8ce7-3f70d990cb8a.png, copied to assets/mobile/bedrock-v2.png.
Prompt: seamless overhead dark cool-grey weathered dungeon basalt; broad uneven
mineral planes, angular layered fractures, sharply chipped edges and fine cracks;
dark-fantasy surface albedo, subtle cavity shading, no directional cast shadows,
no regular grid, cobblestones, lettering, borders or isometric perspective.
Imported at 1024px with mipmaps. This asset is a material, not a gameplay mockup.

Actual comparisons: artifacts/environment-{true,false}-{45,135,225,315}.png and
artifacts/environment-small.png. Capture tool uses an expanded toolbar and 1.30
zoom for a comparable overview; earlier closer iterations were also inspected.
The reference still has more sculpted rock silhouettes and denser contact detail:
visual fidelity is improved, not pixel-identical or independently art-approved.

Validation: 57/57 tests, Vulkan captures, and 900-frame desktop memory probe.
Loaded: 96.11 MiB static, 225.43 MiB video, 156.72 MiB textures, 1231 nodes, 285
resources. After 600 camera-motion frames: 96.28 MiB static; raid: 96.37 MiB.
About 6 MiB more video memory than the original environment prototype, mostly
the new texture. Pixel 10 performance is not verified by these desktop checks.

## Wall and paving follow-up

Wall courses now have different heights, individual stones have slight top slopes
and chipped face contours, and coping lengths vary. Recessed mortar closes gaps
without adding scene nodes. Dimensions stay inside the existing wall footprint.
Paving carries a four-bit exposed-edge mask in UV2. The shared shader blends stone
dust and narrow contact shading only along the excavated perimeter, not internal
tile seams. Digging updates the masks without extra meshes or textures.

Both full and trimmed rocks and the entire decorative backdrop use the same 0.16
vertical cutaway scale when walls are hidden; restoring walls restores their full
relief. Small natural height differences remain, but the near/far height step is
removed. Captures now also include environment-detail-{true,false}.png.
The earlier memory measurements above precede this follow-up.
