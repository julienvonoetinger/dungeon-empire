"""Independent packed-pose reload, full grip contacts and foot registration."""
import bpy,json,math,hashlib,sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from mesh_checks import geometry,bounds,crossings
report=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(OUT/'mycean-gait-poses.blend'))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
probe=bpy.data.objects['MyceanSoleProbe'];assert probe.hide_render
assert bpy.data.objects['StaffGripContactEnvelope'].hide_render
assert len(arm.data.bones)==35 and len(body.data.vertices)==15429
assert all(sum(g.weight for g in v.groups if body.vertex_groups[g.group].name.startswith('Bone_'))>1e-5 for v in body.data.vertices)
sole={s:[v.index for v in body.data.vertices if (p:=body.matrix_world@v.co).z<.13 and (p.x>0)==(s=='L')] for s in ('L','R')}
checks=[];contacts={};cached={}
for entry in report['poses']:
 scene.frame_set(entry['frame']);bpy.context.view_layer.update()
 p,tri=geometry(body);feet,_=geometry(probe);sp,st=geometry(staff)
 actual=bounds(p);err=max(abs(actual[j][k]-entry['body_bounds'][j][k]) for j in range(2) for k in range(3))
 assert err<1e-5,(entry['frame'],'body replay',err)
 assert all(math.isfinite(c) for v in p+sp for c in v)
 assert min(v.z for v in p)>-.0001,(entry['frame'],'body below floor',min(v.z for v in p))
 assert min(v.z for v in sp)>0,(entry['frame'],'staff below floor')
 for side,ids in sole.items():
  low=min(feet[i].z for i in ids);expected=report['gaits'][entry['gait']]['lift'][entry['feet'][side]['phase']]
  assert abs(low-expected)<.0001,(entry['frame'],side,'sole',low,expected)
  if entry['feet'][side]['grounded']:contacts[(entry['gait'],entry['index'],side)]=sum(feet[i].y for i in ids)/len(ids)
 for name,expected in report['approved_attachments'].items():
  obj=bpy.data.objects[name];rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
  assert max(abs(rel[i][j]-expected[i][j]) for i in range(4) for j in range(4))<1e-5,(entry['frame'],name,'grip changed')
 hit=crossings(sp,st,p,tri)+crossings(p,tri,sp,st)
 assert hit==0,(entry['frame'],'staff/full-body collision, hand included',hit)
 assert entry['equipment']['staff']['full_body_crossings']==0
 cached[entry['frame']]=(actual,bounds(sp))
 checks.append({'frame':entry['frame'],'gait':entry['gait'],'body_replay_error':err,'sole_contacts_ok':True,'full_body_crossings':hit,'staff_min_z':min(v.z for v in sp)})
stride=[]
for gait,cfg in report['gaits'].items():
 for side in ('L','R'):
  for i in range(8):
   a=(gait,i,side);b=(gait,(i+1)%8,side)
   if a not in contacts or b not in contacts:continue
   delta=contacts[b]-contacts[a]
   expected=cfg['speed']/cfg['fps'];error=abs(delta-expected)
   assert error<.0002,(gait,side,i,'support slide',delta,expected)
   stride.append({'gait':gait,'side':side,'pose':i,'foot_delta':delta,'travel_delta':expected,'error':error})
assert len(stride)==12, 'All eight walk and four run support transitions must be checked'
assert all(not p['airborne'] for p in report['poses'] if p['gait']=='walk')
assert sum(p['airborne'] for p in report['poses'] if p['gait']=='run')==2
# Loop playback must revisit the exact starting geometry; no accumulated root drift.
for start,end in [(1,8),(9,16)]:
 scene.frame_set(end);scene.frame_set(start);bpy.context.view_layer.update()
 for obj,expected in zip((body,staff),cached[start]):
  actual=bounds(geometry(obj)[0]);assert max(abs(actual[j][k]-expected[j][k]) for j in range(2) for k in range(3))<1e-5
for entry in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
 assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
assert hashlib.sha256((OUT.parent/'v2-meshy-inspection/mycean-equipped-review.blend').read_bytes()).hexdigest()==report['source_scene_sha256']
images=[i for i in bpy.data.images if i.type=='IMAGE' and i.size[0]>0]
assert len(images)==6 and all(i.has_data and i.packed_file for i in images)
result={'poses':checks,'support_stride':stride,'packed_images':6,'source_hashes_unchanged':True,'loop_replay_ok':True,
 'all_three_grip_attachments_preserved':True,'hand_excluded_from_collision_checks':False,
 'limits':'Sampled held poses, real sole vertices and full equipment/body surface crossings. Not continuous 3D interpolation, all self-collisions or phone profiling.'}
(OUT/'saved-pose-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('SAVED_MYCEAN_GAITS_OK',len(checks),'poses',len(stride),'support intervals')
