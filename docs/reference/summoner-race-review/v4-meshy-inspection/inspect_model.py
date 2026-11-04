"""Run with blender --background --factory-startup --python inspect_model.py."""
import hashlib
import json
import struct
from pathlib import Path

import bpy
from mathutils import Vector

out = Path(__file__).resolve().parent
source = out.parent / "source" / "Meshy_AI_Grumgaze_20261102_character.glb"
raw = source.read_bytes()
digest = hashlib.sha256(raw).hexdigest()
assert digest == "2ed56ff6ec1cac294436df2ecf1fdc4b906b3b7a1b1835f4b77f84d179dccfbe"
gltf = json.loads(raw[20:20 + struct.unpack_from("<I", raw, 12)[0]])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
scene = bpy.context.scene
mesh, = [obj for obj in scene.objects if obj.type == "MESH" and obj.find_armature()]
arm, = [obj for obj in scene.objects if obj.type == "ARMATURE"]
coords = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
lo, hi = [Vector([f(v[i] for v in coords) for i in range(3)]) for f in (min, max)]
center = (hi + lo) * 0.5
bone_names = set(arm.data.bones.keys())
weighted = {g.index for g in mesh.vertex_groups if g.name in bone_names}
primitive, = gltf["meshes"][0]["primitives"]
accessors = gltf["accessors"]
report = {
    "source_sha256": digest,
    "gltf_vertices": accessors[primitive["attributes"]["POSITION"]]["count"],
    "triangles": len(mesh.data.polygons),
    "rig_joints": len(gltf["skins"][0]["joints"]),
    "unweighted_imported_vertices": sum(not any(g.group in weighted and g.weight > 0 for g in v.groups) for v in mesh.data.vertices),
    "animation_clips": len(gltf.get("animations", [])),
    "dimensions_blender_xyz": list(hi - lo),
    "textures": {img.name: list(img.size) for img in bpy.data.images if img.packed_file},
}
(out / "inspection.json").write_text(json.dumps(report, indent=2) + "\n")
scene.render.engine = "CYCLES"
scene.cycles.samples = 8
scene.cycles.use_denoising = True
scene.world = bpy.data.worlds.new("Studio")
scene.world.use_nodes = True
scene.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = 0.7
for pos, power, size in [((-3,-4,5),420,4), ((3,-1,3),200,3), ((1,3,4),350,3)]:
    bpy.ops.object.light_add(type="AREA", location=pos)
    lamp = bpy.context.object
    lamp.rotation_euler = (center - lamp.location).to_track_quat("-Z","Y").to_euler()
    lamp.data.energy = power
    lamp.data.shape = "DISK"
    lamp.data.size = size
bpy.ops.object.camera_add()
scene.camera = cam = bpy.context.object
cam.data.type = "ORTHO"
cam.data.ortho_scale = 2.22
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
for name, direction in [("front",(0,-1,0)), ("profile",(1,0,0)), ("back",(0,1,0)), ("isometric",(1,-1,0.8165))]:
    axis = Vector(direction).normalized()
    cam.location = center + axis * 6
    cam.rotation_euler = (-axis).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath = str(out / (name + ".png"))
    bpy.ops.render.render(write_still=True)

