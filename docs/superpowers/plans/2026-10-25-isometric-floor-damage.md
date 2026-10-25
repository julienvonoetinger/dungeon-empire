# Approved floor damage integration plan

> **For agentic workers:** Use superpowers:executing-plans inline, with one focused independent review at completion.

**Goal:** Integrate the four accepted floor damage appearances, sparsely among clean B floors.

**Architecture:** Preserve the four ImageGen originals. Project selected painted stone faces onto existing B stone rectangles offline, using geometric masks, shared stone colour and unchanged boundary pixels. Add four prepared decorated floors to the common atlas. A deterministic selector chooses them during rebuild, skipping specials and heart support; no runtime painting.

**Spec:** User acceptance “ok ajoutes les”; docs/reference/isometric-floor-damage-review/v1/README.md and generation.json describe A/B/C/D. Existing B geometry and root AGENTS.md govern integration.

**Tech Stack:** Node/Sharp offline preparation, GDScript/Godot prepared atlas renderer.

## Constraints and rulings

- Keep isometric projection, logical cells, camera, layouts, props, clean floor B and all104 existing atlas regions unchanged.
- Keep newly approved sources and previous approval files unchanged. Appearance adaptation must be documented, not claimed to be a direct source pixel copy.
- User's standing mask/wireframe workflow authorizes offline geometric source sampling; no new artwork generation or hand-redrawn cracks.
- Stay in existing codex/2d-foundation checkout: required uncommitted approved migration exists only here. No branch switch, commit or push.
- Repository forbids new automated tests without request. Use focused visual captures, pixel/geometry evidence, import/export checks instead.
- Maintain mostly clean floors. Corruption rarer than ordinary fissures. Stable seed, neighbour exclusion, skip special cells and actual heart support.

## Review focus

1. Source projection must not introduce foreign mortar edges, light stone patches or blurred/stretched fissures.
2. All prepared floor borders/alpha must remain identical to their clean B host.
3. Negative logical coordinates, dictionary order and seed restoration must stay deterministic.
4. Disabled option and old review plans remain bare; heart/special exclusions work.
5. Atlas memory growth and filtered joins must be verified from the real packed pixels and Godot captures.

## Task 1 — Freeze selection and prepare four decorated B floors

- [x] Save selection hashes, current catalogue/atlas/code baseline and sources used.
- [x] Implement tools/isometric_floor_damage.cjs with source-plane patches on complete B stones, common palette and geometric masks; save mappings and prepared sprite comparison.
- [x] Inspect all four at game scale and magnified, verify source hashes and unchanged host boundaries before exporting.

## Task 2 — Integrate sparse placement and atlas entries

- [x] Add four items/metadata/provenance to export_isometric_painted_kit.cjs.
- [x] Add deterministic dungeon_floor_damage.gd; wire floor_damage/seed options into common renderer and twenty layouts.
- [x] Generate atlas and check104 retained regions, new prepared pixels, boundaries and atlas size.

## Task 3 — Capture, verify, review and document

- [x] Capture forced samples, negative patch, off/on/changed/restored seed, heart/special exclusions and full scene.
- [x] Import and capture23 runtime scenes plus representative editor views; inspect actual images.
- [x] Stage resource export and isolated startup; record exact bytes/process diagnostics.
- [x] Run focused independent read-only review, resolve concrete findings, update evidence/docs and show final capture.

## Progress ledger

- Plan created; implementation not started. Current concept-only generation/validation are frozen pre-acceptance snapshots.
- Ruling: full decorated floor copies caused the packer to cross2048px height (16MiB). Keep the exact same painted pixels as cropped host-specific overlays with unchanged2px backing borders; draw after matching clean B, before ground shadows. This avoids redundant whole-floor storage and preserves base floor selection/joins. The rectangular backing requires the declared host; selector enforces it.

- Tasks1–3 complete. Evidence: integration/validation.json. Source hashes and104 retained regions unchanged; atlas108 stays8MiB. Review alpha/joint-root fixes closed, with final Godot captures/export after pixel changes. Final metadata-only regeneration left atlas/catalogue byte-identical. No automated tests, commit or push.
