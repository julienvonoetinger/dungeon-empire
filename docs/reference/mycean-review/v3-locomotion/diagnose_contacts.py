"""Print collision heights in the saved pilot to locate problematic geometry."""
import bpy,sys,json
from collections import Counter
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from mesh_checks import geometry,crossings
bpy.ops.wm.open_mainfile(filepath=str(OUT/'mycean-gait-poses.blend'))
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
for f in (9,10,12,16):
 bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
 p,t=geometry(body);s,st=geometry(staff)
 hits=crossings(p,t,s,st,True)|crossings(s,st,p,t,True)
 print('CONTACT_HEIGHTS',f,len(hits),dict(Counter(round(h[2],1) for h in hits)))
