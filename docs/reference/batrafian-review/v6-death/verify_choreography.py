"""Independent checks of knee-first forward collapse and final resting body."""
import bpy,sys,json,math
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry
source=Path(sys.argv[sys.argv.index('--')+1])if '--'in sys.argv else OUT/'batrafian-death-poses.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene;a=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('batrafian_')and any(m.type=='ARMATURE'for m in o.modifiers))
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
def head(n):return a.matrix_world@a.pose.bones[n].head
def low(p,names):return min(p[i].z for i,n in enumerate(dominant)if n in names)
results=[];failures=[]
def check(ok,label):
    results.append({'check':label,'passed':bool(ok)})
    if not ok:failures.append(label)
scene.frame_set(1);bpy.context.view_layer.update();standing=head('Bone_000').z
scene.frame_set(5);bpy.context.view_layer.update()
check(head('Bone_000').z<standing-.22,'pelvis lowers before collapse')
check(max(head('Bone_008').z,head('Bone_013').z)<.26,'knees receive weight first')
scene.frame_set(10);bpy.context.view_layer.update();p,_=geometry(body)
axis=head('Bone_017')-head('Bone_000')
check(-axis.y>.32 and -axis.y>abs(axis.x)*3,'torso lies forward, not on its side')
check(low(p,{'Bone_002','Bone_003','Bone_004'})<.13,'chest rests near the floor')
check(low(p,{'Bone_015','Bone_016'})<.13,'turned head rests near the floor')
for side,names in {'R':('Bone_021','Bone_020','Bone_019'),'L':('Bone_025','Bone_024','Bone_023')}.items():
    s,e,w=[head(n)for n in names]
    check(math.degrees((s-e).angle(w-e))>150,side+' elbow extended, not a push-up')
    check(s.y-w.y>.34,side+' hand reaches forward')
    check(abs(w.z)<.18,side+' wrist on floor')
check(min(v.z for v in p)>-.0001,'no body below floor')
result={'source':str(source),'checks':results,'failures':failures}
filename='choreography-red.json'if '--'in sys.argv else 'choreography-validation.json'
(OUT/filename).write_text(json.dumps(result,indent=2)+'\n')
print('BATRAFIAN_DEATH_CHOREOGRAPHY',len(results),'checks',failures)
if failures:raise AssertionError(failures)
