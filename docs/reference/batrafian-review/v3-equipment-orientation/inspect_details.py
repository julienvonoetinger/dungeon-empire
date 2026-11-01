"""Native close-ups of actual fitted equipment, without repainting or compositing."""
import bpy, json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'batrafian-equipped-review.blend'))
s=bpy.context.scene;c=s.camera
s.render.resolution_x=768;s.render.resolution_y=768;s.cycles.samples=40
fit=json.loads((OUT/'equipment-fit.json').read_text())
target=Vector(fit['attachments']['bow_output_unwrapped']['target'])
for name,direction in [('grip-outer',(1,-1,.15)),('grip-inner',(-1,-1,.20))]:
    c.location=target+Vector(direction).normalized()*5
    c.rotation_euler=(target-c.location).to_track_quat('-Z','Y').to_euler();c.data.ortho_scale=.48
    bpy.context.view_layer.update();s.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
target=Vector((-.14,.3,1.02))
c.location=target+Vector((-1,1,.45)).normalized()*5
c.rotation_euler=(target-c.location).to_track_quat('-Z','Y').to_euler();c.data.ortho_scale=1.35
bpy.context.view_layer.update();s.render.filepath=str(OUT/'quiver-back.png');bpy.ops.render.render(write_still=True)
print('DETAILS_OK')
