"""Eight explicit whole-mesh poses per gait, with the approved equipment grips.

Dedicated background Blender only. --pilot renders a small visual sample.
"""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT))
from mesh_checks import geometry,bounds,crossings

SOURCE=OUT.parent/'v3-equipment-grips/paladin-equipped-review.blend'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
props={name:next(o for o in scene.objects if o.name.startswith(name+'_') and o.type=='MESH') for name in ('hammer','shield')}
arm.animation_data_clear()
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
APPROVED={p.name:p.matrix_basis.copy() for p in arm.pose.bones}
ARMS={'R':('Bone_025','Bone_024','Bone_023'),'L':('Bone_021','Bone_020','Bone_019')}
LEGS={'R':('Bone_009','Bone_008','Bone_007'),'L':('Bone_014','Bone_013','Bone_012')}
WRISTS={s:arm.matrix_world@arm.pose.bones[names[2]].head for s,names in ARMS.items()}
WRIST_Q={s:(arm.matrix_world@arm.pose.bones[names[2]].matrix).to_quaternion()@R[names[2]].to_quaternion().inverted() for s,names in ARMS.items()}
RELATIVE={name:(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world for name,o in props.items()}
rest_points=[body.matrix_world@v.co for v in body.data.vertices]
SOLE={s:[i for i,v in enumerate(rest_points) if v.z<.13 and (v.x>0)==(s=='L')] for s in LEGS}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,body_tri=geometry(body)
NONHAND={}
for name,ids in [('hammer',[22,23,*range(38,50)]),('shield',[18,19,*range(26,38)])]:
    allowed={f'Bone_{i:03}' for i in ids}
    NONHAND[name]=[t for t in body_tri if not any(dominant[i] in allowed for i in t)]
GAITS={
 'walk':{'fps':12,'speed':.84,'offset':[-.14,-.07,0,.07,.14,.09,0,-.09],
         'lift':[0,0,0,0,0,.055,.10,.055],'bob':[-.040,-.050,-.040,-.025]*2,
         'pitch':[0,0,0,0,0,10,0,-6],'lean':2,'swing':.035,'roll':1.0},
 'run':{'fps':16,'speed':1.60,'offset':[-.21,-.11,-.01,.16,.14,.035,-.13,-.22],
        'lift':[0,0,0,.080,.19,.22,.14,.070],'bob':[-.070,-.100,-.060,.005]*2,
        'pitch':[0,0,7,25,30,18,-4,-7],'lean':8,'swing':.060,'roll':1.6}}

def set_world(name,head,q=None):
    m=R[name].copy()
    if q is not None:m=q.to_matrix().to_4x4()@m
    m.translation=head;arm.pose.bones[name].matrix=AI@m;bpy.context.view_layer.update()
def aim(name,head,end,rest_end):
    q=(rest_end-H[name]).normalized().rotation_difference((end-head).normalized());set_world(name,head,q)
def solve(root,end,l1,l2,pole):
    delta=end-root;distance=delta.length
    if distance>=l1+l2-.001:end=root+delta.normalized()*(l1+l2-.001);delta=end-root;distance=delta.length
    direction=delta.normalized();a=(l1*l1-l2*l2+distance*distance)/(2*distance)
    height=math.sqrt(max(0,l1*l1-a*a));p=pole-direction*direction.dot(pole)
    return root+direction*a+p.normalized()*height,end

def apply_pose(gait,index):
    cfg=GAITS[gait];arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=APPROVED[p.name];p.rotation_mode='QUATERNION'
    bpy.context.view_layer.update()
    phase=index*math.tau/8
    shift=Vector((.012*math.cos(phase),0,cfg['bob'][index]))
    lean=Quaternion((0,1,0),math.radians(cfg['roll']*math.cos(phase)))@Quaternion((1,0,0),math.radians(cfg['lean']))
    pivot=H['Bone_000']
    def bodypoint(p):return pivot+lean@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,lean)
    feet={}
    for side,(upper,lower,foot) in LEGS.items():
        k=index if side=='L' else (index+4)%8
        hip=bodypoint(H[upper]);target=H[foot]+Vector((0,cfg['offset'][k],cfg['lift'][k]))
        knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((0,-1,0)))
        aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot])
        foot_q=Quaternion((1,0,0),math.radians(cfg['pitch'][k]));set_world(foot,end,foot_q)
        feet[side]={'phase':k,'grounded':cfg['lift'][k]==0,'target_error':(end-target).length,'ankle':list(end)}
        # Register the actual boot, including its pitched toe, to the requested
        # sole height. Correct this leg only; never slide the whole body.
        for _ in range(12):
            p,_=geometry(body);low=min(p[i].z for i in SOLE[side]);error=cfg['lift'][k]-low
            if abs(error)<.00005:break
            end.z+=error
            knee,end=solve(hip,end,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((0,-1,0)))
            aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,foot_q)
        feet[side]['ankle']=list(end)
    for side,(upper,fore,wrist) in ARMS.items():
        sign=1 if side=='L' else -1;swing=math.cos(phase)*sign
        shoulder=bodypoint(H[upper])
        wrist_target=bodypoint(WRISTS[side]+Vector((0,cfg['swing']*swing,.008*math.sin(phase))))
        elbow,end=solve(shoulder,wrist_target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector((sign,.1,-.1)))
        aim(upper,shoulder,elbow,H[fore]);aim(fore,elbow,end,H[wrist])
        q=lean@Quaternion((1,0,0),math.radians((1.5 if gait=='walk' else 3.0)*swing))@WRIST_Q[side]
        set_world(wrist,end,q)
    bpy.context.view_layer.update()
    p,tri=geometry(body);soles={s:min(p[i].z for i in ids) for s,ids in SOLE.items()}
    allp=p.copy();equipment={}
    for name,o in props.items():
        op,ot=geometry(o);allp+=op
        rel=(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world
        err=max(abs(rel[i][j]-RELATIVE[name][i][j]) for i in range(4)for j in range(4))
        hit=crossings(op,ot,p,NONHAND[name])+crossings(p,NONHAND[name],op,ot)
        equipment[name]={'grip_error':err,'nonhand_crossings':hit,'bounds':bounds(op)}
    return {'gait':gait,'index':index,'feet':feet,'sole_min_z':soles,
      'airborne':not any(f['grounded'] for f in feet.values()),'mesh_min_z':min(v.z for v in p),
      'finite':all(math.isfinite(c) for v in allp for c in v),'body_bounds':bounds(p),'bounds':bounds(allp),'equipment':equipment}

scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=2.6
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy()) for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update();q=world_to_camera_view(scene,cam,root)
    return [q.x*512,(1-q.y)*512]

report={'source_scene_sha256':SOURCE_HASH,'frame_count':8,'master_size':512,'sprite_size':256,'ortho_scale':2.6,
 'hero_scale':.85*2.6/2.35,'gaits':GAITS,'views':{},'poses':[],
 'limits':'Held poses and static contact/edge intersection checks; no full motion-range or physical-device guarantee.'}
for gait_index,gait in enumerate(GAITS):
    for i in range(8):
        frame=gait_index*8+i+1;scene.frame_set(frame);entry=apply_pose(gait,i);entry['frame']=frame;report['poses'].append(entry)
        for p in arm.pose.bones:
            p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
        arm.keyframe_insert('location',frame=frame)
action=arm.animation_data.action;action.name='Paladin_Walk_Run_Held_Poses'
for layer in action.layers:
    for strip in layer.strips:
        if hasattr(strip,'channelbags'):
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=16;scene.render.fps=12
for view in VIEWS:report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view]}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
pilot='--pilot' in sys.argv
for view in (['se','nw'] if pilot else list(VIEWS)):
    camera(view)
    for entry in report['poses']:
        if pilot and entry['index'] not in (0,3):continue
        scene.frame_set(entry['frame']);bpy.context.view_layer.update()
        allp=[v for ob in [body,*props.values()] for v in geometry(ob)[0]]
        assert all(.015<(q:=world_to_camera_view(scene,cam,v)).x<.985 and .015<q.y<.985 for v in allp),(view,entry['frame'],'clipped')
        folder=OUT/'masters'/entry['gait']/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f"{entry['gait']}-{entry['index']:02d}.png");bpy.ops.render.render(write_still=True)
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'paladin-gait-poses.blend'),compress=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('PALADIN_GAITS_RENDERED', 'pilot' if pilot else 'full',json.dumps([{'gait':p['gait'],'i':p['index'],'soles':p['sole_min_z'],'hits':{n:e['nonhand_crossings'] for n,e in p['equipment'].items()}} for p in report['poses']]))
