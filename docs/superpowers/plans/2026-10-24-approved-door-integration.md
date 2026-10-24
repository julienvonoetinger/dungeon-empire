# Approved mobile door integration

> Execution: superpowers:executing-plans, in the existing working branch.

**Goal:** Integrate the user's approved painted-art-v2 door in the shared mobile
kit and all consuming Godot scenes, preserving its geometry and exact paint.

**Architecture:** Reuse the eight prepared parts per direction (original main
arch plus seven v8 parts). Catalogue leaf entries declare their six additional
stone components. The common renderer places these using existing support-depth
ordering. All sprites share the existing atlas; runtime only places textures.

**Tech stack:** Node/Sharp offline exporter, Godot 4 GDScript, AtlasTexture.

## Constraints and decisions

- Approval: painted-art-v2/selection.json and wireframe-v8/selection.json.
- User explicitly said "Vas-y" to integration. No additional approval gate.
- Keep .75 fixed zoom, 256 px/cell, grid, layouts, stairs, walls, pillars and floor.
- No automated tests, commits or pushes; repository/user instructions override
  those defaults of the planning/execution skills. Use export reports, import,
  render captures and code review as evidence. Preserve live editor/cache state.
- Keep the existing dirty working branch so the previously approved local work
  is included. Do not move unrelated files or reset the checkout.

## Tasks

- [x] 1. Add tools/mobile_approved_doors.cjs. Verify approval/source hashes, use
  explicit art-v2 settings independent of CLI flags, export exact reviewed parts.
  Extend mobile_special_parts.specials with an optional door-export callback.
  Wire export_mobile_kit to it and add per-leaf component IDs/provenance.
- [x] 2. Make mobile_dungeon_renderer place catalogue-declared components.
  Old review catalogues without component IDs retain their old behavior.
  Regenerate the atlas/catalogue; expected 47 sprites, one atlas.
- [x] 3. Import with Godot and capture all 21 architecture scenes, including
  the four doors in WireframeDoorCross and ReferenceCalibration. Inspect native
  scale and joins. Refresh review boards and dependency/package size evidence.
- [x] 4. Update documentation and migration evidence; obtain a fresh code review
  focused on approvals, component order, imports, and exclusion of authoring
  sources from export. Address material findings, summarize the actual result.

## Review focus

Exact approved pixels/anchors, both leaf faces, front-wall occlusion, backwards
compatibility of frozen review tools, scene editor resource refresh, mobile size.

## Progress

- Planning: inspected common renderer, exporter, capture and deployment staging.
  Review already demonstrates the eight-part door depth order. Reusing that
  split adds six small sprites per orientation; no runtime painting introduced.
- Completed: 47 sprites / one 1024×2048 atlas, unchanged 8 MiB RGBA. 28 approved
  components and 19 retained sprites match pixels and placement in final atlas.
- Import, 60 runtime captures / 21 scenes, staging import, resource export and
  package opening: exit 0, empty stderr. Resource ZIP 609,890 bytes, 40 source
  dependencies, one imported texture. No APK/device performance claim.
- Editor helper: 13 captures / three scenes; all seven special-centered views
  match runtime. Two native views retain editor camera zoom 1 rather than .75;
  see integration report. Helper exits 0 with native editor shutdown diagnostics.
- Fresh read-only code review found no actionable issue. No automated tests,
  commit or push. Evidence: docs/reference/mobile-door-frame-review/integration/.
