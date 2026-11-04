"""Normalize the Meshy preview, simplify it, and skin it to a five-link spine."""
from pathlib import Path
import bpy
from mathutils import Vector
folder = Path(__file__).resolve().parent
root = folder.parents[3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(folder/"meshy-vortex.glb"))
mesh, = [o for o in bpy.context.scene.objects if o.type == 'MESH']
mesh.data.transform(mesh.matrix_world.copy())
mesh.parent = None
from mathutils import Matrix
mesh.matrix_world = Matrix.Identity(4)
verts = mesh.data.vertices
lo = Vector([min(v.co[i] for v in verts) for i in range(3)])
hi = Vector([max(v.co[i] for v in verts) for i in range(3)])
mid = (lo+hi)*.5
for v in verts:
    v.co = (v.co-mid)*(1.88/(hi.z-lo.z))
mesh.name = "Vortex"
bpy.context.view_layer.objects.active = mesh
mesh.data.calc_loop_triangles()
simplify = mesh.modifiers.new("Mobile silhouette", 'DECIMATE')
simplify.ratio = min(1.,12000/len(mesh.data.loop_triangles))
bpy.ops.object.modifier_apply(modifier=simplify.name)
mesh.data.materials.clear()
bones = bpy.data.armatures.new("Vortex spine")
rig = bpy.data.objects.new("InvocationRig",bones)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
prev = None
for i in range(5):
    b = bones.edit_bones.new("Coil%d"%i)
    b.head = (0,0,-.94+i*.376)
    b.tail = (0,0,-.94+(i+1)*.376)
    if prev: b.parent, b.use_connect = prev, True
    prev = b
bpy.ops.object.mode_set(mode='OBJECT')
groups = [mesh.vertex_groups.new(name="Coil%d"%i) for i in range(5)]
for v in mesh.data.vertices:
    height = max(0.,min(4.,(v.co.z+.94)/.376-.5))
    lower = int(height)
    w = height-lower
    groups[lower].add([v.index],1-w,'REPLACE')
    if w: groups[lower+1].add([v.index],w,'REPLACE')
mesh.parent = rig
skin = mesh.modifiers.new("Animated coils",'ARMATURE')
skin.object = rig
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
rig.select_set(True)
dest = root/"assets/game/introduction/invocation/presence.glb"
bpy.ops.export_scene.gltf(filepath=str(dest),export_format="GLB",use_selection=True,export_materials="NONE",export_texcoords=False,export_animations=False)
print("Rigged",len(mesh.data.vertices),"vertices",dest)
