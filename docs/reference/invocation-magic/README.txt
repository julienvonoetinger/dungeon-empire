Sanctuary magic - 2026-11-04

User requests magical effects, appearing symbols, lightning and light bursts
during invocation. Existing scene/actors/art/paths/timeline unchanged.

scripts/game/invocation_magic.gd renders two additive Node2D layers using the
existing shared falloff texture and procedural lines/particles, no new PNG.
The floor layer follows the painted altar ellipse/diamond/eye (centre -6,7;
ellipse130x64) and stays above the altar but below the floating master.
The aerial layer sits above stones, below the foreground actors. Six floating
geometric glyphs,36 inward/rising motes, stone charge halos and short jagged
arcs build toward manifestation. Stone anchors use actual sprite alpha bounds.

10-13.5s: seal reveals. Symbols rise from11.5s. Stones gather energy from12s.
Lightning bursts at13.8,15.7,17.1,18.35,19.25,19.8,20.12 (each.22s).
17.5-21.4: light filaments gather.20-21: localized manifestation flare/rays;
20-22: expanding ground shockwave. Effects settle by23, leaving faint seal.
No screen-wide flash or new audio. No spiral motif.

Every effect depends exclusively on present(time). No autonomous particle
simulation, random state or shader TIME; pause/seek/replay remain deterministic.
check_magic.gd first fails because effects absent, then passes: no pre-chant
magic, charge/flash/settle, layer ordering, actual native pixel changes,
byte-identical render after seek, replay reset. Portrait/landscape captures
at11.5,15,18.5,20.18,23 inspected. Existing procession suite also rerun.

No physical-phone profiling, new sound, APK, player saves, commit or push.

Soft-light revision: user found lines too crisp. Replaced stacked hard strokes
with continuous ribbon meshes and invocation_light.gdshader: smooth transverse
Gaussian falloff, violet centre, variable width/brightness and softened open
endpoints. Existing halo sprites retain their sampled alpha. Ribbon resources
are retained until the next redraw so deferred rendering never uses freed RIDs.
Lightning adds small branches and two scales of displacement. All variation
uses effect_time supplied by present(time), including during pause/seek.
Before capture: artifacts/sanctuary-procession/magic-lines-before.png.
Native magic checks pass with empty stderr; updated portrait/landscape viewed.

Manifestation alignment: the master's initial centre previously sat88world pixels
above the light. Magic.MANIFESTATION_CENTER now anchors the gathering glow,
flash and initial master sprite. Hold this centre through20.6s, then smoothly
rise to the original hover centre by22s. Final size, layering and choreography
are preserved. Native regression fails at20.01/20.18/20.5 before the fix and
passes after; magic and procession checks pass with empty stderr. Captures at
20.5/21s inspected in portrait; both portrait/landscape renders retained.
