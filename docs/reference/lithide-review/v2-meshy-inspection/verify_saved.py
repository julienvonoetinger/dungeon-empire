"""Reopen the derived Blender scene and verify persistence of equipment/rig."""
import bpy,json,hashlib,math
from pathlib import Path
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'paladin-equipped-review.blend'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
assert len(arm.data.bones)==50
body=next(o for o in bpy.context.scene.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE'for m in o.modifiers))
assert len(body.data.vertices)==14680
assert all(sum(g.weight for g in v.groups)>1e-5 for v in body.data.vertices)
attachments=json.loads((OUT/'equipment-fit.json').read_text())['attachments']
checks=[]
for name,attachment in attachments.items():
    o=next(o for o in bpy.context.scene.objects if o.name.startswith(name+'_') and o.type=='MESH')
    assert o.parent==arm and o.parent_type=='BONE' and o.parent_bone==attachment['bone']
    initial=o.matrix_world.copy();pb=arm.pose.bones[o.parent_bone];basis=pb.matrix_basis.copy();mode=pb.rotation_mode
    pb.rotation_mode='XYZ';pb.rotation_euler.x+=math.radians(8);bpy.context.view_layer.update()
    moved=max(abs(o.matrix_world[i][j]-initial[i][j])for i in range(4)for j in range(4))
    pb.matrix_basis=basis;pb.rotation_mode=mode;bpy.context.view_layer.update()
    error=max(abs(o.matrix_world[i][j]-initial[i][j])for i in range(4)for j in range(4))
    assert moved>1e-5 and error<1e-5
    checks.append({'object':name,'bone':pb.name,'follows_after_reload':True,'restore_error':error})
images=[i for i in bpy.data.images if i.type=='IMAGE' and i.size[0]>0]
assert len(images)==9 and all(i.has_data and i.packed_file for i in images)
provenance=json.loads((OUT.parent/'source/provenance.json').read_text())
for entry in provenance['files']:
    for p in (OUT.parent/'source'/entry['file'],Path(entry['original'])):
        assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],str(p)
report={'status':'passed','bones':len(arm.data.bones),'weighted_vertices':len(body.data.vertices),'embedded_images':len(images),'attachments':checks,'original_and_archive_hashes_match':True,'limits':'Attachment persistence only. Initial grip fit is provisional; no walking/combat sprite or runtime integration.'}
(OUT/'saved-scene-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('SAVED_SCENE_OK',json.dumps(report))
