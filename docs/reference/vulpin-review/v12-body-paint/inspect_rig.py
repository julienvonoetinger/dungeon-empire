import bpy,json,math
from pathlib import Path
OUT=Path('C:/Users/A/Documents/GitHub/dungeon-empire/docs/reference/vulpin-review/v12-body-paint')
src=OUT.parent/'v9-motion-correction/build_clips.py';g={'__file__':str(src),'__name__':'body_guide'};exec(compile(src.read_text().split('rest={')[0],str(src),'exec'),g)
print('OBJECTS',json.dumps([(o.name,[v.name for v in o.vertex_groups]) for o in bpy.data.objects if o.type=='MESH']))
