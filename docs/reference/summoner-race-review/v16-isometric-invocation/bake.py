"""Bake seven Oculins from the original rig. Run in background Blender, then pack.py."""
from pathlib import Path
from math import radians
import sys
from mathutils import Vector, Quaternion
import bpy

root = Path(__file__).resolve().parents[4]
angle = sys.argv[-1] if "--" in sys.argv else "assembly"
out = root / "artifacts/invocation-iso" / {"assembly":"poses","overhead":"overhead","elder":"elder"}[angle]
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(next((root / "docs/reference/summoner-race-review/source").glob("*.glb"))))
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == "ARMATURE")
body = next(o for o in scene.objects if o.type == "MESH" and o.find_armature())
scene.render.engine = "CYCLES"
scene.cycles.samples = 5
scene.cycles.use_denoising = True
scene.world = bpy.data.worlds.new("Moonlight")
scene.world.color = (.32, .30, .42)
center = Vector((0, 0, .73))
for pos, energy, color in [((-3,-4,5),480,(.79,.85,1)),((2,-2,3),220,(.96,.79,.89)),((1,3,4),380,(.83,.61,1))]:
    bpy.ops.object.light_add(type="AREA", location=pos)
    light = bpy.context.object
    light.rotation_euler = (center-light.location).to_track_quat("-Z","Y").to_euler()
    light.data.energy, light.data.size, light.data.color = energy, 4, color
bpy.ops.object.camera_add()
cam = bpy.context.object
scene.camera = cam
cam.data.type, cam.data.ortho_scale = "ORTHO", 2.24
cam.location = center + Vector((0,-5,{"assembly":3.05,"elder":1.7,"overhead":7.4}[angle]))
cam.rotation_euler = (center-cam.location).to_track_quat("-Z","Y").to_euler()
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 384 if angle == "elder" else 128
scene.render.resolution_percentage = 100
pivot = bpy.data.objects.new("Facing", None)
scene.collection.objects.link(pivot)
for obj in (arm,body):
    if not obj.parent: obj.parent = pivot

def bend(index, angle):
    bone = arm.pose.bones["Bone_%03d" % index]
    # Strip the group turn so bend always uses the character's lateral axis.
    axis = (arm_basis @ bone.bone.matrix_local).to_quaternion().inverted() @ Vector((1,0,0))
    bone.rotation_quaternion = Quaternion(axis, radians(angle))

arm_basis = arm.matrix_world.copy()
def ease(t):
    return t*t*(3-2*t)

for actor, facing in enumerate([25,-35,70,-78,120,-125,165]):
    if angle == "elder" and actor != 0: break
    for frame in range(33 if angle == "elder" else 49):
        lift = min(frame / 32, 1)
        rise = ease(lift)
        gaze = ease(min(1, lift*1.18)) if frame <= 32 else 1-ease((frame-32)/16)
        pivot.rotation_euler.z = radians(facing*(1-rise) + facing*.11*rise)
        for joint in [13,18]: bend(joint, -47)
        for joint in [12,17]: bend(joint, 85)
        for joint in [11,16]: bend(joint, -22)
        bend(8, 29-43*(rise if frame <= 32 else gaze))
        bend(22, 18-(65 if angle == "overhead" else 48)*gaze)
        for joint in [27,32]: bend(joint, -38-10*gaze)
        bpy.context.view_layer.update()
        mesh = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        ground = min((mesh.matrix_world @ v.co).z for v in mesh.data.vertices)
        cam.location.z += ground
        scene.render.filepath = str(out / ("%d-%02d.png" % (actor,frame)))
        bpy.ops.render.render(write_still=True)
        cam.location.z -= ground
