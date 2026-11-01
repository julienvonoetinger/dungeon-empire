import bpy,math,json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'paladin-equipped-review.blend'))
s=bpy.context.scene;c=s.camera
body=next(o for o in s.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE'for m in o.modifiers))
hammer=next(o for o in s.objects if o.name.startswith('hammer_') and o.type=='MESH')
shield=next(o for o in s.objects if o.name.startswith('shield_') and o.type=='MESH')
body.hide_render=True;hammer.hide_render=True
center=shield.matrix_world.translation
c.data.ortho_scale=1.5
for label,d in [('shield-source-back',(0,1,0)),('shield-source-rear-side',(1,1,.4))]:
    c.location=center+Vector(d).normalized()*5;c.rotation_euler=(center-c.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(OUT/(label+'.png'));bpy.ops.render.render(write_still=True)
body.hide_render=False;hammer.hide_render=False
grips=json.loads((OUT/'equipment-fit.json').read_text())['grips']
for label,side,d in [('hammer-grip','R',(-1,-1,.5)),('shield-grip','L',(1,1,.6))]:
    center=Vector(grips[side]);c.data.ortho_scale=.64
    c.location=center+Vector(d).normalized()*5;c.rotation_euler=(center-c.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(OUT/(label+'.png'));bpy.ops.render.render(write_still=True)
print('GRIP_INSPECTION_OK')
