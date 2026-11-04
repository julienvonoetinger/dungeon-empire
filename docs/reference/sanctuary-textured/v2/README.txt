Sanctuary painted scenery — 2026-11-04

User rejected the uniform material-mapped v1 and requested the visual richness
of the supplied ritual and gorge illustrations. This version uses native
ImageGen artwork for the complete independent scenery objects. It is not a
single scene backdrop. Open scenes/SanctuaryPainted.tscn in Godot.

The 1051 logical placements and shared portrait/landscape camera framing are
retained from v1/geometry.json. Generated artwork interprets the wireframe
silhouettes with chipped edges, moss and natural detail: it is not an exact
per-pixel or per-vertex match to the wireframe. Complete individual objects
are uniformly resized and registered by their solid lower edge/centre. No
mirroring, body assembly, procedural repaint, alpha removal or color keying.
Each source sheet cell retains its native alpha, including fine foliage.

43 terrain/ritual sprites, 9 dressing sprites, 64 seamless ground regions and
43 contact shadows. 36 additional dressing instances: six candle groups and
30 vegetation pockets, with clear space to approach the ritual. All solid
sprites share the existing x+y depth ordering. Shadows remain under solids.

Sources:
source/style-ritual.png and style-gorge.png are the user's attached references.
guides/*.png and layout.json preserve the wireframe input sheets.
source/ritual.png, cliffs.png, boulders.png, dressing.png and ground.png are
native ImageGen outputs. Initial versions and transparency-cleanup attempts
are retained. Some viewers show hidden RGB haze even where alpha is zero;
runtime captures verify the actual compositing on the game ground.
Exact prompts: source/prompts.json, source/prompts-additional.json and
source/prompt-dressing-cleanup.txt. recipe.json records source and sprite
hashes, whole-cell crop coordinates, scales, offsets and decoration placements.

Reproduction from archived sources, no API or machine cache needed:
  npm install --prefix artifacts/sanctuary-textured/deps sharp --no-audit --no-fund
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node tools/prepare_sanctuary_painted.cjs
Then import the project in Godot and open scenes/SanctuaryPainted.tscn.
The exporter also reuses the preserved v1 contact-shadow PNGs.

Native captures: artifacts/sanctuary-painted/390x844.png and 1280x720.png.
This is scenery review only. Characters, animated flames, invocation effects,
moving-character shadows and gameplay integration are outside this step.
Previous wireframe and v1 texture preview remain available separately.
