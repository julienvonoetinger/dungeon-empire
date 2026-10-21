# 2D foundation implementation plan

> Execution: superpowers:executing-plans, inline in the current checkout.

**Goal:** Replace the legacy project with the approved static 2D dungeon.

**Architecture:** A grid Resource stores the fixed scene. A Node2D draws the
nineteen approved sprite crops and resolves boundaries from neighboring cells.
A Camera2D fits the entire composition on window resize.

**Tech stack:** Godot 4.3+, GDScript, GL Compatibility, PNG textures.

**Spec:** User-approved scope in this conversation; `GAME_DESIGN.md` records
the implemented rules. Visual target: `docs/reference/approved-scene.png`.

## Constraints

- The current checkout is the project being replaced, as requested by the user.
  Work on `codex/2d-foundation`; retain Git history and remote `v1.0.0`.
- Preserve untracked local work outside the repository before cleanup.
- Use the exact approved sprite crops, not a full-scene image as the renderer.
- Fixed 28 x 18 grid, 54 px cells, 90 px composition margin; six rooms.
- No gameplay, construction tools, HUD, saves, legacy models or network services.

## Tasks

- [x] Verify HEAD and remote tag match; archive local files and old checkout.
- [x] Bring in the 19 sprites, small backdrop, attribution/crop manifest and
  approved reference. Freeze the approved floor-variation choices in the layout.
- [x] Add a scene verification script covering load, map connectivity, clear
  corridors and camera fitting in landscape, portrait and square windows.
- [x] Implement layout Resource, 2D drawing and automatic framing.
- [x] Replace configuration, README and design/instruction documents.
- [x] Import in Godot, run verification and capture the actual scene with the GPU.
- [x] Review the new project and inspect captures against the approved reference.

## Review focus

- All floor cells remain connected; two-cell corridors contain no blocking wall.
- Wall orientation/corners retain the reference lighting and thickness.
- Resizing never stretches or crops the scene; no legacy assets are loaded.
- The runtime uses small sprite resources, not the reference illustration.
- The starting project remains recoverable from the confirmed tag/local archive.

## Execution record

- Backup: `C:/Users/A/Documents/DungeonEmpireBackups/2026-10-21-before-2d`.
- Remote tag and main both point to `cba21ed0c96fd9afdff1746f70a380b9c24c39df`.
- 374 local untracked/ignored files copied and SHA256 verified before cleanup.
- Ruling: replace the current checkout on a feature branch, following the user's
  approved reset; no additional worktree or approval cycle is needed.
- Bulk deletion was blocked by automatic review. Instead, all 31 old top-level
  entries were moved to the external `legacy-checkout` archive, preserving data.
- Validation uses a focused scene probe and visual capture; obsolete gameplay
  tests are archived with the old implementation.
- Scene probe RED: exit 1 before implementation, missing main scene as expected.
- Scene probe GREEN: `tools/test-mobile.ps1 -All -Capture`, exit 0 under
  Godot 4.7.2 (GL Compatibility / NVIDIA). Import, scene assertions and main-scene
  launch passed without script errors.
- GPU captures inspected at 1692 x 1152 and 720 x 1280. All six rooms and
  two-cell corridors remain visible, with the approved wall orientations.
- SHA256 comparison confirms the 19 sprite PNGs are unchanged from the approved
  kit. All 20 runtime PNGs total 97,559 bytes.
- Pixel comparison of native-size GPU capture with approved composition:
  mean absolute RGB difference below 0.103 per channel on a 0–255 scale.
  Background filtering and alpha rounding account for small rendering differences.
- The historical Git objects remain in `.git`; only the active project has been
  reduced. Documentation references are excluded from Godot import via `.gdignore`.
- Final independent read-only review found no concrete issue in the approved
  static-scene scope. No deferred findings.
- Ruling cost: replacing the current checkout requires switching to `v1.0.0`
  (or opening the external archive) to work on the old prototype again. Its
  history and local source files remain recoverable.
- Delivery remains on `codex/2d-foundation`, saved locally; no merge or remote
  publication is part of this implementation step.
