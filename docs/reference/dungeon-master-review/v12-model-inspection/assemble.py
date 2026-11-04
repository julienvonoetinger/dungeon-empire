"""Static placement proposal: original meshes/materials, two independent roots."""
import bpy, math, json, hashlib, struct
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pathlib import Path

OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'eye-inspection.blend'))
scene=bpy.context.scene
eye_meshes=[o for o in scene.objects if o.type=='MESH']

def points(objects): return [o.matrix_world@v.co for o in objects for v in o.data.vertices]
def centre(objects):
    ps=points(objects)
    return Vector([(min(p[i] for p in ps)+max(p[i] for p in ps))*.5 for i in range(3)])
def group(name,objects):
    root=bpy.data.objects.new(name,None);scene.collection.objects.link(root)
    root.location=centre(objects);bpy.context.view_layer.update()
    for obj in objects:
        world=obj.matrix_world.copy();obj.parent=root;obj.matrix_world=world
    root.location=(0,0,0);bpy.context.view_layer.update()
    return root
def fingerprint(objects):
    h=hashlib.sha256()
    for obj in objects:
        for v in obj.data.vertices: h.update(struct.pack('<3f',*v.co))
        for p in obj.data.polygons: h.update(struct.pack('<'+'I'*len(p.vertices),*p.vertices))
        for uv in obj.data.uv_layers:
            for v in uv.data: h.update(struct.pack('<2f',*v.uv))
    return h.hexdigest()
def tree(obj):
    return BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],
        [list(p.vertices) for p in obj.data.polygons],all_triangles=False,epsilon=0.0)

eye_hash=fingerprint(eye_meshes)
eye_root=group('Eye_Control',eye_meshes)
before=set(scene.objects)
bpy.ops.import_scene.gltf(filepath=str(SOURCE/'volute-original.glb'))
volute_meshes=[o for o in scene.objects if o not in before and o.type=='MESH']
volute_hash=fingerprint(volute_meshes)
volute_root=group('Volute_Control',volute_meshes)
volute_root.scale=(2.4,)*3
volute_root.location.x=-0.30
volute_root.location.z=0.35
volute_root.rotation_euler=(math.radians(18),math.radians(-20),math.radians(8))
eye_tree=tree(eye_meshes[0])
trials=[]
for depth in [0,.15,.3,.45,.6,.75,.9,1.05,1.2,1.35,1.5,1.65,1.8]:
    volute_root.location.y=depth;bpy.context.view_layer.update()
    overlaps=len(eye_tree.overlap(tree(volute_meshes[0])))
    trials.append(dict(depth=depth,bvh_surface_candidates=overlaps))
    if overlaps==0: break
assert overlaps==0
assert fingerprint(eye_meshes)==eye_hash and fingerprint(volute_meshes)==volute_hash

# Fit all actual geometry, with the same framing in both views.
ps=points(eye_meshes+volute_meshes)
target=centre(eye_meshes+volute_meshes)
views=[('assembly-front',(0,-1,0)),('assembly-iso',(1,-1,.55)),('assembly-side',(1,-.3,.2))]
extent=0
for name,direction in views:
    basis=(-Vector(direction)).to_track_quat('-Z','Y').to_matrix().transposed()
    extent=max(extent,max(abs((basis@(p-target))[i]) for p in ps for i in (0,1))*2)
scene.camera.data.ortho_scale=extent*1.15
for name,direction in views:
    scene.camera.location=target+Vector(direction).normalized()*12
    scene.camera.rotation_euler=(target-scene.camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'master-assembly.blend'),compress=True)
report=dict(status='static placement proposal; original source materials',
    eye_geometry_uv_sha256=eye_hash,volute_geometry_uv_sha256=volute_hash,
    eye_root=eye_root.name,volute_root=volute_root.name,volute_scale=list(volute_root.scale),
    volute_rotation=list(volute_root.rotation_euler),volute_position=list(volute_root.location),
    placement_trials=trials,remaining_bvh_surface_candidates=overlaps,
    images=[dict(name=i.name,size=list(i.size),packed=bool(i.packed_file)) for i in bpy.data.images],
    limitations='No rig, deformation, animation or full-volume/continuous collision validation. Surface BVH placement check only.')
(OUT/'assembly.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
for entry in json.loads((SOURCE/'provenance.json').read_text())['files']:
    assert hashlib.sha256((SOURCE/entry['file']).read_bytes()).hexdigest()==entry['sha256']
print('STATIC_ASSEMBLY_OK',json.dumps(dict(depth=depth,surface_candidates=overlaps)),flush=True)
