# Compact door integration

User approval: “oui ça à l'air beaucoup mieux”, following hero-fit-v11-compact.
This completes the earlier request to integrate the revised doors in the game
and scenes. Geometry is copied byte-identically from v11. The rejected v9/v10
large door and v25 raised-lock poses are not production sources.

## Sources and registration

- Frozen `geometry.json`: total height1.16, opening .96/.63, same low junction
  span1/3..2/3, slimmer posts preserve their exterior plane and depth.
- `source/face-source.png`: selected built-in ImageGen result. Original images
  and all three prompts retained. The two earlier positioning attempts are
  historical, not selected. ImageGen was used, not a command-line/API fallback.
- `mapping.json` and `preparation.json`: original1024x1536 RGBA sampled with
  uniform scale1/translation(0,-.4). Contact (512,1138) lies inside the black
  keyhole and maps to lock Z=.32. This is a contact point, not a claim that
  the round hole's mathematical center was generated at an exact coordinate.
- Generated stone fronts use frozen wall palette grading; side/top faces use
  the shared stone material. Steel hinge regions bypass stone grading. Geometry
  provides the silhouette; the original image's outer halo is never exported.
  Two smooth leaf planes and perimeter remain independent of their painting.
- `selection.json` freezes input hashes. It records geometry approval and
  integration authorization, not user approval of unseen final paint.

## Reproduce

Use Node with Sharp on NODE_PATH and the repository root as working directory:

1. `node tools/prepare_approved_compact_door_texture.cjs`
2. `node tools/export_isometric_painted_kit.cjs`
3. `node tools/verify_approved_compact_door.cjs`
4. `node docs/reference/vulpin-review/v26-lower-lock-review/prepare.cjs --install`
5. Godot `--headless --editor --path . --import`
6. Godot `--path . --script res://tools/capture_integrated_compact_door.gd --rendering-method gl_compatibility`
7. Godot `--path . --script res://tools/capture_vulpin_lockpick_preview.gd --rendering-method gl_compatibility`

Door/game capture tools accept `-- --output=res://.../native-doors` or
`native-game`; use tools/capture_seal_doors.gd and capture_seal_game_contacts.gd.
Run verify_open_doors.gd and verify_door_badges.gd for semantic state checks.
capture_mobile_kit.gd accepts `-- --output-root=res://.../native-previews MobileReference DungeonPreview`.
These fixtures use no game session or isolated never-written save paths.

V26's `render_lockpick.py` and `verify_saved_poses.py` reproduce the original
whole-mesh eight held poses. The native source still uses a .85 hero scale,
256px frame/anchor,8fps/one-second loop. Four sheets894106PNG bytes/8MiB RGBA.
Only four lockpick sheets/registration changed; 31 other hero assets compare
identically to the earlier pipeline manifest. The Vulpin animations still do
not replace the simulation's hero AI; this request changes doors and previews.

## Validation and allocation

- The old production geometry failed the new fixture before the switch.
- export-validation.json:159IDs preserved,143 non-door regions/metadata exact,
  all four closed/open render recompositions alpha error0 and premultiplied
  colour error below1/255, no opaque wood left inside the open aperture.
- Closed/open doors now share the existing `open-doors/atlas-256.png` page.
  Total kit PNG2015739->2094094 (+78355) and RGBA12->13MiB. The architecture
  page stays1024x2048; this avoids doubling it to1024x4096. No larger density.
- Native import/captures exit0 with empty stderr. Four-door rail removal and
  restoration pass; game contact fixture covers7 states; open doors40 checks
  and door badges87 checks pass. V26 verifies32 tool projections, controls,
  distance, ghost view and four viewport sizes. Native images inspected.
- The v11 passage proof remains valid because XYZ is byte-identical:17 held
  walk/run/idle meshes fit,8 picking meshes are XZ-disjoint from masonry.
- Focused independent review found no important correctness/regression issue.

No continuous collision, facial performance, swinging-hinge mechanics,
physical-phone performance, or artistic approval claim. No player save touched,
APK built, commit or push. Source docs and hero pipeline manifest are updated.
