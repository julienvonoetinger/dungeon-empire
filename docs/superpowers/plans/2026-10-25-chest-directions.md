# Chest directions implementation plan

> **For agentic workers:** Use superpowers:executing-plans for this authorized continuation.

**Goal:** Orient free and protected chests toward usable space instead of walls.

**Architecture:** Keep the accepted closed south painting unchanged. Correct the open south to retain its violet lock hardware, as subsequently requested, then generate three additional views per state. Uniformly prepare them with individual contacts and ambient shadows. Choose logical N/E/S/W at rebuild time through a focused presentation helper; no runtime rotations, mirroring or gameplay path changes.

**Tech Stack:** ImageGen native-alpha sources, offline Node/Sharp preparation, Godot atlas renderer.

**Spec:** User screenshot and request for angle variants, plus accepted ritual chest appearance and current small-coins variant.

## Constraints and decisions

- Work in the existing feature checkout with its uncommitted gameplay. No native UI control, tests, commit or push.
- Preserve original closed source and all120 architecture regions. User subsequently requested a25% size reduction: prepare every chest at72px body width at.75, with proportional shadows. Version corrected open sources and append direction entries.
- User explicitly confirmed the ORIGINAL metal chevron, after rejecting straight lip/tab revisions. Keep it on both states; the violet keyhole stays on the body, never duplicated on the lid.
- Logical south/front currently points screen lower-left. East points lower-right; north and west need rear views with hinges, not duplicated front locks.
- Exclude ROCK/outside, CORE, VAULT, stairs and intact doors from usable adjacent space. Score immediate usable cells by two-step clearance and lateral room; tie-break consistently S/E/N/W to favour readable fronts when access is equal.
- If no side is usable, fall back deterministically and expose that condition in diagnostics; do not move/delete the chest or claim a valid approach exists.
- Choose orientation from static layout, not hero position or camera. Recompute after layout/door-state changes; gold-only updates keep the same view.

## Review focus

Corners/borders, one-cell corridors, nearby heart/chests/closed doors, no-access vaults, reopening/rebuilding without orphan sprites, front/back artwork matching its logical direction, unchanged source hashes, mobile size and memory budget.

## Tasks

- [x] Preserve pre-change atlas/catalogue; create six new source views plus corrected south-open with exact prompts/provenance under v4-directions. Inspect front/back planes and contacts.
- [x] Add direction preparation/data to tools/isometric_treasure_chest.cjs; individual source guards, uniform scaling, bounds/shadows and direction metadata. Export catalogue/companion page.
- [x] Add scripts/game/chest_orientation.gd and use it in isometric_game_view.gd. Caption detection uses chest metadata rather than two hardcoded IDs. No economy/save-format change.
- [x] Headless import and13 static directional presentations, plus source/region integrity and small-scale offline comparison. No automated test suite or GPU/device claim.
- [x] One independent focused read-only review found no concrete issue. Final documentation/evidence saved; changes uncommitted.
