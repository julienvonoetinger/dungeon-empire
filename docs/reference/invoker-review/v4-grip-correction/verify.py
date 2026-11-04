import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).parent
old='--old' in sys.argv
source=OUT.parent/'v3-meshy-inspection/invoker-equipped.blend' if old else OUT/'invoker-equipped.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
body=next(o for o in bpy.data.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers));staff=bpy.data.objects['Staff'];arm=staff.parent
def geometry(obj):
 ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles();p=[ev.matrix_world@v.co for v in me.vertices];t=[tuple(t.vertices)for t in me.loop_triangles];ev.to_mesh_clear();return p,t
def crossings(pa,ta,pb,tb):
 tree=BVHTree.FromPolygons(pb,tb,all_triangles=True);hits=set()
 for a,b in {tuple(sorted((t[i],t[(i+1)%3])))for t in ta for i in range(3)}:
  delta=pa[b]-pa[a];length=delta.length
  if length<.00002:continue
  d=delta/length;point,_,_,_=tree.ray_cast(pa[a]+d*.00001,d,length-.00002)
  if point is not None:hits.add(tuple(round(float(v),5)for v in point))
 return hits
bp,bt=geometry(body);sp,st=geometry(staff)
evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get());evaluated_mesh=evaluated.to_mesh()
grip=[p for p in sp if .74<p.z<.94];center=Vector([(min(p[i]for p in grip)+max(p[i]for p in grip))*.5 for i in range(3)])
palm=arm.matrix_world@arm.pose.bones['Bone_019'].head
direction=palm-center;direction.z=0;direction.normalize()
digits={};fail=[];tree=BVHTree.FromPolygons(sp,st,all_triangles=True)
for label,chain in [('lower',(36,35,34,33)),('middle',(44,43,42,41)),('upper',(40,39,38,37)),('thumb',(32,31,30,29))]:
 tip=arm.matrix_world@arm.pose.bones[f'Bone_{chain[-1]:03d}'].tail
 delta=tip-center;delta.z=0
 groups={body.vertex_groups[f'Bone_{i:03d}'].index for i in chain}
 indices=[v.index for v in evaluated_mesh.vertices if sum(g.weight for g in v.groups if g.group in groups)>.5]
 distances=[tree.find_nearest(bp[i])[3]for i in indices]
 digits[label]={'tip':list(tip),'tip_opposition_to_palm':delta.dot(direction),'closest_mesh_distance':min(distances) if distances else None}
 if not distances or min(distances)>.008:fail.append(label+' is separated from the handle')
 if label!='thumb' and delta.dot(direction)>-.008:fail.append(label+' does not wrap beyond shaft axis')
 if label=='thumb' and delta.y<=0:fail.append('thumb is not opposed behind shaft')
 if label!='thumb' and delta.y>=0:fail.append(label+' is not around front of shaft')
hits=crossings(sp,st,bp,bt)|crossings(bp,bt,sp,st)
evaluated.to_mesh_clear()
if hits:fail.append('body/staff surface crossings')
for entry in json.loads((OUT.parent/'source/provenance.json').read_text(encoding='utf-8-sig'))['files']:
 assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
report={'source':str(source),'grip_center':list(center),'digits':digits,'crossings_count':len(hits),'crossings':sorted(hits),'failures':fail,'original_hashes_unchanged':True,'packed_images':sum(bool(i.packed_file)for i in bpy.data.images)}
if not old:
 pb=arm.pose.bones['Bone_020'];saved=pb.matrix.copy();mode=pb.rotation_mode
 attached=[staff,bpy.data.objects['GripContactEnvelope']]
 before=[pb.matrix.inverted()@arm.matrix_world.inverted()@o.matrix_world for o in attached]
 pb.rotation_mode='XYZ';pb.rotation_euler.y+=.1;bpy.context.view_layer.update()
 after=[pb.matrix.inverted()@arm.matrix_world.inverted()@o.matrix_world for o in attached]
 error=max(abs(a[i][j]-b[i][j])for a,b in zip(before,after)for i in range(4)for j in range(4))
 assert error<1e-5
 pb.matrix=saved;pb.rotation_mode=mode;bpy.context.view_layer.update()
 report['attachment_probe_error']=error
(OUT/('before-validation.json' if old else 'validation.json')).write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items()if k!='crossings'}))
assert not fail,fail
