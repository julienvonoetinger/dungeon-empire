import bpy, json, math, hashlib
from pathlib import Path
OUT = Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'vulpin-chest-open-poses.blend'))
report = json.loads((OUT/'poses.json').read_text())
mesh = bpy.data.objects['output_unwrapped']
assert not any(o.name in ['Pick','TensionWrench'] for o in bpy.data.objects)
checks = []
for i in range(8):
    bpy.context.scene.frame_set(i+1)
    obj = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); me = obj.to_mesh()
    points = [obj.matrix_world@v.co for v in me.vertices]; obj.to_mesh_clear()
    bounds = [[min(v[k] for v in points) for k in range(3)],[max(v[k] for v in points) for k in range(3)]]
    error = max(abs(bounds[j][k]-report['poses'][i]['bounds'][j][k]) for j in range(2) for k in range(3))
    assert error < 1e-5, (i,error)
    assert all(math.isfinite(c) for v in points for c in v)
    # Conservative container interior below the lip, excluding the rim/grip.
    # This is a placement proxy, not a collision proof for painted lid/ornaments.
    inside = [p for p in points if abs(p.x)<.40 and -1.30<p.y<-.705 and 0<p.z<.44]
    assert not inside, (i, 'Body inside chest container proxy',len(inside))
    checks.append({'pose':i+1, 'bounds_replay_error':error, 'container_interior_vertices':len(inside)})
assert hashlib.sha256(Path(report['source']).read_bytes()).hexdigest() == report['source_sha256']
(OUT/'saved-pose-validation.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print('SAVED_POSES_REPLAY_OK',len(checks),max(x['bounds_replay_error'] for x in checks))
