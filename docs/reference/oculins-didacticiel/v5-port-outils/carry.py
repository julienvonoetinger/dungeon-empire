"""Repose the carrying arm of the archived walk and render the existing four cameras.

blender -b --python-exit-code 1 --python carry.py -- <role> <output> [--render] [--optix]
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


SETTINGS = {
    # Object, shoulder pitch/yaw, forward/sideways shaft lean, blade roll.
    "mineur": ("Pioche", -76, -46, -.12, -.06, .40),
    "menuisier": ("Marteau", -57, -52, -.12, -.06, .65),
}
VIEWS = {"se": (-1,-1), "sw": (1,-1), "nw": (1,1), "ne": (-1,1)}
args = sys.argv[sys.argv.index("--") + 1:]
role, destination = args[:2]
folder = Path(destination).resolve() / role
folder.mkdir(parents=True, exist_ok=True)
free_hand = role == "scientifique"
if free_hand:
    prop = "Diapason"
else:
    prop, pitch, yaw, forward, lateral, roll = SETTINGS[role]
source = Path(__file__).resolve().parent.parent / "v4-marche" / role / (role+"-marche.blend")
bpy.ops.wm.open_mainfile(filepath=str(source))
scene = bpy.context.scene
tool, body = scene.objects[prop], scene.objects[role.capitalize()]
rig = tool.parent
hand = rig.pose.bones[tool.parent_bone]
wrist = hand.parent
shoulder = wrist.parent.parent
if free_hand:
    # The archived equipped hand has a boolean cut for the handle.
    body.modifiers.remove(body.modifiers["Empreinte du manche"])
    bpy.data.objects.remove(tool, do_unlink=True)
    tool = None


def rotate_joint(joint, rotation):
    original = rig.matrix_world @ joint.matrix
    updated = rotation.to_4x4() @ original
    updated.translation = original.translation
    joint.matrix = rig.matrix_world.inverted() @ updated
    bpy.context.view_layer.update()


def surface(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.data
    xyz = np.empty(len(mesh.vertices)*3, np.float32)
    mesh.vertices.foreach_get("co", xyz)
    matrix = np.asarray(evaluated.matrix_world)
    xyz = xyz.reshape(-1,3) @ matrix[:3,:3].T + matrix[:3,3]
    mesh.calc_loop_triangles()
    indices = np.empty(len(mesh.loop_triangles)*3, np.int32)
    mesh.loop_triangles.foreach_get("vertices", indices)
    triangles = indices.reshape(-1,3)
    return xyz, triangles, BVHTree.FromPolygons(xyz.tolist(), triangles.tolist(), all_triangles=True)


def pose_bounds(points, triangles):
    # Bound complete triangles in height bands so a high blade does not give
    # the lower handle its full width when checking clearance above a low wall.
    heights = points[triangles, 2].mean(axis=1)
    cuts = np.linspace(points[:, 2].min(), points[:, 2].max(), 9)[1:-1]
    bands = np.digitize(heights, cuts)
    boxes = []
    for band in np.unique(bands):
        vertices = points[triangles[bands == band].ravel()]
        boxes.append([vertices.min(axis=0).tolist(), vertices.max(axis=0).tolist()])
    return boxes


# Sample the untouched action before writing keys. The wrist is not keyed in v4.
original = []
untouched = [joint for joint in rig.pose.bones if joint != shoulder and shoulder not in joint.parent_recursive]
walk = []
for frame in range(1,18):
    scene.frame_set(frame)
    original.append((shoulder.matrix_basis.copy(), wrist.matrix_basis.copy()))
    walk.append([np.asarray(joint.matrix).copy() for joint in untouched])
if not free_hand:
    grip = (rig.matrix_world @ hand.matrix).inverted() @ tool.matrix_world
poses = []
for frame, (arm_basis, wrist_basis) in enumerate(original, 1):
    scene.frame_set(frame)
    shoulder.matrix_basis, wrist.matrix_basis = arm_basis, wrist_basis
    bpy.context.view_layer.update()
    if free_hand:
        rotate_joint(shoulder, Matrix.Rotation(math.radians(19),3,"Y"))
        poses.append((shoulder.matrix_basis.copy(), wrist.matrix_basis.copy()))
        continue
    rotate_joint(shoulder, Matrix.Rotation(math.radians(yaw),3,"Z") @ Matrix.Rotation(math.radians(pitch),3,"X"))
    basis = tool.matrix_world.to_3x3().normalized()
    shaft = Vector((lateral, forward, 1.)).normalized()
    aim = basis.col[2].rotation_difference(shaft)
    blade = aim @ basis.col[0]
    lengthwise = Vector((0,1,0))
    lengthwise = (lengthwise-shaft*lengthwise.dot(shaft)).normalized()
    if lengthwise.dot(blade) < 0:
        lengthwise = -lengthwise
    twist = math.atan2(shaft.dot(blade.cross(lengthwise)), blade.dot(lengthwise)) * roll
    rotate_joint(wrist, Matrix.Rotation(twist,3,shaft) @ aim.to_matrix())
    poses.append((shoulder.matrix_basis.copy(), wrist.matrix_basis.copy()))

for frame, matrices in enumerate(poses, 1):
    scene.frame_set(frame)
    for joint, matrix in zip((shoulder,wrist), matrices):
        joint.matrix_basis = matrix
        for channel in ("location", "rotation_quaternion", "scale"):
            joint.keyframe_insert(channel,frame=frame,group=joint.name)

bounds = []
axes = []
for frame in range(1,18):
    scene.frame_set(frame)
    for joint, previous in zip(untouched, walk[frame-1]):
        assert np.max(np.abs(np.asarray(joint.matrix)-previous)) < .0001, (role,frame,joint.name)
    shoulder_z = (rig.matrix_world @ shoulder.head).z
    elbow_z = (rig.matrix_world @ wrist.parent.head).z
    grip_z = (rig.matrix_world @ hand.head).z
    assert elbow_z < shoulder_z - .08 and grip_z < shoulder_z, (role,frame,"raised carrying arm")
    if free_hand:
        assert grip_z < shoulder_z - .3, (role,frame,"free hand")
        if frame in (1, 17):
            points, _, _ = surface(body)
    else:
        points, triangles, metal = surface(tool)
        _, _, skin = surface(body)
        crossings = len(skin.overlap(metal))
        assert not crossings, (role, frame, "body/tool crossings", crossings)
        relative = (rig.matrix_world @ hand.matrix).inverted() @ tool.matrix_world
        assert np.max(np.abs(np.asarray(relative)-np.asarray(grip))) < .0001
        axes.append(tool.matrix_world.to_quaternion())
        if frame > 1:
            delta = 2*math.acos(min(1.,abs(axes[-1].dot(axes[-2]))))
            assert delta < math.radians(20), (role,frame,"abrupt grip rotation",delta)
    if frame == 1:
        first = points.copy()
    if frame == 17:
        assert np.max(np.abs(first-points)) < .001
    else:
        bounds.append([] if free_hand else pose_bounds(points, triangles))
(folder/"bounds.json").write_text(json.dumps(bounds), encoding="utf-8")
print("WALK VERIFIED",role, "16 poses and loop", flush=True)

if "--render" in args:
    if "--optix" in args:
        devices = bpy.context.preferences.addons["cycles"].preferences
        devices.compute_device_type = "OPTIX"
        devices.refresh_devices()
        for device in devices.devices:
            device.use = device.type == "OPTIX"
        assert any(device.use for device in devices.devices)
        scene.cycles.device = "GPU"
    scene.render.resolution_x = scene.render.resolution_y = 384
    scene.render.resolution_percentage = 100
    scene.cycles.samples = 8
    scene.render.use_persistent_data = True
    center = Vector((0,0,.76))
    for view,(x,y) in VIEWS.items():
        scene.camera.location = center + Vector((x,y,math.sqrt(2/3))).normalized()*8
        scene.camera.rotation_euler = (center-scene.camera.location).to_track_quat("-Z","Y").to_euler()
        scene.camera.data.ortho_scale = 2.55
        for frame in range(16):
            scene.frame_set(frame+1)
            scene.render.filepath = str(folder/view/f"{frame:02}.png")
            bpy.ops.render.render(write_still=True)
