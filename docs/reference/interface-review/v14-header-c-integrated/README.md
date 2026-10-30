# Approved C header integrated — 2026-10-28

User approved v13 C with ten HP runes. This version replaces the runtime iron
band/round medallion with blue stone wings and an angular central keystone.
The header keeps its existing 96-unit height, or 84 on short landscapes.
It does not change game rules, camera, other HUD panels, heroes or dungeon art.

## Artwork and preparation

- Original ImageGen output copied unchanged to `source/header-c.png`; exact
  request in `source/prompt.txt`, approved v13 image used as reference. Native
  alpha; no hand repaint, color correction or separate generated parts.
- SHA256 `45efa5e8fc21c906ae7e140197d02aabc645b05e60fd0e03b4b72e42d4a64c79`.
- `tools/prepare_header_c.cjs` makes three adjacent straight crops of the same
  image and uniformly reduces each to 192 pixels high. `preparation.json`
  records bounds, source eye center and rune radius. All visible alpha>8 pixels
  lie within the combined crop; each output was independently regenerated
  byte-for-byte during review.
- Runtime PNGs: 415,602 bytes total, decoded RGBA 918,528 bytes (0.876 MiB).
  This excludes engine/import metadata and any CPU copies. Historical assets
  remain unchanged; old `eye.png` is still the Android launcher source.
- `prepare_master_ui.cjs` now invokes this preparer instead of restoring the
  old header. It retains its existing trap-icon preparation behavior.

## Runtime behavior

`hud_master_header.gd` lays out two horizontally stretchable stone wings with
small fixed end caps and one center that scales uniformly. Native labels/icons
are centered in padded lanes. Native progress fills remain clipped inside
their troughs, with borderless, non-antialiased fill rectangles. The percent
occupies the carved lower lip; no extra panel or double border.
Both gauge fills use violet (#b66af2), matching the runes and corruption, per
the user's follow-up. Timer and treasury numerals keep their gold coloring.

`master_eye.gdshader` uses the calibrated source center and pixel aspect ratio.
Ten sectors start at twelve o'clock and proceed clockwise. `ceil(HP/10)` keeps
the partly occupied tranche lit (1% = one rune, 60% = six, 100% = ten).
Only the rune annulus dims. The housing, lip and pupil retain their colors.
Vertex tint is applied once; multiplying sampled art by fragment COLOR would
sample the texture twice and darken the central masonry relative to the wings.

The center remains the pause/domain button, with a target larger than 48 units.
After user feedback, visible OR/PROCHAINES PROIES titles are removed. An hourglass
marks the countdown and crossed swords mark elapsed raid time; the gold stack
already identifies the treasury. Icon/value groups are vertically recentered.
Phase details remain in the header tooltip, with ordinary French wording.
Existing timer/gold rules are unchanged. Both new icons are small native SVGs.
The value rows use the actual painted face bounds (source-crop y84 upper fissure
to y230 lower groove), scaled with header height. A small Cinzel digit-ink offset
centers visible numerals rather than the font's padded line box. The earlier
fixed y24/32-high lane placed the text about six pixels too high at 96px height.

## Reproduce

Use Node with `sharp` to run `tools/prepare_header_c.cjs`, then a Godot import.
Use graphical Godot (Compatibility) for GPU checks; headless rendering cannot
produce the frame-post-draw images:

```text
godot --headless --editor --path . --import --quit
godot --path . --script res://tools/verify_header_c.gd
godot --path . --script res://tools/capture_header_c.gd
godot --path . --script res://tools/verify_header_gauges.gd
godot --path . --script res://tools/verify_master_mobile.gd
godot --path . --script res://tools/verify_mobile_rotation.gd
```

On Windows, retain the native process handle and inspect both exit code and
stderr. New scripts set `persistence_enabled=false` before tree entry. Existing
mobile regressions use their own ignored artifacts save slots, never player data.

## Evidence and limits

- Initial new-layout check failed twice on the old header; retained locally in
  `artifacts/header-c/red.*.log`. Layout trials exposed label/rail overlap, fixed
  by measured text sizing and separated vertical lanes.
- Final focused verifier after title removal: 856 checks, zero failures. Four header sizes,
  seven phase states, 225/38,400 gold; label bounds, icon gaps, aspect, rail
  separation, actual viewport click, sixteen HP values and three source-color
  comparisons. Ready preparation and construction included after review.
- Gauge verifier refreshed for violet fills: 40 fill/scale cases, zero leaked pixels. Mobile
  interaction suite: zero failures. Rotation suite: 227 checks, zero failures.
- Five actual-game captures (1280×720, 844×390, 568×299, 390×844, 320×568).
  Portrait/landscape, long amount and enlarged runes inspected. Captures refreshed
  after title removal, with an additional active-raid header. Frozen capture
  sessions explicitly refresh after resizing. Normal gameplay refreshes each frame.
- Final native runs exited 0 with empty stderr. Independent final code/art-pipeline
  review of the C integration reported no important findings. The subsequent
  title/icon adjustment uses the existing focused checks and refreshed captures.
  This is desktop rendering evidence,
  not a physical Android/DPI/sensor/performance test. No APK, commit or push.
