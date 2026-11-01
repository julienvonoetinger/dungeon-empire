"""Load the approved equipped model and the established fixed-length pose helpers.

Dedicated background Blender only; importing this module opens the v3 source.
The v4 locomotion script and its generated assets remain untouched.
"""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT.parent / "v4-locomotion"))
from mesh_checks import geometry,bounds,crossings

SOURCE=OUT.parent/'v3-equipment-grips/paladin-equipped-review.blend'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
props={name:next(o for o in scene.objects if o.name.startswith(name+'_') and o.type=='MESH') for name in ('hammer','shield')}
arm.animation_data_clear()
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
APPROVED={p.name:p.matrix_basis.copy() for p in arm.pose.bones}
ARMS={'R':('Bone_025','Bone_024','Bone_023'),'L':('Bone_021','Bone_020','Bone_019')}
LEGS={'R':('Bone_009','Bone_008','Bone_007'),'L':('Bone_014','Bone_013','Bone_012')}
WRISTS={s:arm.matrix_world@arm.pose.bones[names[2]].head for s,names in ARMS.items()}
WRIST_Q={s:(arm.matrix_world@arm.pose.bones[names[2]].matrix).to_quaternion()@R[names[2]].to_quaternion().inverted() for s,names in ARMS.items()}
RELATIVE={name:(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world for name,o in props.items()}
rest_points=[body.matrix_world@v.co for v in body.data.vertices]
SOLE={s:[i for i,v in enumerate(rest_points) if v.z<.13 and (v.x>0)==(s=='L')] for s in LEGS}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,body_tri=geometry(body)
NONHAND={}
for name,ids in [('hammer',[22,23,*range(38,50)]),('shield',[18,19,*range(26,38)])]:
    allowed={f'Bone_{i:03}' for i in ids}
    NONHAND[name]=[t for t in body_tri if not any(dominant[i] in allowed for i in t)]
def set_world(name,head,q=None):
    m=R[name].copy()
    if q is not None:m=q.to_matrix().to_4x4()@m
    m.translation=head;arm.pose.bones[name].matrix=AI@m;bpy.context.view_layer.update()
def aim(name,head,end,rest_end):
    q=(rest_end-H[name]).normalized().rotation_difference((end-head).normalized());set_world(name,head,q)
def solve(root,end,l1,l2,pole):
    delta=end-root;distance=delta.length
    if distance>=l1+l2-.001:end=root+delta.normalized()*(l1+l2-.001);delta=end-root;distance=delta.length
    direction=delta.normalized();a=(l1*l1-l2*l2+distance*distance)/(2*distance)
    height=math.sqrt(max(0,l1*l1-a*a));p=pole-direction*direction.dot(pole)
    return root+direction*a+p.normalized()*height,end
