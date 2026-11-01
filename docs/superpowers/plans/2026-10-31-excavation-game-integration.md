# Excavation game integration implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline, then request one independent read-only code review.

**Goal:** Make the approved v29 excavation cubes and terrain recess the normal DungeonGame presentation.

**Architecture:** Promote the active terrain and cube controller to shared runtime scripts. The production scene uses them directly; DigBlocksPreview becomes a no-save wrapper around that same game. Historical terrain profiles remain only in its preview adapter.

**Tech stack:** Godot 4.7.2, GDScript, native GPU fixtures and headless probes.

**Spec:** User request “ok mais maintenant il faut mettre à jour le jeu”; approved visual state is docs/reference/interface-review/v29-cube-recess-fit/index.html.

## Constraints and decisions

- Preserve .74 square cubes, wall height, common row/column offsets and dark pick icon.
- Preserve the vertical cut, 1.35 placement reference, .04 edge gap and height-derived foreground setback.
- Preserve 5 gold transactions, Undo, camera pan, raid rules, English UI and normal persistence in the actual game.
- Tests disable persistence before tree entry. No player-save I/O, APK, commit or push.
- Keep the current workspace: approved implementation and unrelated earlier work are uncommitted here. No reset or isolated checkout that drops that work.
- User has already requested implementation; execute directly without an additional approval gate.
- Reuse existing imported art and shader resources; avoid asset copies or a broad historical-path migration.

## Review focus

- HUD constructs its children before the renderer has rebuilt: null definitions/world nodes must be safe.
- Raid, pause, welcome, catalog and selection must suppress cubes and preserve contextual hints.
- Removing old excavation guides must not hide Paths or valid-placement guides.
- World rebuilds must not leave duplicate/freed cube nodes or charge twice on a held pointer.
- Small portrait/landscape rotation and dragging from a cube must preserve no-purchase behavior.

## Tasks

### 1. Prove the production scene still lacks the approved presentation

- [x] Add tools/verify_excavation_game.gd instantiating DungeonGame directly with persistence disabled.
- [x] Assert the 1.35 placement margin, swept cut and cube controller exist; capture failing baseline.
- [x] Cover cold empty-map startup and preparation without relying on the preview's script replacement.

### 2. Share the approved renderer between game and preview

- [x] Create scripts/game/excavation_terrain.gd for the active cut/material; keep historical slope/legacy selection in scripts/dig_terrain_preview.gd.
- [x] Point scenes/game/DungeonGame.tscn at the runtime terrain.
- [x] Create scripts/game/ui/hud_dig_blocks.gd from the approved adapter, guarding startup and removing its unconditional hint override.
- [x] Point game_hud.gd at the controller and update only the preparation hint.
- [x] Remove only the flat dig branch in isometric_game_view.gd; retain placement and Paths drawing.
- [x] Make dig_blocks_preview.gd use the game's controller; retain the old adapter path as a compatibility wrapper.

### 3. Validate runtime behavior and review

- [x] Extend the new fixture with native top/side purchase, drag/cancel, Undo, UI mode visibility, rotation, raid hint and persistent terrain during raids/no funds.
- [x] Compare main-game terrain/cube geometry with the approved preview before native interactions.
- [x] Run native integration, existing cube capture, geometry fit/spacing, masonry, mobile interaction/rotation and direct-dig checks as relevant; run gameplay probe recipes.
- [x] Inspect production-scene captures in desktop, short landscape and portrait.
- [x] Request independent read-only review and resolve actionable issues.
- [x] Update AGENTS.md with evidence, limitations and production status.

## Execution record

- Initial production baseline: 4 checks, 3 failures (old cut margin, no cubes, no projected setback). First integration: 7/7 pass, then 45/45 behavioral checks.
- Independent review requested hint bounds at 480x320 and noted unnecessary solid reordering when cubes are absent. Expanded native checks reproduced a stale desktop hint minimum (1043.75 high) plus actor-order mutation. Saved red report/log as artifacts/excavation-game/review-before.*. Hint now applies one final rectangle and refits when minimum size settles; empty-block refresh preserves renderer order.
- Final integration: 62 checks, no failures, five sizes (1280x720, 844x390, 390x844, 480x320, 320x480), actual raid completed. Production captures inspected; exact geometry matches preview.
- Fresh regressions: cube capture337, projected recess fit2109, spacing12974, masonry7, direct dig308, rotation227, radial1836, mobile interactions all pass; seven headless probe recipes pass. Graphical runs were sequential. Final stderr logs empty and editor import exits0.
- Mobile fixture now disables persistence before entry, enabling it only for its pre-existing deliberate invalid artifact-path save-error test. Rotation fixture also disables persistence. Normal game persistence unchanged; no player saves read or written.
- Independent follow-up review: no actionable findings. No new art, APK, commit or push. Physical-phone profiling and exhaustive layouts remain outside this validation.
