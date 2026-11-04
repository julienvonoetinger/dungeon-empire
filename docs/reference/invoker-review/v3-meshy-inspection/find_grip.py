import bpy,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).parent
ns={"__file__":str(OUT/"verify_equipped.py")};exec((OUT/'verify_equipped.py').read_text().split('bp,bt=geometry(body)')[0],ns)
body,staff=ns['body'],ns['staff'];geo=ns['geometry'];cross=ns['crossings']
for name in ['KeepHandOutsideStaff','ContactSurfaceSampling']:
 if body.modifiers.get(name):body.modifiers[name].show_viewport=False
bpy.context.view_layer.update();bp,bt=geo(body);sp,st=geo(staff)
results=[]
for dx in [-.16,-.12,-.08,-.04,0,.04,.08,.12,.16]:
 for dy in [-.16,-.12,-.08,-.04,0,.04,.08,.12,.16]:
  p=[v+Vector((dx,dy,0))for v in sp]
  hits=cross(p,st,bp,bt)|cross(bp,bt,p,st)
  results.append({'dx':dx,'dy':dy,'crossings':len(hits)})
results.sort(key=lambda r:(r['crossings'],r['dx']**2+r['dy']**2))
(OUT/'grip-search.json').write_text(json.dumps(results,indent=2));print(results[:10])


