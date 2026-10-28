"""Paint projection prototype on the real armature, separate from source art.
Run with background Blender. Uses frozen v9 motion, v10's eight-state set.
"""
import bpy,math,json,sys,warnings
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).resolve().parent
warnings.filterwarnings('ignore',category=DeprecationWarning)
src=OUT.parent/'v9-motion-correction/build_clips.py'
g={'__file__':str(src),'__name__':'paint_base'}
exec(compile(src.read_text().split('rest={')[0],str(src),'exec'),g)
rig=g['rig'];root=g['root'];pose=g['pose'];scene=g['scene'];cam=scene.camera
registration=json.loads((OUT/'registration.json').read_text())
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
scene.view_settings.exposure=0;scene.view_settings.gamma=1
for obj in bpy.data.objects:
 if obj.name.startswith('Eye.'):obj.hide_render=True
head_parts=[o for o in bpy.data.objects if o.name in ['Hood volume','Hood collar','Face','Muzzle','Nose'] or o.name.startswith(('Ear.','Eye.'))]
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o not in head_parts]
for obj in head_parts:obj.hide_render=True
def head_card(direction):
 old=bpy.data.objects.get('Painted head card')
 if old:bpy.data.objects.remove(old,do_unlink=True)
 dg=bpy.context.evaluated_depsgraph_get();points=[]
 for obj in head_parts:
  ev=obj.evaluated_get(dg)
  for v in ev.data.vertices:
   q=world_to_camera_view(scene,cam,ev.matrix_world@v.co);points.append((q.x*448,(1-q.y)*448))
 x0=min(p[0] for p in points);x1=max(p[0] for p in points);y0=min(p[1] for p in points);y1=max(p[1] for p in points)
 image=bpy.data.images.load(str(OUT/'source'/('head-'+direction+'.png')),check_existing=True)
 h=y1-y0;w=h*image.size[0]/image.size[1];cx=(x0+x1)/2
 right=cam.matrix_world.to_quaternion()@Vector((1,0,0));up=cam.matrix_world.to_quaternion()@Vector((0,1,0));forward=cam.matrix_world.to_quaternion()@Vector((0,0,-1))
 center=rig.matrix_world@Vector((0,0,1.2));depth=(center-cam.location).dot(forward)-.05
 inv=rig.matrix_world.inverted();vertices=[]
 for x,y in [(cx-w/2,y1),(cx+w/2,y1),(cx+w/2,y0),(cx-w/2,y0)]:
  world=cam.location+forward*depth+right*((x/448-.5)*cam.data.ortho_scale)+up*((.5-y/448)*cam.data.ortho_scale)
  vertices.append(inv@world)
 mesh=bpy.data.meshes.new('Painted head mesh');mesh.from_pydata(vertices,[],[(0,1,2,3)]);mesh.update();obj=bpy.data.objects.new('Painted head card',mesh);scene.collection.objects.link(obj);obj.parent=rig
 vg=obj.vertex_groups.new(name='head');vg.add([0,1,2,3],1,'REPLACE');mod=obj.modifiers.new('Head bone','ARMATURE');mod.object=rig
 uv=mesh.uv_layers.new(name='Head');
 for li,xy in enumerate([(0,0),(1,0),(1,1),(0,1)]):uv.data[li].uv=xy
 mat=bpy.data.materials.new('Head paint '+direction);mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();l=mat.node_tree.links
 out=n.new('ShaderNodeOutputMaterial');em=n.new('ShaderNodeEmission');tex=n.new('ShaderNodeTexImage');tex.image=image;tex.extension='CLIP';l.new(tex.outputs['Color'],em.inputs['Color'])
 trans=n.new('ShaderNodeBsdfTransparent');mix=n.new('ShaderNodeMixShader');l.new(tex.outputs['Alpha'],mix.inputs[0]);l.new(trans.outputs[0],mix.inputs[1]);l.new(em.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],out.inputs['Surface']);obj.data.materials.append(mat)
def base(name):
 if name in ['Hood volume','Hood collar','Tunic body','Pelvis'] or name.startswith(('upper_arm','Joint upper_arm','thigh','Joint thigh')):rgb=(.33,.40,.14)
 elif name.startswith('Tail'):rgb=(.96,.86,.65) if name.endswith('2') else (.85,.28,.045)
 elif name=='Muzzle':rgb=(.95,.83,.56)
 elif name=='Face' or name.startswith('Ear'):rgb=(.95,.34,.04)
 elif name=='Nose':rgb=(.035,.02,.015)
 elif name.startswith('Tiny lockpick'):rgb=(.38,.42,.48)
 else:rgb=(.39,.18,.08)
 return tuple(v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in rgb)+(1,)
def projection(direction):
 old=bpy.data.objects.get('Painted head card')
 if old:bpy.data.objects.remove(old,do_unlink=True)
 root.rotation_euler.z=math.radians(g['DIRS'][direction]);pose('idle',0)
 reg=registration[direction];image=bpy.data.images.load(str(OUT/reg['file']),check_existing=True)
 dg=bpy.context.evaluated_depsgraph_get()
 for obj in meshes:
  ev=obj.evaluated_get(dg)
  uv=obj.data.uv_layers.get('PaintProjection') or obj.data.uv_layers.new(name='PaintProjection')
  attr=obj.data.color_attributes.get('PaintVisibility') or obj.data.color_attributes.new(name='PaintVisibility',type='FLOAT_COLOR',domain='CORNER')
  weights={v.index:[] for v in obj.data.vertices}
  toward_camera=cam.matrix_world.to_quaternion()@Vector((0,0,1))
  for poly in obj.data.polygons:
   points=[ev.matrix_world@ev.data.vertices[idx].co for idx in poly.vertices];center=sum(points,Vector())/len(points)
   hit,loc,normal,idx,hit_obj,matrix=scene.ray_cast(dg,center+toward_camera*10,-toward_camera,distance=10.05)
   visible=1.0 if hit and hit_obj.original==obj and (loc-center).length<.025 else 0.0
   for idx in poly.vertices:weights[idx].append(visible)
   for li in poly.loop_indices:
    idx=obj.data.loops[li].vertex_index;p=ev.matrix_world@ev.data.vertices[idx].co;q=world_to_camera_view(scene,cam,p)
    uv.data[li].uv=((q.x*448*reg['scale']+reg['dx'])/reg['size'],1-((1-q.y)*448*reg['scale']+reg['dy'])/reg['size'])
  for li,loop in enumerate(obj.data.loops):
   ws=weights[loop.vertex_index];visible=sum(ws)/len(ws)
   attr.data[li].color=(visible,visible,visible,1)
  mat=bpy.data.materials.new('Paint '+direction+' '+obj.name);mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();l=mat.node_tree.links
  out=n.new('ShaderNodeOutputMaterial');em=n.new('ShaderNodeEmission');l.new(em.outputs[0],out.inputs['Surface'])
  tex=n.new('ShaderNodeTexImage');tex.image=image;tex.extension='CLIP';tex.interpolation='Linear'
  coords=n.new('ShaderNodeUVMap');coords.uv_map='PaintProjection';l.new(coords.outputs[0],tex.inputs['Vector'])
  attribute=n.new('ShaderNodeVertexColor');attribute.layer_name='PaintVisibility';mul=n.new('ShaderNodeMath');mul.operation='MULTIPLY';l.new(attribute.outputs['Color'],mul.inputs[0]);l.new(tex.outputs['Alpha'],mul.inputs[1])
  mix=n.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[1].default_value=base(obj.name);l.new(mul.outputs[0],mix.inputs[0]);l.new(tex.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],em.inputs['Color'])
  if obj.name.startswith('Tiny lockpick'):em.inputs['Color'].default_value=base(obj.name);l.remove(em.inputs['Color'].links[0])
  obj.data.materials.clear();obj.data.materials.append(mat)
scene.render.resolution_x=448;scene.render.resolution_y=448
complete='--full' in sys.argv
clips={k:v.copy() for k,v in g['CLIPS'].items() if k!='death'};clips['dead'].pop('reuse',None)
manifest={'canvas':224,'anchor':[112,180],'nominalDensity':160,'modelToCell':.4,'directions':g['DIRS'],'clips':clips,'scope':'Painted review: projected body skin, head cards, four fixed generated corpse sprites. No falling animation.'}
for d in g['DIRS']:
 projection(d);head_card(d)
 card=bpy.data.objects['Painted head card'];tex=next(n for n in card.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE')
 neutral=tex.image;hurt=bpy.data.images.load(str(OUT/'source'/('head-hurt-'+d+'.png')),check_existing=True)
 jobs=[]
 if complete:
  for state,c in clips.items():
   if state=='dead':continue
   folder=OUT/'renders'/d/state;folder.mkdir(parents=True,exist_ok=True)
   for i in range(c['source']):jobs.append((state,i/(c['source'] if c['loop'] else c['source']-1),folder/f'{i:02d}.png'))
 else:
  jobs=[(state,t,OUT/'renders'/f'test-{d}-{state}.png') for state,t in [('idle',0),('walk',.25),('run',.25),('hurt',.5),('lock-door',.25),('lock-chest',.25)]]
 for state,t,file in jobs:
  pose(state,t);tex.image=hurt if state=='hurt' and .05<t<.95 else neutral
  scene.render.filepath=str(file);bpy.ops.render.render(write_still=True)
 print('PAINTED_DIRECTION',d,len(jobs),flush=True)
 if d=='se':
  pose('idle',0);tex.image=neutral;bpy.context.preferences.filepaths.save_version=0
  for im in bpy.data.images:
   if im.source=='FILE':im.pack()
  bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-painted-rig.blend'))
(OUT/'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print('PAINTED_PROJECTION_REVIEW_COMPLETE',flush=True)
