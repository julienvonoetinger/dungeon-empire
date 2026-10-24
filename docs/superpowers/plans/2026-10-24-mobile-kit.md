# Complete mobile architecture kit

## Authorization and design

The user asks to finish optimization with the rest of the kit. This authorizes
promotion beyond MobileReference. Keep its 256 source pixels per logical 1x1
cell, 192 displayed pixels per cell, free panning without zoom, quiet common
stone, three calm rounded floor rows, two wall courses and separate pillar caps.
Keep every existing layout, two-cell SixRoomPreview corridors and four door and
stair orientations. Runtime only places prepared images; masks/material painting
and projection remain offline. Preserve historical sources and user editor edits.

## Implementation plan (inline)

- [x] Share the mobile export primitives and add compact prepared door and stair
  parts, using the established projection and common materials. Pack the active
  kit into atlas resources with filter gutters. Save provenance and guides.
- [x] Add a shared atlas renderer and scene-independent grid boundary placement.
  Preserve openings; use pillars at turns and physical depth for occlusion.
  Migrate the common scene renderer, entrance board and MobileReference. Keep
  editor atlas/region refresh coherent and camera fixed with mouse/touch panning.
- [x] Limit the export preset to active scene dependencies. Keep historical
  high-resolution sources available for authoring but outside the mobile package.
- [x] Import and capture the architecture scenes and four special orientations;
  inspect normal-distance and joint views. Measure atlas pixels, PNG bytes and
  exported resource contents. Document reproduction and remaining limitations.

## Rulings

- Continue on the existing codex branch: the authorized prototype is uncommitted
  here and a fresh checkout would omit it. Do not commit/push until requested.
- No automated tests: explicit repository/user instructions override skill TDD
  defaults. Use export audits, Godot import and visual scene captures instead.
- Retain generated material sources. The latest recessed cap remains optional;
  migration does not imply artistic approval of this pending ornament.
- Special geometry must meet the centered mobile walls, whose inner edge is
  T/2 from the grid boundary (the older walls occupied T inside each cell).
  Adapt the door opening and stair width offline; never scale their perspective
  independently or stretch a rendered image at runtime.

## Progress / evidence

Initial inventory: active old architecture has 2,900 structural PNGs plus shared
floor and 57 isolated references. MobileReference currently has ten base images,
three rejected ornament comparisons and one optional recessed cap at two densities.


### Completed

- 23 runtime sprites: floor + 8 walls + pillar + cap + 8 door parts + 4 stairs.
  The initial 39-sprite export was reduced by baking five steps per stair offline.
- 21 migrated scenes, 60 captures, exact prototype/editor/game MobileReference
  appearance retained. All existing map sources unchanged.
- Explicit 40-file resource graph and fresh ignored export stage avoid stale
  dependencies in the user's open editor cache. ZIP excludes historical assets.
- Import/capture/export/package launch exit 0, empty stderr. Editor-only capture
  emits native screen/progress/shutdown warnings; image matches runtime exactly.
- Independent review: legacy unowned sprite cleanup and editor watcher reentry
  fixed. Follow-up reports no Important/Critical issue remaining.
- No tests or commit/push. Full recipes, limits and reproduction in mobile-kit/.
