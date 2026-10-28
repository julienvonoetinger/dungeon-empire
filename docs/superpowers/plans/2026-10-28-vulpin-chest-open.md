# Vulpin unlocked chest opening

> Execution: superpowers:executing-plans, inline; final independent review.

**Goal:** Render a readable unarmed chest-opening gesture in four directions, with a native inspection scene.
**Architecture:** Same unchanged Meshy GLB, fixed Blender poses/camera/paint as walk and lockpick. Eight held whole-character sprites per direction; non-looping action. Following the user's correction, the native preview uses ONLY the unlocked/ajar chest artwork throughout. No access-state change or continuous chest-lid animation.
**Spec:** Latest user request and AGENTS.md Meshy pose workflow. No tools, attack, lock search or coin collection; existing gameplay/save behavior remains untouched. No APK, commit or push requested.
**Tech:** Blender 5.2, Python, sharp, Godot 4.7.

- [x] Pose and export: ready, bend, grasp, start lift, lift, hold, release, recover. Common ground anchor, feet fixed, hand/contact metadata and original source hash; preserve old sprite hashes. Inspect pose board.
- [x] Native scene `scenes/VulpinChestOpen.tscn`: four opposing chest facings, real paving/chest textures, one-shot plus optional repetition, pause/step/replay and 0.5x–2x; optional contact guides. The chest stays ajar on replay and completion.
- [x] Validate source replay, finite/unclipped images, grounded feet and contact projections, native controls/timing/unlocked-state preservation/layout. Capture native evidence; inspect before claiming completion; final fresh code review.

## Rulings

- User correction supersedes the original two-state presentation: unlocked chests are already ajar. Only prop-chest-open and its matching shadow may appear in this scene. Locked chest lockpicking is a separate preceding action, not implemented here.
- The painted chest is not a reconstructed 3D mesh. Contact positions are a calibrated visual proxy; numerical checks cannot establish exact physical contact with its illustrated lid.
- The first high hand lift overshot the barely-open lid. Reduced lift to .06 model units, retaining a crouch rather than stretching the arms. Slight ready/recovery knee bend removes initial unreachable ankle targets. Native clock initialization failed its first duration/autoplay check and was fixed before captures.
- Use the current checkout: prior preview scripts/assets are uncommitted dependencies. Keep all old previews and production files intact.

## Review focus

- One-shot, replay and repetition must all preserve the same unlocked/ajar chest; only the actor gesture resets.
- Occlusion must work when the hero is behind the chest as well as in front.
- Same limb reach and ground position in all four views, no tool props.
- All controls fit landscape and portrait review layouts.
- Explicitly distinguish the hero gesture on an already ajar chest from chest lockpicking, lid animation and gameplay integration.

## Final evidence

Native import and capture: exit0, empty stderr,247 checks/0 failures;15 PNGs/4 sizes. Eight saved Blender poses replay with zero bounds error, no vertices in the conservative container interior. Four sheets/32 unclipped unique images:1,102,311PNG bytes,8MiB decoded RGBA. Original GLB and16 prior animation sheets unchanged. Independent review found no important actionable finding; artistic naturalness and exact painted-lid contact remain visual judgments. No gameplay/save/APK/commit/push.

User-correction validation: regression failed96 checks on the old closed/open scene. Updated stage has one unlocked illustration only; final capture315 checks/0 failures, exit0, empty stderr.15 captures and native-preview.webp refreshed and inspected. Hero PNGs unchanged; only scene state/presentation, metadata and checks corrected.
