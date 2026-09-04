# Dungeon Empire — Godot Prototype v0.2

Godot 4.x prototype built to test the core loop of the dungeon builder.

## What this version brings
- two clear phases: **Preparation** and **Raid**;
- during a raid the player can **not** build, move, repair or collect anything;
- the dungeon persists from one raid to the next;
- 3 adventurer archetypes: Vulpin Thief, Lithide Paladin, Batrafian Ranger;
- destructible doors with HP, repairable only during preparation;
- a hero's death slightly regenerates the Dungeon Core;
- persistent corpses: they change the perceived danger of a path;
- loot left where a hero died: a later adventurer can pick it up;
- dungeon wealth exists only in storages (150 gold each); the run starts with vaults around the Core holding the treasury;
- dead heroes leave loot on the body until you store it — it stays there if storage is full;
- after a raid the player can click a loot bag to move gold into storage (if there is room);
- after a raid the player can absorb a corpse (+2 Core) or leave it to influence future raids;
- an intact door **blocks**: it has to be broken before passing through;
- traps have limited charges: a spent defense stays inert until repaired;
- a thief carries away only what fits in its bag, then teleports out — the rest of the hoard stays;
- a badly wounded hero, or one that has explored enough, flees to the entrance with whatever it carries;
- every hero rolls its own personality (Greedy, Cautious, Stubborn, Cowardly) and its own weights, so no layout stays solved;
- AI still based on partial exploration + memory + probabilistic scoring;
- end-of-raid report (killed, escaped, gold stolen, doors destroyed, charges spent, Core);
- Core at 0 = campaign lost, no further raid starts;
- no offline simulation: while the application is closed, no raid advances.

## Controls
During the preparation phase:
- **Dig**: turns rock adjacent to an existing passage into a passage (5 gold), or clears a structure;
- **Storage** (60 gold): holds the dungeon's wealth, the Vulpin's favourite target;
- **Spikes** (35 gold): direct damage, 3 charges;
- **Snare** (30 gold): damage + slowdown, 3 charges;
- **Door** (40 gold): destructible obstacle that blocks the way;
- **Repair**: restores damaged doors (15 gold) and trap charges (10 gold);
- **Absorb corpse**: dedicated tool; clicking a corpse consumes it and heals the Core by 2 points;
- **Reset**: asks for confirmation (second click) before wiping the run;
- clicking a **yellow loot bag**: moves its gold into storage if there is room;

During a raid the whole dungeon is locked: you only watch the outcome of your preparation. The hero's trait is shown above it; its internal weights are never displayed.

Placeholder colors come from `art_bible/palette/COLOR_PALETTE.md`, so the prototype already reads on-brand.

## Running
1. Install Godot 4.x.
2. Open this folder as a Godot project.
3. Run the project (F6/F5).

## Project structure

Gameplay code is split so `Main` only wires systems. Follow `docs/GODOT_PROJECT_STRUCTURE.md` when adding features (`GameTypes`, `DungeonSim`, `RaidDirector`, HUD, `DungeonWorld`).

## Quick verification
A headless harness simulates building, raids, deaths, thefts, wear and defeat:

```
godot --headless --path . --script res://tests/smoke.gd
```

It prints `OK: all checks pass.` and returns 0 when everything is fine.

## Deliberately out of scope
No world map, kingdoms, multiple dungeons, floors, expansion sanctum, save/cloud, adventuring parties or final art yet. The goal is still to test whether building the labyrinth and watching the behaviours are fun.
