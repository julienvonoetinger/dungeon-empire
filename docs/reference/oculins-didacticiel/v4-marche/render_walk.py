"""Create the equipped Blender walk action and its four registered isometric views.
Run in Blender background with -- <mineur|menuisier|scientifique> [--render].
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

OUT = Path(__file__).resolve().parent
role = sys.argv[sys.argv.index("--") + 1]
# Hip, knee, ankle on positive/negative X. The three Meshy skeletons differ.
RIGS = {
    "mineur": ((14, 13, 12), (9, 8, 7), 25, 21, "Pioche", .154, .085),
    "menuisier": ((6, 5, 4), (11, 10, 9), 22, 26, "Marteau", .145, .080),
    "scientifique": ((9, 8, 7), (14, 13, 12), 20, 24, "Diapason", .138, .078),
}
left, right, carry, free, prop_name, half_step, lift = RIGS[role]
# The longer handles need more room past the hip during the opposite footfall.
carry_adduction = {"mineur": 8., "menuisier": 13., "scientifique": 26.}[role]
VIEWS = {"se": (-1,-1), "sw": (1,-1), "nw": (1,1), "ne": (-1,1)}
folder = OUT / role
folder.mkdir(exist_ok=True)
packed = folder / (role + "-marche.blend")
render = "--render" in sys.argv
source = OUT.parent / ("v3-" + role + "-equipe") / (role + "-equipe.blend")
bpy.ops.wm.open_mainfile(filepath=str(packed if render else source))
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == "ARMATURE")
body = scene.objects[role.capitalize()]
prop = scene.objects[prop_name]
cam = scene.camera
FPS = 20
COUNT = 16

def set_camera(view):
    x, y = VIEWS[view]
    center = Vector((0, 0, .76))
    cam.location = center + Vector((x,y,math.sqrt(2/3))).normalized() * 8
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 2.55

def coordinates(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.data
    coords = np.empty(len(mesh.vertices)*3, dtype=np.float32)
    mesh.vertices.foreach_get("co", coords)
    matrix = np.asarray(evaluated.matrix_world)
    return coords.reshape(-1,3) @ matrix[:3,:3].T + matrix[:3,3]

def surface(obj):
    mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
    mesh.calc_loop_triangles()
    indices = np.empty(len(mesh.loop_triangles)*3, dtype=np.int32)
    mesh.loop_triangles.foreach_get("vertices", indices)
    return BVHTree.FromPolygons(coordinates(obj).tolist(), indices.reshape(-1,3).tolist(), all_triangles=True)

def bone(n):
    return arm.pose.bones[f"Bone_{n:03}"]

def set_world(n, mat):
    # Resolve parent motion from the current pose before assigning the next joint.
    bone(n).matrix = arm.matrix_world.inverted() @ mat
    bpy.context.view_layer.update()

def key(n, frame):
    for channel in ("location","rotation_quaternion","scale"):
        bone(n).keyframe_insert(channel,frame=frame,group=bone(n).name)

def pose_leg(chain, ankle_goal, hip):
    thigh, shin, foot = chain
    a, b = (head[shin]-head[thigh]).length, (head[foot]-head[shin]).length
    axis = (ankle_goal-hip).normalized()
    d = min((ankle_goal-hip).length,a+b-.0001)
    proj = (a*a-b*b+d*d)/(2*d)
    pole = Vector((.44 if hip.x>0 else -.44,-1,0))
    knee = hip + axis*proj + (pole-axis*axis.dot(pole)).normalized()*math.sqrt(max(0,a*a-proj*proj))
    end = hip + axis*d
    for n,child,start,stop in ((thigh,shin,hip,knee),(shin,foot,knee,end)):
        turn = (head[child]-head[n]).rotation_difference(stop-start)
        mat = turn.to_matrix().to_4x4() @ neutral[n]
        mat.translation = start
        set_world(n,mat)
    mat = neutral[foot].copy()
    mat.translation = end
    set_world(foot,mat)

if not render:
    forearm = carry - 1
    assert bone(forearm).parent == bone(carry)
    moving = (0,*left,*right,carry,forearm,free)
    neutral = {n:arm.matrix_world @ bone(n).matrix.copy() for n in moving}
    head = {n:mat.translation.copy() for n,mat in neutral.items()}
    probe = body.copy()
    scene.collection.objects.link(probe)
    for mod in list(probe.modifiers):
        if mod.type != "ARMATURE":
            probe.modifiers.remove(mod)
    probe.hide_render = True
    probe.hide_set(True)
    original = coordinates(probe)
    soles = [(original[:,2]<.055)&(original[:,0]*sign>0) for sign in (1,-1)]
    records = []
    for i in range(COUNT+1):
        scene.frame_set(i+1)
        phase = i*math.tau/COUNT
        shift = Vector((.026*math.sin(phase),0,-.060+.012*math.cos(phase*2)))
        mat = neutral[0].copy()
        mat.translation += shift
        set_world(0,mat)
        for n,swing,adduction in ((carry,6.0,carry_adduction),(free,-10.0,9.)):
            # Draw the upper arm toward the flank, then swing about the shoulder.
            side = 1 if head[n].x > 0 else -1
            lower = Matrix.Rotation(math.radians(side*adduction),4,"Y")
            swing_rotation = Matrix.Rotation(math.radians(swing*math.cos(phase)),4,"X")
            mat = swing_rotation @ lower @ neutral[n]
            mat.translation = head[n]+shift
            set_world(n,mat)
            if n == carry:
                # Pivot at the moving elbow. The hand and fitted tool follow together.
                elbow = mat @ neutral[n].inverted() @ neutral[forearm]
                relax = Matrix.Rotation(math.radians(side*20.),4,"Y")
                relaxed = relax @ elbow
                relaxed.translation = elbow.translation
                set_world(forearm,relaxed)
        contacts = []
        for j,chain in enumerate((left,right)):
            t = ((i/COUNT)+j*.5)%1
            if t <= .5:
                dy, dz = half_step*(4*t-1), 0
            else:
                u = 2*t-1
                dy = half_step*math.cos(math.pi*u)
                dz = lift*math.sin(math.pi*u)**1.6
            ankle = head[chain[2]]+Vector((0,dy,dz))
            hip = head[chain[0]]+shift
            target_y = original[soles[j],1].mean()+dy
            for _ in range(7):
                pose_leg(chain,ankle,hip)
                points = coordinates(probe)[soles[j]]
                ez, ey = dz-points[:,2].min(), target_y-points[:,1].mean()
                if max(abs(ez),abs(ey)) < .0005:
                    break
                ankle += Vector((0,ey,ez))
            contacts.append([round(float(ez),5),round(float(ey),5)])
        for n in moving:
            key(n,i+1)
        hits = len(surface(body).overlap(surface(prop)))
        print("WALK",role,i,contacts,hits,flush=True)
        records.append(dict(pose=i,sole_errors=contacts,crossings=hits))
    bpy.data.objects.remove(probe,do_unlink=True)
    action = arm.animation_data.action
    action.name = "Marche_" + role
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for k in curve.keyframe_points:
                        k.interpolation = "LINEAR"
                    curve.modifiers.new("CYCLES")
    scene.frame_start,scene.frame_end = 1,COUNT
    scene.render.fps = FPS
    scene.frame_set(1)
    set_camera("se")
    (folder/"controle.json").write_text(json.dumps(records,indent=2))
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(packed),compress=True)
else:
    scene.render.resolution_x = scene.render.resolution_y = 384
    scene.render.resolution_percentage = 100
    scene.cycles.samples = 8
    for view in VIEWS:
        set_camera(view)
        target = folder/"masters"/view
        target.mkdir(parents=True,exist_ok=True)
        for i in range(COUNT):
            scene.frame_set(i+1)
            scene.render.filepath = str(target/f"{i:02}.png")
            bpy.ops.render.render(write_still=True)


