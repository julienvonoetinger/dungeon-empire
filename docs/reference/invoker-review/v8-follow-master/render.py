"""Additional actual camera directions of the unchanged equipped walk source."""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
SRC=OUT.parent/'v5-procession'
source=SRC/'invoker-poses.blend'
digest=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene
camera=scene.camera
camera.animation_data_clear()
records=json.loads((SRC/'invoker.json').read_text())['frames']
records=[r for r in records if r['clip'] in ['idle','walk']]
scene.render.resolution_x=scene.render.resolution_y=384
scene.render.resolution_percentage=100
result=[]
for name,angle in [('ne',45),('se',135),('sw',225),('nw',315)]:
    folder=OUT/name
    folder.mkdir(parents=True,exist_ok=True)
    a=math.radians(angle)
    direction=Vector((math.sin(a)*math.sqrt(3),math.cos(a)*math.sqrt(3),1)).normalized()
    for record in records:
        scene.frame_set(record['index'])
        focus=Vector((0,0,.8+record['ground']))
        camera.location=focus+direction*7
        camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
        output=folder/record['file']
        scene.render.filepath=str(output)
        bpy.ops.render.render(write_still=True)
        result.append(dict(direction=name,angle=angle,**record))
assert hashlib.sha256(source.read_bytes()).hexdigest()==digest
(OUT/'render.json').write_text(json.dumps(dict(source=str(source),sha256=digest,frames=result),indent=2))
print('FOLLOW_RENDER_OK',len(result),flush=True)
