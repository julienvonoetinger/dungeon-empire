# Dark painted header insignia — 2026-10-28

User still finds the header text/icons too heroic. This iteration replaces thin
gold numerals and flat gold symbols with pale lavender/ivory bold numbers,
painted blue-slate/violet insignia and worn treasure coins. Current runtime uses
the iteration; visual acceptance remains with the user. Approved C masonry,
ten HP runes, violet gauges, layout budget and gameplay rules are unchanged.

## Assets

Built-in ImageGen made three independent native-alpha images, using the v14
native header and actual dungeon screenshot only as material/style references.
Unmodified originals and exact prompts are in `source/`: hourglass (countdown),
stone skull (active-raid danger), three worn gold coins (currency). No generated
text. The skull is symbolic danger, not an enemy character replacement.

`tools/prepare_header_icons.cjs` crops alpha>8 bounds plus four source pixels,
uniformly scales to a 60px box and adds two transparent pixels on each side.
No recoloring, repaint, stretch or warp. Each result is 64×64, shown at 26 units
normally and 22 in narrow layouts. PNG total 25,031 bytes; decoded RGBA 49,152
bytes. `preparation.json` records source hashes/crops and font provenance.
The font is additional to these texture figures. Old global coin badges and
other UI glyphs are untouched; these replacements are header-only.

The variable [Grenze font](https://github.com/google/fonts/tree/main/ofl/grenze)
is distributed unchanged with its [SIL OFL license](https://raw.githubusercontent.com/google/fonts/main/ofl/grenze/OFL.txt).
Original files are retained under `source/` and copied into assets by the
preparer. Weight700, OpenType lining/tabular figures (`lnum`, `tnum`), MSDF.
This avoids old-style descending digits and variable-width timer changes.
Labels have a restrained dark outline and no gold glow. Font size adapts to
available width; heart percent uses the same font.

## Alignment and verification

The row still follows source masonry y84..230. Grenze has taller ascender/line
metrics than Cinzel; its optical offset is -11% of font size, not Cinzel's +9%.
The initial trial failed the existing rail-bound checks and visibly placed the
digits below their icons. Lining figures plus corrected optical offset resolve
this. Do not reuse another font's line-box offset without native inspection.

Current `tools/verify_header_c.gd`: 856 checks, zero failures, exit0, empty stderr.
Four header sizes, seven phases, short/long values, actual menu input, source
color and sixteen HP values. No new tests needed for this visual revision;
existing checks were reused. `tools/capture_header_c.gd` writes five actual
game sizes plus active-raid header into this directory. Landscape, small-screen,
portrait and long-amount outputs visually inspected. Local review links checked.
No physical-phone/DPI/performance verification, APK, player saves, commit/push.

Regenerate: Node with `sharp`, `node tools/prepare_header_icons.cjs`; then native
Godot import and the two scripts above. `prepare_master_ui.cjs` includes the new
icon/font preparation. Historical v14 captures remain unchanged for comparison.
