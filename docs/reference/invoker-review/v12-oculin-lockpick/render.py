"""Render the volunteer working a single lock from the four corridor directions."""
import math
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Quaternion, Vector

here = Path(__file__).resolve().parent
output = here.parents[3] / "artifacts/oculin-door-lockpick/frames"
bpy.ops.wm.open_mainfile(filepath=str(here.parent / "v5-procession/oculin-poses.blend"))
scene = bpy.context.scene
scene.frame_set(0)
rig = next(obj for obj in scene.objects if obj.type == "ARMATURE")
rig.animation_data_clear()
camera = scene.camera
camera.animation_data_clear()
rest = {b.name: b.matrix_basis.copy() for b in rig.pose.bones}
scene.render.resolution_x = scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.cycles.samples = 8
update = bpy.context.view_layer.update


def joint(index):
    return rig.pose.bones[f"Bone_{index:03}"]


def point(index):
    return rig.matrix_world @ joint(index).head


def rotate(index, rotation):
    bone = joint(index)
    world = rig.matrix_world @ bone.matrix
    world = rotation.to_matrix().to_4x4() @ world
    world.translation = point(index)
    bone.matrix = rig.matrix_world.inverted() @ world
    update()


def aim(index, source_vector, target_vector):
    rotate(index, source_vector.normalized().rotation_difference(target_vector.normalized()))


def arm(shoulder, palm, aim_hand, side):
    elbow, wrist = shoulder-1, shoulder-2
    # The rig's finger roots branch out of the primary hand chains.
    finger = 57 if side > 0 else 45
    palm_offset = point(finger)-point(wrist)
    target = palm-aim_hand.normalized()*palm_offset.length
    upper = (point(elbow)-point(shoulder)).length
    lower = (point(wrist)-point(elbow)).length
    reach = target-point(shoulder)
    axis = reach.normalized()
    length = min(reach.length, upper+lower-.001)
    along = (length*length + upper*upper - lower*lower)/(2*length)
    pole = Vector((side,.1,-.5))
    outward = (pole-axis*axis.dot(pole)).normalized()
    elbow_offset = axis*along + outward*math.sqrt(max(0,upper*upper-along*along))
    aim(shoulder, point(elbow)-point(shoulder), elbow_offset)
    aim(elbow, point(wrist)-point(elbow), target-point(elbow))
    aim(wrist, point(finger)-point(wrist), aim_hand)
    return point(finger)


def rod(name, radius, color):
    data = bpy.data.curves.new(name,"CURVE")
    data.dimensions = "3D"
    data.bevel_depth = radius
    data.bevel_resolution = 3
    data.use_fill_caps = True
    obj = bpy.data.objects.new(name,data)
    scene.collection.objects.link(obj)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color,1)
    data.materials.append(mat)
    return obj


def line(obj, points):
    obj.data.splines.clear()
    spline = obj.data.splines.new("POLY")
    spline.points.add(len(points)-1)
    for vertex, pos in zip(spline.points, points):
        vertex.co = (*pos,1)


shaft = rod("Bent steel pick",.020,(.72,.84,.94))
handle = rod("Brass pick handle",.033,(.82,.47,.14))
lock = Vector((.06,-1.14,.83))
angles = {"ne":-45,"se":-135,"sw":135,"nw":45}
# Reach, settle, work the pick through alternating wrist turns, draw back.
# Frames 3 to 7 hold the steel tip at the same point in all four renders.
poses = [(0,0,0),(9,.42,-.18),(18,.82,-.12),(24,1,0),
         (27,1,.65),(20,1,-.60),(25,1,.30),(23,1,-.22),
         (15,.74,.12),(7,.35,-.10),(0,0,0)]
for frame,(lean,reach,turn) in enumerate(poses):
    for bone in rig.pose.bones:
        bone.matrix_basis = rest[bone.name]
    update()
    rotate(8,Quaternion((1,0,0),math.radians(lean)))
    rotate(22,Quaternion((1,0,0),math.radians(lean*.23)))
    working = Vector((.15+turn*.14,-.70,.77+turn*.13))
    grip = point(57) if reach == 0 else arm(33,point(57).lerp(working,reach),
                                          Vector((-.26,-.9,-.22)),1)
    if reach > 0:
        arm(28,point(45).lerp(Vector((-.17,-.72,.87-turn*.055)),reach),
            Vector((.26,-.82,-.2)),-1)
    direction = (lock-grip).normalized()
    tip = lock if reach == 1 else grip + direction*.45
    line(handle,[grip-direction*.09,grip+direction*.08])
    line(shaft,[grip+direction*.055,tip-direction*.045-Vector((0,0,.035)),tip])
    for obj in (handle,shaft):
        obj.hide_render = reach == 0
    focus = Vector((0,0,.8))
    for name,deg in angles.items():
        a = math.radians(deg)
        camera.location = focus+Vector((math.sin(a)*math.sqrt(3),math.cos(a)*math.sqrt(3),1)).normalized()*7
        camera.rotation_euler = (focus-camera.location).to_track_quat("-Z","Y").to_euler()
        folder = output/name
        folder.mkdir(parents=True,exist_ok=True)
        update()
        if frame == 3:
            uv = world_to_camera_view(scene,camera,lock)
            print("CONTACT", name,round(uv.x*256-128,3),round((1-uv.y)*256-187.1207,3),flush=True)
        scene.render.filepath = str(folder/f"{frame:02}.png")
        bpy.ops.render.render(write_still=True)
