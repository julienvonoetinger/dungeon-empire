"""Read the supplied invoker in an isolated background Blender; preserve source art."""
import bpy, json, math, hashlib
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).parent
SOURCE = OUT.parent / 'source'
entry = json.loads((SOURCE / 'provenance.json').read_text(encoding='utf-8-sig'))['files'][0]
source = SOURCE / entry['file']
assert hashlib.sha256(source.read_bytes()).hexdigest() == entry['sha256']
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
scene = bpy.context.scene
arms = [o for o in scene.objects if o.type == 'ARMATURE']
helpers = [o for o in scene.objects if o.type == 'MESH' and not any(m.type=='ARMATURE' for m in o.modifiers)]
meshes = [o for o in scene.objects if o.type == 'MESH' and o not in helpers]
def xyz(v): return [float(x) for x in v]
def points(obj):
    e = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    m = e.to_mesh()
    p = [e.matrix_world @ v.co for v in m.vertices]
    e.to_mesh_clear()
    return p
allpoints = [p for o in meshes for p in points(o)]
lo = Vector([min(p[i] for p in allpoints) for i in range(3)])
hi = Vector([max(p[i] for p in allpoints) for i in range(3)])
report = {'blender': bpy.app.version_string, 'source': entry, 'bounds': {'min':xyz(lo), 'max':xyz(hi), 'size':xyz(hi-lo)}, 'meshes':[], 'armatures':[], 'probes':[], 'actions':[a.name for a in bpy.data.actions], 'excluded_rig_display_helpers':[o.name for o in helpers]}
for o in meshes:
    o.data.calc_loop_triangles()
    weights = {g.index: {'bone':g.name, 'vertices':0} for g in o.vertex_groups}
    for v in o.data.vertices:
        for g in v.groups:
            if g.weight > 1e-5: weights[g.group]['vertices'] += 1
    report['meshes'].append({'name':o.name, 'vertices':len(o.data.vertices), 'triangles':len(o.data.loop_triangles), 'uv_layers':len(o.data.uv_layers), 'materials':[m.name if m else None for m in o.data.materials], 'unweighted_vertices':sum(sum(g.weight for g in v.groups)<1e-5 for v in o.data.vertices), 'weights':list(weights.values()), 'shape_keys': [k.name for k in o.data.shape_keys.key_blocks] if o.data.shape_keys else []})
for arm in arms:
    report['armatures'].append({'name':arm.name, 'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':xyz(arm.matrix_world@b.head_local),'tail':xyz(arm.matrix_world@b.tail_local)} for b in arm.data.bones]})
    linked = [o for o in meshes if any(m.type=='ARMATURE' and m.object==arm for m in o.modifiers)]
    before = [p for o in linked for p in points(o)]
    weighted = {g.name for o in linked for g in o.vertex_groups if any(any(w.group==g.index and w.weight>1e-5 for w in v.groups) for v in o.data.vertices)}
    for pb in arm.pose.bones:
        if not pb.parent or pb.name not in weighted: continue
        saved = pb.matrix_basis.copy(); mode = pb.rotation_mode
        pb.rotation_mode='XYZ'; pb.rotation_euler.x += math.radians(5)
        bpy.context.view_layer.update()
        after = [p for o in linked for p in points(o)]
        displacement = max((a-b).length for a,b in zip(after,before))
        pb.matrix_basis=saved; pb.rotation_mode=mode; bpy.context.view_layer.update()
        restored = [p for o in linked for p in points(o)]
        error = max((a-b).length for a,b in zip(restored,before))
        assert displacement>1e-6, pb.name+' does not deform'
        assert error<1e-5, pb.name+' did not restore'
        report['probes'].append({'bone':pb.name, 'max_displacement':displacement, 'restoration_error':error})
report['images'] = [{'name':i.name, 'size':list(i.size), 'packed':bool(i.packed_file), 'has_data':i.has_data} for i in bpy.data.images]
report['limits'] = 'Static inspection and isolated five-degree deformation/restoration probes only; not an animation, garment collision, or facial expression validation.'
(OUT/'inspection.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
scene.render.engine='CYCLES'; scene.cycles.samples=16; scene.cycles.use_denoising=True
scene.render.resolution_x=640; scene.render.resolution_y=640; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.image_settings.color_mode='RGBA'; scene.render.film_transparent=True
scene.view_settings.view_transform='Standard'; scene.view_settings.look='None'
world=bpy.data.worlds.new('ReviewWorld'); world.use_nodes=True
world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.55,.58,.65,1)
world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.65; scene.world=world
center=(lo+hi)*.5; size=max(hi-lo)
camera_data=bpy.data.cameras.new('ReviewCamera'); camera_data.type='ORTHO'
camera=bpy.data.objects.new('ReviewCamera',camera_data); scene.collection.objects.link(camera); scene.camera=camera
for name,pos,power,radius in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
    data=bpy.data.lights.new(name,'AREA'); data.shape='DISK'; data.energy=power*size*size; data.size=radius*size
    light=bpy.data.objects.new(name,data); scene.collection.objects.link(light); light.location=center+Vector(pos)*size
    light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
views=[('front',(0,-1,0)),('back',(0,1,0)),('iso-front-right',(1,-1,math.sqrt(2/3))),('iso-front-left',(-1,-1,math.sqrt(2/3))),('iso-back-right',(1,1,math.sqrt(2/3))),('iso-back-left',(-1,1,math.sqrt(2/3)))]
extent=0
for name,direction in views:
    rot=(-Vector(direction)).to_track_quat('-Z','Y').to_matrix().transposed()
    extent=max(extent,max(abs((rot@(p-center))[i]) for p in allpoints for i in (0,1))*2)
camera_data.ortho_scale=extent*1.13
for name,direction in views:
    camera.location=center+Vector(direction).normalized()*size*5
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/(name+'.png')); bpy.ops.render.render(write_still=True)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'invoker-inspection.blend'),compress=True)
assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256']
print('INVOCATEUR_INSPECTION_OK',json.dumps({'bones':sum(len(a.data.bones) for a in arms),'probes':len(report['probes']),'vertices':sum(r['vertices'] for r in report['meshes']),'triangles':sum(r['triangles'] for r in report['meshes'])}))
