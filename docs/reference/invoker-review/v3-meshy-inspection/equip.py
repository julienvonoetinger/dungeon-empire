"""Provisional static staff fitting, original mesh and painting preserved."""
import bpy,math,json,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'combined-source.blend'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=next(o for o in bpy.data.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
staff=bpy.data.objects['Staff'];scene=bpy.context.scene
rest={p.name:arm.matrix_world@p.matrix for p in arm.pose.bones}
def setworld(name,m):
    arm.pose.bones[name].matrix=arm.matrix_world.inverted()@m;bpy.context.view_layer.update()
def orient(name,start,end):
    r=rest[name];direction=r.to_3x3()@Vector((0,1,0))
    q=direction.rotation_difference((end-start).normalized())
    m=q.to_matrix().to_4x4()@r;m.translation=start;setworld(name,m)
upper=arm.pose.bones['Bone_022'];fore=arm.pose.bones['Bone_021']
shoulder=rest['Bone_022'].translation;wrist=Vector((.53,-.18,.81))
length1=upper.length;length2=fore.length
axis=(wrist-shoulder).normalized();distance=(wrist-shoulder).length
a=(length1**2-length2**2+distance**2)/(2*distance)
pole=Vector((1,.5,0));pole=(pole-axis*pole.dot(axis)).normalized()
elbow=shoulder+axis*a+pole*math.sqrt(max(0,length1**2-a*a))
orient('Bone_022',shoulder,elbow);orient('Bone_021',elbow,wrist)
m=Matrix.Rotation(math.radians(-80),4,'X')@rest['Bone_020'];m.translation=wrist
# Match forearm axial roll to the wrist: some palm vertices use forearm weights.
y=(wrist-elbow).normalized();x=m.to_3x3().col[0];x=(x-y*x.dot(y)).normalized();z=x.cross(y).normalized()
fm=Matrix((x,y,z)).transposed().to_4x4();fm.translation=elbow;setworld('Bone_021',fm)
setworld('Bone_020',m)
# Curl the three long fingers around the vertical grip, keeping original weights.
for chain in [(36,35,34,33),(40,39,38,37),(44,43,42,41)]:
    for idx,angle in zip(chain,(20,25,20,5)):
        pb=arm.pose.bones[f'Bone_{idx:03d}'];m=arm.matrix_world@pb.matrix;p=m.translation.copy()
        m=Matrix.Rotation(math.radians(-angle),4,'Z')@m;m.translation=p;setworld(pb.name,m)
staff.scale=(.98,)*3;staff.location=(.435,-.23,.955)
bpy.context.view_layer.update()
# A rigid accessory attached to the wrist; retain the authored global fit.
world=staff.matrix_world.copy();staff.parent=arm;staff.parent_type='BONE';staff.parent_bone='Bone_020';staff.matrix_world=world
bpy.context.view_layer.update()
def vertices(o):
    e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=e.to_mesh();p=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear();return p
points=vertices(body)+vertices(staff)
lo=Vector([min(v[i]for v in points)for i in range(3)]);hi=Vector([max(v[i]for v in points)for i in range(3)])
center=(lo+hi)/2;camera=scene.camera
views=[('equipped-front',(0,-1,.05)),('equipped-iso',(1,-1,math.sqrt(2/3))),('equipped-back',(-1,1,math.sqrt(2/3)))]
extent=0
for _,direction in views:
    rot=(-Vector(direction)).to_track_quat('-Z','Y').to_matrix().transposed()
    extent=max(extent,2*max(abs((rot@(p-center))[i])for p in points for i in (0,1)))
camera.data.ortho_scale=extent*1.15
for name,direction in views:
    camera.location=center+Vector(direction).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
camera.location=Vector((2,-3,1.25));target=Vector((.55,-.3,.88));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=.65
scene.render.filepath=str(OUT/'grip.png');bpy.ops.render.render(write_still=True)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'invoker-equipped.blend'),compress=True)
print('STATIC_FIT_RENDERED')


