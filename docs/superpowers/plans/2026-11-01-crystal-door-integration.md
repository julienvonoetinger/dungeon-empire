# Crystal Door Integration Implementation Plan

> **For agentic workers:** Execute inline using superpowers:executing-plans; request one focused read-only review.

**Goal:** Install the approved v15 metal/stone/crystal door in the shared game kit.
**Architecture:** Freeze an approved selection referencing the existing geometry and new leaf source, switch the shared offline painter, then regenerate existing atlas resources. Runtime gameplay and geometry remain unchanged.
**Tech Stack:** Node/Sharp asset pipeline, Godot native captures and existing fixtures.
**Spec:** User: “ok applique cette porte au jeu”; approved appearance is hero-fit-v15-iron-crystals.

## Constraints

- Work in the current authorized workspace; preserve the accumulated uncommitted excavation work.
- Reuse exact v15 source, compact geometry, masonry, keyhole/hinge contacts and independent jamb supports. No new art or hero poses.
- Open doors retain their stone frames. Atlas allocation and non-door pixels must remain unchanged.
- No APK, commit, push or player saves. Native fixtures disable persistence before entry; captures use ignored artifacts.
- Existing asset/behavior checks plus direct comparison with the approved raster provide verification; no implementation-mirroring unit tests for this material swap.

## Steps

- [x] Record current kit/hero hashes and demonstrate approved review sprites differ from active atlas.
- [x] Create v15 approval selection; preserve historical v13 files and pin old review material explicitly.
- [x] Regenerate the shared kit through the existing exporter; verify selected paint, approved packed pixels, unchanged metadata/open frames/non-door sprites and allocation.
- [x] Import and run native opening, badges, passage and Vulpin checks, with production-resource captures in four directions.
- [x] Review the narrow integration delta, inspect captures, update production/review documentation and AGENTS.

## Execution record

- Initial inspection: runtime selection still v13; v15 source and preview catalogue exist. User explicitly authorizes integration. No fresh design approval required.
- Native fixtures run sequentially to avoid Windows focus-loss interactions.
- Baseline exposes16 old-paint mismatches. Installed atlas passes361 checks;
  155 other regions and37 hero files unchanged, all171 metadata entries preserved.
  PNG delta -2307bytes; RGBA delta0 (13MiB).
- Import and opening84/badges87/passage863/Vulpin367 pass with empty stderr.
  Production captures:32 picking contacts and64 passage poses; four orientations,
  picking detail and open passage visually inspected.
- Read-only focused review found no runtime issue; its P3 obsolete installation
  status was corrected. Historical evidence retained separately; documentation
  now distinguishes comparison generation from actual production integration.
- No APK, player saves, commit/push or physical-phone validation.
