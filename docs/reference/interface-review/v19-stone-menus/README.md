# Shared stone menu theme

2026-10-30. User approved v18's painted stone/violet direction and requested it
throughout the menus. This version is integrated in the native game. Historical
v18 is a generated concept; the images under `native/` here are actual captures.

## Shared artwork

Three native-alpha ImageGen sources and their complete prompts are under
`source/`: square panel, round disc and horizontal button. Original generated
files are retained in the session's `$CODEX_HOME/generated_images` folder.
`tools/prepare_stone_ui.cjs` makes bounding crops and uniform reductions only;
`preparation.json` records source SHA256, crop, size and output bytes.

- panel128: nine-slice frame for catalog, selection, pause/results and cards.
- button256x64: long actions, category tabs, catalog items and placement notices.
- round384: centre Close, utility buttons and the radial's narrow painted rims.
- face128: quiet central stone crop for variable radial sectors.
- Existing cross/pause vector shapes use pale lavender in this theme.

Four PNGs total359859 bytes and786432 RGBA bytes (0.75MiB), shared across menus;
small SVG icon storage is additional. Source images under docs are excluded by
docs/.gdignore. This is an asset budget, not measured physical-phone memory.

The normal/selected/disabled styles retain existing content margins and touch
targets. Selection uses violet; text and transaction prices remain native.
Radial geometry is still dynamic, including1–5 action sectors and short-screen
sizes. Painting is sampled inside those shapes; no fixed three-action mockup
is used as a runtime menu. Narrow rims avoid occupying the icon face area.
The full catalog remains available from its existing HUD button.

## Reproduction

Set NODE_PATH to the existing Sharp installation as documented in
../../../production/hero-animation-reproduction.md, then run:

```powershell
node tools/prepare_stone_ui.cjs
# prepare_master_ui.cjs also delegates to this preparer.
godot --headless --path . --editor --quit
godot --path . --script res://tools/capture_master_mobile.gd -- --output=res://artifacts/stone-menus/
```

Capture fixture disables persistence before tree entry and supports an output
argument; default output now goes to ignored artifacts rather than overwriting
the historical v10 review. The before images are preserved native screenshots
from the English UI/central-Close iterations. Do not overwrite them when
refreshing this version's native captures.

## Validation and limits

- The radial's superseded gold-state assertion failed11 times before switching
  to violet sockets. Final fixture:1594 checks,0 failures across11 sizes,
  real mouse/touch navigation, costs, Close, cancellation and single purchase.
- Mobile interaction fixture:0 failures; rotation227 and header health32 pass.
- Import and all fixtures exited0 with empty stderr. Graphical fixtures ran
  sequentially. No player-save access, APK, commit or push.
- 133 captured states at7 sizes, no clipped nonwrapping text. Catalog, short
  landscape pause, transfer, result and small portrait radial visually reviewed.
- Independent focused review found no actionable regression. Later horizontal
  button art was revalidated by the same native suites and captures.
- Phone rendering/performance and art preference on a physical device remain
  untested. Scrollable panels intentionally show partial content at the bottom
  of short screens; scrolling reveals the remaining actions.
