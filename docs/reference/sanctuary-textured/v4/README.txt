Sanctuary continuous natural ground - 2026-11-04

User requests correcting the candle at the rear-left pillar and replacing
the uniform repetitive ground with a richer, naturally varied painting.

Open scenes/SanctuaryNaturalGround.tscn. Scenery sprites, camera, all original
1051 logical placements and all other dressing positions are retained from
the v3 preview. Bougies2 moves from grid (-.95,-.12) to (-.95,.5), away from
the Menhir3 pedestal and onto adjacent ground. Solids are sorted again by
their actual x+y depth after this move.

The 1008 ground cells now share one continuous native ImageGen painting with
world-consistent UV coordinates. Each cell samples a different part of it;
there is no tile-sized repetition. Ground remains attached to the existing
floor geometry. Rocks, vegetation, candles and ritual objects remain separate.
The painting combines natural slate, soil, moss, gravel and tiny wildflowers.
Its centre received additional detail for the narrow portrait framing.

Native built-in ImageGen outputs, unmodified bytes:
  source/ground-initial.png: exec-0879246e-154a-4f89-8480-5479cdcd87a2.png
  source/ground.png: exec-40b10af7-4b21-4afc-88e2-b7710e962c3f.png
The initial reference was artifacts/sanctuary-coherent/1280x720.png.
Exact prompts: source/prompt-ground.txt and source/prompt-ground-details.txt.
The runtime copy is assets/previews/sanctuary-natural-ground/ground.png.
No procedural repaint, alpha removal or stitched synthetic ground details.

The square native image is 1254px despite requesting higher resolution.
It spans 2100 scene units, a slight 1.067x display enlargement at 1280x720;
at 390x844 it is slightly reduced. It is not claimed as a native 2048 asset.
The map covers both reviewed viewports without repetition. Mirrored texture
sampling outside that extent preserves coverage for other camera ratios.
Ground polygons overlap by a small guard with identical world UVs to avoid
filtering seams. Same static preview scope, no gameplay or save changes.

Reproduce after installing Sharp as for v3:
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node tools/prepare_sanctuary_natural_ground.cjs
Then import Godot and open scenes/SanctuaryNaturalGround.tscn.
recipe.json records native source hash, map extent, baseline hash and move.
Captures and validation logs: artifacts/sanctuary-natural-ground/.
