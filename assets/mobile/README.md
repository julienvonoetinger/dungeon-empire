# Mobile Art

The user designated the mobile mockups as the visual reference and authorized
new image generation instead of prioritizing old assets.

Generated with the built-in image tool on 2026-09-28:

- `command-atlas-v1.png`: transparent 4-column, 3-row fantasy item atlas.
  Row 1: excavation, vault, spikes, snare. Row 2: void, door, magical door,
  entrance. Row 3: repairs, corpse, gold, crystal.
- `core-monument-v1.png`: transparent isometric Core monument. The game uses
  a camera-facing 3D sprite over the real 2x2 simulation footprint.
- `hero-portraits-v1.png`: transparent 2x2 portraits; thief/paladin on top,
  ranger/mage below. Actual moving heroes remain animated 3D models.

Atlas regions use imported texture dimensions, not hard-coded source sizes.
The source PNGs are retained at full resolution. Android texture import budgets
are documented in `docs/ANDROID_TESTING.md` and the preservation manifest in
`tools/android/mobile-texture-budget-manifest.json`.

`cinzel.ttf` comes from the Google Fonts Cinzel family, distributed under the
SIL Open Font License in `CINZEL-LICENSE.txt`.
Source: https://github.com/google/fonts/tree/main/ofl/cinzel
