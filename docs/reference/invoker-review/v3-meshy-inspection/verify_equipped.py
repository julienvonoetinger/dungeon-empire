import bpy,json,hashlib
from pathlib import Path
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'invoker-equipped.blend'))
body=next(o for o in bpy.data.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
staff=bpy.data.objects['Staff']
def geometry(obj):
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles()
    points=[ev.matrix_world@v.co for v in me.vertices];tri=[tuple(t.vertices)for t in me.loop_triangles];ev.to_mesh_clear();return points,tri
def crossings(pa,ta,pb,tb):
    tree=BVHTree.FromPolygons(pb,tb,all_triangles=True);hits=set()
    for a,b in {tuple(sorted((t[i],t[(i+1)%3])))for t in ta for i in range(3)}:
        delta=pa[b]-pa[a];length=delta.length
        if length<.00002:continue
        d=delta/length;point,_,_,_=tree.ray_cast(pa[a]+d*.00001,d,length-.00002)
        if point is not None:hits.add(tuple(round(float(v),4)for v in point))
    return hits
bp,bt=geometry(body);sp,st=geometry(staff)
hits=crossings(sp,st,bp,bt)|crossings(bp,bt,sp,st)
assert not hits,'Staff crosses body or hand'
assert min(p.z for p in sp)>=0,'Staff below ground'
assert staff.parent_bone=='Bone_020'
arm=staff.parent;pb=arm.pose.bones[staff.parent_bone]
before=pb.matrix.copy();relative=pb.matrix.inverted()@arm.matrix_world.inverted()@staff.matrix_world
mode=pb.rotation_mode;pb.rotation_mode='XYZ';pb.rotation_euler.y+=.1;bpy.context.view_layer.update()
after=pb.matrix.inverted()@arm.matrix_world.inverted()@staff.matrix_world
attachment_error=max(abs(relative[i][j]-after[i][j])for i in range(4)for j in range(4))
assert attachment_error<1e-5
pb.matrix=before;pb.rotation_mode=mode;bpy.context.view_layer.update()
tree=BVHTree.FromPolygons(bp,bt,all_triangles=True)
grip_distance=min(tree.find_nearest(p)[3]for p in sp if .7<p.z<.95)
sources=json.loads((OUT.parent/'source/provenance.json').read_text(encoding='utf-8-sig'))
for entry in sources['files']:assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
report={'surface_crossings_including_hand':len(hits),'crossings':sorted(hits),'staff_floor_min':min(p.z for p in sp),'grip_nearest_distance':grip_distance,'parent_bone':staff.parent_bone,'attachment_probe_max_error':attachment_error,'source_hashes_unchanged':True,'packed_images':sum(bool(i.packed_file)for i in bpy.data.images),'limits':'Static edge/surface checks, not complete self-collision or containment validation. Pose and fingers remain an artistic proposal.'}
(OUT/'equipment-validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
