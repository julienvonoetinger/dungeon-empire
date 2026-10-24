# Repository instructions

## Retired large assets removed — 2026-10-24

- User explicitly requests deleting obsolete large files after the mobile migration.
  This supersedes earlier instructions to retain retired generated PNGs and local
  archive copies. Keep the active mobile kit, props, material sources, geometry,
  selected reviews and original references.
- Removed painted-connected/, painted-cells/, their unused runtime catalogue and
  style selector, and 17 named obsolete cache/archive directories under artifacts/.
  Exact paths, sizes, SHA256, recovery commits and preserved dependency hashes:
  docs/cleanup/2026-10-24-retired-large-assets.json. No replacement archive copy.
- export_mobile_kit.cjs reads frozen legacy-catalog-inventory.json for historical
  comparisons; it must not require the retired PNG directories to exist.
  Their summed RGBA remains a historical catalogue measure, not old live VRAM.
- Shared materials, wireframe geometry, nw-material-review-v2/validation.json and
  the pillar cap source remain necessary. Historical tools/docs can mention retired
  paths; use the mobile export pipeline for current assets. Git history is retained.
- Do not remove/reset the user's .godot/ cache or editor state. No automated tests,
  commit or push without a user request. See docs/cleanup/README.md for the outcome.

## Full mobile architecture migration — 2026-10-24

- User asks to finish optimization with the rest of the kit. This authorizes
  production migration beyond the prototype and supersedes prototype-only gates.
  All 21 architecture scenes now share assets/dungeon/mobile-kit/catalog.tres
  and atlas-256.png: 23 prepared sprites in one 1024x2048 atlas (8 MiB RGBA).
- Keep 256 source px/cell, fixed .75 zoom, free finger/mouse panning, no user
  zoom, logical 1x1 grid, three calm floor rows, two wall facade courses and
  separate pillars. Existing layouts and wide SixRoomPreview corridors preserved.
- Common bare stone replaces the complete A/B/C/D2 variation families. The
  recessed pillar top is an optional separate patch, still a visual proposal.
  Do not reintroduce the rejected historical A/B/C medallions into the active kit.
- export_mobile_kit.cjs shares primitives/materials/packing with the prototype
  helper. mobile_special_parts.cjs adapts the four doors and stairs to walls
  centered on grid edges (inner side at T/2). Door arch radii increase by T/2,
  thickness T stays fixed. Reproject geometry, never rotate a raster sprite.
  Four complete stairs are composed offline; each door has separate arch/leaf.
- mobile_dungeon_renderer.gd only places prepared AtlasTextures. Physical support
  bounds order walls/pillars/stairs/leaf/arch; optional cap follows its pillar.
  Do not generate image pixels, materials or perspective at runtime. Preserve
  periodic complete floor stones before clipping, original wall/pillar contacts.
- The common renderer refreshes catalog regions and the external PNG together;
  watches imports after scanning completes; reconnects and checks timestamps on
  scene reentry. It narrowly removes old unowned generated Floor_/Walls_/Door_/
  Entrance_ children during renderer migration, preserving authored scene nodes.
- Reproduce: node tools/export_mobile_kit.cjs, Godot import,
  tools/capture_mobile_kit.gd, node tools/prepare_mobile_kit_review.cjs.
  Old direct prepare_mobile_reference.cjs invocation is historical only.
- Android Mobile preset explicitly selects 40 active dependencies. Use
  prepare_mobile_export.cjs to stage only them in a fresh ignored directory before
  export. Existing editor filesystem caches can retain retired dependencies even
  after import. Never reset/restart the user's editor or delete its cache.
  Material libraries and authoring sources are retained but not shipped. Retired
  large PNGs were subsequently deleted; see the cleanup section above. Heart/torch
  props remain separate and outside this architecture export.
- Evidence: docs/reference/mobile-kit/README.md, recipe.json, package-report.json,
  scene-inventory.json and captures. 60 captures / 21 scenes, import and resource
  export exit 0 with empty stderr. MobileReference editor/runtime images match.
  Custom editor capture has native screen/progress/shutdown warnings; don't call
  its stderr clean. No automated tests or Android device profiling performed.
  Independent review's migration cleanup and watcher findings are resolved.
- This source migration does not validate every future arbitrary layout or imply
  final artistic approval of the optional cap. Do not claim old catalogue summed
  RGBA was old live VRAM; contexts were loaded lazily. Do not count the resource
  ZIP as a complete APK. No commit/push until the user asks.


## Mobile editor atlas refresh — 2026-10-24

- User reported a broken MobileReference editor preview after atlas repacking.
  The script read catalog.json only at _ready and used cached AtlasTexture .tres
  and their external PNG dependencies. A persistent editor could mix generations
  while fresh runtime captures were correct. Do not repair geometry for this.
- scripts/mobile_reference.gd now refreshes catalog + used .tres + each external
  atlas PNG together. Editor loads use CACHE_MODE_REPLACE, once per resource
  path per refresh; runtime uses normal caches. Parameter-only rebuilds reuse
  loaded resources, and a newly selected density gets fresh editor resources.
- Computed Callable button "Actualiser le rendu" on the root MobileReference
  node. It also attaches the editor watcher for old hot-reloaded instances.
  EditorFileSystem reimport/reload events queue a refresh; filesystem changes
  check the catalog/image timestamps. Wait until scanning/importing finishes.
  Preserve current inspector options, scene edits and camera view. Never restart
  the user's editor to flush these caches. No runtime pixel generation.
- Capture utility accepts --editor and waits for editor import before producing
  editor-preview/ PNGs. The default 256 editor/game captures match exactly.
  The custom editor capture process emits native editor shutdown/progress-dialog
  warnings; record those, do not describe its stderr as empty. Runtime/import
  captures exit 0 with empty stderr. No automated tests were added or run.
- Details, original screenshot and scope: mobile-optimization/editor-preview/.

## Integrated pillar top proposal — 2026-10-24

- User rejected the detailed A/B/C ornaments at gameplay distance: tiny detail
  disappears and the relief looks pasted on. Their "ok" approves prototyping a
  simple large recessed diamond painted WITH its stone top background. This
  supersedes the proposal direction below, not the common bare-base architecture.
- Latest review: docs/reference/pillar-cap-review/. ImageGen original, exact
  prompt and previous state are frozen in source/ and generation.json. No tiny
  chipping, multiple rings or floating medallion silhouette. Judge at the actual
  ~46px-wide top first, not enlarged source art. Appearance awaits user review.
- tools/mobile_pillar_cap.cjs maps the generated opaque top into the existing
  top geometry using the approved offline material/mask workflow. Retain the
  original 3px rim and blend over the next 3px of quiet stone. No guide movement.
  Final density exports suppress cap pixels outside the opaque top interior;
  the bare pillar below retains its original bevel and silhouette alpha.
- pillar-top-carved is a prepared 68x68 top patch at density 256 (34x34 at 128),
  same ground anchor as pillar: (-50,-114). Godot overlays the whole prepared
  stone top at the support's depth. Do NOT add the old height translation again.
  This visually replaces the upper surface, reusing the common full bare pillar.
- MobileReference defaults to "Dessus creusé"; old A/B/C remain explicitly
  historical comparison choices, and old wall ornaments are disabled by default.
  Current prototype has 10 geometry + 4 detail images including those three old
  comparisons. Offline rectangle packing keeps atlases at 512x256 / 1024x512.
- Export audits at both densities: zero composed-alpha differences and zero RGB
  changes outside the top interior against the same transparent-overlay pipeline.
  Nine Godot captures/import exit 0, empty stderr. Review normal game scale and
  enlarged actual game pixels. No automated tests or phone-performance claim.
- Reproduce mobile export/import/captures, then tools/prepare_pillar_cap_review.cjs.
  The older A/B/C review uses frozen captures in its source/captures directory.

## Historical separate painted decoration proposals — 2026-10-24

- User confirms bare walls, floors and pillars with separate decoration sprites.
  The old thin procedural diamonds are rejected as appearance references. Keep
  the bare geometry and common paint; enrich the separate artwork instead.
- Three native-alpha ImageGen proposals in docs/reference/mobile-decoration-review/:
  A sculpted slate diamond, B ancient octagonal seal, C localized violet socket.
  Their application was rejected for small-scale readability and pasted-on look.
  A was the old default preview only, not an approval record.
  Original images and exact prompts are frozen in source/ and generation.json.
- tools/mobile_painted_decorations.cjs preserves the complete native-alpha source,
  uniformly resizes/pads it into a common centred 68x68 frame at density 256.
  Alpha >8 bounds measure centre/scale only; never threshold or remove alpha.
  The main subject is 44px tall, about 33 displayed px at the proposed game scale.
- Prototype IDs decor-a/b/c replace ornament-h/v/pillar. Pillar choice is exposed
  through historical detail_style choices in F6. Old wall examples use C at .72
  uniform scale. Their common horizontal top plane needs translation by the
  projected support height only; no runtime painting/perspective deformation.
- Retain support-depth drawing order: each decoration immediately follows its
  own wall/pillar so foreground geometry can hide it. Both decoration toggles
  off show the bare bases. No production-catalogue migration is implied.
- Reproduce atlas/captures with the mobile reference commands, then run
  tools/prepare_mobile_decoration_review.cjs. Comparison includes enlarged source
  art and unscaled Godot crops. Eight captures exported; stderr empty; reviewed
  A/B/C at game scale. No automated tests or mobile profiling performed.

## Mobile optimization direction — 2026-10-24

- User now targets mobile with a fixed viewing scale comparable to the original
  mockup. No user zoom; FREE camera panning by finger is explicitly selected.
  Do not fit the entire dungeon into the screen as the future gameplay framing.
- Simplify surfaces for that reading distance and reduce sprite resolution.
  Exact reference scale and pixel dimensions are still to be established visually.
- User proposes one common stone appearance plus separate prepared transparent
  decoration sprites (cracks/corruption), instead of complete painted style sets.
  This supersedes the prior single-complete-image restriction for decorative
  overlays. No runtime texture generation or perspective deformation.
- Distinct pillars like the mockup should terminate/join walls at corners.
  Use real geometric contacts/occlusion; remove the need for continuous painted
  stones turning around corners. Preserve the fixed projection and 1x1 grid.
- Latest correction: floor slabs are now too large relative to wall bricks.
  Match the mockup's proportions. The old approved C slab size is superseded as
  a constraint for the next proposal; retain calm floor surfaces and rounded corners.
- Decisions and exact user references: docs/reference/mobile-optimization/.
  This is the new design direction, NOT an implemented migration. Current
  A/B/C/D2 assets remain active from 6a6fcaa7. First establish a small reference
  scene and viewing scale before regenerating the production catalogue.
- No tests added/run without a user request.

## Mobile reference spike — 2026-10-24

- User accepted preparing the small reference scene ("ok"), not a production
  catalogue migration. New scene: scenes/MobileReference.tscn, separate script
  and assets/dungeon/mobile-reference/. Existing scene contents are not migrated.
  The local main_scene setting currently points at this prototype; preserve it.
- Proposed values: 192 displayed px/cell at 1280x720, zoom .75, free finger/mouse
  panning. 3x2 room plus east/south branches. Three floor rows, .32..35-cell slabs,
  quiet rounded finish; .24-cell pillars against 1/6-cell walls. Not yet approved.
- Offline exporter tools/prepare_mobile_reference.cjs reuses approved paint with
  local reduced contrast. Current fourteen logical sprites: floor, eight wall
  terminations, bare pillar, carved top, three historical decorations.
  One wall appearance; no runtime painting. pillar_details / Décors piliers
  toggles the separate pillar detail independently of walls. Do not rebake it.
- Two comparison atlases: 128 px/cell (512x256) and 256 px/cell (1024x512).
  Default 256 appears clearer; source resolution is still an appearance decision.
- Pillars must NOT have a global layer above walls. This caused the reported
  NW overlap. Walls/pillars now share a layer, sorted by ground-support depth
  along (.18,.9); each ornament follows its own wall. Freeze the before capture
  in mobile-optimization/join-review/. Recheck occlusion for future geometry.
- Physical wall ends meet pillars. New geometry is a proposal, not validated by
  old guides. Preserve integer grid, common projection, two facade courses.
- Reproduction, isolated magenta guides, scope and captures in
  docs/reference/mobile-optimization/. No automated tests or mobile profiling.
  Do not generalize this spike to all production variants without user review.

## Wall variants with D2: integration authorized — 2026-10-23

- User said "Go" after selecting D2. Integrate complementary A/B/C walls and
  selected D2 in Godot. This supersedes proposal-only gates for these materials.
- Active recipe: `shared-materials/active-recipe.json`, wallVariation section.
  Source `wall-variation-atlas-v1.png` is copied unchanged from the reviewed
  atlas. Exact crop hashes are checked by prepare_shared_stone_materials.cjs.
  The smooth rounded floor, wood, iron, B finish and geometry are preserved.
- `tools/wall_material_variation.cjs` paints whole local faces. Any stone
  touching a longitudinal cell boundary, leaving the centre cell, or belonging
  to a pillar keeps common quiet paint. Interior stones vary. D2 has one UV
  rectangle unfolded across top/upper facade, with per-face lighting preserved.
- `tools/export_connected_stone_contexts.cjs` exports complete A/B/C/D2 PNGs
  and deduplicates identical results. catalog.contextStyles maps a geometric
  context to four paths. Keep context/material/UV signatures and lazy loading.
  A material promotion needs a FULL export, not --specials-only.
- `painted_wall_selection.gd` deterministically chooses a prepared style per
  integer cell: base buckets A8/B4/C3/D2-1 out of 16. Only the lowest-hash
  neighbouring D2 candidate survives (eight neighbours, coordinate tie-break).
  It selects files only; never generate or recolor images in Godot.
- Re-export both kits and import Godot after material changes. The isolated
  references use D2 on eligible stones; assembled scenes use all four styles.
  Preserve layouts, wide SixRoomPreview corridors and all special orientations.
- Completed: 2,900 unique structural PNGs / 1,444 four-style contexts (161 empty),
  plus 57 isolated images / 146 aliases. Export audits report zero alpha or
  unpainted-interior differences; joints match. Shared floor hash unchanged.
  Godot import and 53 captures of all 20 scenes exit 0 with empty stderr.
  Boards and selected enlarged joins reviewed; future arbitrary joins unproven.
  641 unreferenced previous PNGs and their .import files are archived locally
  under artifacts/wall-variants-retired/; inventory is in the integration review.
- Current execution/evidence: docs/superpowers/plans/2026-10-23-wall-variants-d2.md,
  docs/reference/WALL_VARIATIONS.md and wall-variants-integration/. Reproduce
  boards with tools/prepare_wall_variants_integration_review.cjs after captures.
  No automated tests without user request.

## Corrupted wall D2 selected — 2026-10-23

- User selected "D2" from `wall-corruption-review-v2/comparison.png`.
  Retain D2 as the corrupted wall appearance; old D is rejected and D1 is an
  unselected comparison. This supersedes the pending D2 appearance status below.
- Exact material: `corruption-v2-1`, crop left 1070, top 390, width 170,
  height 220 from the existing `atlas-calm.png`. Preserve the continuous
  unfolded mapping across top and upper facade, not a repeated face-local motif.
- `docs/reference/wall-corruption-review-v2/selection.json` records the user's
  choice and selected PNG hashes. The corner in the original comparison shows
  D1 and is historical; do not use it as the selected D2 appearance reference.
- D2 appearance is approved. Full context-family propagation and Godot asset
  integration have not been performed by this selection record.

## Corrupted wall D rejected; continuous mapping proposal — 2026-10-23

- User rejected D because its motif repeats identically. Root cause: same
  material ID but face-local UV origin/scale, duplicating the violet centre
  on the top and upper facade. Sharing a material ID alone is insufficient.
- `tools/prepare_wall_corruption_review.cjs` produces a separate review under
  `docs/reference/wall-corruption-review-v2/`. D1 unwraps the existing patch
  continuously around one stone; D2 uses a different vein from the same atlas.
  A twelve-cell assembly shows D1/D2 sparsely among A/B/C. No new generation.
- One unfolded material rectangle maps top and upper facade, with identical
  UV along their common physical edge. Keep per-face lighting and fixed joints.
  The renderer's optional `face.textureTransform` is used only by this review;
  normal production export mapping remains unchanged unless opted in later.
- Four straight sprites, NW corner and magenta overlays are pending approval.
  No Godot catalog or asset replacement. Connection stones retain quiet common
  paint. Source before-images/recipe are frozen; previous D is rejected history.
  Do not interpret this correction as approval of the complete wall family.

## Wall variation appearance review — 2026-10-23

- User now asks to reduce wall repetition and create variants. Proposal:
  `docs/reference/wall-variation-review/`, reproduced by
  `tools/prepare_wall_variants_review.cjs`. Four complementary variants:
  A calm, B weathered, C chipped, D localized violet corruption.
- Eight prepared straight-wall PNGs (four horizontal, four vertical), mixed
  assemblies and a NW corner with magenta overlay. This is an appearance
  review awaiting approval, not an active Godot material/catalog replacement.
- Existing generated `proposals/variation-review/atlas-calm.png` supplies the
  shared paint. Three exact crops under the review's `materials/` keep quiet
  boundary stones and make chip/violet details visible on narrow wall faces.
  Crop recipes, hashes and tool inputs are recorded in `recipe.json`.
- Paint complete stones through the existing local context exporter. Stones
  touching a longitudinal cell boundary, including endpoints/filter guards,
  retain common quiet paint across all variants. Only interior stones vary.
  Top and upper facade share a material; no rotation, joint or alpha changes.
- The procedural violet Y stroke is disabled in this proposal. Preserve the
  active smooth rounded floor, wall finish B, projection and existing layouts.
  Frozen baselines and material catalogs under `source/` must not be replaced
  after promotion. No arbitrary corner/door/stair variant compatibility claim.
- Export audits report matching construction alpha and guide layers for the
  eight straight sprites and NW proposal. Horizontal, vertical, NW overlay and
  enlarged B/A join reviewed visually; no automated tests or Godot changes.

## Approved smooth rounded floor integration — 2026-10-23

- User answered "Oui" to integrating the smooth floor with rounded slab corners
  in Godot. This supersedes the proposal-only floor gates below; the proposed
  varied wall family remains a separate review.
- Active recipe: shared-materials/active-recipe.json. Exact accepted atlas copied
  unchanged to shared-materials/floor-smooth-atlas-v1.png. Four existing floor IDs
  select samples 6/2/4/3 from the eight-source atlas. They cover four complete
  periodic C stones; both boundary fragments share one ID. Legacy names such as
  floors-fine-crack are compatibility IDs, not descriptions of the new surface.
- floor.opacity=.55. Active recipe floorFinish has radius 10.5 and floorFactor
  .63; it applies only to ground slabs. Walls and stair tread rounding retain B.
  Stairs use the smooth palette through the existing shared floor material IDs.
  Dimensions, construction guides, alpha, anchors and layouts remain fixed.
- Production exporters explicitly pass floorFinish and floorPattern to models.
  Historical material reviews keep their explicit old recipes/default B finish.
  Reproduce with prepare_shared_stone_materials.cjs, export_painted_image_catalog.cjs
  and export_painted_connected_kit.cjs --specials-only (also refreshes shared floor),
  then Godot import. Special contexts need re-export because they contain stairs.
- Partial context exports preserve ordinary structures' sourceHashes and record
  updated specialSourceHashes; floor.sourceHashes remains separate. Godot still
  places prepared PNGs. No new runtime variation system or wall promotion here.

- Completed: 57 isolated images / 146 aliases; connected 737 images / 1444
  contexts. Godot import and five scene captures exit 0, stderr empty. Normal
  views inspected; no automated tests. Logs: artifacts/smooth-rounded-*.log.
  Isolated review sheets now use the same atomic writer as sprites to avoid
  truncating a Windows-locked PNG. Source review found no Important/Critical
  issues in the floor propagation. Existing editor refresh still requires the
  inspector button or F6 after import.

## Smooth rounded floor review history — 2026-10-23

- User accepted the smoother floor direction and requested rounded slab corners
  like the mockup. Keep its eight smooth samples and low contrast (.55 opacity).
- `tools/prepare_rounded_smooth_floor_c_review.cjs` prepares a floor-only finish
  proposal: radius 10.5 reference pixels, multiplied by the existing .63 floor
  factor (about 6.6 px at 256 px/cell). Inset, bevel width, material IDs and seeds
  stay fixed. Walls retain B; the active stone-finish.json is not changed.
- Outputs in material-variation-review/: `rounded-smooth-floor-detail.png`,
  `rounded-smooth-floor-comparison.png`, `rounded-smooth-c-comparison.png` with
  magenta overlay, and `rounded-smooth-floor-recipe.json`. The previous smooth
  images are frozen in source/*-before-rounding.png.
- The shared compositor accepts an optional model.floorFinish, recorded in the
  report. Production exports without this option retain their existing finish.
  Whole floor stones are rounded before framing; connection cuts must not gain
  a corner or bevel. Review images are not runtime assets. Corner rounding still
  awaits visual approval before propagation; no Godot scene change at this stage.

## Smoother floor material proposal — 2026-10-23

- User wants smoother, quieter floor surfaces like the original mockup so future
  objects remain distinguishable. Keep large slab C geometry and finish B.
- `tools/prepare_smooth_floor_c_review.cjs` revises only the proposed floor
  materials, keeping the proposed walls from `appearance-c-recipe.json`.
  Source: `shared-materials/proposals/variation-review/floor-smooth-v1.png`, eight
  generated smooth slate samples without large chips, holes or cracks. Floor
  texture opacity .55 softens contrast; all other floor profile values stay fixed.
- Review: `material-variation-review/smooth-floor-comparison.png` and
  `smooth-c-comparison.png` (NW corner with magenta overlay). Exact prompt,
  references and original path: `smooth-floor-generation.json`; complete material
  recipe: `smooth-floor-recipe.json`. Previous proposal PNGs are frozen in source/.
- This supersedes the scarred floor samples in the pending material proposal,
  not the active production family. No Godot propagation before appearance review.
  The corner retains 38 guide segments and matching construction alpha with no
  interior holes. This is not a gameplay legibility test or arbitrary join proof.

## Approved large floor C; material variety pending — 2026-10-23

- User dislikes the small violet branching stroke, repeated wall motifs and
  repetitive floor. Latest steering identifies floor slabs as too small versus
  the original mockup. User approved option C: "oui le C".
- Proposal: `docs/reference/material-variation-review/floor-size-comparison.png`
  compares 6 / 3 / 2 decorative rows per logical cell over the same 3x3 area.
  All three use the same proposed materials and finish B. The logical grid stays
  1x1. C is now active in `floor-periodic-cell.json`: row heights [2.5,2.5]
  and widths [[1.15,3.05,1.8],[2.3,3.15,.55]] in the normalized 6x5 frame.
  Two rows, six fragments, four complete periodic stones; full widths .475..525
  cells. The connected floor has six source segments and keeps its opaque frame.
- `tools/prepare_material_variation_review.cjs` reproduces the appearance study;
  `--floor-sizes-only` renders the size comparison alone. Whole stones crossing
  cell borders are painted before framing. The previews are not production room
  sprites or proof of arbitrary prepared tile compatibility. Frozen pre-C floor
  source/PNG live under the review's source/ directory for reproduction.
- Proposed source `shared-materials/proposals/variation-review/atlas-calm.png`
  has 8 wall and 8 floor samples. Earlier atlas.png is an overly rough intermediate.
  Generation provenance and prompts are beside the review. This new material
  family is not promoted by the C slab-size decision. Active materials remain
  the approved stylized family; all scenes receive the prepared large floor.
  Isolated PNGs and transparent guides are re-exported with C too. Connected
  structures contain no ground and stay unchanged; --floor-only preserves them.
  Floor input hashes are stored under catalog.floor.sourceHashes, leaving the
  retained structures' original provenance intact. The optional `drawAccent:false`
  renderer flag suppresses the purple doodle in proposals only.

- Latest material proposal after C: `corner-c-comparison.png` in the same review
  directory shows the NW corner before/after and its magenta overlay (38 source
  segments). `appearance-c-comparison.png` compares a six-cell wall and a 3x3 C
  floor field with 8 proposed wall / 8 floor materials. Floors favor calm samples;
  violet lives in rare painted crevices, with no added branch stroke.
  Reproduce with `node tools/prepare_material_variety_c_review.cjs`.
  The corner is a deliberately composed palette sample; field assignment uses
  whole stone identities. Both are appearance proposals, NOT a prepared runtime
  variant catalogue. Active textures remain unchanged pending this visual review.
  `appearance-c-recipe.json` stores inputs, profiles and export reports. The NW
  report records zero missing interior pixels and matching construction alpha;
  this does not prove arbitrary future tile joins. Baseline PNGs are frozen in
  the review's source/ directory so future regeneration retains the comparison.

## Approved wall join correction — 2026-10-23

- User found texture seams inside stones spanning cells after B. Root cause:
  fragment-local material IDs, UV framing and finish gradients. Floor wrapping
  did not cover walls; unchanged alpha alone did not prove texture continuity.
- User approved the enlarged horizontal/vertical comparison and requested
  generalization to the kit and Godot. Preserve the approved material crops,
  B finish, projection, wall geometry and scene layouts.
  `tools/prepare_wall_join_review.cjs` produces `docs/reference/wall-join-review/`;
  `tools/capture_wall_join_review.gd` captures its separate PNGs in Godot at 1x/2x.
- The proposal paints whole stones in a shared geometric context, then exports
  cell sprites. A single union mask and identical interior edge pixels prevent
  alpha/filter seams. See the review README for alpha changes and exact scope.
- Production export now uses reusable local contexts and stable stone identities
  in `tools/connected_stone_context.cjs`. The connected export selects complete
  face regions across the neighbour guides before painting/cutting cell PNGs.
  Material, UV, finish seed and accents must not depend on a fragment's bounds
  or the order of faces. Never bake a scene-sized production image.
- The baseline PNGs of the accepted comparison are frozen under
  `docs/reference/wall-join-review/source/` from ab9ebe7. Do not replace them
  with the promoted assets when reproducing the before/after comparison.
- Godot selects a prepared local-context PNG, with existing anchors and scale.
  Context paths load on demand; do not preload the entire context family into
  VRAM. Keep the floor image shared. Local special-neighbour configurations are
  inventoried by `tools/export_painted_scene_contexts.gd` before PNG export.
- Combined special contexts must also hide source lines behind neighbouring
  volumes before finding stone faces. ReferenceCalibration exposed stair lines
  painting across an arch; compare source depth against the combined model.
  Preserve the generic fallback warning for new, unexported special contexts.

## Approved soft stone B — 2026-10-23

- User approved B: "ok pour B". Apply its modest rounding to existing isolated
  and connected stone sprites with the accepted offline material-mask workflow.
- Durable recipe: `assets/dungeon/shared-materials/stone-finish.json`.
  Radius 3.8, inset .55, unevenness .12, bevel 2.2 reference pixels; floor factor
  .63 and proportional reduction for narrow faces. Do not replace this with C.
- `tools/stone_edge_finish.cjs` is shared by the production compositor. Retain
  source material crops, projection, silhouette alpha, grid and scene layouts.
  Wood/metal retain their finish. Godot places complete prepared PNGs as before.
- Periodic floor boundary fragments share one complete stone, texture mapping
  and finish seed. Uninked connection cuts receive no new inset, rounded corner
  or end bevel. Internal stone joint appearance changes intentionally; the
  construction overlay is a geometry reference, not every visible mortar pixel.
- `docs/reference/stone-edge-review/` preserves the A/B/C decision. Its generator
  now reads frozen A/report/guide/material metadata, never the promoted active B
  as a new baseline. Keep the accepted B image for comparison.
- After changing the finish, re-export BOTH kits and import in Godot. Existing
  scene references pick up the resulting PNGs. Record visual review limits in
  `docs/reference/PAINTED_GODOT.md`; approval of B does not prove arbitrary joins.

## Legacy asset cleanup — 2026-10-23

- User requested removal of failed architecture trials predating the wireframes.
  `alpha-kit`, old `entrances`, `modular-study`, `reference-study`,
  `single-cell-study`, loose original crop PNGs and three rejected gloom corners
  are retired. Their exclusive renderers, capture scripts and obsolete checks
  have been removed from the active tree too. Do not restore them from the
  historical instructions below.
- Active assets: `painted-connected`, `painted-cells`, `shared-materials` and
  the three `wireframe-*` directories. Keep accepted geometry sources and mask
  metadata, including `docs/reference/nw-material-review-v2/validation.json`.
- The unchanged native-alpha heart is now `assets/dungeon/heart/heart.png`;
  `alpha_heart.gd` loads it directly with the same region, scale and anchor.
  Keep the separate heart/torch scenes and original user mockups.
- Current commands: `README.md`, `assets/dungeon/README.md`, `PAINTED_GODOT.md`.
  `tools/test-mobile.ps1` and its pre-wireframe checks are retired; they are not
  valid checks for the current kit. Do not run/add tests without a user request.
- `docs/cleanup/2026-10-23-pre-wireframe.json` inventories the removed paths,
  hashes and recovery commit. Files are also retained in the ignored local
  `artifacts/pre-wireframe-archive-2026-10-23/`, excluded from Godot by .gdignore.
  The preexisting modified alpha-kit provenance is preserved byte-for-byte in
  `docs/cleanup/alpha-kit-generation-before-cleanup.json`. Older prose referring
  to retired paths is historical, not an active dependency.

## Approved active stylized family — 2026-10-23

- User approved the latest stylized preview: "oui utilise cette nouvelle gamme
  de texture". Apply its exact materials to all existing painted assets and Godot
  scenes. This supersedes the earlier proposal-only gates below.
- Active material recipe: `assets/dungeon/shared-materials/active-recipe.json`.
  Source: `stylized-atlas-v2.png`; exact reference: `stylized-reference.png`.
  `tools/prepare_shared_stone_materials.cjs` now reproduces these approved crops
  and profiles by default, checking their hashes. It must not restore old textures.
- Keep existing material IDs. Four wall variants use plain/corrupted painted
  stone; four floor variants use calm painted stone; wood is simplified. Iron is
  retained from the approved preview. Older realistic sources are historical only.
- Re-export isolated and connected kits after preparation. Preserve geometry,
  alpha, joints, floor periodicity, anchors, scale and scene layouts. Godot still
  places whole prepared PNGs; no generation or color correction at runtime.
- Editor preview refresh: `wireframe_cell_study.gd` keeps its computed Callable
  button and reloads used imported textures with `CACHE_MODE_REPLACE`, once per
  unique path, on manual refresh / scene entry. Parameter-only rebuilds and runtime
  retain normal preloads. After external PNG exports, finish import before clicking
  "Actualiser le rendu"; a second Godot import process cannot refresh the memory of
  the user's already-open editor. Do not restart that editor or discard its edits.

## Current style correction — 2026-10-23

- User finds the A/B/C corruption materials too realistic compared with the
  original mockup. Do not use their grain, pits or bark as style references.
  Prefer broad painted facets, a few deliberate scars, simplified wood grain
  and localized violet accents. Keep the approved masks, joints and projection.
- `docs/reference/stylized-material-review/` contains a new NW corner and north
  door proposal, overlays, comparison, recipe, prompt and the exact user reference.
  Its generated atlas is `assets/dungeon/shared-materials/proposals/stylized/atlas.png`.
  Reproduce with `node tools/prepare_stylized_material_review.cjs`.
  This preview is now approved and promoted to the active family described above.

## Pending corrupted material directions — 2026-10-23

- User finds ALL current materials too smooth/clean and asks for multiple evil,
  corrupted dungeon texture proposals. This broadens the earlier door-only review.
- Three generated material atlases: damp eroded crypt, cursed violet fissures,
  and embedded black roots. Sources: `assets/dungeon/shared-materials/proposals/corruption/`.
  Exact prompts and original outputs: `docs/reference/corruption-material-review/generation.json`.
- `tools/prepare_corruption_material_review.cjs --variant=01-humide` (or
  `02-fissures`, `03-racines`) exports one direction in a separate process.
  Run without arguments to rebuild `comparison.png` with current art + A/B/C.
  Each uses the same NW cell and north door geometry; masks/joints stay fixed.
  Different rectangular crops supply variation without mirroring or rotating art.
- These are unapproved appearance proposals only, with magenta overlays and
  recipes. Active Godot assets/material catalogs remain unchanged. A production
  library would need further variation and deliberate sparse corruption placement;
  these samples do not validate connected roots or glowing veins across modules.

## Pending door material review — 2026-10-23

- User reports that door textures do not integrate with the dungeon. The current
  oak is very orange with high-contrast grain. A muted aged grey-brown oak proposal
  is saved in `assets/dungeon/shared-materials/proposals/door-oak-v2.png`.
- `tools/prepare_door_material_review.cjs` applies it to all four existing door
  masks and produces `docs/reference/door-material-review-v2/comparison.png`,
  individual PNGs, magenta overlays and a reproducible recipe. Geometry, stone,
  floor and iron materials stay unchanged. This is an appearance proposal awaiting
  user review; active Godot assets and catalogs have NOT been replaced.

## Previous floor rhythm correction — superseded by C above

- User reports columns of long slabs caused by the wireframe subdivision.
  Paving source `docs/reference/floor-periodic-cell.json` previously superseded
  the historic 19-fragment motif. That intermediate version had six row heights,
  26 fragments / 20 full periodic stones, full widths .24..40 cells, staggered cuts.
  Count the left+right fragments as ONE stone when assessing width; the old
  pattern joined them into stones up to .78 cells and repeated a long-stone band.
- Preserve 1x1 grid, projection, wall geometry, opaque connected floor frame and
  continuous material at X boundaries. Re-export source wireframes, overlays,
  isolated painted images and connected PNGs together after a floor joint change.

## Current request: painted Godot scenes — 2026-10-23

- User now explicitly requests updating all Godot scenes with the new assets.
  This supersedes the previous image-only/no-integration gate below.
- Export connected structural images OFFLINE from the existing connected
  wireframes and shared material library. Keep the isolated review images.
  Godot places prepared floor/structure PNGs at uniform .25 scale on the same
  256-pixel square grid; no runtime image generation or appearance repair.
- Preserve the current room layouts, branch lengths, two-cell-wide corridors
  in SixRoomPreview, four door orientations and entrance stairs.
- Update older architecture demonstration scenes too. The standalone torch and
  heart props have no replacements in this architecture catalogue.

- Integration is now implemented in `scripts/painted_cell_catalog.gd` and the
  shared `wireframe_cell_study.gd`. All 20 architecture scenes use painted PNGs.
  `tools/export_painted_connected_kit.cjs` exports 96 unique structural PNGs,
  128 structural IDs, 16 empty states and one connected floor (26 revised joints).
  The three standalone floor closing contours must not become cell-grid borders.
- Connected floor boundary fragments must share ONE full stone across X=0/1,
  with the same material, UV coordinates and bevel seed. `wrapFloorX` in the
  offline compositor expands those fragments before clipping to the fixed cell.
  Removing only the outline leaves vertical bevel/texture seams (user-reported).
  Never shade an artificial cell boundary as a physical stone edge.
- Connected floor export is now an opaque 1024x1024 exact-cell frame, anchor
  (0,0), still displayed at .25 scale. Transparent floor gutters caused a second
  dark filtering seam even with continuous RGB. Repeat the next row's north
  joint into the bottom edge offline, retaining full joint width. Structural
  and isolated-review frames remain unchanged. See outputFrame/repeatInkY.
- See `docs/reference/PAINTED_GODOT.md` for scene inventory, export/import and
  capture commands. Connected doors/stairs omit the ground layer; every grid cell
  receives the same prepared floor before its structure. Isolated review sprites
  remain complete and are used only by EntranceVariants and the review boards.

## Previous request: remaining painted images — 2026-10-23

- User: "Ok tu peux faire les autres images ?" authorizes propagating the
  shared-material approach to the existing isolated wireframe image catalogue.
  This supersedes the NW-only propagation gate below. Prepare ordinary cells,
  floor, isolated pillar, four entrances and four double-sided doors for review.
- Reuse the approved slate material library and fixed projection. Add shared
  wood/metal materials for door leaves/hardware, based on the canonical mockup.
  Keep all source guide lines, framing, end faces and hidden-line visibility.
- Deliver PNGs, catalog/provenance and overview/overlay images. This request is
  for images; it does not request replacing the Godot scenes or their connected
  textures. Standalone end-face guides are not connected-runtime assets.
- Exporter: `tools/export_painted_image_catalog.cjs`, shared compositor:
  `tools/painted_material_renderer.cjs`. Output: `assets/dungeon/painted-cells/`,
  57 unique PNGs covering 146 isolated guide identifiers through catalog aliases.
  Includes 47 cell configurations, floor, pillar, four stairs and four doors.
  Review boards, magenta overlays and measurements: `docs/reference/painted-kit-review/`.
- Source lines and widths are copied unchanged. Independently projected volume
  alpha is checked against the exported PNG. Open uninked floor edges close
  MATERIAL masks only. Doors additionally use source-volume visibility masks
  so adjacent stone and wood never inherit each other's material across a
  missing inked intersection. Wood grain is projected from local leaf coordinates.
- Common wood/iron sources join the eight existing stone materials. Keep all
  material settings in `shared-materials/catalog.json` via its preparation script.
  Final artistic approval and connected-scene conversion remain separate work.

## Approved method: shared generated materials on fixed geometry — 2026-10-23

- The user approved retaining the masked-material method after the first test:
  "c'est une bonne méthode donc on peut l'autoriser". They explicitly want it
  preserved so all elements reuse the SAME textures. The one-time restriction
  in the historical section below is superseded for this method.
- Architecture may now be composed OFFLINE from shared AI-generated material
  swatches, clipped to approved wireframe faces. Geometry defines silhouettes,
  joints, anchors and projection. The output is a prepared PNG; Godot places it.
  This supersedes the older native-alpha/no-masks rules for this workflow only.
  Do not use generative painting to reposition joints or freely repair geometry.
- The first masked image is visually too simple. Current work enriches the
  shared material library with several coherent variants, following the canonical
  mockup: darker slate, painterly facets, sparse wear and violet accents. Floors
  must remain calmer than walls. Avoid unrelated color palettes per orientation.
- Validate the richer materials on the SAME NW corner before propagating the
  painted kit or updating scenes. Approval of the method is not approval of the
  current appearance or permission to skip overlay checks.
- Read `docs/reference/MATERIAL_WORKFLOW.md`. The pending library contains four
  wall and four floor materials in `assets/dungeon/shared-materials/`, with a
  shared renderProfile in catalog.json. `--materials-v2` on the NW prototype
  uses it and exports `nw-shared-materials-v2.png`; comparison and per-face
  material IDs are in `docs/reference/nw-material-review-v2/`. Never regenerate
  or tune materials independently per orientation. The general isolated exporter
  is now described above; no painted runtime integration exists yet.

## Historical one-time masked-material experiment — 2026-10-23

- The user explicitly authorized testing vector masks **for this time only**,
  on the single painted NW corner under review. This is a narrow exception to
  the native-alpha/no-programmatic-repair rules, not a general policy change.
- Scope: generate joint-free stone material from the canonical mockup, compose
  it offline inside the exact approved faces, and draw joints from the unchanged
  wireframe. Export one transparent review sprite and its magenta comparison.
  Do not integrate it into Godot or extend the technique to other variants.
- Preserve all generated originals and geometry. Record the source material,
  masks, composition script and validation. No other painted sprite is approved.
- This experiment has now been produced: `nw-masked-experiment.png`, with
  sources/review in `docs/reference/nw-mask-test/` and the deliberately NW-only
  `tools/prototype_nw_masked_material.cjs`. Its 51 guide segments are copied
  unchanged; decoded alpha matches the construction raster exactly. The result
  is more regular than the mockup and awaits artistic review. The one-time
  authorization does NOT permit more variants or scene integration.

## One painted NW corner under review — 2026-10-23

- The user explicitly requested ONE painted NW corner from the wireframe, with
  transparent magenta overlay validation. See docs/reference/painted-corner-review/
  for the exact prompts, generation.json, measurements and comparison images.
  No Godot integration or generation of the rest of the painted kit is approved.
- nw-cell-wireframe-v1.png was rejected for a false extra TOP course: its top
  planes looked like separate coping slabs. The top and upper-front faces must
  belong to the SAME stone; only two equal facade courses, no under-cap strip,
  added lip or overhang. The user's criticism was NOT about the narrow floor
  band at the wall foot; the assistant initially misidentified it.
- v2/v3 reduce the detached-cap effect but remain UNAPPROVED. The first top-face
  joint along the west wall is still too low (about y350 instead of y322 at
  1166x1349). Do not claim exact fidelity from silhouette overlap: v3 is 99.32%
  IoU yet has this visible internal mismatch. Preserve the source geometry.
- v4 restarts from the exact construction drawing, with the canonical mockup
  as material-only input. It also FAILS review: the floor strip at the north
  wall foot becomes a dark projecting facade, its joints move, and facade
  shading reads as horizontal slabs. Exterior contours still differ. Do not
  use any of v1-v4 as approved geometry, material or runtime images.
- The user requires exact contours AND joints to prevent connection defects.
  Free image generation has not met that requirement. A deterministic offline
  material composition inside fixed vector faces now has a ONE-TIME test
  authorization in the section above. The general prohibition remains in force
  for every other asset and for any further use outside this experiment.
- Built-in image_gen supplied native-alpha images, copied unchanged into
  assets/dungeon/gloom-kit/proposals/nw-cell-wireframe-v{1,2,3,4}.png. Review PNGs
  are separate, never runtime assets. Use tools/review_nw_corner_image.cjs with
  the image, version tag and requested WIDTHxHEIGHT; uniform whole-canvas scale,
  fixed origin, no fitted translation, clipping or repair of painted pixels.

## Transparent wireframe control guides — 2026-10-23

- The user wants transparent guides with conspicuous colored lines to overlay
  future painted sprites and compare geometry. The initial export uses magenta
  #ff00ff (assistant choice), keeping projection, framing, anchors and widths.
- IMPORTANT correction: review each piece ALONE with all VISIBLE end contours.
  Do not omit port/end faces as in the connected kit; do not reveal hidden edges.
  The user supplied the standalone south door as the explicit visual reference.
- `tools/export_wireframe_overlays.cjs --png` prepares 146 SVG/RGBA PNG guides
  in `docs/reference/wireframe-overlays/`: 136 complete cell variants, one floor,
  four entrances, four doors and one isolated pillar. PNG export needs sharp.
  Read its README and WIREFRAME_WORKFLOW.md section 12 before using/regenerating.
- Preserve existing white construction sources. The common cell geometry has
  an offline standalone mode retaining end faces; its runtime export is unchanged.
  Doors use the isolated studies' visibleEdges exactly; stairs use complete
  source edges with world rotation and fixed-camera visibility. Floor strokes
  are trimmed against vector faces before omitting fills. No painted pixel cleanup.
- Individual PNGs have transparent backgrounds; comparison.png alone includes
  a checkerboard. Complete ordinary guides use wall framing (304x352, anchor
  24,88), while the standalone floor keeps 264x264, anchor 4,4. Doors keep their
  taller 304x392 frame, anchor 24,128. Never auto-crop or shift guides to hide errors.
- The isolated pillar is T x T x H (1/6, 1/6, 1.88/6), one joint at .94/6,
  no floor or vertical joints; 96x144 canvas, anchor 24,88, same 256 px/cell scale.
  The user does not need a separate painted "floor + two pillars" asset; that
  composition reuses floor + pillar. Remove it from the production review sheet,
  preserve the technical catalogue variant. 146 guides are not 146 art commissions.
- These are ISOLATED review guides, not a Godot overlay mode or replacement for
  connected textures. Existing scenes and runtime
  textures remain unchanged by this export; no painted generation is authorized
  by a transparent-guide request alone.

## Six-room wireframe scene — 2026-10-23

- Latest user request migrates `scenes/SixRoomPreview.tscn` to the existing
  wireframe catalogue, replaces the entry door with stairs, and removes torches
  and the heart for visual review. The legacy probe overlay is also detached.
- Explicit width correction: KEEP THE ORIGINAL TWO-CELL-WIDE CORRIDORS.
  The user wants to inspect these joins and considers this a valid option for
  the future player-built dungeon. A cell remains square 1x1; corridor width
  may span several cells. Earlier one-cell studies remain valid examples,
  not a universal width restriction. No player construction editor exists yet.
- `assets/layouts/six_rooms_wireframe.tres` preserves all 255 occupied cells
  of `six_rooms.tres`, their locations and values, and adds only (3,2), just
  north of the old entry, for one south-opening stair. Grid 28x18, total 256.
  The original layout remains historical. The shared wireframe renderer uses
  pitch 256 and its normal occupancy/diagonal selection, without custom joins.
- `entrance_at_closed_ends=true` selects exactly one existing complete stair
  image (w11_p00_e00). No newly generated art or runtime geometry is introduced.
  F5 is unchanged; open SixRoomPreview and F6 for the current imported textures.
- Full/2x captures: `tools/capture_wireframe_cells.gd -- SixRoomPreview`.
  Entry and wide-connection details: `tools/capture_six_room_wireframe.gd`.
  Older stone-specific capture/probe helpers do not describe this migrated scene.

## Door cell wireframe review — 2026-10-23

- Latest user request authorizes GODOT INTEGRATION in a NEW PLUS-SHAPED SCENE.
  `scenes/WireframeDoorCross.tscn` uses the shared renderer: single-cell centre,
  four branches of length 3, closed ends, 13 cells. Door cells are (0,-2) north,
  (2,0) east, (0,2) south and (-2,0) west; direction names still mean front normal.
  `door_cells` is an exported cell-to-direction dictionary, empty by default.
  Only connected straight variants w10_p00_e00 (N/S doors) or w05_p00_e00 (E/W)
  are supported. Invalid placements warn and retain ordinary cell images.
- `tools/export_wireframe_doors.cjs` prepares four COMPLETE SVGs (floor, walls,
  arch, leaf, both hardware faces) in `assets/dungeon/wireframe-doors/` and
  `scripts/wireframe_door_catalog.gd`. Shared pitch 256; door anchor (24,128),
  image 304x392, with a taller transparent gutter for lateral arches. Both
  contact end faces are internal; the north/west masonry seam is retained.
  Godot replaces the ordinary floor/wall pair with one whole door Sprite2D.
  No runtime geometry, rotation, clipping or tint. Mipmaps enabled for all four.
- Capture the actual scene with `tools/capture_wireframe_cells.gd -- WireframeDoorCross`
  and its four close-ups with `tools/capture_wireframe_doors.gd`. This is a
  static visual scene: opening, interaction, collision and navigation are absent.
  F5 stays unchanged; open the new scene and use F6.
- Current correction: the door is DOUBLE-SIDED. Both faces need plank seams,
  two bands and a handle. The west view must contain the same closed leaf as
  the east view. The previous front-only hardware and deeply recessed back
  were rejected. The source now authors both complete faces before rotation.
- Prepare the FOUR WIREFRAME ORIENTATIONS. Reproduce
  the source, then run `tools/export_arched_door_orientations.cjs`. Four files
  `docs/reference/door-arch-facing-{north,east,south,west}-wireframe.*` and
  `door-arch-four-orientations.*` show the same volume under one fixed camera.
  Direction names identify the FRONT normal: N(1-x,1-y,z), E(y,1-x,z),
  S identity, W(1-y,x,z), all transformed before the unchanged projection.
- Keep the floor pattern in world axes. Recompute visibility AND the apparent
  contour from each transformed camera ray; never rotate source visible edges
  or its camera-dependent silhouette. North/west expose the wood's rear face
  with its own hardware; both handles share the same physical x/z spindle.
  Keep real occlusion: in the west view the arch masks the near-side handle,
  while the leaf and its plank seams remain visible. East/west are near-profile
  views with this camera, not artificially front-facing door drawings.
- The four source variants were standalone visual proposals before the latest
  integration request above. The common framing fits
  all projected bounds; the original viewport would crop the lateral arch.
- Latest correction: the arch must SPRING DIRECTLY FROM THE LEFT/RIGHT WALLS.
  Remove the added jambs inside the passage. The existing walls carry the arch
  across their full thickness. Keep the selected arched door, no torches,
  square 1x1, WEST/EAST walls, NORTH/SOUTH open and door centered at y=.5.
- Read `docs/reference/DOOR_CELLS.md`. Current exporter:
  `tools/export_arched_door_cell_wireframe.cjs`; SVG/JSON/PNG proposal:
  `docs/reference/door-arch-cell-west-east-wireframe.*`. Exact dimensions await
  visual approval. The connected exporter above reuses this reviewed geometry.
- Preserve square 1x1, projection (x-.18*z, y-.9*z), side-wall thickness 1/6,
  height H=1.88/6 and joint .94/6. Arch depth/thickness 1/6, inner radius 1/3,
  outer radius .5, seven stones, starting at H. Its bearings are x=0..1/6
  and x=5/6..1, y=.41666667.. .58333333 on the existing wall tops. The arch
  top is .81333333. Door width is the full clear passage width 2/3.
  The single arched leaf has equal .025 recess on BOTH sides: local
  y=.44166667.. .55833333, thickness .11666667. This keeps the existing front
  face and brings the rear out of the deep frame. No raised threshold.
- Construction and visibility use extruded convex profiles, including the arch
  ring and the arched leaf. Do not use an opaque bounding box across the curved
  opening. Draw radial stone joints and the camera-tangent silhouette of the
  extrusion; omit tessellation edges. Floor remains the normalized 19-slab
  motif at z=0. No mirroring, widened footprint, flared base or new camera.
- The previous rectangular proposal (`export_door_cell_wireframe.cjs` and
  `door-cell-west-east-wireframe.*`) remains historical, not the selected shape.
  The first arched version's .075-wide inner jambs are also superseded.

## Entrance stair wireframe review — 2026-10-23

- Current user request authorizes the OTHER THREE DIRECTIONS AND GODOT
  INTEGRATION after the north-end assembly looked correct. The earlier
  review-only restriction below is historical and is superseded for this task.
- `tools/export_wireframe_entrances.cjs` reads the reviewed south-opening
  source and prepares four complete floor/walls/stair SVG textures in
  `assets/dungeon/wireframe-entrances/`. Names identify the OPEN/downhill side.
  World transforms are N(1-x,1-y,z), E(y,1-x,z), S(x,y,z), W(1-y,x,z);
  all then use the same projection. Never rotate or mirror a projected image.
- `wireframe_entrance_catalog.gd` maps w14/w13/w11/w07 p00/e00 to N/E/S/W
  openings. `entrance_at_closed_ends=false` is the shared renderer default;
  `WireframeClosedCorridors.tscn` enables it, showing four entrances in its
  existing 17 cells. Each entrance replaces BOTH ordinary floor and wall
  textures with one complete Sprite2D, at the same (24,88) anchor/256 pitch.
  The floor motif remains world-aligned. Other scenes retain their old defaults.
- Fills include only visible top/+X/+Y faces and omit open-port faces. Internal
  end-face edges are absent. Real north/west contacts retain the same cap and
  upper-course masonry joints as the shared wall kit (the +X/+Y cell owns them).
  Do not lose these legitimate joints by rotating the isolated source alone.
  No runtime clipping, tint, generated geometry or sprite repair is introduced.
- Import all four SVGs with mipmaps. Actual Godot captures:
  `tools/capture_wireframe_cells.gd -- WireframeClosedCorridors 2x2CellRoom`,
  and `tools/capture_wireframe_entrances.gd` for four enlarged end views.
  Integration is for visual review; navigation and entrance gameplay are absent.

- Historical first assembly request: put the proposed entrance in the PREVIOUS TEST IMAGE,
  replacing its north terminal cell. `room-north-entrance-wireframe.svg`,
  `-north.svg` and JSON retain the 17-cell square room and place the entrance
  at (1,-2,0), opening south into the existing corridor at (1,-1,0).
  `tools/export_entrance_room_wireframe.cjs` reproduces this assembly offline.
  Omit the entrance's ten end-face edges on the shared wall contacts; all
  twelve sampled contact points match exactly. Review full and north detail.
  The room's original global paving continues through the landing; the isolated
  entrance's local catalogue floor motif is not substituted into that global
  pattern. This is an image assembly review, not Godot scene integration or
  final artistic approval of the staircase.
- The user requested four dungeon entrance orientations, starting with stairs
  descending from image top to bottom, enclosed by north/west/east walls and
  open to the south. This was the first direction reviewed before integration.
- Read `docs/reference/ENTRANCE_STAIRS.md`. Source/export tool:
  `tools/export_entrance_stair_wireframe.cjs`; outputs:
  `docs/reference/entrance-stairs-open-south-wireframe.svg` and JSON.
  The PNG is a preview of that vector drawing, not a painted sprite.
- Keep the current square 1x1 cell, wall thickness 1/6, height 1.88/6,
  joint .94/6 and common projection (x-.18*z, y-.9*z). The proposed five
  treads descend from z=.25 to the floor with .05 risers, across y=1/6..0.84.
  Stair width is 2/3; the remaining south landing is at z=0.
  These dimensions are retained for the authorized four-direction review.
- Visibility uses the combined wall AND stair volumes. Do not overlay an
  existing complete wall sprite above the staircase: that would incorrectly
  cover stair surfaces in front of the north wall. Prepare complete imagery
  offline. The current request authorizes the scene and catalogue update above.
- Future directions must be constructed in world coordinates with the SAME
  projection. Never rotate or mirror the projected drawing. No flared base.

## Active Godot integration — 2026-10-23

- Before changing or regenerating wireframes, read
  `docs/reference/WIREFRAME_WORKFLOW.md`. It records source files, construction
  logic, masks, piers, shared projection, anchors, offline export and review.
- The user explicitly authorized replacing the modular study rendering with the
  wireframe cells, and chose WIREFRAMES FIRST before painted sprites. The older
  review-only restrictions below describe previous stages, not a current ban
  on this integration. Artistic acceptance of the imported kit is still pending.
- Godot must NOT generate images, paving, wall geometry or masonry at runtime.
  `scripts/wireframe_cell_study.gd` only selects complete pre-imported textures
  and places Sprite2D nodes on an integer square grid. Ordinary cells use one
  floor image and at most one wall image; entrances and doors use one complete image.
  No stone fitting, clipping, mirroring or tinting.
- `assets/dungeon/wireframe-cells/` is a prepared SVG image catalogue, explicitly
  preloaded by `wireframe_cell_catalog.gd`. It has 136 wall records including
  blank states, covering the 16 cardinal combinations, concave pier combinations
  and exposed open ends. `wireframe_cell_layout.gd` reads cardinal and diagonal
  occupancy; pier geometry is ALREADY in the selected image, not drawn in Godot.
- `tools/export_wireframe_cell_kit.cjs` is an OFFLINE vector preparation tool.
  It is never invoked by Godot. Projection and wall dimensions come from the
  `after` model of `two-course-square-room.json`: true 1x1 grid, thickness 1/6,
  height 1.88/6, single joint at .94/6, height-up (-.18,-.9). The SVGs use neutral
  filled faces to hide rear lines; this is a geometry prototype, not painted art.
- The provisional invented paving pattern was withdrawn after user clarification.
  `floor.svg` uses the EXISTING 19-slab motif of `floor-only-cell-wireframe.json`,
  normalized from its historical 6x5 drawing bounds to a square image. This
  repeated cell motif is distinct from the earlier global whole-room paving.
  Never silently redesign that motif or claim the global study is pixel-identical.
- All 13 existing modular study/alias scenes now reference the new renderer.
  Dimensions, open endpoints and attachment settings are preserved. The explicit
  `WireframeClosedCorridors.tscn` example has a 3x3 room plus four length-two
  closed branches: 17 cells, eight junction piers. F6 opens this example.
  F5 still points to `5x5RoomVerticalCornerCorridors.tscn` in project.godot.
  SixRoomPreview now also uses this renderer; see the latest six-room section.
- Keep the computed refresh_action Callable getter. SVG files are imported as
  textures with mipmaps, including in editor previews. Use linear mipmap
  filtering to avoid disappearing wireframe strokes when the map is reduced.
  Floors and walls are separate layers;
  hero occlusion/ysorting, collision and navigation are NOT implemented by this.
- Human-review captures: `tools/capture_wireframe_cells.gd`, artifacts named
  `wireframe-<scene>.png` and `-2x.png`. The older stone-specific capture helpers
  target legacy renderer diagnostics; use the new helper for these studies.

## Current user review gate — 2026-10-23

- Latest grid constraint: cells must remain SQUARE 1 x 1 units so the dungeon
  can be assembled on a regular grid. The proposed 6 x 7.5 rectangular-cell
  comparison was explicitly rejected before any geometry changes were made.
  Do not adopt that proposal or treat the earlier 6 x 5 drawing dimensions as
  approval of rectangular logical cells. The user clarified that corridors must
  remain ONE CELL wide and authorized revising visible wall height. They then
  specifically requested removing the thin masonry level from every wall.
- Current requested study: SQUARE GRID WITH TWO WALL COURSES.
  `docs/reference/two-course-square-room.svg`, directional detail SVGs, JSON
  and `two-course-square-corridor-{before,after}.svg` use true 1 x 1 cells.
  Keep ground X/Y screen-aligned and height-up (-0.18,-0.9). Thickness is 1/6
  of a cell, using the former six-unit horizontal width as the common scale.
  Both comparison models share this square plan, paving, wall thickness and
  framing; the reference is a square reconstruction, not the old 6 x 5 image.
  Remove the former 0.32/6 thin top band: height drops from 2.2/6 to 1.88/6,
  leaving TWO equal 0.94/6 courses and one horizontal joint. Top-stone joints
  continue through the upper course. All wall orientations and all eight piers
  use the same height; piers retain horizontal joints only. The 17-module
  room keeps four closed corridors, each one cell wide. Eight terminal-wall
  interfaces remain internal (80 source edges omitted, vs 96 with the thin band).
  The horizontal visible floor band grows from 0.336667 to 0.384667 cell,
  approximately 14.3%, on the shared square plan. This is a modest gain, not
  proof of gameplay readability. The blue character is an indicative scale
  guide (height .30, width .18 cell), near the foreground wall at local y=.64;
  dashed portions are occluded. No production hero scale is approved by it.
  The default view shows the full room without the thin band. This remains a
  wireframe review proposal, without Godot or painted-asset changes.
- Previous requested variants: FOUR THREE-WALL CELLS, ONE OPEN SIDE EACH.
  `docs/reference/three-wall-cell-open-{north,east,south,west}.svg` and JSON
  define U-shaped prisms in the shared 6 x 5 cell, height 2.2, thickness 1.
  The suffix names the OPEN side. Floors: north [1,0,5,4], east [1,1,6,4],
  south [1,1,5,5], west [0,1,5,4], all z=0. Each variant retains the shared
  projection, course levels and masonry spacing; never rotate/mirror its
  projected drawing. The isolated floor rows retain the shared slab joints,
  trimmed at wall feet. Foreground-wall occlusion is intentional.
  `room-closed-corridors-wireframe.svg` and four directional detail views append
  one terminal cell to EACH existing corridor, giving 17 modules total. The
  opening faces the room: N-open at (6,20), S-open at (6,-10), E-open at (-12,5),
  W-open at (24,5). Eight full wall-end interfaces become internal (96 source
  edges omitted). Continuous wall runs and paving span those interfaces.
  The eight original square junction piers remain unchanged, with horizontal
  joints only. The assembled floor contains 170 slabs in 33 rows. Overall
  ground bounds are x=-12..30, y=-10..25. These are line-only review proposals,
  without Godot integration or painted-asset changes. The preceding open-ended
  room study is preserved separately.
- Previous requested assembly: 3 x 3 ROOM WITH FOUR CENTERED CORRIDORS.
  `docs/reference/room-four-corridors-wireframe.svg` and its north/east/south/west
  detail SVGs/JSON extend the previous south-corridor study with three branches.
  The 13 modules are the nine room cells plus west/east north-south-wall cells
  at (-6,5) and (18,5), and north/south west-east-wall cells at (6,-5)/(6,15).
  The four room edge-center cells have floor only. Eight identical 1 x 1 x 2.2
  piers bridge full faces: (6,0), (11,0), (0,5), (0,9), (17,5), (17,9),
  (6,14), (11,14). Piers retain horizontal joints only. All far ends are open;
  clear widths are 4 north/south and 3 west/east, from the shared 6 x 5 cell.
  The 142 slabs occupy 25 continuous rows. Room rows at y=6..9 extend across
  both horizontal corridors without cell-border seams. Preserve projection,
  wall height/thickness, masonry courses and staggered joints. This is a
  line-only review proposal, without Godot or painted-asset changes.
- Previous requested variant: ONE CELL WITH NORTH AND SOUTH WALLS ONLY.
  `docs/reference/north-south-cell-wireframe.svg` and construction SVG/JSON
  use two separate prisms at x=0..6, y=0..1 and y=4..5, height 2.2,
  thickness 1. Floor: x=0..6, y=1..4, z=0, nine staggered slabs in three
  rows of heights 1, 1.1 and 0.9. West/east remain open. Preserve the common
  projection and the recent masonry divisions (1.9 spacing, phases 0.7/1.65,
  cap joints continued down to z=1.88). The foreground wall occludes part
  of the floor. This is a line-only proposal, without scene integration.
- Previous requested study: CONTINUOUS PAVING AND MASONRY JOINTS.
  `docs/reference/masonry-floor-wireframe.svg` and its floor/junction/pillar
  views retain the 3 x 3 room, south corridor, square piers and common projection.
  The floor pattern now spans the whole usable floor, with no decorative seams
  at logical cell edges. The saved JSON records 111 slabs in 19 rows (13 room,
  6 corridor), staggered widths and slightly varied row heights. Floor remains
  at z=0 and meets the physical wall feet. This supersedes the old repeated
  per-cell paving pattern for the current proposal only.
  Lower wall courses have 1.9-unit brick spacing, with phases 0.7 and 1.65.
  Cap divisions continue down their 0.32-high front edges. Corner and pier caps
  remain whole square stones. User correction: piers have horizontal joints only,
  with no vertical subdivision of their small faces. Wall height
  2.2, thickness 1, course levels 0.94/1.88 and opening width 4 are unchanged.
  This remains line-only review work, without changes to Godot or painted assets.
- Previous requested piece: SQUARE JUNCTION PIER.
  `docs/reference/pillar-junction-wireframe.svg`, `-pillar.svg`, `-room.svg`
  and JSON propose a 1 x 1 x 2.2 prism, with the common projection and courses
  at z=0.94 and 1.88. Two identical instances at (6,14,0) and (11,14,0)
  bridge the south room walls and the corridor walls with full 1 x 2.2 faces.
  Their footprints cover two 1 x 1 patches of the bottom-center floor cell;
  the clear opening stays x=7..11, width 4. No projection mirroring, flared
  base or extra height. The accent stroke identifies the proposed piers only.
  This is a wireframe review proposal, without Godot or painted-asset changes.
- Previous requested assembly: 3 x 3 ROOM WITH A SOUTH CORRIDOR.
  `docs/reference/room-3x3-south-corridor-wireframe.svg` and JSON retain the
  nine-cell room but replace its bottom-center south-wall cell with floor only.
  A tenth cell with west/east walls is placed at (6,15), below the opening.
  Corridor bounds: x=6..12, y=15..20; clear floor: x=7..11. Preserve the
  common projection and dimensions. Six full wall interfaces remain internal
  (72 source edges omitted). The corridor walls touch the room's south walls
  only along vertical edges at (6,15) and (12,15): a full-thickness junction
  required the dedicated return proposed above. This preserves the earlier study,
  without scene integration or a claim of a validated junction.
- Previous requested variant: ONE CELL WITH WEST AND EAST WALLS.
  `docs/reference/side-walls-cell-wireframe.svg` and its construction SVG/JSON
  use two separate prisms at x=0..1 and x=5..6, y=0..5, height 2.2, thickness 1.
  Floor: x=1..5, y=0..5, z=0; 18 slabs retain the shared pattern's joints.
  Both walls use the same projection and height vector. North and south are
  open; hide occluded floor lines. This is a wireframe proposal only.
- Previous requested assembly: ROOM OF 3 x 3 CELLS (the user corrected 3 x 2).
  `docs/reference/room-3x3-wireframe.svg`, `-seams.svg` and JSON assemble all
  nine studies. Top: upper-left / north / upper-right; middle: west / floor /
  east; bottom: lower-left / south / lower-right. Cell offsets are multiples
  of (6,5), with room bounds x=0..18, y=0..15. Keep the common projection,
  wall height 2.2, thickness 1 and existing slab pattern. The eight shared wall
  end faces are internal (96 source edges omitted). Visibility uses the whole
  assembled volume. This is a wireframe proposal, without Godot integration.
- Previous requested variant: FLOOR-ONLY CELL, with no walls.
  `docs/reference/floor-only-cell-wireframe.svg` and JSON cover x=0..6, y=0..5
  at z=0, preserving the shared projection and the complete slab pattern before
  wall-foot trimming: 19 slabs in six rows (height 1 then five rows of 0.8).
  All four sides are open. This remains a line-only geometry proposal.
- Previous requested variant: LOWER-RIGHT CORNER CELL WITH FLOOR.
  `docs/reference/lower-right-cell-wireframe.svg` and its construction SVG/JSON
  join the east wall (x=5..6, y=0..5) and south wall (x=0..6, y=4..5) as
  one L-shaped prism, height 2.2 and thickness 1. Floor: z=0, x=0..5, y=0..4.
  Preserve the shared projection and slab joints; do not mirror the projected
  lower-left drawing. Hide occluded lines. Top and left remain open.
  This remains a line-only geometry proposal, without scene integration.
- Previous requested variant: LOWER-LEFT CORNER CELL WITH FLOOR.
  `docs/reference/lower-left-cell-wireframe.svg` and its construction SVG/JSON
  join the west wall (x=0..1, y=0..5) and south wall (x=0..6, y=4..5) as
  one L-shaped prism, height 2.2 and thickness 1. Floor: z=0, x=1..6, y=0..4.
  Preserve the shared projection and slab joints. Hide lines occluded by the
  combined volume; top and right remain open. This remains a line-only proposal.
- Previous requested variant: ONE CELL WITH ONLY A SOUTH WALL and floor.
  `docs/reference/south-wall-cell-wireframe.svg` and its construction SVG/JSON
  use wall bounds x=0..6, y=4..5, height 2.2, thickness 1; floor is z=0,
  x=0..6, y=0..4. Preserve the projection and height direction. The foreground
  wall occludes the floor behind it; hidden lines are optional. Top/left/right
  are open. This is still a line-only geometry proposal, without scene changes.
- Previous requested variant: ONE CELL WITH ONLY AN EAST WALL and floor.
  `docs/reference/east-wall-cell-wireframe.svg` and its construction SVG/JSON
  keep the unchanged projection, thickness 1 and height 2.2. Wall: x=5..6,
  y=0..5. Floor: z=0, x=0..5, y=0..5. Preserve the upper-right corner's slab
  joints for y=1..5 and add one row in y=0..1. Clip floor lines hidden by the
  wall volume. Do not mirror the west drawing; top/left/bottom remain open.
- Previous requested variant: ONE CELL WITH ONLY A WEST WALL and floor.
  `docs/reference/west-wall-cell-wireframe.svg` and its construction SVG/JSON
  preserve the same projection and cell bounds. Wall: x=0..1, y=0..5,
  height 2.2. Floor: z=0, x=1..6, y=0..5. Keep the corner's existing joints
  for y=1..5 and add one row in y=0..1 where the north wall was removed.
  Top/right/bottom are open; this remains a line-only geometry proposal.
- Previous requested assembly: THREE CELLS IN A ROW — upper-left corner,
  north-wall-only cell, then upper-right corner. See
  `docs/reference/three-cell-wireframe-join.svg`, `-seams.svg` and JSON.
  Offsets are (0,0,0), (6,0,0), (12,0,0); preserve all source dimensions,
  projection and slab joints. The shared wall end faces at x=6 and x=12 are
  internal (24 outline edges omitted); floor visibility uses the combined
  wall volume. The two continuous floor grout lines remain part of this study.
  This is a line-only assembly proposal, without scene integration.
- Previous requested variant: UPPER-RIGHT CORNER CELL WITH FLOOR, recorded in
  `docs/reference/upper-right-cell-wireframe.svg` and its construction SVG/JSON.
  Keep the accepted projection unchanged; move the return in world coordinates
  to x=5..6, y=0..5. Never mirror the projected upper-left image. The north wall
  stays x=0..6, y=0..1; floor is z=0, x=0..5, y=1..5. North-only slab joints
  are retained and trimmed at x=5. Hide floor lines occluded by the east wall.
  This remains a line-only proposal, without scene integration.
- Previous assembly review: place the upper-left corner cell A beside the
  north-wall-only cell B on its right. See `docs/reference/two-cell-wireframe-join.svg`
  and its JSON; `-seam.svg` marks the interface. B is translated by (6,0,0),
  with no rotation or scaling. The 12 wall edges on the shared end faces become
  internal and are omitted from the joined view. The existing slab layout is
  preserved, including its continuous grout line at x=6; this remains an artistic
  limitation to review. The focused report in `artifacts/two-cell-wireframe-join-report.json`
  checks 14 matching boundary points with zero projected mismatch. This is a
  wireframe assembly proposal, not approval of painted assets or Godot scenes.
- Previous variant: ONE CELL WITH ONLY A NORTH WALL and floor.
  `docs/reference/north-wall-cell-wireframe.svg` (plus construction SVG/JSON)
  derives from the corner study: keep the north wall, remove the west return,
  and extend floor coverage west to x=0. Cell bounds remain x=0..6, y=0..5;
  wall height, thickness, projection and framing are unchanged. Left/right/bottom
  are open. This is another line-only geometry proposal, not scene integration.
- APPROVED GEOMETRY: the user accepted `wall-wireframe-aligned.svg` ("ok très
  bien on avance") and designated it the UPPER-LEFT CORNER OF ONE CELL.
  Preserve that wall geometry and its projection exactly: ground X=(1,0),
  ground Y=(0,1), height-up=(-0.18,-0.9), height 2.2, thickness 1. This approval
  concerns the wireframe geometry, not any rejected painted sprite or live scene.
- Previous floor addition in the corner wireframe: see
  `docs/reference/corner-cell-floor-wireframe.svg`, its construction SVG and JSON.
  Floor is at z=0, x=1..6, y=1..5, touching the north/west WALL FEET. Its 16
  rectangular slabs use five staggered rows. Never align the floor to elevated
  wall-cap edges or change the accepted projection to fit the floor.
- Continue reviewing these wireframe variants before
  painted asset generation or scene integration unless the user directs otherwise.

### Orientation correction now accepted

- Latest correction: the LEFT WALL RUN must be vertical ON SCREEN, not diagonal.
  The two-point wireframe was rejected for its orientation. Current proposal:
  `docs/reference/wall-wireframe-aligned.svg` and
  `wall-wireframe-aligned-construction.svg`, metadata in
  `wall-wireframe-aligned.json`. It is a parallel oblique drawing with ground X
  horizontal and ground Y vertical. All faces share the same height offset.
  This is not a finite two-point camera. The user has now accepted this wireframe
  as the cell's upper-left corner; preserve its relief offset in the floor study.
- The user rejected `corner-parallel-courses.png` as still having
  incorrect perspective and asked for a LINE-ONLY WIREFRAME with correct geometry
  and vanishing lines. The first wireframe files `wall-wireframe.svg` and
  `wall-wireframe-construction.svg` are now rejected historical proposals.
- That rejected wireframe used a real level pinhole camera with two finite ground-plane
  vanishing points and parallel vertical edges. Its constant-section L prism and
  camera recorded in `wall-wireframe-two-point.json`. Do not use it as an
  approved reference for the game's screen-aligned floor plan.
- The old assistant-chosen oblique contract (+16,+96) is suspended for review.
  It was never artistically approved; do not treat it as a user requirement.
- The deterministic line drawing is explicitly requested by the user. It is
  a geometry guide, not a programmatically repaired production sprite.

### Previous sprite review (rejected)

- The user requested one proposed sprite for approval before any further kit
  generation or scene updates. Their latest feedback REJECTED
  `assets/dungeon/gloom-kit/proposals/corner-parallel-courses.png`.
- The user rejected `corner-straight-foot.png`: its base and perspectives were
  still wrong. Do not use that locally straightened end as geometry. The current
  proposal follows `docs/reference/corner-courses-guide.svg`, which draws each
  course with the same (+32,+192) top-to-foot displacement at 2x. The final PNG
  remains an image-generated interpretation, not proof of exact geometry.
- The user likes the material/color of the preceding `corner-review.png` but
  rejects its flaring foot. Preserve that second version's appearance; the wall
  must keep constant thickness down to the ground, with no spreading base.
- The sole palette/style reference is now `assets/dungeon/gloom-kit/reference.png`,
  copied unchanged from the latest user mockup. The user wants darker gloomy
  slate masonry and sparse localized violet luminous details. This supersedes
  cap-muted-v11 and all other previous generated color references.
- Full cleanup, regeneration and scene integration remain pending. See
  docs/superpowers/plans/2026-10-22-gloom-kit.md. The first gloom wall atlas was
  rejected for painting vertical top planes as facades; it must not be used.

## Previous perspective convention — suspended pending wireframe review

- Read `docs/reference/PERSPECTIVE.md` before any dungeon sprite generation or
  assembly correction. The user explicitly requested one remembered camera.
- Previous parallel oblique 2.5D proposal, contract `dungeon-parallel-v1` in
  `docs/reference/perspective-contract.json`. Ground axes stay screen-aligned.
  Top-to-foot projection is (+16,+96)
  at reference scale, uniformly scaled together; never mirror it for west/east.
  Painted lighting comes from image upper left for every orientation.
- Attach `docs/reference/perspective-geometry.png` as the geometry guide and
  the canonical material image to every generation. Include the prompt block
  from PERSPECTIVE.md and record the contract ID in generation provenance.
  Regenerate the guide with `tools/render_perspective_guide.gd` if the contract
  is explicitly revised. The guide is documentation, never production art.
- Use the latest original mockup's unlit wall tops as the color reference in every
  generation. Geometry inputs and color inputs have distinct roles. Do not
  progressively inherit a changed palette from generated variants.
- Check left wall, right wall, horizontal cap, full facade and corners together
  in Godot before propagating. No floating gaps; top and facade are one volume.
- The first lateral-relief experiment was rejected for opposing perspectives,
  different materials and open joints. Its prompts are archived in
  lateral-volume-generation.json; its code and all 14 trial PNGs are only in
  artifacts/lateral-volume-rejected. Never use compact-relief*, closed-relief*,
  shorts-relief*, lengths-relief*, elbows-relief* or paired-relief* from this
  rejected family as generation references or runtime assets. The recorded
  prompts contain the mistaken opposing directions; they are historical data.
  The active renderer has been returned to checkpoint 31e72bf while its replacement
  is calibrated. The checkpoint itself is not artistic approval.
- This convention supersedes all older projection descriptions below, including
  historical TOPS ONLY / exterior-backing and side-specific perspective rules.
  Older measurements describe their implementation, not this calibration contract.
  Native-alpha asset constraints
  and the prohibition on programmatic visual repairs still apply.

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
