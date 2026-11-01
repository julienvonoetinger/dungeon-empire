"""Reload all held poses; verify registered geometry and rigid grip persistence."""
import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from mesh_checks import geometry,bounds,crossings
report=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-gait-poses.blend'))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('batrafian_') and o.type=='MESH' and any(m.type=='ARMATURE'for m in o.modifiers))
props={name:next(o for o in scene.objects if o.name.startswith(name+'_')and o.type=='MESH') for name in ('bow','quiver')}
arrow=next(o for o in scene.objects if o.name.startswith('arrow_')and o.type=='MESH')
assert arrow.hide_render and arrow.hide_get(), 'Spare projectile must stay hidden'
sole={s:[v.index for v in body.data.vertices if (p:=body.matrix_world@v.co).z<.13 and (p.x>0)==(s=='L')] for s in ('L','R')}
checks=[];contacts={};reference_grips={}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,tri=geometry(body);nonhand={}
for name,ids in [('bow',[22,23]),('quiver',[])]:
    allowed={f'Bone_{i:03}'for i in ids};nonhand[name]=[t for t in tri if not any(dominant[i] in allowed for i in t)]
assert len(arm.data.bones)==26 and len(body.data.vertices)==13176
assert all(sum(g.weight for g in v.groups)>.00001 for v in body.data.vertices)
for entry in report['poses']:
    scene.frame_set(entry['frame']);bpy.context.view_layer.update();p,_=geometry(body);actual=bounds(p)
    err=max(abs(actual[j][k]-entry['body_bounds'][j][k])for j in range(2)for k in range(3))
    assert err<1e-5,(entry['frame'],'body replay',err)
    assert all(math.isfinite(c)for v in p for c in v)
    assert min(v.z for v in p)>-.0001,(entry['frame'],'floor penetration')
    for side,ids in sole.items():
        low=min(p[i].z for i in ids);expected=report['gaits'][entry['gait']]['lift'][entry['feet'][side]['phase']]
        assert abs(low-expected)<.0001,(entry['frame'],side,low,expected)
        if entry['feet'][side]['grounded']:contacts[(entry['gait'],entry['index'],side)]=sum(p[i].y for i in ids)/len(ids)
    for name,obj in props.items():
        q,qt=geometry(obj);b=bounds(q);err=max(abs(b[j][k]-entry['equipment'][name]['bounds'][j][k])for j in range(2)for k in range(3))
        assert err<1e-5,(entry['frame'],name,'equipment replay',err)
        assert entry['equipment'][name]['nonhand_crossings']==0,(entry['frame'],name,'armor collision')
        assert crossings(q,qt,p,nonhand[name])+crossings(p,nonhand[name],q,qt)==0,(entry['frame'],name,'reloaded armor collision')
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        assert max(abs(rel[i][j]-report['approved_attachments'][name][i][j]) for i in range(4)for j in range(4))<1e-5,(entry['frame'],name,'approved attachment changed')
        if name not in reference_grips:reference_grips[name]=rel.copy()
        assert max(abs(rel[i][j]-reference_grips[name][i][j]) for i in range(4)for j in range(4))<1e-5
    checks.append({'frame':entry['frame'],'gait':entry['gait'],'bounds_replay_error':err,'contacts_ok':True,'attachments_ok':True,'reloaded_equipment_crossings':0})
stride=[]
for gait,cfg in report['gaits'].items():
    for side in ('L','R'):
        for i in range(8):
            a=(gait,i,side);b=(gait,(i+1)%8,side)
            if a not in contacts or b not in contacts:continue
            delta=contacts[b]-contacts[a]
            # Exclude a new contact after the recovery arc; test support travel.
            if delta<0:continue
            expected=cfg['speed']/cfg['fps'];error=abs(delta-expected)
            assert error<.035,(gait,side,i,'stride',delta,expected)
            stride.append({'gait':gait,'side':side,'pose':i,'foot_delta':delta,'travel_delta':expected,'error':error})
for entry in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
assert hashlib.sha256((OUT.parent/'v3-equipment-orientation/batrafian-equipped-review.blend').read_bytes()).hexdigest()==report['source_scene_sha256']
images=[i for i in bpy.data.images if i.type=='IMAGE'and i.size[0]>0]
assert len(images)==12 and all(i.has_data and i.packed_file for i in images)
result={'poses':checks,'support_stride':stride,'packed_images':12,'sources_unchanged':True,
 'limits':'Sampled held poses, real sole vertices and mesh-edge tests. No continuous interpolation, self-collision proof or phone profiling.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('SAVED_BATRAFIAN_GAITS_OK',len(checks),'poses',len(stride),'support intervals')
