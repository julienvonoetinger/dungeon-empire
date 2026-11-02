OCULIN - MULTI-VIEW REFERENCES - 2026-11-02

User explicitly requests the different images for Meshy after choosing B,
the cyclopean summoner race, and receiving its individual front reference.

Front is retained byte-for-byte from v2. New left/back/right are generated
separately by native ImageGen using front as the fixed identity. Back also
uses left for garment depth; right uses front/left/back. All are transparent
orthographic-style neutral A-pose illustrations with empty hands. No image
mirroring, scripted repainting, resizing or body compositing.

Preserved features: one lavender facial eye, two short pale horns, stocky
slate-blue pebbled skin, thick forearms, bare three-toed feet, purple engraved
collar, front eye amulet, rope belt and layered dark/plum waistcloth. Rear
collar is continuous and has no second pendant. The front rope knot does not
repeat at the back. Rear garment design is an interpretation from the front
and side, not evidence from a pre-existing3D model.

Sources, exact prompts and native paths/hashes: source/ and provenance.json.
prepare.py reads archive hashes, never depends on machine-local generation
cache, checks native alpha/full silhouettes/margins/file sizes, copies bytes
to meshy/ and creates/verifies oculin-meshy-pack.zip (four PNG+README only).
Reproduce from repository root with Python3 and Pillow installed:
python docs/reference/summoner-race-review/v3-meshy-turnaround/prepare.py

Native dimensions: front1305x1206, other views1305x1205. One-pixel canvas
height difference is preserved, not hidden by image resampling. Actual solid
silhouette top/sole spreads are in validation.json. These references are
not mathematically calibrated; proportions/paint can vary slightly between
independently generated views. Meshy reconstruction and rigging untested.

index.html shows all four images and individual downloads. meshy/README.txt
contains import order and official Meshy documentation links. docs/.gdignore
excludes source/review/package files from exports. No game, animation, save,
upload, APK, commit or push change in this task.
