"""Reload the saved assembly and verify preservation against imported sources."""
import bpy,json,hashlib,struct
from pathlib import Path
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'
expected=json.loads((OUT/'inspection.json').read_text())['models']
bpy.ops.wm.open_mainfile(filepath=str(OUT/'master-assembly.blend'))
def fingerprint(objects):
    h=hashlib.sha256()
    for o in objects:
        for v in o.data.vertices:h.update(struct.pack('<3f',*v.co))
        for p in o.data.polygons:h.update(struct.pack('<'+'I'*len(p.vertices),*p.vertices))
        for uv in o.data.uv_layers:
            for v in uv.data:h.update(struct.pack('<2f',*v.uv))
    return h.hexdigest()
meshes=[]
for entry,root_name in zip(expected,['Eye_Control','Volute_Control']):
    root=bpy.data.objects[root_name]
    children=[o for o in root.children if o.type=='MESH']
    assert len(children)==1
    assert fingerprint(children)==entry['geometry_uv_sha256']
    assert not children[0].data.shape_keys
    meshes.extend(children)
assert len([o for o in bpy.context.scene.objects if o.type=='MESH'])==2
assert not [o for o in bpy.context.scene.objects if o.type=='ARMATURE']
packed=[i for i in bpy.data.images if i.packed_file]
assert len(packed)==6
for image in packed:
    # Blender loads packed pixels lazily after opening a blend.
    assert list(image.size)==[2048,2048]
    assert len(image.pixels)==2048*2048*4
    assert 0.0<=image.pixels[0]<=1.0
    assert image.has_data
trees=[BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],
    [list(p.vertices) for p in o.data.polygons],all_triangles=False) for o in meshes]
assert len(trees[0].overlap(trees[1]))==0
for entry in json.loads((SOURCE/'provenance.json').read_text())['files']:
    assert hashlib.sha256((SOURCE/entry['file']).read_bytes()).hexdigest()==entry['sha256']
print('PACKED_ASSEMBLY_VERIFIED: 2 independent roots, source geometry/UVs, 6 packed images, original GLB hashes, no BVH surface candidates',flush=True)
