"""Mycean: buckle, knees, release staff, forward collapse. Background Blender."""
import sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from rig import *
OUT=Path(__file__).parent
staff=props['staff']
STAFF_BASIS=staff.matrix_basis.copy();STAFF_WORLD=staff.matrix_world.copy()
STAFF_LOCAL=[v.co.copy() for v in staff.data.vertices]
GRIP=next(m for m in body.modifiers if m.type=='LATTICE')
CONTACT=next(m for m in body.modifiers if m.type=='SHRINKWRAP')
TIMING=[40,50,60,70,65,65,65,65,70,100]
PHASES=['Standing','Buckle','Lowering','Knees down','Kneeling','Reach','Falling','Catch','Settle','Dead']
PITCH=[0,6,12,18,24,36,50,64,76,82]
HIP_Z=[H['Bone_000'].z,.35,.29,.23,.18,.16,.15,.14,.13,.12]
HIP_Y=[H['Bone_000'].y,.01,.02,.03,.04,.03,.01,-.01,-.03,-.05]
RELEASE=[0,.20,.65,1,1,1,1,1,1,1]
FOOT_PITCH=[145,185,195,165,160,155,150]
# Flatten the staff shaft alongside the body, roots toward the feet. Retain
# geometry/materials; animate only its rigid world transform after release.
STAFF_FINAL=Matrix.Rotation(math.radians(90),4,'X')@Matrix.Rotation(math.radians(-15),4,'Y')@STAFF_WORLD
p=[STAFF_FINAL@v for v in STAFF_LOCAL];c=sum(p,Vector())/len(p)
STAFF_FINAL.translation+=Vector((1.04,-.35,0))-Vector((c.x,c.y,min(v.z for v in p)))

def reset():
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=APPROVED[p.name];p.rotation_mode='QUATERNION'
    staff.matrix_basis=STAFF_BASIS
    GRIP.strength=1;CONTACT.show_viewport=True;CONTACT.show_render=True
    bpy.context.view_layer.update()

def hand(side,shoulder,target,q,lean,pole):
    upper,fore,wrist=ARMS[side]
    elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,pole)
    aim(upper,shoulder,elbow,H[fore])
    transport=(lean@FORE_AXIS[side]).rotation_difference((end-elbow).normalized())
    set_world(fore,elbow,transport@lean@FORE_Q[side]);set_world(wrist,end,q)

def leg(side,hip,target,q,pole):
    upper,lower,foot=LEGS[side]
    for attempt in range(12):
        knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,pole)
        aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,q)
        points,_=geometry(sole_probe);error=-min(points[i].z for i in SOLE[side])
        if abs(error)<.00005:break
        target=end+Vector((0,0,error))

def drop_staff(i):
    amount=RELEASE[i]
    if not amount:return
    center=sum(STAFF_LOCAL,Vector())/len(STAFF_LOCAL)
    a=STAFF_WORLD@center;b=STAFF_FINAL@center
    point=a.lerp(b,amount)+Vector((.15*math.sin(amount*math.pi),0,.12*math.sin(amount*math.pi)))
    mat=Matrix.LocRotScale(Vector(),STAFF_WORLD.to_quaternion().slerp(STAFF_FINAL.to_quaternion(),amount),STAFF_WORLD.to_scale())
    mat.translation=point-mat@center
    points=[mat@v for v in STAFF_LOCAL];mat.translation.z-=min(v.z for v in points)
    staff.matrix_world=mat;bpy.context.view_layer.update()

def pose(i):
    reset()
    if i==0:return
    q=rot((1,0,0),PITCH[i]);pivot=H['Bone_000']
    hip=Vector((pivot.x,HIP_Y[i],HIP_Z[i]));point=lambda p:hip+q@(p-pivot)
    set_world('Bone_000',hip,q)
    chest=(arm.matrix_world@arm.pose.bones['Bone_008'].head).copy()
    set_world('Bone_008',chest,rot((1,0,0),PITCH[i]-[0,0,0,0,0,0,1,2,4,5][i]))
    shoulders={s:(arm.matrix_world@arm.pose.bones[n[0]].head).copy() for s,n in ARMS.items()}
    for side,(upper,lower,foot) in LEGS.items():
        sign=1 if side=='L' else -1;top=point(H[upper])
        if i<3:
            leg(side,top,H[foot]+Vector((sign*.015,0,0)),Quaternion(),Vector((sign*.5,-1,0)))
        else:
            q1=rot((1,0,0),[-25,-10,8,35,62,75,82][i-3]+(3 if side=='R' else -3))@rot((0,1,0),-sign*8)
            q2=rot((1,0,0),[102,108,108,104,98,94,90][i-3])@rot((0,0,1),sign*6)
            knee=top+q1@(H[lower]-H[upper]);ankle=knee+q2@(H[foot]-H[lower])
            aim(upper,top,knee,H[lower]);aim(lower,knee,ankle,H[foot])
            set_world(foot,ankle,rot((1,0,0),FOOT_PITCH[i-3]))
    # The broad cap cannot simply follow an82degree torso rotation: its rim
    # would lift the whole torso. Neck bends independently as the rim settles.
    neck=(arm.matrix_world@arm.pose.bones['Bone_017'].head).copy()
    set_world('Bone_017',neck,rot((1,0,0),[0,6,12,18,23,28,30,32,33,34][i])@rot((0,0,1),[0,0,0,0,0,-6,-12,-20,-26,-30][i]))
    reach=[0,.08,.18,.28,.4,.6,.78,.9,.98,1][i]
    for side in ARMS:
        sign=1 if side=='L' else -1;shoulder=shoulders[side]
        target=point(WRISTS[side]).lerp(shoulder+Vector((sign*.12,-.34,-.07)),reach)
        hand(side,shoulder,target,q@WRIST_Q[side],q,Vector((sign*.7,.1,-.2)))
    GRIP.strength=1-RELEASE[i]
    CONTACT.show_viewport=i==0;CONTACT.show_render=i==0
    # Near the ground, place relaxed arms ahead of the shoulders, not beneath
    # them. Use original open hand orientation once the staff has been released.
    p,_=geometry(body);correction=-min(v.z for v in p)
    weight=[0,0,0,0,0,.25,.5,.8,.95,1][i]
    for side,(_,fore,wrist) in ARMS.items():
        if not weight:continue
        sign=1 if side=='L' else -1;shoulder=shoulders[side]
        current=(arm.matrix_world@arm.pose.bones[wrist].head).copy()
        target=current.lerp(Vector((sign*.44,shoulder.y-.36,.08-correction)),weight)
        hand(side,shoulder,target,rot((1,0,0),80)@rot((0,0,1),sign*12),q,Vector((sign,.1,.05)))
    p,_=geometry(body);arm.location.z=-min(v.z for v in p);bpy.context.view_layer.update()
    drop_staff(i)

def measure(i):
    p,tri=geometry(body);sp,st=geometry(staff);probe,_=geometry(sole_probe)
    groups={'chest':{'Bone_010','Bone_009','Bone_008'},'head':{'Bone_017','Bone_016'},'hands':{'Bone_023','Bone_031'},'knees':{'Bone_005','Bone_014'}}
    hitpoints=crossings(sp,st,p,tri,True)|crossings(p,tri,sp,st,True)
    joints={n:list(arm.matrix_world@arm.pose.bones[n].head) for n in ['Bone_000','Bone_017',*sum([list(v) for v in ARMS.values()],[]),'Bone_005','Bone_014']}
    return {'index':i,'frame':i+1,'phase':PHASES[i],'body_bounds':bounds(p),'bounds':bounds(p+sp),'staff_bounds':bounds(sp),
      'full_body_crossings':len(hitpoints),'contact_bounds':bounds([Vector(x) for x in hitpoints]) if hitpoints else [],
      'floor_samples':{n:min(probe[v.index].z for v in body.data.vertices if any(body.vertex_groups[w.group].name in g and w.weight>.08 for w in v.groups)) for n,g in groups.items()},
      'joints':joints,'grip_strength':GRIP.strength,'contact_enabled':CONTACT.show_render}

scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=3.25
root=Vector((0,-.20,0));target=root+Vector((0,0,.46))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy()) for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update();p=world_to_camera_view(scene,cam,root);return[p.x*640,(1-p.y)*640]

report={'source_scene_sha256':SOURCE_HASH,'durations_ms':TIMING,'phases':PHASES,'master_size':640,'sprite_size':320,'ortho_scale':3.25,'target_z':.46,'hero_scale':.85*2.6/2.35,'poses':[],'views':{}}
for i in range(10):
    scene.frame_set(i+1);pose(i);entry=measure(i);report['poses'].append(entry)
    print('POSE',i,entry['floor_samples'],'crossings',entry['full_body_crossings'],entry['contact_bounds'],flush=True)
    for bone in arm.pose.bones:
        for channel in ('location','rotation_quaternion','scale'):bone.keyframe_insert(channel,frame=i+1)
    arm.keyframe_insert('location',frame=i+1);staff.rotation_mode='QUATERNION'
    for channel in ('location','rotation_quaternion','scale'):staff.keyframe_insert(channel,frame=i+1)
    GRIP.keyframe_insert('strength',frame=i+1)
    for channel in ('show_viewport','show_render'):CONTACT.keyframe_insert(channel,frame=i+1)
for obj in [arm,staff,body]:
    for layer in obj.animation_data.action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=10;scene.render.fps=15
for view in VIEWS:report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view]}
assert all(p['full_body_crossings']==0 and p['body_bounds'][0][2]>-.0001 and p['staff_bounds'][0][2]>-.0001 for p in report['poses']), 'Invalid full-body/staff contact: inspect POSE output'
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mycean-death-poses.blend'),compress=True)
pilot='--pilot' in sys.argv
for view in ([] if '--poses-only' in sys.argv else ['se','nw'] if pilot else VIEWS):
    camera(view)
    for i in range(10):
        if pilot and i not in (3,6,9):continue
        scene.frame_set(i+1);bpy.context.view_layer.update()
        pts=[v for o in [body,staff] for v in geometry(o)[0]]
        assert all(.01<(q:=world_to_camera_view(scene,cam,v)).x<.99 and .01<q.y<.99 for v in pts),(view,i,'clipped')
        folder=OUT/'masters'/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f'death-{i:02}.png');bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('MYCEAN_DEATH_RENDERED',len(report['poses']),'poses',flush=True)
