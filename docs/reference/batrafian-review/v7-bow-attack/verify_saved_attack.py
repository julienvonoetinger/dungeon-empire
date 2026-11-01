"""Reload actual packed keys independently, including original deformed string."""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,bounds,crossings
r=json.loads((OUT/'poses.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-attack-poses.blend'))
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['batrafian_output_unwrapped']
props={n:bpy.data.objects[n+'_output_unwrapped']for n in ('bow','quiver','arrow')}
bow,quiver,arrow=[props[n]for n in props];draw=bow.data.shape_keys.key_blocks['Draw']
assert len(body.data.vertices)==13176 and len(arm.data.bones)==26
assert len(bow.data.vertices)==9502 and len(bow.data.shape_keys.key_blocks)==2
assert bow.parent_bone=='Bone_023'and quiver.parent_bone=='Bone_003'
dom=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
checks=[];rest=None;root=Vector((0,-.20,0));target=root+Vector((0,0,.78))
assert len(r['poses'])==12 and sum(r['durations_ms'])==1150 and r['release_ms']==690
for i,entry in enumerate(r['poses']):
 scene.frame_set(i+1);bpy.context.view_layer.update();p,t=geometry(body);allp=p.copy()
 b=bounds(p);error=max(abs(b[j][k]-entry['body_bounds'][j][k])for j in range(2)for k in range(3))
 assert error<1e-5 and min(v.z for v in p)>-.0001 and all(math.isfinite(c)for v in p for c in v)
 if i==0:rest=p.copy()
 if i==11:assert max((a-b).length for a,b in zip(p,rest))<1e-5,'Rest mismatch'
 assert (not arrow.hide_render)==(1<=i<=6)
 assert abs(draw.value-entry['draw'])<1e-5
 nock=bow.matrix_world@(Vector(r['nock_source'])+Vector(r['nock_draw'])*draw.value)
 assert (nock-Vector(entry['nock'])).length<1e-5
 for name,obj in props.items():
  if obj.hide_render:continue
  q,qt=geometry(obj);allp+=q
  allowed={'bow':{'Bone_022','Bone_023','Bone_018','Bone_019'}if 2<=i<=6 else {'Bone_022','Bone_023'},'quiver':set(),'arrow':{'Bone_018','Bone_019','Bone_022','Bone_023'}}[name]
  bt=[x for x in t if not any(dom[j]in allowed for j in x)]
  assert crossings(q,qt,p,bt)+crossings(p,bt,q,qt)==0,(i,name,'body crossing')
  assert min(v.z for v in q)>-.0001,(i,name,'floor')
  b=bounds(q);assert max(abs(b[j][k]-entry['equipment'][name]['bounds'][j][k])for j in range(2)for k in range(3))<1e-5
 if 4<=i<=6:
  amin=min(v.co.z for v in arrow.data.vertices)
  assert (arrow.matrix_world@Vector((0,0,amin))-nock).length<1e-5,(i,'arrow nock')
  direction=arrow.matrix_world.to_quaternion()@Vector((0,0,1));forward=bow.matrix_world.to_quaternion()@Vector((-1,0,0))
  assert direction.dot(forward)>.99999,(i,'arrow points along bow')
  wrist=arm.matrix_world@arm.pose.bones['Bone_019'].head
  assert (nock-wrist).length<.13,(i,'drawing hand loses nock',(nock-wrist).length)
 if i in (2,3):
  from mathutils import Quaternion
  delta=bow.matrix_world.to_quaternion()@Quaternion((0,0,1),math.radians(-90))
  wrist=arm.matrix_world@arm.pose.bones['Bone_019'].head
  amin=min(v.co.z for v in arrow.data.vertices)
  tail=arrow.matrix_world@Vector((0,0,amin))
  assert (tail-(wrist+delta@Vector((.035,-.095,.018)))).length<1e-5,(i,'carried arrow leaves hand')
 for view,settings in r['views'].items():
  camera=scene.camera;camera.location=target+Vector(settings['camera_vector']).normalized()*8
  camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
  assert all(.01<(v:=world_to_camera_view(scene,camera,x)).x<.99 and .01<v.y<.99 for x in allp),(i,view,'clip')
 checks.append({'frame':i+1,'replay_error':error,'nonhand_crossings':0,'nock_aligned':True,'four_view_fit':True})
for f in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
 assert hashlib.sha256((OUT.parent/'source'/f['file']).read_bytes()).hexdigest()==f['sha256']
assert hashlib.sha256((OUT.parent/'v3-equipment-orientation/batrafian-equipped-review.blend').read_bytes()).hexdigest()==r['source_scene_sha256']
images=[i for i in bpy.data.images if i.type=='IMAGE'and i.size[0]>0]
assert len(images)==12 and all(i.has_data and i.packed_file for i in images)
(OUT/'saved-pose-validation.json').write_text(json.dumps({'poses':checks,'packed_images':12,'sources_unchanged':True,'limits':'Held poses; not exhaustive self/contained-volume collision or interpolated3D.'},indent=2)+'\n')
print('SAVED_BATRAFIAN_ATTACK_OK',len(checks),'poses; nock/hand/string and whole meshes')
