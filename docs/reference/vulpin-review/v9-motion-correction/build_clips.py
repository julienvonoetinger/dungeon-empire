"""Extend the real v6 rig. Isolated geometry study, no painted asset editing."""
import bpy, math, json, sys, shutil, hashlib
from pathlib import Path
from mathutils import Vector, Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'v6-articulated-mannequin/vulpin-mannequin.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['Vulpin_Rig'];root=bpy.data.objects['Vulpin_Ground_Root']
for o in bpy.data.objects:o.animation_data_clear()
for a in list(bpy.data.actions):bpy.data.actions.remove(a)
def B(p):return Vector((p[1],p[0],p[2]))
def turn(name,axis,angle):
    pb=rig.pose.bones[name];pb.rotation_mode='QUATERNION'
    q=rig.data.bones[name].matrix_local.to_quaternion()
    pb.rotation_quaternion=q.inverted()@Quaternion(B(axis),angle)@q
feet={s:bpy.data.objects['Foot_IK.'+s] for s in ['L','R']}
hand_targets={};hand_iks={};tools=[]
for side,s in [('L',1),('R',-1)]:
    target=bpy.data.objects.new('Hand_IK.'+side,None);scene.collection.objects.link(target);target.parent=root
    pole=bpy.data.objects.new('Elbow_Pole.'+side,None);scene.collection.objects.link(pole);pole.parent=root;pole.location=B((-.4,s*.65,.72))
    ik=rig.pose.bones['forearm.'+side].constraints.new('IK');ik.name='Lockpick hand placement';ik.target=target;ik.pole_target=pole;ik.chain_count=2;ik.use_stretch=False;ik.influence=0
    rig.pose.bones['forearm.'+side].ik_stretch=0;rig.pose.bones['upper_arm.'+side].ik_stretch=0
    hand_targets[side]=target;hand_iks[side]=ik
    bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.008,depth=.13,location=B((.185,s*.30,.49)))
    obj=bpy.context.object;obj.name='Tiny lockpick.'+side;obj.rotation_euler.x=math.pi/2
    bpy.context.view_layer.objects.active=obj;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    obj.data.materials.append(bpy.data.materials['Joint guides']);vg=obj.vertex_groups.new(name='hand.'+side);vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Skeleton','ARMATURE');mod.object=rig;obj.parent=rig;tools.append(obj)

CLIPS={
 'idle':dict(seconds=1.6,source=24,loop=True,label='Attente'),
 'walk':dict(seconds=.8,source=48,loop=True,label='Marche',stride=.44),
 'run':dict(seconds=.36,source=48,loop=True,label='Course',stride=.80),
 'hurt':dict(seconds=.4,source=13,loop=False,label='Dégâts'),
 'lock-door':dict(seconds=.8,source=24,loop=True,label='Crochetage porte'),
 'lock-chest':dict(seconds=.8,source=24,loop=True,label='Crochetage coffre'),
 'loot':dict(seconds=1.2,source=24,loop=True,label='Ramassage'),
 'death':dict(seconds=1.5,source=37,loop=False,label='Chute'),
 'dead':dict(seconds=1,source=1,loop=False,label='Mort',reuse='death')}
DIRS={'se':0,'sw':-90,'nw':180,'ne':90}
def smooth(t):return max(0,min(1,t))**2*(3-2*max(0,min(1,t)))
def curve(t,points):
    """Continuous, shape-preserving timed posing, with no stop at every key."""
    if t<=points[0][0]:return points[0][1]
    if t>=points[-1][0]:return points[-1][1]
    slopes=[(b[1]-a[1])/(b[0]-a[0]) for a,b in zip(points,points[1:])]
    tangents=[0]+[0 if a*b<=0 else 2*a*b/(a+b) for a,b in zip(slopes,slopes[1:])]+[0]
    for i,(a,b) in enumerate(zip(points,points[1:])):
        if a[0]<=t<=b[0]:
            h=b[0]-a[0];u=(t-a[0])/h
            return (2*u**3-3*u**2+1)*a[1]+(u**3-2*u*u+u)*h*tangents[i]+(-2*u**3+3*u*u)*b[1]+(u**3-u*u)*h*tangents[i+1]
def angles(name,pitch=0,roll=0,yaw=0):
    pb=rig.pose.bones[name];q=rig.data.bones[name].matrix_local.to_quaternion()
    pb.rotation_quaternion=q.inverted()@Quaternion(B((1,0,0)),roll)@Quaternion(B((0,0,1)),yaw)@Quaternion(B((0,1,0)),pitch)@q
def collapse(t):
    """Hips sink first; knees, torso, head, arms and tail settle on separate curves."""
    knee=curve(t,[(0,0),(.12,.16),(.3,.85),(.43,1),(.65,.8),(1,.8)])
    roll=curve(t,[(0,0),(.23,.025),(.40,.2),(.60,.85),(.78,1),(1,1)])
    settle=curve(t,[(0,0),(.40,0),(.64,.72),(.84,1),(1,1)])
    lag=curve(t,[(0,0),(.35,0),(.7,.75),(.94,1),(1,1)])
    rig.location=B((curve(t,[(0,0),(.23,.03),(.5,.12),(.78,.17),(1,.17)]),-.18*roll,curve(t,[(0,0),(.14,-.07),(.3,-.22),(.43,-.33),(.62,-.44),(.85,-.49),(1,-.49)])))
    angles('pelvis',pitch=-.07*knee,roll=-1.48*roll,yaw=.16*roll)
    angles('chest',pitch=-.25*knee-.08*settle,roll=.30*settle,yaw=-.12*settle)
    angles('head',pitch=curve(t,[(0,0),(.20,-.18),(.47,-.04),(.68,-.16),(.88,-.05),(1,-.05)]),roll=-.10*lag)
    ik=1-smooth((t-.22)/.16)
    for side in ['L','R']:
        for c in rig.pose.bones['shin.'+side].constraints:c.influence=ik
        for c in rig.pose.bones['foot.'+side].constraints:c.influence=ik
    angles('thigh.L',pitch=.65*knee+.43*settle,roll=.8*settle)
    angles('shin.L',pitch=-1.65*knee-.08*settle)
    angles('foot.L',pitch=.48*settle)
    angles('thigh.R',pitch=.78*knee+.026*settle,roll=-.25*settle)
    angles('shin.R',pitch=-1.75*knee+.20*settle)
    angles('foot.R',pitch=.4*settle)
    reach=curve(t,[(0,0),(.16,.08),(.38,.75),(.54,1),(.82,.75),(1,.75)])
    angles('upper_arm.L',pitch=.8*reach,roll=1.1*settle)
    angles('forearm.L',pitch=.12+.68*lag)
    angles('hand.L',pitch=-.3*lag)
    angles('upper_arm.R',pitch=.85*reach-.2375*settle,roll=-.6*settle)
    angles('forearm.R',pitch=.12+.53*settle)
    angles('hand.R',pitch=.16*settle)
    for i in range(3):angles('tail.'+str(i),yaw=-.3*lag)
    bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
    lowest=min((o.evaluated_get(dg).matrix_world@v.co).z for o in bpy.data.objects if o.type=='MESH' and o not in tools for v in o.evaluated_get(dg).data.vertices)
    # Unilateral floor contact: never pull an airborne part down onto the floor.
    # Translate the whole hierarchy, including IK targets/poles. Moving only
    # the rig makes the blended leg solver pull the feet below the floor again.
    root.location.z+=max(0,-lowest)
def foot_motion(t,offset,stride,stance,lift):
    u=(t+offset)%1
    if u<stance:return stride*(stance/2-u),0,True
    v=(u-stance)/(1-stance)
    return -stride*stance/2-stride*(1-stance)*v+stride*smooth(v),lift*math.sin(math.pi*v)**2,False

def pose(name,t):
    root.location=(0,0,0);rig.location=(0,0,0);rig.rotation_mode='QUATERNION';rig.rotation_quaternion=Quaternion()
    for pb in rig.pose.bones:
        pb.location=(0,0,0);pb.rotation_mode='QUATERNION';pb.rotation_quaternion=Quaternion()
    for side,s in [('L',1),('R',-1)]:
        feet[side].location=B((0,s*.145,.08))
        for c in rig.pose.bones['shin.'+side].constraints:c.influence=1
        for c in rig.pose.bones['foot.'+side].constraints:c.influence=1
        hand_iks[side].influence=0
        turn('forearm.'+side,(0,1,0),-.14)
    for o in tools:o.hide_render=name not in ('lock-door','lock-chest')
    contacts={'L':True,'R':True}
    if name in ('walk','run'):
        running=name=='run';stance=.30 if running else .60;stride=CLIPS[name]['stride']
        rig.location=B((0,.012*math.sin(2*math.pi*t),(-.025+.045*(.5-.5*math.cos(4*math.pi*(t-.1)))) if running else -.012*math.cos(4*math.pi*t)))
        turn('chest',(0,1,0),-.28 if running else 0)
        if running:turn('head',(0,1,0),.10)
        for side,s,offset in [('L',1,0),('R',-1,.5)]:
            x,z,c=foot_motion(t,offset,stride,stance,.20 if running else .105)
            feet[side].location=B((x,s*.145,.08+z));contacts[side]=c
            turn('upper_arm.'+side,(0,1,0),-(.85 if running else .34)*math.cos(2*math.pi*(t+offset)))
            turn('forearm.'+side,(0,1,0),(.95 if running else -.14)-.07*math.cos(2*math.pi*(t+offset)))
    elif name in ('lock-door','lock-chest','loot'):
        crouch=name!='lock-door';rig.location=B((.015,0,-.19 if crouch else -.02))
        turn('chest',(0,1,0),-.23 if crouch else -.13);turn('head',(0,1,0),-.10 if crouch else -.04)
        for side,s in [('L',1),('R',-1)]:
            hand_iks[side].influence=1
            if name=='loot':
                v=(t+(0 if side=='L' else .5))%1
                a=.5-.5*math.cos(v*2*math.pi)
                hand_targets[side].location=B((.28-.14*a,s*(.12+.08*a),.48+.10*a))
            else:hand_targets[side].location=B((.26+.007*math.sin(4*math.pi*t+(0 if side=='L' else math.pi)),s*.12,(.48 if crouch else .87)+.008*math.sin(2*math.pi*t)))
            turn('hand.'+side,(0,1,0),.08*math.sin(4*math.pi*t))
    elif name=='hurt':
        e=math.sin(math.pi*min(1,t))**2
        rig.location=B((0,0,-.045*e));turn('chest',(0,1,0),.22*e);turn('head',(0,1,0),.16*e)
        for side in ['L','R']:turn('upper_arm.'+side,(0,1,0),-.5*e);turn('forearm.'+side,(0,1,0),-.6*e-.14)
    elif name in ('death','dead'):
        collapse(1 if name=='dead' else t)
        contacts={'L':False,'R':False}
    else:
        rig.location=B((0,0,-.006+.006*math.cos(2*math.pi*t)))
        turn('head',(0,0,1),.028*math.sin(2*math.pi*t))
    if name not in ('death','dead'):
        for k in range(3):turn('tail.'+str(k),(0,0,1),.055*math.sin(2*math.pi*t-k*.6))
        if name=='run':
            for k in range(3):angles('tail.'+str(k),pitch=(.15,.12,.05)[k],yaw=.055*math.sin(2*math.pi*t-k*.6))
    bpy.context.view_layer.update()
    return contacts

# Match the existing camera density, with overscan for the prone silhouette.
SIZE=224;ANCHOR=[112,180];px=256*.4/math.sqrt(2);cam=scene.camera
cam.data.ortho_scale=SIZE/px
target=Vector((0,0,(ANCHOR[1]-SIZE/2)/(px*math.sqrt(3)/2)))
eye=Vector((math.sqrt(3/8),math.sqrt(3/8),.5));cam.location=target+8*eye;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=448;scene.render.resolution_y=448
def screen(p):
    q=world_to_camera_view(scene,cam,p);return [q.x*SIZE,(1-q.y)*SIZE]
rest={b.name:b.length for b in rig.data.bones};metrics={};manifest={'canvas':SIZE,'anchor':ANCHOR,'nominalDensity':160,'modelToCell':.4,'directions':DIRS,'clips':CLIPS,'poses':{}}
for name,c in CLIPS.items():
    maxbone=0;maxik=0;maxfoot=0;minfloor=100;loop_error=0;first=None;last=None;groups={};drift=0
    for i in range(121):
        t=i/120;contact=pose(name,t)
        for b in rig.pose.bones:maxbone=max(maxbone,abs((b.tail-b.head).length-rest[b.name]))
        current={b.name:list(v for row in b.matrix for v in row) for b in rig.pose.bones}
        if i==0:first=current
        if i==120:last=current
        if name not in ('death','dead'):
            for s,off in [('L',0),('R',.5)]:
                ankle=rig.matrix_world@rig.pose.bones['foot.'+s].head;sole=ankle-Vector((0,0,.08))
                maxik=max(maxik,(ankle-feet[s].matrix_world.translation).length);minfloor=min(minfloor,sole.z)
                if contact[s]:
                    maxfoot=max(maxfoot,abs(sole.z));world=sole+B((c.get('stride',0)*t,0,0));key=(s,math.floor(t+off+1e-8))
                    if key not in groups:groups[key]=world.copy()
                    drift=max(drift,(world-groups[key]).length)
            if name in ('lock-door','lock-chest','loot'):
                for s in ['L','R']:maxik=max(maxik,(rig.matrix_world@rig.pose.bones['forearm.'+s].tail-hand_targets[s].matrix_world.translation).length)
    if c['loop']:loop_error=max(abs(a-b) for k in first for a,b in zip(first[k],last[k]))
    metrics[name]={'samples':121,'max_bone_error':maxbone,'max_target_error':maxik,'stance_floor_error':maxfoot,'stance_drift':drift,'min_sole':minfloor if minfloor<100 else None,'loop_error':loop_error}
    print(name,metrics[name],flush=True)
    assert maxbone<1e-4 and maxik<.003 and maxfoot<.003 and drift<.003 and loop_error<1e-4,(name,metrics[name])
(OUT/'rig-validation.json').write_text(json.dumps(metrics,indent=2))

# Bake editable clips in one named timeline, separated by two guard frames.
frame=1
for name,c in CLIPS.items():
    n=round(c['seconds']*60);c['timeline']=[frame,frame+n]
    ts={i/n for i in range(n+1)}
    if name=='walk':ts.update([.1,.6])
    if name=='run':ts.update([.3,.8])
    for t in sorted(ts):
        pose(name,t);key=frame+t*n
        for obj in [root,rig]+list(feet.values())+list(hand_targets.values()):
            obj.keyframe_insert('location',frame=key)
            if obj==rig:obj.keyframe_insert('rotation_quaternion',frame=key)
        for pb in rig.pose.bones:
            pb.keyframe_insert('rotation_quaternion',frame=key)
            for co in pb.constraints:co.keyframe_insert('influence',frame=key)
        for o in tools:o.keyframe_insert('hide_render',frame=key)
    scene.timeline_markers.new(name,frame=frame);frame+=n+3
for a in bpy.data.actions:
    for layer in a.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fc in bag.fcurves:
                    for k in fc.keyframe_points:k.interpolation='LINEAR'
scene.frame_start=1;scene.frame_end=frame-1;scene.render.fps=60
root.rotation_euler.z=0;scene.frame_set(1);bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'vulpin-all-actions.blend'))
# Render analytical evaluated poses, independent of playback interpolation.
for o in bpy.data.objects:o.animation_data_clear()
for d,angle in DIRS.items():
    root.rotation_euler.z=math.radians(angle);manifest['poses'][d]={}
    for name,c in CLIPS.items():
        if name=='dead':continue
        folder=OUT/'renders'/d/name;folder.mkdir(parents=True,exist_ok=True);data=[]
        for i in range(c['source']):
            t=i/(c['source'] if c['loop'] else c['source']-1)
            contact=pose(name,t);data.append({'t':t,'contact':contact,'feet':{s:screen(rig.matrix_world@rig.pose.bones['foot.'+s].head-Vector((0,0,.08))) for s in ['L','R']}})
            scene.render.filepath=str(folder/f'{i:02d}.png')
            if name in ('run','death'):bpy.ops.render.render(write_still=True)
            else:shutil.copy2(OUT.parent/'v7-complete-budget'/'renders'/d/name/f'{i:02d}.png',scene.render.filepath)
        manifest['poses'][d][name]=data
        print('RENDERED',d,name,c['source'],flush=True)
(OUT/'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print('COMPLETE_ALL_ACTIONS',flush=True)
