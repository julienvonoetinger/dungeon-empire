"""Editable geometric Vulpin study. Run in an isolated --factory-startup Blender.
No generated artwork is edited. Model coordinates: x forward, y left, z up.
Blender swaps x/y so its camera exactly matches the game's projection.
"""
import bpy, bmesh, math, json, sys
from pathlib import Path
from mathutils import Vector, Quaternion, Matrix
from bpy_extras.object_utils import world_to_camera_view

OUT=Path(__file__).resolve().parent
N=24
PERIOD=.8
STRIDE=.44
STANCE=.60
MODEL_TO_CELL=.40
PX_PER_UNIT=256*MODEL_TO_CELL/math.sqrt(2)
ROOT_PIXEL=(80,140)

def B(p): return Vector((p[1],p[0],p[2]))
def logical(p): return (float(p.y),float(p.x),float(p.z))
def motion(t,offset=0):
    u=(t+offset)%1
    if u<STANCE:
        x=STRIDE*(STANCE/2-u)
        z=0.
    else:
        s=(u-STANCE)/(1-STANCE)
        ease=s*s*(3-2*s)
        x=-STRIDE*STANCE/2-STRIDE*(1-STANCE)*s+STRIDE*ease
        z=.105*math.sin(math.pi*s)**2
    return x,z,u<STANCE

# This process starts from Blender factory data, never the user's open file.
for obj in list(bpy.data.objects): bpy.data.objects.remove(obj,do_unlink=True)
scene=bpy.context.scene
scene.name='Vulpin_Mannequin_Review'
scene.render.fps=30
scene.frame_start=1
scene.frame_end=N
root=bpy.data.objects.new('Vulpin_Ground_Root',None)
scene.collection.objects.link(root)
root['scope']='Untextured isolated prototype. Not an approved final silhouette.'
root['cycle_seconds']=PERIOD
root['stride_model_units']=STRIDE
root['model_units_to_grid_cells']=MODEL_TO_CELL

def material(name,color):
    m=bpy.data.materials.new(name)
    m.diffuse_color=(*color,1)
    m.use_nodes=True
    bsdf=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value=(*color,1)
    bsdf.inputs['Roughness'].default_value=.74
    return m

clay=material('Neutral clay — no texture',(.40,.44,.52))
face=material('Face plane',(.60,.64,.70))
hood=material('Hood proxy',(.26,.31,.39))
dark=material('Orientation landmarks',(.045,.065,.09))
leftmat=material('Left limbs — cyan',(.16,.55,.70))
rightmat=material('Right limbs — copper',(.74,.38,.16))
jointmat=material('Joint guides',(.72,.77,.81))
tailtip=material('Tail tip proxy',(.68,.72,.78))

armdata=bpy.data.armatures.new('Vulpin_Skeleton')
rig=bpy.data.objects.new('Vulpin_Rig',armdata)
scene.collection.objects.link(rig)
rig.parent=root
rig.show_in_front=True
bpy.context.view_layer.objects.active=rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bone_defs={}
def bone(name,a,b,parent=None,connected=False):
    e=armdata.edit_bones.new(name);e.head=B(a);e.tail=B(b)
    if parent: e.parent=armdata.edit_bones[parent]
    e.use_connect=connected
    bone_defs[name]=(a,b)
    return e
bone('root',(0,0,0),(0,0,.15))
bone('pelvis',(0,0,.55),(0,0,.71),'root')
bone('chest',(0,0,.71),(0,0,.94),'pelvis',True)
bone('head',(0,0,.94),(0,0,1.35),'chest',True)
for side,s in [('L',1),('R',-1)]:
    y=s*.145
    bone('thigh.'+side,(0,y,.55),(.13,y,.31),'pelvis')
    bone('shin.'+side,(.13,y,.31),(0,y,.08),'thigh.'+side,True)
    bone('foot.'+side,(0,y,.08),(.16,y,.08),'shin.'+side,True)
    bone('upper_arm.'+side,(0,s*.27,.91),(.025,s*.29,.69),'chest')
    bone('forearm.'+side,(.025,s*.29,.69),(.07,s*.30,.52),'upper_arm.'+side,True)
    bone('hand.'+side,(.07,s*.30,.52),(.13,s*.30,.49),'forearm.'+side,True)
bone('tail.0',(-.15,0,.60),(-.38,0,.69),'pelvis')
bone('tail.1',(-.38,0,.69),(-.65,0,.87),'tail.0',True)
bone('tail.2',(-.65,0,.87),(-.84,0,1.07),'tail.1',True)
bpy.ops.object.mode_set(mode='OBJECT')

def bind(obj,bname,mat):
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces[:]);bm.to_mesh(obj.data);bm.free()
    obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    group=obj.vertex_groups.new(name=bname)
    group.add(list(range(len(obj.data.vertices))),1.,'REPLACE')
    mod=obj.modifiers.new('Driven by skeleton','ARMATURE');mod.object=rig
    obj.parent=rig
    return obj

def ellipsoid(name,center,radii,bname,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=B(center))
    obj=bpy.context.object;obj.name=name
    obj.scale=(radii[1],radii[0],radii[2])
    return bind(obj,bname,mat)

def segment(name,a,b,r1,r2,bname,mat):
    a,b=B(a),B(b);delta=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r1,radius2=r2,depth=delta.length,location=(a+b)/2)
    obj=bpy.context.object;obj.name=name
    obj.rotation_mode='QUATERNION'
    obj.rotation_quaternion=delta.to_track_quat('Z','Y')
    return bind(obj,bname,mat)

ellipsoid('Pelvis',(0,0,.57),(.18,.23,.15),'pelvis',clay)
ellipsoid('Tunic body',(-.015,0,.77),(.20,.24,.24),'chest',clay)
ellipsoid('Hood collar',(-.025,0,.95),(.22,.27,.14),'head',hood)
ellipsoid('Hood volume',(-.035,0,1.22),(.34,.36,.36),'head',hood)
ellipsoid('Face',(.135,0,1.21),(.25,.30,.28),'head',face)
ellipsoid('Muzzle',(.335,0,1.10),(.19,.19,.105),'head',face)
ellipsoid('Nose',(.49,0,1.125),(.055,.075,.045),'head',dark)
for side,s in [('L',1),('R',-1)]:
    ellipsoid('Eye.'+side,(.305,s*.186,1.247),(.035,.044,.062),'head',dark)
    # Simple closed ear wedge with fixed topology, symmetric facial landmarks.
    pts=[(.14,s*.14,1.40),(.14,s*.40,1.43),(.11,s*.33,1.77),(-.07,s*.14,1.40),(-.07,s*.40,1.43),(-.10,s*.33,1.77)]
    faces=[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)]
    mesh=bpy.data.meshes.new('Ear mesh.'+side);mesh.from_pydata([B(p) for p in pts],[],faces);mesh.update()
    obj=bpy.data.objects.new('Ear.'+side,mesh);scene.collection.objects.link(obj)
    bind(obj,'head',face)
    mat=leftmat if side=='L' else rightmat
    for part,radii in [('thigh',(.105,.09)),('shin',(.09,.075)),('upper_arm',(.085,.075)),('forearm',(.075,.065))]:
        a,b=bone_defs[part+'.'+side]
        segment(part+'.'+side,a,b,*radii,part+'.'+side,mat)
    for part in ['thigh','shin','upper_arm','forearm']:
        a,b=bone_defs[part+'.'+side]
        ellipsoid('Joint '+part+'.'+side,a,(.055,.055,.055),part+'.'+side,jointmat)
    ellipsoid('Empty glove.'+side,(.115,s*.30,.49),(.085,.065,.07),'hand.'+side,mat)
    # Flat sole, toe toward +x. Sole is exactly z=0 in the rest geometry.
    p=[(-.09,s*.145-.09,0),(.18,s*.145-.09,0),(.20,s*.145+.09,0),(-.09,s*.145+.09,0),(-.08,s*.145-.085,.11),(.14,s*.145-.085,.08),(.16,s*.145+.085,.08),(-.08,s*.145+.085,.11)]
    f=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
    mesh=bpy.data.meshes.new('Boot mesh.'+side);mesh.from_pydata([B(v) for v in p],[],f);mesh.update()
    obj=bpy.data.objects.new('Flat boot.'+side,mesh);scene.collection.objects.link(obj)
    bind(obj,'foot.'+side,mat)
ellipsoid('Hip pouch',(.025,.25,.60),(.105,.07,.115),'pelvis',hood)
for k,r1,r2,mat in [(0,.10,.17,clay),(1,.17,.14,clay),(2,.14,.025,tailtip)]:
    a,b=bone_defs['tail.'+str(k)]
    segment('Tail volume '+str(k),a,b,r1,r2,'tail.'+str(k),mat)
    if k<2: ellipsoid('Tail join '+str(k),b,(r2,r2,r2),'tail.'+str(k),mat)

controls={}
for side,s in [('L',1),('R',-1)]:
    target=bpy.data.objects.new('Foot_IK.'+side,None);scene.collection.objects.link(target)
    target.empty_display_type='CIRCLE';target.empty_display_size=.10;target.parent=root
    target.location=B((0,s*.145,.08))
    pole=bpy.data.objects.new('Knee_Pole.'+side,None);scene.collection.objects.link(pole)
    pole.empty_display_size=.08;pole.parent=root;pole.location=B((1.1,s*.145,.32))
    ik=rig.pose.bones['shin.'+side].constraints.new('IK');ik.name='Foot placement, fixed limb lengths'
    ik.target=target;ik.pole_target=pole;ik.chain_count=2;ik.use_stretch=False
    rig.pose.bones['thigh.'+side].ik_stretch=0
    rig.pose.bones['shin.'+side].ik_stretch=0
    rot=rig.pose.bones['foot.'+side].constraints.new('COPY_ROTATION')
    rot.target=target;rot.owner_space='WORLD';rot.target_space='WORLD'
    controls[side]=(target,pole,ik)
    # Resolve pole convention from actual evaluated bend, not a guessed angle.
    best=(-1e9,0)
    for angle in (0,math.pi/2,-math.pi/2,math.pi):
        ik.pole_angle=angle;bpy.context.view_layer.update()
        hip=rig.pose.bones['thigh.'+side].head;knee=rig.pose.bones['shin.'+side].head
        ankle=rig.pose.bones['shin.'+side].tail
        direction=(ankle-hip).normalized();off=knee-hip-direction*(knee-hip).dot(direction)
        score=off.dot(B((1,0,0)))
        if score>best[0]: best=(score,angle)
    ik.pole_angle=best[1]

def rotate_bone_world(name,axis,angle):
    pb=rig.pose.bones[name];pb.rotation_mode='QUATERNION'
    rest=rig.data.bones[name].matrix_local.to_quaternion()
    pb.rotation_quaternion=rest.inverted() @ Quaternion(axis,angle) @ rest

def pose(t,key=None):
    rig.location=B((0,.012*math.sin(2*math.pi*t),-.012*math.cos(4*math.pi*t)))
    if key is not None: rig.keyframe_insert('location',frame=key)
    for side,s,offset in [('L',1,0),('R',-1,.5)]:
        x,z,contact=motion(t,offset)
        target=controls[side][0];target.location=B((x,s*.145,.08+z))
        if key is not None: target.keyframe_insert('location',frame=key)
        swing=-.34*math.cos(2*math.pi*(t+offset))
        rotate_bone_world('upper_arm.'+side,B((0,1,0)),swing)
        rotate_bone_world('forearm.'+side,B((0,1,0)),-.14-.07*math.cos(2*math.pi*(t+offset)))
    for k in range(3): rotate_bone_world('tail.'+str(k),B((0,0,1)),.065*math.sin(2*math.pi*t-k*.6))
    rotate_bone_world('head',B((0,1,0)),.018*math.sin(4*math.pi*t))
    if key is not None:
        for pb in rig.pose.bones:
            if pb.rotation_mode=='QUATERNION': pb.keyframe_insert('rotation_quaternion',frame=key)

for i in range(N+1): pose(i/N,key=i+1)
# Exact stance/swing boundaries need keys even when they fall between images.
for t in (.1,.6): pose(t,key=1+t*N)
# Sampled controls use linear segments. Sufficiently dense baking preserves the
# exact linear stance track; smooth swing is analytically sampled at 30Hz.
for obj in [rig]+[c[0] for c in controls.values()]:
    action=obj.animation_data.action if obj.animation_data else None
    if not action: continue
    curves=[]
    if hasattr(action,'fcurves'): curves=list(action.fcurves)
    else:
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags: curves.extend(bag.fcurves)
    for fc in curves:
        for p in fc.keyframe_points:p.interpolation='LINEAR'
        fc.modifiers.new('CYCLES')

# Orthographic camera matches the game after the x/y coordinate conversion.
camera_data=bpy.data.cameras.new('Isometric_2_to_1')
camera=bpy.data.objects.new('Isometric_2_to_1',camera_data);scene.collection.objects.link(camera)
camera_data.type='ORTHO';camera_data.ortho_scale=160/PX_PER_UNIT
target=Vector((0,0,(ROOT_PIXEL[1]-80)/(PX_PER_UNIT*math.sqrt(3)/2)))
eye=Vector((math.sqrt(3/8),math.sqrt(3/8),.5))
camera.location=target+eye*8
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera=camera
for name,loc,energy,size in [('Key',(-3,-4,6),420,4),('Fill',(4,1,3),180,4),('Rim',(-2,4,4),280,3)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.shape='DISK';light.size=size
    obj=bpy.data.objects.new(name,light);scene.collection.objects.link(obj);obj.location=loc
    obj.rotation_euler=(Vector((0,0,.8))-obj.location).to_track_quat('-Z','Y').to_euler()
scene.world.color=(.24,.27,.32)
try:scene.render.engine='BLENDER_EEVEE'
except TypeError as error:raise RuntimeError('No EEVEE renderer: '+str(error))
scene.render.resolution_x=480;scene.render.resolution_y=480;scene.render.resolution_percentage=100
scene.render.film_transparent=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.render.image_settings.color_depth='8'
scene.render.fps=30
if hasattr(scene,'eevee') and hasattr(scene.eevee,'taa_render_samples'):scene.eevee.taa_render_samples=24

# Validate the evaluated rig itself, including off-integer frames.
rest_lengths={b.name:b.length for b in armdata.bones}
max_length=0.;max_contact=0.;max_floor=0.;min_floor=1.;max_ik=0.
contact_points={};samples=[]
for j in range(241):
    t=j/120
    frame=1+t*N
    scene.frame_set(int(frame),subframe=frame-int(frame))
    root.location=B((STRIDE*t,0,0));bpy.context.view_layer.update()
    for name,length in rest_lengths.items():
        pb=rig.pose.bones[name]
        max_length=max(max_length,abs((pb.tail-pb.head).length-length))
    feet={}
    for side,s,offset in [('L',1,0),('R',-1,.5)]:
        target=controls[side][0]
        foot=rig.pose.bones['foot.'+side]
        ankle=rig.matrix_world @ foot.head
        actual_sole=ankle+Vector((0,0,-.08))
        x,z,contact=motion(t,offset)
        max_ik=max(max_ik,(ankle-target.matrix_world.translation).length)
        min_floor=min(min_floor,actual_sole.z)
        if contact:
            max_floor=max(max_floor,abs(actual_sole.z))
            key=(side,math.floor(t+offset+1e-8))
            if key not in contact_points:contact_points[key]=actual_sole.copy()
            max_contact=max(max_contact,(actual_sole-contact_points[key]).length)
        feet[side]={'position':logical(actual_sole),'contact':contact}
    if j%5==0:samples.append({'t':t,'feet':feet})
root.location=(0,0,0)
scene.frame_set(1);bpy.context.view_layer.update()
first={b.name:b.matrix.copy() for b in rig.pose.bones}
scene.frame_set(N+1);bpy.context.view_layer.update()
loop_error=max(max(abs(first[b.name][i][k]-b.matrix[i][k]) for i in range(4) for k in range(4)) for b in rig.pose.bones)
scene.frame_set(1);bpy.context.view_layer.update()
projection_errors=[]
for p in [(0,0,0),(1,0,0),(0,1,0),(0,0,1),(.2,-.3,.5)]:
    q=world_to_camera_view(scene,camera,B(p))
    actual=(q.x*160,(1-q.y)*160)
    expected=(80+(p[0]-p[1])*.5*256*MODEL_TO_CELL,140+((p[0]+p[1])*.25-p[2]*math.sqrt(3/8))*256*MODEL_TO_CELL)
    projection_errors.append(math.dist(actual,expected))
metrics={'samples':241,'max_bone_length_error':max_length,'max_stance_world_drift':max_contact,'max_stance_floor_error':max_floor,'minimum_sole_z':min_floor,'max_IK_target_error':max_ik,'loop_pose_error':loop_error,'max_projection_pixel_error':max(projection_errors),'pole_angles':{s:c[2].pole_angle for s,c in controls.items()}}
(OUT/'rig-validation.json').write_text(json.dumps({'metrics':metrics,'contact_samples':samples},indent=2))
print('RIG_METRICS '+json.dumps(metrics),flush=True)
assert max_length<.0001,'Bone length changed'
assert max_contact<.00001,'Foot slides during stance'
assert max_floor<.00001,'Stance foot not on ground'
assert max_ik<.003,'IK target not reached'
assert min_floor>-.003,'Foot penetrates ground'
assert loop_error<.0001,'Loop discontinuity'
assert max(projection_errors)<.001,'Projection mismatch'

metadata={'status':'Untextured rig prototype, not approved silhouette or production actor','frames':N,'fps':30,'cycleSeconds':PERIOD,'strideModel':STRIDE,'modelToCell':MODEL_TO_CELL,'strideCells':STRIDE*MODEL_TO_CELL,'frameSize':160,'renderSize':480,'root':ROOT_PIXEL,'directions':{'se':0,'sw':-90,'nw':180,'ne':90},'rig':'vulpin-mannequin.blend','camera':'Exactly shared 2:1 ground projection; coordinate swap x/y in Blender','gait':'60% stance, 40% swing, fixed two-bone IK; flat soles, no heel/toe roll yet','colors':{'L':'cyan','R':'copper'}}
(OUT/'rig.json').write_text(json.dumps(metadata,indent=2))
for obj in bpy.context.selected_objects:obj.select_set(False)
rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-mannequin.blend'))
(OUT/'renders').mkdir(exist_ok=True)
for name,angle in metadata['directions'].items():
    root.rotation_euler.z=math.radians(angle)
    scene.frame_set(1);bpy.context.view_layer.update()
    scene.render.filepath=str(OUT/'renders'/f'{name}-preview.png')
    bpy.ops.render.render(write_still=True)
root.rotation_euler.z=0;scene.frame_set(1)
print('MANNEQUIN_BUILD_COMPLETE',flush=True)
