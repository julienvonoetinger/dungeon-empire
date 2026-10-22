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
- This direction supersedes older RGB instructions. The modular studies now use
  native palette PNGs with white modulation: floor-calm-v3, brick-muted-v3,
  cap-muted-v11, cap-square-v3, cap-tight-v13, wall-tight-v22/v23, cap-compact-pairs-v24,
  cap-elbows-square-v7, paired-cap-square-v7,
  narrow-separator-muted-v4 and solid-separator-muted-v9. Their geometry follows
  the former atlases listed below; floor-calm-support-v1 supplies shaded supports.
  No floor brightness multiplier, per-stone runtime tint, facade1.10 or support0.70
  remains in the modular renderer. Earlier six-room art is a separate legacy scene.
  Commit2584f57 preserves the state before this palette revision. Exact prompts,
  source mappings and visual-review scope: calm-palette-generation.json.
- Review each shared change against the existing small room/corridor scenes and
  connected configurations at normal scale and enlarged. Reopening connections
  must select the same shared art. Gaps, ledges and painted-end overlaps remain
  defects even if a technical check passes. Arbitrary player-built dungeons are
  the target; the current limited studies do not yet implement that system.

## Current rendering scope

- The modular `Dungeon` inspector refresh button uses a computed Callable getter,
  not a stored initializer: hot reload can leave the stored property Nil.
  Keep this in the shared modular_room_study.gd base for connected studies too.
  The isolated editor diagnosis in artifacts/editor-button-inspection.log invoked
  it before/after parent-script reload and retained302 sprites in3x3RoomCornerCorridors.
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
  one odd rectangular room with configurable N/S attachment columns and W/E
  attachment rows, captured at3x3 and5x5. Empty horizontal_attachment_rows keeps centered ports;
  explicit rows are sorted/deduplicated, invalid indices ignored. All-invalid
  explicit list gives no horizontal branches. Floor extensions use each branch's
  own two paving rows and physical end bounds; supports follow its first row.
  No player editor, navigation, saving or arbitrary multi-room renderer exists.
  Branch logical length counts straight modules; their native corner arms add
  physical span. Do not claim these ports already fit a future navigation grid.
- `scenes/5x5RoomFourCorridors.tscn` is the new UNAPPROVED comparison: layout
  study_5x5 (25cells,10floor rows), same renderer/kit, horizontal3/vertical4,
  connections15. Physical anchor span2462x1449 atscale.29. Closed shoulders
  span2columns, so shared single corners/straight caps are used, not1column
  paired modules. Do not add scene-specific art repairs. Capture with
  `tools/capture_room_corridors.gd -- --scene=5x5RoomFourCorridors`.
  Review full/2x and12 individual corner-X-Y4x images plus corners-comparison.
  Corner centers derive from actual plan anchors; generic shoulder details do
  not fit all5x5 corners in one crop. F5 target stays3x3CellRoom.
- `scenes/5x5RoomVerticalCornerCorridors.tscn` is UNAPPROVED: shared5x5 layout,
  vertical_attachment_columns[0,4], connections5, corridor_length3, four open
  north/south far ends. The new shared column setting mirrors horizontal rows:
  empty centers, explicit indices normalize/sort/deduplicate, all-invalid disables
  vertical branches. Each column reuses the existing whole passage paving; central
  pavers remain fixed. No new art. Capture --scene=5x5RoomVerticalCornerCorridors
  and inspect1x/2x/four inner corners4x; shaft/corner contour differences remain.
- `scenes/5x5RoomCornerCorridors.tscn` is the UNAPPROVED5x5 counterpart:
  shared study_5x5 layout, horizontal_attachment_rows[0,4], connections10,
  corridor_length3. No renderer or asset changes. Capture with
  --scene=5x5RoomCornerCorridors; inspect full1x/2x and four inner corners4x.
- `scenes/3x3RoomCornerCorridors.tscn` is UNAPPROVED: shared3x3 layout,
  horizontal_attachment_rows[0,2], connections10 (E/W), length3, four open far ends.
  Capture with --scene=3x3RoomCornerCorridors and inspect its two separator tips
  in corners-comparison. Long open/open horizontal runs use native end bounds
  established by closed-turn runs; choose WHOLE count/origin at fixed476 cadence,
  never per-span compression. Opposing horizontal boundaries enclosing one empty
  logical row, with one common closed end and one open end, now select a shared
  separator. The two caps, two corner sprites and short side return are omitted;
  one broad cap and a complete solid terminal replace them. The original flat
  v5 ends were rejected: the facade looked like a curtain below a thin slab.
  `modular_separator_kit.gd` registers complete regions/ports from
  `narrow-separator-muted-v4.png` and `solid-separator-muted-v9.png`, with white tint,
  uniform scaling and476 straight cadence. Original open-end bounds are retained.
  The rule depends on exposed edges, not room size or scene name. Wider voids,
  enclosed islands and vertical dividers remain outside this new selection rule.
  The v7 oblique end face was rejected for inconsistent perspective. The v8 PNG
  includes two cap stones and both masonry courses in the shared orthographic
  projection: height runs straight down; the closed edge stays at the same x
  from cap to foot, without a diagonal side plane. Separate bricks stop at its connecting edge; none
  render below the terminal. Native top/course/base ports select whole brick
  counts for each straight course. Terminal regions are982x801 on1964x801;
  body bounds are(202,166,669,539)/(1094,166,671,539), cap height316.
  Two separator-tip details replace the four consumed corner details in this
  scene's capture. Provenance: `solid-separator-generation.json`. User visual
  approval remains pending; this does not validate arbitrary layouts.
- The current square-turn correction uses `paired-cap-square-v7.png`
  (four whole double-bend modules, slots768x512, anchor96,256) and existing
  `cap-elbows-square-v7.png` for compatible single corners. Earlier paired-v1
  and width/depth experiments cap-elbows-ports-v11/v12, paired-v2/v3/v5/v6 are unused.
  Paired-v4 was rejected for a high-alpha backdrop; no alpha cleanup attempted.
  The latter experiments displaced horizontal joins or made fronts too deep.
  Historical width provenance: `port-width-generation.json`; current native
  square turns: `square-corners-generation.json`. Visual approval pending.
- `modular_join_kit.gd` measures each paired shaft's horizontal extent and its
  actual vertical ends, plus the horizontal strip profile. `paired_fit` maps
  the TWO shaft centers to41/517 at476 spacing with ONE uniform transform;
  apply that SAME transform to y ports. Native profile fit remains approximate;
  the old0.55px estimate described muted-v8, not the new square atlas. Single corners use their measured
  shaft centers, not an assumed center41. Preserve complete original regions.
  Their native profiles remain NW/NE[-14,99], SW/SE[1,114]; raw y ports
  NW[-19,165], NE[-19,164], SW/SE[-61,120]. Full horizontal extents are in SHAFTS.
  Retain the calibrated compact profile frame: fitting its extra black rim
  as stone thickness shrinks the horizontal arms and opens their connections.
- Outside bends must continue the BLUE stone face to the outside end. Do not
  square an old chamfer by adding a black backing rectangle. This failed in
  cap-elbows-square-v4 and was explicitly rejected by the user. The active
  compact-v7, closed-v3 and paired-v7 native images extend the front face itself.
  Whole regions, uniform scale and white modulation remain mandatory. Inspect
  `5x5RoomVerticalCornerCorridors-north-span-2.5x.png` with both cap ends and
  the facade visible, plus the individual corner captures. The square closed-v2
  attempt shortened adjacent stones and broke the2x2 side cadence; it is unused.
- Short returns align signed gaps with absolute value at most82, shifting
  WHOLE horizontal runs by half the gap. This also separates negative gaps
  instead of leaving painted ends overlapped. No tiny spacer between shoulders.
- Small and connected studies retain the shared horizontal profile: north/south
  cap scale .99/.97, cadence476 and continuous staggered courses. Facade starts
  come from course_top:96 north,105 south, below the complete painted cap feet.
  Never reinstate per-span cap compression or per-scene facade heights. Stop
  facades at closed corner anchors (retain75 under NW/NE downward arms);
  -12/+14 extensions belong only to open ends. Central approved paving stays
  fixed; west/east continue its exact rows2/3. Supports remain whole pavers,
  y-40; their shade is now painted in floor-calm-support-v1.png, white modulation.
- `modular_side_kit.gd` uses two whole native pairs from cap-tight-v13,
  two compact pairs from cap-compact-pairs-v24, plus eight complementary
  singles from wall-tight-v22/v23. Compact pairs fill short spans without two
  isolated filler squares; they participate in the same shared length search.
  Pair indices0,1,10,11 cost2, singles cost5. The v16
  replacement was rejected for color and width differences; v17/v18 still left
  excessive dark end bands. Native blue color,
  bevels and outlines stay in the PNGs; white modulation only.
  Width is FIXED by the connected corner port (default94 for standalone
  passages). Never multiply it by a height-fit factor. A0.25-unit length search
  chooses whole sprites at that width, preferring the existing cap-atlas pairs.
  Remaining positive length is distributed over joints, with a strong penalty
  above2 source units per joint. There is no stretching or painted-end overlap.
  The short center plate is allowed only for gaps shorter than
  1.5 times target width, never repeated as a long wall cadence.
- Closed rooms, standalone vertical corridors and connected side runs now share
  make_run. The old315*.92 pair at256 cadence overlapped by33.8 source units;
  never restore that placement. Closed corner ports are top279/bottom-166,
  shaft width101, centers41.75 west/-38 east, in modular_wall_profile.gd.
  Width was calibrated from103 to101 for all closed-corner ports, never fitted
  per span. With square closed-v3, the2x2 span is236 and selects compact pair11:
  height234.496, each external gap0.752. The prior237-unit span selected pair10.
  Native dimensions,
  all generation attempts and capture scope: compact-pairs-generation.json.
  Complete silhouettes use uniform scale from width alone.
  cap-square-v3 supplies whole closed corners; cap-tight-v13 retains side pairs;
  horizontal straight strips remain cap-muted-v11. No painted edge is cropped.
  No filler is added for nonpositive gaps; the pre-existing1x1 corner-to-corner
  contact is unchanged. Provenance: tight-joints-generation.json; earlier attempts
  remain recorded in vertical-width-color-generation.json.
  Do not claim old captures unchanged: vertical art and facade starts change.
  Floors stay fixed. Alpha-native generation alone
  does not establish perfect joints or artistic approval.
- Connected sprite layers remain supportZ0/floorZ1/facadeZ2, etc., above the
  opaque background. Frame bounds use complete sprite rectangles plus40px
  margin, never rendered masks. Closed corner regions retain their original anchors.
  Inspect the isolated rooms' southwest-4x captures for the full first brick below
  the corner, plus west/east-4x for double end outlines and spacing.
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
  or half-room image instead of modular parts. The legacy six-room map stays separate.
- Latest perspective correction overrides earlier requests for dark inner faces:
  vertical sides show TOPS ONLY, no dark inner strip and no exterior backing.
  Straight caps use `cap-muted-v11.png`, closed corners use `cap-square-v3.png`;
  shared sides use cap-tight-v13, wall-tight-v22/v23 and compact-pairs-v24.
  Connected corners/transitions use the square-v7 atlases above.
  Horizontal stones retain their visible front thickness. The flattened v7
  caps were rejected; integrated v9 walls corrected the overhang but introduced
  course-height steps at module ends. The current cap preserves that flush
  front face while separate brick-muted-v3 courses run across the ENTIRE wall,
  starting at y=96 north/y=105 south relative to the cap anchor. Never restart them at corners.
  Side textures use white modulation and all straight sides use make_run.
  The legacy pair placement and its [0,3,-2,1] shifts are removed. No stair feet.
  Keep facade faces flush beneath the caps.
  Do not overlap painted cap ends to hide joints: that sliced the next stone.
  Thick black outer contours were corrected with ImageGen native alpha, never
  programmatic trimming. Retain the matching native outlines and complete ends.
- `floor-calm-v3.png` supplies twelve pavers in three native proportions:
  six quiet stones and six different cracks, with softer texture. The user
  rejected the busy texture and repeated identical sizes in floor-variants-v1.
  No engraved center tile. Seed173 and whole-row width ordering retain the
  approved arrangement. The new material is smoother and more uniform, with
  subdued cracks and native color variation. White modulation only: the former
  five tints and(1.74,1.61,1.40) correction are removed. Floor rows cross logical-cell
  boundaries without extra gutters. Each row scales uniformly to its span;
  open vertical passages fit the whole paving composition uniformly to their
  length. Native proportions are preserved. `brick-muted-v3.png` supplies four
  softer masonry variants in two lengths, white modulation. Cell pitch(476,256), scale0.29.
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
