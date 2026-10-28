"""Five held hurt poses of the user's real Meshy mesh; no image puppets.

Offline preview only. Original GLB and its material/vertex data stay intact.
"""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from bpy_extras.object_utils import world_to_camera_view

OUT=Path(__file__).parent
SOURCE=Path(r'C:/Users/A/Downloads/Meshy_AI_Character_output.glb')
SOURCE_HASH='035f4d448e60fefd99b5eb9c8a7f2ddd55405802dcc060018d0c9595d848e2b4'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
mesh=next(o for o in scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
for p in arm.pose.bones:p.rotation_mode='QUATERNION'

# Five distinct held poses. Contact stays fixed; only the torso recoils.
# Clip order is impact, maximum recoil, regain support, recover, neutral.
LABELS=['Neutre','Impact','Recul','Reprise appui','Récupération']
BOB=[-.030,-.070,-.105,-.065,-.035]
BACK=[0,.025,.045,.025,.008]
LEAN=[0,-8,-12,-5,-1]
TWIST=[0,-3,-5,-2,0]
HEAD_TUCK=[0,10,18,10,3]
HAND_L=[(.325,-.240,.490),(.310,-.420,.700),(.300,-.460,.760),(.315,-.350,.650),(.325,-.280,.540)]
HAND_R=[(-.325,-.240,.490),(-.330,-.390,.650),(-.310,-.440,.710),(-.325,-.330,.610),(-.325,-.270,.520)]
LEGS={'R':('Bone_009','Bone_008','Bone_007'), 'L':('Bone_014','Bone_013','Bone_012')}
ARMS={'R':('Bone_026','Bone_025','Bone_024'), 'L':('Bone_031','Bone_030','Bone_029')}
ground_masks={side:[v.index for v in mesh.data.vertices if (mesh.matrix_world@v.co).z<.045 and ((mesh.matrix_world@v.co).x>0)==(side=='L')] for side in LEGS}

def set_world(name,head,rotation=None):
    m=R[name].copy()
    if rotation is not None:
        m=rotation.to_matrix().to_4x4()@m
    m.translation=head
    arm.pose.bones[name].matrix=AI@m
    bpy.context.view_layer.update()

def aim(name,head,target,rest_target):
    q=(rest_target-H[name]).normalized().rotation_difference((target-head).normalized())
    set_world(name,head,q)

def solve_joint(root,end,length1,length2,pole):
    delta=end-root;distance=delta.length
    # No stretch: use a tiny bend instead of crossing the singular straight pose.
    if distance>=length1+length2-.001:
        end=root+delta.normalized()*(length1+length2-.001)
        delta=end-root;distance=delta.length
    direction=delta.normalized()
    along=(length1*length1-length2*length2+distance*distance)/(2*distance)
    hfive=math.sqrt(max(0,length1*length1-along*along))
    perpendicular=pole-direction*direction.dot(pole)
    perpendicular.normalize()
    return root+direction*along+perpendicular*hfive,end

def evaluated_vertices():
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=obj.to_mesh()
    p=[obj.matrix_world@v.co for v in me.vertices];obj.to_mesh_clear();return p

def apply_pose(index):
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    shift=Vector((0,BACK[index],BOB[index]))
    lean=Quaternion((0,0,1),math.radians(TWIST[index]))@Quaternion((1,0,0),math.radians(LEAN[index]))
    pivot=H['Bone_000']
    def bodypoint(p):return pivot+lean@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,lean)
    targets={}
    for side,bones in LEGS.items():
        upper,lower,foot=bones
        hip=bodypoint(H[upper])
        # Slightly staggered fixed stance, never translate the feet with recoil.
        ankle=H[foot]+Vector((0,-.045 if side=='L' else .045,0))
        knee,ankle=solve_joint(hip,ankle,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((0,-1,0)))
        aim(upper,hip,knee,H[lower]);aim(lower,knee,ankle,H[foot])
        set_world(foot,ankle)
        targets[side]={'ankle':list(ankle),'grounded':True}
    for side,bones in ARMS.items():
        upper,lower,wrist=bones;sign=1 if side=='L' else -1
        shoulder=bodypoint(H[upper])
        end=bodypoint(Vector((HAND_L if side=='L' else HAND_R)[index]))
        elbow,end=solve_joint(shoulder,end,(H[lower]-H[upper]).length,(H[wrist]-H[lower]).length,Vector((sign*.25,1,-.4)))
        aim(upper,shoulder,elbow,H[lower]);aim(lower,elbow,end,H[wrist])
        hand='Bone_028' if side=='L' else 'Bone_023'
        # Raise the hands to guard the torso without passing them through it.
        direction=Vector((sign*.01,-.05,-.075)) if index==0 else Vector((-sign*.02,-.065,-.035))
        aim(wrist,end,end+direction,H[hand])
    # The model has no facial morphs. Pose the head/hood as a unit at its neck.
    set_world('Bone_021',bodypoint(H['Bone_021']),lean@Quaternion((1,0,0),math.radians(HEAD_TUCK[index])))
    tail=arm.pose.bones['Bone_019']
    tail.rotation_quaternion=Quaternion((1,0,0),math.radians([0,-4,-7,-3,-1][index]))
    bpy.context.view_layer.update()
    p=evaluated_vertices()
    minima={s:min(p[i].z for i in ids) for s,ids in ground_masks.items()}
    support_min=min(minima.values());arm.location.z=-support_min
    bpy.context.view_layer.update();p=evaluated_vertices()
    minima={s:min(p[i].z for i in ids) for s,ids in ground_masks.items()}
    return {'index':index,'label':LABELS[index],'feet':targets,'sole_min_z':minima,
            'ground_correction':-support_min,'mesh_min_z':min(v.z for v in p),
            'finite':all(math.isfinite(c) for v in p for c in v),
            'bounds':[[min(v[i] for v in p) for i in range(3)],[max(v[i] for v in p) for i in range(3)]]}

scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
world=bpy.data.worlds.new('HurtStudio');world.use_nodes=True;scene.world=world
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.55,.58,.65,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
lights=[]
for name,pos,power,size in [('Key',(-2,-3,4),520,5.1),('Fill',(3,-1,2),200,5.1),('Rim',(1,3,3),290,3.4)]:
    ld=bpy.data.lights.new(name,'AREA');ld.energy=power;ld.shape='DISK';ld.size=size
    ob=bpy.data.objects.new(name,ld);scene.collection.objects.link(ob)
    ob.location=Vector(pos)*1.7+Vector((0,0,.8));ob.rotation_euler=(Vector((0,0,.8))-ob.location).to_track_quat('-Z','Y').to_euler()
    lights.append((ob,Matrix.LocRotScale(ob.location.copy(),ob.rotation_euler.to_quaternion(),ob.scale.copy())))
cam_data=bpy.data.cameras.new('IsometricSpriteCamera');cam_data.type='ORTHO';cam_data.ortho_scale=2.35
cam=bpy.data.objects.new('IsometricSpriteCamera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),
       'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
def set_camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    # Rotate the studio with the camera: equivalent to turning the character
    # before a fixed game camera/light setup, rather than relighting the screen.
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    rotation=Matrix.Rotation(angle,4,'Z')
    for light,base_matrix in lights:light.matrix_world=rotation@base_matrix
    bpy.context.view_layer.update()
    q=world_to_camera_view(scene,cam,root)
    return [q.x*512,(1-q.y)*512]

report={'source':str(SOURCE),'source_sha256':SOURCE_HASH,'method':'Five explicit held 3D poses, no in-between generation.',
 'frame_count':5,'duration_seconds':.48,'fps':10,'playback_order':[1,2,3,4,0],'durations_ms':[60,100,120,100,100],'views':{},'poses':[],'material_policy':'Original imported textures and shaders retained.',
 'validation_scope':'Finite geometry and sampled boot-sole contact only; visual review required for rig quality.'}
# Save five held poses so they are inspectable in Blender, without interpolated
# motion. These are keys for the source document, not a hurttime animation rig.
for i in range(5):
    scene.frame_set(i+1)
    report['poses'].append(apply_pose(i))
    for p in arm.pose.bones:
        p.keyframe_insert('location',frame=i+1);p.keyframe_insert('rotation_quaternion',frame=i+1);p.keyframe_insert('scale',frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
if arm.animation_data and arm.animation_data.action:
    action=arm.animation_data.action;action.name='Hurt_5_Held_Poses'
    for layer in action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=5;scene.render.fps=10
pilot='--pilot' in sys.argv
views=['se'] if pilot else (['nw','ne'] if '--back-only' in sys.argv else list(VIEWS))
indices=list(range(5))
for view in VIEWS:
    report['views'][view]={'anchor_px':set_camera(view),'camera_vector':VIEWS[view]}
for view in views:
    anchor=set_camera(view);report['views'][view]={'anchor_px':anchor,'camera_vector':VIEWS[view]}
    for i in indices:
        scene.frame_set(i+1)
        (OUT/'masters'/view).mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(OUT/'masters'/view/f'hurt-{i:02d}.png')
        bpy.ops.render.render(write_still=True)
report['source_unchanged']=hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
(OUT/('pilot.json' if pilot else 'poses.json')).write_text(json.dumps(report,indent=2),encoding='utf8')
if not pilot:
    scene.frame_set(1);set_camera('se');bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-hurt-poses.blend'))
print('HURT_POSES_OK',len(views)*len(indices),report['source_unchanged'])

