"""Render the four messengers' shared turn and run using the equipped procession Oculin."""
from pathlib import Path
import math
import bpy
from mathutils import Vector, Quaternion

OUT = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'v5-procession/oculin-poses.blend'))
s = bpy.context.scene
s.frame_set(0)
arm = next(o for o in s.objects if o.type=='ARMATURE')
body = next(o for o in s.objects if o.type=='MESH' and o.find_armature())
cam = s.camera
cam.animation_data_clear()
arm.animation_data_clear()
rest = {b.name:b.matrix_basis.copy() for b in arm.pose.bones}
s.render.resolution_x=s.render.resolution_y=256
s.render.resolution_percentage=100
s.cycles.samples=8
directions = {'n':0,'ne':-45,'e':-90,'se':-135,'s':180,'sw':135,'w':90,'nw':45}

def bend(index, degrees):
    bone = arm.pose.bones[f'Bone_{index:03}']
    axis = (arm.matrix_world@bone.bone.matrix_local).to_quaternion().inverted()@Vector((1,0,0))
    bone.matrix_basis = rest[bone.name]@Quaternion(axis,math.radians(degrees)).to_matrix().to_4x4()

def pose(phase, turn=False):
    for bone in arm.pose.bones:
        bone.matrix_basis=rest[bone.name].copy()
    amp=.20 if turn else 1.
    for thigh,shin,foot,sign in [(13,12,11,1),(18,17,16,-1)]:
        swing=math.sin(phase)*sign
        lift=max(0,math.cos(phase)*sign)
        bend(thigh,amp*(31*swing+14*lift))
        bend(shin,amp*(-46*lift-7))
        bend(foot,amp*(10*lift-8*swing))
    for shoulder,elbow,sign in [(33,32,-1),(28,27,1)]:
        bend(shoulder,amp*sign*24*math.sin(phase))
        bend(elbow,amp*(-29+6*sign*math.cos(phase)))
    bend(8,amp*11)
    bpy.context.view_layer.update()
    mesh=body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    floor=min((mesh.matrix_world@v.co).z for v in mesh.data.vertices)
    return floor - (0 if turn else .075*max(0,math.cos(2*phase)))

def render(name, frame, angle, ground):
    focus=Vector((0,0,.8+ground))
    a=math.radians(angle)
    cam.location=focus+Vector((math.sin(a)*math.sqrt(3),math.cos(a)*math.sqrt(3),1)).normalized()*7
    cam.rotation_euler=(focus-cam.location).to_track_quat('-Z','Y').to_euler()
    folder=OUT/'frames'/name
    folder.mkdir(parents=True,exist_ok=True)
    s.render.filepath=str(folder/f'{frame:02}.png')
    bpy.ops.render.render(write_still=True)

for i in range(12):
    floor=pose(math.tau*i/12)
    for direction,angle in directions.items():
        render('run-'+direction,i,angle,floor)
for i in range(9):
    t=i/8
    render('turn',i,180*t*t*(3-2*t),pose(t*math.tau,True))
