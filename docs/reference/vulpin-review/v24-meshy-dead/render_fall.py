"""Ten held Meshy fall poses, four cameras; final frame reused as the corpse."""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from bpy_extras.object_utils import world_to_camera_view

OUT = Path(__file__).parent
SOURCE = OUT.parent / 'source' / 'Meshy_AI_Character_output.glb'
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
    # safe_joint clamps one millimetre inside the reachable range; mathutils
    # stores vectors in float32, so allow its rounding at that boundary.
    assert abs(l1-l2) + .0009 < d < l1+l2-.0009, ('unreachable wrist',d,l1,l2)
    direction = delta/d
    a = (l1*l1-l2*l2+d*d)/(2*d)
    h = math.sqrt(l1*l1-a*a)
    perpendicular = (pole-direction*direction.dot(pole)).normalized()
    return root+direction*a+perpendicular*h

LABELS=['Debout','Jambes qui cèdent','Descente','Genoux au sol','Appui sur les genoux','Bras vers l’avant','Bascule','Réception','Corps au sol','Mort']
# User selected the former 2x as normal speed. Same held poses, 550 ms total.
TIMING=[40,45,45,45,50,50,50,50,70,105]
PITCH=[0,8,16,20,24,36,50,64,74,78]
HIP_Z=[.419883,.355,.29,.255,.24,.22,.20,.18,.16,.15]
HIP_Y=[-.189258,-.20,-.215,-.23,-.24,-.255,-.27,-.29,-.31,-.32]

def safe_joint(root,target,l1,l2,pole):
    delta=target-root
    distance=min(max(delta.length,abs(l1-l2)+.001),l1+l2-.001)
    target=root+delta.normalized()*distance
    return elbow_between(root,target,l1,l2,pole),target

def palm_down(name,head,reference,sign):
    # Match a full basis, not just the finger direction: shortest-arc aim
    # otherwise leaves the palm edge vertical and fingers below the floor.
    old_y=(H[reference]-H[name]).normalized()
    old_z=(Vector((0,-1,0))-old_y*old_y.dot(Vector((0,-1,0)))).normalized()
    old_x=old_y.cross(old_z).normalized()
    new_y=Vector((sign*.15,-1,0)).normalized();new_z=Vector((0,0,1))
    new_x=new_y.cross(new_z).normalized()
    old_basis=Matrix((old_x,old_y,old_z)).transposed()
    new_basis=Matrix((new_x,new_y,new_z)).transposed()
    set_world(name,head,(new_basis@old_basis.inverted()).to_quaternion())

def pose_fall(i):
    arm.location=(0,0,0)
    for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    body=rot((1,0,0),PITCH[i])
    pivot=H['Bone_000'];hip=Vector((pivot.x,HIP_Y[i],HIP_Z[i]))
    def point(p):return hip+body@(p-pivot)
    set_world('Bone_000',hip,body)
    # The chest bends independently of the pelvis. This lets the belly settle
    # while the neck accommodates the large hood, instead of raising the
    # entire body on the hands like a push-up.
    chest_pitch=PITCH[i]-[0,0,0,0,0,0,1,3,5,6][i]
    chest_head=arm.matrix_world@arm.pose.bones['Bone_004'].head
    set_world('Bone_004',chest_head,rot((1,0,0),chest_pitch))
    upper_heads={n:(arm.matrix_world@arm.pose.bones[n].head).copy() for n in ['Bone_026','Bone_031','Bone_021']}
    joints={}
    for side,names in {'R':('Bone_009','Bone_008','Bone_007'),'L':('Bone_014','Bone_013','Bone_012')}.items():
        thigh,shin,foot=names;sign=1 if side=='L' else -1
        top=point(H[thigh]);l1=(H[shin]-H[thigh]).length;l2=(H[foot]-H[shin]).length
        if i<3:
            ankle=H[foot]+Vector((sign*.02,-.075 if side=='L' else .075,0))
            knee,ankle=safe_joint(top,ankle,l1,l2,Vector((0,-1,0)))
            foot_q=rot((1,0,0),0)
        else:
            # Knees receive the body first; shins trail behind, then unfold
            # as the hip tips forward. Different legs avoid bilateral rigidity.
            thigh_pitch=[-25,-10,8,35,62,75,82][i-3]+(3 if side=='R' else -3)
            shin_pitch=[102,108,108,104,98,94,90][i-3]
            q1=rot((1,0,0),thigh_pitch)@rot((0,1,0),-sign*5)
            q2=rot((1,0,0),shin_pitch)@rot((0,0,1),sign*4)
            knee=top+q1@(H[shin]-H[thigh])
            ankle=knee+q2@(H[foot]-H[shin])
            foot_q=rot((1,0,0),[125,130,130,128,125,122,120][i-3])
        aim(thigh,top,knee,H[shin]);aim(shin,knee,ankle,H[foot]);set_world(foot,ankle,foot_q)
        joints['knee_'+side]=list(knee);joints['ankle_'+side]=list(ankle)
    reach=[0,.03,.12,.22,.35,.50,.70,.88,.97,1][i]
    for side,names in {'R':('Bone_026','Bone_025','Bone_024'),'L':('Bone_031','Bone_030','Bone_029')}.items():
        upper,lower,wrist=names;sign=1 if side=='L' else -1
        shoulder=upper_heads[upper]
        neutral=point(Vector((sign*.325,-.24,.49)))
        stretch=shoulder+Vector((sign*.13,-.31,-.05))
        end=neutral.lerp(stretch,reach)
        elbow,end=safe_joint(shoulder,end,(H[lower]-H[upper]).length,(H[wrist]-H[lower]).length,Vector((sign*.7,.2,-.3)))
        aim(upper,shoulder,elbow,H[lower]);aim(lower,elbow,end,H[wrist])
        hand='Bone_028' if side=='L' else 'Bone_023'
        hand_direction=(body@Vector((sign*.01,-.05,-.075))).lerp(Vector((sign*.01,-.09,-.005)),reach)
        aim(wrist,end,end+hand_direction,H[hand])
        joints['wrist_'+side]=list(end)
    head_pitch=PITCH[i]+[0,3,5,6,8,7,2,0,0,0][i]
    head_turn=[0,0,0,0,0,0,-8,-28,-58,-78][i]
    set_world('Bone_021',upper_heads['Bone_021'],rot((1,0,0),head_pitch)@rot((0,0,1),head_turn))
    # The original tail curls upward in standing local space. Flatten it in
    # world space progressively so it lies behind the body in the final pose.
    tail_blend=[0,0,0,.05,.15,.3,.5,.75,.9,1][i]
    names=['Bone_019','Bone_018','Bone_017','Bone_016','Bone_015']
    for j,name in enumerate(names[:-1]):
        current=arm.matrix_world@arm.pose.bones[name].head
        next_name=names[j+1]
        original=point(H[next_name])-point(H[name])
        flat=Vector(([.12,.10,-.025,-.025][j],[.18,.24,.27,.02][j],[-.13,-.035,0,0][j])).normalized()*original.length
        direction=original.lerp(flat,tail_blend).normalized()*original.length
        aim(name,current,current+direction,H[next_name])
    bpy.context.view_layer.update()
    points=vertices()
    correction=-min(p.z for p in points)
    # During the reception the palms go to the floor beside the head. Target
    # in the already grounded body's coordinates, then solve the two links;
    # simply keeping shoulder-relative hands would leave them in mid-air.
    palm_weight=[0,0,0,0,0,.15,.4,.7,.95,1][i]
    if palm_weight:
        for side,names in {'R':('Bone_026','Bone_025','Bone_024'),'L':('Bone_031','Bone_030','Bone_029')}.items():
            upper,lower,wrist=names;sign=1 if side=='L' else -1
            shoulder=upper_heads[upper]
            # Reach along the fall direction, rather than spread the hands
            # laterally into a push-up support stance.
            floor_target=Vector((sign*.30,shoulder.y-.285,.095-correction))
            end=Vector(joints['wrist_'+side]).lerp(floor_target,palm_weight)
            elbow,end=safe_joint(shoulder,end,(H[lower]-H[upper]).length,(H[wrist]-H[lower]).length,Vector((sign,0,.1)))
            aim(upper,shoulder,elbow,H[lower]);aim(lower,elbow,end,H[wrist])
            hand='Bone_028' if side=='L' else 'Bone_023'
            palm_down(wrist,end,hand,sign)
            joints['wrist_'+side]=list(end)
        points=vertices();correction=-min(p.z for p in points)
    arm.location.z=correction
    bpy.context.view_layer.update();points=vertices()
    for key,value in joints.items():value[2]+=correction
    assert all(math.isfinite(c) for p in points for c in p)
    assert abs(min(p.z for p in points))<1e-6
    groups={g.index:g.name for g in mesh.vertex_groups}
    samples={}
    for label,bones in {'head':['Bone_021'],'body':['Bone_004','Bone_001'], 'knees':['Bone_008','Bone_013'], 'hands':['Bone_024','Bone_029']+[f'Bone_{n:03d}' for n in range(33,57)]}.items():
        ids=[v.index for v in mesh.data.vertices if v.groups and groups[max(v.groups,key=lambda g:g.weight).group] in bones]
        samples[label]=min(points[k].z for k in ids)
    return {'index':i,'label':LABELS[i],'pitch':PITCH[i],'hip':list(hip+Vector((0,0,correction))),
            'bounds':[[min(p[k] for p in points) for k in range(3)],[max(p[k] for p in points) for k in range(3)]],
            'minimum_z':min(p.z for p in points),'finite':True,'ground_correction':correction,
            'floor_samples':samples,'joints':joints,'vertices_within_2cm_of_floor':sum(p.z<.02 for p in points)}
scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=768;scene.render.resolution_y=768;scene.render.resolution_percentage=100
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
cam_data=bpy.data.cameras.new('IsometricSpriteCamera');cam_data.type='ORTHO';cam_data.ortho_scale=3.525
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
    return [p.x*768,(1-p.y)*768]

pilot='--pilot' in sys.argv
report={'source_sha256':SOURCE_HASH,'poses':[],'frame_count':10,'views':{},'camera_scale':3.525,
        'canvas':768,'hero_scale':.85,'durations_ms':TIMING,'material_policy':'Original GLB mesh and paint unchanged.',
        'limits':'No facial animation or automatic self-collision proof. New pose awaits artistic feedback.'}
for i in range(10):
    scene.frame_set(i+1)
    report['poses'].append(pose_fall(i))
    for b in arm.pose.bones:
        b.keyframe_insert('location',frame=i+1);b.keyframe_insert('rotation_quaternion',frame=i+1);b.keyframe_insert('scale',frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
if arm.animation_data and arm.animation_data.action:
    arm.animation_data.action.name='Knees_Then_Prone_10_Held_Poses'
    for layer in arm.animation_data.action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
# Lower camera target, preserving focal angle and pixel density, leaves room
# for the prone silhouette below the ground root. Registration records it.
target=root+Vector((0,0,.46))
for view in VIEWS:report['views'][view]={'anchor_px':set_camera(view),'camera_vector':VIEWS[view]}
for view in (['se','nw'] if pilot else VIEWS):
    set_camera(view);(OUT/'masters'/view).mkdir(parents=True,exist_ok=True)
    for i in ([9] if '--final-only' in sys.argv else ([3,6,9] if pilot else range(10))):
        scene.frame_set(i+1)
        scene.render.filepath=str(OUT/'masters'/view/f'fall-{i:02d}.png')
        bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
(OUT/'poses.json').write_text(json.dumps(report,indent=2),encoding='utf8')
set_camera('se');scene.frame_set(10);scene.frame_start=1;scene.frame_end=10
if not pilot:
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-fall-poses.blend'))
print('FALL_POSES_OK',[(p['index'],p['hip'][2],p['floor_samples']) for p in report['poses']])
