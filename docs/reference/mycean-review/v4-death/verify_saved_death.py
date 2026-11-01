"""Independently reload final held poses, contact modifiers and dropped staff."""
import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v3-locomotion'))
from mesh_checks import geometry,bounds,crossings
report=json.loads((OUT/'poses.json').read_text())
SOURCE=OUT.parent/'v2-meshy-inspection/mycean-equipped-review.blend'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
source_body=bpy.data.objects['mycean_output_unwrapped']
def fingerprint(obj):
    return {'verts':[list(v.co) for v in obj.data.vertices],
      'uv':[[list(x.uv) for x in uv.data] for uv in obj.data.uv_layers],
      'weights':[[(g.group,g.weight) for g in v.groups] for v in obj.data.vertices]}
originals={n:fingerprint(bpy.data.objects[n]) for n in ['mycean_output_unwrapped','staff_output_unwrapped']}
original_textures=sorted(hashlib.sha256(i.packed_file.data).hexdigest() for i in bpy.data.images if i.type=='IMAGE' and i.packed_file)
bpy.ops.wm.open_mainfile(filepath=str(OUT/'mycean-death-poses.blend'))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
grip=next(m for m in body.modifiers if m.type=='LATTICE');contact=next(m for m in body.modifiers if m.type=='SHRINKWRAP')
assert len(arm.data.bones)==35 and len(body.data.vertices)==15429
for n,fp in originals.items():assert fingerprint(bpy.data.objects[n])==fp,(n,'original geometry/UV/weights changed')
assert original_textures==sorted(hashlib.sha256(i.packed_file.data).hexdigest() for i in bpy.data.images if i.type=='IMAGE' and i.packed_file)
for name in ['staff_output_unwrapped','MyceanGripCorrective','StaffGripContactEnvelope']:
    obj=bpy.data.objects[name];assert obj.parent==arm and obj.parent_bone=='Bone_031'
assert bpy.data.objects['StaffGripContactEnvelope'].hide_render
assert bpy.data.objects['MyceanSoleProbe'].hide_render
assert len(report['poses'])==10 and sum(report['durations_ms'])==650
checks=[];landed=None
root=Vector((0,-.20,0));target=root+Vector((0,0,.46))
for i,entry in enumerate(report['poses']):
    scene.frame_set(i+1);bpy.context.view_layer.update()
    p,t=geometry(body);sp,st=geometry(staff);actual=bounds(p);sb=bounds(sp)
    err=max(abs(actual[j][k]-entry['body_bounds'][j][k]) for j in range(2) for k in range(3))
    assert err<1e-5,(i,'body replay')
    assert max(abs(sb[j][k]-entry['staff_bounds'][j][k]) for j in range(2) for k in range(3))<1e-5,(i,'staff replay')
    assert all(math.isfinite(c) for v in p+sp for c in v)
    assert min(v.z for v in p)>-.0001 and min(v.z for v in p)<.001,(i,'body floor')
    assert min(v.z for v in sp)>-.0001,(i,'staff floor')
    count=crossings(p,t,sp,st)+crossings(sp,st,p,t)
    assert count==0,(i,'full body/staff crossings',count)
    assert abs(grip.strength-entry['grip_strength'])<1e-5
    assert contact.show_render==contact.show_viewport==entry['contact_enabled']
    if i>=3:
        if landed is None:landed=sp.copy()
        assert max((a-b).length for a,b in zip(sp,landed))<1e-5,(i,'staff slides after landing')
        assert abs(min(v.z for v in sp))<.0001,(i,'staff floats')
        assert grip.strength==0 and not contact.show_render
    for view,settings in report['views'].items():
        cam=scene.camera;cam.location=target+Vector(settings['camera_vector']).normalized()*8
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
        anchor=world_to_camera_view(scene,cam,root)
        assert max(abs(a-b) for a,b in zip([anchor.x*640,(1-anchor.y)*640],settings['anchor_px']))<.001
        assert all(.01<(q:=world_to_camera_view(scene,cam,v)).x<.99 and .01<q.y<.99 for v in p+sp),(i,view,'clip')
    checks.append({'frame':i+1,'replay_error':err,'full_body_crossings':count,'floor_ok':True,'four_view_fit':True})
scene.frame_set(1);bpy.context.view_layer.update()
assert grip.strength==1 and contact.show_render and contact.show_viewport,'replay must restore held grip'
for f in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    assert hashlib.sha256((OUT.parent/'source'/f['file']).read_bytes()).hexdigest()==f['sha256']
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==report['source_scene_sha256']
images=[i for i in bpy.data.images if i.type=='IMAGE' and i.size[0]>0]
assert len(images)==6 and all(i.has_data and i.packed_file for i in images)
result={'poses':checks,'staff_landed_frame':4,'grip_restores_on_replay':True,'packed_images':6,'source_mesh_uv_weights_textures_unchanged':True,
 'sources_unchanged':True,'limits':'Held poses and mesh-edge crossings; not exhaustive self/contained-volume collision, interpolation or phone performance.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('SAVED_MYCEAN_DEATH_OK',len(checks),'poses; four views, dropped staff, grip restore',flush=True)
