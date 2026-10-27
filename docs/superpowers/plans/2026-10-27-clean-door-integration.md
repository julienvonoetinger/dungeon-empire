# Clean door texture integration

> **For agentic workers:** Use superpowers:executing-plans; finish with a focused fresh read-only review.

**Goal:** Integrate the accepted v6 geometry and v7 painting into the existing four-direction doors.

**Architecture:** Freeze the accepted source geometry, image, registration and palette in v8 selection metadata. Replace the old door generator input with that model and reuse the accepted painting algorithm. Retain the two sprite layers, .8 density, IDs and segmented runtime wall depth ordering; metadata carries the new 1/3..2/3 junction span.

**Spec:** User: “Oui c'est corrigé. Tu peux intégrer”. Accepted references: wireframe-v6-clean-leaf and painted-v7-clean-leaf. No new paint or design changes.

**Tech stack:** Node/Sharp XYZ preparation; Godot native scene/capture tools.

## Constraints / review focus

- Keep the smooth interchangeable leaf; hardware only in paint.
- Source painting and accepted reference images immutable; no normal player save access.
- Preserve 143 non-door regions and the 11MiB RGBA allocation.
- No economy/UI/AI/camera changes, commit or push.
- Check all four rotations, both wall contacts, sprite split/filter boundary, actor depth, destruction/removal/restoration.

## Work

- [x] Record pre-integration region hashes and freeze accepted inputs; observe a failing geometry/metadata check against the old runtime.
- [x] Load the accepted geometry and pinned material preparation in production; update junction metadata and export provenance.
- [x] Verify prepared door pixels against the accepted preview, exact geometry, two-layer recomposition and unrelated asset preservation.
- [x] Export/import and native captures; verify physical contact ownership and gameplay group lifecycle with the existing isolated harness.
- [x] Read-only review, final visual inspection, evidence and repository notes.

## Ledger

- Reuse the current feature branch and existing uncommitted approved work. This continues the earlier door correction; do not reset trap/HUD assets or overwrite prior review evidence.
- RED: old geometry fails accepted-model comparison. GREEN: all four exact v6 models, 75,972 interior pixels compared to approved v7 with zero byte difference, split alpha error 0 and premultiplied rounding <1 byte.
- Export/import exit0, empty stderr. 143 non-door regions/metadata unchanged; 151 total regions, 11MiB RGBA unchanged, PNG total -11,135 bytes versus pre-integration v4 baseline.
- Eleven static native views plus four game screenshots; seven lifecycle/actor states passed. Exact contact interiors: zero ownership errors; painted/filter boundary excluded. Four directions and near-threshold actor overlap inspected.
- Independent scoped review: no actionable findings. No phone/profile/full-campaign validation, player save access, commit or push.
