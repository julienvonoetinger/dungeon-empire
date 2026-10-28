# Lower lock / readable hands — active native preview

V25 (.49 lock height) was rejected: the head occludes the raised hands.
This review uses .32, wrists .10 forward and .035 laterally outward, original
Meshy model/materials, fixed feet and unchanged camera/anchor. Eight held
poses in four directions, 8 fps, one second. No procedural runtime skeleton.

render_lockpick.py creates the poses and packed Blender source; prepare.cjs
writes sprites and local native-resources. Its explicit `--install` option
copies them to assets/previews/vulpin-lockpick for VulpinLockpick.tscn.
verify_saved_poses.py verifies eight saved poses and tools reproduce exactly.
32 PNG frames are unique and unclipped; sheets total 894106 bytes / 8 MiB RGBA.
The user approved compact v11 proportions; the painted integrated review is
door-redesign/seal-v1/hero-fit-v12-integrated. Native scene evidence is in
native-scene. The shared game door kit is updated; this still does not replace
the gameplay hero/AI with the Vulpin animations. No new APK.
