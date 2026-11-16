"""Run with background Blender. Render the messenger at its existing camera scale."""
from pathlib import Path
import math

import bpy
from mathutils import Quaternion, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
FRAMES = ROOT / "artifacts/oculin-trap-hurt/frames"
bpy.ops.wm.open_mainfile(filepath=str(HERE.parent / "v5-procession/oculin-poses.blend"))
scene = bpy.context.scene
scene.frame_set(0)
rig = next(obj for obj in scene.objects if obj.type == "ARMATURE")
body = next(obj for obj in scene.objects if obj.type == "MESH" and obj.find_armature() == rig)
camera = scene.camera
camera.animation_data_clear()
rig.animation_data_clear()
rest = {bone.name: bone.matrix_basis.copy() for bone in rig.pose.bones}
scene.render.resolution_x = scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.cycles.samples = 8

# Pose angles in degrees, camera registration in model units. The struck foot
# pulls up first; the other leg takes the weight again on landing.
# torso, head, struck thigh/shin, other thigh/shin, shoulders, elbows, rise, retreat
poses = [
    (  5,  -6, -14,  30,   9,   8, -16, -22, .00, .00),
    (-17, -12, -36,  72,   3,  24, -44, -39, .09, .05),
    (-29, -16, -60, 101, -16,  43, -70, -51, .22, .14),
    (-24, -12, -54,  93, -19,  39, -63, -46, .19, .17),
    (-14,   1, -40,  78,  -6,  24, -45, -34, .08, .17),
    ( 12,   7, -25,  56, -25,  49, -34, -26, .00, .14),
    (  5,  -3, -12,  30,  -9,  21, -21, -15, .00, .08),
    (  0,   0,   0,   0,   0,   0,   0,   0, .00, .00),
]
angles = {"n":0, "ne":-45, "e":-90, "se":-135,
          "s":180, "sw":135, "w":90, "nw":45}

def bend(index, degrees):
    bone = rig.pose.bones[f"Bone_{index:03}"]
    joint = (rig.matrix_world @ bone.bone.matrix_local).to_quaternion()
    local_axis = joint.inverted() @ Vector((1, 0, 0))
    bone.matrix_basis = rest[bone.name] @ Quaternion(local_axis, math.radians(degrees)).to_matrix().to_4x4()

for frame, (torso, head, thigh, shin, other_thigh, other_shin, arm, elbow, rise, retreat) in enumerate(poses):
    for index, angle in [(8,torso), (22,head), (13,thigh), (12,shin), (11,-shin*.40),
                         (18,other_thigh), (17,other_shin), (16,-other_shin*.55),
                         (33,arm), (32,elbow), (28,arm*.76), (27,elbow*.86)]:
        bend(index, angle)
    bpy.context.view_layer.update()
    mesh = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    ground = min((mesh.matrix_world @ v.co).z for v in mesh.data.vertices)
    focus = Vector((0, -retreat, .8 + ground - rise))
    for direction, degrees in angles.items():
        a = math.radians(degrees)
        camera.location = focus + Vector((math.sin(a)*math.sqrt(3), math.cos(a)*math.sqrt(3), 1)).normalized()*7
        camera.rotation_euler = (focus-camera.location).to_track_quat("-Z", "Y").to_euler()
        folder = FRAMES / direction
        folder.mkdir(parents=True, exist_ok=True)
        scene.render.filepath = str(folder / f"{frame:02}.png")
        bpy.ops.render.render(write_still=True)
