# Sanctuary procession implementation plan

**Goal:** Invoker and four Oculins enter from screen bottom, walk to the altar, stop; invoker chants; master appears; group kneels.
**Architecture:** Preserve approved modular scenery. Bake complete posed invoker and Oculin meshes into 24fps sprite sequences, with original staff/contact correction retained. Use existing real 3D Wraith levitation through transparent viewport. One explicit timeline drives staging, animation and manifestation.
**Tech stack:** Background Blender, Python/Pillow packing, Godot GDScript.
**Spec:** User's sequence in this chat, 2026-11-04. Group of four and approximate 28-second timeline are implementation choices. This supersedes earlier kneeling-before-manifestation storyboard.

- [x] Render walk/idle/chant/bow for the corrected invoker, walk/idle/kneel for Oculins. Archive reproducible sources and verify bounds/alpha, preserve original inputs.
- [x] Stage actors in approved sanctuary. All enter below current visible bottom, stop before altar. Master hidden until chant ends; followers kneel only after appearance. Preserve timeline handoff via Film.DURATION and deterministic present().
- [x] Native tests: chronology, seek/reset, portrait/landscape framing and captures. Review whole change; standalone preview exposes pause/scrub/replay.

Ruling: Work additively in shared workspace; retain historical previews and source art, no commits/push/APK. Four followers; invoker bows with staff while followers kneel, avoiding dragging staff through ground. No synthesized speech: incantation is gestural in this first staging.

Review: independent review found invoker staff tip visible at time zero with190px starting margin. Increased to260px and added full sprite-bounds entrance check. Corrected scene-depth insertion to exclude authored shadow layers; released scene stays hidden across layout changes. Native fixture missing staging failed before implementation, revised chronology/depth/three-size/release checks pass. Full walk support-foot IK and continuous self-collision remain outside this staging.
