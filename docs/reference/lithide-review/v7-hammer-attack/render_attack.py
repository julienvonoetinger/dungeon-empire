"""Offline whole-mesh hammer attack. Never runs in the user's live Blender."""
import sys
from pathlib import Path
HERE=Path(__file__).parent
sys.path.insert(0,str(HERE.parent/'v5-reactions'))
from rig import *
OUT=HERE
OUT.mkdir(parents=True,exist_ok=True)
PROP_BASIS={n:o.matrix_basis.copy()for n,o in props.items()}
INITIAL_PROP={n:o.matrix_world.copy()for n,o in props.items()}
GROUND={}
NEUTRAL={}

CFG={'size':320,'ortho':3.25,'target_z':1.04,
     'durations':[90,110,110,80,60,45,65,100,120,120],
     'phases':['Guard','Raise','Wind-up','Loaded','Swing','Impact','Follow-through','Recover','Return','Guard'],
     'impact_frame':5}
# A point on the actual forward hammer face, retained in prop-local space.
hp=geometry(props['hammer'])[0]
head=[v for v in hp if v.z>max(p.z for p in hp)-.28]
front=min(p.y for p in head)
face=[v for v in head if v.y<front+.012]
CONTACT_LOCAL=props['hammer'].matrix_world.inverted()@(sum(face,Vector())/len(face))

def reset():
    arm.location=(0,0,0)
    for p in arm.pose.bones:
        p.matrix_basis=APPROVED[p.name];p.rotation_mode='QUATERNION'
    for n,o in props.items():o.matrix_basis=PROP_BASIS[n]
    bpy.context.view_layer.update()

def chain(side,root,target,q,pole,feet=False):
    upper,lower,endbone=(LEGS if feet else ARMS)[side]
    l1=(H[lower]-H[upper]).length;l2=(H[endbone]-H[lower]).length
    # Guard against folding beyond the possible annulus of a two-bone chain.
    for _ in range(14 if feet else 1):
        delta=target-root
        assert delta.length>abs(l1-l2)+.002,(side,'target too close')
        joint,end=solve(root,target,l1,l2,pole)
        assert (end-target).length<.006,(side,'unreachable wrist/ankle',list(target),list(end))
        aim(upper,root,joint,H[lower]);aim(lower,joint,end,H[endbone]);set_world(endbone,end,q)
        if not feet:break
        points,_=geometry(body);error=Vector((0,0,-min(points[i].z for i in SOLE[side])))
        if side in GROUND:
            ids,reference=GROUND[side]
            center=sum((points[j]for j in ids),Vector())/len(ids)
            error.x=reference.x-center.x;error.y=reference.y-center.y
        if error.length<.00005:break
        target=end+error

def pose(i):
    if i==9:
        # End on the exact initial key, rather than re-solving an IK support
        # pose whose sub-millimetre corrections can otherwise accumulate.
        for p in arm.pose.bones:p.matrix_basis=NEUTRAL[p.name].copy()
        bpy.context.view_layer.update()
        return
    power=[0,.3,.75,1,.8,1,.8,.45,.15,0][i]
    pitch=[0,-3,-5,-5,5,11,13,8,3,0][i]
    twist=[0,-5,-10,-12,-3,7,10,5,1,0][i]
    q=Quaternion((0,0,1),math.radians(twist))@Quaternion((1,0,0),math.radians(pitch))
    shift=Vector((0,-.025*max(0,pitch)/13,-.022-.028*power))
    pivot=H['Bone_000'];point=lambda v:pivot+q@(v-pivot)+shift
    set_world('Bone_000',pivot+shift,q)
    for side,names in LEGS.items():
        chain(side,point(H[names[0]]),H[names[2]].copy(),Quaternion(),Vector((0,-1,0)),True)
    wrist=[WRISTS['R'],Vector((-.65,-.10,1.10)),Vector((-.64,.10,1.32)),
           Vector((-.60,.20,1.40)),Vector((-.58,-.24,1.34)),Vector((-.55,-.43,.99)),
           Vector((-.55,-.43,1.02)),Vector((-.60,-.33,.99)),Vector((-.61,-.27,.90)),WRISTS['R']][i]+Vector((0,0,-.022))
    angle=[0,-25,-60,-72,15,90,80,55,20,0][i]
    wristq=Quaternion((1,0,0),math.radians(angle))@WRIST_Q['R']
    chain('R',point(H[ARMS['R'][0]]),wrist,wristq,Vector((-1,.2,-.05)))
    # The shield braces the opposite side, never crosses the weapon path.
    shield=WRISTS['L']+Vector((.025*power,-.015*power,.025*power))
    chain('L',point(H[ARMS['L'][0]]),shield+Vector((0,0,-.022)),WRIST_Q['L'],Vector((1,.1,-.1)))
    if i==0:
        points,_=geometry(body)
        for side in LEGS:
            ids=[j for j in SOLE[side]if points[j].z<.008]
            GROUND[side]=(ids,sum((points[j]for j in ids),Vector())/len(ids))
        NEUTRAL.update({p.name:p.matrix_basis.copy()for p in arm.pose.bones})

def measure(i):
    bp,bt=geometry(body);allp=bp.copy();equip={}
    for n,o in props.items():
        p,t=geometry(o);allp+=p
        relative=(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world
        error=max(abs(relative[j][k]-RELATIVE[n][j][k])for j in range(4)for k in range(4))
        equip[n]={'grip_error':error,'bounds':bounds(p),'nonhand_crossings':crossings(p,t,bp,NONHAND[n])+crossings(bp,NONHAND[n],p,t)}
    h=props['hammer']
    normal=h.matrix_world.to_quaternion()@INITIAL_PROP['hammer'].to_quaternion().inverted()@Vector((0,-1,0))
    return {'frame':i+1,'index':i,'action':'attack','bounds':bounds(allp),'body_bounds':bounds(bp),
            'sole_min_z':{s:min(bp[j].z for j in ids)for s,ids in SOLE.items()},
            'equipment':equip,'hammer_contact':list(h.matrix_world@CONTACT_LOCAL),'face_normal':list(normal),
            'pelvis':list(arm.matrix_world@arm.pose.bones['Bone_000'].head)}

scene.cycles.samples=12 if '--pilot'in sys.argv else 32
scene.cycles.use_denoising=True
scene.render.resolution_x=CFG['size']*2;scene.render.resolution_y=CFG['size']*2;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=CFG['ortho']
root=Vector((0,-.20,0));target=root+Vector((0,0,CFG['target_z']))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy())for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update()
def screen(p):
    v=world_to_camera_view(scene,cam,Vector(p));return [v.x*CFG['size']*2,(1-v.y)*CFG['size']*2]

report={'source_scene_sha256':SOURCE_HASH,'actions':{'attack':CFG},'hero_scale':.85*2.6/2.35,
        'contact_local':list(CONTACT_LOCAL),'views':{'attack':{}},'poses':[]}
for i in range(10):
    scene.frame_set(i+1);reset();pose(i)
    row=measure(i);report['poses'].append(row)
    for p in arm.pose.bones:
        for prop in ('location','rotation_quaternion','scale'):p.keyframe_insert(prop,frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
    print('POSE',i,row['bounds'],row['hammer_contact'],{n:e['nonhand_crossings']for n,e in row['equipment'].items()},flush=True)
for layer in arm.animation_data.action.layers:
    for strip in layer.strips:
        if hasattr(strip,'channelbags'):
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=10;scene.render.fps=12
contact=report['poses'][CFG['impact_frame']]['hammer_contact']
for view in VIEWS:
    camera(view)
    report['views']['attack'][view]={'anchor_px':screen(root),'camera_vector':VIEWS[view],
        'impact_px':screen(contact),'ground_contact_px':screen([*contact[:2],0]),
        'target_top_corners_px':[screen([contact[0]+x,contact[1]+y,contact[2]])for x,y in [(-.20,-.20),(.20,-.20),(.20,.20),(-.20,.20)]],
        'target_bottom_corners_px':[screen([contact[0]+x,contact[1]+y,0])for x,y in [(-.20,-.20),(.20,-.20),(.20,.20),(-.20,.20)]]}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'paladin-attack-poses.blend'),compress=True)
if '--measure-only'not in sys.argv:
    for view in (['se','nw']if '--pilot'in sys.argv else VIEWS):
        camera(view)
        for entry in report['poses']:
            if '--pilot'in sys.argv and entry['index']not in [0,3,5,7]:continue
            scene.frame_set(entry['frame']);bpy.context.view_layer.update()
            pts=[v for o in [body,*props.values()]for v in geometry(o)[0]]
            projected=[world_to_camera_view(scene,cam,v)for v in pts]
            assert all(.015<p.x<.985 and .015<p.y<.985 for p in projected),(view,entry['index'],'clipped')
            folder=OUT/'masters/attack'/view;folder.mkdir(parents=True,exist_ok=True)
            scene.render.filepath=str(folder/f"attack-{entry['index']:02}.png")
            bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('PALADIN_ATTACK_DONE',flush=True)
