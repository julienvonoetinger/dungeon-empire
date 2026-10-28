import bpy, json
from pathlib import Path
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'vulpin-chest-lockpick-poses.blend'))
mesh=bpy.data.objects['output_unwrapped']
data=json.loads((OUT/'poses.json').read_text())
result=[]
for i in range(8):
    bpy.context.scene.frame_set(i+1)
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=obj.to_mesh()
    p=[obj.matrix_world@v.co for v in me.vertices];me.calc_loop_triangles()
    behind=[v.z for v in p if v.y<data['lock_target'][1]]
    low=[v.y for v in p if v.z<.49/data['model_to_grid']]
    candidates=[t for t in me.loop_triangles if min(p[n].z for n in t.vertices)<.45/data['model_to_grid']]
    tri_clearance=min(p[n].y for t in candidates for n in t.vertices)-data['lock_target'][1]
    result.append({'pose':i,'crossing_z_range':[min(behind),max(behind)] if behind else None,'below_chest_top_min_y':min(low),'chest_tier_triangle_clearance_model':tri_clearance})
    obj.to_mesh_clear()
print(json.dumps(result,indent=2))
