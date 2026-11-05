"""Bake the supplied GLB at the sanctuary's 30-degree orthographic pitch.
Run with Blender in background. The camera looks from the procession up the steps.
"""
import bpy
import numpy as np
from mathutils import Vector
from pathlib import Path
from math import sqrt

HERE = Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(HERE/"source/autel.glb"))
model = next(o for o in bpy.context.scene.objects if o.type == "MESH")
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
world = bpy.data.worlds.new("Clair de lune")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (.43,.47,.68,1)
world.node_tree.nodes["Background"].inputs[1].default_value = .55
scene.world = world
def aim(obj, target):
    obj.rotation_euler = (target-obj.location).to_track_quat("-Z","Y").to_euler()
focus = Vector((0,0,-.31))
cam = bpy.data.objects.new("Vue du rituel",bpy.data.cameras.new("Orthographique"))
scene.collection.objects.link(cam)
scene.camera = cam
cam.data.type = "ORTHO"
cam.data.ortho_scale = 2.9
direction = Vector((0,-sqrt(3)/2,.5))
cam.location = focus+direction*6
aim(cam,focus)
for xyz,power,color,size in [
    ((-3,-3,5),525,(1,.88,.77),4),((3,-2,3),170,(.65,.71,1),3),
    ((1,3,4),440,(.75,.70,1),3)]:
    lamp = bpy.data.lights.new("Reflet", "AREA")
    lamp.energy, lamp.color, lamp.size = power,color,size
    ob = bpy.data.objects.new(lamp.name,lamp)
    scene.collection.objects.link(ob)
    ob.location = xyz
    aim(ob,focus)
scene.render.filepath = str(HERE/"autel-isometrique.png")
bpy.ops.render.render(write_still=True)

# Classify actual visible mesh samples so characters and magic can pass between
# stelae. All seven layers use the same lighting, projection and material bake.
from mathutils.bvhtree import BVHTree
mesh = model.data
vertices = [model.matrix_world @ v.co for v in mesh.vertices]
tree = BVHTree.FromPolygons(vertices,[p.vertices[:] for p in mesh.polygons])
pixel = cam.data.ortho_scale/768
up = Vector((0,.5,sqrt(3)/2))
right = Vector((1,0,0))
# Original sanctuary numbering, from near left around the ring to near right.
pillars = [(-.41,-.72,.15,.15),(-.66,-.12,.17,.20),(-.35,.76,.23,.25),
           (.35,.76,.23,.25),(.66,-.12,.17,.20),(.41,-.72,.15,.15)]
labels = np.full((768,768),255,dtype=np.uint8)
for y in range(75,575):
    start = cam.location + up*((384-y-.5)*pixel)
    for x in range(128,641):
        hit,_,_,_ = tree.ray_cast(start+right*((x+.5-384)*pixel), -direction)
        if hit is None:
            continue
        distances = [((hit.x-px)/rx)**2+((hit.y-py)/ry)**2 for px,py,rx,ry in pillars]
        idx = int(np.argmin(distances))
        labels[y,x] = idx+1 if distances[idx] < 1 or hit.z > -.21 else 0
# Intermediate numerical data are consumed by pack_altar.py (system Pillow).
import tempfile
cache = Path(tempfile.gettempdir())/"oculin-altar-bake"
cache.mkdir(exist_ok=True)

(cache/"layers.raw").write_bytes(labels.tobytes())
import json
mesh.calc_loop_triangles()
plane_z = min(v.z for v in vertices)
shadow = []
for v in vertices:
    # Shadow falls away from the key light, behind the rock.
    dx,dy = .24*(v.z-plane_z),.18*(v.z-plane_z)
    shadow.append([round(384+(v.x+dx)/pixel),round(384-(.5*(v.y+dy)+up.z*(plane_z-focus.z))/pixel)])
(cache/"shadow.json").write_text(json.dumps([[shadow[i] for i in tri.vertices] for tri in mesh.loop_triangles]))

# Project the base perimeter to the terrain plane for the procession pathfinder.
from mathutils.geometry import convex_hull_2d
floor_points = [Vector((round(-6+v.x/pixel,1),round(7-(v.y*.5+(plane_z-focus.z)*up.z)/pixel,1)))
                for v in vertices if v.z < plane_z+.12]
footprint = [[round(c,1) for c in floor_points[i]] for i in convex_hull_2d(floor_points)]
(HERE/"footprint.json").write_text(json.dumps(footprint,separators=(",",":"))+"\n")
