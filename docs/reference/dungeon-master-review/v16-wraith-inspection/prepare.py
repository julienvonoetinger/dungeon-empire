"""Preserve the supplied rigged Wraith and derive a dedicated inspection script."""
from pathlib import Path
import hashlib, json, shutil, struct

out = Path(__file__).resolve().parent
source = out / 'source'
source.mkdir(exist_ok=True)
original = Path('C:/Users/A/Downloads/Meshy_AI_Violet_Wraith_20261104_character.glb')
blob = original.read_bytes()
dst = source / 'wraith-original.glb'
if dst.exists():
    assert dst.read_bytes() == blob
else:
    shutil.copy2(original, dst)
length, kind = struct.unpack_from('<II', blob, 12)
assert kind == 0x4e4f534a
gltf = json.loads(blob[20:20 + length])
entry = dict(id='wraith', original=str(original), file=dst.name, bytes=len(blob), sha256=hashlib.sha256(blob).hexdigest(), skins=len(gltf.get('skins', [])), joints=[len(s['joints']) for s in gltf.get('skins', [])], animations=[a.get('name', '') for a in gltf.get('animations', [])])
(source / 'provenance.json').write_text(json.dumps(dict(files=[entry]), indent=2), encoding='utf-8')
(out / 'gltf.json').write_text(json.dumps(gltf, indent=2), encoding='utf-8')
template = (out.parent / 'v12-model-inspection/inspect.py').read_text(encoding='utf-8')
template = template.replace("SOURCE=OUT.parent/'source'", "SOURCE=OUT/'source'")
template = template.replace("meshes=[o for o in scene.objects if o.type=='MESH']", "custom_shapes={b.custom_shape for rig in scene.objects if rig.type=='ARMATURE' for b in rig.pose.bones if b.custom_shape}\n    meshes=[o for o in scene.objects if o.type=='MESH' and o not in custom_shapes]")
template = template.replace("views=[('front',(0,-1,0)),('left',(-1,0,0)),('back',(0,1,0)),('iso',(1,-1,.65))]", "views=[('front',(0,-1,0)),('left',(-1,0,0)),('back',(0,1,0)),('iso',(1,-1,.65))]")
probe = '''
    report['rigs'] = []
    def evaluated_points():
        deps = bpy.context.evaluated_depsgraph_get()
        result = []
        for obj in meshes:
            ev = obj.evaluated_get(deps)
            mesh = ev.to_mesh()
            result.extend(ev.matrix_world @ v.co for v in mesh.vertices)
            ev.to_mesh_clear()
        return result
    base = evaluated_points()
    for rig in [o for o in scene.objects if o.type == 'ARMATURE']:
        bones = []
        for bone in rig.pose.bones:
            weights = sum(1 for obj in meshes for v in obj.data.vertices if any(obj.vertex_groups[g.group].name == bone.name and g.weight > .00001 for g in v.groups))
            old = bone.matrix_basis.copy()
            from mathutils import Matrix
            bone.matrix_basis = old @ Matrix.Rotation(math.radians(8), 4, 'X')
            bpy.context.view_layer.update()
            moved = evaluated_points()
            displacement = max((a-b).length for a,b in zip(base,moved))
            assert math.isfinite(displacement)
            bone.matrix_basis = old
            bpy.context.view_layer.update()
            restored = evaluated_points()
            error = max((a-b).length for a,b in zip(base,restored))
            assert error < .00001
            bones.append(dict(name=bone.name, parent=bone.parent.name if bone.parent else None, head=list(rig.matrix_world @ bone.head), tail=list(rig.matrix_world @ bone.tail), weighted_vertices=weights, probe_max_displacement=displacement, restore_error=error))
        report['rigs'].append(dict(name=rig.name, bones=bones))
    report['unweighted_vertices'] = sum(1 for obj in meshes for v in obj.data.vertices if not any(g.weight > .00001 for g in v.groups))
    report['probe_note'] = 'Each bone receives a temporary 8 degree local X rotation then restores; this checks deformation response, not anatomical suitability or animation quality.'
'''
template = template.replace('    camera=setup(scene,center,size)', probe + '\n    camera=setup(scene,center,size)')
(out / 'inspect.py').write_text(template, encoding='utf-8')
print(json.dumps(entry, indent=2))
