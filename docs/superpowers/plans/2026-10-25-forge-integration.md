# Forge and excavated bedrock Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement task-by-task.

**Goal:** Implement the accepted v9 stone/violet Forge UI and real rock cutout in the playable Godot scene.
**Architecture:** A cached terrain mesh follows the occupied cell union. A reserved world viewport area and a responsive side rail keep controls off the dungeon. The guarded session API supports repeated immediate placement and transient undo, retaining confirmation for destructive replacement and all current gameplay/save guards.
**Tech Stack:** Godot 4.7, GDScript, CanvasItem meshes/shader, existing PNG artwork.
**Spec:** User's “ok go pour l’implémentation”; `docs/reference/interface-review/v9-rock-cutout/index.html`, `world.js`, `notes.html`, and existing `GAME_DESIGN.md` game rules.

## Global Constraints
- Preserve accepted architecture/props, 2:1 projection, .75 fixed camera zoom, free pan, economy and save format.
- Terrain cap height is .3133333333333333, actual cutout margin .90 cell; expose ground at z=0. Never use the rejected dark band or raised outcrops.
- Stone/violet interface, actual painted icons, >=48 logical-unit targets; world and controls occupy separate rectangles. Landscape first, safe areas and a portrait fallback.
- Approved UI quick tools persist; selecting a catalogue tool retracts the catalogue. No per-cell confirm for ordinary construction. Destructive replacements, initial core, reset and transfers keep explicit actions.
- No automated tests per repository instruction. Use parser/import, isolated presentation captures and an interactive review slot; no player's save writes during captures.
- Continue current feature branch in place: all playable code and accepted mockups are uncommitted here. Preserve unrelated edits; no commit/push requested.

## Review Focus
1. Native touch and emulated mouse must not double-purchase; dragging/pinching and releases over UI never place.
2. Undo cannot cross a raid, transfer, collection, save reload or replacement that invalidates its snapshot.
3. Terrain must handle concave layouts, border cells and empty maps; never regenerate meshes on camera movement.
4. HUD must retain reset/save-blocked/defeat/pause guards and all existing contextual economic actions.
5. Reserved world area must match picking/camera transforms at mobile scale and after rail resizing.

### Task 1: Adopt art and integrate terrain
- [x] Freeze selection hashes and copy only used small assets into production folders.
- [x] Add `scripts/game/terrain_geometry.gd`: cached cell-union clipping into non-overlapping top polygons and contours.
- [x] Add `scripts/game/dungeon_terrain.gd` and `shaders/dungeon_terrain.gdshader`: top, exposed faces, raw ground; world-anchored materials and bounded coverage beyond the 16x16 map.
- [x] Attach terrain to DungeonGame; rebuild only when occupied cells change. Import/startup and inspect rendered rooms/extension.

### Task 2: Place directly, retain safeguards and undo
- [x] Add `activate_cell`, `can_undo`, `undo_build` to session; snapshot FIELDS plus affected raid knowledge/timer before each successful construction. Invalidate on non-construction mutation and raid/reset.
- [x] Keep explicit confirm for initial core and occupied-cell replacement; block invalid/locked/insufficient-gold placements.
- [x] Route tap and palette drag through one guarded activation; cancel on second finger, focus loss or UI release. Preserve free pan.

### Task 3: Native Forge interface and reserved view
- [x] Port skin and painted icons in `ui/hud_theme.gd`; update catalogue to vertical scroll.
- [x] Replace HUD layout with compact tools136, observation56, expanded244 logical units. Keep all pause/result/reset/save failure actions in reserved rail, with scrolling on small devices.
- [x] Adapt selection panel to reserved rail, retain transfer precision and loot/body actions. Expose viewport rectangle and compensate camera centre; no user zoom.
- [x] Capture three landscape sizes plus portrait, catalogue/context/menu/raid states and inspect spacing and visibility.

### Task 4: Validate and review
- [x] Godot import/startup and isolated visual captures; review source/presentation, then one fresh focused code review per execution skill.
- [x] Fix concrete important findings and rerun affected checks. Document exact validation, performance/device limits and any deferred findings.
- [x] Update README/GAME_DESIGN/AGENTS and preserve all approved review snapshots.
