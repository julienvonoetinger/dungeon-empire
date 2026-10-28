import bpy,math,json
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).resolve().parent
meta=json.loads((OUT/'rig.json').read_text());scene=bpy.context.scene
rig=bpy.data.objects['Vulpin_Rig'];root=bpy.data.objects['Vulpin_Ground_Root']
result={}
def screen(p):
    q=world_to_camera_view(scene,scene.camera,p)
    return [q.x*160,(1-q.y)*160]
for name,angle in meta['directions'].items():
    root.rotation_euler.z=math.radians(angle);result[name]=[]
    for i in range(meta['frames']):
        scene.frame_set(i+1);bpy.context.view_layer.update()
        bones={b.name:{'head':screen(rig.matrix_world@b.head),'tail':screen(rig.matrix_world@b.tail)} for b in rig.pose.bones}
        feet={s:screen(rig.matrix_world@rig.pose.bones['foot.'+s].head-Vector((0,0,.08))) for s in ('L','R')}
        result[name].append({'frame':i,'bones':bones,'feet':feet,'contact':{'L':(i/meta['frames'])%1<.6,'R':(i/meta['frames']+.5)%1<.6}})
(OUT/'pose-data.json').write_text(json.dumps(result,indent=2))
print('Evaluated skeleton endpoints exported for all 96 views.')
