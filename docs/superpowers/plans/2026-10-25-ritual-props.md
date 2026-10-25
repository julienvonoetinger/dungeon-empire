# Six ritual props implementation plan

**Goal:** integrate the six selected appearances as small prepared 2D decorations
in the existing isometric Godot kit, with floor contact and correct solid order.
**Spec:** `docs/reference/isometric-prop-review/v1/selection.json` and its README;
the user explicitly authorized preparation/integration with “ok vas-y”.
**Architecture:** offline uniform sprite preparation, source-space foot calibration
mapped through the existing inverse ground projection, separate prepared contact
shadows, common atlas and existing physical support sort. Authored positions;
no unrequested automatic population or gameplay collision system.
**Tech:** Node/Sharp, GDScript, existing Godot capture/export tools.

## Constraints and decisions

- Preserve all 12 selection hashes and all 108 existing atlas regions/metadata.
- Keep 2:1 projection, .75 fixed zoom and pan. No mirroring, screen rotation,
  independent-axis scaling, regeneration or retouching of selected source art.
- Native alpha and one uniform scale; small-size targets 62/76/84/49/56/67px.
  Footprints are placement/occlusion proxies, not a claim to recover exact 3D art.
- Authored `decoration_positions` maps ground Vector2 to one of six prop IDs;
  reject missing floor, special cells and intersection with solid supports.
- Short contact/cast shadows below all solids. Candle local light is optional
  and independent of the torch switch. No dynamic shadow simulation.
- Continue in this feature checkout to retain current selected/uncommitted art
  and the user's Godot setup. No editor-cache reset, automated tests, commit/push.
  Use capture/import/export and pixel-integrity checks as in the repository.

## Tasks

- [x] Prepare `tools/isometric_ritual_props.cjs`, integration recipe, calibrated
  base guides and six sprites/six shadows; guard selected source hashes.
- [x] Extend `export_isometric_painted_kit.cjs` metadata/catalogue; prove prior
  pixels and non-region metadata unchanged and report atlas size.
- [x] Add placement properties and support validation to common renderer/study;
  use existing depth ordering, rebuild lifecycle and independent light switch.
- [x] Add `scenes/DungeonDecorations.tscn` and sparse authored examples in
  MobileReference, DungeonPreview and SixRoomPreview. Keep layouts intact.
- [x] Capture game scale, close view, foreground/background walls, lighting
  on/off, invalid placement/negative coordinates and refresh restoration.
- [x] Run full scene runtime captures, focused editor captures and staged
  resource export/startup. Inspect visual results and request focused independent
  review, fix concrete findings, save evidence and usage documentation.

## Review focus

Foot contact versus drawn base; low props behind foreground walls; authored
positions in void/special cells or overlapping heart; duplicate/rebuilt lights;
atlas growth and old approval/region preservation. Exercise these through the
capture script and read-only artifact checks, not a new automated test suite.

## Execution ledger

- Started from `18d96a23` with only the pending prop proposals/selection and
  their AGENTS/attributes edits. No production modifications at baseline.
- Explicit integration authorization covers the described preparation. No
  repeated design/plan permission request is necessary.
- Completed: 108 old RGBA regions/non-region metadata and 12 selected hashes
  preserved; 120 regions in 8 MiB, +62070 PNG bytes. Raster density .75/.5 avoids
  initial full-density packing overflow to 16 MiB while keeping the game scale.
- Windows direct writes to in-use existing PNGs failed. Reused atomic writer in
  wall/floor variant exporters; old region identity verified after successful export.
- Captured 13 focused, 70 runtime/24 scenes, 17 editor/five. Six deliberate
  invalid placements rejected; no normal scene warnings. First authored stele
  straddled void at x10; moved to x10.5 and recaptured both large scenes.
- Editor first-pass legacy resolution error did not reproduce in parser-only or
  second editor run; native shutdown diagnostics remain documented, not hidden.
- Independent review by review_ritual_props: no concrete actionable findings.
  Final pixel-integrity checks also passed. ZIP1324453,53 dependencies, startup0.
- Concurrent project.godot main-scene change was not authored by this work and
  remains intact. No tests, commit/push or device-performance claims.
