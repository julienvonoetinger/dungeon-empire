# Isometric texture migration

> Execute inline with superpowers:executing-plans. The user explicitly authorized
> applying/migrating textures after the wireframe migration; no renewed approval gate.

**Goal:** Apply approved painted sources to the isometric kit and show them in all
active scenes, retaining offline masks, logical cells and the fixed camera.

**Architecture:** Keep migration-v1 geometry/guides as frozen comparison inputs.
Add an offline painter using the existing stone compositor, projected faces and
depth masks. Door artwork, torch metal/flame and heart appearance are reused
from their approved sources, never regenerated. Godot still places prepared PNGs.

**Spec:** AGENTS.md; user "Maintenant on peut appliquer/migrer les textures."
**Stack:** Node/Sharp/SVG material compositing, CPU depth masks, Godot atlas resources.

## Constraints

- Preserve 2:1 camera, XYZ dimensions, floor joints, two wall courses, door v8
  nested arches/smooth infill, 1x1 occupancy, .75 zoom/free pan and all layouts.
- Keep old approved images and migration-v1 snapshots. New evidence: painted-v1.
- Retain quiet smooth floors and softened stone corners within exact masks.
- Reuse approved heart sculptural details on rigid planes, and its vortex as a
  camera-facing effect. This is an appearance adaptation, not new art approval.
- Flame uses one screen scale, native alpha, and physical cup depth occlusion.
- Work in current checkout with uncommitted migration. No commit/push requested.
- No automated tests added/run. Use imports, visual captures and export review.

## Tasks

- [x] 1. Prepare architecture paint, exact geometry masks and magenta overlays.
- [x] 2. Adapt approved door, heart, pillar cap and torch appearance offline.
- [x] 3. Pack active catalogue; retain wireframe generation/review separately.
- [x] 4. Capture all scenes and inspect joins, special views and overlays; repair.
- [x] 5. Refresh export graph/docs; independent read-only final review.

## Decisions / progress

- Existing approved visual choices supply the design; brainstorming adds no new
  artistic direction or questions. Implementation details are delegated to us.
- Use a separate painter and output directory, preserving the wireframe exporter.
- Painted prop adaptations must be described as adaptations, not identical old PNGs.
- Final 26 sprites / 1024x1024 / 497604 PNG bytes / 4 MiB RGBA. Runtime 68
  captures/23 scenes and import clean; editor 21 captures/five scenes exits0 but
  retains native shutdown/progress diagnostics. Source graph45; ZIP432264 bytes.
- Reviewer identified filtering of a disjoint door cut: fixed with 2px opaque
  interior color overlap while retaining exterior alpha. Added geometry helper
  source hashes. Final review: no remaining findings. No automated tests/commit/push.
