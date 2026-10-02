# Mobile Chest States

Dedicated full/empty images replace the command-atlas chest and its dark empty tint.
Both use white modulation, alpha-discard depth, the same canvas scale and ground anchor.
The image follows stored gold per vault; depletion and refill are reversible.
Desktop vault models and gameplay are unchanged. Mobile import budget: 512px with mipmaps.

Built-in image generation produced `assets/mobile/chest-full-v1.png` and
`assets/mobile/chest-empty-v1.png`. The full image references `command-atlas-v1.png`;
the empty image edits the full image. Original sources remain unchanged.

## Full Prompt

Create a standalone transparent square game sprite based ONLY on the open treasure chest in the second column first row of the reference atlas. One open dark wooden chest with steel and gold fittings, filled with bright gold coins. Match original painterly fantasy style and isometric camera, front and right side visible. No other atlas objects. No coins outside the chest, no floor tile or pedestal, no cast shadow outside object, no background or text. Genuine transparent alpha background. Chest centered horizontally, entire chest including open lid contained between 15% and 85% canvas width, lowest front base point at exactly 90% canvas height; maintain 10% empty transparent margin at bottom. Even readable illumination, no dramatic darkness. This is the FULL state, gold confined to interior; exterior silhouette must remain reusable for an empty version.

## Empty Prompt

Edit this EXACT full chest sprite into its EMPTY state. Remove ALL gold coins from inside, showing the empty wooden bottom and inner walls. Change NOTHING outside the interior cavity. Preserve identical open lid, metal fittings, gold trim, exterior wood, colors, brightness, canvas size, object scale, perspective, outline, bottom anchor and transparent margins. No darkening filter. Keep empty wood interior readable in warm natural light. Genuine transparent alpha background, no floor, no shadow, no text. Do not resize, recenter, crop or add objects. One sprite.

## Verification

`tests/mobile_render_test.gd` checks image choice, white modulation, depth writing,
depletion and refill. `tools/capture_mobile.gd` captures adjacent full/empty chests
at four camera rotations, then depletion and refill. Phone playtest remains necessary.
