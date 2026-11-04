"""Six-second skeletal levitation study; preserve the supplied Meshy painting/mesh."""
from pathlib import Path
import bpy, math, json, hashlib, struct
from mathutils import Vector, Quaternion

OUT = Path(__file__).resolve().parent
REPO = OUT.parents[3]
PREVIOUS = OUT.parent / 'v16-wraith-inspection'
bpy.ops.wm.open_mainfile(filepath=str(PREVIOUS / 'wraith-inspection.blend'))
scene = bpy.context.scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
body = bpy.data.objects['output_unwrapped']
source = PREVIOUS / 'source/wraith-original.glb'
expected = json.loads((PREVIOUS / 'source/provenance.json').read_text())['files'][0]['sha256']
assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
def fingerprint():
    h = hashlib.sha256()
    for v in body.data.vertices:
        h.update(struct.pack('<3f', *v.co))
        for g in v.groups: h.update(struct.pack('<If', g.group, g.weight))
    for p in body.data.polygons: h.update(struct.pack('<'+'I'*len(p.vertices), *p.vertices))
    for uv in body.data.uv_layers:
        for v in uv.data: h.update(struct.pack('<2f', *v.uv))
    return h.hexdigest()
original_fingerprint = fingerprint()
rest_location = rig.location.copy()
scene.render.fps = 30
scene.frame_start = 0
scene.frame_end = 180
for bone in rig.pose.bones:
    bone.rotation_mode = 'QUATERNION'
    bone.rotation_quaternion = Quaternion()
def rotate(name, axis, degrees):
    bone = rig.pose.bones[name]
    local_axis = bone.bone.matrix_local.to_3x3().inverted() @ Vector(axis)
    bone.rotation_quaternion = Quaternion(local_axis.normalized(), math.radians(degrees))
tail = ['Bone_011','Bone_010','Bone_009','Bone_008','Bone_007','Bone_006','Bone_005']
for frame in range(181):
    phase = math.tau * frame / 180
    rig.location = rest_location + Vector((.012*math.sin(phase), 0, .055*math.sin(phase*2)))
    rig.keyframe_insert('location', frame=frame)
    rotate('Bone_004', (0,1,0), 2.0*math.sin(phase))
    rotate('Bone_003', (1,0,0), 1.8*math.sin(phase*2-.4))
    rotate('Bone_014', (0,0,1), 7*math.sin(phase-.3))
    rotate('Bone_013', (1,0,0), 2.2*math.sin(phase*2-.6))
    for index,name in enumerate(tail):
        rotate(name, (0,1,0), (3+index*.65)*math.sin(phase-index*.48))
    # Both sides lift, with a slight temporal offset; forearms counterrotate.
    for side,offset,names in [(1,0,['Bone_018','Bone_017','Bone_016']),(-1,.45,['Bone_023','Bone_022','Bone_021'])]:
        rotate(names[0],(0,1,0),side*5*math.sin(phase+offset))
        rotate(names[1],(0,0,1),side*3*math.sin(phase+offset-.5))
        rotate(names[2],(0,1,0),-side*3*math.sin(phase+offset-.7))
    for index,name in enumerate(['Bone_033','Bone_032','Bone_031']):
        rotate(name,(0,1,0),2*math.sin(phase-index*.5))
    for bone in rig.pose.bones: bone.keyframe_insert('rotation_quaternion',frame=frame)
rig.animation_data.action.name = 'Levitation'
for layer in rig.animation_data.action.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for curve in bag.fcurves:
                for key in curve.keyframe_points: key.interpolation = 'LINEAR'

def evaluated():
    deps = bpy.context.evaluated_depsgraph_get()
    obj = body.evaluated_get(deps)
    mesh = obj.to_mesh()
    points = [obj.matrix_world @ v.co for v in mesh.vertices]
    obj.to_mesh_clear()
    return points
scene.frame_set(0)
first = evaluated()
extent = []
peak_change = 0
for frame in range(181):
    scene.frame_set(frame)
    points = evaluated()
    assert all(math.isfinite(c) for p in points for c in p)
    peak_change = max(peak_change, max((a-b).length for a,b in zip(first,points)))
    extent.extend(points[::8])
scene.frame_set(180)
loop_error = max((a-b).length for a,b in zip(first,evaluated()))
assert loop_error < .00001 and peak_change > .08, (loop_error, peak_change)
assert fingerprint() == original_fingerprint
scene.frame_set(0)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'wraith-levitation.blend'),compress=True)
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True); body.select_set(True)
bpy.context.view_layer.objects.active = rig
target = REPO/'assets/previews/wraith-master/wraith-levitation.glb'
target.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='SCENE',export_anim_scene_split_object=False,
    export_frame_range=True,export_force_sampling=True,export_frame_step=1,export_materials='EXPORT')
assert fingerprint() == original_fingerprint
assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
report = dict(duration=6,fps=30,frames=181,loop_error=loop_error,peak_vertex_change=peak_change,
    preserved_geometry_uv_weights=original_fingerprint,source_sha256=expected,
    source_unchanged=True,tail_chain=tail,export_bytes=target.stat().st_size,
    export_sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
    limitations='Low-amplitude skeletal study. No facial morphs, no full self-collision proof, no sanctuary integration.')
(OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('WRAITH_ANIMATION_OK',json.dumps(report))
