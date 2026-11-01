"""Independent knee-first collapse checks; generator is never imported."""
import bpy,sys,json,math
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v3-locomotion'))
from mesh_checks import geometry
source=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else OUT/'mycean-death-poses.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene;a=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['mycean_output_unwrapped']
def head(n):return a.matrix_world@a.pose.bones[n].head
def low(names):
    ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
    result=min((ev.matrix_world@v.co).z for v in mesh.vertices if any(body.vertex_groups[g.group].name in names and g.weight>.25 for g in v.groups))
    ev.to_mesh_clear();return result
results=[];failures=[]
def check(ok,label):
    results.append({'check':label,'passed':bool(ok)})
    if not ok:failures.append(label)
scene.frame_set(1);bpy.context.view_layer.update();standing=head('Bone_000').z
heights=[]
for i in range(10):
    scene.frame_set(i+1);bpy.context.view_layer.update();heights.append(head('Bone_000').z)
check(all(b-a<.02 for a,b in zip(heights,heights[1:])), 'pelvis does not jump back up during fall')
scene.frame_set(5);bpy.context.view_layer.update()
check(head('Bone_000').z<standing-.11,'short-legged pelvis lowers before torso lands')
check(max(head('Bone_005').z,head('Bone_014').z)<.12,'knees receive weight first')
scene.frame_set(10);bpy.context.view_layer.update();p,_=geometry(body)
axis=head('Bone_017')-head('Bone_000')
check(-axis.y>.36 and -axis.y>abs(axis.x)*3,'torso lies forward, not on its side')
check(low({'Bone_010','Bone_009','Bone_008'})<.13,'chest rests near floor')
for side,ns in {'R':['Bone_025','Bone_024','Bone_023'],'L':['Bone_033','Bone_032','Bone_031']}.items():
    s,e,w=[head(n) for n in ns]
    check(math.degrees((s-e).angle(w-e))>150,side+' elbow extends, not a push-up')
    check(s.y-w.y>.24,side+' hand reaches forward')
    check(abs(w.z)<.18,side+' wrist rests near floor')
check(min(v.z for v in p)>-.0001,'body stays above floor')
result={'source':str(source),'checks':results,'pelvis_heights':heights,'failures':failures}
(OUT/('choreography-red.json' if '--' in sys.argv else 'choreography-validation.json')).write_text(json.dumps(result,indent=2)+'\n')
print('MYCEAN_DEATH_CHOREOGRAPHY',len(results),'checks',failures,flush=True)
if failures:raise AssertionError(failures)
