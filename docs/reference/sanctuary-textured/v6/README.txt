Sanctuary vegetation style correction - 2026-11-04

User identifies old detailed plants as inconsistent with the simplified scene.
Six native vegetation sprites replace the old v2 artwork still used by v5:
fern, violets, mushrooms, moss, wildflowers and garden. Shapes are broader,
leaf groupings simpler, highlights subdued and edges painted without ink.
30 vegetation placements retain their original sizes, coordinates and depth.
Candles, ground, rocks, ritual, camera and all scene nodes remain unchanged.

Built-in ImageGen precise edit, original native output:
exec-2f6e8a74-13f3-4b65-a9e7-b70223531985.png
Archived bytes: source/dressing.png, 1536x1024 native alpha.
Exact prompt: source/prompt.txt.
Edit target: ../v3/source/dressing.png.
Style reference: artifacts/sanctuary-integrated/1280x720.png.
Only six cells from the final two rows are used; regenerated candle pixels
are not used. Existing candle resources stay byte-identical.
Hidden RGB haze in some image viewers is transparent in native compositing.
No procedural repaint, alpha removal, blur or botanical assembly.

Run with the existing task-local Sharp dependency:
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node tools/prepare_sanctuary_flora.cjs
Open scenes/SanctuaryFlora.tscn in Godot.
Runtime sprites: assets/previews/sanctuary-flora/.
recipe.json records source hash, crops, unchanged frames and output hashes.
Captures and validation: artifacts/sanctuary-flora/.
Scenery preview only. No gameplay, saves, APK, commit or push.
