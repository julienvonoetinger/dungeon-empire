"""Reload the packed held poses independently; never trust only render logs."""
import bpy,json,math,hashlib,sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,bounds,crossings
report=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-jump-poses.blend'))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('batrafian_')and any(m.type=='ARMATURE'for m in o.modifiers))
props={n:next(o for o in scene.objects if o.type=='MESH'and o.name.startswith(n+'_'))for n in ('bow','quiver')}
arrow=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('arrow_'))
assert arrow.hide_render and arrow.hide_get()
assert len(arm.data.bones)==26 and len(body.data.vertices)==13176
assert all(sum(g.weight for g in v.groups)>.00001 for v in body.data.vertices)
sole={s:[v.index for v in body.data.vertices if (p:=body.matrix_world@v.co).z<.13 and (p.x>0)==(s=='L')]for s in ('L','R')}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,tri=geometry(body)
nonhand={'bow':[t for t in tri if not any(dominant[i]in ('Bone_023','Bone_022')for i in t)],'quiver':tri}
checks=[];rest=None;rest_props={}
assert len(report['poses'])==12 and sum(report['durations_ms'])==1000
for i,entry in enumerate(report['poses']):
    scene.frame_set(i+1);bpy.context.view_layer.update();p,_=geometry(body)
    if i==0:rest=p.copy()
    if i==11:assert max((a-b).length for a,b in zip(p,rest))<1e-6,'Rest endpoint mismatch'
    actual=bounds(p);err=max(abs(actual[j][k]-entry['body_bounds'][j][k])for j in range(2)for k in range(3))
    assert err<1e-5 and all(math.isfinite(c)for v in p for c in v)
    # All local soles are above z0, so every nonnegative continuous trajectory
    # sample is safe too. Altitude is not stored on the Blender armature root.
    assert arm.location.length<1e-6 and min(v.z for v in p)>-.0001
    for side,ids in sole.items():
        assert abs(min(p[j].z for j in ids)-entry['local_sole_target'])<.0001,(i,side,'sole')
    for name,obj in props.items():
        q,qt=geometry(obj);b=bounds(q)
        if i==0:rest_props[name]=q.copy()
        if i==11:assert max((a-b).length for a,b in zip(q,rest_props[name]))<1e-6,(name,'rest endpoint mismatch')
        assert all(math.isfinite(c)for v in q for c in v)and min(v.z for v in q)>-.0001,(i,name,'ground')
        assert max(abs(b[j][k]-entry['equipment'][name]['bounds'][j][k])for j in range(2)for k in range(3))<1e-5
        assert crossings(q,qt,p,nonhand[name])+crossings(p,nonhand[name],q,qt)==0,(i,name,'body crossing')
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        assert max(abs(rel[j][k]-report['approved_attachments'][name][j][k])for j in range(4)for k in range(4))<1e-5
    checks.append({'frame':i+1,'phase':entry['phase'],'replay_error':err,'soles_ok':True,'attachments_ok':True,'nonhand_crossings':0})
for f in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    assert hashlib.sha256((OUT.parent/'source'/f['file']).read_bytes()).hexdigest()==f['sha256']
assert hashlib.sha256((OUT.parent/'v3-equipment-orientation/batrafian-equipped-review.blend').read_bytes()).hexdigest()==report['source_scene_sha256']
images=[i for i in bpy.data.images if i.type=='IMAGE'and i.size[0]>0]
assert len(images)==12 and all(i.has_data and i.packed_file for i in images)
result={'poses':checks,'identical_rest_endpoints':True,'packed_images':12,'sources_unchanged':True,
 'limits':'Held poses and mesh-edge crossings only; not exhaustive self/contained-volume collision, interpolation or phone performance.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('SAVED_BATRAFIAN_JUMP_OK',len(checks),'poses; endpoints and equipment unchanged')
