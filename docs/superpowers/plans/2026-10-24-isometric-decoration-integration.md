# Isometric decoration integration

> Execute inline using executing-plans; focused final review using requesting-code-review.

**Goal:** Integrate the four accepted damage motifs into the common dungeon kit
and distribute them sparsely and deterministically in the existing scenes.

**Spec:** User accepted the four appearances, then accepted integration with an
evenly spaced, varied distribution. Exact art: isometric-decoration-review/v1/selection.json.

**Architecture:** Adopt the twelve prepared PNGs unchanged into the existing
atlas. Select decorations from logical coordinates and a scene seed on rebuild.
Draw each decoration immediately after its host; floor effects precede shadows
and all solids. No runtime projection, image generation or per-frame selection.

**Constraints:** Preserve geometry, all previous sprite pixels, .75 camera, all
layouts and two-cell corridors. Work in the current checkout containing the
ongoing migration. No automated tests, commit or push under session instructions.
Capture evidence in v1/integration/, preserving the accepted review snapshots.

## Steps

- [x] Freeze the current production atlas/catalogue/renderer and source hashes.
- [x] Add tools/isometric_approved_decorations.cjs, checking approval hashes and
  dimensions; append its prepared overlays in export_isometric_painted_kit.cjs.
- [x] Add scripts/dungeon_surface_details.gd for deterministic placement. Use
  coordinate hashes, sparse candidate selection and neighbour exclusion for each
  surface. Prefer ordinary damage; corruption gets the lowest weight. Skip
  door/stair cells, torch mounts and floor cells intersecting the heart support.
- [x] Expose surface_details and surface_detail_seed on wireframe_cell_study;
  pass settings in its plan. Draw selected regions in host order in the common
  renderer. Explicitly enable in production layout scenes; script defaults and
  historical review plans stay off. Prepared art remains at its accepted scale.
- [x] Re-export/import the kit. Capture the main reference, large layout,
  corridors, door/entrance and editor views; inspect gameplay-scale images.
  Record atlas pixels/metadata preservation, metrics and export dependencies.
- [x] Focused independent review, address material issues, update documentation
  and deliver an actual Godot preview. No device-performance claim.

## Review focus

Negative coordinates and insertion-order independence; real eligible hosts and
special/heart/torch exclusion; wall mortar alignment across four wall variants;
floor decorations beneath shadows/props; atlas filtering, reload and packaged
dependencies; accepted review source hashes remain unchanged.

## Implementation choices

- Stable per-coordinate ranking rather than a traversal-dependent random stream;
  neighbouring selected hosts on the same surface suppress one another. This
  keeps density low and scene refreshes consistent. A different seed changes it.
- Reuse the existing atlas if it fits at 1024 square; preserve all source pixels.
- Reviewer/captures inspect the implementation; no automated test suite added
  or run because developer instructions prohibit unsolicited tests.

## Completion evidence

- Active atlas: 47 regions, 583101 PNG bytes, still 4 MiB RGBA. Existing 35
  regions unchanged; 12 additions exactly match approved review atlas pixels.
  Standalone PNG copies and all 35 selected reference hashes unchanged.
- Focused view: off=0, seed17=8, seed43=4, restored17 byte-identical capture.
  Runtime68/23 and editor21/5 complete; editor retains native diagnostics.
- Staged export includes the new placement script; ZIP489337 bytes, all three
  import/export/isolated-startup processes exit0 with empty stderr.
- Independent scoped review found no concrete findings or deferred minors.
  Artistic distribution preference and device performance remain unproven;
  pre-existing light leakage/editor shutdown diagnostics are unchanged. These
  are explicit scope limits, not inferred approvals. Documentation reviewed by
  the parent after concurrent edits. No commit, push or automated tests.
