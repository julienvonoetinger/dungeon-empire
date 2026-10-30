# Vulpin sprites in the playable raid

The Vulpin-only roster selects `thief` correctly, but the playable renderer still
creates the old polygon pawn. Reuse the approved whole-character Meshy sheets;
do not generate artwork or change raid rules, timers, AI, or movement speed.

1. Reproduce in a no-save `DungeonGame` fixture: a real raid must instantiate a
   textured Vulpin, not `game_marker`'s hero pawn. Keep this as a regression test.
2. Add a presentation actor selecting idle/walk/run/hurt/door pick/chest pick/
   collect/death from real raid state, driven by simulation time (pause and 2x).
   Reuse the approved .85 scale, foot anchor, registration and physical bounds.
   Preserve its clock across structure rebuilds. Keep other classes' fallback.
3. Integrate positioning at the actual lock/chest and independently sorted door
   parts. Persist only optional corpse appearance metadata, backwards compatible
   with existing saves. No saving in test fixtures.
4. Verify real spawn, directions, action states, pause/rate, rebuilding, open
   arch ordering, corpse, and unchanged simulation with native tests/captures
   plus the existing probe suite. Review actual gameplay captures at mobile size.
5. Fresh code review and document results/limits. No APK, commit or push.

Review focus: simulation vs visual state; timer restart on rebuild; wrong chest
front/lock; hero/crown ordering; reference-only files accidentally needed at export.

## Execution record

- Root cause: `isometric_game_view.rebuild()` unconditionally creates `Marker`.
  Resource sheets are only referenced by isolated preview scripts.
- Implementation proceeds inline under the user's existing request to correct
  the playable result. This is reuse of accepted art, not a new art proposal.
- Initial native regression: actual thief selected but missing AnimatedSprite2D,
  RED 1/2; after integration GREEN. Final suite: 367 checks, zero failures.
- Approved resources reused with no PNG edits. Registration packed into a native
  dependency; actor retained across structure rebuilds. Optional corpse metadata
  validated, old records accepted. Gameplay rules/timers unchanged.
- Fresh review found blocked chest fronts moving the fox into rock. Added legal
  dense-storage fixture: 3 failures before fix, zero after. Whole pose envelope
  now stays on the walkable tile; precise hand contact is best effort there.
  Actual seed-21 reproduction now reports feet on VAULT rather than ROCK.
- Validation: full 5 probe recipes, 160 trap, 84 open-door, 34 eye-world and 63
  probe API checks pass. Eye/open-door captures require GPU; initial headless
  invocations expired and were rerun graphically. Native import clean.
- Native screenshots inspected (four-facing interaction/passage, real raid,
  recoil/death, landscape/portrait, blocked chest fallback). No APK or device run.
