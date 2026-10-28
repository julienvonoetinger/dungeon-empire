import bpy,json,math
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).resolve().parent
src=OUT.parent/'v9-motion-correction/build_clips.py';g={'__file__':str(src),'__name__':'body_guide'};exec(compile(src.read_text().split('rest={')[0],str(src),'exec'),g)
scene=g['scene'];rig=g['rig'];root=g['root'];cam=scene.camera
PARTS=[('body','chest',['Tunic body','Pelvis','Hip pouch']),('upper-L','upper_arm.L',['upper_arm.L','Joint upper_arm.L']),('upper-R','upper_arm.R',['upper_arm.R','Joint upper_arm.R']),('hand-L','forearm.L',['forearm.L','Joint forearm.L','Empty glove.L']),('hand-R','forearm.R',['forearm.R','Joint forearm.R','Empty glove.R']),('tail','tail.0',['Tail join 0','Tail join 1','Tail volume 0','Tail volume 1','Tail volume 2']),('thigh-L','thigh.L',['thigh.L','Joint thigh.L']),('shin-L','shin.L',['shin.L','Joint shin.L']),('foot-L','foot.L',['Flat boot.L']),('thigh-R','thigh.R',['thigh.R','Joint thigh.R']),('shin-R','shin.R',['shin.R','Joint shin.R']),('foot-R','foot.R',['Flat boot.R'])]
meshes=[o for o in bpy.data.objects if o.type=='MESH'];data={}
for d,angle in g['DIRS'].items():
 root.rotation_euler.z=math.radians(angle);g['pose']('idle',0);dg=bpy.context.evaluated_depsgraph_get();data[d]=[]
 for name,bone,names in PARTS:
  points=[];worlds=[]
  for o in meshes:
   o.hide_render=o.name not in names
   if o.name in names:
    ev=o.evaluated_get(dg)
    for v in ev.data.vertices:
     world=ev.matrix_world@v.co;q=world_to_camera_view(scene,cam,world);points.append((q.x*448,(1-q.y)*448));worlds.append(world)
  xs=[p[0] for p in points];ys=[p[1] for p in points];center=sum(worlds,Vector())/len(worlds)
  data[d].append({'name':name,'bone':bone,'objects':names,'bounds':[min(xs),min(ys),max(xs),max(ys)],'worldCenter':list(center)})
  scene.render.filepath=str(OUT/'guides'/f'{d}-{name}.png');bpy.ops.render.render(write_still=True)
(OUT/'guide-geometry.json').write_text(json.dumps(data,indent=2));print('GUIDES_COMPLETE',flush=True)
