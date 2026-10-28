"""Conservative mesh/door separation, with the low jamb and upper crown tiers.

Every triangle touching a tier must be entirely outside its frontmost plane.
This proves separation even for triangle interiors; the four view rotations
preserve it. Lockpicks intentionally reach the leaf and are excluded.
"""
import bpy,json,sys
from pathlib import Path
OUT=Path(__file__).parent
before='--before' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(OUT/('vulpin-lockpick-poses.blend1' if before else 'vulpin-lockpick-poses.blend')))
geometry=json.loads((OUT/'../../door-redesign/seal-v1/wireframe-v6-clean-leaf/geometry.json').resolve().read_text())
report=json.loads((OUT/'poses.json').read_text())
faces=[f for f in geometry['door']['faces'] if not f['kind'].startswith('leaf')]
split=.3133333333333333
leaf=max(p[1] for f in geometry['door']['faces'] if f['kind']=='leaf' for p in f['points'])
tiers=[('lower',0,split),('upper',split,2)]
mesh=bpy.data.objects['output_unwrapped'];k=report['model_to_grid'];checks=[]
for i in range(8):
    bpy.context.scene.frame_set(i+1)
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=obj.to_mesh();me.calc_loop_triangles()
    tip=bpy.data.objects['Pick'].data.splines[0].points[-1].co
    points=[obj.matrix_world@v.co for v in me.vertices]
    for name,lo,hi in tiers:
        # Include surfaces that actually occupy this tier's interior.
        candidates=[f for f in faces if max(p[2] for p in f['points'])>lo+1e-8 and min(p[2] for p in f['points'])<hi-1e-8]
        front=max(p[1] for f in candidates for p in f['points'])
        triangles=[t for t in me.loop_triangles if max(points[n].z*k for n in t.vertices)>=lo and min(points[n].z*k for n in t.vertices)<=hi]
        nearest=min(leaf+(points[n].y-tip.y)*k for t in triangles for n in t.vertices)
        clearance=nearest-front
        checks.append({'pose':i,'tier':name,'clearance_cells':clearance,'front':front})
    obj.to_mesh_clear()
result={'checks':checks,'method':__doc__,'before':before}
(OUT/('masonry-before.json' if before else 'masonry-clearance.json')).write_text(json.dumps(result,indent=2))
assert all(c['clearance_cells']>.003 for c in checks),checks
print('MASONRY_CLEARANCE_OK',len(checks),min(c['clearance_cells'] for c in checks))
