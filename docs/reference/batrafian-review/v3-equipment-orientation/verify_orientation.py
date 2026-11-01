"""Before/after orientation checks, independent of the attachment metadata."""
import bpy, json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'v2-meshy-inspection/inspection.blend'))
quiver_source=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('quiver_')).matrix_world.copy()
def inspect(path):
    bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene
    arm=next(o for o in s.objects if o.type=='ARMATURE')
    wrist='Bone_023';rest=arm.matrix_world@arm.data.bones[wrist].matrix_local
    posed=arm.matrix_world@arm.pose.bones[wrist].matrix
    q=(posed@rest.inverted()).to_3x3()
    h=lambda n:arm.matrix_world@arm.data.bones[n].head_local
    fingers=(h('Bone_022')-h(wrist)).normalized()
    thumb=Vector((fingers.z,0,-fingers.x)).normalized()
    actual_thumb=(q@thumb).normalized();actual_palm=(q@Vector((0,1,0))).normalized()
    quiver=next(o for o in s.objects if o.type=='MESH' and o.name.startswith('quiver_'))
    transform=(quiver.matrix_world@quiver_source.inverted()).to_3x3()
    face=(transform@Vector((0,-1,0))).normalized()
    up=(transform@Vector((0,0,1))).normalized()
    return {'thumb_axis':list(actual_thumb),'palm_axis':list(actual_palm),
            'quiver_front_axis':list(face),'quiver_up_axis':list(up),
            'hand_upright':actual_thumb.z>.95 and actual_palm.x<-.95 and abs(actual_palm.z)<.1,
            'quiver_broad_front_outward':face.y>.9 and up.z>.85}
before=inspect(OUT.parent/'v2-meshy-inspection/batrafian-equipped-review.blend')
after=inspect(OUT/'batrafian-equipped-review.blend')
report={'before':before,'after':after,'limits':'Orientation only, supplemented by separate saved-scene clearance checks and native close-up inspection.'}
(OUT/'orientation-validation.json').write_text(json.dumps(report,indent=2)+'\n')
assert not before['hand_upright'] and not before['quiver_broad_front_outward']
assert after['hand_upright'] and after['quiver_broad_front_outward']
print('ORIENTATION_OK',json.dumps(report))
