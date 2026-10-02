# Mobile Grasp

## Approved direction

The approved September 29 concept replaces the rejected regular block hand with
a fractured charcoal stone claw, hooked fingertips and restrained violet cracks.
The three approved states are a sealed floor fissure, a rising claw, and shattered
claw fragments without magic. There is no separate raised floor platform.

## Runtime

- `scripts/world/mobile_grasp.gd` owns the mobile visual construction.
- Armed fissures use a transparent Sprite3D lying on the existing floor.
- Active and broken states use separate white, unshaded, depth-tested billboard
  sprites, following the existing mobile core/chest approach. The same view of
  the claw faces the camera; this is not a rotating 3D claw model.
- The active state takes priority on the last charge. Existing raid state and
  damage rules are unchanged. An active claw replaces the hidden state; no new
  skeletal animation or per-frame material creation is introduced.
- Three shared textures import at 512px with mipmaps. The UI icon reuses the
  active texture. At most two Sprite3D nodes are added per trap.
- Charge labels sit above the taller artwork.

## Art provenance

Built-in image generation was used, with the approved concepts as edit targets.
Production prompt summaries:

- Active: extract the exact approved claw on genuine transparent alpha; retain
  stone grain, pose and violet cracks; remove all surrounding floor and plinths.
- Broken: extract the approved claw rubble on transparency; retain the low wrist
  stump and recognizable hooked fragments; no violet magic or floor backing.
- Fissures: orthographic top-down transparent branching crevices with restrained
  violet inner light; leave the space between cracks transparent for the game floor.

Assets: `assets/mobile/grasp-active-v2.png`, `grasp-broken-v2.png`, and
`grasp-fissures-v2.png`. Source generation files remain in the Codex image archive.

## Verification

- `tests/mobile_grasp_sprite_test.gd`: states, last charge, shared textures,
  import size, depth testing and floor alignment.
- `tools/capture_grasp.gd`: Vulkan captures of three states at four camera angles,
  960x540 layout and an actual raid trap trigger on its final charge.
- Full test suite: 44/44 passing at integration.
- `tools/android/configure-grasp.gd` selects new resources and configures the
  Vulkan preset as version code 4 / `0.1.3-grasp`; default backend unchanged.

Desktop Vulkan captures do not establish Pixel performance or long-session
stability. Physical-device verification is still required.
