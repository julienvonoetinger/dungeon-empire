# Mycean spore-burst attack

> Execution: superpowers:executing-plans; continue the current approved feature checkout.

**Goal:** A distinct offensive staff spell against the actual Core, presented in four isometric directions. User requests a different attack from magical unlocking.

**Design call:** A compact cyan/green spore orb gathers at the staff cap during a backward wind-up, is cast with a forward thrust, travels independently, and bursts against the vortex. No continuous beam or unlocking runes. Keep the original equipped model, painting, corrected grip and gait pixel density. All character motion comes from whole-model held Blender renders.

**Timing:** Twelve slots over 1400ms; durations 100,100,120,130,200,100,100,100,100,100,130,120ms. Release650ms, flight320ms, impact970ms. Feet remain planted. Neutral recovery is exact. Runtime effect uses the preview clock only, including pause/seek/speed and replay. Visual preview only; no gameplay damage, roster, save, APK, commit or push.

## Tasks

- [x] Render source: new v8-spore-attack scripts and packed pose blend, measured emitter, four cameras. Independently reload and check complete staff/body crossings, contacts, source fingerprints and frame bounds. Pack320px whole sprites from640px masters; retain source/recipe under docs/.gdignore.
- [x] Preview: MyceanCoreAttack.tscn, mycean_attack_stage.gd, mycean_attack_preview.gd and mycean_spore_burst.gd. Reuse existing action controls and real Core renderer without modifying other previews. Separate charge, free projectile and target burst; physical actor ordering retained.
- [x] Validate: missing-scene red test, choreography negative control, native release/impact, pause/seek/2x and visual fit at1280x720,844x390,720x960. Capture native motion, prepare review page, record limits and fresh independent review.

## Review focus

- Staff/cap/hand contact across held poses; all three wrist attachments travel together.
- Projectile starts at measured cap in the release frame, then detaches and reaches Core; no continuous laser.
- Charge and impact supports fit in all four stage panels; no paint through near objects.
- Replay/large tick/pause/seek do not skip or duplicate preview events or desynchronize effects.
- Prior Mycean and production art remain unchanged; exact source hashes and whole-sprite traceability.

## Ledger

Initial checkout clean at553b57df. Use existing feature workspace so native previews stay in the user's project. Inline implementation with final independent review. No additional permission gate: this is the next requested animation in the already-established pipeline.

Completed2026-11-02. Native missing-scene regression fails before implementation; standing source fails5choreography assertions. Pilots detect cap then boot crossings; charged staff uses neutral axial correction with20degree forward pitch, preserving the original three-part grip. Final354saved-source checks pass;40masters/4atlases,1,891,722PNGbytes. Max actual mean-sole support error.000030764.

Native704checks and17isolated-effect checks pass;7headless scenario suite passes. Desktop/portrait/short-landscape inspected. First small effect lacked visible volume; larger sphere/bloom plus passing vertex tint without resampling fallback alpha restores mobile readability. Review WebPs preserve exact sample timing2400/3800ms including1s endpoint pause.

Fresh independent read-only review: no actionable finding,154asset/hash/repack/timeline checks and15source preservation comparisons pass. Source evaluated neutral differs from original static by.001673modelunit(~.155nativepx), base data unchanged and first/last recovery exact; record as diagnostic, no visible issue. No deferred code finding. Physical-phone profiling, exhaustive self/contained collisions, continuous3D interpolation and final artistic acceptance are not claimed by these checks.
