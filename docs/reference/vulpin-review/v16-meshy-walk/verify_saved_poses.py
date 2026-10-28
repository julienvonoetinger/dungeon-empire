import bpy,json,math
from pathlib import Path
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'vulpin-walk-poses.blend'))
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
    checks.append({'pose':i+1,'bounds_replay_error':error})
(OUT/'saved-pose-validation.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print('SAVED_POSES_REPLAY_OK',len(checks),max(x['bounds_replay_error'] for x in checks))
