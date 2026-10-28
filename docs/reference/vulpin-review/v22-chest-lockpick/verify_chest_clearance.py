"""Conservative triangle separation from the catalogue's chest bounds.

The head may project over the receiving plane ABOVE the chest. Only triangles
touching the chest's height interval need to remain outside its front plane.
Painted chest bounds are placement proxies, not reconstructed lid geometry.
"""
import bpy,json,re
from pathlib import Path
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'vulpin-chest-lockpick-poses.blend'))
data=json.loads((OUT/'poses.json').read_text())
contacts=json.loads((OUT/'chest-contacts.json').read_text())
catalog=(OUT/'../../../../assets/dungeon/isometric-kit/catalog.tres').resolve().read_text(encoding='utf8')
entries=json.loads(re.search(r'^entries = (.*)$',catalog,re.M).group(1))
config={'se':('prop-chest-west',0,-1),'sw':('prop-chest-north',1,-1),
        'nw':('prop-chest-east',0,1),'ne':('prop-chest',1,1)}
mesh=bpy.data.objects['output_unwrapped']; k=data['model_to_grid']; checks=[]
for i in range(8):
    bpy.context.scene.frame_set(i+1)
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); me=obj.to_mesh();me.calc_loop_triangles()
    p=[obj.matrix_world@v.co for v in me.vertices]
    for view,(chest,axis,sign) in config.items():
        b=entries[chest]['bounds']; front=sign*b['min' if sign<0 else 'max'][axis]
        candidates=[t for t in me.loop_triangles if min(p[n].z*k for n in t.vertices)<=b['max'][2]+.005]
        nearest=min(p[n].y-data['lock_target'][1] for t in candidates for n in t.vertices)*k
        lock_front=sign*contacts['views'][view]['grid'][axis]
        clearance=lock_front+nearest-front
        checks.append({'pose':i,'view':view,'clearance_cells':clearance,'chest_height':b['max'][2]})
    obj.to_mesh_clear()
result={'checks':checks,'contacts':contacts,'method':__doc__}
(OUT/'chest-clearance.json').write_text(json.dumps(result,indent=2),encoding='utf8')
assert all(c['clearance_cells']>.003 for c in checks),checks
print('CHEST_CLEARANCE_OK',len(checks),min(c['clearance_cells'] for c in checks))
