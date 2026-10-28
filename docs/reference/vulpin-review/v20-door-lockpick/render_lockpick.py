"""Eight held lockpick poses of the user's real Meshy mesh; no image puppets.

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

# A small circular search of the lock with a fixed tension hand.
LABELS=['Recherche','Tension','Soulève','Écoute','Relâche','Reprend','Ajuste','Recherche']
BOB=[-.085,-.086,-.088,-.089,-.088,-.086,-.085,-.084]
LEAN=[10,10.5,11,11.5,11,10.5,10,9.5]
TWIST=[-2,-2.3,-2.6,-2.7,-2.5,-2.2,-2,-1.8]
PICK_X=[-.105,-.095,-.085,-.082,-.09,-.105,-.115,-.117]
PICK_Y=[-.535,-.543,-.552,-.556,-.55,-.54,-.53,-.528]
PICK_Z=[.505,.515,.525,.53,.52,.505,.495,.495]
MODEL_TO_GRID=.85/(2.35*math.sqrt(.5))
# Keep the head outside the protruding crown, not only outside the wood plane.
# Allow the reviewed crown and low jambs to project beyond the wood face.
LOCK=Vector((0,-1.06,.275/MODEL_TO_GRID))
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

# Simple 3D lockpicks are rendered with the original character, not overlays.
metal=bpy.data.materials.new('LockpickSteel');metal.diffuse_color=(.44,.51,.63,1)
metal.use_nodes=True
bsdf=metal.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value=(.44,.51,.63,1)
bsdf.inputs['Metallic'].default_value=.65;bsdf.inputs['Roughness'].default_value=.3
tools=[]
for name,radius in [('Pick',.006),('TensionWrench',.005)]:
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=radius;curve.bevel_resolution=2
    line=curve.splines.new('POLY');line.points.add(2)
    ob=bpy.data.objects.new(name,curve);scene.collection.objects.link(ob);ob.data.materials.append(metal)
    tools.append(ob)

def set_tool(ob,points,index):
    for q,p in zip(ob.data.splines[0].points,points):
        q.co=(*p,1);q.keyframe_insert('co',frame=index+1)

def apply_pose(index):
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    shift=Vector((0,.018,BOB[index]))
    lean=Quaternion((0,0,1),math.radians(TWIST[index]))@Quaternion((1,0,0),math.radians(LEAN[index]))
    pivot=H['Bone_000']
    def bodypoint(p):return pivot+lean@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,lean)
    targets={};hands={}
    for side,bones in LEGS.items():
        upper,lower,foot=bones
        hip=bodypoint(H[upper])
        # Slightly staggered fixed stance, never translate the feet with recoil.
        ankle=H[foot]+Vector((.020 if side=='L' else -.020,-.075 if side=='L' else .075,0))
        knee,ankle=solve_joint(hip,ankle,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((0,-1,0)))
        aim(upper,hip,knee,H[lower]);aim(lower,knee,ankle,H[foot])
        set_world(foot,ankle)
        targets[side]={'ankle':list(ankle),'grounded':True}
    for side,bones in ARMS.items():
        upper,lower,wrist=bones;sign=1 if side=='L' else -1
        shoulder=bodypoint(H[upper])
        end=Vector((.115,-.545,.54)) if side=='L' else Vector((PICK_X[index],PICK_Y[index],PICK_Z[index]))
        elbow,end=solve_joint(shoulder,end,(H[lower]-H[upper]).length,(H[wrist]-H[lower]).length,Vector((sign*.25,1,-.4)))
        aim(upper,shoulder,elbow,H[lower]);aim(lower,elbow,end,H[wrist])
        hand='Bone_028' if side=='L' else 'Bone_023'
        # Raise the hands to guard the torso without passing them through it.
        direction=(LOCK-end).normalized()*.09
        aim(wrist,end,end+direction,H[hand])
        hands[side]=end+direction*.65
    # Curl the existing finger chains into a protective fist, never add cards.
    for chain in FINGERS:
        for joint,name in enumerate(chain):
            axis=R[name].to_quaternion().inverted()@Vector((1,0,0))
            arm.pose.bones[name].rotation_quaternion=Quaternion(axis,math.radians([-25,-45,-40][joint]))
    bpy.context.view_layer.update()
    # The model has no facial morphs. Pose the head/hood as a unit at its neck.
    set_world('Bone_021',bodypoint(H['Bone_021']),lean@Quaternion((1,0,0),math.radians(7)))
    tail=arm.pose.bones['Bone_019']
    tail.rotation_quaternion=Quaternion((1,0,0),math.radians([1,1.5,2,2.5,2,1.5,1,.5][index]))
    bpy.context.view_layer.update()
    p=evaluated_vertices()
    minima={s:min(p[i].z for i in ids) for s,ids in ground_masks.items()}
    support_min=min(minima.values());arm.location.z=-support_min
    bpy.context.view_layer.update();p=evaluated_vertices()
    minima={s:min(p[i].z for i in ids) for s,ids in ground_masks.items()}
    grips={side:v+Vector((0,0,-support_min)) for side,v in hands.items()}
    for side,ob in zip(['R','L'],tools):
        tip=LOCK if side=='R' else LOCK+Vector((0,0,-.008))
        mid=grips[side].lerp(tip,.76)+Vector((0,0,.018 if side=='R' else -.015))
        set_tool(ob,[grips[side],mid,tip],index)
    return {'index':index,'label':LABELS[index],'feet':targets,'sole_min_z':minima,
            'ground_correction':-support_min,'mesh_min_z':min(v.z for v in p),
            'finite':all(math.isfinite(c) for v in p for c in v),'body_pitch_degrees':LEAN[index],'head_pitch_degrees':LEAN[index]+7,'grips':{s:list(v) for s,v in grips.items()},'lock_target':list(LOCK),'door_clearance':min(v.y-LOCK.y for v in p),
            'bounds':[[min(v[i] for v in p) for i in range(3)],[max(v[i] for v in p) for i in range(3)]]}

scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
world=bpy.data.worlds.new('LockpickStudio');world.use_nodes=True;scene.world=world
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

report={'source':str(SOURCE),'source_sha256':SOURCE_HASH,'method':'Eight explicit held 3D poses, no in-between generation.',
 'frame_count':8,'duration_seconds':1.0,'fps':8,'playback_order':list(range(8)),'durations_ms':[125]*8,'lock_target':list(LOCK),'model_to_grid':MODEL_TO_GRID,'views':{},'poses':[],'material_policy':'Original imported textures and shaders retained.',
 'validation_scope':'Finite geometry and sampled boot-sole contact only; visual review required for rig quality.'}
# Save eight held poses so they are inspectable in Blender, without interpolated
# motion. These are keys for the source document, not a runtime animation rig.
for i in range(8):
    scene.frame_set(i+1)
    report['poses'].append(apply_pose(i))
    for p in arm.pose.bones:
        p.keyframe_insert('location',frame=i+1);p.keyframe_insert('rotation_quaternion',frame=i+1);p.keyframe_insert('scale',frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
if arm.animation_data and arm.animation_data.action:
    action=arm.animation_data.action;action.name='Lockpick_8_Held_Poses'
    for layer in action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=8;scene.render.fps=8
pilot='--pilot' in sys.argv
views=['se'] if pilot else (['nw','ne'] if '--back-only' in sys.argv else list(VIEWS))
indices=[4] if '--peak-only' in sys.argv else list(range(8))
for view in VIEWS:
    anchor=set_camera(view);q=world_to_camera_view(scene,cam,LOCK)
    report['views'][view]={'anchor_px':anchor,'camera_vector':VIEWS[view],'lock_px':[q.x*512,(1-q.y)*512]}
for view in views:
    set_camera(view)
    for i in indices:
        scene.frame_set(i+1)
        (OUT/'masters'/view).mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(OUT/'masters'/view/f'lockpick-{i:02d}.png')
        bpy.ops.render.render(write_still=True)
report['source_unchanged']=hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
(OUT/('pilot.json' if pilot else 'poses.json')).write_text(json.dumps(report,indent=2),encoding='utf8')
for ob in tools:
    action=ob.data.animation_data.action
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
if not pilot:
    scene.frame_set(1);set_camera('se');bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-lockpick-poses.blend'))
print('LOCKPICK_POSES_OK',len(views)*len(indices),report['source_unchanged'])




