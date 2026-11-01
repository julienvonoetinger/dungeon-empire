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
def inspect(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    s=bpy.context.scene;arm=next(o for o in s.objects if o.type=='ARMATURE')
    body=next(o for o in s.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE'for m in o.modifiers))
    bp,bt=geometry(body)
    dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
    metrics={}
    for name,wrist,hand_ids in [('hammer','Bone_023',[22,23,*range(38,50)]),('shield','Bone_019',[18,19,*range(26,38)])]:
        obj=next(o for o in s.objects if o.name.startswith(name+'_') and o.type=='MESH')
        op,ot=geometry(obj);allowed={f'Bone_{i:03}' for i in hand_ids}
        # Faces touching the holding hand are excluded: contact there is intended.
        nonhand=[t for t in bt if not any(dominant[i] in allowed for i in t)]
        hit_count=crossings(op,ot,bp,nonhand)+crossings(bp,nonhand,op,ot)
        pb=arm.pose.bones[wrist];rest=obj.matrix_world.copy();basis=pb.matrix_basis.copy()
        relative=(arm.matrix_world@pb.matrix).inverted()@obj.matrix_world
        pb.rotation_quaternion=pb.rotation_quaternion@Quaternion((0,1,0),math.radians(8));bpy.context.view_layer.update()
        moved=max(abs(obj.matrix_world[i][j]-rest[i][j]) for i in range(4)for j in range(4))
        relative_after=(arm.matrix_world@pb.matrix).inverted()@obj.matrix_world
        error=max(abs(relative_after[i][j]-relative[i][j]) for i in range(4)for j in range(4))
        pb.matrix_basis=basis;bpy.context.view_layer.update()
        restore=max(abs(obj.matrix_world[i][j]-rest[i][j]) for i in range(4)for j in range(4))
        metrics[name]={'nonhand_surface_crossings':hit_count,'follows_hand':moved>1e-5,'relative_attachment_error':error,'restore_error':restore}
    return metrics

before=inspect(OUT.parent/'v2-meshy-inspection/paladin-equipped-review.blend')
after=inspect(OUT/'paladin-equipped-review.blend')
report={'before':before,'after':after,'limits':'Static mesh-edge/triangle surface intersections outside holding-hand regions. Hand contacts inspected in close-up. Does not certify every animation pose or contained closed volumes.'}
fit=json.loads((OUT/'equipment-fit.json').read_text())
hammer=next(o for o in bpy.context.scene.objects if o.name.startswith('hammer_') and o.type=='MESH')
strike=(hammer.matrix_world.to_3x3()@Vector((1,0,0))).normalized()
shaft=(hammer.matrix_world.to_3x3()@Vector((0,0,1))).normalized()
grip_error=(hammer.matrix_world@Vector(fit['source_grips']['hammer'])-Vector(fit['grips']['R'])).length
report['hammer_orientation']={'strike_axis':list(strike),'shaft_axis':list(shaft),'grip_error':grip_error}
for entry in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
report['source_hashes_unchanged']=True
images=[i for i in bpy.data.images if i.type=='IMAGE'and i.size[0]>0]
assert len(images)==9 and all(i.has_data and i.packed_file for i in images)
report['embedded_images']=len(images)
(OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('EQUIPMENT_VALIDATION',json.dumps(report))
assert all(v['follows_hand'] and v['relative_attachment_error']<1e-5 and v['restore_error']<1e-5 for v in after.values())
assert all(v['nonhand_surface_crossings']==0 for v in after.values()),'Equipment still crosses non-hand armor'
assert (strike-Vector((0,-1,0))).length<1e-5 and (shaft-Vector((0,0,1))).length<1e-5
assert grip_error<1e-5,'Hammer rotation shifted its grip'
