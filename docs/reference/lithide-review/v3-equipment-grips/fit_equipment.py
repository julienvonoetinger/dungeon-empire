"""Correct the equipped static pose with real hand grips, from immutable GLBs.

Run only in a dedicated background Blender process. No source mesh repainting.
"""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from bpy_extras.object_utils import world_to_camera_view

OUT=Path(__file__).parent
PRIOR=OUT.parent/'v2-meshy-inspection'
bpy.ops.wm.open_mainfile(filepath=str(PRIOR/'inspection.blend'))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
hammer=next(o for o in scene.objects if o.name.startswith('hammer_') and o.type=='MESH')
shield=next(o for o in scene.objects if o.name.startswith('shield_') and o.type=='MESH')
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
for b in arm.pose.bones:b.rotation_mode='QUATERNION';b.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()

def xyz(v):return [round(float(x),6) for x in v]
def points(o):
    e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=e.to_mesh()
    p=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear();return p
def set_world(name,head,q):
    m=q.to_matrix().to_4x4()@R[name];m.translation=head
    arm.pose.bones[name].matrix=AI@m;bpy.context.view_layer.update()
def aim(name,head,end,rest_end):
    q=(rest_end-H[name]).normalized().rotation_difference((end-head).normalized())
    set_world(name,head,q)
def joint(root,end,l1,l2,pole):
    delta=end-root;dist=delta.length
    assert abs(l1-l2)+.001<dist<l1+l2-.001,'Unreachable wrist'
    d=delta/dist;a=(l1*l1-l2*l2+dist*dist)/(2*dist)
    h=math.sqrt(max(0,l1*l1-a*a));p=pole-d*d.dot(pole)
    return root+d*a+p.normalized()*h

hands={}
for side,chain,target,pole in [
    ('R',('Bone_025','Bone_024','Bone_023'),(-.59,-.25,.87),(-1,.1,-.1)),
    ('L',('Bone_021','Bone_020','Bone_019'),(.55,-.25,.90),(1,.1,-.1))]:
    upper,fore,wrist=chain;w=Vector(target)
    elbow=joint(H[upper],w,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector(pole))
    aim(upper,H[upper],elbow,H[fore]);aim(fore,elbow,w,H[wrist])
    # Original finger spread follows Y. Rotate it to Z so a vertical handle
    # passes through the fist, rather than lengthwise along the forearm.
    q=Quaternion((1,0,0),math.radians(-90))
    set_world(wrist,w,q)
    hands[side]={'wrist':wrist,'head':w,'q':q,'elbow':elbow}

# Curl the existing weighted fingers, never deform source vertices by hand.
# Right thumb is049; left thumb031 (different order from the other hand).
fingers={
 'R':[(('Bone_040','Bone_039','Bone_038'),(-22,-30,-15)),(('Bone_043','Bone_042','Bone_041'),(-22,-30,-15)),(('Bone_046','Bone_045','Bone_044'),(-22,-30,-15)),(('Bone_049','Bone_048','Bone_047'),(15,20,20))],
 'L':[(('Bone_028','Bone_027','Bone_026'),(12,20,10)),(('Bone_034','Bone_033','Bone_032'),(12,20,10)),(('Bone_037','Bone_036','Bone_035'),(12,20,10)),(('Bone_031','Bone_030','Bone_029'),(-35,-15,-10))]}
for side,chains in fingers.items():
    hand=hands[side]
    for names,angles in chains:
        q=hand['q'].copy()
        head=hand['head']+q@(H[names[0]]-H[hand['wrist']])
        for index,(name,angle) in enumerate(zip(names,angles)):
            q=q@Quaternion((0,1,0),math.radians(angle));set_world(name,head,q)
            if index<2:head=head+q@(H[names[index+1]]-H[name])

def hand_point(side,p):
    hand=hands[side];return hand['head']+hand['q']@(Vector(p)-H[hand['wrist']])
grips={'R':hand_point('R',(-.724,.07,.413)),'L':hand_point('L',(.731,.065,.413))}
def attach(obj,world,bone):
    obj.parent=arm;obj.parent_type='BONE';obj.parent_bone=bone;obj.matrix_world=world;obj.hide_render=False;bpy.context.view_layer.update()
    return world.copy()
hp=points(hammer);hammer_scale=1.04/(max(v.z for v in hp)-min(v.z for v in hp))
hammer_source=Vector((0,0,-.46))
# Character forward is -Y. The source hammer head spans X; turn it around
# its vertical handle so the striking faces follow forward/back, not left/right.
# -90 also puts the decorative side toward the outside of the right hand.
hammer_yaw_degrees=-90
hammer_yaw=Matrix.Rotation(math.radians(hammer_yaw_degrees),4,'Z')
hammer_world=Matrix.Translation(grips['R'])@hammer_yaw@Matrix.Scale(hammer_scale,4)@Matrix.Translation(-hammer_source)@hammer.matrix_world
attach(hammer,hammer_world,hands['R']['wrist'])

sp=points(shield);shield_scale=1.16/(max(v.z for v in sp)-min(v.z for v in sp))
# Rear close-up reveals the original gold vertical grip. Use it directly.
# Both anchors are in the imported object's world axes before fitting.
shield_source=Vector((0,.205,.055))
shield_world=Matrix.Translation(grips['L'])@Matrix.Scale(shield_scale,4)@Matrix.Translation(-shield_source)@shield.matrix_world
attach(shield,shield_world,hands['L']['wrist'])
body.hide_render=False

scene.render.resolution_x=960;scene.render.resolution_y=960;scene.cycles.samples=24
camera=scene.camera
for name,pos,power,size in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
    light=bpy.data.objects[name];light.location=Vector((0,0,.85))+Vector(pos)*1.7;light.rotation_euler=(Vector((0,0,.85))-light.location).to_track_quat('-Z','Y').to_euler();light.data.energy=power*1.7**2;light.data.size=size*1.7
all_points=[v for obj in (body,hammer,shield) for v in points(obj)]
lo=Vector([min(v[i] for v in all_points) for i in range(3)]);hi=Vector([max(v[i] for v in all_points) for i in range(3)]);center=(lo+hi)*.5
views={'front':(0,-1,0),'sw':(1,-1,math.sqrt(2/3)),'se':(-1,-1,math.sqrt(2/3)),'back':(0,1,0),'ne':(-1,1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3))}
extents=[]
for d in views.values():
    camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();inv=camera.rotation_euler.to_matrix().transposed()
    projected=[inv@(v-center) for v in all_points];extents.append(max(max(v[i] for v in projected)-min(v[i] for v in projected) for i in (0,1)))
camera.data.ortho_scale=max(extents)*1.18
checks=[]
for name,d in views.items():
    camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
    assert all(.02<(uv:=world_to_camera_view(scene,camera,v)).x<.98 and .02<uv.y<.98 for v in all_points)
    scene.render.filepath=str(OUT/('equipped-'+name+'.png'));bpy.ops.render.render(write_still=True);checks.append(name)
camera.location=center+Vector(views['sw']).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'paladin-equipped-review.blend'),compress=True)
report={'grips':{k:xyz(v) for k,v in grips.items()},'source_grips':{'hammer':xyz(hammer_source),'shield':xyz(shield_source)},'hammer_yaw_degrees':hammer_yaw_degrees,'hammer_strike_axis':xyz(hammer_yaw.to_3x3()@Vector((1,0,0))),'hands':{k:{'wrist':v['wrist'],'head':xyz(v['head']),'elbow':xyz(v['elbow'])} for k,v in hands.items()},'views':checks,'limits':'Static corrective pose; not an animation-range validation. Both original handles used; original GLBs unchanged.'}
(OUT/'equipment-fit.json').write_text(json.dumps(report,indent=2)+'\n')
print('GRIP_FIT_OK',json.dumps(report))
