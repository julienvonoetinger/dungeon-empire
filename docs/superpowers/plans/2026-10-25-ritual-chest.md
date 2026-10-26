# Ritual chest integration plan

> **For agentic workers:** Use superpowers:executing-plans for this authorized, sequential integration.

**Goal:** Replace gameplay vault placeholders with the accepted closed ritual chest, grounded and sorted like existing props.

**Architecture:** Prepare the immutable selected PNG with a uniform resize and calibrated source-space contact. Add chest/shadow regions to the shared atlas. Feed vault positions through the existing decoration/support pipeline and attach the existing live gold caption to its solid group.

**Tech Stack:** Godot GDScript, Node/Sharp offline preparation, existing atlas and floor-shadow shader.

**Spec:** `docs/reference/treasure-chest-review/v2/selection.json` plus user authorization to integrate with anchor and shadow.

**User steering during execution:** The accepted closed design is for locked chests. Free chests should be visibly distinct, ajar with coins. Prepare the requested open variant and select appearance through existing `vault_protected`, including forced locks. Closed approval is unchanged; do not infer approval of new open artwork.

## Global constraints

- Preserve original accepted art/native alpha; no new ImageGen, warping or invented orientations.
- Fixed .75 camera, approximate96px displayed chest body width from the accepted review.
- Existing ritual props provide the short ambient contact/cast convention.
- Preserve the120 existing atlas regions' pixels and metadata except packing positions.
- Keep the existing1024x2048 page; chest variants and shadows go into one small256-wide companion page referenced by the same catalogue. The original packing could not fit the additional rectangles without doubling memory.
- Work in the existing feature checkout: required gameplay files are uncommitted here.
- No native UI control, app restart, player save writes, automated tests, commit or push.
- Validation uses asset integrity inspection, headless Godot import/startup and static in-memory scene inventories; distinguish montages from Godot captures.

## Review focus

- Captions remain current when vault gold changes without a rebuild.
- Foreground walls/heroes use the chest's actual prepared support ordering.
- At boundary floor cells, shadows use existing receiving-floor masks.
- Rebuild/remove/recreate leaves exactly one chest/shadow/caption per vault.
- Repacking preserves all accepted art; existing local project settings remain untouched.

## Task 1: Prepared art and atlas

Files: new `tools/isometric_treasure_chest.cjs`; modify `tools/isometric_ritual_props.cjs` only to expose its shadow helper; extend `tools/export_isometric_painted_kit.cjs`; generated `assets/dungeon/isometric-kit/{atlas-256.png,catalog.json,catalog.tres}`.

- [x] Snapshot active atlas/catalogues and the touched gameplay files under the new integration evidence folder.
- [x] Verify all six selection hashes; crop only fully transparent margins and resize uniformly to128 logical body pixels. Preserve a padded frame and measured contact proxy.
- [x] Produce `prop-chest` with decoration/support metadata and `prop-chest-shadow` through the shared short ambient shadow helper. No added light emitter or open-state artwork.
- [x] Extend the full exporter and run it; inspect contact guide and mobile montage. Compare all120 retained region pixels/non-region metadata against the snapshot.

## Task 2: Gameplay hookup

Files: `scripts/game/isometric_game_view.gd`, `scripts/game/game_marker.gd`.

- [x] Supply every VAULT cell centre as `prop-chest` in plan.decoration_positions, before rendering floors/shadows/solids.
- [x] Use `prop-chest-open` when `vault_protected` is false. Include protected state in structure hash so forced locks redraw; gold alone must not trigger structural rebuilds.
- [x] Replace the old chest geometry with its live gold caption, grouped with the prepared chest. Keep gameplay/saves, storage rules and HUD untouched.
- [x] Import with headless Godot and inspect in-memory layouts for isolated/boundary/adjacent vaults, dynamic gold, remove/rebuild and actor ordering. No automated test suite or player commands/saves.

## Task 3: Review and evidence

- [x] Produce an offline preview from the actual prepared atlas and scene placement inventory. Label it as a montage, not GPU capture.
- [x] Headless startup of DungeonGame and resource dependency check; no native window.
- [x] One focused independent read-only review, address concrete findings; record validation limits and size delta.
- [x] Update repository guidance with source immutability and production status; leave changes uncommitted.
