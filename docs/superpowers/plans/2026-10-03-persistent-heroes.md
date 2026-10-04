# Persistent Heroes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let individual surviving heroes gain expedition XP and return at higher levels, with permanent death and no consecutive visits by one individual.

**Architecture:** A HeroRoster owns durable profiles, selection and XP accounting. RaidDirector retains transient actions and reports successful events, then commits one terminal outcome. MobileSave validates roster data before applying a save; existing UI presents identity and progression.

**Tech Stack:** Godot 4 / GDScript, existing SceneTree tests and node probes, PowerShell test runner. No new dependency.

**Spec:** `docs/superpowers/specs/2026-10-03-persistent-heroes-design.md` (approved 2026-10-03).

## Execution Record

Implemented in the existing worktree on 2026-10-03, all six tasks complete.
RED-to-GREEN evidence: missing roster, missing spawn integration, missing XP,
missing save field, then six missing UI assertions; each focused suite passed
after implementation. Final full suite: 87/87 after all corrections. Native
Vulkan Vulpin sequence and landscape/portrait UI probes report zero failures;
captures are in artifacts/hero-progression-1280.png and -720.png.
Independent review by Leibniz found permissive class-stat validation (corrected
after eight failing regression assertions) and a stale scope sentence (corrected).
No deferred findings. The existing optional-save-field test was updated to accept
legacy saves without a roster. Delayed-death coverage enters through the actual
arrival resolver before advancing its animation, rather than setting HP alone.
Product changes left uncommitted, with no push and no real user save modified.

## Global Constraints

- New recruits start at level 1 with zero XP.
- Death is permanent: a dead individual can never be selected again.
- XP is awarded only when departure alive actually completes, not when its animation starts.
- Cost to advance from level L to L+1 is 50 * L XP.
- Returning heroes arrive at full HP. Their rolled base stats and personality stay fixed.
- No new HP, damage, movement or class-skill scaling in this change.
- Void banishment preserves existing behavior: departure alive with carried loot.
- Keep the current pre-raid checkpoint model; do not implement mid-raid saves.
- Preserve all unrelated dirty-worktree changes and existing game save files.
- Work in `C:/Users/A/.codex/worktrees/mobile-25d/dungeon-empire`, the current feature worktree. Do not accidentally edit the other checkout.
- Update GAME_DESIGN.md section 0 alongside implemented rules, not ahead of code.

## Review Focus

1. Only eligible survivor is the last visitor: recruit without rerolling forever (Task 2).
2. Callback duplication or delayed death animation: one terminal award, never XP for death (Task 3).
3. Shared map memory and discovery beyond cap: no unearned XP or deferred overflow farming (Task 3).
4. Corrupt roster appended to a valid save: reject before mutating any live state (Task 4).
5. Long personal names and multi-digit levels: compact badge and result remain readable (Task 5).

## Files and Execution

Create `scripts/game/hero_roster.gd`; keep stable profiles and XP math here, not
in the renderer or Core progression. Modify `scripts/game/raid_director.gd` for
spawn/events/outcomes, `scripts/mobile/mobile_save.gd` for save integration,
`scripts/mobile/mobile_session.gd` for results, and `scripts/mobile/hero_badge.gd`
only if layout testing requires it. Existing Core rewards remain unchanged.

New tests: `hero_roster_test.gd`, `hero_return_test.gd`, `hero_experience_test.gd`,
`hero_roster_save_test.gd`, `hero_progression_ui_test.gd` under `tests/`.
All are SceneTree scripts with explicit failure count and nonzero exit on failure.
Existing tests may assume every hero is new; adapt only such fixtures explicitly.

Run one focused script (substitute the actual test filename in each task):

```powershell
Start-Process -FilePath 'C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe' -ArgumentList '--headless --path . --script res://tests/hero_roster_test.gd --quit-after 600' -WindowStyle Hidden -Wait -RedirectStandardOutput artifacts/hero-roster.out.log -RedirectStandardError artifacts/hero-roster.err.log
Get-Content artifacts/hero-roster.out.log,artifacts/hero-roster.err.log
```

Commands run separately. Assert no `SCRIPT ERROR:`, `ERROR:` or `FAIL:` in logs;
Godot's exit status alone is insufficient. Tests creating Main must set
`persistence_enabled = false` before adding it to the tree. Use isolated temporary
paths for persistence tests. Existing `tools/test-mobile.ps1 -All` discovers new tests.

### Task 1: Durable Profiles and Level Math

**Files:** Create `scripts/game/hero_roster.gd`, `tests/hero_roster_test.gd`.

**Interfaces produced:**

```gdscript
class_name HeroRoster
extends RefCounted
var profiles: Dictionary = {} # int ID -> durable dictionary
var next_id: int = 1
var previous_id: int = 0
static func level_for_xp(xp: int) -> int
func recruit(base: Dictionary) -> Dictionary
func reset() -> void
func snapshot() -> Dictionary
func restore(data: Dictionary) -> bool
static func valid_snapshot(data: Variant) -> bool
```

Durable fields: `id`, `name`, `class_name`, `kind`, `trait`, `xp`, `discovered`,
and `stats`. Stats whitelist: `max_hp`, `greed`, `steal_capacity`, `fear_weight`,
`trap_weight`, `objective`, `door_damage`, `flee_ratio`, `patience`.
`discovered` is a dictionary of Vector2i -> true. Level is derived, not saved.
Return deep copies, not references callers can mutate. Personal name uses a
small class-specific name list plus the monotonic ID as a unique suffix; retain
class_name separately for result text. Never reroll an existing profile.

- [ ] Write failing tests with exact boundaries and copy isolation:

```gdscript
assert(HeroRoster.level_for_xp(0) == 1)
assert(HeroRoster.level_for_xp(49) == 1)
assert(HeroRoster.level_for_xp(50) == 2)
assert(HeroRoster.level_for_xp(149) == 2)
assert(HeroRoster.level_for_xp(150) == 3)
assert(HeroRoster.level_for_xp(750) == 6)
```

- [ ] Run the focused test and confirm missing class/API failure.
- [ ] Implement level derivation with integer thresholds; use at most 64-bit arithmetic and reject invalid persisted negatives:

```gdscript
static func level_for_xp(xp: int) -> int:
    var level := 1
    while xp >= 25 * level * (level + 1):
        level += 1
    return level
```

- [ ] Implement whitelist-based recruitment, monotonic identity, unique names, deep snapshot and reset. Do not copy action timers or lockpick overrides.
- [ ] Implement strict profile validation used by restore: all required keys/types; four supported classes; TRAITS membership; objective matches class; finite stats within current generation ranges; nonnegative XP <= MobileSave.MAX_VALUE; unique positive IDs below next_id; previous_id in `[0,next_id)`; valid in-bounds discovery coordinates and boolean true values. Use existing MAX_RECORDS bounds; no silent truncation.
- [ ] Add cases for duplicate/missing identities, negative XP, NaN stats, malformed discoveries, aliasing and level at MAX_VALUE. Run focused tests green.

### Task 2: Recruit/Return Selection and Fresh Raid State

**Files:** Modify `hero_roster.gd`, `raid_director.gd`; create `tests/hero_return_test.gd`.

**Interfaces:** `RaidDirector.roster: HeroRoster`; `HeroRoster.select_return(pressure: int, vulpin_only: bool, rng: RandomNumberGenerator) -> Dictionary` returns a profile or `{}`. It performs the 50% return decision and eligible weighted selection. RaidDirector recruits if result is empty; it owns template rolls and pressure consumption.

- [ ] Write deterministic tests with seeded RNG: empty roster, one last-visitor profile, two same-class profiles, dead profile removed, eligible classes filtered by Vulpin-only. Across seeds assert both recruit and return decisions occur and no returned ID equals previous_id.
- [ ] Run RED, then implement eligibility BEFORE random selection. Choose return branch with `rng.randf() < 0.5`. Group eligible IDs by kind; weight Mage by `1 + max(0, pressure)`, others by 1, then uniformly choose within selected class. Use a seeded RNG owned by roster or passed by director; tests supply one directly.
- [ ] Extract current base-stat creation into `_new_hero_profile() -> Dictionary` in RaidDirector, using existing `_random_hero_template`, trait rolls and jitter unchanged. Build transient hero from the chosen profile:

```gdscript
hero["id"] = profile.id
hero["name"] = profile.name
hero["class_name"] = profile.class_name
hero["level"] = HeroRoster.level_for_xp(profile.xp)
hero["hp"] = profile.stats.max_hp
hero["max_hp"] = profile.stats.max_hp
roster.previous_id = int(profile.id)
```

- [ ] Keep all current fresh route/animation/action initialization. Starting carried gold is a fresh roll from the four existing class ranges, not old carried loot. Preserve personality/stat values on returns. Reset attempts, ignored objectives, health, stolen counters and observation ledger. Consume pressure when a Mage actually enters; Vulpin-only does not consume it.
- [ ] Add a real `_start_raid` test that damages a hero, sets timers and exhausted lock budgets, returns it after an intervening individual, and checks same identity/stats/XP with full HP and no stale action state. Missing entrance must not change roster or previous_id.
- [ ] Run focused tests plus `vulpin_progression_test.gd`, `vulpin_only_test.gd` and `mobile_session_test.gd`. Update fixtures which rely on recruitment to clear roster explicitly; do not weaken permanent-identity assertions.

### Task 3: Successful-Event Ledger and Terminal XP

**Files:** Modify `hero_roster.gd`, `raid_director.gd`; create `tests/hero_experience_test.gd`.

**Interfaces:**

```gdscript
static func experience_breakdown(ledger: Dictionary) -> Dictionary
func finish(id: int, survived: bool, ledger: Dictionary) -> Dictionary
```

Ledger fields: `acquired_gold` int, `locks` Dictionary[Vector2i,bool],
`obstacles` Dictionary[Vector2i,bool], `core_damage` int,
`discoveries` Dictionary[Vector2i,bool]. Return award fields `hero_id`,
`hero_xp_breakdown`, `hero_xp_gained`, `hero_xp_total`, `hero_level_before`,
`hero_level_after`. Finish deletes dead profiles; survivors gain XP and union
all discoveries including those beyond the 20 XP cap.

- [ ] Write exact XP tests (and run RED):

```gdscript
var ledger := {"acquired_gold": 150, "locks": {Vector2i(1, 1): true},
    "obstacles": {}, "core_damage": 0, "discoveries": {}}
var xp := HeroRoster.experience_breakdown(ledger)
assert(xp.total == 55)
ledger.acquired_gold = 4
assert(HeroRoster.experience_breakdown(ledger).gold == 0)
ledger.acquired_gold = 5
assert(HeroRoster.experience_breakdown(ledger).gold == 1)
```

- [ ] Implement breakdown as survival10 + floor(acquired_gold/5) + 15 per unique lock + 15 per unique obstacle + actual core_damage + min(20, discoveries.size()). Deduplicate a cell across locks/obstacles so no single obstacle pays twice.
- [ ] Initialize a fresh ledger on spawn. At `_remember_nearby`, record personally new perceived cells even if already in shared `known`; compare against durable discovered cells and the current ledger. Inherited knowledge without actual observation earns zero.
- [ ] Hook actual successful events: `_resolve_vulpin_lockpick`, `_resolve_mage_arcane_open`, `_apply_door_damage` when HP crosses zero; both immediate and delayed vault withdrawals; ground-bag pickup; actual Core HP subtraction. Verify exact method names in current source before editing. Do not award for entering an animation or partial damage to a door.
- [ ] Track acquired gold independently of initial carried_gold. At terminal survival bound credit by actually carried amount. Void retains loot under current rules. All death paths discard pending XP.
- [ ] Integrate `roster.finish` inside `_end_raid`, AFTER existing `_completed_raid_id` guard and BEFORE hero clear/report signal. Derive survival from completed escape without killed flag; do not treat an aborted raid as survival. Include award data in last_result. For legacy/test heroes without a managed ID return an empty award rather than creating a phantom profile.
- [ ] Probe real portal completion, void, delayed Vulpin death and direct death. Before final frame expect no XP; after completion expect exactly one award; repeat completion callback and assert unchanged XP. Test 25 discoveries save all25 but award20, then revisit awards0. Check empty vault, failed lockpick, starting loot and duplicate events award no action XP. Test multiple level gains and different class exploits.
- [ ] Run focused tests and `vault_protection_raid_test.gd`, `vulpin_sequence_probe_test.gd`, `mobile_raid_result_test.gd`.

### Task 4: Validated Saves, Checkpoints and Reset

**Files:** Modify `mobile_save.gd`, `raid_director.gd`; create `tests/hero_roster_save_test.gd`; extend `tests/mobile_restart_test.gd` as needed.

**Interfaces:** Existing `MobileSave.capture/apply` gain optional `hero_roster` snapshot. Validation calls `HeroRoster.valid_snapshot` before any progression/sim mutation. RaidDirector.reset_for_new_map calls roster.reset; apply restores it after the reset.

- [ ] Write RED round-trip test with two survivors, discovery history and previous_id. Test old snapshot with no hero_roster gives an empty roster and level1 recruit.
- [ ] Add invalid roster to an otherwise valid save; snapshot sim/raid/profile before apply and assert all unchanged on false. Cover unknown classes, bad IDs, out-of-bounds cells, inconsistent stats and invalid XP.
- [ ] Implement optional capture/validation/apply:

```gdscript
data["hero_roster"] = raid.roster.snapshot()
# In validation, before applying anything:
if data.has("hero_roster") and not HeroRoster.valid_snapshot(data.hero_roster):
    return false
# After reset_for_new_map(), after successful validation:
if snapshot.has("hero_roster"):
    raid.roster.restore(snapshot.hero_roster)
```

- [ ] Preserve strict version1 validation, MAX_FILE_BYTES and backup behavior. Test write failure propagates instead of dropping profiles; previous_id may refer to a dead but previously allocated ID.
- [ ] Verify checkpoint capture occurs before `_start_raid`; reloading mid-raid restores that checkpoint, not transient XP. Persist roster with completed results. Explicit restart clears roster/history but preserves current Core progression and rewarded raid-ID semantics.
- [ ] Run focused tests plus `mobile_save_test.gd`, `mobile_restart_test.gd`, `mobile_session_test.gd`. Never write actual SAVE_PATH in tests.

### Task 5: Identity and Progression Feedback

**Files:** Modify `mobile_session.gd`; inspect/adapt `hero_badge.gd`; create `tests/hero_progression_ui_test.gd`; extend `tests/hero_badge_test.gd`.

**Interfaces consumed:** Existing hero.name/level portrait API, terminal award fields from Task3. Do not replace class keys used for portrait selection with personal names.

- [ ] Write RED UI tests for distinct personal names, retained class portrait, level before/after, XP breakdown, and no success/progression message after death. Existing Core reward text must remain distinguishable from hero XP.
- [ ] Extend `_raid_finished` result text with survivor name, class and hero XP, separately from Core XP:

```gdscript
if int(result.get("hero_xp_gained", 0)) > 0:
    modal_body.text += "\n%s : +%d XP, niv. %d" % [
        result.get("hero_name", ""), result.hero_xp_gained,
        result.hero_level_after]
```

- [ ] Add readable source breakdown (survival, gold, locks, obstacles, Core damage, discovery) and explicit level gain when before < after, using existing modal and layout. No second top HUD or roster management page.
- [ ] Render isolated Main fixtures at 1280x720 and 720x1280 with long personal names and levels10/100. Assert labels remain inside their controls, level is visible, modal content is not clipped and buttons remain accessible. Save screenshots under artifacts and inspect them; adapt existing wrapping/scroll behavior if required.
- [ ] Run UI tests plus existing hero badge/HUD/result tests. Native probes must disable persistence before entering tree.

### Task 6: Documentation and Final Regression Gate

**Files:** Modify `GAME_DESIGN.md` sections0.5,0.6,0.11,0.12 and validation list. Update tests only for intentional persistent-spawn changes.

- [ ] Document stable identity/stat rolls, selection weights and exclusion, permanent death, full-health return, void survival, all XP values, level thresholds, lack of other stat scaling, checkpoint rollback, restart and optional save migration. Replace the old statement that heroes always spawn level1 with recruits vs returns.
- [ ] Run `& ./tools/test-mobile.ps1 -All`. Expect all discovered scripts PASS and zero failures. Inspect actual logs; do not assume the old count of82 is still the final count.
- [ ] Run native expedition/UI probes and inspect captures. Reconfirm no Vulpin jump and no early trap or collection effects.
- [ ] Run `git diff --check`; inspect scoped diffs against spec. Preserve unrelated edits and generated files. Review all five Review Focus cases against their tests.
- [ ] Obtain one independent final code review when tools allow; fix findings and rerun affected tests, then full suite for gameplay changes.
- [ ] Report implemented behavior, verification and known checkpoint limitations in French. No push or broad commit of the existing dirty worktree. Scope any explicitly requested commit to this feature's changes only.

## Handoff

Recommended: native execution in this session, tasks1-6 sequentially, with one
independent final review. Selection, event accounting and persistence share the
same interfaces, so parallel implementation would add coordination overhead.
Alternative: fresh implementer/reviewer per task after each interface is established.
The user approved this plan and native execution; implementation is complete.
