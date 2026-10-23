# Soft stone B implementation plan

> **For agentic workers:** Use superpowers:executing-plans for this approved appearance change.

**Goal:** Apply the user's approved B stone finish to the existing isolated and connected dungeon sprites.

**Architecture:** Reuse the accepted material library and offline face masks. A shared finish helper rounds only visible stone edges inside the unchanged structural silhouette. Godot continues to place finished PNGs.

**Tech stack:** Node.js, Sharp, SVG composition, Godot 4.

**Spec:** User approval “ok pour B”; `docs/reference/stone-edge-review/recipe.json` and `b-soft.png`.

## Global constraints

- B: radius 3.8, inset 0.55, unevenness 0.12, bevel 2.2 reference pixels.
- Same palette, source materials, projection, cell pitch, silhouettes and scene layouts.
- Floor fragments across a periodic boundary share the full stone and finish seed.
- An omitted internal connection edge must not acquire a new end bevel.
- Wood and metal keep their existing finish. No runtime generation.
- No new or executed tests without a user request. Use export diagnostics, import and visual captures for this asset task.
- Keep the approved comparison reproducible from frozen pre-promotion inputs.
- No commit/push requested for this change.

## Review focus

Periodic floor cuts; open wall ports; very narrow projected side faces; arch masks against wood; original comparison reproduction.

## Task 1: Shared finish and provenance

- [x] Freeze the comparison inputs and add the approved finish recipe.
- [x] Extract deterministic shape/finish helpers and integrate them in the offline renderer.
- [x] Retain construction-guide metadata while distinguishing softened visible joints.
- [x] Include new helper and recipe hashes in both export catalogs.

## Task 2: Promotion and visual delivery

- [x] Export all isolated and connected PNGs; retain their alpha and layout.
- [x] Import in Godot and capture representative rooms, doors, stairs and the six-room layout.
- [x] Inspect the resulting images and record any limits.
- [x] Update AGENTS.md and rendering documentation; request one final read-only code review.
