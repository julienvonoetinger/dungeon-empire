# Integrated mobile doors

Android 0.2.12-doors replaces mobile legacy door models with a shared masonry
frame, recessed wooden double leaves and engraved runes for the sealed variant.
Desktop rendering and gameplay rules are unchanged. Floating door medallions are
not used on mobile.

- Frame stone shader, 0.28 thickness and 1.10 coping height match corridor walls.
- Leaves have physical thickness and textured front/back faces, opening 90 degrees.
- Healthy and damaged normal/sealed doors use four dedicated 512px mipmapped images.
- Destroyed doors leave low rubble; opened seals stop emitting violet light.
- Frame meshes and leaf materials are cached. No extra lights are introduced.
- Door frames remain visible when the player hides surrounding walls.

Verification: `tests/mobile_door_integration_test.gd` covers both types and all four
states. `tools/capture_doors.gd` renders 32 state/orientation combinations plus a
walls-hidden view using Vulkan. The full mobile suite has 56 tests.
Pixel performance and appearance still require testing on device.
