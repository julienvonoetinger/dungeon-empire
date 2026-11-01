"""Load the immutable equipped Mycean and its corrected three-part grip.

Shared transforms for offline held damage poses. Dedicated background Blender.
"""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT.parent/"v3-locomotion"))
from mesh_checks import geometry,bounds,crossings

SOURCE=OUT.parent/'v2-meshy-inspection/mycean-equipped-review.blend'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('mycean_') and o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
props={'staff':bpy.data.objects['staff_output_unwrapped']}
attachments={name:bpy.data.objects[name] for name in ('staff_output_unwrapped','MyceanGripCorrective','StaffGripContactEnvelope')}
arm.animation_data_clear()
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
APPROVED={p.name:p.matrix_basis.copy() for p in arm.pose.bones}
ARMS={'R':('Bone_025','Bone_024','Bone_023'),'L':('Bone_033','Bone_032','Bone_031')}
LEGS={'R':('Bone_006','Bone_005','Bone_004'),'L':('Bone_015','Bone_014','Bone_013')}
WRISTS={s:arm.matrix_world@arm.pose.bones[names[2]].head for s,names in ARMS.items()}
WRIST_Q={s:(arm.matrix_world@arm.pose.bones[names[2]].matrix).to_quaternion()@R[names[2]].to_quaternion().inverted() for s,names in ARMS.items()}
# The approved palm shares weights with its forearm. Transport that forearm's
# full orientation, including axial roll, rather than rebuilding a minimal aim.
FORE_Q={s:(arm.matrix_world@arm.pose.bones[n[1]].matrix).to_quaternion()@R[n[1]].to_quaternion().inverted() for s,n in ARMS.items()}
FORE_AXIS={s:(WRISTS[s]-arm.matrix_world@arm.pose.bones[n[1]].head).normalized() for s,n in ARMS.items()}
RELATIVE={name:(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world for name,o in attachments.items()}
rest_points=[body.matrix_world@v.co for v in body.data.vertices]
SOLE={s:[i for i,v in enumerate(rest_points) if v.z<.13 and (v.x>0)==(s=='L')] for s in LEGS}
SOLE_Y={s:sum(rest_points[i].y for i in ids)/len(ids) for s,ids in SOLE.items()}
# Only hand geometry has corrective modifiers; un-subdivided sole measurements
# avoid evaluating the dense render mesh during each leg IK iteration.
sole_probe=body.copy();sole_probe.name='MyceanSoleProbe';scene.collection.objects.link(sole_probe)
for modifier in list(sole_probe.modifiers):
    if modifier.type!='ARMATURE':sole_probe.modifiers.remove(modifier)
sole_probe.hide_render=True;sole_probe.hide_set(True)
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


def rot(axis,degrees):return Quaternion(axis,math.radians(degrees))

dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
