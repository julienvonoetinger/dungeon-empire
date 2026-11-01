"""Inspect immutable user GLBs in a separate background Blender process."""
import bpy, json, math, hashlib
from pathlib import Path
from mathutils import Vector

OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'
PROVENANCE=json.loads((SOURCE/'provenance.json').read_text(encoding='utf8'))
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
report={'blender':bpy.app.version_string,'sources':{},'limits':'Rig probes check connectivity and exact restoration, not animation quality or full collision-free range.'}
groups={}
def xyz(v): return [round(float(x),6) for x in v]
def vertices(o):
    e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=e.to_mesh()
    result=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear();return result
def bounds(meshes):
    p=[v for o in meshes for v in vertices(o)]
    lo=Vector([min(v[i] for v in p)for i in range(3)]);hi=Vector([max(v[i]for v in p)for i in range(3)])
    return lo,hi,p
for entry in PROVENANCE['files']:
    name=entry['file'].split('-')[0];source=SOURCE/entry['file']
    assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256']
    old=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(source));objects=[o for o in bpy.data.objects if o not in old]
    arms=[o for o in objects if o.type=='ARMATURE']
    meshes=[o for o in objects if o.type=='MESH' and (any(m.type=='ARMATURE' for m in o.modifiers) if arms else not o.hide_render)]
    for o in objects:o.name=name+'_'+o.name
    groups[name]={'objects':objects,'meshes':meshes,'armatures':arms}
    lo,hi,p= bounds(meshes)
    r={'file':entry['file'],'sha256':entry['sha256'],'bytes':entry['bytes'],'bounds':{'min':xyz(lo),'max':xyz(hi),'size':xyz(hi-lo)},'meshes':[],'armatures':[],'deformation_probes':[]}
    for o in meshes:
        o.data.calc_loop_triangles()
        weights={g.index:{'bone':g.name,'vertices':0,'sum':0.0}for g in o.vertex_groups};unweighted=0
        for v in o.data.vertices:
            if sum(g.weight for g in v.groups)<1e-5:unweighted+=1
            for g in v.groups:
                if g.weight>1e-5:weights[g.group]['vertices']+=1;weights[g.group]['sum']+=g.weight
        r['meshes'].append({'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'uv_layers':len(o.data.uv_layers),'unweighted_vertices':unweighted if arms else None,'weights':list(weights.values()),'materials':[m.name if m else None for m in o.data.materials]})
    for arm in arms:
        r['armatures'].append({'name':arm.name,'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':xyz(arm.matrix_world@b.head_local),'tail':xyz(arm.matrix_world@b.tail_local),'deform':b.use_deform}for b in arm.data.bones]})
        mesh=meshes[0];before=vertices(mesh)
        # Probe all weighted non-root bones independently and restore each one.
        for group in r['meshes'][0]['weights']:
            if not group['vertices'] or group['bone'] not in arm.pose.bones:continue
            pb=arm.pose.bones[group['bone']]
            if not pb.parent:continue
            saved=pb.matrix_basis.copy();mode=pb.rotation_mode
            pb.rotation_mode='XYZ';pb.rotation_euler.x+=math.radians(5);bpy.context.view_layer.update()
            after=vertices(mesh);d=[(a-b).length for a,b in zip(after,before)]
            pb.matrix_basis=saved;pb.rotation_mode=mode;bpy.context.view_layer.update();restored=vertices(mesh)
            err=max((a-b).length for a,b in zip(restored,before))
            assert err<1e-5,'Restoration failed: '+pb.name
            assert max(d)>1e-6,'No mesh deformation: '+pb.name
            r['deformation_probes'].append({'bone':pb.name,'changed_vertices':sum(x>1e-6 for x in d),'max_displacement':max(d),'restoration_max_error':err})
    report['sources'][name]=r
    for o in objects:o.hide_render=True
report['actions']=[a.name for a in bpy.data.actions]
report['images']=[{'name':i.name,'size':list(i.size),'packed':bool(i.packed_file),'has_data':i.has_data}for i in bpy.data.images]
(OUT/'inspection.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')

scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=768;scene.render.resolution_y=768;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
world=bpy.data.worlds.new('InspectionWorld');world.use_nodes=True
background=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
background.inputs['Color'].default_value=(.55,.58,.65,1);background.inputs['Strength'].default_value=.65;scene.world=world
camera_data=bpy.data.cameras.new('InspectionCamera');camera_data.type='ORTHO'
camera=bpy.data.objects.new('InspectionCamera',camera_data);scene.collection.objects.link(camera);scene.camera=camera
lights=[]
for name,pos,power,size in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
    data=bpy.data.lights.new(name,'AREA');data.shape='DISK'
    o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);lights.append((o,Vector(pos),power,size))
for name,group in groups.items():
    for o in group['meshes']:o.hide_render=False
    lo,hi,points=bounds(group['meshes']);center=(lo+hi)*.5;scale=max(hi-lo)
    for o,pos,power,size in lights:
        o.location=center+pos*scale;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler();o.data.energy=power*scale*scale;o.data.size=size*scale
    views=[('front',(0,-1,0)),('isometric',(1,-1,math.sqrt(2/3)))] if name=='paladin' else [('isometric',(1,-1,math.sqrt(2/3)))]
    for view,direction in views:
        camera.location=center+Vector(direction).normalized()*scale*5;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
        inv=camera.rotation_euler.to_matrix().transposed();projected=[inv@(p-center)for p in points]
        extent=max(max(v[i]for v in projected)-min(v[i]for v in projected)for i in (0,1));camera_data.ortho_scale=extent*1.15
        scene.render.filepath=str(OUT/(name+'-'+view+'.png'));bpy.ops.render.render(write_still=True)
    for o in group['meshes']:o.hide_render=True
for o in groups['paladin']['meshes']:o.hide_render=False
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'inspection.blend'),compress=True)
for entry in PROVENANCE['files']:assert hashlib.sha256((SOURCE/entry['file']).read_bytes()).hexdigest()==entry['sha256']
print('INSPECTION_OK',json.dumps({name:{'bounds':r['bounds'],'bones':sum(len(a['bones'])for a in r['armatures']),'probes':len(r['deformation_probes'])}for name,r in report['sources'].items()}))
