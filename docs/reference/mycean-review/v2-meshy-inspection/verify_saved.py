"""Reload the saved Mycean source and check the complete static grip."""
import bpy, hashlib, json, math, runpy
from pathlib import Path
from mathutils import Quaternion, Vector
OUT=Path(__file__).parent
ns=runpy.run_path(str(OUT/'check_clearance.py'))
geometry,crossings=ns['geometry'],ns['crossings']
clearance=json.loads((OUT/'static-clearance.json').read_text())
assert clearance['surface_crossings_including_hand']==0, 'Hand/staff intersection'
assert clearance['excluded_body_triangles']==0
assert clearance['staff_floor_clearance']>=0
assert clearance['nearest_hand_to_staff']<.012, 'Hand detached from staff'
scene=bpy.context.scene;arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
assert len(arm.data.bones)==35 and len(body.data.vertices)==15429
assert all(sum(g.weight for g in v.groups if g.group!=body.vertex_groups['StaffGripCorrective'].index)>1e-5 for v in body.data.vertices)
images=[i for i in bpy.data.images if i.type=='IMAGE' and i.size[0]>0]
assert len(images)==6 and all(i.has_data and i.packed_file and list(i.size)==[2048,2048] for i in images)
fit=json.loads((OUT/'equipment-fit.json').read_text())
assert len(fit['views'])==6 and len(fit['closeups'])==2
assert all((OUT/('equipped-'+v+'.png')).is_file() for v in fit['views'])
assert all((OUT/(v+'.png')).is_file() for v in fit['closeups'])
# The original defect must be observable when the contact constraint is absent.
contact=body.modifiers['GripOutsideStaff'];contact.show_viewport=False;bpy.context.view_layer.update()
bp,bt=geometry(body);sp,st=geometry(staff)
without=len(crossings(bp,bt,sp,st)|crossings(sp,st,bp,bt))
assert without>0, 'Regression fixture no longer exercises contact'
contact.show_viewport=True;bpy.context.view_layer.update()
attachments=[];wrist=arm.pose.bones['Bone_031'];basis=wrist.matrix_basis.copy()
for name in ['staff_output_unwrapped','MyceanGripCorrective','StaffGripContactEnvelope']:
 obj=bpy.data.objects[name];assert obj.parent==arm and obj.parent_type=='BONE' and obj.parent_bone==wrist.name
 before=obj.matrix_world.copy();relative=(arm.matrix_world@wrist.matrix).inverted()@before
 wrist.rotation_quaternion=wrist.rotation_quaternion@Quaternion((0,1,0),math.radians(8));bpy.context.view_layer.update()
 after=(arm.matrix_world@wrist.matrix).inverted()@obj.matrix_world
 error=max(abs(after[i][j]-relative[i][j]) for i in range(4) for j in range(4))
 moved=max(abs(obj.matrix_world[i][j]-before[i][j]) for i in range(4) for j in range(4))
 wrist.matrix_basis=basis;bpy.context.view_layer.update()
 restored=max(abs(obj.matrix_world[i][j]-before[i][j]) for i in range(4) for j in range(4))
 assert error<1e-5 and moved>1e-5 and restored<1e-5
 attachments.append({'name':name,'relative_error':error,'restore_error':restored})
assert (staff.matrix_world@Vector(fit['staff']['source_grip'])-Vector(fit['staff']['target'])).length<1e-5
# Compare the base mesh and UV coordinates to fresh imports, not just our report.
def mesh_signature(o):
 return {'vertices':[tuple(v.co) for v in o.data.vertices],
         'faces':[tuple(p.vertices) for p in o.data.polygons],
         'uv':[[tuple(d.uv) for d in layer.data] for layer in o.data.uv_layers]}
provenance=json.loads((OUT.parent/'source/provenance.json').read_text())
for entry in provenance['files']:
 path=OUT.parent/'source'/entry['file'];assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']
 original=Path(entry['originalPath'])
 if original.exists():assert hashlib.sha256(original.read_bytes()).hexdigest()==entry['sha256']
 expected=body if entry['file'].startswith('mycean') else staff
 old=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path))
 imported=max((o for o in bpy.data.objects if o not in old and o.type=='MESH'),key=lambda o:len(o.data.vertices))
 a,b=mesh_signature(imported),mesh_signature(expected)
 print('MESH_COMPARE',entry['file'],len(a['vertices']),len(b['vertices']),a['faces']==b['faces'],
       max((Vector(x)-Vector(y)).length for x,y in zip(a['vertices'],b['vertices'])),
       max((Vector(x)-Vector(y)).length for al,bl in zip(a['uv'],b['uv']) for x,y in zip(al,bl)))
 assert a['faces']==b['faces'] and len(a['vertices'])==len(b['vertices']) and len(a['uv'])==len(b['uv'])
 assert max((Vector(x)-Vector(y)).length for x,y in zip(a['vertices'],b['vertices']))<1e-6
 assert max((Vector(x)-Vector(y)).length for al,bl in zip(a['uv'],b['uv']) for x,y in zip(al,bl))<1e-6
report={'status':'passed','bones':35,'weighted_body_vertices':15429,'packed_images':6,
 'reweighted_grip_vertices':fit['grip_correction']['reweighted_vertex_count'],
 'crossings_without_contact_constraint':without,'crossings_with_constraint':0,
 'full_body_triangles_tested':clearance['tested_body_triangles'],
 'nearest_hand_to_staff':clearance['nearest_hand_to_staff'],'attachments':attachments,
 'source_hashes_match':True,'base_mesh_and_uv_match_originals':True,'views':fit['views'],
 'limits':'Static pose only. Wrist attachment follows/restores, but future animation clearances, independently articulated fingers and in-game scale remain unvalidated.'}
(OUT/'saved-scene-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('MYCEAN_SAVED_SCENE_OK',json.dumps(report))
