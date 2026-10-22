# Repository instructions

## Keep the game design synchronized

- Read `GAME_DESIGN.md` before changing gameplay, balance, hero AI, controls,
  progression, persistence, visual state feedback or playtest configuration.
- Update the corresponding rules in `GAME_DESIGN.md` in the same change as
  implementation. Include costs, defaults, prerequisites, state transitions,
  exceptional outcomes, save/load behavior and affected player feedback.
- Section 0 describes the implemented static 2D foundation. Keep implemented
  rules distinct from future design, legacy behavior and known limitations.
  A sprite, model or animation asset is not proof of an implemented hero class.
- Document temporary test overrides and their active values. Do not turn them
  into permanent progression or conceal them behind the normal balance rules.
- Verify written numbers against code and tests. Do not change gameplay merely
  to make it agree with documentation; surface any discrepancy instead.
- For bug fixes, add a regression reproducing the relevant player scenario;
  use simulation/node/animation probes and visual captures when appropriate.
- Before declaring a behavior change complete, check the design update and
  report verification. Run `tools/test-mobile.ps1 -All` for gameplay changes.
- Documentation-only edits require source and reference checks, not a full
  gameplay test run unless code also changes.

## Required asset workflow — native transparency

- Every dungeon element must use generated images with genuine alpha already
  present in the source. Never make silhouettes through programmatic cutouts,
  traced render polygons, masks, color/luminance removal or cutout shaders,
  either offline or at runtime. Baking those techniques into a PNG is forbidden.
- Generate additional complete sprites for missing orientations, corners, ends,
  intersections and transitions. Do not approximate missing art by clipping
  painted stones, stretching them or displaying a full-scene illustration.
- Preserve the approved slate-blue style, overhead/front-facade perspective,
  proportions and fixed layout. Uniform sprite scaling is allowed. Rectangular
  atlas regions select complete sprites and their existing transparent gutters;
  they must never trim the painted silhouette.
- The current main scene has completed this migration. Eight generated PNGs in
  `assets/dungeon/alpha-kit/` supply 27 sprite definitions; the existing separate
  torch PNG is retained. `generation.json` records prompts and original outputs.
  The unused `walls.png` is an initial generation draft, not a scene dependency.
- `scripts/alpha_kit.gd` stores full regions and body measurements. Measurements
  only determine anchors and uniform scale; they are never rendered masks.
- Transparency does not guarantee compatible joins. Inspect actual captures at
  normal scale and at least 2x. Sparse probes cannot establish artistic quality.

## Durable modular rendering direction — user clarification, 2026-10-22

- The goal is a coherent dungeon that the player can customize. Build reusable
  assembly rules from logical occupancy, exposed edges and neighboring modules.
  A new room size or connection must reuse those rules. Existing scenes are
  examples and visual regression references, not separate hard-coded renderers.
- Prefer generating a new complete native-alpha image over programmatic visual
  repairs. Generate as many orientations, lengths, corners, ends, intersections
  and transitions as needed. A dedicated sprite must represent a reusable local
  configuration, not an entire prepainted room or a patch tied to one scene.
- Reuse compatible approved sprites and existing assembly helpers first. When
  a configuration requires new art, register its source, orientation, dimensions,
  anchors, connection ports and selection rule in the shared kit and generation
  provenance. Every subsequent matching configuration must use that same entry.
  Keep scale, perspective, color, contours and connection geometry consistent.
- The stone color, bevels, edge highlights, shadows and outlines belong in the
  generated PNGs. Godot selects and places whole sprites, applies uniform scale
  and draw order; it must not repair their appearance with lights, glow, shaders,
  runtime RGB/alpha tinting, clipping, stretching or overlapping painted ends.
  This rule concerns dungeon architecture; separately authored gameplay lights
  such as torches are outside this asset correction.
- This direction supersedes older instructions below that prescribe RGB
  multipliers. Existing code still tints floors, facades, supports and vertical
  stones: that is a known migration task, NOT compliance with pure-image rendering.
  Preserve the approved floor arrangement and intended appearance when replacing
  those adjustments with generated art. Do not silently remove them and claim
  that the visual migration is complete.
- Review each shared change against the existing small room/corridor scenes and
  connected configurations at normal scale and enlarged. Reopening connections
  must select the same shared art. Gaps, ledges and painted-end overlaps remain
  defects even if a technical check passes. Arbitrary player-built dungeons are
  the target; the current limited studies do not yet implement that system.

## Current rendering scope

- The current modular art studies are the closed rooms `1x1CellRoom.tscn`,
  `2x2CellRoom.tscn`, `3x3CellRoom.tscn` and the OPEN corridors
  `1x2Corridor.tscn`, `2x1Corridor.tscn`, `1x3Corridor.tscn`,
  `3x1Corridor.tscn`. Dimensions mean columns x rows. Vertical corridors open
  north/south; horizontal corridors open west/east. These are isolated studies,
  not an arbitrary-layout system. A separate four-way connection study is below.
  The previous `SingleCellRoom.tscn` displayed four floor modules and was
  renamed to `2x2CellRoom.tscn` at the user's request.
- `scenes/3x3RoomFourCorridors.tscn` remains UNAPPROVED. It now rebuilds a 3x3
  room with centered branches: `connections` N1/E2/S4/W8, default15;
  `corridor_length` 1-3, script default2, scene override3 for west/east.
  `vertical_corridor_length` defaults0 (inherit corridor_length); positive values
  set north/south only, negatives clamp0. Scene override4 adds one more cell
  vertically for user-requested continuity inspection. Use the resolved vertical
  length for occupancy, end openings, floors, side walls and detail framing.
  Far ends remain open. The occupancy/perimeter
  resolver is `modular_connection_plan.gd`; floor assembly currently supports
  one odd rectangular room and centered cardinal branches, reviewed at 3x3.
  No player editor, navigation, saving or arbitrary multi-room renderer exists.
  Branch logical length counts straight modules; their native corner arms add
  physical span. Do not claim these ports already fit a future navigation grid.
- The latest width/alignment correction uses `paired-cap-transitions-v7.png`
  (four whole double-bend modules, slots768x512, anchor96,256) and existing
  `cap-elbows-flush-v9.png` for compatible single corners. Earlier paired-v1
  and width/depth experiments cap-elbows-ports-v11/v12, paired-v2/v3/v5/v6 are unused.
  Paired-v4 was rejected for a high-alpha backdrop; no alpha cleanup attempted.
  The latter experiments displaced horizontal joins or made fronts too deep.
  Provenance/prompts: `port-width-generation.json`. Visual approval pending.
- `modular_join_kit.gd` measures each paired shaft's horizontal extent and its
  actual vertical ends, plus the horizontal strip profile. `paired_fit` maps
  the TWO shaft centers to41/517 at476 spacing with ONE uniform transform;
  apply that SAME transform to y ports. Native profile fit remains approximate:
  maximum edge difference about0.55 game pixels, not exact pixel equality. Single corners use their measured
  shaft centers, not an assumed center41. Preserve complete original regions.
  Their native profiles remain NW/NE[-14,99], SW/SE[1,114]; raw y ports
  [-14,159]/[-55,114]. Full horizontal extents are in SHAFTS.
- Short returns align signed gaps with absolute value at most82, shifting
  WHOLE horizontal runs by half the gap. This also separates negative gaps
  instead of leaving painted ends overlapped. No tiny spacer between shoulders.
- Small and connected studies retain the shared horizontal profile: north/south
  cap scale .99/.97, cadence476, facade top88 and continuous staggered courses.
  Never reinstate per-span cap compression or per-scene facade heights. Stop
  facades at closed corner anchors (retain75 under NW/NE downward arms);
  -12/+14 extensions belong only to open ends. Central approved paving stays
  fixed; west/east continue its exact rows2/3. Supports remain whole pavers,
  y-40; their legacy RGB0.70 remains a separate migration task.
- `modular_side_kit.gd` uses `wall-tops-ports-v12.png`: four complete sprites
  (pair plus three single lengths), four627x627 regions on1254x1254 canvas.
  NO runtime color tint, white modulation. A composition of up to two native
  lengths minimizes fit error at a common target width, then all pieces receive
  one common uniform fit. No arbitrary four-piece limit, no independent x/y
  scale. Width comes from the connected corner port, default94 for standalone
  vertical passages. The v9 center plate is allowed only for gaps shorter than
  1.5 times target width, never repeated as a long wall cadence.
- Standalone vertical corridors and connected side runs share make_run. Closed
  rooms still retain their legacy pair positions (normalize315, center+/-41,
  top-15, scale.92) using the new source/white tint. Do not claim all14 old
  captures unchanged: their vertical art intentionally changes. Floors and
  horizontal standalone corridors stay fixed. Alpha-native generation alone
  does not establish perfect joints or artistic approval.
- Connected sprite layers remain supportZ0/floorZ1/facadeZ2, etc., above the
  opaque background. Frame bounds use complete sprite rectangles plus40px
  margin, never rendered masks. Original closed corner art remains unchanged.
- Inspect `3x3RoomFourCorridors.png`, its 2x version, four junctions and the
  focused west-floor/corridor-wall-foot/corner-style captures at4x with
  `tools/capture_room_corridors.gd`. `tools/capture_module_connections.gd`
  renders all16 masks, lengths1/2/3 and same-instance close/reopen. Review
  `connection-masks-comparison.png`, `connection-lengths-comparison.png`,
  `junction-perspective-comparison.png`, `junction-continuity-comparison.png`,
  `junction-profile-comparison.png`, `wall-profile-shared-comparison.png`.
  Inspect the entire four short runs in `junction-all-returns.png` and the
  before/after `junction-native-parts-comparison.png` / `vertical-material-comparison.png`.
  General west4x crops the lower short course; use west-lower-return4x explicitly.
  `junction-ports-{west-upper-return,west-lower-return,north,south}-comparison.png`
  compares the actual24721 baseline saved in artifacts/before-port-widths.
  Captures do not establish artistic acceptance or perfect arbitrary joins.
- Current `project.godot` F5 target is `3x3CellRoom.tscn`; `SixRoomPreview.tscn`
  still contains the six-room composition. Do not infer the launch target from
  historical F5 descriptions below.
- SMALL FLOOR TILES are correct. Each logical cell contributes two paving rows;
  mixed native widths vary the number of individual decorative pavers.
  `modular_room_study.gd` and `modular_study_kit.gd` share
  complete native-alpha sprites across all seven scenes; never create a room
  or half-room image instead of modular parts. F5's six-room map is unchanged.
- Latest perspective correction overrides earlier requests for dark inner faces:
  vertical sides show TOPS ONLY, no dark inner strip and no exterior backing.
  Original caps/corners use `cap-continuous-v10.png`; shared sides now use
  `wall-tops-ports-v12.png`. Connected corners/transitions use v9/paired-v7 above.
  Horizontal stones retain their visible front thickness. The flattened v7
  caps were rejected; integrated v9 walls corrected the overhang but introduced
  course-height steps at module ends. The current cap preserves that flush
  front face while separate brick-soft-v2 courses run across the ENTIRE wall,
  starting at y=88 relative to the cap anchor. Never restart them at corners.
  Side textures now use white modulation. Closed-room pair placement retains
  offsets [0,3,-2,1] mirrored on east/west; open vertical passages use make_run. No stair feet.
  Keep facade faces flush beneath the caps.
  Do not overlap painted cap ends to hide joints: that sliced the next stone.
  Thick black outer contours were corrected with ImageGen native alpha, never
  programmatic trimming. Retain the thin native outlines and complete ends.
- `floor-varied-v2.png` supplies twelve pavers in three native proportions:
  six quiet stones and six different cracks, with softer texture. The user
  rejected the busy texture and repeated identical sizes in floor-variants-v1.
  No engraved center tile. Seed 173, whole-row width ordering and five subtle
  per-stone tints provide deterministic variety. The user approved these floor
  variations; keep their exact layout and PNG. Multiply their existing RGB
  modulation by (1.74,1.61,1.40) to lighten the floor without excessive blue;
  alpha remains 1. Floor rows cross logical-cell
  boundaries without extra gutters. Each row scales uniformly to its span;
  open vertical passages fit the whole paving composition uniformly to their
  length. Native proportions are preserved. `brick-soft-v2.png` supplies four
  softer masonry variants in two lengths, RGB1.10. Cell pitch (476,256), scale0.29.
  Regions select whole sprites and their transparent gutters only.
- The user explicitly requested VISUAL inspection, not the old programmatic
  tests or probes, for this art correction. `capture_modular_room.gd` renders
  all seven cases at 1x/2x and four sides at 4x, without assertions or scores:
  `artifacts/<SceneName>.png`, `<SceneName>-2x.png`,
  `<SceneName>-{west,east,north,south}-4x.png`.
  Inspect `cell-rooms-comparison.png` and `corridors-comparison.png` too.
  The historical `verify_single_cell.gd` is outside the active suite and
  describes a rejected assembly. Do not revive it as artistic validation.
  These studies have no entrance, heart, torch, gameplay, collisions or saving.
  Current correction provenance is in
  `assets/dungeon/modular-study/continuous-courses-generation.json`.


- The user rejected the current native-alpha wall composition on 2026-10-21.
  It is NOT an approved perspective baseline: repeated cap blocks, upright
  pier faces and thin filler stones read as incompatible stacked objects.
  The current floor rendering also differs visibly from the original reference.
  Passing alpha, coverage or overlap checks does not resolve this rejection.
  Re-establish a coherent reference-matching wall/floor/corner study before
  propagating another asset revision across the six-room map.
- Latest user corrections: the entrance must share the other walls' height,
  stone scale and treatment; break long aligned joints in floors and masonry;
  cover exposed exterior edges even beside corners and piers. Determine those
  edges from the visible perimeter, not blanket rectangular pier exclusions.
  The user prioritizes visual fidelity and asked to set probes aside for now.
  Use actual rendering and direct comparison with the original as the acceptance
  method for this art calibration; technical probe passes are not the objective.
- `scenes/ReferenceCalibration.tscn` is a separate, UNAPPROVED visual study (F6),
  assembled from five complete PNGs in `assets/dungeon/reference-study/` plus
  the two existing torch sprites. `reference_calibration.gd` is not the six-room
  renderer. Inspect `reference-calibration.png`, `reference-calibration-2x.png`
  and `reference-calibration-comparison.png`; do not treat this study as an
  approved replacement kit or a completed six-room correction.
- The separate arch over fitted returns was rejected as pasted on. The study
  now uses `entry-masonry-v3.png`: wall courses, arch, inner reveals and threshold
  are drawn as ONE complete native-alpha masonry module, scale 0.44 at (27,-86),
  Z3. `door-leaf-v4.png` contains only the wooden leaf, scale 0.128 at (238,43),
  Z2, tint (0.78,0.80,0.85,1), behind the transparent aperture. Wall foot is near
  y=225, jamb feet near y=243. `east-corner-v1.png` joins under its existing pier
  at scale 0.75, position (0,-75), Z4, tint 0.9. All receive light mask 2.
  `door-masonry-comparison.png` shows original/rejected/current rendering;
  `door-integration-opening.png` hides ONLY the wooden leaf, retaining the arch.
  These review artifacts do not establish user approval or exact fidelity.
- The leaf v3 was rejected as stylistically detached from the masonry. The v4
  PNG repaints its wood in quieter brown planes and its fittings in darker,
  less reflective iron. Its whole native-alpha silhouette is uniformly scaled
  to the previous visible footprint. Inspect `door-style-comparison.png` and
  the 2x capture; style acceptance remains visual, not a numeric test result.
- The broad aperture was redrawn: measured alpha spans are now 107 x 119 px,
  versus the rejected 118 x 113 px. `door-proportions-comparison.png` shows
  original / broad doorway / current study at the same capture scale. The
  capture regression rejects an aperture width/height ratio outside 0.70–0.90;
  this geometric guard does not establish fidelity to the reference artwork.
- Study torch instances use uniform scale 0.36 (25% smaller), with feet
  at (160,225)/(460,225), symmetric at +/-150 px around the visible arch axis
  x=310. Their light centers follow at y=176.25. The focused capture checks
  spacing against both visible jamb edges (2 px tolerance), equal torch height
  and scale, and following lights. Inspect `torch-spacing-comparison.png`.
  This override
  belongs to ReferenceCalibration; the shared torch scene retains scale 0.48.
- `scenes/SixRoomPreview.tscn` is the main scene: six rooms, 255 floor cells,
  96 px logical cells, 3008 x 2048 px composition. It uses complete Sprite2D art,
  overlapping whole floor substrates and appropriately placed walls/piers.
  There is no gameplay, procedural generation, animation or save system.
- The artistic reference remains
  `assets/dungeon/perspective/reference-atlas.png`. Main production rendering
  no longer samples it. `scenes/PerspectiveRoom.tscn` preserves the historical
  source-frame (0, 120, 560, 510) study and its old polygons; do not reuse that
  cutout pipeline for production. The rejected low-wall/side-door experiments
  and `docs/reference/approved-scene.png` are historical, not perspective targets.
- Side-wall cores and outside backing MUST be separate sprites. The user rejected
  the baked side row because it crossed right-angle junctions. Cores are 68 px;
  outside stones are 24 px with 2 px overlap, only on exposed spans. Stop backing
  before horizontal facades and corner piers; it may continue behind straight-run
  buttresses. Do not restore a baked exterior row or rotate masonry faces.
- The rejected implementation repeats caps with south-facing lips and stops
  their runs at upright piers, filling gaps with short caps. Do not treat this
  assembly rule as an approved art requirement. Its current nominal wall body
  heights are 117 px north, 101 px south and 191 px at the entrance; corner piers
  are 68 px wide and side buttresses 76 px. These are implementation measurements,
  not validated reference proportions. Preserve uniform scale and open passages.
- The north entrance remains at logical cell (3,3). Door body bottom is (546,454).
  Preserve the 22 px continuous floor underlay. Whole entrance wall ends are
  hidden under corner columns and their middle join behind the arch.
- `DungeonTorch.tscn` uses true alpha, imported at 256 x 384, scale 0.48,
  offset (-128,-321), feet at (430,454)/(662,454). Two static lights use mask 2.
  Floors and walls receive that mask; fixtures/piers keep their painted light.
- `Dungeon/Heart` is the authored `DungeonHeart.tscn` at (2368,784).
  Its generated complete PNG depicts the approved square pedestal/vortex design.
  It has one sprite and one static light. Rebuilds preserve the authored instance.
- `stone_variation` defaults to true with seed 173. Six complete floor variants
  in three proportions and two north/south variants provide art variation.
  Per-stone tints are deterministic. Disabling variation selects variant zero
  and white top-surface tint; geometry and sprite count stay the same.
- Default counts: 852 generated sprites, two torches, one heart sprite and three
  lights = 858 inspectable elements. The masonry includes 99 side-core and 102
  separate outside sprites. F3 has 644 unchanged fixed spatial probes. Picking
  ignores alpha below 0.5; source PNG path, atlas region and local UVs are exported.
  The editor refresh interval is 0.5 s; no periodic inspection runs in play mode.
- For rendering changes run `tools/test-mobile.ps1 -All -Capture`; inspect
  `artifacts/dungeon-2d.png`, `six-room-details.png`,
  `vertical-wall-details.png`, `alpha-joins-2x.png`,
  `entrance-seams-detail.png`, `heart-detail.png`,
  `stone-variation-before-after.png`, `wall-projection-comparison.png` and
  `reference-comparison.png`. The wall comparison shows entry/upper room at
  the same camera scale; it is not a pixel comparison with the original art.
- `verify_wall_layers.gd` checks independent exterior layers, no overlap with
  corner/horizontal-facade spans, and no core stones underneath pier faces.
- Native-alpha regression checks source alpha, absence of production polygons,
  materials/clipping and nonuniform scales, plus transparent atlas boundaries.
  GPU checks compare alpha compositing at 599 map, 3828 entrance and 2809 heart
  samples with lights disabled, tolerance 4/255. These derive textures/transforms
  from the scene and are not independent proof of approved geometry. Fixed
  spatial probes and visual inspection are complementary.
- The reference comparison measures only the historical entrance study.
  Arbitrary layouts, side entrances, memory profiling, mobile exports and touch
  controls remain unvalidated. The old gameplay/assets are in Git at v1.0.0;
  do not restore them as dependencies of this foundation.
