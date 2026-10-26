# Master mobile UI implementation plan

> For agentic workers: use superpowers:executing-plans. User has explicitly requested implementation of the reviewed PDF plus corrected header; proceed inline in the current project branch.

**Goal:** Replace the permanent Forge rail with the approved stone/vortex header, contextual construction and temporary mobile sheets.
**Architecture:** Native Godot Controls keep all commands in IsometricGameSession. A dedicated header renders live status; a bounded radial handles empty-cell construction; existing selection/transfer and guarded dialogs retain their behavior. The world fills the viewport at the unchanged fixed camera scale.
**Tech stack:** Godot 4.7, GDScript, existing isometric renderer, PNG painting and native vector utility glyphs.
**Spec:** User-supplied Dungeon Empire — refonte mobile v2 PDF and 24818.jpg header, reviewed in this chat. Screenshot supersedes missing PDF header.

## Global constraints
- Keep fixed .75 camera plus existing portrait compensation, free pan, all saves/economy/progression and approved dungeon sprites.
- World fills screen; only header/actions persist. Catalogue and contextual sheets retract.
- At least 48 logical units per touch target; safe areas and stretch compensation retained.
- Radial family directions fixed, only existing unlocked variants; costs and names outside fingertip.
- Keep armed tool through pan/invalid taps; explicit stop/Back. Occupied replacements retain confirmation.
- New replay/share, additional trap types, multihero raids and rewards are not part of UI migration.
- Main player save must not be read/written for validation. No commit/push unless requested.

## Review focus
1. Near screen edges radial targets stay reachable and first opening tap cannot accidentally purchase.
2. Input over HUD/sheets/modals never reaches the world; second touch/focus loss cancels pending gestures.
3. Portrait and short landscape keep labels/costs and catalogue families readable without resizing camera.
4. Paused/result/reset/save error states block edits, effects and correct countdown behavior.
5. Existing initial-heart, occupied confirmation, repairs, loot/body and exact chest transfers remain reachable.

### Task 1: Status band and fullscreen world
- [x] Record failing native baseline: world still reserved, no master header.
- [x] Add hud_master_header.gd with painted band, vortex and live life/time/gold, explicit phase text and passive progress strips.
- [x] Replace game_hud.gd rail composition with full world, header and compact utility controls; preserve guarded dialogs.
- [x] Inspect native 320x568,390x844,667x375,844x390 and1280x720 views.

### Task 2: Context construction and catalogue
- [x] Add hud_build_radial.gd, fixed family sectors, existing tool definitions, 48-unit targets and edge-safe positioning centered on selected cell.
- [x] Route world taps through HUD: empty unarmed cell opens radial, choosing valid tool places once then repeats; occupied cells keep details.
- [x] Catalogue has four fixed tabs, unlocked count, locked cards and scroll; chooses tool without spending. Add reachable repair action to object sheet.
- [x] Verify selection costs, repeated placement, invalid tap retention, pan, dismissal, pause guards and all four corners using isolated native harness.

### Task 3: Presentation feedback, verification and review
- [x] Isometric valid-cell highlights, optional access-path guide (explicitly not AI prediction), spend feedback and raid speed controls.
- [x] Capture native states, initial heart, transfers, raid, results, reset, defeat; verify parse/import and meaningful input/transaction checks.
- [x] Fresh read-only code review per executing-plans; resolve concrete findings, document limits and sources in AGENTS.md and review evidence.

## Execution ledger
- 2026-10-26: Current branch codex/2d-foundation clean at92dfc6a. Continue in user's project so their Godot scene reflects changes; no additional worktree or commit approval workflow.
- User authorized implementation; no repeat design/plan approval. Header art must be reconstructed from screenshot; retain exact extracted eye source where possible. New rendering is an adaptation, not a claim of pixel-exact reproduction.
- Ruling: PDF eye was flattened into a full-page raster. Two native-alpha ImageGen assets recreate the supplied header reference. Retain prompts/originals and uniform preparation. Eye has ten runes; dim segments and interior rotation are native shader effects. Cinzel is bundled under OFL, MSDF enabled.
- Ruling: four existing families have at most three unlocked variants today. Cap radial at five quick variants to retain 48-unit wedge thickness/arcs; Tout always reaches the complete family. Stable source order, no usage-based reshuffling.
- Ruling: keep a labelled Pause utility alongside Catalogue/Accès/Annuler for discoverability. Access overlay shows reachable cells, not a deterministic hero trajectory. No extra hero count or synthetic best-trap/replay statistics.
- Ruling: at short landscape heights move radial footer beside rings (420x208 footprint), header84 high; regular radial260x256/header96. Tests cover568x320 and568x299 useful area. Do not shrink touch targets.
- Review: independent reviewer identified hidden save-write failures, possible canceled multitouch rearming, non-MSDF display font and short-landscape radial clipping. Each behavioral issue reproduced before correction; native font issue visually observed then MSDF corrected. Final check reports zero failures.
- Testing note: real viewport input uses push_input(event,true) because parse_input_event remaps window coordinates through stretch; the original pan test incorrectly supplied viewport coordinates to that remapper. Correcting the harness demonstrates real pan without spend.
