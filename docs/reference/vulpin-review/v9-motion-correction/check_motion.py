"""Evaluate the articulated rig; no game, save, or rendered-source mutation."""
from pathlib import Path
import json
src=Path(__file__).with_name('build_clips.py')
g={'__file__':str(src),'__name__':'__main__'}
exec(compile(src.read_text().split('# Match the existing camera')[0],str(src),'exec'),g)
bpy=g['bpy'];rig=g['rig'];pose=g['pose'];tools=g['tools']
samples=[]
for i in range(121):
 t=i/120;pose('death',t);dg=bpy.context.evaluated_depsgraph_get();mins={}
 for o in bpy.data.objects:
  if o.type=='MESH' and o not in tools:
   e=o.evaluated_get(dg);mins[o.name]=min((e.matrix_world@v.co).z for v in e.data.vertices)
 hip=rig.matrix_world@rig.pose.bones['pelvis'].head
 samples.append({'t':t,'hip_z':hip.z,'minimum_z':min(mins.values()),'parts_min_z':mins})
 assert min(mins.values())>=-1e-5,('Ground penetration',t,mins)
 assert rig.rotation_quaternion.angle<1e-5,'Whole-rig tipping returned'
assert samples[0]['hip_z']-samples[24]['hip_z']>.1,'Hips must sink before lateral collapse'
end=samples[-1]['parts_min_z']
assert end['Pelvis']<.07 and end['Hood volume']<.09 and end['Empty glove.R']<.02,('Final body support too high',end)
final={b.name:b.matrix.copy() for b in rig.pose.bones};loc=rig.location.copy()
pose('dead',0)
assert (rig.location-loc).length<1e-6
assert max(abs(a-b) for n,m in final.items() for ar,br in zip(m,rig.pose.bones[n].matrix) for a,b in zip(ar,br))<1e-6
report={'samples':121,'penetration_min':min(s['minimum_z'] for s in samples),'hip_drop_before_roll':samples[0]['hip_z']-samples[24]['hip_z'],'final_support':end,'dead_equals_last_fall_pose':True,'whole_rig_rotation':0,'samples_at_six_times':[samples[i] for i in [0,24,48,72,96,120]],'limits':'Rigid untextured mannequin; no soft-body collisions or physical-device validation. Contact tolerances describe proxy shapes, not final painted feet/clothing.'}
src.with_name('motion-validation.json').write_text(json.dumps(report,indent=2))
print('MOTION_CHECK_PASS',json.dumps({k:report[k] for k in ['penetration_min','hip_drop_before_roll','dead_equals_last_fall_pose','whole_rig_rotation']}),flush=True)
