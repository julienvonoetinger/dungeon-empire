"""Saved static pose: full body/staff crossings, INCLUDING the holding hand."""
import bpy, json
from pathlib import Path
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).parent

def geometry(obj):
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles()
    points=[ev.matrix_world@v.co for v in me.vertices]
    tri=[tuple(t.vertices) for t in me.loop_triangles]
    ev.to_mesh_clear()
    return points,tri

def crossings(pa,ta,pb,tb):
    tree=BVHTree.FromPolygons(pb,tb,all_triangles=True)
    edges={tuple(sorted((t[i],t[(i+1)%3]))) for t in ta for i in range(3)};hits=set()
    for a,b in edges:
        delta=pa[b]-pa[a];length=delta.length
        if length<.00002:continue
        d=delta/length;point,normal,index,dist=tree.ray_cast(pa[a]+d*.00001,d,length-.00002)
        if point is not None:hits.add(tuple(round(float(v),4) for v in point))
    return hits

bpy.ops.wm.open_mainfile(filepath=str(OUT/'mycean-equipped-review.blend'))
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
bp,bt=geometry(body);sp,st=geometry(staff)
hits=crossings(sp,st,bp,bt)|crossings(bp,bt,sp,st)
tree=BVHTree.FromPolygons(sp,st,all_triangles=True)
evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get());me=evaluated.to_mesh()
gi=body.vertex_groups['StaffGripCorrective'].index
hand_points=[evaluated.matrix_world@v.co for v in me.vertices if any(g.group==gi and g.weight>.9 for g in v.groups)]
hand_weights=[next((g.weight for g in v.groups if g.group==gi),0) for v in me.vertices]
evaluated.to_mesh_clear()
body_tree=BVHTree.FromPolygons(bp,bt,all_triangles=True)
hit_details=[]
for h in sorted(hits):
 tri=bt[body_tree.find_nearest(h)[2]]
 hit_details.append({'point':h,'weights':[hand_weights[i] for i in tri]})
distances=[tree.find_nearest(p)[3] for p in hand_points]
report={'surface_crossings_including_hand':len(hits),'crossings':sorted(hits),
        'hit_details':hit_details,
        'excluded_body_triangles':0,'tested_body_triangles':len(bt),
        'hand_vertices_within_6mm':sum(d<.006 for d in distances),'nearest_hand_to_staff':min(distances),
        'staff_floor_clearance':min(p.z for p in sp),
        'limits':'Full static surface intersections; includes hand and all equipment. Does not prove absence of fully contained volumes or collisions during future animations.'}
(OUT/'static-clearance.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('CLEARANCE',json.dumps(report))
