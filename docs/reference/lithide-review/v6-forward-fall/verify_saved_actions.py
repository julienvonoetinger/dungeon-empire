"""Reload source poses: real floor contacts, equipment intersections and fixed scale."""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,bounds,crossings
report=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(OUT/'paladin-action-poses.blend'))
scene=bpy.context.scene;a=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and any(m.type=='ARMATURE'for m in o.modifiers))
props={n:next(o for o in scene.objects if o.name.startswith(n+'_')and o.type=='MESH')for n in ('hammer','shield')}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,tri=geometry(body);nonhand={}
for name,ids in [('hammer',[22,23,*range(38,50)]),('shield',[18,19,*range(26,38)])]:
    allowed={f'Bone_{i:03}'for i in ids};nonhand[name]=[t for t in tri if not any(dominant[i]in allowed for i in t)]
checks=[];grips={};neutral=None
for entry in report['poses']:
    scene.frame_set(entry['frame']);bpy.context.view_layer.update()
    p,tri=geometry(body);b=bounds(p)
    err=max(abs(b[j][k]-entry['body_bounds'][j][k])for j in range(2)for k in range(3))
    assert err<1e-5,(entry['frame'],'body replay',err)
    assert all(math.isfinite(c)for v in p for c in v)
    assert b[0][2]>-.0001,(entry['frame'],'body below floor')
    cfg=report['actions'][entry['action']];allp=p.copy()
    if entry['action']=='hurt':
        assert all(abs(v)<.0001 for v in entry['sole_min_z'].values()),'hurt planted feet'
        if entry['index']==0:neutral=p
        if entry['index']==7:assert max((v-w).length for v,w in zip(p,neutral))<1e-5,'neutral return'
    for name,obj in props.items():
        op,ot=geometry(obj);allp+=op;pb=bounds(op)
        assert pb[0][2]>-.0001,(entry['frame'],name,'below floor')
        replay=max(abs(pb[j][k]-entry['equipment'][name]['bounds'][j][k])for j in range(2)for k in range(3))
        assert replay<1e-5,(entry['frame'],name,'prop replay',replay)
        body_tri=tri if entry['action']=='death'and entry['index']>=3 else nonhand[name]
        hits=crossings(op,ot,p,body_tri)+crossings(p,body_tri,op,ot)
        assert hits==0,(entry['frame'],name,'equipment/body crossings',hits)
        relative=(a.matrix_world@a.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        if name not in grips:grips[name]=relative.copy()
        grip_error=max(abs(relative[i][j]-grips[name][i][j])for i in range(4)for j in range(4))
        if entry['action']=='hurt'or entry['index']==0:assert grip_error<1e-5,(entry['frame'],name,'held grip')
        elif entry['index']>=3:assert grip_error>.1 and abs(pb[0][2])<.0001,(entry['frame'],name,'released on floor')
    hp,ht=geometry(props['hammer']);sp,st=geometry(props['shield'])
    assert crossings(hp,ht,sp,st)+crossings(sp,st,hp,ht)==0,(entry['frame'],'equipment overlap')
    # Check every vertex from all meshes in all four cameras, not just PNG alpha.
    root=Vector((0,-.20,0));target=root+Vector((0,0,.46 if entry['action']=='death'else .72));cam=scene.camera;cam.data.ortho_scale=cfg['ortho']
    scene.render.resolution_x=cfg['size']*2;scene.render.resolution_y=cfg['size']*2
    for view,viewcfg in report['views'][entry['action']].items():
        cam.location=target+Vector(viewcfg['camera_vector']).normalized()*8
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
        assert all(.01<(q:=world_to_camera_view(scene,cam,v)).x<.99 and .01<q.y<.99 for v in allp),(entry['frame'],view,'clipping')
    checks.append({'frame':entry['frame'],'replay_error':err,'floor_and_equipment_ok':True})
death=[p for p in report['poses']if p['action']=='death']
assert death[4]['pelvis'][2]<death[0]['pelvis'][2]-.15,'knees must buckle before forward fall'
assert death[-1]['head'][2]<death[0]['head'][2]-.7,'head lowers to corpse pose'
assert abs(death[-1]['body_bounds'][0][2])<.0001,'corpse supported by real mesh'
for entry in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
assert hashlib.sha256((OUT.parent/'v3-equipment-grips/paladin-equipped-review.blend').read_bytes()).hexdigest()==report['source_scene_sha256']
images=[im for im in bpy.data.images if im.type=='IMAGE'and im.size[0]>0]
assert len(images)==9 and all(im.packed_file for im in images)
assert len(a.data.bones)==50 and len(body.data.vertices)==14680
result={'poses':checks,'source_hashes_unchanged':True,'packed_images':9,'four_camera_bounds':True,
 'limits':'Held poses only. Edge/triangle checks do not prove absence of full containment or all armour self-intersections. No continuous 3D motion or phone performance validation.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('PALADIN_ACTION_RELOAD_OK',len(checks),'poses / 4 cameras')
