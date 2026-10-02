# Meshy entrance integration

Approved reference: `production/meshy_assets/walls/entrance_rock_arch_v1.png`.
Meshy task: `01a0fbf2-c116-7333-9373-552591f246c2`.
Source model: `assets/models/walls/entrance_rock_arch_v1.glb` (4900 triangles).

`tools/bake_mobile_entrance.gd` creates `assets/mobile/entrance-rock-v1.res`.
It fits the entrance to 1.6 x 1.4 x 0.85 world units, grounds its base, preserves
the recessed passage, and draws outer rock shoulders back behind the jambs.
Rebuild this resource after changing the fit. The original GLB is preserved.

`assets/rendering/entrance_stone.gdshader` shares the wall grain, world-space
texture scale, masonry tint and roughness. Source shading only darkens the inner
tunnel, not the entire facade. The albedo atlas is capped at 1024px with mipmaps;
unused Meshy normal and metallic maps are not referenced by the runtime resource.

Two masonry connectors use the existing pillar geometry and wall material.
They register with the explicit wall-visibility toggle and switch to foundations
when walls are hidden. The existing two torch visuals are retained; no new lights
are added. Original procedural stairs are removed because the model has stairs.
Placement, pathfinding and hero entry rules are unchanged.

Validation: targeted entrance test passes; Vulkan captures cover all four camera
angles in `artifacts/entrance-detail-*.png`, alongside normal environment captures.
Android export selections include the baked resource, shader and atlas.
No new APK or phone performance validation in this change.

## Entrance torch clearance

Entrance torch visuals use half the standard wall torch size (0.325 world units
high). Their bounds are grounded and centered on mounts at x +/-0.37, y 0.40,
z 0.20 in entrance space. Connector pillars move back to z -0.02. This keeps
backplates clear of the connectors and inside the corridor wall planes while
remaining attached to the arch when wall connectors switch to foundations.
Other dungeon torches are unchanged. The visual test checks size, connector
non-intersection and side-wall clearance for all four entrance orientations.
Capture fixtures now save close views with walls both shown and hidden.
