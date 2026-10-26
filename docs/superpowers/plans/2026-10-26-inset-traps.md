# Inset traps implementation plan

> **For agentic workers:** Use superpowers:executing-plans, inline in the existing checkout. No commit or push in this task.

**Goal:** Replace the provisional Pointes, Entrave and Néant ground symbols with traps seated inside the approved floor opening.
**Architecture:** Shared frozen XYZ socket geometry and existing floor paint. Offline depth raster creates a floor replacement and a separately ordered raised mechanism. Six floor states and two raised mechanisms live on a compact companion atlas. Runtime chooses ready/spent from existing charges.
**Tech stack:** Node/sharp preparation, Godot 4 native Sprite2D and existing support ordering.
**Spec:** User-approved `docs/reference/trap-review/v2-inset-floor/wireframe-board.png` and its `geometry.json`; latest user approval supersedes the old proposal status in the immutable snapshot.

## Constraints
- Opening .22..78; inner .235..765; insert z=-.025; 2:1 shared camera; floor z=0. Only mechanism parts project above ground.
- Keep surrounding periodic floor material, original architecture/chest regions, UI, rules, save format and fixed .75 camera.
- No player save access, commit or push. Preserve unrelated work in the current codex/2d-foundation checkout; transferring its extensive uncommitted work would be inappropriate.
- Ready/spent are static presentation states, not a new trigger animation or changed game rule.

## Review focus
- Normal paving/damage must not cover the socket.
- Last charge, repair, deletion and restoration update art and badge consistently.
- Raised mechanism and actor retain independent physical ordering; ring remains readable over walls.
- Added atlas page resolves correctly in resource and JSON loaders, without altering previous atlas pixels.
- Native capture is isolated from player saves; whole raid/device validation is not implied.

## Tasks
1. Freeze approval hashes and previous atlas baseline. Create an isolated Godot capture/check for missing prepared traps and run it before implementation.
2. Implement `tools/isometric_inset_traps.cjs`: approved opening, shared floor paint, nine spikes, toothed iron snare, recessed violet seal; spent variants. Export via a third atlas page, keeping existing pages intact. Verify geometry and baseline hashes.
3. Add `floor_replacements` and `mechanisms` plan inputs to renderer; map actual traps in game view. Remove provisional ground marker, keep charge ring. Switch only on ready/spent boundary; no per-charge scene rebuild required.
4. Run import and isolated native capture/check for all three traps, zero charges, partial charges, repair/restoration, actor overlap and removal. Inspect mobile/close views, request one focused read-only review, fix concrete findings. Record evidence and limitations.

## Progress / rulings
- Setup: existing checkout retained to preserve the already-authorized uncommitted assets and gameplay work. No gameplay tests for cosmetic geometry; the isolated native capture checks actual state transitions and ordering.
- Complete: frozen wireframe hashes in selection.json. Readiness is derived in the game view; no session structure hash or gameplay file change. Depleted mechanics hide, floor swaps retain frame/size, partial charge changes retain nodes.
- Red: isolated capture failed on the three missing prepared floors before implementation (`artifacts/trap-red.err`). Green: native GPU capture exits 0 with empty stderr, eight states including missing-charge defaults, initial spent rebuild, sim repair, partial charge, actor and removal. Renderer sprites checked for unwanted floor/damage overlay and mechanism visibility.
- Export verification: 136 prior entries and two PNG atlas files unchanged; 174960 surrounding-paving pixels checked unchanged. Added eight regions on 512x512 page, 106068 PNG bytes / 1 MiB RGBA; total 10 MiB RGBA.
- One focused independent code review found no concrete actionable bug. Exact actor occlusion is supported by native screenshot/code inspection, not an automated pixel oracle. No full raid or physical mobile validation, no user save access, no commit/push.
- Initial offscreen capture used a 64px root window that inflated DPI-dependent rings; corrected the capture harness to 1280x720 and refreshed badges after camera changes. Production HUD untouched.
