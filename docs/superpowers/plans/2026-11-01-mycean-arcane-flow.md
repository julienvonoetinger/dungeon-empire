# Mycean spell finish

User rejects the simple straight laser as insufficiently magical. Replace only
the procedural spell in the existing isolated scene: a gathering of spores
at the staff cap, two intertwined wispy ribbons, orbiting sparks, runic seal
reaction and dissolving fragments. Preserve whole hero sprites/door art,
depth order, measured contacts, 450–1500ms channel and 1850ms full clip.

- [x] Add native visual regression for a flow extending beyond a thin beam,
  same-time deterministic rendering, pause, dormant/final silence and bounds.
- [x] Implement lightweight procedural ribbons/particles with existing soft
  falloff texture, single preview clock. Inspect native captures and iterate.
- [x] Run existing scene checks plus focused visual checks, compile v7 review,
  document bounds/cost/limits, fresh independent code review.

No new raster sprite, source mesh, production raid, player save, APK or commit.
v6 review remains archived; v7 records old effect source and comparison movie.

Result: two static shader-deformed mist strips, gathering/flowing spores and
door-plane runes. No new runtime bitmap. Oldlaser fails off-axis coverage with
0pixels; new effect passes. Fresh independent review identifies the1500ms
release gap. Added regression fails, explicit releasing state fixes it. Added
translated-render regression also reproduces culling of displaced unitmesh;
registered custom AABB fixes it. Final23effect+738scene checks pass, empty
stderr. Import passes. Native comparison movies and three-size captures saved.
All source hero/door art and gameplay remain unchanged; phone profiling undone.
