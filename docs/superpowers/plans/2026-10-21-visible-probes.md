# Visible dungeon probes implementation plan

> Execute inline using the existing Godot project and test entry point.

**Goal:** Make existing spatial probes visible and inspect every rendered element,
with automated regressions that identify misplaced pieces by ID and coordinates.

**Spec:** User requests probes for tests and element placement visualization.
Implementation choices: F3 toggles a diagnostic overlay, initially off; colored
points show spatial checks, clicking selects a contour/anchor with coordinates,
category filtering keeps the view readable. Test reports include exact positions.
This is developer tooling for the approved six-room scene, not a level editor.

**Architecture:** Shared fixture points consumed by both existing tests and a
read-only inspector. Catalog all actual polygon surfaces, sprites and lights in
dungeon-local coordinates; preserve inherited transforms and drawing order.
Keep expected placement independent of the observed current node positions.

## Constraints

- Preserve artwork, placement, stone seed, authored heart and normal camera.
- No persistent settings, new textures or gameplay. Overlay disabled by default.
- Rendering tests remain separate from spatial PASS labels in the overlay.
- Work in the current feature checkout, retaining prior uncommitted work.

## Tasks

- [x] Add failing `tools/verify_probes.gd`: overlay absent by default visually,
  complete catalog, fixed probes passing, displaced wall/heart and missing floor
  detected, inherited coordinate transforms, repeatable IDs and refresh after rebuild.
- [x] Implement `scripts/probe_fixtures.gd` and `scripts/dungeon_probes.gd`;
  reuse fixed floor/side/entrance/east/heart samples in existing verification.
- [x] Add `scripts/probe_overlay.gd` to main scene: F3, category selection,
  inspect actual contour/origin/bounds/Z/atlas, failed probe picking, refresh,
  JSON export; default off, no changes to rendered artwork.
- [x] Add input and GPU overlay regressions, annotated full-map/detail captures;
  integrate the runner and isolated editor fixture, update design/README.
- [x] Run `tools/test-mobile.ps1 -All -Capture`, inspect captures, read-only review.

## Review focus

- Expected probes must not move along with a faulty object.
- Floor checks intentionally inspect substrate underneath the heart, not the top object.
- Picking must use contours and inherited transforms/Z, not just bounding boxes.
- Regeneration must not leave stale node references, IDs or duplicated overlays.
- Overlay-off pixels must equal the original frame; PASS means spatial validation,
  not certified lighting/artistic correctness. JSON must retain numeric coordinates.

## Verification ledger

- Initial missing-overlay test failed as expected (`artifacts/probes-red.*.log`).
- Headless inspector regression passed after assigning stable names to the two
  generated torch lights. Full catalog: 978 entries; fixed spatial checks: 640.
- GPU inspection found oversized panels after initial autowrap sizing; layout now
  shrinks to content. Regression checks compact toolbar and visible detail panel.
  Dense failure labels were separated using collision checks and leader lines.
- Initial full capture suite passed (`artifacts/probes-full-suite.log`).
- Read-only review found two P2 cases: Polygon2D.offset omitted from contours and
  UV interpolation assumed a native mapping without checking it. Added deliberate
  faults; both failed first (`probes-review-red.*.log`) then passed after including
  draw offsets and validating every UV vertex and texture transform
  (`probes-review-green.*.log`).
- Also corrected selection of hidden probes; two regression assertions failed
  first (`probes-selection-red.*.log`). Drawing and picking now use the same filter.
- Review boundaries retained: artistic fidelity is assessed through captures;
  mobile controls, arbitrary layouts and exhaustive pixel coverage are not claimed.
  Existing render regressions still cover source pixels and normal scene appearance.
- Final `tools/test-mobile.ps1 -All -Capture` passed after all fixes
  (`artifacts/probes-final-suite.log`). Normal GPU source error remains 0.82/255;
  heart samples 0/255. Actual F3/click/R, compact panels, non-overlapping labels,
  masked-probe selection and exact pixels after disabling diagnostics pass.
- Inspected the final normal map, entrance/joins, vertical walls, reference study,
  full annotated map, wall detail and temporary fault illustration. The design
  and README describe controls, coordinates, counts, scope and test-only overrides.
- No game-state persistence, gameplay change, new texture, commit or push.
