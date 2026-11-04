import bpy, json, hashlib, math
from pathlib import Path
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'invoker-poses.blend'))
body=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.find_armature())
staff=bpy.data.objects['Staff']
arm=staff.parent
scene=bpy.context.scene
def geometry(obj):
    evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh=evaluated.to_mesh();mesh.calc_loop_triangles()
    points=[evaluated.matrix_world@v.co for v in mesh.vertices]
    triangles=[tuple(t.vertices) for t in mesh.loop_triangles]
    evaluated.to_mesh_clear()
    return points,triangles
def edge_hits(points,triangles,indices,tree):
    edges={tuple(sorted((triangles[i][j],triangles[i][(j+1)%3]))) for i in indices for j in range(3)}
    hits=0
    for a,b in edges:
        delta=points[b]-points[a];length=delta.length
        if length<.00002: continue
        direction=delta/length
        if tree.ray_cast(points[a]+direction*.00001,direction,length-.00002)[0] is not None: hits+=1
    return hits
records=[]
for frame in [0,8,16,24,32,40,47]:
    scene.frame_set(frame)
    bp,bt=geometry(body);sp,st=geometry(staff)
    btree=BVHTree.FromPolygons(bp,bt,all_triangles=True)
    stree=BVHTree.FromPolygons(sp,st,all_triangles=True)
    pairs=btree.overlap(stree)
    crossings=edge_hits(bp,bt,{a for a,b in pairs},stree)+edge_hits(sp,st,{b for a,b in pairs},btree)
    evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
    digits={}
    for label,chain in [('lower',(36,35,34,33)),('middle',(44,43,42,41)),('upper',(40,39,38,37)),('thumb',(32,31,30,29))]:
        groups={body.vertex_groups[f'Bone_{i:03d}'].index for i in chain}
        indices=[v.index for v in mesh.vertices if sum(g.weight for g in v.groups if g.group in groups)>.5]
        digits[label]=min(stree.find_nearest(bp[i])[3] for i in indices)
    evaluated.to_mesh_clear()
    record=dict(frame=frame,body_staff_edge_crossings=crossings,finger_contact=digits,staff_floor=min(p.z for p in sp)-min(p.z for p in bp))
    records.append(record)
    print('POSE_CHECK',json.dumps(record),flush=True)
scene.frame_set(0);first,_=geometry(body);first_staff,_=geometry(staff)
scene.frame_set(47);last,_=geometry(body);last_staff,_=geometry(staff)
endpoint=max((a-b).length for a,b in zip(first+first_staff,last+last_staff))
source=json.loads((OUT/'invoker.json').read_text())
unchanged=hashlib.sha256(Path(source['source']).read_bytes()).hexdigest()==source['sha256']
report=dict(poses=records,endpoint_error=endpoint,source_unchanged=unchanged,packed_images=sum(bool(i.packed_file) for i in bpy.data.images))
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
assert unchanged and endpoint<.00001
assert all(r['body_staff_edge_crossings']==0 for r in records)
assert all(max(r['finger_contact'].values())<.012 for r in records)
assert all(r['staff_floor']>-.005 for r in records)
print('STAFF_MOTION_CHECK_OK',flush=True)
