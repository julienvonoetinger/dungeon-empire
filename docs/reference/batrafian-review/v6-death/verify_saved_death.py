"""Independently reopen actual keyframes; no pose generator is imported."""
import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector,Matrix
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,bounds,crossings
report=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-death-poses.blend'))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('batrafian_')and any(m.type=='ARMATURE'for m in o.modifiers))
props={n:next(o for o in scene.objects if o.type=='MESH'and o.name.startswith(n+'_'))for n in ('bow','quiver')}
arrow=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('arrow_'))
assert arrow.hide_render and arrow.hide_get()
assert len(arm.data.bones)==26 and len(body.data.vertices)==13176
assert all(sum(g.weight for g in v.groups)>.00001 for v in body.data.vertices)
assert props['quiver'].parent==arm and props['quiver'].parent_bone=='Bone_003'
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,tri=geometry(body);nonhand=[t for t in tri if not any(dominant[i]in ('Bone_023','Bone_022')for i in t)]
checks=[];landed=None
assert len(report['poses'])==10 and sum(report['durations_ms'])==650
root=Vector((0,-.20,0));target=root+Vector((0,0,.46))
for i,entry in enumerate(report['poses']):
    scene.frame_set(i+1);bpy.context.view_layer.update();p,_=geometry(body);allp=p.copy()
    actual=bounds(p);err=max(abs(actual[j][k]-entry['body_bounds'][j][k])for j in range(2)for k in range(3))
    assert err<1e-5 and all(math.isfinite(c)for v in p for c in v)
    assert abs(min(v.z for v in p))<.0001,(i,'body ground')
    objects={}
    for name,obj in props.items():
        q,qt=geometry(obj);allp+=q;objects[name]=(q,qt);b=bounds(q)
        assert all(math.isfinite(c)for v in q for c in v)and min(v.z for v in q)>-.0001,(i,name,'ground')
        assert max(abs(b[j][k]-entry['equipment'][name]['bounds'][j][k])for j in range(2)for k in range(3))<1e-5
        bt=nonhand if name=='bow'and i<3 else tri
        assert crossings(q,qt,p,bt)+crossings(p,bt,q,qt)==0,(i,name,'body crossing')
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        if i==0:
            assert max(abs(rel[j][k]-report['approved_attachments'][name][j][k])for j in range(4)for k in range(4))<1e-5
        if name=='quiver':
            # Strap flex changes only translation, never the mount's rotation/scale.
            base=Matrix(report['approved_attachments'][name]);delta=(rel.translation-base.translation).length
            assert max(abs(rel[j][k]-base[j][k])for j in range(3)for k in range(3))<1e-5
            assert delta<.14 and (i>4 or delta<1e-5),(i,'quiver sway')
        if name=='bow'and i>=3:
            if landed is None:landed=q.copy()
            assert max((a-b).length for a,b in zip(q,landed))<1e-5,(i,'bow moves after landing')
            assert abs(min(v.z for v in q))<.0001,(i,'bow floats')
    a,at=objects['bow'];b,bt=objects['quiver']
    assert crossings(a,at,b,bt)+crossings(b,bt,a,at)==0,(i,'props cross')
    for view,settings in report['views'].items():
        cam=scene.camera;cam.location=target+Vector(settings['camera_vector']).normalized()*8
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
        anchor=world_to_camera_view(scene,cam,root)
        assert max(abs(a-b)for a,b in zip([anchor.x*640,(1-anchor.y)*640],settings['anchor_px']))<.001
        assert all(.01<(q:=world_to_camera_view(scene,cam,v)).x<.99 and .01<q.y<.99 for v in allp),(i,view,'clip')
    checks.append({'frame':i+1,'phase':entry['phase'],'replay_error':err,'ground_ok':True,'nonhand_crossings':0,'four_view_fit':True})
for f in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    assert hashlib.sha256((OUT.parent/'source'/f['file']).read_bytes()).hexdigest()==f['sha256']
assert hashlib.sha256((OUT.parent/'v3-equipment-orientation/batrafian-equipped-review.blend').read_bytes()).hexdigest()==report['source_scene_sha256']
images=[i for i in bpy.data.images if i.type=='IMAGE'and i.size[0]>0]
assert len(images)==12 and all(i.has_data and i.packed_file for i in images)
result={'poses':checks,'bow_landed_frame':4,'quiver_attached':True,'packed_images':12,'sources_unchanged':True,
 'limits':'Held poses and mesh-edge crossings; not exhaustive self/contained-volume collision, interpolation or phone performance.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('SAVED_BATRAFIAN_DEATH_OK',len(checks),'poses; four views, dropped bow, attached quiver')
