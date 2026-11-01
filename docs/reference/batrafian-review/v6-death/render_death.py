"""Knees first, forward collapse, open palms, dropped bow, attached quiver."""
import sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from rig import *
OUT=Path(__file__).parent
PROP_BASIS={n:o.matrix_basis.copy()for n,o in props.items()}
PROP_WORLD={n:o.matrix_world.copy()for n,o in props.items()}
PROP_LOCAL={n:[v.co.copy()for v in o.data.vertices]for n,o in props.items()}
TIMING=[40,50,60,70,65,65,65,65,70,100]
PHASES=['Standing','Buckle','Lowering','Knees down','Kneeling','Reach','Falling','Catch','Settle','Dead']
PITCH=[0,8,16,20,24,36,50,64,76,82]
HIP_Z=[H['Bone_000'].z,.62,.50,.40,.32,.28,.24,.21,.18,.16]
HIP_Y=[H['Bone_000'].y,.08,.06,.04,.02,0,-.02,-.04,-.06,-.08]
RELEASE=[0,.18,.60,1,1,1,1,1,1,1]
QUIVER_SWAY=[0,0,0,0,0,.25,.6,.8,.95,1]
# Flatten the actual bow plane using the principal axes, not an assumed GLB
# import orientation. It lands left of the body; the back-mounted quiver stays.
import numpy as np
bow_points,_=geometry(props['bow']);array=np.array([list(v)for v in bow_points]);mean=array.mean(axis=0)
_,vectors=np.linalg.eigh(np.cov((array-mean).T))
long=Vector(vectors[:,2]);wide=Vector(vectors[:,1])
if long.z<0:long=-long
if wide.x<0:wide=-wide
normal=wide.cross(long).normalized()
flatten=Matrix((wide,long,normal)).to_4x4()
BOW_FINAL=flatten@PROP_WORLD['bow']
pp=[BOW_FINAL@v for v in PROP_LOCAL['bow']];center=sum(pp,Vector())/len(pp)
BOW_FINAL.translation+=Vector((.94,-.02,0))-Vector((center.x,center.y,min(v.z for v in pp)))

def reset():
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=APPROVED[p.name];p.rotation_mode='QUATERNION'
    for n,o in props.items():o.matrix_basis=PROP_BASIS[n]
    bpy.context.view_layer.update()

def leg(side,hip,target,q,pole,sole=None):
    upper,lower,foot=LEGS[side]
    for attempt in range(16):
        knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,pole)
        aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,q)
        if sole is None:break
        p,_=geometry(body);error=sole-min(p[i].z for i in SOLE[side])
        if abs(error)<.00005:break
        target=end+Vector((0,0,error))

def hand(side,shoulder,target,q,lean,pole):
    upper,fore,wrist=ARMS[side]
    elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,pole)
    aim(upper,shoulder,elbow,H[fore])
    transport=(lean@FORE_AXIS[side]).rotation_difference((end-elbow).normalized())
    set_world(fore,elbow,transport@lean@FORE_Q[side]);set_world(wrist,end,q)

def palm_basis(name,reference,sign):
    finger=(H[reference]-H[name]).normalized()
    normal=(Vector((0,1,0))-finger*finger.dot(Vector((0,1,0)))).normalized()
    new_finger=Vector((sign*.12,-1,0)).normalized();new_normal=Vector((0,0,-1))
    old=Matrix((finger,normal,finger.cross(normal))).transposed()
    new=Matrix((new_finger,new_normal,new_finger.cross(new_normal))).transposed()
    return (new@old.transposed()).to_quaternion()

def drop_bow(index):
    amount=RELEASE[index]
    if not amount:return
    obj=props['bow'];current=obj.matrix_world.copy();local_center=sum(PROP_LOCAL['bow'],Vector())/len(PROP_LOCAL['bow'])
    point=(current@local_center).lerp(BOW_FINAL@local_center,amount)
    point.x+=.20*math.sin(amount*math.pi);point.z+=.05*math.sin(amount*math.pi)
    turn=max(0,(amount-.15)/.85)
    matrix=Matrix.LocRotScale(Vector(),current.to_quaternion().slerp(BOW_FINAL.to_quaternion(),turn),current.to_scale())
    matrix.translation=point-matrix@local_center
    p=[matrix@v for v in PROP_LOCAL['bow']];matrix.translation.z+=max(0,-min(v.z for v in p))
    obj.matrix_world=matrix;bpy.context.view_layer.update()

def pose(index):
    reset();pitch=PITCH[index];q=rot((1,0,0),pitch);pivot=H['Bone_000']
    hip=Vector((pivot.x,HIP_Y[index],HIP_Z[index]));point=lambda p:hip+q@(p-pivot)
    set_world('Bone_000',hip,q)
    chest_pitch=pitch-[0,0,0,0,0,0,1,2,4,5][index]
    chest_head=(arm.matrix_world@arm.pose.bones['Bone_004'].head).copy()
    set_world('Bone_004',chest_head,rot((1,0,0),chest_pitch))
    shoulders={s:(arm.matrix_world@arm.pose.bones[n[0]].head).copy()for s,n in ARMS.items()}
    for side,(upper,lower,foot)in LEGS.items():
        sign=1 if side=='L'else -1;top=point(H[upper])
        if index<3:
            leg(side,top,H[foot]+Vector((sign*.015,-.01 if side=='L'else .01,0)),Quaternion(),Vector((sign*1.2,-1,0)),0)
        else:
            q1=rot((1,0,0),[-25,-10,8,35,62,75,82][index-3]+(3 if side=='R'else -3))@rot((0,1,0),-sign*8)
            q2=rot((1,0,0),[102,108,108,104,98,94,90][index-3])@rot((0,0,1),sign*6)
            knee=top+q1@(H[lower]-H[upper]);ankle=knee+q2@(H[foot]-H[lower])
            aim(upper,top,knee,H[lower]);aim(lower,knee,ankle,H[foot])
            set_world(foot,ankle,rot((1,0,0),[125,130,135,140,145,150,155][index-3]))
    reach=[0,.03,.10,.18,.3,.5,.7,.88,.97,1][index]
    for side,names in ARMS.items():
        sign=1 if side=='L'else -1;shoulder=shoulders[side]
        target=point(WRISTS[side]).lerp(shoulder+Vector((sign*.12,-.46,-.06)),reach)
        hand(side,shoulder,target,q@WRIST_Q[side],q,Vector((sign*.7,.1,-.2)))
    head=(arm.matrix_world@arm.pose.bones['Bone_017'].head).copy()
    headturn=[0,0,0,0,0,0,-8,-25,-48,-65][index]
    headpitch=chest_pitch+[0,0,0,0,0,0,0,0,5,12][index]
    set_world('Bone_017',head,rot((1,0,0),headpitch)@rot((0,0,1),headturn))
    if RELEASE[index]:
        for name in ('Bone_022','Bone_018'):
            b=arm.pose.bones[name];b.rotation_quaternion=b.rotation_quaternion.slerp(Quaternion(),min(1,RELEASE[index]*2))
        bpy.context.view_layer.update()
    p,_=geometry(body);correction=-min(v.z for v in p)
    weight=[0,0,0,0,0,.2,.45,.75,.95,1][index]
    for side,(upper,fore,wrist)in ARMS.items():
        if not weight:continue
        sign=1 if side=='L'else -1;shoulder=shoulders[side]
        current=(arm.matrix_world@arm.pose.bones[wrist].head).copy()
        target=current.lerp(Vector((sign*.53,shoulder.y-.44,.075-correction)),weight)
        hand(side,shoulder,target,Quaternion(),q,Vector((sign,.05,.1)))
        end=(arm.matrix_world@arm.pose.bones[wrist].head).copy()
        elbow=(arm.matrix_world@arm.pose.bones[fore].head).copy()
        # Palm and forearm share weights; rotate both toward the floor.
        pq=palm_basis(wrist,'Bone_022'if side=='L'else 'Bone_018',sign)
        axis=(end-elbow).normalized();old=(H[wrist]-H[fore]).normalized()
        base=old.rotation_difference(axis)
        old_normal=base@Vector((0,1,0));old_normal=(old_normal-axis*axis.dot(old_normal)).normalized()
        wanted=Vector((0,0,-1));wanted=(wanted-axis*axis.dot(wanted)).normalized()
        roll=math.atan2(axis.dot(old_normal.cross(wanted)),old_normal.dot(wanted))
        set_world(fore,elbow,Quaternion(axis,roll)@base);set_world(wrist,end,pq)
    p,_=geometry(body);arm.location.z=-min(v.z for v in p);bpy.context.view_layer.update()
    # The slung quiver settles across the shoulder instead of intersecting the
    # raised upper arm and turned head. It remains parented to the torso.
    props['quiver'].matrix_world.translation+=rot((1,0,0),chest_pitch)@Vector((-.12,.055,0))*QUIVER_SWAY[index]
    bpy.context.view_layer.update()
    drop_bow(index)

def measure(index):
    p,tri=geometry(body);allp=p.copy();equipment={}
    for name,obj in props.items():
        op,ot=geometry(obj);allp+=op
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        test_tri=tri if name=='bow'and index>=3 else NONHAND[name]
        equipment[name]={'bounds':bounds(op),'grip_error':max(abs(rel[j][k]-RELATIVE[name][j][k])for j in range(4)for k in range(4)),
          'nonhand_crossings':crossings(op,ot,p,test_tri)+crossings(p,test_tri,op,ot)}
    groups={'chest':{'Bone_002','Bone_003','Bone_004'},'head':{'Bone_015','Bone_016'},'hands':{'Bone_018','Bone_019','Bone_022','Bone_023'},'knees':{'Bone_008','Bone_013'}}
    return {'frame':index+1,'index':index,'phase':PHASES[index],'body_bounds':bounds(p),'bounds':bounds(allp),
      'floor_samples':{n:min(p[j].z for j,b in enumerate(dominant)if b in g)for n,g in groups.items()},
      'equipment':equipment,'pelvis':list(arm.matrix_world@arm.pose.bones['Bone_000'].head),
      'finite':all(math.isfinite(c)for v in allp for c in v)}

scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=3.25
root=Vector((0,-.20,0));target=root+Vector((0,0,.46))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy())for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update();q=world_to_camera_view(scene,cam,root)
    return [q.x*640,(1-q.y)*640]
report={'source_scene_sha256':SOURCE_HASH,'durations_ms':TIMING,'phases':PHASES,'master_size':640,'sprite_size':320,
 'quiver_sway_weights':QUIVER_SWAY,'quiver_sway_local':[-.12,.055,0],
 'ortho_scale':3.25,'target_z':.46,'hero_scale':.85*2.6/2.35,'poses':[],'views':{},
 'approved_attachments':{n:[list(row)for row in m]for n,m in RELATIVE.items()}}
for i in range(10):
    scene.frame_set(i+1);pose(i);entry=measure(i);report['poses'].append(entry)
    for bone in arm.pose.bones:
        for channel in ('location','rotation_quaternion','scale'):bone.keyframe_insert(channel,frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
    for obj in props.values():
        obj.rotation_mode='QUATERNION'
        for channel in ('location','rotation_quaternion','scale'):obj.keyframe_insert(channel,frame=i+1)
    print('POSE',i,json.dumps(entry['floor_samples']),{n:e['nonhand_crossings']for n,e in entry['equipment'].items()},flush=True)
for obj in [arm,*props.values()]:
    for layer in obj.animation_data.action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=10;scene.render.fps=15
for view in VIEWS:report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view]}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'batrafian-death-poses.blend'),compress=True)
pilot='--pilot'in sys.argv
for view in ([]if '--poses-only'in sys.argv else ['se','nw']if pilot else VIEWS):
    camera(view)
    for i in range(10):
        if pilot and i not in (4,7,9):continue
        scene.frame_set(i+1);bpy.context.view_layer.update()
        pts=[v for o in [body,*props.values()]for v in geometry(o)[0]]
        assert all(.01<(q:=world_to_camera_view(scene,cam,v)).x<.99 and .01<q.y<.99 for v in pts),(view,i,'clipped')
        folder=OUT/'masters'/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f'death-{i:02}.png');bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('BATRAFIAN_DEATH_RENDERED',len(report['poses']),'poses')
