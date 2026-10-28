import bpy, json, math, hashlib
from pathlib import Path
from mathutils import Vector

SOURCE = Path(__file__).resolve().parent.parent / 'source' / 'Meshy_AI_Character_output.glb'
OUT = Path(__file__).parent
OUT.mkdir(parents=True, exist_ok=True)
source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.read_factory_settings(use_empty=True)
result = bpy.ops.import_scene.gltf(filepath=str(SOURCE))
all_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
# glTF importer can create a hidden Icosphere as a custom bone display shape;
# it is not part of the character and must not affect camera framing.
meshes = [o for o in all_meshes if any(m.type == 'ARMATURE' for m in o.modifiers)]
arms = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE']
def xyz(v): return [round(float(x),6) for x in v]
report = {'source': str(SOURCE), 'source_sha256': source_hash,
          'bytes': SOURCE.stat().st_size, 'blender': bpy.app.version_string,
          'import_result': sorted(result), 'meshes': [], 'armatures': [],
          'images': [], 'actions': [a.name for a in bpy.data.actions],
          'excluded_display_helpers': [o.name for o in all_meshes if o not in meshes]}
for o in meshes:
    weights = {g.index: {'name': g.name, 'weighted_vertices': 0, 'total_weight': 0.0} for g in o.vertex_groups}
    unweighted = 0
    for v in o.data.vertices:
        total = sum(g.weight for g in v.groups)
        if total < .00001: unweighted += 1
        for g in v.groups:
            if g.weight > .00001:
                weights[g.group]['weighted_vertices'] += 1
                weights[g.group]['total_weight'] += g.weight
    o.data.calc_loop_triangles()
    report['meshes'].append({'name': o.name, 'vertices': len(o.data.vertices),
       'triangles': len(o.data.loop_triangles), 'uv_layers': len(o.data.uv_layers),
       'unweighted_vertices': unweighted,
       'modifiers': [{'type': m.type, 'target': m.object.name if m.type == 'ARMATURE' and m.object else None} for m in o.modifiers],
       'groups': list(weights.values())})
for a in arms:
    report['armatures'].append({'name': a.name, 'bone_count': len(a.data.bones),
       'constraints': sum(len(p.constraints) for p in a.pose.bones),
       'bones': [{'name': b.name, 'parent': b.parent.name if b.parent else None,
                  'head': xyz(a.matrix_world @ b.head_local), 'tail': xyz(a.matrix_world @ b.tail_local),
                  'deform': b.use_deform} for b in a.data.bones]})
for im in bpy.data.images:
    report['images'].append({'name': im.name, 'size': list(im.size), 'packed': bool(im.packed_file),
                            'has_data': im.has_data, 'colorspace': im.colorspace_settings.name})

# Small isolated bone rotation verifies that a weighted bone actually deforms
# geometry after import. This is a connectivity check, not animation approval.
def positions(o):
    dg = bpy.context.evaluated_depsgraph_get()
    eo = o.evaluated_get(dg)
    em = eo.to_mesh()
    points = [v.co.copy() for v in em.vertices]
    eo.to_mesh_clear()
    return points
if arms and meshes:
    a, o = arms[0], meshes[0]
    candidates = sorted(report['meshes'][0]['groups'], key=lambda g:g['weighted_vertices'], reverse=True)
    candidate = next((g['name'] for g in candidates if g['name'] in a.pose.bones and a.pose.bones[g['name']].parent), None)
    if candidate:
        before = positions(o)
        pb = a.pose.bones[candidate]
        saved = pb.matrix_basis.copy()
        pb.rotation_mode = 'XYZ'
        pb.rotation_euler.x += math.radians(5)
        bpy.context.view_layer.update()
        after = positions(o)
        distances = [(p-q).length for p,q in zip(before,after)]
        pb.matrix_basis = saved
        bpy.context.view_layer.update()
        restored = positions(o)
        report['deformation_probe'] = {'bone': candidate, 'angle_degrees': 5,
          'changed_vertices': sum(d > 1e-6 for d in distances), 'max_displacement': max(distances),
          'restore_max_error': max((p-q).length for p,q in zip(before,restored)),
          'scope': 'Connectivity only; no gait or joint-quality validation.'}

points = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
lo = Vector(tuple(min(v[i] for v in points) for i in range(3)))
hi = Vector(tuple(max(v[i] for v in points) for i in range(3)))
center = (lo+hi)/2
report['bounds'] = {'min':xyz(lo),'max':xyz(hi),'size':xyz(hi-lo)}
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = 768
scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.film_transparent = True
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
world = bpy.data.worlds.new('InspectionWorld')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (.55,.58,.65,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = .65
scene.world = world
scale = max(hi-lo)
for name,pos,power,size in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
    light = bpy.data.lights.new(name,'AREA'); light.energy = power*scale*scale; light.shape = 'DISK'; light.size = size*scale
    obj=bpy.data.objects.new(name,light); scene.collection.objects.link(obj)
    obj.location=center+Vector(pos)*scale
    obj.rotation_euler=(center-obj.location).to_track_quat('-Z','Y').to_euler()
camera_data=bpy.data.cameras.new('InspectionCamera');camera_data.type='ORTHO'
camera=bpy.data.objects.new('InspectionCamera',camera_data);scene.collection.objects.link(camera);scene.camera=camera
report['renders']=[]
for name,direction in [('front',(0,-1,0)),('isometric',(1,-1,math.sqrt(2/3)))]:
    camera.location=center+Vector(direction).normalized()*scale*5
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    inv=camera.rotation_euler.to_matrix().transposed()
    projected=[inv@(v-center) for v in points]
    extent=max(max(v[i] for v in projected)-min(v[i] for v in projected) for i in (0,1))
    camera_data.ortho_scale=extent*1.14
    scene.render.filepath=str(OUT/(name+'.png'))
    bpy.ops.render.render(write_still=True)
    report['renders'].append({'file':name+'.png','direction':direction,'ortho_scale':camera_data.ortho_scale})
report['source_unchanged']=hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_hash
(OUT/'inspection.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('INSPECTION_OK', json.dumps({'armatures':len(arms),'meshes':len(meshes),'actions':report['actions'],'bounds':report['bounds'],'source_unchanged':report['source_unchanged']}))
