# Wall variants and D2 integration plan

> Execute inline with superpowers:executing-plans. Preserve existing user work.

**Goal:** Use the selected D2 corruption and complementary A/B/C walls throughout
the existing Godot architecture scenes, with less repetition and continuous joins.

**Architecture:** Generate complete PNG variants offline from the accepted masks
and material crops. Keep shared boundary stones fixed. Godot selects a prepared
variant deterministically by grid coordinate, with sparse nonadjacent D2 accents.

**Tech stack:** Node/sharp offline exporters; Godot GDScript image selection.

**Spec:** User's D2 selection and “Go”; AGENTS.md and the wall variation reviews.

## Constraints and rulings

- Fixed grid, projection, geometry, joints, B finish, smooth rounded floor,
  two-cell-wide corridors, stairs/doors and all existing layouts.
- No runtime image generation, clipping, recoloring, or sprite rotation.
- No tests added/run: repository and developer instructions prohibit them
  without an explicit request. Use normal export audits/import and visual captures.
- Continue in the existing `codex/2d-foundation` checkout used by the user's
  Godot editor and containing the selected reviews. No workspace move or editor restart.
- No commit/push requested for this task. Keep `.codex-remote-attachments/` alone.

## Review focus

- Whole-stone material and filtering-guard agreement across differently styled cells.
- D2 is one unfolded patch across top/facade, without double centre or altered alpha.
- Special neighbours retain visibility masks and geometry.
- Negative coordinates and sparse D2 placement remain deterministic in the editor.
- Historical review baselines and the approved floor stay unchanged.

## Tasks

- [x] Promote exact selected crops and persist the active wall recipe. Extract
  reusable offline variant/material mapping, including D2 continuous UVs.
- [x] Extend connected export with four prepared styles and shared-image dedup.
  Update isolated export and deterministic Godot selection, retaining lazy loading.
- [x] Re-export both kits, import Godot, capture representative scenes and inspect
  walls, doors, stairs and wide corridors. Update durable docs with measured scope.
- [x] Fresh source review of final changes; resolve material issues and report result.

## Execution record

- Initial checkout inspected; preexisting modifications are the wall reviews and
  optional texture-transform support from this conversation. No tests run.
- Active wall recipe promoted with 17 material crops; preparation matches their
  saved hashes. Isolated export complete (57 images / 146 aliases). Connected
  four-style export completed: 2,900 unique structures / 1,444 contexts,
  four prepared paths each, 161 empty contexts. Export audits: zero alpha
  differences/unpainted interior pixels; all construction joint layers match.
  Shared floor PNG hash equals the frozen pre-wall floor.
- Fresh read-only source review completed: no Critical, Important or Minor defects.
  Review covered shared boundary materials, unfolded D2 UVs, cache signatures,
  lazy paths and signed 64-bit coordinate hashing. Generated output/import and
  assembled visual review remain separate from that source review.
- Final Godot import and all four capture commands exit 0 with empty stderr.
  Captured 20 scenes at two viewport sizes and 13 close-ups (53 PNGs total).
  Reviewed both boards plus individual ReferenceCalibration, west door, east
  stairs and west wide-corridor join. No visible material discontinuity found
  in those inspected views; no claim about every future arrangement/zoom.
- Retired 641 unreferenced old structural PNGs and their .import files to an
  ignored recoverable local archive, with SHA-256 inventory in the review.
  Scene/layout files are unchanged. No automated tests, commit or push.
