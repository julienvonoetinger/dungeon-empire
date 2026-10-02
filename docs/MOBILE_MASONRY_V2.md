# Mobile masonry v2

Approved direction: irregular graphite masonry, worn lighter gray paving,
and an explicit right-toolbar visibility toggle. No camera/hero-driven lowering.

## Implementation

- Mobile wall modules have variable stone widths, chipped corners and a shared
  triplanar stone-grain material. Each module remains a single mesh surface.
- Masonry and pillars switch to a prebuilt first-course mesh when hidden.
  Their transforms and stone proportions stay unchanged. Natural rock and
  legacy fallback holders retain the low-height fallback in hidden mode.
- Wall-mounted torch visuals disappear with walls; practical illumination is
  retained for consistent floor readability. Newly created fixtures inherit state.
- The toolbar button shows the current state. The choice lasts for the current
  session; it is not saved as a device preference yet.
- Mobile floor rendering uses one batched surface at y=0.175 with a shared
  paver texture, replacing the repeated relief models. Desktop relief is unchanged.
- Picking uses the currently displayed mesh bounds; simulation rules are unchanged.
- No new per-frame texture generation or per-frame wall animation.

## Generated assets

Built-in image generation, not Meshy. Source files copied into assets/mobile.
Godot imports are capped at 1024px with mipmaps.

- masonry-grain-v2.png: continuous charcoal stone, fine mineral grain, shallow
  chips and hairline fissures, neutral even lighting, no bricks/joints, seamless.
- floor-pavers-v2.png: overhead irregular mixed-size gray rectangular paving,
  worn edges, narrow joints, sparse cracks, no objects, seamless texture.

Approved comparison: exec-58bd11b3-39f0-49d5-a0b8-a44ea9cfd48a.png.
Production sources: exec-2a16df99-ec42-403e-9ad3-a9678c1bfe2d.png and
exec-e8591b8f-81a4-4180-b839-51fabfd0dd79.png in the task's generated_images folder.
The comparison is concept art, not a screenshot or a pixel-perfect fidelity claim.

## Verification

tools/capture_masonry.gd captures visible/hidden states at four angles plus
960x540, using Vulkan mobile on the development PC. Test coverage includes
manual visibility, newly registered walls, foundation meshes and floor picking.
Android remains Vulkan; no claim of a resolved OpenGL driver/memory issue.
Pixel performance and long-session stability require device testing.
