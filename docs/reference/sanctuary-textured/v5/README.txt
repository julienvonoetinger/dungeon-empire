Sanctuary scenery integration - 2026-11-04

User observes that scenery looks laid on top of the ground, and suggests
inconsistent dark contours and/or perspective. Comparing the earlier painted
version and v4 reveals heavier dark outlines on the small rocks, clean-cut
bases, and different edge treatment between objects and the continuous floor.

An isolated 22-boulder pilot changes only their native painted sprites. The
native landscape capture shows improved contact without any camera or position
changes. The same treatment is applied to all 43 terrain/ritual objects:
local-color silhouette edges, softer painted crevices, small irregular earth,
moss and chip details at the feet. No blurred silhouette or procedural alpha
feathering. Constructed ritual stone and gold eye/diamond engravings remain;
natural outcrops stay continuous stone rather than brickwork.

The 9 native ImageGen sources in source/ are complete sprite edits of the v3
canvases. Boulders is the initial pilot, then used as a treatment reference.
Exact prompts: source/prompt-boulders.txt and source/prompts.json.
Whole original cells are cropped and uniformly resized using v3 frame sizes,
offsets and registration. New moss does not redefine the foot anchor.
No object assembly, mirroring, procedural recoloring or outline filter.

The entire node section of SanctuaryNaturalGround.tscn is preserved byte for
byte. Only 43 texture resource paths change in SanctuaryIntegrated.tscn.
Ground painting, all 1051 original placements, portrait/landscape cameras,
corrected candle, other decoration and contact shadows remain unchanged.

This is a paint/contact correction, not a new calibrated perspective solution.
Generated sprites have small silhouette interpretation differences; source
alpha overlap is measured, not claimed identical to the wireframe. If exact
multi-angle camera motion is later needed, this preview does not prove it.

Reproduction from archived sources:
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node tools/prepare_sanctuary_integrated.cjs
Then import Godot and open scenes/SanctuaryIntegrated.tscn.

recipe.json records native hashes, original crop rectangles and output frames.
artifacts/sanctuary-integrated contains the boulder pilot, final portrait and
landscape captures, import/capture logs and validation.json. Validation checks
source hashes, frame registration, unchanged node data, native alpha, silhouette
overlap and reduced dark boulder edge coverage. Visual inspection remains
necessary for integration and engraving legibility. Artistic approval is the
user's decision. Scenery preview only; no gameplay, saves, APK, commit or push.
