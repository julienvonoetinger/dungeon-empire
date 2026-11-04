"""Inspect and render immutable eye/volute sources in a dedicated background Blender."""
import bpy, json, math, hashlib, struct
from pathlib import Path
from mathutils import Vector

OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'
entries=json.loads((SOURCE/'provenance.json').read_text())['files']
reports=[]

def geometry_hash(meshes):
    h=hashlib.sha256()
    for o in meshes:
        for v in o.data.vertices: h.update(struct.pack('<3f',*v.co))
        for p in o.data.polygons: h.update(struct.pack('<'+'I'*len(p.vertices),*p.vertices))
        for uv in o.data.uv_layers:
            for v in uv.data: h.update(struct.pack('<2f',*v.uv))
    return h.hexdigest()

def setup(scene,center,size):
    scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
    scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.render.film_transparent=True;scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
    world=bpy.data.worlds.new('ReviewWorld');world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.55,.58,.65,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.6;scene.world=world
    data=bpy.data.cameras.new('ReviewCamera');data.type='ORTHO'
    camera=bpy.data.objects.new('ReviewCamera',data);scene.collection.objects.link(camera);scene.camera=camera
    for name,pos,power,radius in [('Key',(-2,-3,4),140,3),('Fill',(3,-1,2),60,3),('Rim',(1,3,3),70,2)]:
        data=bpy.data.lights.new(name,'AREA');data.shape='DISK';data.energy=power*size*size;data.size=radius*size
        light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=center+Vector(pos)*size
        light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    return camera

for entry in entries:
    source=SOURCE/entry['file']
    assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    scene=bpy.context.scene
    meshes=[o for o in scene.objects if o.type=='MESH']
    points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    assert points and all(math.isfinite(c) for p in points for c in p)
    lo=Vector([min(p[i] for p in points) for i in range(3)])
    hi=Vector([max(p[i] for p in points) for i in range(3)])
    center=(lo+hi)*.5;size=max(hi-lo)
    fingerprint=geometry_hash(meshes)
    report=dict(id=entry['id'],blender=bpy.app.version_string,source=entry,
        bounds=dict(min=list(lo),max=list(hi),size=list(hi-lo)),geometry_uv_sha256=fingerprint,
        meshes=[],armatures=[o.name for o in scene.objects if o.type=='ARMATURE'],
        actions=[a.name for a in bpy.data.actions],images=[])
    for o in meshes:
        o.data.calc_loop_triangles()
        report['meshes'].append(dict(name=o.name,vertices=len(o.data.vertices),triangles=len(o.data.loop_triangles),
            materials=[m.name for m in o.data.materials],uv_layers=len(o.data.uv_layers),
            shape_keys=[k.name for k in o.data.shape_keys.key_blocks] if o.data.shape_keys else []))
    report['images']=[dict(name=i.name,size=list(i.size),packed=bool(i.packed_file),has_data=i.has_data) for i in bpy.data.images]
    camera=setup(scene,center,size)
    views=[('front',(0,-1,0)),('left',(-1,0,0)),('back',(0,1,0)),('iso',(1,-1,.65))]
    extent=0
    for name,direction in views:
        basis=(-Vector(direction)).to_track_quat('-Z','Y').to_matrix().transposed()
        extent=max(extent,max(abs((basis@(p-center))[i]) for p in points for i in (0,1))*2)
    camera.data.ortho_scale=extent*1.15
    for name,direction in views:
        camera.location=center+Vector(direction).normalized()*size*5
        camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(OUT/(entry['id']+'-'+name+'.png'))
        bpy.ops.render.render(write_still=True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(entry['id']+'-inspection.blend')),compress=True)
    assert geometry_hash(meshes)==fingerprint
    assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256']
    reports.append(report)
    (OUT/'inspection.json').write_text(json.dumps(dict(models=reports),indent=2)+'\n',encoding='utf8')
    print('INSPECTED',entry['id'],json.dumps(report['bounds']),flush=True)
print('MODEL_INSPECTION_OK',flush=True)
