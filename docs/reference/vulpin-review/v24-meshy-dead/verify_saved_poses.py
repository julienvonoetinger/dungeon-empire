import bpy,json,math
from pathlib import Path
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'vulpin-fall-poses.blend'))
report=json.loads((OUT/'poses.json').read_text(encoding='utf8'))
mesh=bpy.data.objects['output_unwrapped'];checks=[]
arm=bpy.data.objects['SmartRigArmature']
for i in range(10):
    bpy.context.scene.frame_set(i+1)
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=obj.to_mesh()
    points=[obj.matrix_world@v.co for v in me.vertices];obj.to_mesh_clear()
    bounds=[[min(p[k] for p in points) for k in range(3)], [max(p[k] for p in points) for k in range(3)]]
    error=max(abs(bounds[j][k]-report['poses'][i]['bounds'][j][k]) for j in range(2) for k in range(3))
    assert error<1e-5,(i,error)
    assert all(math.isfinite(c) for p in points for c in p)
    assert abs(min(p.z for p in points))<1e-6
    checks.append({'pose':i,'bounds_replay_error':error,'floor_min':min(p.z for p in points)})
# These samples establish distinct support phases, not a physical simulation.
assert report['poses'][4]['floor_samples']['knees']<.03
assert report['poses'][4]['floor_samples']['head']>.35
assert report['poses'][-1]['floor_samples']['head']<.025
assert report['poses'][-1]['floor_samples']['hands']<.025
assert report['poses'][-1]['floor_samples']['body']<.04
assert report['poses'][3]['hip'][2]<report['poses'][0]['hip'][2]-.15
arms=[]
for side,names in {'R':['Bone_026','Bone_025','Bone_024'],'L':['Bone_031','Bone_030','Bone_029']}.items():
    shoulder,elbow,wrist=[arm.matrix_world@arm.pose.bones[n].head for n in names]
    forward=shoulder.y-wrist.y
    angle=math.degrees((shoulder-elbow).angle(wrist-elbow))
    assert forward>.26,('hands beside head rather than forward',side,forward)
    assert angle>165,('folded final arm',side,angle)
    arms.append({'side':side,'forward_reach':forward,'elbow_degrees':angle})
(OUT/'final-arm-validation.json').write_text(json.dumps(arms,indent=2),encoding='utf8')
(OUT/'saved-pose-validation.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print('SAVED_FALL_POSES_OK',len(checks),'maximum bounds error',max(x['bounds_replay_error'] for x in checks))
