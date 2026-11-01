"""Independently inspect actual saved spell channel, corrected grips and foot supports."""
import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v3-locomotion'))
from mesh_checks import geometry,bounds,crossings
SOURCE=OUT.parent/'v2-meshy-inspection/mycean-equipped-review.blend'
source=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else OUT/'mycean-unlock-poses.blend'
report=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
def fingerprint(obj):
    return {'verts':[list(v.co) for v in obj.data.vertices],
      'faces':[(list(p.vertices),p.material_index) for p in obj.data.polygons],
      'uv':[[list(x.uv) for x in uv.data] for uv in obj.data.uv_layers],
      'weights':[[(g.group,g.weight) for g in v.groups] for v in obj.data.vertices]}
originals={n:fingerprint(bpy.data.objects[n]) for n in ['mycean_output_unwrapped','staff_output_unwrapped']}
original_textures=sorted(hashlib.sha256(i.packed_file.data).hexdigest() for i in bpy.data.images if i.type=='IMAGE' and i.packed_file)
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
grip=next(m for m in body.modifiers if m.type=='LATTICE');contact=next(m for m in body.modifiers if m.type=='SHRINKWRAP')
checks=[];failures=[]
def check(ok,label):
    checks.append({'check':label,'passed':bool(ok)})
    if not ok:failures.append(label)
def head(n):return arm.matrix_world@arm.pose.bones[n].head
scene.frame_set(1);bpy.context.view_layer.update();start_head=head('Bone_017').copy();start_hip=head('Bone_000').copy()
start_body=geometry(body)[0];start_staff=geometry(staff)[0]
scene.frame_set(4);bpy.context.view_layer.update()
check((head('Bone_031')-Vector(report['poses'][0]['joints']['Bone_031'])).length>.10,'staff hand raises and aims')
check(head('Bone_000').z<start_hip.z-.02,'knees brace')
check(head('Bone_017').y<start_head.y-.01,'head aims forward')
if '--' in sys.argv:
    (OUT/'choreography-red.json').write_text(json.dumps({'checks':checks,'failures':failures},indent=2)+'\n')
    print('MYCEAN_UNLOCK_NEGATIVE_CONTROL',len(checks),failures,flush=True)
    assert not failures,failures
    raise SystemExit(0)
check(len(arm.data.bones)==35 and len(body.data.vertices)==15429,'original rig and body counts')
for n,fp in originals.items():check(fingerprint(bpy.data.objects[n])==fp,n+' original geometry/UV/weights/material assignments')
check(original_textures==sorted(hashlib.sha256(i.packed_file.data).hexdigest() for i in bpy.data.images if i.type=='IMAGE' and i.packed_file),'original packed textures')
probe=bpy.data.objects['MyceanSoleProbe'];check(probe.hide_render,'measurement probe hidden')
check(bpy.data.objects['StaffGripContactEnvelope'].hide_render,'contact proxy hidden')
check(len(report['poses'])==12 and sum(report['durations_ms'])==1850,'twelve slots over1850ms')
sole={s:[v.index for v in body.data.vertices if (p:=body.matrix_world@v.co).z<.13 and (p.x>0)==(s=='L')] for s in ('L','R')}
support_errors=[];pose_records=[]
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
for i,entry in enumerate(report['poses']):
    scene.frame_set(i+1);bpy.context.view_layer.update()
    p,t=geometry(body);sp,st=geometry(staff);feet,_=geometry(probe)
    check(all(math.isfinite(c) for v in p+sp for c in v),f'{i} finite geometry')
    actual=bounds(p);sb=bounds(sp)
    check(max(abs(actual[j][k]-entry['body_bounds'][j][k]) for j in range(2) for k in range(3))<1e-5,f'{i} body replay')
    check(max(abs(sb[j][k]-entry['staff_bounds'][j][k]) for j in range(2) for k in range(3))<1e-5,f'{i} staff replay')
    check(min(v.z for v in p)>-.0001 and min(v.z for v in p)<.001,f'{i} body ground')
    check(min(v.z for v in sp)>0,f'{i} staff above floor')
    hits=crossings(p,t,sp,st)+crossings(sp,st,p,t)
    check(hits==0,f'{i} whole body/staff contact including hand')
    cap_z=max(v.co.z for v in staff.data.vertices)
    cap_points=[v.co for v in staff.data.vertices if v.co.z>cap_z-.025]
    cap=sum(cap_points,Vector())/len(cap_points);cap.z=cap_z+.012
    actual_emitter=staff.matrix_world@cap
    check((actual_emitter-Vector(entry['emitter_world'])).length<1e-5,f'{i} actual saved staff cap emitter')
    for s,ids in sole.items():
        support=Vector((sum(feet[j].x for j in ids)/len(ids),sum(feet[j].y for j in ids)/len(ids),min(feet[j].z for j in ids)))
        error=(support-Vector(report['contacts'][s])).length;support_errors.append(error)
        check(error<.0002,f'{i} {s} fixed XYZ sole support')
    for name,expected in report['approved_attachments'].items():
        obj=bpy.data.objects[name]
        check(obj.parent==arm and obj.parent_bone=='Bone_031',f'{i} {name} wrist parent')
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        check(max(abs(rel[j][k]-expected[j][k]) for j in range(4) for k in range(4))<1e-5,f'{i} {name} original mount')
    check(grip.strength==1 and contact.show_render and contact.show_viewport,f'{i} approved grip enabled')
    for view,settings in report['views'].items():
        cam=scene.camera;cam.location=target+Vector(settings['camera_vector']).normalized()*8
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
        anchor=world_to_camera_view(scene,cam,root)
        check(max(abs(a-b) for a,b in zip([anchor.x*640,(1-anchor.y)*640],settings['anchor_px']))<.001,f'{i} {view} registered anchor')
        emitter=world_to_camera_view(scene,cam,Vector(entry['emitter_world']))
        check(max(abs(a-b) for a,b in zip([emitter.x*640,(1-emitter.y)*640],settings['emitters'][i]))<.001,f'{i} {view} emitter registration')
        check(all(.015<(q:=world_to_camera_view(scene,cam,v)).x<.985 and .015<q.y<.985 for v in p+sp),f'{i} {view} no clipping')
    pose_records.append({'frame':i+1,'full_body_crossings':hits,'staff_min_z':min(v.z for v in sp)})
check(max((a-b).length for a,b in zip(p,start_body))<1e-5,'exact full-body neutral recovery')
check(max((a-b).length for a,b in zip(sp,start_staff))<1e-5,'exact staff neutral recovery')
for f in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    check(hashlib.sha256((OUT.parent/'source'/f['file']).read_bytes()).hexdigest()==f['sha256'],f['file']+' immutable')
check(hashlib.sha256(SOURCE.read_bytes()).hexdigest()==report['source_scene_sha256'],'equipped source immutable')
images=[i for i in bpy.data.images if i.type=='IMAGE' and i.size[0]>0]
check(len(images)==6 and all(i.has_data and i.packed_file for i in images),'six packed original images')
result={'checks':checks,'failures':failures,'poses':pose_records,'max_support_error':max(support_errors),
 'limits':'Held poses, full equipment/body surface crossing and sole support checks; not exhaustive self/contained-volume collisions, interpolation or phone performance.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('MYCEAN_UNLOCK_SAVED',len(checks),'checks',len(failures),'failures',failures,flush=True)
assert not failures,failures
