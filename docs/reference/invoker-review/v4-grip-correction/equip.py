"""Fit a real palm-and-finger grasp from the supplied Meshy rig."""
import bpy,math,json,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'v3-meshy-inspection/combined-source.blend'))
scene=bpy.context.scene
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=next(o for o in bpy.data.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
staff=bpy.data.objects['Staff']
R={b.name:(arm.matrix_world@b.matrix_local).copy()for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
def name(i):return f'Bone_{i:03d}'
def setworld(n,m):
    arm.pose.bones[n].matrix=arm.matrix_world.inverted()@m;bpy.context.view_layer.update()
def orient(n,start,end):
    q=(R[n].to_3x3()@Vector((0,1,0))).rotation_difference((end-start).normalized())
    m=q.to_matrix().to_4x4()@R[n];m.translation=start;setworld(n,m)
def points(o):
    ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();p=[ev.matrix_world@v.co for v in me.vertices];ev.to_mesh_clear();return p
for mod in body.modifiers:
    if mod.type=='ARMATURE':mod.use_deform_preserve_volume=True
wrist=Vector((.55,-.18,.85));shoulder=H[name(22)]
axis=(wrist-shoulder).normalized();d=(wrist-shoulder).length
l1=(H[name(21)]-shoulder).length;l2=(H[name(20)]-H[name(21)]).length
assert abs(l1-l2)<d<l1+l2
a=(l1*l1-l2*l2+d*d)/(2*d);pole=Vector((1,.5,0));pole=(pole-axis*pole.dot(axis)).normalized()
elbow=shoulder+axis*a+pole*math.sqrt(l1*l1-a*a)
orient(name(22),shoulder,elbow);orient(name(21),elbow,wrist)
f=(H[name(44)]-H[name(20)]).normalized()
u=H[name(32)]-H[name(44)];u=(u-f*u.dot(f)).normalized();normal=f.cross(u).normalized()
forward=Vector((0,-1,0));up=Vector((0,0,1));inward=forward.cross(up)
source_basis=Matrix((f,u,normal)).transposed();target_basis=Matrix((forward,up,inward)).transposed()
q=(target_basis@source_basis.transposed()).to_quaternion()
# Forearm axial roll follows the actual palm plane, not a bone-local guessed axis.
m=arm.matrix_world@arm.pose.bones[name(21)].matrix;axis=(wrist-elbow).normalized()
cur=(m@R[name(21)].inverted()).to_3x3()@normal;cur=(cur-axis*cur.dot(axis)).normalized()
want=(inward-axis*inward.dot(axis)).normalized();roll=math.atan2(axis.dot(cur.cross(want)),cur.dot(want))
fm=Quaternion(axis,roll).to_matrix().to_4x4()@m;fm.translation=elbow;setworld(name(21),fm)
m=q.to_matrix().to_4x4()@R[name(20)];m.translation=wrist;setworld(name(20),m)
grip_axis=Vector((.462,-.35,0))
# Articulate each digit around the handle's cross-section, thumb opposed.
for chain,radius,sign in [((36,35,34,33),.071,-1),((40,39,38,37),.071,-1),((44,43,42,41),.071,-1),((32,31,30,29),.078,1)]:
    first=arm.matrix_world@arm.pose.bones[name(chain[0])].head
    if chain[0]==36:
        radial=Vector((first.x-grip_axis.x,first.y-grip_axis.y,0))
        first+=radial.normalized()*max(0,.081-radial.length)
    start=first.copy();rel=start-grip_axis;distance=math.hypot(rel.x,rel.y)
    theta=math.atan2(rel.y,rel.x)
    for k,idx in enumerate(chain):
        pb=arm.pose.bones[name(idx)];length=pb.length
        if k==0:
            cosine=(distance*distance+radius*radius-length*length)/(2*distance*radius)
            assert -1.001<=cosine<=1.001,(idx,cosine)
            theta+=sign*math.acos(max(-1,min(1,cosine)))
        else:theta+=sign*2*math.asin(min(1,length/(2*radius)))
        end=Vector((grip_axis.x+radius*math.cos(theta),grip_axis.y+radius*math.sin(theta),first.z))
        current=arm.matrix_world@pb.matrix;old_direction=current.to_3x3()@Vector((0,1,0))
        rotation=old_direction.rotation_difference((end-start).normalized())
        posed=rotation.to_matrix().to_4x4()@current;posed.translation=start;setworld(name(idx),posed)
        start=end
staff.scale=(.98,)*3;staff.location=(.462,-.358,.955)
bpy.context.view_layer.update()
world=staff.matrix_world.copy();staff.parent=arm;staff.parent_type='BONE';staff.parent_bone=name(20);staff.matrix_world=world;bpy.context.view_layer.update()
grip_points=[p for p in points(staff) if .72<p.z<1.0]
cx=(min(p.x for p in grip_points)+max(p.x for p in grip_points))*.5
cy=(min(p.y for p in grip_points)+max(p.y for p in grip_points))*.5
radius=max(math.hypot(p.x-cx,p.y-cy)for p in grip_points)+.002
group=body.vertex_groups.new(name='GripContact')
selected=[i for i,p in enumerate(points(body)) if p.x>.32 and p.y<-.21 and .66<p.z<1.1]
group.add(selected,1,'REPLACE')
bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=radius,depth=.5,location=(cx,cy,.85))
envelope=bpy.context.object;envelope.name='GripContactEnvelope';envelope.hide_render=True;envelope.hide_set(True)
bpy.context.view_layer.update();matrix=envelope.matrix_world.copy();envelope.parent=arm;envelope.parent_type='BONE';envelope.parent_bone=name(20);envelope.matrix_world=matrix
sub=body.modifiers.new('GripSampling','SUBSURF');sub.subdivision_type='SIMPLE';sub.levels=2;sub.render_levels=2
contact=body.modifiers.new('HandContact','SHRINKWRAP');contact.target=envelope;contact.vertex_group=group.name;contact.wrap_method='NEAREST_SURFACEPOINT';contact.wrap_mode='OUTSIDE';contact.offset=.001
bpy.context.view_layer.update()
hand={name(i):{'head':list(arm.matrix_world@arm.pose.bones[name(i)].head),'tail':list(arm.matrix_world@arm.pose.bones[name(i)].tail)}for i in [20,19,32,31,30,29,36,35,34,33,40,39,38,37,44,43,42,41]}
(OUT/'hand-joints.json').write_text(json.dumps(hand,indent=2))
allp=points(body)+points(staff);lo=Vector([min(v[i]for v in allp)for i in range(3)]);hi=Vector([max(v[i]for v in allp)for i in range(3)]);center=(lo+hi)*.5
camera=scene.camera;camera.data.ortho_scale=max(hi-lo)*1.22
for label,direction in [('front',(0,-1,.03)),('iso',(1,-1,.816)),('back',(-1,1,.816))]:
    camera.location=center+Vector(direction).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/(label+'.png'));bpy.ops.render.render(write_still=True)
target=Vector((.5,-.28,.85));camera.data.ortho_scale=.65
for label,direction in [('grip-front',(0,-1,0)),('grip-outer',(1,-1,.5)),('grip-inner',(-1,-1,.5)),('grip-top',(0,0,1))]:
    camera.data.clip_start=2.75 if label=='grip-top' else .1
    camera.location=target+Vector(direction)*3;camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/(label+'.png'));bpy.ops.render.render(write_still=True)
camera.data.clip_start=.1
bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'invoker-equipped.blend'),compress=True)
print('GRIP_RENDERED')
