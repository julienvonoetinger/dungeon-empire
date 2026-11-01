Arcane door leaf — isolated Mycean unlocking preview
Date: 2026-11-01

The requested magic-sealed leaf is a variation of the approved v15 iron/crystal
door. A violet engraved rune ring surrounds its existing central crystal. Its
mechanical keyhole stays available at the original lower contact. This is a
material change only: the original compact masonry, smooth receiver, UV fit,
wall junctions, geometry, camera and independent depth supports stay fixed.

The selected source is an unchanged copy of the native built-in ImageGen edit.
source/prompt.txt and source/generation.json retain the exact prompt, inputs and
original output path. The first native result is retained with its original
prompt as initial-framing-keyhole-rejected.png: it changed framing and removed
the keyhole, so it is not used in the preview. Only the final source supplies
the leaf material. Existing masonry still samples its approved v12 painting.
No source paint is redrawn or composited by script.
Reproduction verifies archived sources against the native SHA256 recorded in
generation.json. The original generated_images paths are provenance only;
their machine-local cache is not required. Both hashes were checked against
the unchanged native outputs when archiving.

Reproduce from the repository root with Node and sharp available:

  $env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
  node tools/prepare_arcane_door_review.cjs

The script invokes the existing isometric_seal_door.paint optional leafPainting
parameter. It does not edit the shared selection or export the production kit.
It writes the native closed-part PNGs and catalog.json to:

  assets/previews/mycean-unlock/door/

Consumption: after the native renderer loads its production definition, make
a deep duplicate of that resource. Load catalog.json as the id-to-entry map;
replace each duplicate entries[id] and set textures[id] to an ImageTexture
created from the PNG identified by the entry's relative file. The existing
renderer already scales textures to their logical entry size. Leave all
production open-door IDs unchanged. The manifest describes the semantic seal
target and records each PNG hash.

There are four pieces per direction. Legacy '-leaf' is the LEFT JAMB, '-arch'
is the crown above z=.92, '-jamb-right' is the other jamb, and '-panel' is the
actual door leaf. Load all four pieces to preserve the existing 2px opaque seam
overlap. Rendering still sorts each piece independently around an actor.

Target registration:
  Source canvas: 1024 x 1536.
  UV x = 512 + (canonical x - .5) * 820.
  UV y = 1400.4 - world z * 820.
  Spell target: source (512,875.6), world z=.64, canonical (.5,.525,.64).
  Door-plane contact: door cell + (.5,.5) + facing normal * .025.
  Mechanical keyhole: source (512,1138), world z=.32.

preservation.json records actual checks: original geometry and supports,
identical full and per-part alpha, unchanged stone outside the existing 3px
panel filtering fringe, exact keyhole/central-crystal contact samples, all 12
open-frame parts identical, and hashes of the unchanged production inputs.
four-directions.png and door-{direction}.png show the projected final painting.
production-door-{direction}.png retains its current production comparison.

This directory is review data under docs/.gdignore. Only the small prepared
closed-part textures and metadata are used by the isolated Mycean preview.
Native animation, beam alignment, controls and screenshots are checked in the
Mycean unlocking task. No raid integration, player saves, APK, commit or push.
