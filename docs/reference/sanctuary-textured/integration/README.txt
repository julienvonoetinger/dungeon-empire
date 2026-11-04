Approved sanctuary integrated into introduction - 2026-11-04

Latest user scope: integrate only the approved scenery. Oculin staging is a
separate future step. No new actors, choreography, ritual effects or camera
movement are added. The old invocation_film.gd is retained but no longer used
by first_dungeon_intro.gd or the InvocationIsometrique preview scene.

scenes/game/InvocationSanctuary.tscn is the approved SanctuaryFlora scenery
promoted to production resources. Its 96 textures are byte-identical copies
under assets/game/introduction/sanctuary. It has no preview-script dependency.
All ground polygons, object transforms, corrected candle and vegetation stay.
scripts/game/invocation_sanctuary.gd provides the same portrait/landscape fit
inside the existing intro Control and exposes present/release/DURATION.

The existing controller opens it after narrative page 10 (or Passer le recit).
The previous 18-second handoff, final fade, Passer button, dungeon entrance
and tutorial logic are retained. The sanctuary itself is static. The existing
invoker entering the dungeon is unchanged and is not staged in this sanctuary.

Reproduce promotion:
  node tools/promote_invocation_sanctuary.cjs
recipe.json records baseline scene hash and all source/runtime asset hashes.

Validation: artifacts/sanctuary-intro/check.gd instantiates the actual game
with persistence_enabled=false before entering the tree. Before integration,
it failed because the sanctuary was absent. Afterwards all 34 checks pass:
narrative handoff, scenery and six pillars, full coverage in portrait and
landscape, no legacy 3D presence or independent animation clock, skip, pause,
existing entrance and lesson transitions. Import/runtime stderr are empty.
Both native captures were inspected. No player saves, APK, commit or push.
