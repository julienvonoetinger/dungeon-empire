# Mobile Masonry Revision

Reference: the approved September 28 mobile mockup, with constructed stone room walls
standing above fragmented exterior rock. The continuous slab from the first visual fix
did not preserve this distinction and has been replaced.

## Geometry

- Four staggered stone courses per wall, beveled edges, visible joints, separate coping.
- Joint pillars rise slightly above the wall caps.
- Two irregular chamfered rock columns per unexcavated cell, deterministic variation,
  narrow fissures and heights below the constructed walls. Rocks retain the generated texture.
- Rock geometry stays inside cell bounds and leaves space for masonry on excavated edges.
- Meshes are combined per module. The existing cutaway and picking use their actual bounds.
- Desktop geometry, save data, digging rules and simulation are unchanged.
- Palette follow-up: graphite body stones and restrained blue-gray coping replace pale
  gray tints. The material no longer mixes the texture with pure white; specular response
  is limited to 0.15. Torch illumination remains unchanged, so warm light is still local.

## Validation

Surface tests cover 64 narrow footprints, deterministic rebuilding, fissures, wall bounds,
modeled stones and pillar heights. The rendering suite covers cutaway picking at four yaws.
The capture tool records management, raids, camera rotations and 960x540/1280x720/1560x720.
Compatibility starter management capture: approximately 371 draws and 367k primitives,
versus 375 draws and 657k primitives before replacing the imported wall/pillar meshes.
These desktop measurements are not a phone performance guarantee.
