"""Evaluated whole-mesh measurements for held-pose sources."""
import bpy
from mathutils.bvhtree import BVHTree

def geometry(obj):
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles()
    points=[ev.matrix_world@v.co for v in me.vertices]
    triangles=[tuple(t.vertices) for t in me.loop_triangles]
    ev.to_mesh_clear();return points,triangles

def bounds(points):
    return [[min(v[k] for v in points) for k in range(3)],[max(v[k] for v in points) for k in range(3)]]

def crossings(pa,ta,pb,tb):
    tree=BVHTree.FromPolygons(pb,tb,all_triangles=True)
    edges={tuple(sorted((t[i],t[(i+1)%3]))) for t in ta for i in range(3)};hits=set()
    for a,b in edges:
        delta=pa[b]-pa[a];length=delta.length
        if length<.00002:continue
        d=delta/length;p,_,_,_=tree.ray_cast(pa[a]+d*.00001,d,length-.00002)
        if p is not None:hits.add(tuple(round(float(v),4) for v in p))
    return len(hits)
