"""Eight held chest-opening poses of the user's real Meshy mesh; no image puppets.

Offline preview only. Original GLB and its material/vertex data stay intact.
"""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from bpy_extras.object_utils import world_to_camera_view

OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'/'Meshy_AI_Character_output.glb'
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

# Direct opening: empty hands, no picking tools and no looting gesture.
LABELS=['Prêt','Se penche','Saisit','Amorce','Soulève','Maintient','Relâche','Se redresse']
BOB=[-.02,-.055,-.105,-.105,-.10,-.10,-.05,-.02]
LEAN=[0,10,18,18,18,16,9,0]
HAND_Y=[-.29,-.48,-.60,-.61,-.62,-.62,-.46,-.29]
HAND_Z=[.52,.49,.48,.50,.54,.54,.52,.52]
HAND_X=[.25,.19,.14,.14,.14,.14,.20,.25]
HEAD=[8,12,14,10,7,7,10,12]
TIMING=[120,140,100,100,120,180,140,180]
MODEL_TO_GRID=.85/(2.35*math.sqrt(.5))
# Grip trajectory measured in the unchanged source model. Index 2 = first contact.
# It is registered against the painted chest, not a reconstructed chest mesh.
CONTACT=Vector((0,-.675,.505))
FINGERS=[['Bone_035','Bone_034','Bone_033'],['Bone_038','Bone_037','Bone_036'],['Bone_041','Bone_040','Bone_039'],['Bone_044','Bone_043','Bone_042'],['Bone_047','Bone_046','Bone_045'],['Bone_050','Bone_049','Bone_048'],['Bone_053','Bone_052','Bone_051'],['Bone_056','Bone_055','Bone_054']]
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
    height=math.sqrt(max(0,length1*length1-along*along))
    perpendicular=pole-direction*direction.dot(pole)
    perpendicular.normalize()
    return root+direction*along+perpendicular*height,end

def evaluated_vertices():
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=obj.to_mesh()
    p=[obj.matrix_world@v.co for v in me.vertices];obj.to_mesh_clear();return p

def apply_pose(index):
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    shift=Vector((0,0,BOB[index]))
    lean=Quaternion((1,0,0),math.radians(LEAN[index]))
    pivot=H['Bone_000']
    def bodypoint(p):return pivot+lean@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,lean)
    targets={};hands={};reach_errors=[]
    for side,bones in LEGS.items():
        upper,lower,foot=bones
        hip=bodypoint(H[upper])
        ankle=H[foot]+Vector((.025 if side=='L' else -.025,-.045 if side=='L' else .045,0))
        knee,ankle=solve_joint(hip,ankle,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((0,-1,0)))
        aim(upper,hip,knee,H[lower]);aim(lower,knee,ankle,H[foot]);set_world(foot,ankle)
        targets[side]={'ankle':list(ankle),'grounded':True}
    for side,bones in ARMS.items():
        upper,lower,wrist=bones;sign=1 if side=='L' else -1
        shoulder=bodypoint(H[upper])
        requested=Vector((sign*HAND_X[index],HAND_Y[index],HAND_Z[index]))
        elbow,end=solve_joint(shoulder,requested,(H[lower]-H[upper]).length,(H[wrist]-H[lower]).length,Vector((sign*.3,.5,-.5)))
        reach_errors.append((end-requested).length)
        aim(upper,shoulder,elbow,H[lower]);aim(lower,elbow,end,H[wrist])
        hand='Bone_028' if side=='L' else 'Bone_023'
        direction=Vector((0,-.075,.025)) if index in [1,2,3,4,5] else Vector((0,-.04,-.075))
        aim(wrist,end,end+direction,H[hand])
        hands[side]=end+direction
    for chain in FINGERS:
        for joint,name in enumerate(chain):
            axis=R[name].to_quaternion().inverted()@Vector((1,0,0))
            curl=([12,25,38][joint] if index in [2,3,4,5] else [5,12,15][joint])
            arm.pose.bones[name].rotation_quaternion=Quaternion(axis,math.radians(-curl))
    set_world('Bone_021',bodypoint(H['Bone_021']),lean@Quaternion((1,0,0),math.radians(HEAD[index])))
    arm.pose.bones['Bone_019'].rotation_quaternion=Quaternion((1,0,0),math.radians([0,3,6,5,3,2,1,0][index]))
    bpy.context.view_layer.update()
    p=evaluated_vertices();minima={s:min(p[i].z for i in ids) for s,ids in ground_masks.items()}
    correction=-min(minima.values());arm.location.z=correction
    bpy.context.view_layer.update();p=evaluated_vertices()
    minima={s:min(p[i].z for i in ids) for s,ids in ground_masks.items()}
    grips={side:v+Vector((0,0,correction)) for side,v in hands.items()}
    return {'index':index,'label':LABELS[index],'feet':targets,'sole_min_z':minima,
            'ground_correction':correction,'mesh_min_z':min(v.z for v in p),
            'finite':all(math.isfinite(c) for v in p for c in v),'body_pitch_degrees':LEAN[index],
            'grips':{s:list(v) for s,v in grips.items()},'max_reach_error':max(reach_errors),
            'bounds':[[min(v[i] for v in p) for i in range(3)],[max(v[i] for v in p) for i in range(3)]]}
scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
world=bpy.data.worlds.new('ChestOpenStudio');world.use_nodes=True;scene.world=world
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

report={'source':str(SOURCE),'source_sha256':SOURCE_HASH,'method':'Eight fixed whole-mesh poses; original Meshy paint.',
 'frame_count':8,'duration_seconds':sum(TIMING)/1000,'fps':10,'playback_order':list(range(8)),
 'durations_ms':TIMING,'contact':list(CONTACT),'model_to_grid':MODEL_TO_GRID,'views':{},'poses':[],
 'chest_state':'unlocked-ajar','material_policy':'Original imported textures and shaders retained; no tools.',
 'validation_scope':'Grounding, reach and projection proxies; painted chest has no actual 3D mesh.'}
for i in range(8):
    scene.frame_set(i+1);report['poses'].append(apply_pose(i))
    assert report['poses'][-1]['max_reach_error']<.001,(i,report['poses'][-1]['max_reach_error'])
    for p in arm.pose.bones:
        p.keyframe_insert('location',frame=i+1);p.keyframe_insert('rotation_quaternion',frame=i+1);p.keyframe_insert('scale',frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
if arm.animation_data and arm.animation_data.action:
    action=arm.animation_data.action;action.name='Chest_Open_8_Held_Poses'
    for layer in action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=8;scene.render.fps=10
pilot='--pilot' in sys.argv
views=['se'] if pilot else list(VIEWS)
indices=[0,7] if '--ends-only' in sys.argv else list(range(8))
for view in VIEWS:
    anchor=set_camera(view)
    def projected(v):
        q=world_to_camera_view(scene,cam,Vector(v));return [q.x*512,(1-q.y)*512]
    report['views'][view]={'anchor_px':anchor,'camera_vector':VIEWS[view],
      'grips_px':[{s:projected(v) for s,v in p['grips'].items()} for p in report['poses']]}
if '--no-render' not in sys.argv:
    for view in views:
        set_camera(view)
        for i in indices:
            scene.frame_set(i+1)
            (OUT/'masters'/view).mkdir(parents=True,exist_ok=True)
            scene.render.filepath=str(OUT/'masters'/view/f'chest-open-{i:02d}.png')
            bpy.ops.render.render(write_still=True)
report['source_unchanged']=hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
(OUT/'poses.json').write_text(json.dumps(report,indent=2),encoding='utf8')
scene.frame_set(1);set_camera('se');bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-chest-open-poses.blend'))
print('CHEST_OPEN_POSES_OK',len(views)*len(indices),report['source_unchanged'])
