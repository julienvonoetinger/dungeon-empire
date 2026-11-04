Sanctuary coherent surface scenery - 2026-11-04

User approves the simplified texture style, but rejects masonry-like natural
rocks. Final cliffs and Crete-1..6 keep broad painted surfaces, subdued grey,
warm highlights and sparse moss, with natural erosion instead of brick joints.
Only constructed ritual pillars and altar use cut stone. Rejected masonry
sources are preserved with the -masonry-rejected suffix.

Open scenes/SanctuaryCoherent.tscn. This is an isolated scenery preview only.
Original 1051 logical placements and portrait/landscape camera are retained.
Painted silhouettes interpret the wireframe; they are not exact mesh matches.
No entrance, marked road, characters or invocation animation added here.

Six large Crete objects each have a separate native ImageGen source; eight
Paroi objects share a 3x3 sheet. No flowers are baked into those large rocks.
Existing native v2 dressing art is reused at smaller flower/fern sizes.
Ground source is the project's assets/dungeon/bedrock/quiet.png, byte-identical.
43 contact shadows are reused byte-identically from the v1 geometry bake.
Whole source cells retain native alpha and are resized uniformly, never
repainted or assembled from fragments. Native captures verify compositing.

Final natural-rock correction prompts: source/prompts-natural-correction.json
Pilot correction prompt: source/prompt-natural-rock-pilot.txt
The pilot became Crete-4.png. Guide sheets and source references are archived
beside the generated PNGs. The initial ritual/boulder prompts were not recovered;
do not treat correction prompts as reproduction of those initial generations.
recipe.json records all selected source and output hashes, crops and transforms.

Rebuild from archived images without generation or machine-local image cache:
  npm install --prefix artifacts/sanctuary-textured/deps sharp --no-audit --no-fund
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node tools/prepare_sanctuary_painted.cjs --coherent

159 texture resources: 43 scenery sprites, 9 dressing sprites, 64 ground regions,
43 shadows. Large rocks have sufficient native pixel density at the reviewed
1280x720 and 390x844 viewports; this is not a guarantee for arbitrary resolutions.
Native captures: artifacts/sanctuary-coherent/1280x720.png and 390x844.png.
Import and capture logs plus asset verification are in that same directory.
No gameplay integration, save access, APK, commit or push.
