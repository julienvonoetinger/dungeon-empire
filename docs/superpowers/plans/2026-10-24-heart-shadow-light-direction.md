# Heart shadow light direction

> Execute inline using executing-plans; review with requesting-code-review.

**Goal:** Orient the heart's ground shadow away from the closest active nearby
torch, retaining the approved large directional silhouette and fine contact.
User approved this approach in chat after accepting the v5 appearance.

**Architecture:** Bake eight ground directions plus contact-only fallback from
the frozen rigid volume. The renderer selects one prepared atlas region on
rebuild, using world-space emitter coordinates. No screen rotation, geometry
generation, new artwork, live shadow map, or per-frame work.

**Constraints:** Same geometry, .75 zoom, layouts, heart and torch pixels. Keep
v5 snapshots. Work in the current checkout because the kit migration is already
uncommitted here. No automated tests, commit or push (session instructions).

## Implementation

- [x] Freeze v5 renderer, generators, recipe, hashes and captures under
  painted-v1/heart-shadow-v6/before.
- [x] Extend isometric_ground_shadow.cjs with prepareSet(model): contact-only
  heart-shadow and eight heart-shadow-0..7 variants. Preserve cast slope length
  hypot(2.1,1.2), .32 opacity, .38 contact, 1.2/.7 source-pixel softness.
- [x] Export emitter_world on torch metadata and ground_shadow_directions on
  the heart entry. Preserve all non-shadow PNGs exactly.
- [x] Renderer selects the nearest enabled, positive-energy torch within its
  existing screen light radius and an unobstructed floor path. No source or no
  direction fitting the floor: contact-only fallback. Historical catalogues
  retain their prior single-shadow behavior. One ground sprite per heart.
- [x] Import and inspect actual Godot captures at .75, including current two
  torches, each torch alone, disabled lights, and no torch. Record selection and
  before/after images. These are visual review captures, not automated tests.
- [x] Obtain a focused independent code review; fix material findings. Update
  current metrics, limitations and reproduction documentation.

## Review focus

World-plane direction versus screen projection; no torch through void or a
door/stair; lights disabled/zero energy/out of range; stable ties; bounds near
floor edges; historical catalogues; standalone heart contact-only. Direction is
quantized to eight orientations, length remains artistic and fixed; selection
happens on layout refresh. No physically exact multi-light shadows or dynamic
response to moving lights is claimed.

## Execution record

- Full-density eight extra effects grew atlas memory to 8 MiB. Ruling: pack only
  the diffuse effects at half density and honor logical frames in Sprite2D scale;
  atlas returns to 4 MiB. Trade-off: softer shadow pixels, no change to painted art.
- Seven placement captures observed selection 2, 7 and 1 after heart/torch moves;
  edge, disabled, range and no-torch cases use contact only. No source positions
  hardcoded into production selection. All prior non-shadow PNG hashes match.
- Independent read-only review: no Critical/Important findings; one minor mixed
  tolerance near-tie issue. Ruling: fix within this change because deterministic
  source selection is an explicit requirement. Use distance buckets of .00001
  squared world units and lexical keys. Cost: imperceptible distance quantization.
- Review scope rulings: fixed length/eight directions/multi-light limits are
  intentional mobile approximations; direct PointLight2D movement and prop
  occlusion remain unsupported and documented. Artistic approval and phone
  performance cannot be inferred from desktop captures. Documentation and final
  export were completed after the review. No further independent review claimed.
- Fresh import, runtime 68/23, placement 7, editor 21/5, resource export and
  isolated package startup completed; exact results in heart-shadow-v6/validation.json.
  No automated tests, commit or push. Current user editor state retained.
