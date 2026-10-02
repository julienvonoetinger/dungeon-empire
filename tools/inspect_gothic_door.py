"""Inspect Meshy's door topology before attempting an animated split."""
from pathlib import Path

import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT / "assets/models/doors/door_gothic_single_v1.glb"))
for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        continue
    # Ignore UV seam duplicates when assessing physical connectivity.
    welded = bmesh.new()
    welded.from_mesh(obj.data)
    bmesh.ops.remove_doubles(welded, verts=list(welded.verts), dist=0.00001)
    welded.to_mesh(obj.data)
    welded.free()
    adjacent = [[] for _ in obj.data.vertices]
    for edge in obj.data.edges:
        a, b = edge.vertices
        adjacent[a].append(b)
        adjacent[b].append(a)
    unseen = set(range(len(adjacent)))
    components = []
    while unseen:
        stack = [unseen.pop()]
        count = 0
        while stack:
            vertex = stack.pop()
            count += 1
            for neighbour in adjacent[vertex]:
                if neighbour in unseen:
                    unseen.remove(neighbour)
                    stack.append(neighbour)
        components.append(count)
    print("DOOR_TOPOLOGY", obj.name, "vertices", len(adjacent), "component_count", len(components), "largest", sorted(components, reverse=True)[:12])
