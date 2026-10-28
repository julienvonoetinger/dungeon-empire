# Headless gameplay probes implementation plan

**Goal:** Run real dungeon simulations and assertions without the graphical interface.

**Architecture:** Instantiate only the existing game-session Node, with persistence disabled before initialization and automatic processing disabled. A scenario runner sends existing gameplay commands and advances the same gameplay tick in fixed 50 ms increments. Read-only probes expose JSON-compatible state and check invariants after every command/tick. CLI runs are isolated, sequential and seeded; no UI, renderer or player save is loaded.

**Tech stack:** Godot 4.7 GDScript, JSON scenarios, PowerShell launcher.

**Scope from the request:** Programmatic simulations/tests through probes. Choices made here: stable entity IDs, JSON scenario/report format, bounded waits, nonzero failure exit codes, deterministic replay on the same engine/version. No visual-overlay restoration or claim of pixel correctness. No APK, commit or push.

## Interfaces and tasks

- [x] Session seam: `persistence_enabled` defaults true; `advance_simulation(delta)` is also called by `_process`. Test no-save initialization, edits, raids and unchanged default persistence. Keep simulation rules unchanged.
- [x] `scripts/testing/game_probes.gd`: `snapshot(session)` returns records indexed by stable IDs; `violations(session)` returns structured invariant failures. Queries must not reconcile/mutate storage. Test deliberate bad HP/charges/stale references and read purity.
- [x] `scripts/testing/scenario_runner.gd`: validate the entire JSON scenario before executing; reuse session build/start/repair/undo/collect/transfer commands; advance/wait by fixed ticks; assertions and checkpoints; seeded sequential runs; bounded failure reports. Test real raids, rejected edits, timing/pause, deterministic replay and malformed input.
- [x] `tools/run_probes.gd`, `tools/run-probes.ps1`, `tests/scenarios/*.json`: batch launcher and useful construction/raid regression scenarios. Exit 0 success, 1 observed failure, 2 malformed input/runner error. Reports identify scenario, seed, engine, step, tick, probe, expected/actual and final state.
- [x] Document commands, state IDs, supported actions, limits, seeds and extension points in `docs/testing/probes.md`; add README entry and current repository notes.
- [x] Fresh-context final review and focused regressions.

## Review focus

1. No player save read/write, including initialization and end-of-raid autosave.
2. Rejected actions do not silently succeed or debit resources; failed assertions and timeouts return nonzero.
3. No duplicated gameplay logic; the same session tick, progression and completion signals execute.
4. Queries do not mutate state, and tests notice impossible entity references and hero occupancy.
5. Invalid scenario types, unknown fields/actions/probes, unbounded durations and missing report paths fail clearly; deterministic runs exclude wall-clock metadata.

## Execution ledger

- Inspection: session contains rules/commands but always reads/writes a save. `_process` caps delta at .1. RaidDirector uses global RNG, plus locally seeded roster RNG. Sequential isolated runner will reset the global seed per scenario; concurrent in-process runs are explicitly unsupported. Production RNG behavior remains untouched.
- Ruling: work in the existing `codex/2d-foundation` workspace (clean at start); implement inline and perform one independent final review. This is requested internal tooling, using existing rules, not an unapproved new gameplay design.
- Red/green: absent no-save/tick hooks failed, then passed; absent probes/runner failed, then passed. A targeted test showed no-save must preserve Save.capture's normal balance reconciliation; fixed before final validation.
- Independent review reproduced native report/input overwrite, Boolean/object version comparison fail-open, overly tolerant large fractional durations and Windows trailing-separator quoting. All corrected and covered by regressions; reviewer rechecked fixes, no remaining important implementation finding.
- Windows WaitForExit could lose ExitCode; wrapper retains the process handle and derives failure from the structured report. CLI regression checks actual 0/1/2 exit codes, native input preservation and byte-identical replay.
- Batch audit: 3/40 runs exceeded the original 180 s test deadline. Extended investigation showed completion at 195.1/196.55 s due to existing Stubborn morale, not an infinite loop. Deadline corrected to 240 s; no AI rule changed. Initial treasury fixture incorrectly assumed 150 in the first chest; real prepared-map purchases leave 95, corrected before final suite.
- Final: headless import exit0/empty stderr; 63 native tool checks, 14 CLI checks, 5 scenario recipes and 40 seeded raids (9 mage,11 paladin,10 ranger,10 thief) pass. Evidence in artifacts/probes. Existing graphical regressions were not rerun because renderer/art remained untouched. No APK, player-save access, commit or push.
