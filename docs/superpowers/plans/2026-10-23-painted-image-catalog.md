# Remaining Painted Images Implementation Plan

> Execute inline in the current workspace, continuing the user-approved method.

**Goal:** Prepare the existing isolated wireframe families as painted PNGs with
shared materials, exact geometry and review overlays.

**Architecture:** Offline Node/SVG/sharp exporter. Read guide linework unchanged;
derive bounded face masks and classify them using the source 3D volumes under
the fixed camera. Reuse the stone library; shared generated wood and iron supply
doors. Deduplicate identical isolated variants through a manifest.

**Spec:** docs/reference/MATERIAL_WORKFLOW.md, WIREFRAME_WORKFLOW.md, and current
user authorization to produce the other images.

## Constraints

- Square 1x1; projection (x-.18*z,y-.9*z), wall T=1/6, H=1.88/6, joint=.94/6.
- Same guide frames/anchors, uniformly rendered at 4x; no image mirroring.
- Preserve all visible standalone end contours and the existing hidden lines.
- No Godot integration, automatic commits, or gameplay changes.
- Perform requested visual/geometry checks; do not add a gameplay test suite.

## Tasks

- [x] `tools/painted_material_renderer.cjs`: shared planar-face and paint helpers;
  retain exact line coordinates/widths, texture identities and style profile.
- [x] `tools/export_painted_image_catalog.cjs`: cell/floor/pillar model adapters,
  stairs/door adapters using existing source volumes, deduplicated PNG catalog.
- [x] `assets/dungeon/shared-materials/`: generated wood/iron material sources,
  prompt/provenance; reuse stone PNGs without palette regeneration.
- [x] `assets/dungeon/painted-cells/`: standalone painted PNGs plus catalog.
- [x] `docs/reference/painted-kit-review/`: overlays, contact sheets, measurements
  and instructions; inspect all overview pages and enlarged door/stair examples.
- [x] Synchronize AGENTS.md, GAME_DESIGN.md and material workflow with actual scope.

## Result

57 unique images resolve 146 guide identifiers. Full export completed with
unchanged guide line coordinates/widths, zero alpha differences, zero unpainted
interior pixels and zero excess pixels. The three complete cell sheets, special
pieces, magenta sheets and enlarged door/stair examples were inspected.
During review, lateral doors exposed uninked floor boundaries and a region that
spanned wood and stone. Source-volume material masks now handle both cases;
no source guide or geometry was changed. Artistic acceptance and connected-scene
integration remain outside this image export.

## Review focus

- Concave corners, pillars and disconnected outlines must leave no unpainted face.
- East/west use one camera, not mirrored art. Physical top/facade material IDs agree.
- Stairs retain all five steps and distinct tread/riser shading.
- Both door faces retain handles/bands; lateral doors preserve real occlusion.
- Every exported guide segment matches the source; raster alpha matches the
  independent projected volume silhouette. Catalog aliases resolve to real PNGs.
