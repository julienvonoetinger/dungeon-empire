"""One posed Meshy corpse, four cameras. No fall or generated in-between frames."""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from bpy_extras.object_utils import world_to_camera_view

OUT = Path(__file__).parent
SOURCE = Path(r'C:/Users/A/Downloads/Meshy_AI_Character_output.glb')
SOURCE_HASH = '035f4d448e60fefd99b5eb9c8a7f2ddd55405802dcc060018d0c9595d848e2b4'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_HASH
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == 'ARMATURE')
mesh = next(o for o in scene.objects if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers))
R = {b.name: (arm.matrix_world @ b.matrix_local).copy() for b in arm.data.bones}
H = {b.name: arm.matrix_world @ b.head_local for b in arm.data.bones}
AI = arm.matrix_world.inverted()
for bone in arm.pose.bones:
    bone.rotation_mode = 'QUATERNION'

def rot(axis, degrees):
    return Quaternion(axis, math.radians(degrees))

def set_world(name, head, rotation):
    m = rotation.to_matrix().to_4x4() @ R[name]
    m.translation = head
    arm.pose.bones[name].matrix = AI @ m
    bpy.context.view_layer.update()

def aim(name, head, end, rest_end):
    q = (rest_end - H[name]).normalized().rotation_difference((end - head).normalized())
    set_world(name, head, q)

def vertices():
    obj = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    me = obj.to_mesh()
    points = [obj.matrix_world @ v.co for v in me.vertices]
    obj.to_mesh_clear()
    return points

def elbow_between(root, target, l1, l2, pole):
    delta = target - root
    d = delta.length
    assert abs(l1-l2) + .001 < d < l1+l2-.001, ('unreachable wrist',d,l1,l2)
    direction = delta/d
    a = (l1*l1-l2*l2+d*d)/(2*d)
    h = math.sqrt(l1*l1-a*a)
    perpendicular = (pole-direction*direction.dot(pole)).normalized()
    return root+direction*a+perpendicular*h

def pose_dead():
    # A side/front resting pose, articulated before any grounding correction.
    # Hip below head accommodates the large hood without balancing on an ear.
    body = rot((1,0,0),82) @ rot((0,0,1),-72)
    pivot = H['Bone_000']
    def point(p): return pivot + body @ (p-pivot)
    set_world('Bone_000',pivot,body)
    lengths=[]
    for side,names in {'R':('Bone_009','Bone_008','Bone_007'), 'L':('Bone_014','Bone_013','Bone_012')}.items():
        thigh,shin,foot=names
        hip=point(H[thigh])
        ankle=hip+Vector((.12,.17,.09) if side=='L' else (.10,.20,-.04))
        knee=elbow_between(hip,ankle,(H[shin]-H[thigh]).length,(H[foot]-H[shin]).length,Vector((-.2,-1,.1)))
        aim(thigh,hip,knee,H[shin]);aim(shin,knee,ankle,H[foot])
        set_world(foot,ankle,rot((1,0,0),85) @ rot((0,0,1),-35 if side=='L' else -20))
        lengths.append({'side':side,'thigh_error':abs((knee-hip).length-(H[shin]-H[thigh]).length),
                        'shin_error':abs((ankle-knee).length-(H[foot]-H[shin]).length)})
    hands={'L':Vector((.20,-.45,.83)), 'R':Vector((-.20,-.40,.67))}
    for side,names in {'R':('Bone_026','Bone_025','Bone_024'),'L':('Bone_031','Bone_030','Bone_029')}.items():
        upper,lower,wrist=names
        shoulder=point(H[upper]);end=point(hands[side]);sign=1 if side=='L' else -1
        elbow=elbow_between(shoulder,end,(H[lower]-H[upper]).length,(H[wrist]-H[lower]).length,body@Vector((sign*.6,.4,-.3)))
        aim(upper,shoulder,elbow,H[lower]);aim(lower,elbow,end,H[wrist])
        reference='Bone_028' if side=='L' else 'Bone_023'
        aim(wrist,end,end+body@Vector((sign*.025,-.04,-.06)),H[reference])
    # Lower face is turned towards the floor; no invented facial rig or repaint.
    set_world('Bone_021',point(H['Bone_021']),body @ rot((0,0,1),20))
    # Let the tail rest alongside the body instead of retaining its upright arch.
    tail=arm.pose.bones['Bone_019']
    tail.rotation_quaternion=rot((1,0,0),-25)
    bpy.context.view_layer.update()
    points=vertices()
    # Ground the whole silhouette, not standing boot masks. One rigid correction
    # preserves the relative posed anatomy and all original bone lengths.
    arm.location.z -= min(p.z for p in points)
    bpy.context.view_layer.update()
    points=vertices()
    assert all(math.isfinite(c) for p in points for c in p)
    assert abs(min(p.z for p in points))<1e-6
    # Keep footprint around the shared logical root rather than offsetting a
    # prone body by a standing torso's height along the grid.
    centre=Vector(((min(p.x for p in points)+max(p.x for p in points))/2,
                   (min(p.y for p in points)+max(p.y for p in points))/2,0))
    arm.location += Vector((0,-.20,0))-centre
    bpy.context.view_layer.update()
    points=vertices()
    return {'bounds':[[min(v[i] for v in points) for i in range(3)],
                      [max(v[i] for v in points) for i in range(3)]],
            'minimum_z':min(p.z for p in points),'finite':True,'length_checks':lengths,
            'vertices_within_2cm_of_floor':sum(p.z<.02 for p in points),
            'armature_location':list(arm.location),
            'resting_pose':'Asymmetric folded legs, relaxed arms, face angled down.'}

pose = pose_dead()
scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
world=bpy.data.worlds.new('DeadStudio');world.use_nodes=True;scene.world=world
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.55,.58,.65,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
lights=[]
for name,pos,power,size in [('Key',(-2,-3,4),520,5.1),('Fill',(3,-1,2),200,5.1),('Rim',(1,3,3),290,3.4)]:
    ld=bpy.data.lights.new(name,'AREA');ld.energy=power;ld.shape='DISK';ld.size=size
    ob=bpy.data.objects.new(name,ld);scene.collection.objects.link(ob)
    ob.location=Vector(pos)*1.7+Vector((0,0,.8));ob.rotation_euler=(Vector((0,0,.8))-ob.location).to_track_quat('-Z','Y').to_euler()
    lights.append((ob,ob.matrix_basis.copy()))
cam_data=bpy.data.cameras.new('IsometricSpriteCamera');cam_data.type='ORTHO';cam_data.ortho_scale=2.35
cam=bpy.data.objects.new('IsometricSpriteCamera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
VIEWS={'se':(-1,-1,math.sqrt(2/3)), 'sw':(1,-1,math.sqrt(2/3)),
       'nw':(1,1,math.sqrt(2/3)), 'ne':(-1,1,math.sqrt(2/3))}
def set_camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    rotation=Matrix.Rotation(math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1),4,'Z')
    for light,base in lights: light.matrix_world=rotation@base
    bpy.context.view_layer.update()
    p=world_to_camera_view(scene,cam,root)
    return [p.x*512,(1-p.y)*512]

pilot='--pilot' in sys.argv
report={'source_sha256':SOURCE_HASH,'pose':pose,'frame_count':1,'views':{},'camera_scale':2.35,
        'canvas':512,'hero_scale':.85,'material_policy':'Original GLB mesh and paint unchanged.',
        'limits':'No facial animation or automatic self-collision proof. New pose awaits artistic feedback.'}
for view in VIEWS: report['views'][view]={'anchor_px':set_camera(view),'camera_vector':VIEWS[view]}
(OUT/'masters').mkdir(exist_ok=True)
for view in (['se','nw'] if pilot else VIEWS):
    set_camera(view)
    scene.render.filepath=str(OUT/'masters'/f'dead-{view}.png')
    bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
(OUT/'pose.json').write_text(json.dumps(report,indent=2),encoding='utf8')
set_camera('se');scene.frame_start=1;scene.frame_end=1
if not pilot:
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-dead-pose.blend'))
print('DEAD_POSE_OK',json.dumps(pose))
