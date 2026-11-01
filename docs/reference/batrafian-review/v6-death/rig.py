"""Load immutable equipped Batrafian. Dedicated background Blender only."""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,bounds,crossings
SOURCE=OUT.parent/'v3-equipment-orientation/batrafian-equipped-review.blend'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('batrafian_')and any(m.type=='ARMATURE'for m in o.modifiers))
props={n:next(o for o in scene.objects if o.type=='MESH'and o.name.startswith(n+'_'))for n in ('bow','quiver')}
arm.animation_data_clear()
R={b.name:(arm.matrix_world@b.matrix_local).copy()for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
APPROVED={p.name:p.matrix_basis.copy()for p in arm.pose.bones}
ARMS={'R':('Bone_021','Bone_020','Bone_019'),'L':('Bone_025','Bone_024','Bone_023')}
LEGS={'R':('Bone_009','Bone_008','Bone_007'),'L':('Bone_014','Bone_013','Bone_012')}
WRISTS={s:arm.matrix_world@arm.pose.bones[n[2]].head for s,n in ARMS.items()}
WRIST_Q={s:(arm.matrix_world@arm.pose.bones[n[2]].matrix).to_quaternion()@R[n[2]].to_quaternion().inverted()for s,n in ARMS.items()}
FORE_Q={s:(arm.matrix_world@arm.pose.bones[n[1]].matrix).to_quaternion()@R[n[1]].to_quaternion().inverted()for s,n in ARMS.items()}
FORE_AXIS={s:(WRISTS[s]-arm.matrix_world@arm.pose.bones[n[1]].head).normalized()for s,n in ARMS.items()}
RELATIVE={n:(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world for n,o in props.items()}
SOLE={s:[v.index for v in body.data.vertices if (p:=body.matrix_world@v.co).z<.13 and(p.x>0)==(s=='L')]for s in LEGS}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,TRI=geometry(body)
NONHAND={'bow':[t for t in TRI if not any(dominant[i]in ('Bone_023','Bone_022')for i in t)],'quiver':TRI}
def rot(axis,degrees):return Quaternion(axis,math.radians(degrees))
def set_world(name,head,q):
    m=q.to_matrix().to_4x4()@R[name];m.translation=head
    arm.pose.bones[name].matrix=AI@m;bpy.context.view_layer.update()
def aim(name,head,end,rest_end):
    set_world(name,head,(rest_end-H[name]).normalized().rotation_difference((end-head).normalized()))
def solve(root,target,l1,l2,pole):
    delta=target-root
    distance=min(max(delta.length,abs(l1-l2)+.001),l1+l2-.001)
    direction=delta.normalized();end=root+direction*distance
    a=(l1*l1-l2*l2+distance*distance)/(2*distance)
    p=pole-direction*direction.dot(pole)
    return root+direction*a+p.normalized()*math.sqrt(max(0,l1*l1-a*a)),end
