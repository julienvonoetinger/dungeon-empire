Oculin shadow deity - first levitation animation study

Six-second continuous skeletal loop, 30 fps samples with runtime interpolation.
Body vertical float (5.5 cm amplitude), small lateral sway, head turn/nod,
opposed arm motion with temporal offset, seven-joint traveling tail wave and
subtle crest motion. No scaling or mesh/UV/weight edits; original three textures.
Appearance/invocation choreography and sanctuary integration are not included.

Sources: v16-wraith-inspection/source/wraith-original.glb (immutable archive).
build.py loads the packed inspected model, bakes animation, verifies 181 finite
poses, compares whole-body endpoints and preserved geometry/UV/weights hash,
saves wraith-levitation.blend and exports assets/previews/wraith-master/.
Endpoint maximum vertex difference: 0. Peak vertex change: 0.204974736.
prepare_preview.py derives an isolated UI without changing older prototypes.

Preview: scenes/previews/WraithMasterPreview.tscn.
Pause, replay, speed .5x-2x, explicit clock scrub and viewing angle +/-180 deg.
artifacts/wraith-master/check.gd: 70 native checks pass, empty stderr. Confirms
58 bones, one full mesh, six-second clip, all bone endpoint poses, animated
bones, pause/speed/loop, controls in three window sizes, visible movement and
deterministic seek. Native screenshot sequence encoded by pack_review.py.

Review PNGs/animation are actual native renderer captures. The 10fps WebP is
only a lightweight review copy; live runtime interpolates the 30fps source.
No full self-collision, facial animation, phone performance or sanctuary test.
No player saves, APK, commit or push. Artistic approval remains with the user.
