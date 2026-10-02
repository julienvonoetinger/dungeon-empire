# Mobile visual corrections

September 29, 2026. Changes are scoped to mobile mode; legacy desktop remains unchanged.

- Exterior bedrock is now split into irregular, separated rock columns with varied heights,
  below the masonry. This supersedes the continuous surface used in the first correction.
- Mobile room walls use four staggered courses of modeled beveled stones, individual
  coping stones and taller joint pillars. Existing paired wall runs, dig rebuilding and
  foreground cutaways remain in use. Each wall module is one mesh, not one draw per stone.
- Traps retain the surrounding floor and use shallow mechanisms. Spent spikes retract;
  snares relax and void rings lose their glow. Charges remain visible.
- Core art writes depth and fits a smaller footprint. All states retain full artwork colors:
  intact above 50 HP, damaged at 1-50 HP, destroyed at 0 HP. Repair restores the matching
  image. Mobile heroes attack from outside the 2x2 footprint.
- Stationary Core strikes update model orientation; routing, fleeing and jumps cannot
  traverse the Core. Thieves detour to treasure.

Validation: 40 headless test scripts passed. Compatibility and Forward+ captures cover
four camera rotations. `tools/capture_mobile.gd` captures Core health 100/51/50/1/0/100 and
all three traps armed/spent. These checks do not prove every possible wall overlap or
actual phone performance. The Android debug APK was rebuilt; device playtest pending.

## Generated Asset

Built-in image generation, copied into `assets/mobile/bedrock-v1.png`.
Imported at 1024 pixels with mipmaps. Final prompt:

> Generate a square seamless tiling albedo texture for natural fractured dungeon bedrock,
> hand-painted high quality dark fantasy mobile game environment. Orthographic straight
> top-down flat material swatch fills entire image edge to edge. Dense irregular craggy
> natural charcoal-gray limestone rock, broad angular fracture planes, finer mineral grain
> and thin uneven dark cracks, subtle muted silver and neutral gray mineral variation.
> Moderate light midgray exposure, no blue tint, no purple or brown tint. Absolutely no
> bricks, no cobblestone, no floor tiles, no regular grid, no repeating square blocks,
> no objects, no gems, no UI, no text, no border, no perspective. Soft nondirectional
> diffuse light baked minimally, suitable to apply to 3D low-poly rock mass. Seamless
> opposing edges. Save the image as a project texture asset.

## Core State Images

Built-in image generation edits referencing `assets/mobile/core-monument-v1.png`.
Outputs: `assets/mobile/core-damaged-v1.png`, `assets/mobile/core-destroyed-v1.png`.
Both use transparent square canvases, imported at 1024 with mipmaps.

Damaged prompt:

> Edit this exact transparent game sprite to create its DAMAGED health state. Preserve square canvas, transparent alpha background, exact camera angle, overall scale, base footprint, base bottom anchor, lighting brightness, stone and gold colors. Do not zoom or recenter. Keep the same recognizable four-pillar stepped stone circular dungeon Core with purple orb. Show substantial structural damage clearly readable at mobile scale: the rear pillar top broken off, left pillar chipped, one gold orbital ring snapped with a missing segment, several broad fresh stone fractures and small fallen stone/gold fragments resting ON the existing platform. Purple orb still alive with uneven electrical arcs. Do NOT darken or desaturate the artwork. Maintain original bottom edge and platform outline exactly. No background, no floor outside platform, no text, no UI. Output one damaged sprite, not a comparison sheet.

Destroyed prompt:

> Edit this exact transparent game sprite to create its DESTROYED health state. Preserve square canvas, transparent alpha background, exact camera angle, overall scale, base footprint and original base bottom anchor, lighting brightness, stone and gold colors. Do not zoom, enlarge or recenter the remaining ruins: leave empty transparent space where the original tall parts stood. Keep the stepped circular stone platform EXACTLY in its original lower-canvas position and dimensions. The central floating purple orb is completely GONE, the orbital gold rings have collapsed into broken curved fragments resting on the platform, all four pillars broken down to short jagged stumps with rubble on the platform, shattered purple crystals and faint residual purple sparks at center. The damage must be unmistakable at mobile size. Well lit gray stone and gold rubble, NOT blackened, NOT darkened, NO overall dimming. Maintain original bottom edge and outer platform outline exactly. No background, no floor outside platform, no text, no UI. Output one destroyed sprite, not a comparison sheet.
