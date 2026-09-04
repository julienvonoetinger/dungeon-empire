# Godot project structure

Use this file when adding features or scenes. It is the project rule for how code and assets are split.

Godot treats **scenes as classes**. A scene is a reusable object (node tree + script + default connections). Scripts should have **one job**. Nodes talk through **signals**, not by reaching into siblings’ internals. Autoloads are only for true globals (save slot, audio), never for the dungeon grid or raid AI.

## Layout

```text
docs/                          standing project rules (this file)
scenes/game/                   play session / orchestrator scenes
scenes/hud/                    toolbar, overlays
scenes/world/                  3D dungeon view
scripts/game/                  rules: types, sim, raid
scripts/hud/                   HUD scripts
scripts/world/                 DungeonWorld and view helpers
assets/models|sprites|...      shipped runtime art
production/                    generation sources, not gameplay code
tests/                         headless harnesses
```

Keep a scene next to the art it owns when a feature grows its own folder (`scenes/traps/void/`). Until then, shared models stay under `assets/models/`.

`Main.tscn` may remain at the project root as the run scene. New gameplay scenes go under `scenes/`.

## Responsibilities

| Unit | Owns | Does not own |
|---|---|---|
| `GameTypes` | `Tile` / `Tool` enums, costs, grid size, colors, traits | Simulation or drawing |
| `DungeonSim` | Grid, gold, vaults, doors, traps, build/repair | Hero AI, camera, HUD |
| `RaidDirector` | Hero, raid timer, pathing, trap triggers, portal | Toolbar layout |
| `Toolbar` | Tool buttons and their layout | Grid writes (emits `tool_chosen`) |
| `DungeonWorld` | 3D meshes, lights, picking math | Game rules |
| `Main` (`DungeonGame`) | Wiring, camera chrome, HUD paint, input routing | New rules (put those on sim/raid) |

`Main` is a **conductor**. After a sim or raid change it calls `dungeon.sync(self)` and `queue_redraw()`.

## Where to put a new feature

1. **New tile, cost, or tool** — `scripts/game/game_types.gd`, then sim placement and world mesh.
2. **Build/repair/storage rule** — `DungeonSim`.
3. **Hero behaviour during a raid** — `RaidDirector`.
4. **Something the player clicks in the toolbar** — `Toolbar` signal → `Main` → sim or raid.
5. **How a tile looks in 3D** — `DungeonWorld` only.
6. **Headless proof** — extend `tests/smoke.gd` (or a focused test next to it).

Do not add another 200-line function onto `Main.gd` because the file is already open.

## Communication

- Prefer `signal` from HUD and world toward `Main`.
- `DungeonWorld.sync(game)` may read sim/raid state through the game facade (`grid`, `hero`, `Tile`, …) so the view stays a renderer.
- Do not copy enums into a second file. Import `GameTypes` (or the facade aliases on `DungeonGame`).

## Size rule

A script that mixes unrelated change rates (button pixels vs A* costs) should be split. File length alone is not the trigger; **who needs the data** is.

## Tests

Smoke tests may keep using the `Main` facade (`m.grid`, `m.Tile`, `m._new_map()`). New logic should still be reachable from that facade so the harness stays one entry point until a dedicated sim test exists.
