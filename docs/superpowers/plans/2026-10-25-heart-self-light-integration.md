# Heart self-light integration

> Execute inline using executing-plans; finish with requesting-code-review.

**Goal:** Adopt the accepted self-lit heart in every production scene, including
DungeonPreview without torches. Retain its exact artwork and projected effects.

**Spec:** User approved heart-self-light-v1/comparison.png ("oui c'est bien").
The heart is its own source; torch positions must not select its shadow.

**Architecture:** Freeze/adopt the two prepared PNGs, trimming only alpha-zero
padding without scaling. Pack them in the active atlas, replacing nine old heart
effects. A small canvas shader clips them to a 4x4 logical receiving-cell mask,
computed at scene rebuild; no new rasterization, geometry, PointLight2D or CPU
per-frame work. Keep ordinary mix for shadow and additive blend for violet glow.

**Constraints:** Preserve accepted source images, all other regions, geometry,
camera and layouts. Continue in current codex/2d-foundation checkout because it
contains the ongoing migration. No commit/push or device-performance claims.

## Steps

- [x] Freeze selection and current production; reproduce missing pair before fix.
- [x] Adopt exact effects, add floor-mask shaders, renderer hook, export sources.
- [x] Verify pixels, capture normal/edge/special/negative/standalone/multiple-heart
  cases, toggled torches and repeat rebuilds. Check no spill outside receiving floor.
- [x] Capture production runtime/editor, package with shaders, isolated startup.
- [x] Focused review and current documentation; retain previous review snapshots.

## Review focus

Atlas UV versus local vertex coordinates; clipping at negative/fractional cells;
two independent blend modes, correct floor/solid ordering; mask range bounded by
verified nontransparent footprint; shader dependencies included in isolated export.
General lighting of other objects and occlusion by movable props remain out of scope.

## Completion ledger

Baseline catalogue had no self-light pair. Adopted exact approved effects with
alpha-zero crops404x208/516x260; native scale retained. Atlas43regions1024square,
602507bytes,4MiB. All41 retained regions unchanged; approved crops exact,73selection
hashes unchanged. GPU captures match accepted view within2/255 per channel.
Focused rendered checks pass: torch toggle/move independent, rebuild no duplicates,
standalone unmasked, negative fractional edge/special/multiple hearts show0spilled
pixels beyond .015 raster tolerance. Initial capture helper typed-array error
fixed; final focused exit0empty stderr. Runtime68/23 exit0empty; editor19/5 exit0,
native shutdown diagnostics1518stderrbytes. Package49deps521921bytes, stage import,
export and isolated OpenGL startup exit0empty. Export repeats identical assets.
Independent focused review found no concrete issue. No commit/push/device profile.
