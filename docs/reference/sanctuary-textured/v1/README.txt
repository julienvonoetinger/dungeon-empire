Sanctuary texture proposal, 2026-11-04

Open scenes/SanctuaryTextured.tscn in Godot. The approved wireframe remains
available as scenes/SanctuaryWireframe.tscn. Both use the same viewport framing.
This is a scenery preview, not a replacement of the gameplay invocation yet.

geometry.json freezes the complete approved XYZ models, visible edges, camera,
frames and 1051 placements. The textured scene preserves these positions.
Source ground.png is a native built-in ImageGen output; exact prompt and source
path are in source/ground-prompt.txt. Two unchanged existing project stone
materials are archived there as well. No source depends on a machine cache.

Reproduce with Node.js and Sharp:
  npm install --prefix artifacts/sanctuary-textured/deps sharp --no-audit --no-fund
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node tools/export_sanctuary_textured.cjs
Then import the project in Godot.

The exporter uses the dungeon's offline isometric raster. It projects existing
material pixels on the XYZ surfaces, bakes directional light, subtle creases
and recessed glyph shading, and emits independent RGBA sprites. Ground UVs
continue between tiles, with a two-pixel sampling guard and an eight-cell
mirrored period. Contact shadows are separate ground sprites. Godot only places
the prepared images; there is no runtime generated geometry or material.

recipe.json records sources, hashes, dimensions and final sprite checksums.
Native 390x844 and 1280x720 captures are in artifacts/sanctuary-textured.
Import and captures exited 0 with empty stderr. Source geometry and all 1051
placements were compared to the wireframe exporter; 150 texture dimensions,
alpha channels and hashes checked. Artistic review remains with the user.

Lighting is baked for this first texture review. Shadowing of moving characters
and activation of the ritual are not implemented by this scenery step.
