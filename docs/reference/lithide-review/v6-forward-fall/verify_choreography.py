"""Check the requested forward, articulated fall independently of its renderer."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent
source=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else OUT/'paladin-action-poses.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
a=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
body=next(o for o in bpy.context.scene.objects if o.type=='MESH'and any(m.type=='ARMATURE'for m in o.modifiers))
sys.path.insert(0,str(OUT.parent/'v4-locomotion'));from mesh_checks import geometry
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
def head(n):return a.matrix_world@a.pose.bones[n].head
def low(points,names):return min(points[i].z for i,n in enumerate(dominant)if n in names)
failures=[];results=[]
def check(ok,label):
    results.append({'check':label,'passed':bool(ok)})
    if not ok:failures.append(label)
# Existing pose indices: hurt1–8, death9–18.
bpy.context.scene.frame_set(13);bpy.context.view_layer.update();p,_=geometry(body)
check(max(head('Bone_008').z,head('Bone_013').z)<.25,'knees receive the body before the forward fall')
bpy.context.scene.frame_set(18);bpy.context.view_layer.update();p,_=geometry(body)
pelvis=head('Bone_000');neck=head('Bone_016');forward=neck-pelvis
check(-forward.y>abs(forward.x)*3 and -forward.y>.65,'final torso falls forward, not sideways')
check(low(p,{'Bone_002','Bone_003','Bone_004'})<.12,'chest actually rests near the floor')
check(low(p,{'Bone_015','Bone_016'})<.12,'turned helmet rests near the floor')
for side,names in {'R':('Bone_025','Bone_024','Bone_023'),'L':('Bone_021','Bone_020','Bone_019')}.items():
    s,e,w=[head(n)for n in names]
    angle=math.degrees((s-e).angle(w-e))
    check(angle>150,f'{side} elbow extends instead of a push-up support')
    check(s.y-w.y>.35,f'{side} hand reaches forward beyond shoulder')
    check(abs(w.z)<.18,f'{side} hand reaches floor')
summary={'source':str(source),'checks':results,'failures':failures}
(OUT/'choreography-validation.json').write_text(json.dumps(summary,indent=2)+'\n')
print('FORWARD_FALL',len(results),'checks',failures)
if failures:raise AssertionError(failures)
