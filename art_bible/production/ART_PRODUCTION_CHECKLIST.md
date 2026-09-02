# Art Production Checklist

Before accepting any new asset:

## Identity
- [ ] One asset only.
- [ ] No contact sheet/grid.
- [ ] No text in the image.
- [ ] Full silhouette is visible.
- [ ] Asset fits the Art Bible.
- [ ] Purple is used selectively.

## State variants
- [ ] Variant was made from the canonical `*_reference.png`.
- [ ] Same object identity is preserved.
- [ ] Only gameplay-required changes were introduced.
- [ ] Camera and proportions remain compatible.
- [ ] Destroyed state still reads as the same original object.

## Meshy readiness
- [ ] Object is isolated.
- [ ] Major surfaces are visible.
- [ ] No important geometry is hidden.
- [ ] No unrelated floor/background geometry is attached.
- [ ] Intended pivot and scale are documented.

## Godot readiness
- [ ] Determine whether this is a new mesh, animation state, material state or VFX state.
- [ ] Avoid duplicate meshes for simple hinge/visibility changes.
- [ ] Damaged/destroyed collision behavior is defined.
