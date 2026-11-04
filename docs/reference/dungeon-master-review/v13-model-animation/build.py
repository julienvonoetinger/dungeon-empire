"""Bake a reversible object-control animation of the supplied Meshy models."""
import bpy,math,json,hashlib,struct
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree

OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'
REPO=OUT.parents[3]
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'v12-model-inspection/master-assembly.blend'))
scene=bpy.context.scene
eye=bpy.data.objects['Eye_Control'];volute=bpy.data.objects['Volute_Control']
eye_mesh=next(o for o in eye.children if o.type=='MESH')
volute_mesh=next(o for o in volute.children if o.type=='MESH')
source_info=json.loads((OUT.parent/'v12-model-inspection/inspection.json').read_text())['models']

def fingerprint(obj):
    h=hashlib.sha256()
    for v in obj.data.vertices:h.update(struct.pack('<3f',*v.co))
    for p in obj.data.polygons:h.update(struct.pack('<'+'I'*len(p.vertices),*p.vertices))
    for uv in obj.data.uv_layers:
        for v in uv.data:h.update(struct.pack('<2f',*v.uv))
    return h.hexdigest()
def smooth(a,b,t):
    x=max(0.,min(1.,(t-a)/(b-a)))
    return x*x*(3.-2.*x)
def check_sources():
    assert fingerprint(eye_mesh)==source_info[0]['geometry_uv_sha256']
    assert fingerprint(volute_mesh)==source_info[1]['geometry_uv_sha256']
    for entry in json.loads((SOURCE/'provenance.json').read_text())['files']:
        assert hashlib.sha256((SOURCE/entry['file']).read_bytes()).hexdigest()==entry['sha256']
check_sources()
base=volute.matrix_world.copy()
eye_radius=max((eye_mesh.matrix_world@v.co).length for v in eye_mesh.data.vertices)
volute_points=[volute_mesh.matrix_world@v.co for v in volute_mesh.data.vertices]
tree=BVHTree.FromPolygons(volute_points,[list(p.vertices) for p in volute_mesh.data.polygons],all_triangles=False)
nearest=tree.find_nearest(Vector((0,0,0)))
assert nearest[0] is not None
inner_radius=nearest[0].length
# Radius is invariant under every global rotation. Use a margin beyond the
# largest eye scale, not a frame-only test of two particular silhouettes.
safety=max(1.,(eye_radius*1.012+0.14)/inner_radius)
scene.render.fps=30;scene.frame_start=0;scene.frame_end=540
records=[]
eye.rotation_mode='QUATERNION';volute.rotation_mode='QUATERNION'
for frame in range(541):
    t=frame/30.
    eye_growth=smooth(3.,8.,t)
    eye_scale=max(.0001,eye_growth*(1.+.012*math.sin(max(0,t-8)*.65)**2))
    if t<2.5: deployment=max(.0001,1.16*smooth(0,2.5,t))
    else: deployment=1.16-.16*smooth(2.5,8,t)+.018*math.sin(max(0,t-8)*.7)**2
    angle=-math.radians(130)+1.75*math.tau*(1-math.exp(-t/4.0))
    tilt=Matrix.Rotation(.23*math.sin(t*.35),4,'X')@Matrix.Rotation(.12*math.sin(t*.31),4,'Z')
    desired=Matrix.Rotation(angle,4,'Y')@tilt@Matrix.Scale(safety*deployment,4)@base
    location,rotation,scale=desired.decompose()
    volute.location=location;volute.rotation_quaternion=rotation;volute.scale=scale
    eye.location=(0,0,0)
    gaze=smooth(6,10,t)
    eye.rotation_quaternion=(Matrix.Rotation(.07*math.sin((t-8)*.35)*gaze,4,'Z')@
        Matrix.Rotation(.035*math.sin((t-8)*.6)*gaze,4,'X')).to_quaternion()
    eye.scale=(eye_scale,)*3
    for obj in [eye,volute]:
        for channel in ['location','rotation_quaternion','scale']:obj.keyframe_insert(channel,frame=frame)
    gap=inner_radius*safety*deployment-eye_radius*eye_scale
    if t>=3:assert gap>=.1399,(t,gap)
    records.append(dict(time=t,eye_scale=eye_scale,volute_scale=deployment,
        angle=angle,conservative_gap=gap))

# Dense linear transform samples avoid Bezier overshoot of the safe radii.
for obj in [eye,volute]:
    action=obj.animation_data.action
    action.name=obj.name+'_Invocation'
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for point in curve.keyframe_points:point.interpolation='LINEAR'

scene.frame_set(300)
check_sources()
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'master-animated.blend'),compress=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in [eye,volute,eye_mesh,volute_mesh]:obj.select_set(True)
bpy.context.view_layer.objects.active=eye
target=REPO/'assets/previews/master-meshy/master-invocation.glb'
target.parent.mkdir(parents=True,exist_ok=True)
properties=bpy.ops.export_scene.gltf.get_rna_type().properties
options=dict(filepath=str(target),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='SCENE',export_frame_range=True,
    export_force_sampling=True,export_frame_step=1,export_materials='EXPORT')
if 'export_nla_strips_merged_animation_name' in properties:options['export_nla_strips_merged_animation_name']='Invocation'
if 'export_anim_scene_split_object' in properties:options['export_anim_scene_split_object']=False
bpy.ops.export_scene.gltf(**options)
check_sources()
data=target.read_bytes();length=struct.unpack_from('<I',data,12)[0];gltf=json.loads(data[20:20+length])
assert len(gltf.get('animations',[]))==1,gltf.get('animations')
report=dict(duration=18,fps=30,frames=541,eye_radius=eye_radius,volute_inner_radius=inner_radius,
    safety_scale=safety,minimum_gap_after_eye_appears=min(r['conservative_gap'] for r in records if r['time']>=3),
    animation_names=[a.get('name') for a in gltf['animations']],
    export_sha256=hashlib.sha256(data).hexdigest(),bytes=len(data),motion=records,
    scope='Object-control rig: growth, gaze, orbit and settlement. No skeletal eyelid deformation.',
    limitation='Conservative source-surface radial clearance; export interpolation checked separately.')
(OUT/'animation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('MASTER_ANIMATION_BUILT',json.dumps({k:v for k,v in report.items() if k!='motion'}),flush=True)
