# Entrance seam correction

Approved scope: the north door and the two facade extensions in the six-room
scene. Preserve the atlas, native proportions, side walls, layout and heart.

1. Reproduce the straight y=448 floor cutoff and truncated facade crops with
   independent geometry probes before changing rendering.
2. Assemble full source stone contours behind isolated arch and torch contours.
   Extend the existing slab substrate behind their feet. Keep end cuts hidden
   by the existing corner columns, without changing those columns' geometry.
3. Inspect a GPU closeup at 2x and add it to the capture suite. Check geometry,
   source pixels, substrate, editor refresh and the unchanged reference study.
4. Synchronize implemented design and surface counts; run the full capture suite.

Other corridor and side-wall joins remain outside this focused repair.

## Verification

- Original regression: 60 failures (fixture feet, missing substrate, partial crops).
- Corrected entrance: no failures; GPU maximum error 0.7000/255.
- Full `tools/test-mobile.ps1 -All -Capture` passes, including editor refresh,
  variation modes, unchanged reference study, heart and spatial probes.
- Native and 2x captures inspected; independent read-only review found no P1/P2.
- Final inventory: 973 generated surfaces, 3 heart surfaces, 981 inspectable
  elements and 644 fixed probes; 970 generated surfaces with variation disabled.
