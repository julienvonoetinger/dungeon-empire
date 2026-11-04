# Physical stairwell transition implementation plan

> Execute inline using superpowers:executing-plans. User has approved the painted two-cell entrance and requested the next animation stage.

**Goal:** Replace the rejected portal with a broken rock, revealed physical stairwell and master descent, continuing into the existing dormant-Core arrival.
**Architecture:** Retain the accepted first 24 seconds and explicit film clock. Promote the approved entrance bytes; partition foreground masonry for physical occlusion. A dedicated passage controller fractures the original rock into textured pieces, reveals the stairs, and provides the ground trajectory. Film handles camera, rig and depth placement.
**Tech stack:** Godot GDScript/canvas shaders, existing native painted sprites and rigged master, Node/sharp offline layer extraction.
**Spec:** Approved sequence and staircase in this chat; wireframe and painted recipes under docs/reference/invocation-magic.

Constraints: no portal/ring; no new scene at start; first step at ground height, ten regular treads in two cells; original ritual and Core timing unchanged. One seekable/pausable clock; no player saves, APK, commits or push. Existing dirty workspace retained because all approved sources and runtime work are here.

Review focus: entrance before destruction; replay restoring the rock/shadow; master crossing foreground masonry; portrait framing during travel; shared viewport and dormant Core at handoff.

- [x] Add a failing native physical-entry regression and preserve old portal implementation as historical evidence.
- [x] Prepare production entrance plus foreground masonry from original painted bytes, keeping frame/scale and geometry. Move approved neighbouring rocks and their shadows consistently.
- [x] Replace passage effects with deterministic textured fragments, dust and magic revealing the stairwell. Route a compacted master over the approach then down the actual stair axis; pan camera and sort/clamp under masonry.
- [x] Verify native ritual/physical entry/dungeon handoff at three sizes, inspect frames and seek/pause/replay. Focused independent review, fix important findings, launch full preview.

Ruling: use fixed 35.4-second film duration. Rock breaks 26–28.2s, stair reveal 27–29s, approach 28.8–31s, descent 31–33.2s, tunnel entry through34s. The energy creature contracts before travel to fit the approved architecture; no perspective-based shrinking during the stair descent.

Execution ledger: absent physical-entry test failed first. Native physical,
procession, magic, transition and dungeon handoff suites passed. Visual review
caught multichannel mask indexing and early arch clipping; masks are now one
channel and the arch is separate from the near rail. Native solid-colour probe
verifies the projected foreground ground clips underground pixels and inactive
occlusion preserves all actor alpha. Reviewer independently verified unchanged
approved art, masks, replay, shared-viewport handling and near-ground equation.
Final fresh native physical/transition/handoff checks pass, empty stderr.
Three-size captures inspected, including underground travel and delayed Core
awakening. Full preview launched for user review; no unresolved review finding.
