# Isometric gameplay implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline. User already
> authorized the first playable loop and temporary markers; no additional
> permission gate for these reversible changes. Do not commit/push or run tests.

**Goal:** A playable preparation/raid/result loop on the approved 2D kit.
**Architecture:** Restore pure v1.0.0 simulation; add a separate session, 2D view,
HUD and pan/tap router. Retain prepared art and static scenes.
**Tech Stack:** Existing Godot 4.7.2/GDScript; no new dependencies.
**Spec:** `docs/superpowers/specs/2026-10-25-isometric-gameplay-design.md`

## Global constraints

- 16×16 logical grid; 1×1 solid heart; fixed .75 zoom and free pan.
- Existing economics/AI; no testing overrides, source-art edits or old 3D assets.
- Separate isometric save slot. Preserve existing project.godot local change.
- No automated tests per repository instruction; compilation and manual play only.

## Review focus

UI tap leaking into construction; pan turning into a purchase; mutation during
raid/pause; duplicate rewards and corrupt-save overwrite; actor occlusion against
walls/doors/heart. Check these deliberately during source review and manual play.

### Task 1: Restore rules and isolate persistence

- [x] Restore five pure scripts under `scripts/game/` from v1.0.0, removing obsolete
  display constants/paths from game_types and setting CORE_W/H=1.
- [x] Restore save adapter as `scripts/game/gameplay_save.gd`; source tag provenance.
- [x] Inspect class references, bounds and save validation; no old rendering deps.

### Task 2: Session and isometric interaction

- [x] Add `scripts/game/game_session.gd`: owns sim/raid/progression, guarded commands,
  state changes, result/reward, checkpoint persistence, reset and optional starter.
- [x] Add `scripts/game/isometric_game_view.gd`, `game_marker.gd`, `game_input.gd`:
  reads model into renderer; geometry-based picking, fixed camera, independent
  moving marker order. Do not rebuild the architecture for movement alone.
- [x] Add `scripts/game/game_hud.gd` and `scenes/game/DungeonGame.tscn`: French HUD,
  construction/confirm/cancel, chest transfer, repairs, collection, pause and results.

### Task 3: Verify and document

- [x] Godot import/parser and explicit scene launch; inspect outputs.
- [ ] Finish manual gameplay validation: a full raid/result, economy UI, pan/touch,
  actor ordering and corrected interactions. Starter + raid entry seen; UI control
  stopped at user's request. See docs/gameplay/validation-2026-10-25.md.
- [x] Fresh focused read-only code review; correct concrete problems and recheck.
- [x] Update active GAME_DESIGN/README and AGENTS with implemented scope, commands,
  actual verification and limitations. Leave current editor main scene unchanged.
