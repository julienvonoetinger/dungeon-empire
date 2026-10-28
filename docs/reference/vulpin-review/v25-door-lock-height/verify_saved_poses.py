import bpy,json,math
from pathlib import Path
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'vulpin-lockpick-poses.blend'))
report=json.loads((OUT/'poses.json').read_text())
mesh=bpy.data.objects['output_unwrapped']
checks=[]
for i in range(8):
    bpy.context.scene.frame_set(i+1)
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=obj.to_mesh()
    points=[obj.matrix_world@v.co for v in me.vertices];obj.to_mesh_clear()
    bounds=[[min(v[k] for v in points) for k in range(3)],[max(v[k] for v in points) for k in range(3)]]
    error=max(abs(bounds[j][k]-report['poses'][i]['bounds'][j][k]) for j in range(2) for k in range(3))
    assert error<1e-5,(i,error)
    assert all(math.isfinite(c) for v in points for c in v)
    pick=bpy.data.objects['Pick'].data.splines[0].points[-1].co
    target=report['lock_target']
    tip_error=max(abs(pick[k]-target[k]) for k in range(3))
    assert tip_error<1e-6,(i,tip_error)
    checks.append({'pose':i+1,'bounds_replay_error':error,'tool_tip_error':tip_error})
(OUT/'saved-pose-validation.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print('SAVED_POSES_REPLAY_OK',len(checks),max(x['bounds_replay_error'] for x in checks))


