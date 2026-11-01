"""Whole equipped Paladin held poses. Dedicated background Blender only."""
import sys,math,json,hashlib
from pathlib import Path
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT.parent/'v5-reactions'))
from rig import *
OUT=Path(__file__).parent
PROP_BASIS={n:o.matrix_basis.copy() for n,o in props.items()}
PROP_WORLD={n:o.matrix_world.copy() for n,o in props.items()}
PROP_LOCAL={n:[v.co.copy()for v in o.data.vertices]for n,o in props.items()}

# Milliseconds include the displayed pose; no runtime interpolation or puppet.
ACTIONS={
 'hurt':{'size':256,'ortho':2.6,'target_z':.72,'durations':[65,65,90,115,100,95,90,100],
         'phases':['Ready','Impact','Recoil','Brace','Return','Recover','Balance','Ready']},
 'death':{'size':320,'ortho':3.25,'target_z':.46,'durations':[55,65,75,85,80,70,70,65,80,105],
          'phases':['Standing','Buckle','Lowering','Knees down','Kneeling','Reach','Falling','Catch','Settle','Dead']}}

def reset():
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=APPROVED[p.name];p.rotation_mode='QUATERNION'
    for n,o in props.items():o.matrix_basis=PROP_BASIS[n]
    bpy.context.view_layer.update()

def leg(side,hip,target,foot_q,pole,sole_height=None):
    upper,lower,foot=LEGS[side]
    for _ in range(14):
        knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,pole)
        aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,foot_q)
        if sole_height is None:break
        points,_=geometry(body);error=sole_height-min(points[i].z for i in SOLE[side])
        if abs(error)<.00005:break
        target=end+Vector((0,0,error))
    return {'knee':list(knee),'ankle':list(end)}

def hand(side,shoulder,target,q,pole):
    upper,fore,wrist=ARMS[side]
    elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,pole)
    aim(upper,shoulder,elbow,H[fore]);aim(fore,elbow,end,H[wrist]);set_world(wrist,end,q)

def hurt(index):
    strength=[0,.40,.85,1,.65,.32,.10,0][index]
    pitch=[0,-6,-13,-14,-9,-4,-1,0][index]
    q=Quaternion((0,1,0),math.radians(-2*strength))@Quaternion((1,0,0),math.radians(pitch))
    pivot=H['Bone_000'];shift=Vector((0,.025*strength,-.022-.050*strength))
    point=lambda p:pivot+q@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,q)
    for side,names in LEGS.items():leg(side,point(H[names[0]]),H[names[2]].copy(),Quaternion(),Vector((0,-1,0)),0)
    for side,names in ARMS.items():
        sign=1 if side=='L' else -1
        delta=Vector((sign*.02*strength,-.025*strength,.04*strength))
        hand(side,point(H[names[0]]),point(WRISTS[side]+delta),q@WRIST_Q[side],Vector((sign,.1,-.1)))
    return strength

def rot(axis,degrees):return Quaternion(axis,math.radians(degrees))

def palm_down(name,head,reference,sign):
    old_y=(H[reference]-H[name]).normalized()
    old_z=(Vector((0,-1,0))-old_y*old_y.dot(Vector((0,-1,0)))).normalized()
    old_x=old_y.cross(old_z).normalized()
    new_y=Vector((sign*.10,-1,0)).normalized();new_z=Vector((0,0,-1));new_x=new_y.cross(new_z).normalized()
    old=Matrix((old_x,old_y,old_z)).transposed();new=Matrix((new_x,new_y,new_z)).transposed()
    set_world(name,head,(new@old.inverted()).to_quaternion())

def forearm_down(name,head,end,reference):
    old_y=(H[reference]-H[name]).normalized()
    old_z=(Vector((0,-1,0))-old_y*old_y.dot(Vector((0,-1,0)))).normalized()
    new_y=(end-head).normalized()
    new_z=(Vector((0,0,-1))-new_y*new_y.dot(Vector((0,0,-1)))).normalized()
    old=Matrix((old_y.cross(old_z).normalized(),old_y,old_z)).transposed()
    new=Matrix((new_y.cross(new_z).normalized(),new_y,new_z)).transposed()
    set_world(name,head,(new@old.inverted()).to_quaternion())

def death(index):
    # Adapt the approved Vulpin sequence to THIS skeleton's lengths and armour:
    # pelvis lowers, knees receive weight, chest folds separately, hands reach.
    pitch=[0,8,16,20,24,36,50,64,76,82][index]
    hip_z=[.474,.42,.35,.285,.255,.23,.205,.18,.16,.15][index]
    hip_y=[.038,.02,0,-.02,-.04,-.055,-.07,-.09,-.11,-.12][index]
    q=rot((1,0,0),pitch);pivot=H['Bone_000'];hip=Vector((pivot.x,hip_y,hip_z))
    point=lambda p:hip+q@(p-pivot)
    set_world('Bone_000',hip,q)
    chest_head=(arm.matrix_world@arm.pose.bones['Bone_004'].head).copy()
    chest_pitch=pitch-[0,0,0,0,0,0,1,2,4,5][index]
    set_world('Bone_004',chest_head,rot((1,0,0),chest_pitch))
    shoulders={side:(arm.matrix_world@arm.pose.bones[n[0]].head).copy()for side,n in ARMS.items()}
    for side,(upper,lower,foot) in LEGS.items():
        sign=1 if side=='L'else -1;top=point(H[upper])
        if index<3:
            leg(side,top,H[foot]+Vector((sign*.01,-.015 if side=='L'else .015,0)),Quaternion(),Vector((0,-1,0)),0)
        else:
            q1=rot((1,0,0),[-25,-10,8,35,62,75,82][index-3]+(3 if side=='R'else -3))@rot((0,1,0),-sign*4)
            q2=rot((1,0,0),[102,108,108,104,98,94,90][index-3])@rot((0,0,1),sign*4)
            knee=top+q1@(H[lower]-H[upper]);ankle=knee+q2@(H[foot]-H[lower])
            aim(upper,top,knee,H[lower]);aim(lower,knee,ankle,H[foot])
            set_world(foot,ankle,rot((1,0,0),[125,130,138,146,155,162,166][index-3]))
    reach=[0,.03,.10,.18,.3,.5,.7,.88,.97,1][index]
    for side,(upper,lower,wrist) in ARMS.items():
        sign=1 if side=='L'else -1;shoulder=shoulders[side]
        target=point(WRISTS[side]).lerp(shoulder+Vector((sign*.08,-.48,-.06)),reach)
        hand(side,shoulder,target,q@WRIST_Q[side],Vector((sign*.5,.1,-.2)))
    # Turn the neck in its own frame, without rolling the body onto one shoulder.
    head=(arm.matrix_world@arm.pose.bones['Bone_017'].head).copy()
    headturn=[0,0,0,0,0,0,-8,-25,-48,-65][index]
    head_pitch=chest_pitch+[0,0,0,0,0,0,0,8,27,43][index]
    set_world('Bone_017',head,rot((1,0,0),head_pitch)@rot((0,0,1),headturn))
    release=[0,.08,.32,.7,1,1,1,1,1,1][index]
    if release:
        for n in [*range(26,38),*range(38,50)]:
            b=arm.pose.bones[f'Bone_{n:03}'];b.rotation_quaternion=b.rotation_quaternion.slerp(Quaternion(),min(1,release*2))
        bpy.context.view_layer.update()
    # Ground the actual armour first. Then place palms in that grounded space;
    # keeping shoulder-relative hands would hold the chest up like a push-up.
    p,_=geometry(body);correction=-min(v.z for v in p)
    weight=[0,0,0,0,0,.2,.45,.75,.95,1][index]
    for side,(upper,lower,wrist)in ARMS.items():
        if not weight:continue
        sign=1 if side=='L'else -1;shoulder=shoulders[side]
        current=(arm.matrix_world@arm.pose.bones[wrist].head).copy()
        floor=Vector((sign*.47,shoulder.y-.49,.075-correction))
        target=current.lerp(floor,weight)
        hand(side,shoulder,target,Quaternion(),Vector((sign,.05,.1)))
        end=(arm.matrix_world@arm.pose.bones[wrist].head).copy()
        elbow=(arm.matrix_world@arm.pose.bones[lower].head).copy()
        forearm_down(lower,elbow,end,wrist)
        palm_down(wrist,end,'Bone_018'if side=='L'else 'Bone_022',sign)
    p,_=geometry(body);arm.location.z=-min(v.z for v in p);bpy.context.view_layer.update()
    # Equipment falls beside the knees, away from the receiving hands/chest.
    for name,obj in props.items():
        if not release:continue
        start=PROP_WORLD[name]
        rotation=rot((0,1,0),90)if name=='hammer'else rot((1,0,0),-90)
        final=rotation.to_matrix().to_4x4()@start;pp=[final@v for v in PROP_LOCAL[name]]
        center=sum(pp,Vector())/len(pp)
        destination=Vector((-1.03,-.08,0))if name=='hammer'else Vector((1.06,-.12,0))
        final.translation+=destination-Vector((center.x,center.y,min(v.z for v in pp)))
        current=obj.matrix_world.copy();amount=min(1,release*2.5)
        local_center=sum(PROP_LOCAL[name],Vector())/len(PROP_LOCAL[name])
        loc=(current@local_center).lerp(final@local_center,amount)
        loc.x+=(-1 if name=='hammer'else 1)*.24*math.sin(amount*math.pi)
        loc.z+=.08*math.sin(amount*math.pi)
        turn=max(0,(amount-.2)/.8)
        matrix=Matrix.LocRotScale(Vector(),current.to_quaternion().slerp(final.to_quaternion(),turn),current.to_scale())
        matrix.translation=loc-matrix@local_center
        pp=[matrix@v for v in PROP_LOCAL[name]];matrix.translation.z+=max(0,-min(v.z for v in pp))
        obj.matrix_world=matrix;bpy.context.view_layer.update()
    return pitch

def measure(action,index):
    points,tri=geometry(body);allp=points.copy();equipment={}
    for name,obj in props.items():
        p,t=geometry(obj);allp+=p
        relative=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        err=max(abs(relative[i][j]-RELATIVE[name][i][j])for i in range(4)for j in range(4))
        equipment[name]={'grip_error':err,'bounds':bounds(p),'nonhand_crossings':crossings(p,t,points,NONHAND[name])+crossings(points,NONHAND[name],p,t)}
    floor_groups={'chest':{'Bone_002','Bone_003','Bone_004'},'head':{'Bone_015','Bone_016'},'hands':{'Bone_019','Bone_023'},'knees':{'Bone_008','Bone_013'}}
    samples={name:min(points[i].z for i,n in enumerate(dominant)if n in group)for name,group in floor_groups.items()}
    return {'action':action,'index':index,'body_bounds':bounds(points),'bounds':bounds(allp),'floor_samples':samples,
            'sole_min_z':{s:min(points[i].z for i in ids)for s,ids in SOLE.items()},
            'equipment':equipment,'pelvis':list(arm.matrix_world@arm.pose.bones['Bone_000'].head),
            'head':list(arm.matrix_world@arm.pose.bones['Bone_015'].head),
            'knees':{s:list(arm.matrix_world@arm.pose.bones[n[1]].head)for s,n in LEGS.items()},
            'finite':all(math.isfinite(c)for p in allp for c in p)}

scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.cycles.samples=16 if '--pilot' in sys.argv else 32
scene.cycles.use_denoising=True;scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=2.6
root=Vector((0,-.20,0));target=root+Vector((0,0,.46))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy())for n in ('Key','Fill','Rim')]
def camera(view,action='hurt'):
    cfg=ACTIONS[action]
    target=root+Vector((0,0,cfg['target_z']))
    scene.render.resolution_x=cfg['size']*2;scene.render.resolution_y=cfg['size']*2
    cam.data.ortho_scale=cfg['ortho']
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update();p=world_to_camera_view(scene,cam,root)
    return [p.x*cfg['size']*2,(1-p.y)*cfg['size']*2]

report={'source_scene_sha256':SOURCE_HASH,'actions':ACTIONS,'ortho_scale':2.6,'hero_scale':.85*2.6/2.35,'views':{},'poses':[]}
frame=0
for action,cfg in ACTIONS.items():
    for index in range(len(cfg['durations'])):
        frame+=1;scene.frame_set(frame);reset();(hurt if action=='hurt' else death)(index)
        entry=measure(action,index);entry['frame']=frame;report['poses'].append(entry)
        for p in arm.pose.bones:
            for prop in ('location','rotation_quaternion','scale'):p.keyframe_insert(prop,frame=frame)
        arm.keyframe_insert('location',frame=frame)
        for obj in props.values():
            obj.rotation_mode='QUATERNION'
            for prop in ('location','rotation_quaternion','scale'):obj.keyframe_insert(prop,frame=frame)
        print('POSE',action,index,entry['bounds'],{k:e['nonhand_crossings']for k,e in entry['equipment'].items()},flush=True)
for obj in [arm,*props.values()]:
    for layer in obj.animation_data.action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=frame;scene.render.fps=12
for action in ACTIONS:
    report['views'][action]={view:{'anchor_px':camera(view,action),'camera_vector':VIEWS[view]}for view in VIEWS}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'paladin-action-poses.blend'),compress=True)
if '--measure-only' not in sys.argv:
    for view in (['se','nw']if '--pilot'in sys.argv else VIEWS):
        for entry in report['poses']:
            if entry['action']!='death':continue
            if '--pilot'in sys.argv and entry['index']not in ([0,3]if entry['action']=='hurt'else[4,7,9]):continue
            camera(view,entry['action'])
            scene.frame_set(entry['frame']);bpy.context.view_layer.update()
            pts=[v for o in [body,*props.values()]for v in geometry(o)[0]]
            projected=[world_to_camera_view(scene,cam,v)for v in pts]
            assert all(.01<p.x<.99 and .01<p.y<.99 for p in projected),(view,entry['action'],entry['index'],'clipped')
            folder=OUT/'masters'/entry['action']/view;folder.mkdir(parents=True,exist_ok=True)
            scene.render.filepath=str(folder/f"{entry['action']}-{entry['index']:02}.png")
            bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('PALADIN_ACTIONS_DONE',len(report['poses']),'poses',flush=True)
