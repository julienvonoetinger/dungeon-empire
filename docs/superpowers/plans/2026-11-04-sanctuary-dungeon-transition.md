# Sanctuary to dungeon transition

2026-11-04 subsequent user correction: glowing portal rejected. The two-cell
wireframe and painted entrance were subsequently approved and are now animated
in runtime. Current implementation plan: 2026-11-04-physical-stairwell-transition.md.
Review/recipe: docs/reference/invocation-magic/stairwell-painted/README.txt.
The previously completed portal below is historical.

**Goal:** After the approved apparition, the master magically opens the mountain and enters the dungeon himself.

**Spec:** User's approved sequence in this chat, 2026-11-04. Earlier proposal of the invoker entering first is superseded.

**Architecture:** Retain the existing scene and explicit timeline. Carve a progressive rocky opening in the existing rear wall with a local shader, add soft magic and dust, turn and move the real rigged master toward it. Continue with the same master's viewport on the actual dungeon map before handing control to the existing lessons.

**Tech stack:** Godot GDScript/canvas shader, existing painted scenery and rigged GLB. No new raster painting or model required.

**Rulings:** Work in the existing dirty workspace, preserving all unrelated work. No commits, player saves, APK or new sound. Opening position/timing and camera framing are implementation choices. The invoker remains present for the existing tutorial dialogue; his travel choreography is a subsequent task, not a replacement for the master's entrance.

- [x] Add a regression for an absent opening before the end of the ritual, progressive opening, master movement/turn/occlusion, deterministic seek/reset and portrait coverage.
- [x] Implement opening and master departure after the approved first24seconds; preserve approved apparition, glyphs, gestures and kneeling.
- [x] Replace the old Oculin-only entrance shot with the master's entrance on the actual map, with a covered handoff and cleanup on skip/replay/lesson. Reuse the current invoker art for the stationary tutorial character.
- [x] Provide a full-transition preview using a game session with persistence disabled; validate the actual state handoff, pause/skip and several aspect ratios, inspect native captures and request one focused code review.

Review focus: early gate visibility, a sprite passing through uncut wall or menhirs, seam/frame during scene handoff, resize/replay restoring transforms, persistent viewport/actor after skipping.

User refinement: the Core starts as a pedestal only; its sphere appears after
the master reaches it. Existing offline pedestal renderer now accepts
includeVortex=false (default true unchanged). core-dormant.png has the identical
212x215 frame; original atlas remains unchanged. Shader blends the full base
and active Core with premultiplied alpha. Floor light follows awakening.
Entry reaches the Core at6.5s; awakening6.6–8.6s, lesson at9s.

Validation: first missing-gate regression fails, then transition, dungeon
handoff, original magic and procession fixtures all pass. Native stderr empty.
Three viewport sizes and the actual full preview were captured and inspected.
Evidence: artifacts/sanctuary-procession/final-*.log and corresponding captures.
Independent review caught double texture multiplication on the wall, stale
invoker during backward seek, hidden-film resize resetting the shared model,
invoker endpoint mismatch, and the Core's independent clock. All corrected and
covered. Native visual inspection also caught the master's missing solid z-layer
and the nested Core sprite escaping a direct-child-only update; corrected.

Preview: scenes/previews/SanctuaryTransition.tscn starts23.5s with Pause, Début,
Passage and seek controls. Persistence disabled before adding the game to tree.
Core animator uses manual time only for cinematics/preview; normal gameplay
restores its existing clock. Empty base recipe: tools/prepare_dormant_intro_core.cjs
(NODE_PATH=artifacts/sanctuary-textured/deps/node_modules for existing sharp).
No new audio or phone-device profiling. Invoker travel remains a later staging
step; current stationary tutorial portrait fades in beside the awakened Core.
