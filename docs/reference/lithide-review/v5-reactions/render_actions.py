"""Whole equipped Paladin held poses. Dedicated background Blender only."""
import sys,math,json,hashlib
from pathlib import Path
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT))
from rig import *
PROP_BASIS={n:o.matrix_basis.copy() for n,o in props.items()}
PROP_WORLD={n:o.matrix_world.copy() for n,o in props.items()}
PROP_LOCAL={n:[v.co.copy()for v in o.data.vertices]for n,o in props.items()}

# Milliseconds include the displayed pose; no runtime interpolation or puppet.
ACTIONS={
 'hurt':{'size':256,'ortho':2.6,'durations':[65,65,90,115,100,95,90,100],
         'phases':['Ready','Impact','Recoil','Brace','Return','Recover','Balance','Ready']},
 'death':{'size':320,'ortho':3.25,'durations':[55,65,75,85,80,70,70,65,80,105],
          'phases':['Standing','Hit','Buckle','Lowering','Knees down','Yield','Falling','Landing','Settle','Dead']}}

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

def death(index):
    # First lower on both knees. Only after that does the torso roll onto its
    # right side; legs remain bent instead of rotating an upright mannequin.
    kneel=[0,.10,.35,.75,1,1,1,1,1,1][index]
    roll=[0,-1,-2,-4,-8,-22,-46,-68,-80,-83][index]
    pitch=[0,-5,0,6,10,14,18,20,20,20][index]
    q=Quaternion((0,1,0),math.radians(roll))@Quaternion((1,0,0),math.radians(pitch))
    pivot=H['Bone_000'];shift=Vector((-.055*max(0,(index-4)/5),0,-.022-.27*kneel))
    point=lambda p:pivot+q@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,q)
    for side,names in LEGS.items():
        foot=H[names[2]]+Vector((0,.32*kneel,.07*kneel))
        # Feet stay planted while lowering; folded legs then follow the fall.
        if index<5:
            foot_q=Quaternion((1,0,0),math.radians(-65*kneel))
            target=foot.copy();pole=Vector((0,-1,0));sole=0
        else:
            foot_q=q@Quaternion((1,0,0),math.radians(-65))
            target=point(foot-Vector((0,0,shift.z)))
            pole=q@Vector((0,-1,0));sole=None
        leg(side,point(H[names[0]]),target,foot_q,pole,sole)
    for side,names in ARMS.items():
        sign=1 if side=='L' else -1
        reach=max(0,(index-4)/5)
        # Hammer arm reaches forward to leave space under the falling chest.
        folded=Vector((sign*.18,-.34,.74 if side=='L'else .68))
        wrist=WRISTS[side].lerp(folded,reach)
        wristq=q@Quaternion((1,0,0),math.radians(35*reach if side=='R' else 0))@WRIST_Q[side]
        pole=Vector((sign,.1,-.1)).lerp(Vector((sign*.15,-1,-.25)),reach)
        hand(side,point(H[names[0]]),point(wrist),wristq,q@pole)
    # Physical support comes from real evaluated armour/equipment, not a guessed
    # pivot height. This translation is baked in the held pose, never runtime.
    points=geometry(body)[0]
    correction=-min(v.z for v in points)
    if index>=5 or correction>0:
        arm.location.z+=correction;bpy.context.view_layer.update()
    # Fingers loosen as the equipment is released. Parent bones stay intact;
    # the relative prop transforms are explicitly keyed for these held poses.
    release=max(0,(index-3)/6)
    if release:
        for side,ids in [('R',range(38,50)),('L',range(26,38))]:
            for i in ids:
                bone=arm.pose.bones[f'Bone_{i:03}']
                bone.rotation_quaternion=bone.rotation_quaternion.slerp(Quaternion(),release*.8)
        bpy.context.view_layer.update()
        points=geometry(body)[0]
        arm.location.z-=min(v.z for v in points)
        bpy.context.view_layer.update()
    for name,obj in props.items():
        start=PROP_WORLD[name]
        # Flat final equipment beside the torso, with no root-height compensation.
        rot=Quaternion((0,1,0),math.radians(90)) if name=='hammer'else Quaternion((1,0,0),math.radians(-90))
        final=rot.to_matrix().to_4x4()@start
        pp=[final@v for v in PROP_LOCAL[name]]
        centre=sum(pp,Vector())/len(pp)
        destination=Vector((-.20,-1.45,0))if name=='hammer'else Vector((.65,-.65,0))
        final.translation+=destination-Vector((centre.x,centre.y,min(v.z for v in pp)))
        if release:
            current=obj.matrix_world.copy()
            # Ease quickly out of the hand; equipment has landed before the body.
            amount=min(1,release*2.5)
            loc=current.translation.lerp(final.translation,amount)
            loc.z+=.10*math.sin(amount*math.pi)
            quat=current.to_quaternion().slerp(final.to_quaternion(),amount)
            matrix=Matrix.LocRotScale(loc,quat,current.to_scale())
            pp=[matrix@v for v in PROP_LOCAL[name]]
            matrix.translation.z+=max(0,-min(v.z for v in pp))
            obj.matrix_world=matrix
            bpy.context.view_layer.update()
    return kneel

def measure(action,index):
    points,tri=geometry(body);allp=points.copy();equipment={}
    for name,obj in props.items():
        p,t=geometry(obj);allp+=p
        relative=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        err=max(abs(relative[i][j]-RELATIVE[name][i][j])for i in range(4)for j in range(4))
        equipment[name]={'grip_error':err,'bounds':bounds(p),'nonhand_crossings':crossings(p,t,points,NONHAND[name])+crossings(points,NONHAND[name],p,t)}
    return {'action':action,'index':index,'body_bounds':bounds(points),'bounds':bounds(allp),
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
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy())for n in ('Key','Fill','Rim')]
def camera(view,action='hurt'):
    cfg=ACTIONS[action]
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
            if '--death-only' in sys.argv and entry['action']!='death':continue
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
