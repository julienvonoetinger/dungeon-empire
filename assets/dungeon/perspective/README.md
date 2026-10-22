# Historical perspective reference

`reference-atlas.png` is the user's original 1672 × 941 illustration, copied
without editing. It remains the artistic reference for the slate-blue masonry,
overhead floors, visible wall facades, piers and violet lighting.

The main `scenes/SixRoomPreview.tscn` no longer samples this image.
Its complete native-alpha sprites are in `assets/dungeon/alpha-kit/` and
`assets/dungeon/torches/`. See `GAME_DESIGN.md` for the current assembly.

`scenes/PerspectiveRoom.tscn` preserves the historical calibration study:
55 separate elements reproduce source frame (0, 120, 560, 510) using
`reference_pieces.gd`. Its polygons, source positions and baked illumination
are unchanged. This is an isolated reference experiment, not a production
cutout pipeline to extend or reuse.

`artifacts/reference-comparison.png` compares only this study to the original
frame. Its pixel score does not measure the appearance of the new six-room
assembly. Inspect the actual `dungeon-2d.png`, entry, heart and 2x join captures
for that purpose.