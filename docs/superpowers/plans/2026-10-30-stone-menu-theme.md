# Stone Menu Theme Implementation Plan

> Execution: inline using superpowers:executing-plans. User approved v18 and
> requests the same direction throughout the menus; no further design gate.

**Goal:** Apply the approved painted slate/violet radial direction to the live
radial, catalog, selection/transfer, pause/results and utility controls.

**Architecture:** Preserve existing containers, input paths and geometry. Share
small ImageGen stone textures through hud_theme.gd. Use textured polygons for
variable radial sectors, independent native text/icons and inset price sockets.

**Tech Stack:** Godot GDScript/StyleBoxTexture, existing Sharp preparation tools.

**Spec:** ../../reference/interface-review/v18-radial-stone/README.md and its
proposal.png, approved by user 2026-10-30; extend visual language to other menus.

## Constraints and review focus

- English UI, central Close, live costs, minimum48 touch targets unchanged.
- Existing header, world art, gameplay and save schema unchanged.
- No player-save access, APK, commit or push.
- Keep small-screen layout/padding; do not add panel size for decoration.
- Verify selected/disabled states remain distinguishable, 1–5 radial sectors,
  transparent corners, full-button hit targets, short landscape and portrait.

## Task1 — Reusable painted surfaces and shared menu theme

- [x] Generate blank rectangular and round stone surfaces with ImageGen using
  approved header/v18 references. Preserve source/prompts in v19-stone-menus.
- [x] Create tools/prepare_stone_ui.cjs for crop/uniform resize, hashes and
  exported assets/ui/master/stone-menu textures. No pixel repaint or new deps.
- [x] Adapt hud_theme.gd surface/command_surface and add round_surface; replace
  StyleBoxFlat-specific consumers in tile and radial. Keep content margins.
- [x] Native import and existing mobile interactions/rotation checks.

## Task2 — Radial stone sectors and native visual validation

- [x] Paint variable sectors with shared stone face, recessed seams/bevels,
  inset price sockets and violet active state; keep hit geometry/price logic.
- [x] Adapt radial pixel assertion from the superseded gold state to the
  approved violet state; retain transaction/touch/Close assertions.
- [x] Run radial, mobile interactions, rotation and header health checks
  sequentially. Inspect captures on small portrait and short landscape.
- [x] Capture all menu states with persistence disabled using reusable fixture;
  check text bounds and publish native comparison page under v19-stone-menus.
- [x] Focused review, document asset sizes/results/limits in README and AGENTS.

## Ledger

- Baseline f0dc3289; pending central-Close implementation and v18 proposal are
  intentionally preserved. Work remains in the user's existing checkout.
- Existing layout/interaction suites are reused; do not write tests that merely
  repeat texture filenames or artistic choices.

- Completed: native interaction/radial1594/rotation227/health32 pass;133 captures/7sizes without nonwrapping-label overflow. Independent focused review clean.
- Ruling: use a separate horizontal button source and quiet face crop to avoid distorted texture grain and oversized bevels behind icons; shared output remains0.75MiB RGBA.
- No commit/push: those remain separate user requests.
