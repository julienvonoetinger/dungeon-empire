# Mobile black and gold HUD Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Port the accepted interface proposal into the playable Godot scene with touch-sized controls and all existing game actions.
**Architecture:** A shared Godot theme and vector icons provide the appearance; dedicated catalogue and selection components feed the existing guarded session API. The HUD owns responsive layout and modal presentation. The world camera and simulation rules remain unchanged.
**Tech Stack:** Godot 4.7, GDScript, small imported SVG assets.
**Spec:** `docs/reference/interface-review/v1/README.md`, `index.html`, and GAME_DESIGN.md section 0. User explicitly requests implementation on 2026-10-25.

## Global Constraints

- Black/gold, landscape mobile first; 48 logical UI unit minimum touch targets.
- Fixed .75 world zoom/free pan and all accepted dungeon assets remain unchanged.
- Preserve initial heart, economy, transfers, progression gates, save failures, pause/reset/defeat safeguards.
- No control of the user's screen or applications. Background import/startup/source inspection only; report device/visual validation limits.
- No automated tests without user request (repository instruction supersedes skill TDD); no commit/push requested.
- Continue in the current feature branch: the playable code to modify is uncommitted here. Preserve unrelated project.godot change.

## Review Focus

1. Countdown must stop while browsing construction without pretending the game is paused.
2. Touch on controls must not select/dig terrain behind them, including drag releases.
3. Modal confirmation, invalid save and defeat must not be bypassed by pause/Escape.
4. Transfers must keep a valid destination, nonnegative bounded amount and explicit action, without tiny popup/spinbox controls.
5. Small landscape, high DPI and safe areas must preserve target size without changing the world camera.

### Task 1: Native appearance and catalogue
- [x] Extract small standalone SVG icons from the accepted HTML; add stretchable black/gold panels and action backgrounds.
- [x] Create `scripts/game/ui/hud_theme.gd` (styles/common control builders) and `hud_catalog.gd` (three categories/eleven existing tools).
- [x] Import with Godot headless; inspect parser/import diagnostics and asset footprint.

### Task 2: Complete adaptive HUD
- [x] Create `scripts/game/ui/hud_selection.gd` for compact placement, loot/body actions and an inline touch-sized transfer editor.
- [x] Replace `game_hud.gd` with resource cards, phase, utilities, retracting catalogue, contextual panel and guarded modal flows.
- [x] Add a session presentation flag solely for suspending countdown while catalogue is open; preserve economic guards.
- [x] Size the HUD independently of world stretch; handle resize/density/safe area and compact text. Route Escape/Android back through the HUD.
- [x] Run parser/import and isolated headless scene startup; inspect changed handlers and constraints.

### Task 3: Review and documentation
- [x] Collect background layout diagnostics without invoking gameplay commands or writing player saves.
- [x] Obtain one fresh focused source review, address concrete important findings, rerun affected startup/import checks.
- [x] Update GAME_DESIGN, README, AGENTS and validation record with exact implemented behavior and limits.
