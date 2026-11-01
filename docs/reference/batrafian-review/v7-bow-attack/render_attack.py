"""Whole-mesh archery poses, deforming original bow/string; dedicated Blender."""
import sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT.parent/'v6-death'))
from rig import *
OUT=Path(__file__).parent
bow=props['bow'];quiver=props['quiver']
arrow=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('arrow_'))
arrow.hide_set(False);arrow.rotation_mode='QUATERNION'
PROP_BASIS={n:o.matrix_basis.copy()for n,o in props.items()}
ARROW_SCALE=arrow.matrix_world.to_scale().x
ARROW_MIN=min(v.co.z for v in arrow.data.vertices);ARROW_MAX=max(v.co.z for v in arrow.data.vertices)
N=12
TIMING=[100,110,90,100,100,100,90,50,80,100,100,130]
PHASES=['Guard','Reach','Ready arrow','Align','Nock and draw','Aim','Hold','Release','Follow-through','Recover','Lower','Guard']
LOAD=[0,0,0,.08,.60,.88,1,0,.04,0,0,0]
TURN=[0,-8,-25,-50,-68,-80,-80,-80,-72,-44,-16,0]
LIFT=[0,.1,.3,.65,.9,1,1,1,.95,.60,.20,0]
YAW_EXTRA=[0,0,-30,-45,-15,0,0,0,0,-45,-20,0]
# Original painted string is a narrow strip at x~.12-.24*z in source space.
# A key deforms that actual strip, not an extra line superimposed over it.
bow.data=bow.data.copy();basis=bow.shape_key_add(name='Basis');draw=bow.shape_key_add(name='Draw')
for i,v in enumerate(basis.data):
    p=v.co;z=abs(p.z)
    bend=.045*(min(z/.82,1)**2)
    string=p.x>.12-.24*p.z-.035 and z<.79
    taper=(p.z-.11)/(.79-.11) if p.z>=.11 else (.11-p.z)/(.79+.11)
    pull=.46*max(0,1-taper) if string else 0
    draw.data[i].co=p+Vector((bend+pull,0,0))
STRING_IDS=[i for i,v in enumerate(basis.data)if abs(v.co.z-.11)<.015 and v.co.x>.06]
assert STRING_IDS
NOCK_SOURCE=sum((basis.data[i].co for i in STRING_IDS),Vector())/len(STRING_IDS)
NOCK_SOURCE.z=.11
NOCK_DRAW=sum((draw.data[i].co-basis.data[i].co for i in STRING_IDS),Vector())/len(STRING_IDS)

def reset():
    arm.location=(0,0,0)
    for b in arm.pose.bones:b.matrix_basis=APPROVED[b.name];b.rotation_mode='QUATERNION'
    for n,o in props.items():o.matrix_basis=PROP_BASIS[n]
    draw.value=0;arrow.hide_render=True;arrow.hide_viewport=False
    bpy.context.view_layer.update()

def hand(side,target,q,pole):
    upper,fore,wrist=ARMS[side];shoulder=(arm.matrix_world@arm.pose.bones[upper].head).copy()
    elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,pole)
    aim(upper,shoulder,elbow,H[fore]);base=(H[wrist]-H[fore]).normalized().rotation_difference((end-elbow).normalized())
    axis=(end-elbow).normalized();source_normal=Vector((0,1,0))
    old=base@source_normal;old=(old-axis*axis.dot(old)).normalized()
    wanted=q@source_normal;wanted=(wanted-axis*axis.dot(wanted)).normalized()
    roll=math.atan2(axis.dot(old.cross(wanted)),old.dot(wanted))
    set_world(fore,elbow,Quaternion(axis,roll)@base);set_world(wrist,end,q)
    return end

def right_grip():
    finger=(H['Bone_018']-H['Bone_019']).normalized()
    thumb=Vector((-finger.z,0,finger.x)).normalized()
    old=Matrix((finger,thumb,finger.cross(thumb))).transposed()
    new=Matrix((Vector((0,-1,0)),Vector((0,0,1)),Vector((-1,0,0)))).transposed()
    return (new@old.transposed()).to_quaternion()

def nock_world():return bow.matrix_world@(NOCK_SOURCE+NOCK_DRAW*draw.value)

def place_arrow(nock,direction):
    arrow.matrix_world=Matrix.Translation(nock)@Vector((0,0,1)).rotation_difference(direction).to_matrix().to_4x4()@Matrix.Scale(ARROW_SCALE,4)@Matrix.Translation(Vector((0,0,-ARROW_MIN)))
    bpy.context.view_layer.update()

def pose(index):
    if index==11:index=0
    reset();amount=LIFT[index];q=rot((0,0,1),TURN[index])
    chest=(arm.matrix_world@arm.pose.bones['Bone_004'].head).copy()
    set_world('Bone_004',chest,q)
    neck=(arm.matrix_world@arm.pose.bones['Bone_017'].head).copy()
    set_world('Bone_017',neck,rot((0,0,1),-4*amount))
    # Body turn presents the left shoulder; feet/pelvis stay planted.
    left=WRISTS['L'].lerp(Vector((-.28,-.475,1.03)),amount)
    left.y-=.22*math.sin(math.pi*amount)
    lq=rot((1,0,0),10*math.sin(math.pi*amount))@rot((0,0,1),YAW_EXTRA[index])@WRIST_Q['L'].slerp(rot((0,0,1),30)@WRIST_Q['L'],amount)
    hand('L',left,lq,Vector((1,-.1,-.4)))
    draw.value=LOAD[index];bpy.context.view_layer.update()
    nock=nock_world()
    bow_delta=bow.matrix_world.to_quaternion()@rot((0,0,1),-90)
    if index==1:
        target=Vector((-.48,.34,1.28));rq=WRIST_Q['R']
    elif index in (2,3):
        target=Vector((-.45,.02,1.13)) if index==2 else Vector((-.36,-.05,1.18))
        rq=bow_delta@right_grip()
    elif 2<=index<=8:
        target=nock+bow_delta@Vector((-.035,.095,-.018))
        if index==7:target.y+=.31
        if index==8:target.y+=.22
        rq=bow_delta@right_grip()
    else:
        target=WRISTS['R'].lerp(nock+Vector((-.035,.095,-.018)),amount)
        rq=WRIST_Q['R'].slerp(right_grip(),amount)
    hand('R',target,rq,Vector((-1,.55,.12)))
    # The loose sling follows the turned torso but clears the broad frog head.
    quiver.matrix_world.translation+=q@Vector((0,.14,0))*amount
    if 2<=index<=8:
        wrist=(arm.matrix_world@arm.pose.bones['Bone_019'].head).copy()
        set_world('Bone_018',wrist+rq@(H['Bone_018']-H['Bone_019']),rot((0,0,1),35)@rq)
    arrow.hide_render=not(1<=index<=6)
    if index==1:
        wrist=(arm.matrix_world@arm.pose.bones['Bone_019'].head).copy()
        place_arrow(wrist+Vector((-.07,-.03,-.04)),Vector((-1,-.3,-.25)).normalized())
    elif index in (2,3):
        wrist=(arm.matrix_world@arm.pose.bones['Bone_019'].head).copy()
        place_arrow(wrist+bow_delta@Vector((.035,-.095,.018)),bow.matrix_world.to_quaternion()@Vector((-1,0,0)))
    else:place_arrow(nock,bow.matrix_world.to_quaternion()@Vector((-1,0,0)))
    bpy.context.view_layer.update()

def measure(index):
    p,t=geometry(body);allp=p.copy();eq={}
    for n,o in {**props,'arrow':arrow}.items():
        if o.hide_render:continue
        op,ot=geometry(o);allp+=op
        allowed={'bow':{'Bone_022','Bone_023','Bone_018','Bone_019'}if 2<=index<=6 else {'Bone_022','Bone_023'},'quiver':set(),'arrow':{'Bone_018','Bone_019','Bone_022','Bone_023'}}[n]
        bt=[tri for tri in t if not any(dominant[i]in allowed for i in tri)]
        eq[n]={'bounds':bounds(op),'nonhand_crossings':crossings(op,ot,p,bt)+crossings(p,bt,op,ot)}
    return {'frame':index+1,'phase':PHASES[index],'body_bounds':bounds(p),'bounds':bounds(allp),'equipment':eq,
      'nock':list(nock_world()),'left_wrist':list(arm.matrix_world@arm.pose.bones['Bone_023'].head),
      'right_wrist':list(arm.matrix_world@arm.pose.bones['Bone_019'].head),'draw':draw.value,
      'soles':{s:min(p[i].z for i in ids)for s,ids in SOLE.items()},'arrow_visible':not arrow.hide_render,
      'arrow_role':'nocked'if 4<=index<=6 else 'carried'if 1<=index<=3 else 'hidden'}

scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=3.25
root=Vector((0,-.20,0));target=root+Vector((0,0,.78))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy())for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update()
def project(point):
    p=world_to_camera_view(scene,cam,point);return [p.x*640,(1-p.y)*640]
report={'source_scene_sha256':SOURCE_HASH,'durations_ms':TIMING,'phases':PHASES,'release_ms':sum(TIMING[:7]),'flight_ms':260,
 'master_size':640,'sprite_size':320,'ortho_scale':3.25,'target_z':.78,'hero_scale':.85*2.6/2.35,
 'nock_source':list(NOCK_SOURCE),'nock_draw':list(NOCK_DRAW),'string_ids':STRING_IDS,'poses':[],'views':{}}
for i in range(N):
    scene.frame_set(i+1);pose(i);entry=measure(i);report['poses'].append(entry)
    for bone in arm.pose.bones:
        for channel in ('location','rotation_quaternion','scale'):bone.keyframe_insert(channel,frame=i+1)
    for obj in [*props.values(),arrow]:
        obj.rotation_mode='QUATERNION'
        for channel in ('location','rotation_quaternion','scale'):obj.keyframe_insert(channel,frame=i+1)
    arrow.keyframe_insert('hide_render',frame=i+1);draw.keyframe_insert('value',frame=i+1)
    print('POSE',i,{n:v['nonhand_crossings']for n,v in entry['equipment'].items()},entry['soles'],flush=True)
for obj in [arm,*props.values(),arrow,bow.data.shape_keys]:
    for layer in obj.animation_data.action.layers:
        for strip in layer.strips:
            if hasattr(strip,'channelbags'):
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=N;scene.render.fps=15
scene.frame_set(7)
release_nock=Vector(report['poses'][6]['nock']);release_tip=release_nock+Vector((0,-(ARROW_MAX-ARROW_MIN)*ARROW_SCALE,0))
for view in VIEWS:
    camera(view);report['views'][view]={'anchor_px':project(root),'camera_vector':VIEWS[view],
      'nock_px':project(release_nock),'tip_px':project(release_tip)}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'batrafian-attack-poses.blend'),compress=True)
pilot='--pilot'in sys.argv
for view in ([]if '--poses-only'in sys.argv else ['se','sw']if pilot else VIEWS):
    camera(view)
    for i in range(N):
        if pilot and i not in (1,3,6,7):continue
        scene.frame_set(i+1);bpy.context.view_layer.update()
        pts=[v for o in [body,*props.values(),arrow]if not o.hide_render for v in geometry(o)[0]]
        assert all(.01<(p:=world_to_camera_view(scene,cam,v)).x<.99 and .01<p.y<.99 for v in pts),(view,i,'clipped')
        folder=OUT/'masters'/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f'attack-{i:02}.png');bpy.ops.render.render(write_still=True)
    if not pilot:
        scene.frame_set(7);body.hide_render=True;bow.hide_render=True;quiver.hide_render=True
        scene.render.filepath=str(OUT/'masters'/view/'projectile.png');bpy.ops.render.render(write_still=True)
        body.hide_render=False;bow.hide_render=False;quiver.hide_render=False
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('BATRAFIAN_ATTACK_RENDERED',N,'poses')
