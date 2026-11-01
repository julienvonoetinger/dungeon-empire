"""Reload packed equipment and check source integrity, attachment and clearance."""
import bpy, json, hashlib, math, runpy
from pathlib import Path
from mathutils import Quaternion, Vector
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-equipped-review.blend'))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH' and o.name.startswith('batrafian_') and any(m.type=='ARMATURE' for m in o.modifiers))
assert len(arm.data.bones)==26 and len(body.data.vertices)==13176
assert all(sum(g.weight for g in v.groups)>1e-5 for v in body.data.vertices)
assert all(m.use_deform_preserve_volume for m in body.modifiers if m.type=='ARMATURE')
prior=json.loads((OUT.parent/'v2-meshy-inspection/equipment-fit.json').read_text())
for side,fore in [('L','Bone_024'),('R','Bone_020')]:
    old=prior['hands'][side]
    for name,key in [(fore,'elbow'),(old['wrist'],'head')]:
        actual=(arm.matrix_world@arm.pose.bones[name].matrix).translation
        assert (actual-Vector(old[key])).length<1e-5,'Segment endpoint moved: '+name
images=[i for i in bpy.data.images if i.type=='IMAGE' and i.size[0]>0]
assert len(images)==12 and all(i.has_data and i.packed_file for i in images)
fit=json.loads((OUT/'equipment-fit.json').read_text())
attachments=[]
for name,entry in fit['attachments'].items():
    o=bpy.data.objects[name];pb=arm.pose.bones[entry['bone']]
    assert o.parent==arm and o.parent_type=='BONE' and o.parent_bone==pb.name
    before=o.matrix_world.copy();basis=pb.matrix_basis.copy()
    relative=(arm.matrix_world@pb.matrix).inverted()@before
    pb.rotation_quaternion=pb.rotation_quaternion@Quaternion((0,1,0),math.radians(8))
    bpy.context.view_layer.update()
    moved=max(abs(o.matrix_world[i][j]-before[i][j]) for i in range(4) for j in range(4))
    after=(arm.matrix_world@pb.matrix).inverted()@o.matrix_world
    error=max(abs(after[i][j]-relative[i][j]) for i in range(4) for j in range(4))
    pb.matrix_basis=basis;bpy.context.view_layer.update()
    restored=max(abs(o.matrix_world[i][j]-before[i][j]) for i in range(4) for j in range(4))
    assert moved>1e-5 and error<1e-5 and restored<1e-5
    attachments.append({'name':name,'bone':pb.name,'relative_error':error,'restore_error':restored})
arrow=next(o for o in scene.objects if o.type=='MESH' and o.name.startswith('arrow_'))
assert arrow.parent is None and arrow.hide_render
p=[arrow.matrix_world@v.co for v in arrow.data.vertices]
assert abs(max(v.z for v in p)-min(v.z for v in p)-.79)<1e-5
provenance=json.loads((OUT.parent/'source/provenance.json').read_text(encoding='utf8'))
for entry in provenance['files']:
    assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
    original=Path(entry['originalPath'])
    if original.exists():assert hashlib.sha256(original.read_bytes()).hexdigest()==entry['sha256']
assert len(fit['views'])==6,'Incomplete pilot render set'
for view in fit['views']:assert (OUT/('equipped-'+view+'.png')).is_file()
# Independent reload and mesh-edge / triangle checks outside intended hand contact.
runpy.run_path(str(OUT/'check_clearance.py'))
clearance=json.loads((OUT/'static-clearance.json').read_text())
assert all(x['surface_crossings_outside_holding_hand']==0 for x in clearance.values())
report={'status':'passed','bones':26,'weighted_vertices':13176,'packed_images':12,
        'attachments':attachments,'source_hashes_match':True,'arrow_independent':True,
        'static_clearance':clearance,'views':fit['views'],
        'limits':'Static edge/triangle crossings only, excludes intended bow hand contact and does not test contained volumes or all future poses. Grouped finger curl is provisional; bow/string are rigid.'}
(OUT/'saved-scene-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('SAVED_SCENE_OK',json.dumps(report))
