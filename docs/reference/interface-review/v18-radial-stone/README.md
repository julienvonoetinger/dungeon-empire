# Stone radial menu proposal

2026-10-30. The user finds the plain radial inconsistent with the painted stone
header. This is an ImageGen visual proposal, not production art or a native
game screenshot. The user approved its direction and requested the same look
throughout the menus on2026-10-30. See ../v19-stone-menus for native integration.

- `before.png`: native game capture after the centre Close change.
- `proposal.png`: unchanged built-in ImageGen output.
- `prompt.txt`: full prompt, including the required menu structure.
- Reference: `../v14-header-c-integrated/source/header-c.png` (approved C header).
- Original output: `C:/Users/A/.codex/generated_images/01a15ce9-67f0-77e2-a485-14b09d65f5da/exec-fbdb8bd6-2890-4174-84b0-eb95f50833bc.png`.

Direction: slate stone faces, chipped bevels, recessed joints, sparse violet
fissures, separate price sockets, violet selected category and inset Close.
All four categories and three trap choices remain visible. No second Close.

ImageGen slightly reinterprets the footprint, icons and scene details. Do not
derive gameplay geometry from this image. An implementation must keep native
touch targets and live prices, support different numbers of action sectors,
keep price digits upright, and validate portrait/short landscape. Text and
icons must remain independent from the painted backing. No runtime assets,
gameplay, player saves or APK changed in this visual proposal.
