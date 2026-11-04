# Invoker follows the master

User correction: invoker is too small and teleports near the Core. Replace
the static fade-in with actual travel through the surface entrance and dungeon.

- [x] Regression: invoker leaves ritual formation, arrives from dungeon stairs,
  moves toward the Core, stays behind master, keeps position at lesson handoff.
- [x] Reuse unchanged equipped source/poses; render actual NE/SE/SW/NW camera
  directions for walk/idle (no mirroring), retain source and masters.
- [x] Route around altar and scenery after standing from bow. Show stair descent
  with separate per-actor occlusion material. Hold scene until invoker enters.
- [x] Use same .95 scale as sanctuary on identical256px cell grid; walk in the
  dungeon corridor behind master, stop at existing tutorial destination. Core
  timing stays6.5s arrival/6.6–8.6awakening. No mid-room fade-in.
- [x] Native pause/seek/replay and three-size visual checks; focused review and
  launch save-free full preview. No APK, saves, commit or push.

Ruling: extend surface shot to40.4s so the invoker has time to walk around the
altar, while master's accepted motion remains unchanged. Four followers remain
at ritual site; only invoker is requested to follow. Same source gait preserves
prior support/contact limitations; this task adds directional renders and travel.
