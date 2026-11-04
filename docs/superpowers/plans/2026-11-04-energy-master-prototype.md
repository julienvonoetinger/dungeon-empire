# Energy master prototype implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline. No commits or gameplay integration are authorized in this prototype.

**Goal:** Show the approved black-hole/vortex eye as a moving volumetric entity in an isolated Godot scene.

**Architecture:** A procedural Node3D builds a black sphere, curved iris, tilted accretion ribbons, eye arcs and sparse motes. A single explicit clock controls shaders and geometry. A separate Control preview owns the SubViewport, camera and playback controls.

**Tech stack:** Godot 4.7 GL Compatibility, GDScript, spatial shaders; no dependencies or generated textures.

**Spec:** User approved an isolated animated prototype of the concept in `docs/reference/dungeon-master-review/v3-vortex-eye/`, before sanctuary integration.

## Constraints and review focus

- Existing HUD eye, introduction, sanctuary, game session, saves and assets stay unchanged.
- No Meshy calls, no flattened concept painting as the animated entity.
- Front and rear energy must genuinely surround and be occluded by the core.
- Pause and seeking use one clock; shaders must not use TIME.
- Controls and phenomenon must fit landscape and portrait.
- Work alongside existing local changes in additive isolated files; no worktree migration of unrelated uncommitted assets.

## Tasks

- [x] Create a native fixture with an absent-scene negative control (exit 1, missing scene reported).
- [x] Implement `scripts/previews/energy_master.gd` and `shaders/energy_master.gdshader` with `present(time, attention, manifestation)`.
- [x] Implement `scripts/previews/energy_master_preview.gd` and `scenes/previews/EnergyMasterPreview.tscn`, isolated from gameplay.
- [x] Verify import/GPU shader compilation, deterministic seek/pause, visible change over time, viewport layouts and real depth from several camera angles.
- [x] Inspect native captures, review implementation and fix significant findings, document limits, open the playable preview.

## Execution record

Prototype only; no production integration. Automated checks are limited to playback behavior and rendering/layout failures; artistic judgement uses native captures.

Final: native fixture zero failures, no import/check/capture errors. Reviewer found no important issue. Captures at three aspect ratios plus orbit inspected. 24-second native WebP timing verified. Interactive window launched. Ruling: use an opaque matching preview background because additive energy was attenuated twice through the transparent SubViewport; transparent sanctuary composition remains future work. Phone performance and exact painted-concept fidelity remain unvalidated.
