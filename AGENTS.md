# Repository instructions

## Keep the game design synchronized

- Read `GAME_DESIGN.md` before changing gameplay, balance, hero AI, controls,
  progression, persistence, visual state feedback or playtest configuration.
- Update the corresponding rules in `GAME_DESIGN.md` in the same change as
  implementation. Include costs, defaults, prerequisites, state transitions,
  exceptional outcomes, save/load behavior and affected player feedback.
- Section 0 describes the implemented static 2D foundation. Keep implemented
  rules distinct from future design, legacy behavior and known limitations.
  A sprite, model or animation asset is not proof of an implemented hero class.
- Document temporary test overrides and their active values. Do not turn them
  into permanent progression or conceal them behind the normal balance rules.
- Verify written numbers against code and tests. Do not change gameplay merely
  to make it agree with documentation; surface any discrepancy instead.
- For bug fixes, add a regression reproducing the relevant player scenario;
  use simulation/node/animation probes and visual captures when appropriate.
- Before declaring a behavior change complete, check the design update and
  report verification. Run `tools/test-mobile.ps1 -All` for gameplay changes.
- Documentation-only edits require source and reference checks, not a full
  gameplay test run unless code also changes.

## Current rendering scope

- Use `docs/reference/approved-scene.png` and the actual sprites in
  `assets/dungeon/` as the visual reference. Do not substitute a full-scene image
  for the assembled rendering or redesign the art without user authorization.
- The current scene is fixed and has no gameplay. Keep future rules separate.
- `tools/test-mobile.ps1 -All` now checks the 2D scene and camera. The old gameplay
  suite and assets remain available in Git at `v1.0.0`; do not restore them as
  dependencies of this foundation.
