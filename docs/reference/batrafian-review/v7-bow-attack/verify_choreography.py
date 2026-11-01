"""Independent pose checks for a drawn bow rather than a static held prop."""
import bpy,json,sys,math
from pathlib import Path
OUT=Path(__file__).parent
source=Path(sys.argv[sys.argv.index('--')+1])if '--'in sys.argv else OUT/'batrafian-attack-poses.blend'
bpy.ops.wm.open_mainfile(filepath=str(source));scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
bow=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('bow_'))
arrow=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('arrow_'))
results=[]
def check(ok,name):results.append({'check':name,'passed':bool(ok)})
def head(n):return arm.matrix_world@arm.pose.bones[n].head
scene.frame_set(7);bpy.context.view_layer.update()
l,r=head('Bone_023'),head('Bone_019')
check(l.y<-.35,'bow held ahead of chest')
check(r.y-l.y>.30,'drawing hand pulls behind bow hand')
check(abs(r.z-l.z)<.18 and l.z>.9,'hands aim on a shared firing level')
check(not arrow.hide_render,'arrow nocked before release')
shape=bow.data.shape_keys
check(shape is not None and shape.key_blocks.get('Draw') is not None and shape.key_blocks['Draw'].value>.9,'string visibly drawn')
s,e,w=[head(n)for n in ('Bone_025','Bone_024','Bone_023')]
check(math.degrees((s-e).angle(w-e))>140,'bow arm extends toward target')
scene.frame_set(8);bpy.context.view_layer.update()
check(arrow.hide_render,'nocked arrow removed at projectile handoff')
check(shape is not None and shape.key_blocks.get('Draw') is not None and shape.key_blocks['Draw'].value<.05,'string returns on release')
failures=[r['check']for r in results if not r['passed']]
(OUT/('choreography-red.json'if '--'in sys.argv else 'choreography-validation.json')).write_text(json.dumps({'checks':results,'failures':failures},indent=2)+'\n')
print('BATRAFIAN_ARCHERY',len(results),'checks',failures)
if failures:raise AssertionError(failures)
