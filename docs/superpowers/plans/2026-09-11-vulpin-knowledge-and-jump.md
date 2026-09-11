# Vulpin Knowledge and Trap Jump Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax for tracking.

**Goal:** Share discovered dungeon information between living heroes, make Vulpins thief-specific, and render their known-trap jump.

**Architecture:** `RaidDirector` stores a per-dungeon `kingdom_knowledge` map. Each hero copies that map on entry and merges discoveries only after a living exit. Vulpin interaction state is exposed through hero flags and selected by `VulpinHero` in `DungeonWorld`.

**Tech Stack:** Godot 4.7, GDScript, GLB animation assets, headless GDScript tests.

**Spec:** `docs/superpowers/specs/2026-09-11-hero-knowledge-design.md`

## Global Constraints

- Shared knowledge contains only perceived cells.
- Death and void absorption transmit nothing.
- A Vulpin jumps only one known intact trap; a trap on its landing cell resolves normally.
- The Paladin targets only the Core; the Vulpin never damages it.
- A Paladin forcing a door uses the attack animation and applies door damage
  only at that animation's impact.
- Run the smoke, Vulpin world, and Lithide hero tests before completion.

---

### Task 1: Shared knowledge lifecycle

**Files:**
- Modify: `scripts/game/raid_director.gd`
- Modify: `scripts/Main.gd`
- Test: `tests/smoke.gd`

**Interfaces:**
- Produces `kingdom_knowledge: Dictionary`.
- Produces `invalidate_kingdom_knowledge(cell: Vector2i) -> void`.
- Produces `merge_hero_knowledge_if_alive() -> void`.

- [ ] Write failing smoke checks: a living exit shares a known Core, Vault and Spike; a dead hero does not; invalidating one changed cell preserves other entries.
- [ ] Run `godot.windows.opt.tools.64.exe --headless --path . --script tests/smoke.gd` and confirm those checks fail.
- [ ] Initialize `kingdom_knowledge` when resetting a map; copy it into `hero["known"]` in `_start_raid()`; merge `hero["known"]` in `_finish_town_portal()` before ending the raid; never merge in `_kill_hero()` or `_banish_via_void()`.
- [ ] Call `invalidate_kingdom_knowledge(cell)` from every player operation in `Main.gd` that changes terrain, door, trap or vault state.
- [ ] Re-run the smoke test and confirm it passes.

### Task 2: Objectives and interactions

**Files:**
- Modify: `scripts/game/game_types.gd`
- Modify: `scripts/game/raid_director.gd`
- Test: `tests/smoke.gd`

**Interfaces:**
- Produces hero flags `lockpicking`, `lockpick_t`, `jumping_trap`, and `jump_t`.
- Produces `_can_vulpin_jump_trap(from: Vector2i, trap: Vector2i) -> bool`.

- [ ] Write failing checks that a thief on the Core leaves `core_hp` unchanged; a Paladin ignores known Vault targets; a Vulpin lockpicks a known intact door; only the first of two adjacent known traps is skipped; and a Paladin keeps door HP unchanged until its attack impact.
- [ ] Run the smoke test and confirm the new assertions fail.
- [ ] Make Vulpins target only Vaults and exploration, never `_hero_reaches_core()`. Make Paladins target only the Core and ignore Vaults.
- [ ] Add Vulpin lockpick timing that opens an intact door without force damage. Retain lower Paladin physical-trap damage while giving the Vulpin a higher named trap-damage constant; lower Paladin door-force damage below the Vulpin's effective lockpick result. Add a Paladin `door_striking` timer matching the attack-impact timing, then apply one door hit only when that timer reaches the impact.
- [ ] Before normal movement, permit a Vulpin to move across one known intact trap only if its landing cell is in bounds and not another trap. Set `jumping_trap` during the jump. Resolve the landing cell normally.
- [ ] Re-run the smoke test and confirm it passes.

### Task 3: Jump animation and design source

**Files:**
- Create: `assets/models/characters/vulpin/hero_vulpin_jump_trap.glb`
- Modify: `scripts/world/vulpin_hero.gd`
- Modify: `scripts/world/dungeon_world.gd`
- Modify: `GAME_DESIGN.md`
- Test: `tests/vulpin_world_test.gd`

**Interfaces:**
- Produces `VulpinHero.set_jumping(value: bool) -> void`.
- Consumes `game.hero["jumping_trap"]` in `DungeonWorld._sync_hero()`.
- Consumes `game.hero["door_striking"]` in `DungeonWorld._sync_hero()` and
  forwards it to `LithideHero.set_attacking()`.

- [ ] Write a failing world test that sets `jumping_trap`, synchronizes the world, and expects a visible `JumpTrap` node with a playing clip containing `jump`.
- [ ] Run `godot.windows.opt.tools.64.exe --headless --path . --script tests/vulpin_world_test.gd` and confirm it fails.
- [ ] Copy the supplied jump GLB to `hero_vulpin_jump_trap.glb`, import it with Godot, then add a mutually exclusive `JumpTrap` model and `set_jumping()` method to `VulpinHero`.
- [ ] Send `jumping_trap` from `DungeonWorld._sync_hero()` after running and collecting state have been applied.
- [ ] Send `door_striking` from `DungeonWorld._sync_hero()` to the Lithide
  controller so a Paladin forcing a door displays its existing attack clip.
- [ ] Update `GAME_DESIGN.md` sections 8, 9, 10, 11 and 23 with survivor knowledge, class objectives, lockpick, trap resistance and the one-trap jump rule.
- [ ] Run smoke, Vulpin world and Lithide hero tests; all must report `OK`.
