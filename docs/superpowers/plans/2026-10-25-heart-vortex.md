# Heart vortex animation implementation plan

> **For agentic workers:** Use superpowers:executing-plans for this authorized continuation.

**Goal:** Animate the approved vortex gently, with an inward spiral and violet pulse, while keeping pedestal, ring shape and neck stable.

**Spec:** User accepted the previous proposal with "ok vas-y". Current native heart artwork and the isometric perspective remain authoritative.

**Architecture:** Isolate the interior in a shader mask within the existing atlas sprite, instead of extracting new image layers. This preserves exact approved pixels/alpha, occlusion and memory. Offline preparation supplies the painted centre/radius, with the same frozen geometry. A small renderer-owned animator drives a bounded phase and pauses with gameplay, independently of asset refresh. Editor previews remain static.

**Tech Stack:** Godot4 CanvasItem shader and GDScript; existing Node/Sharp export, background verification.

## Constraints

- Existing feature checkout/uncommitted work stays intact. No native UI control, app restart, automated tests, commit or push.
- Original source, all136 prepared pixels, atlas pages, geometry, layout, projection, heart shadows and existing light remain unchanged. Only heart metadata adds the vortex coordinates.
- One atlas sprite/material per heart; no per-frame scene rebuild or texture generation.
- Runtime cycle12seconds; restrained pulse3times per cycle. No TIME reliance because it ignores pause.
- Preserve user project.godot/main scene and save files.

## Review focus

Atlas sampling must not bleed into neighbouring regions; motion mask must exclude stone/neck/rim shape. Phase wrap must be continuous. Pausing, disabled effect, rebuilds and multiple hearts must not create orphan animation materials or move the image. Standalone, gameplay and layout renderers must share the effect.

## Tasks

- [x] Preserve baseline and add centre/radius metadata in heart preparation/export; both atlas pages and all136 prepared region pixels stay unchanged.
- [x] Add focused vortex shader/animator, renderer binding and gameplay pause hook.
- [x] Background import and17 static state observations; same-fragment WebGL preview at mobile size, wrap/static-mask and shader dependency loading checked. Native GPU/device limitations documented.
- [x] Focused independent read-only review found no concrete issue. Documentation and evidence saved, with no commit/push.
