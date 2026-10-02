# Gothic single-leaf door: Meshy prototype

Status: separate frame and leaf integrated for normal gameplay doors.
The monolithic source below remains an archived prototype.

- Meshy task: `01a0fc5e-bbab-7764-91fc-97abb7645f35`.
- Reference: `production/meshy_assets/walls/door_gothic_single_v1.png`.
- Source: `assets/models/doors/door_gothic_single_v1.glb`.
- Request: meshy-t2, smart-topology, target 6000 triangles, PBR textures.
- Imported result: one mesh, one surface, 6174 triangles.
- Bounds: approximately 0.534 x 1.0 x 0.163 before fitting.

The isolated reference was generated using the built-in image tool from the
approved two-view concept. Prompt: isolate the single tall blackened-oak gothic
door with two riveted iron straps, left hinges, right ring handle and complete
gray stone arch; no neighbouring walls, floor, torch, lighting bake or scenery.

Run `tools/preview_gothic_door.gd` with the Godot Vulkan Mobile renderer for
screenshots with walls shown/hidden. The preview uses uniform scaling to 1.08
units high above the 0.175-unit floor, preserving the source silhouette. The
arch apex is 1.255 versus adjacent walls at 1.10. Lateral masonry fills the
remaining gap without stretching the leaf. The preview reduces metallic response.
It does not replace the functional door or alter placement rules.

`tools/inspect_gothic_door.py` inspects connectivity through Blender without
changing the GLB. After welding UV seam duplicates, the mesh has 89 connected
components, not a clean two-object frame/leaf hierarchy. An animated release
needs explicit classification/separation of the wood and hardware, a hinge
pivot, fitted wall connections, reduced texture imports, and open-state checks.
No damaged/magic variants or Android APK have been generated for this prototype.

## Separate frame and leaf

Two independent image-to-3D generations supersede the monolithic source for
the animated prototype. Originals are preserved.

| Part | Meshy task | Model |
| --- | --- | --- |
| Empty stone arch | `01a0fc84-afaa-743a-a321-a82c84b23707` | `assets/models/doors/door_gothic_frame_v1.glb` |
| Wood and iron leaf | `01a0fc86-5c5d-75b7-a7ec-41ef8dec31b8` | `assets/models/doors/door_gothic_leaf_v1.glb` |

Both references are saved under `production/meshy_assets/walls/` with matching
PNG basenames. Built-in image edits isolated each part from the approved door:
the frame prompt removes all wood/hardware and shows background through the
opening; the leaf prompt removes all stone and retains the pointed silhouette,
left hinges, iron straps and right ring handle. Each Meshy request targets 3500
triangles using meshy-t2 smart topology with PBR textures.

Run `tools/preview_gothic_door.gd -- --separate` to assemble the parts at the
validated frame height. The frame and leaf use uniform scales independently;
the leaf has a separate hinge node. The preview checks that the frame does not
move during opening and captures closed/open views with walls shown/hidden.
This remains a preview, not a replacement for gameplay doors or an APK export.

## Gameplay integration

`scripts/world/mobile_gothic_door.gd` now builds the normal door from cached
`assets/mobile/gothic-door-frame.res` and `gothic-door-leaf.res`. Rebuild them
with `tools/bake_gothic_door.gd`. Geometry is uniformly fitted offline; runtime
instances share meshes and materials. Only two albedo maps are used, capped
at 1024 with mipmaps by `tools/android/configure-gothic-door.gd`; that tool also
selects the runtime resources in existing export presets without changing versions.

The fixed arch remains 1.08 high above the floor. A single independent hinge
opens the leaf by 90 degrees over 0.25 seconds when an existing door opens.
Loading an already-open door restores its final pose directly. Damaged normal
doors keep this same model (no new damaged artwork yet); destroyed doors retain
the arch with rubble and no blocking leaf. Magic doors keep their prior model.
Placement, costs, HP and pathfinding rules are unchanged. No APK rebuilt here.

The arch now uses the same world-space grain shader and masonry vertex tint as
the corridor walls, rather than Meshy's stone albedo. Side connections register
with wall visibility: their height switches from 1.10 to a 0.23 foundation when
walls are hidden. The arch and functional leaf retain their height. Regression
tests cover both visibility states and the shared masonry material type.
