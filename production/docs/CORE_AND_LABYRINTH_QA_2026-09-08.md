# Core anomaly and labyrinth integration — 8 September 2026

## Core

The living core now combines an unlit, fog-independent black sphere, a thin
animated violet halo, and seven independently drifting stones. The stones were
extracted from connected components of the existing Meshy `core_void_nexus.glb`
by `tools/extract_core_fragments.gd`, retaining original UVs and normals. Their
small mesh resources share the existing source textures. No new Meshy job was
needed for the core.

The original pedestal is shortened and its upper geometry masked by a shader;
its material is matte and desaturated. Its lower bound is aligned to the
finished floor at Y=0.175; the void, halo and fragments share the same 0.045
vertical lift so the complete composition rests on the paving instead of
sinking into it. Health changes update the same anomaly
without restarting its orbit. At zero HP the void and halo disappear,
the fragments settle, and the violet light switches off.

## Labyrinth scenario

`tests/labyrinth_integration_test.gd` builds a winding route with two branches,
20 excavated cells, one entrance, a corridor door, and spike, snare and void
traps. Construction uses the real build rules and costs 250 of the initial
320 gold. Repairing all seven consumed trap charges costs the remaining 70.
The scenario runs in a separate game instance; it does not modify a live run.

Checks cover:

- Entry through the stair mouth and construction locked during a raid.
- Armed, triggered (including the last charge), depleted and repaired models.
- Spike damage, snare damage and movement delay, harmless void banishment.
- Depleted traps cause no damage; banishment ends the raid without a corpse.
- Trap geometry stays within its cell, with recessed plinths and visible mechanisms.
- Twelve seeded natural raids using all three adventurer archetypes. Every
  trap was encountered, the door was broken, no hero crossed a wall, and all
  raids terminated.

Controlled arrivals exercise each state through the real resolver; the twelve
additional natural raids exercise autonomous path choice without teleporting
the hero. This is a scripted engine integration test, not manual GUI clicking.

## Defects found and corrected

1. Trap bases overlapped the floor. Raising the whole base made traps look
   placed on top of the paving. Their plate surfaces now align with Y=0.16,
   using model-specific plinth depths (including the raised snare variant).
   Trap cells replace the stone relief and lower the backing floor to Y=-0.02,
   so mechanisms remain visible without stacking two slabs. Removing a trap
   restores the normal floor even when the excavated cells have not changed.
2. A last spike/snare charge immediately selected the broken model, skipping
   its activation. The triggered model now remains while the hero occupies the
   triggered cell, until departure or raid termination.
3. Core health originally refreshed only at HP-band boundaries, recreating its
   fragments and resetting the orbit. HP now updates the existing presentation.
4. Five procedural emissive strips extended beyond the pedestal and appeared as
   straight violet lines over the surrounding floor. They were removed; the
   animated halo, pedestal material and floating fragments retain the living
   core's supernatural energy without projecting geometry onto floor tiles.

## Reproduce

### Stone trap redesign

The world uses the detailed original Meshy trap families in armed, sprung and
broken states. Each model replaces one complete floor cell and its upper base
surface is sunk flush with the matching 1x1 production floor modules. See
`MESHY_STONE_TRAPS_2026-09-08.md` for the rejected stone-matching prototype,
the final integration and acceptance criteria.

`tests/meshy_stone_traps_test.gd` loads every real GLB, checks the fitted
footprint and paving height, cycles all states, and verifies that repair restores
the original armed transform. The labyrinth test checks the presentations
against actual charge consumption and raid transitions.

Run Godot with `--headless --path . --script res://tests/labyrinth_integration_test.gd`.
For screenshots, omit `--headless` and append `-- --capture`. Captures cover the
whole maze, entrance, and individual trap states in `artifacts/`. The text
summary is `artifacts/labyrinth_test_report.txt`.

The labyrinth test, core component and health integration tests, gameplay smoke
test, lighting test, floor clipping test and wall pairing test passed. Existing
Godot warnings about SubViewport sizing, exit-time resource cleanup and this
sandbox's user-directory/certificate access remain outside these changes.
