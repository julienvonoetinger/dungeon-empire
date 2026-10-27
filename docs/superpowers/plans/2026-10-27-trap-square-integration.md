# Approved trap square integration plan

> **For agentic workers:** Use superpowers:executing-plans in the current session, task by task.

**Goal:** Apply the user-approved v11 larger square to all three painted traps.

**Architecture:** Freeze the approved geometry and render its complete rectangular stones with the existing calm floor material. Register the existing trap paints and raised surfaces to the enlarged footprint; retain the same runtime state handling and atlas page budget.

**Tech Stack:** Node/Sharp offline geometry and paint pipeline; native Godot captures.

**Spec:** `docs/reference/trap-review/v11-larger-square/geometry.json`, approved by the user with “voilà c'est correct” on 2026-10-27.

## Global constraints

- Opening .16..84, centred, side .68; z0; shared 2:1 camera; rectangular paving only.
- Preserve original paintings, v9/v10/v11 historical evidence and non-trap assets.
- No game rule, save format, player-save access or HUD layout changes; no commit/push.
- Preserve current uncommitted work on codex/2d-foundation. No checkout switch.

## Review focus

- Adjacent B floor variants: continuous joints/material at the logical cell boundary.
- Enlarged raised parts: no clipping, proportional dimensions, consistent state frames.
- Floor sockets: same positions in ready/triggered/spent; no duplicate raised parts.
- Repair/removal/pause/lethal raid end: existing state transitions remain intact.
- Atlas packing: preserve two unrelated pages and 136 regions; retain 2MiB trap page.

## Task 1 — Approved geometry and registered paint

Files: tools/isometric_trap_receiver.cjs, tools/isometric_trap_registration.cjs,
tools/isometric_painted_traps.cjs, tools/verify_trap_paving_geometry.cjs.

- [x] Freeze v11 hashes and snapshot current production metadata/sprites under v12.
- [x] Add and run a failing geometry check against the approved square and rectangles.
- [x] Replace the rejected collar with the approved complete stones and original material anchors.
- [x] Enlarge all trap XYZ geometry uniformly about the floor centre; derive a common padded mechanism frame and conservative scaled bounds. Keep original source pixels immutable.
- [x] Pass geometry, registration, and mechanism-frame checks.

## Task 2 — Export and native validation

Files: tools/verify_painted_traps.cjs; existing export, UI preparation and capture tools.

- [x] Export the kit and verify non-trap identity, floor border continuity and shared spike sockets.
- [x] Import and capture the nine-state scene and existing 11-state native harness to v12.
- [x] Inspect closeups with neighbours and actor overlaps; regenerate derived trap icons.
- [x] Complete a focused independent read-only review and resolve concrete defects.
- [x] Record evidence, limits and completion in v12 and AGENTS.md; show the native result.

## Execution ledger

- Setup: current branch codex/2d-foundation; v11 approval supplies the fixed geometry. Native execution continues the already authorized correction, without another approval step.
- Pre-flight: receiver supplies a base floor to all states; registration consumes the same approved opening. Captures and export checks use a new v12 output directory so previous evidence stays intact.
- Task 1: geometry RED (paint opening .22 instead of .16), then GREEN (12 approved rectangles; area .5376; 45 registration round trips). Uniform enlargement preserves XYZ proportions; all raised states use one derived padded frame.
- Task 2: initial export exposes small boundary finish differences on resized slabs (167 opaque pixels in the .06 boundary strip). Preserve the original finish inside .06 and blend to new finish by .07. The guard check rejected the first .10 width because the old right slab ends at .92; the final guard is narrower than that .08 distance. This addresses filtering continuity without restoring removed geometry.
- Task 2: final geometry/export checks pass. 136 other regions/two pages unchanged; 220428 identical border pixels; 2600 shared ground pixels; mechanism alpha stays outside a two-pixel frame margin. Trap page remains 512x1024/2MiB. Source PNG total 1843825 bytes; trap PNG 214176 bytes.
- Task 2: UI trap glyphs regenerated; Godot import and both GPU captures exit0/empty stderr. Native harness11 checks passed; nine-state overview, three neighbour closeups and actor insertion inspected. Reviewer dispatched read-only against this turn's saved baseline.
- Final review: independent reviewer found no actionable finding. Masked raised surfaces fit scaled bounds; the excess of unmasked mesh bounds is invisible. B3/B4's single boundary-pixel discrepancy from B1 is pre-existing. Artistic approval, exhaustive actor-depth validation, phone performance and full campaign remain outside the evidence; these are disclosed limits, not asserted passes. No deferred code findings. Final nine-state catalogue additionally inspected by author. No commit/push.
