# Isometric floor B implementation plan

> **For agentic workers:** Use superpowers:executing-plans in this session.

**Goal:** Integrate four compatible B floor arrangements into all production layouts.

**Architecture:** Offline complete-stone geometry and the existing calm material
produce four prepared floor PNGs. All share the same whole crossing stones at
the four logical borders. Godot chooses one region per cell on rebuild, with a
stable seed; existing bare floor remains the historical/default fallback.

**Tech Stack:** Node/sharp, existing mask/material painter, Godot GDScript.

**Spec:** `docs/reference/isometric-floor-variation-review/v1/selection.json`
and user "ok go" following selection of B alone.

## Constraints and rulings

- Keep 2:1 projection, logical1x1, .75 zoom/pan, layouts, walls and all props.
- B supplies the selected size/assembly direction; reuse the current approved
  calm material/rounded finish to preserve palette. Original B PNG is immutable.
- Four variations: balanced stagger; long/short alternation; tall middle slab;
  transverse slab with smaller complements. No fissures, holes, raised stones.
- Whole stones cross x/y borders; same geometry, material UV and finish seed
  on both sides. Paint before cropping; retain the existing 2px filter guard.
- Current feature checkout contains the entire uncommitted migration. Work in
  place and snapshot touched files; no worktree/HEAD switch, commit or push.
- Existing repository instruction forbids new automated tests without request.
  Use preparation integrity checks, Godot captures/import and isolated export.
- User already authorized implementation. Execute directly without a new gate.

## Review focus

1. Any pair of four tiles connects in both axes, including four-way corners.
2. Shared boundary stones retain identical sampled colour and full bevels.
3. Negative coordinates, different seeds and reconstruction preserve stable art.
4. Doors, stairs, heart shadows/lights and new wall families retain their output.
5. Small mobile scale stays quiet; large floor does not form visible cell columns.

### Task 1 — Prepare compatible floor art

Files: new `tools/isometric_floor_variants.cjs`; existing
`tools/export_isometric_painted_kit.cjs`; evidence under floor review `v1/integration/`.

- [x] Snapshot current catalogue/atlas, touched scripts/scenes and sources.
- [x] Build four sets of complete rectangles with common border stones; check
  coverage/no overlap and matched boundary strips before rendering.
- [x] Paint using `isometric_stone_paint.paint`; prepare geometry, guides,
  sprites/overlays and a mixed-tile board. Preserve all100 original atlas entries.
- [x] Register floor-b1..b4, metadata/provenance and repack; measure atlas size.

### Task 2 — Integrate stable selection

Files: new `scripts/dungeon_floor_variants.gd`; renderer,
`wireframe_cell_study.gd`, twenty layout `.tscn` files; focused capture tool.

- [x] Select from four IDs by logical coordinates/seed, no per-frame work;
  use disjoint two-variant buckets on horizontal neighbours to avoid duplicates.
- [x] Add floor_variants=false/floor_variant_seed=17, rebuild setters and plan
  fields. Enable twenty production layouts; leave isolated props/reviews bare.
- [x] Capture all combinations at fixed zoom and close range, negative-grid
  patch, MobileReference before/seed17/seed43/restored17, SixRoomPreview.
- [x] Inspect images, verify seed restoration and unchanged non-floor placements.

### Task 3 — Verify and document

- [x] Import and capture all23 scenes; capture five in editor. Record actual
  exit/stderr; existing native editor diagnostics must not be called clean.
- [x] Compare all100 retained atlas regions rawRGBA/metadata and selected hashes.
- [x] Stage50+ dependencies, export resource ZIP, run isolated package.
- [x] Focused independent review under requesting-code-review; resolve findings.
- [x] Update active design/asset docs and AGENTS with measured size and scope.

## Progress

- Plan reviewed against selected B and prior seam/palette failures. No new art
  generation: this is a geometry/layout adaptation using approved base material.

- Tasks1–3 complete: geometry/pixel integrity;9 focused+68 runtime+18 editor captures; resource export/startup. Independent review: no actionable findings.
- Ruling:2px alpha guard alone caused downsampling RGB seams; full ink and a6px temporary colour guard before final2px alpha remove them (maxdelta9→1). Existing100 regions remain byte-identical in RGBA.
- Ruling: historical helper snapshot recovered only after matching archived recipe SHA256; exact provenance retained. No commits or tests per session scope.
