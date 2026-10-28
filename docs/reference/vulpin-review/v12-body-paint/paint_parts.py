import bpy,math,json,sys,warnings
import shutil
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
warnings.filterwarnings('ignore',category=DeprecationWarning)
OUT=Path(__file__).resolve().parent;OLD=OUT.parent/'v11-painted-sprites'
src=OUT.parent/'v9-motion-correction/build_clips.py';g={'__file__':str(src),'__name__':'body_parts'};exec(compile(src.read_text().split('rest={')[0],str(src),'exec'),g)
rig=g['rig'];root=g['root'];pose=g['pose'];scene=g['scene'];cam=scene.camera
scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=0;scene.view_settings.gamma=1
head_parts=[o for o in bpy.data.objects if o.name in ['Hood volume','Hood collar','Face','Muzzle','Nose'] or o.name.startswith(('Ear.','Eye.'))]
for o in bpy.data.objects:
 if o.type=='MESH':o.hide_render=True
# Reuse the unchanged head painting and fitting, not the rejected body projection.
head_code=(OLD/'paint_rig.py').read_text().split('def head_card(direction):')[1].split('def base(')[0]
exec('def head_card(direction):'+head_code.replace("OUT/'source'","OLD/'source'"),globals())
data=json.loads((OUT/'parts.json').read_text())
complete='--full' in sys.argv
manifest=json.loads((OLD/'source-manifest.json').read_text())
manifest['scope']='Painted cutout parts animated by the same rig; unchanged head artwork and static death. Review only.'
for o in g['tools']:
 mat=bpy.data.materials.new('Steel lockpick');mat.diffuse_color=(.42,.46,.51,1);o.data.materials.clear();o.data.materials.append(mat)
cards=[]
def part_card(d,p):
 image=bpy.data.images.load(str(OUT/p['paintFile']),check_existing=True);b=p['bounds'];h=b[3]-b[1];w=b[2]-b[0];scale=(w/image.size[0] if p['name'].startswith('foot') else h/image.size[1]);w=image.size[0]*scale;h=image.size[1]*scale;cx=(b[0]+b[2])/2;cy=(b[1]+b[3])/2
 right=cam.matrix_world.to_quaternion()@Vector((1,0,0));up=cam.matrix_world.to_quaternion()@Vector((0,1,0));forward=cam.matrix_world.to_quaternion()@Vector((0,0,-1));depth=(Vector(p['worldCenter'])-cam.location).dot(forward)
 inv=rig.matrix_world.inverted();deform=rig.pose.bones[p['bone']].matrix@rig.data.bones[p['bone']].matrix_local.inverted();vertices=[]
 for x,y in [(cx-w/2,cy+h/2),(cx+w/2,cy+h/2),(cx+w/2,cy-h/2),(cx-w/2,cy-h/2)]:
  world=cam.location+forward*depth+right*((x/448-.5)*cam.data.ortho_scale)+up*((.5-y/448)*cam.data.ortho_scale);vertices.append(deform.inverted()@inv@world)
 mesh=bpy.data.meshes.new('Paint '+p['name']);mesh.from_pydata(vertices,[],[(0,1,2,3)]);mesh.update();obj=bpy.data.objects.new('Paint '+p['name'],mesh);scene.collection.objects.link(obj);obj.parent=rig
 vg=obj.vertex_groups.new(name=p['bone']);vg.add([0,1,2,3],1,'REPLACE');mod=obj.modifiers.new('Skeleton','ARMATURE');mod.object=rig;uv=mesh.uv_layers.new(name='Paint')
 for li,xy in enumerate([(0,0),(1,0),(1,1),(0,1)]):uv.data[li].uv=xy
 mat=bpy.data.materials.new('Paint '+d+' '+p['name']);mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();l=mat.node_tree.links;out=n.new('ShaderNodeOutputMaterial');em=n.new('ShaderNodeEmission');tex=n.new('ShaderNodeTexImage');tex.image=image;tex.extension='CLIP';l.new(tex.outputs['Color'],em.inputs['Color']);trans=n.new('ShaderNodeBsdfTransparent');mix=n.new('ShaderNodeMixShader');l.new(tex.outputs['Alpha'],mix.inputs[0]);l.new(trans.outputs[0],mix.inputs[1]);l.new(em.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],out.inputs['Surface']);obj.data.materials.append(mat);cards.append(obj)
for d,parts in data.items():
 for o in cards:bpy.data.objects.remove(o,do_unlink=True)
 cards.clear();root.rotation_euler.z=math.radians(g['DIRS'][d]);pose('idle',0)
 for p in parts:part_card(d,p)
 head_card(d);tex=next(n for n in bpy.data.objects['Painted head card'].data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE');neutral=tex.image;hurt=bpy.data.images.load(str(OLD/'source'/('head-hurt-'+d+'.png')),check_existing=True)
 jobs=[]
 if complete:
  for state,c in manifest['clips'].items():
   folder=OUT/'renders'/d/state;folder.mkdir(parents=True,exist_ok=True)
   if state=='dead':shutil.copy2(OLD/'renders'/d/'dead/00.png',folder/'00.png');continue
   for i in range(c['source']):jobs.append((state,i/(c['source'] if c['loop'] else c['source']-1),folder/f'{i:02d}.png'))
 else:jobs=[(state,t,OUT/'renders'/f'test-{d}-{state}.png') for state,t in [('idle',0),('walk',.25),('run',.25),('hurt',.5),('lock-door',.25),('lock-chest',.25)]]
 for state,t,file in jobs:
  pose(state,t);tex.image=hurt if state=='hurt' and .05<t<.95 else neutral;scene.render.filepath=str(file);bpy.ops.render.render(write_still=True)
 print('BODY_PAINT_DIRECTION',d,len(jobs),flush=True)
(OUT/'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print('PART_PAINT_SAMPLES_COMPLETE',flush=True)

