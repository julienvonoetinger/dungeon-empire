# Transparent torch integration

User approved integrating the generated torch-violet-v1.png in the six-room scene.

1. Add a regression for two shader-free Sprite2D instances, shared RGBA texture,
   uniform size, foot anchors, rebuild lifecycle and entrance toggling.
2. Replace only the two old torch polygons. Import the generated source at
   256 x 384, preserve its alpha, position feet at (430,454) and (662,454).
   Keep walls, arch, floor underlay, heart and existing lights.
3. Teach spatial probes to select opaque sprite pixels and inspect sprite UVs.
   Update source-pixel checks for PNG alpha blending. Capture at native scale
   and 2x, update implemented design, and run the full capture suite.
