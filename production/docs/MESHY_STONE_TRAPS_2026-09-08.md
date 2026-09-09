# Meshy stone traps — 8 September 2026

## Production

This production pass generated a matching stone-based Meshy AI trap set.
Nine canonical/state images were created with the built-in ImageGen tool and
saved in `production/meshy_assets/traps/stone_v2/`. The existing
`environment/modules/floor_tile_controlled.png` is the visual reference for
all three armed images. Each sprung/broken image edits its family's exact armed
image, retaining camera, framing, outer stones and material identity.

The source and destination mappings are in `meshy_model_manifest.csv`.
The nine image-to-3D jobs use Meshy `meshy-t2`, smart topology, a 6,000 polygon
target, textured GLB output and PBR maps. Task IDs, credit consumption and GLB
validation results are recorded in `.meshy/tasks.json` (local, ignored).

The first armed spike generation added unwanted round details. A Meshy
retexture attempt retained these details and introduced a blue cast; it was
rejected. A second image-to-3D generation with a plain-stone texture prompt
was accepted as `spike_armed_clean.glb`. Earlier candidates remain for
provenance and comparison. The retexture operation is reproducible through
`tools/meshy_retexture_trap.py`; its separate task record is
`.meshy/spike_retexture.json`.

## Image prompt set

Common armed-image brief: edit the controlled floor reference into one
isolated square trap tile for Meshy, preserving cool anthracite irregular
rounded polygon paving, broad worn bevels, matte stone and faint violet seams.
Thin solid base, flush perimeter stones, full object visible with margin,
orthographic three-quarter view and neutral studio illumination on charcoal.
No text, environment, character, contact sheet, raised ornamental border,
gems, metal plate or loose fragments outside the footprint.

- Spike armed: short robust dark iron tips emerging through narrow fitted
  sockets in broad paving stones; the selected reference has six tips.
- Spike sprung: extend those same six tips vertically to tall iron spears;
  restrained violet only deep inside their original sockets.
- Spike broken: snap the same six tips into blunt stubs near the paving;
  small chips remain inside the sockets, with no purple emission.
- Snare armed: six folded mineral claws around a central stepping stone,
  sculpted as articulated rock roots; narrow joints and no central abyss.
- Snare sprung: raise those six claws and curl them inward around the central
  empty space, retaining their attachment points and the central stone.
- Snare broken: crack the six claws into blunt segments in their original
  locations; retain the stepping stone and perimeter, remove emission.
- Void armed: four interlocking irregular stone leaves close a circular seal,
  surrounded by ordinary paving; only a hairline violet fissure.
- Void sprung: part and tilt those four leaves to reveal a deep circular
  opening within the existing seal; keep outer paving flat and unchanged.
- Void broken: settle and crack the four leaves, closing most of the opening
  with fractured stone, narrow dark gaps and no emission.

All state-edit prompts explicitly preserve base, footprint, outer stone layout,
materials, camera, background, lighting and framing from the armed reference.

## Integration

Playtesting showed that the stone-based variants were too close to ordinary
paving once their square edges were hidden. A second integration pass restored
the strong silhouettes of the detailed Voidspike, Voidstone Nexus and Arcane
Nexus families, but their monolithic bases still read as objects placed on top
of the floor.

Production now uses the `paver_v3` Meshy family. Nine new references and nine
new 6,000-polygon textured GLBs cover spike, snare and void in armed, sprung
and broken states. Every reference carries the same complete one-stone-wide
outer row of dark rectangular and clipped-corner pavers. The mechanism is
inset inside that border: six spike sockets, an articulated snare, or a
four-braced void gateway. The spike family was regenerated with the other two
so all three traps share the same stone scale, bevels, grout and material
language rather than mixing asset generations.

Their three state models are fitted to the complete 1x1 cell footprint.
The surrounding floor uses a direct 1x1 Meshy module in the same architectural
stone language. Its dark backing continues beneath the whole trap cell, while
the relief instance is omitted locally because the trap is the replacement tile.
The upper perimeter surface of each trap base is aligned to the adjacent floor
at Y=0.175, burying the slab thickness. This avoids raised platforms and
preserves the traps' distinct silhouettes, materials and violet state accents.
The original and `stone_v2` jobs remain as documented prototypes and are not
selected by the world renderer.

Gameplay still controls activation, final charge, exhaustion and repair.
Missing or invalid models return failure so the existing world fallback can
render instead of silently leaving an empty tile.

## Verification commands

- `--headless --path . --script res://tests/meshy_stone_traps_test.gd`
- `--path . --script res://tests/labyrinth_integration_test.gd -- --capture`
- `--path . --script res://tools/capture_meshy_traps.gd -- --capture --states`

Use the installed Godot executable for these arguments. The component test
checks that detailed models fill one cell, aligns their base surface to the
floor and checks exact armed placement after repair. The integration test
exercises twenty legal excavations, an entrance,
a door, all trap states and twelve autonomous raids. Captures in `artifacts/`
are renderer output, not generated concept images. Known host warnings about
user-directory access, viewport sizing and exit cleanup remain separate.
