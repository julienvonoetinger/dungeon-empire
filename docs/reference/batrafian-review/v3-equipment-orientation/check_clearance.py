"""Check saved rigid grips and intersections outside the holding hand regions."""
import bpy,math,json,hashlib
from pathlib import Path
from mathutils import Vector,Quaternion
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).parent

def geometry(obj):
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles()
    p=[ev.matrix_world@v.co for v in me.vertices];tri=[tuple(t.vertices) for t in me.loop_triangles];ev.to_mesh_clear();return p,tri
def crossings(pa,ta,pb,tb):
    tree=BVHTree.FromPolygons(pb,tb,all_triangles=True)
    edges={tuple(sorted((t[i],t[(i+1)%3]))) for t in ta for i in range(3)};hits=set()
    for a,b in edges:
        delta=pa[b]-pa[a];length=delta.length
        if length<.00002:continue
        d=delta/length;point,normal,index,dist=tree.ray_cast(pa[a]+d*.00001,d,length-.00002)
        if point is not None:hits.add(tuple(round(float(v),4) for v in point))
    return len(hits)

bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-equipped-review.blend'))
s=bpy.context.scene;arm=next(o for o in s.objects if o.type=='ARMATURE')
def mesh(name):return next(o for o in s.objects if o.name.startswith(name+'_') and o.type=='MESH' and (name!='batrafian' or any(m.type=='ARMATURE'for m in o.modifiers)))
body=mesh('batrafian');bp,bt=geometry(body)
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
results={}
for name in ['bow','quiver']:
 obj=mesh(name);op,ot=geometry(obj)
 test_tri=[t for t in bt if name!='bow' or not any(dominant[i] in ['Bone_023','Bone_022'] for i in t)]
 hit=crossings(op,ot,bp,test_tri)+crossings(bp,test_tri,op,ot)
 results[name]={'surface_crossings_outside_holding_hand':hit}
print('CROSSINGS',json.dumps(results))
(OUT/'static-clearance.json').write_text(json.dumps(results,indent=2)+'\n')
