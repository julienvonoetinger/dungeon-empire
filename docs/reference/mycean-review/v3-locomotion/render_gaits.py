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

SOURCE=OUT.parent/'v2-meshy-inspection/mycean-equipped-review.blend'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('mycean_') and o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
props={'staff':bpy.data.objects['staff_output_unwrapped']}
attachments={name:bpy.data.objects[name] for name in ('staff_output_unwrapped','MyceanGripCorrective','StaffGripContactEnvelope')}
arm.animation_data_clear()
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
APPROVED={p.name:p.matrix_basis.copy() for p in arm.pose.bones}
ARMS={'R':('Bone_025','Bone_024','Bone_023'),'L':('Bone_033','Bone_032','Bone_031')}
LEGS={'R':('Bone_006','Bone_005','Bone_004'),'L':('Bone_015','Bone_014','Bone_013')}
WRISTS={s:arm.matrix_world@arm.pose.bones[names[2]].head for s,names in ARMS.items()}
WRIST_Q={s:(arm.matrix_world@arm.pose.bones[names[2]].matrix).to_quaternion()@R[names[2]].to_quaternion().inverted() for s,names in ARMS.items()}
# The approved palm shares weights with its forearm. Transport that forearm's
# full orientation, including axial roll, rather than rebuilding a minimal aim.
FORE_Q={s:(arm.matrix_world@arm.pose.bones[n[1]].matrix).to_quaternion()@R[n[1]].to_quaternion().inverted() for s,n in ARMS.items()}
FORE_AXIS={s:(WRISTS[s]-arm.matrix_world@arm.pose.bones[n[1]].head).normalized() for s,n in ARMS.items()}
RELATIVE={name:(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world for name,o in attachments.items()}
rest_points=[body.matrix_world@v.co for v in body.data.vertices]
SOLE={s:[i for i,v in enumerate(rest_points) if v.z<.13 and (v.x>0)==(s=='L')] for s in LEGS}
SOLE_Y={s:sum(rest_points[i].y for i in ids)/len(ids) for s,ids in SOLE.items()}
# Only hand geometry has corrective modifiers; un-subdivided sole measurements
# avoid evaluating the dense render mesh during each leg IK iteration.
sole_probe=body.copy();sole_probe.name='MyceanSoleProbe';scene.collection.objects.link(sole_probe)
for modifier in list(sole_probe.modifiers):
    if modifier.type!='ARMATURE':sole_probe.modifiers.remove(modifier)
sole_probe.hide_render=True;sole_probe.hide_set(True)
GAITS={
 'walk':{'fps':15,'speed':1.125,'offset':[-.15,-.075,0,.075,.15,.10,0,-.10],
         'lift':[0,0,0,0,0,.055,.10,.055],'bob':[-.060,-.065,-.060,-.045]*2,
         'pitch':[0,0,0,0,0,10,0,-6],'lean':2,'swing':.035,'roll':.7,'carry_lift':.075,'staff_swing':.008,'staff_outward':0,'staff_pitch':0},
 'run':{'fps':16,'speed':1.6,'offset':[-.20,-.10,0,.13,.16,.04,-.13,-.20],
        'lift':[0,0,0,.080,.14,.16,.12,.060],'bob':[-.130,-.090,-.065,-.015]*2,
        'pitch':[0,0,0,12,15,5,-3,-5],'lean':5,'swing':.060,'roll':1.0,'carry_lift':.10,'staff_swing':.014,'staff_outward':-15,'staff_pitch':42}}

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
        # Short booted legs bend slightly outward beneath the leaf tunic.
        k=index if side=='L' else (index+4)%8
        hip=bodypoint(H[upper]);target=H[foot]+Vector((0,cfg['offset'][k],cfg['lift'][k]))
        knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((.5 if side=='L' else -.5,-1,0)))
        aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot])
        foot_q=Quaternion((1,0,0),math.radians(cfg['pitch'][k]));set_world(foot,end,foot_q)
        feet[side]={'phase':k,'grounded':cfg['lift'][k]==0,'target_error':(end-target).length,'ankle':list(end)}
        # Register the actual boot sole to its requested height. Correct only
        # this leg; never slide the whole body to hide a ground intersection.
        for _ in range(12):
            p,_=geometry(sole_probe);low=min(p[i].z for i in SOLE[side]);error=cfg['lift'][k]-low
            travel_error=SOLE_Y[side]+cfg['offset'][k]-sum(p[i].y for i in SOLE[side])/len(SOLE[side]) if feet[side]['grounded'] else 0
            if abs(error)<.00005 and abs(travel_error)<.00005:break
            end.z+=error;end.y+=travel_error
            knee,end=solve(hip,end,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((.5 if side=='L' else -.5,-1,0)))
            aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,foot_q)
        feet[side]['ankle']=list(end)
    for side,(upper,fore,wrist) in ARMS.items():
        sign=1 if side=='L' else -1;swing=math.cos(phase)*sign
        shoulder=bodypoint(H[upper])
        amplitude=cfg['staff_swing'] if side=='L' else cfg['swing']
        carry=cfg['carry_lift'] if side=='L' else 0
        wrist_target=bodypoint(WRISTS[side]+Vector((0,amplitude*swing,carry+.008*math.sin(phase))))
        elbow,end=solve(shoulder,wrist_target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector((sign,.1,-.1)))
        aim(upper,shoulder,elbow,H[fore])
        transport=(lean@FORE_AXIS[side]).rotation_difference((end-elbow).normalized())
        set_world(fore,elbow,transport@lean@FORE_Q[side])
        outward=Quaternion((0,1,0),math.radians(cfg['staff_outward'] if side=='L' else 0))
        forward_tilt=Quaternion((1,0,0),math.radians(cfg['staff_pitch'] if side=='L' else 0))
        q=lean@forward_tilt@outward@Quaternion((1,0,0),math.radians((.6 if side=='L' else 3.0)*swing))@WRIST_Q[side]
        set_world(wrist,end,q)
    bpy.context.view_layer.update()
    sole_points,_=geometry(sole_probe);soles={s:min(sole_points[i].z for i in ids) for s,ids in SOLE.items()}
    p,tri=geometry(body)
    allp=p.copy();equipment={}
    for name,o in props.items():
        op,ot=geometry(o);allp+=op
        rel=(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world
        err=max(abs(rel[i][j]-RELATIVE[o.name][i][j]) for i in range(4)for j in range(4))
        hit=crossings(op,ot,p,tri)+crossings(p,tri,op,ot)
        equipment[name]={'grip_error':err,'full_body_crossings':hit,'bounds':bounds(op),'floor_min_z':min(v.z for v in op)}
        if any(a.startswith('--check-pose=') for a in sys.argv):
            hitpoints=crossings(op,ot,p,tri,True)|crossings(p,tri,op,ot,True)
            equipment[name]['contact_bounds']=bounds(list(hitpoints)) if hitpoints else []
    attachment_errors={}
    for name,obj in attachments.items():
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        attachment_errors[name]=max(abs(rel[i][j]-RELATIVE[name][i][j]) for i in range(4)for j in range(4))
    return {'gait':gait,'index':index,'feet':feet,'sole_min_z':soles,'sole_mean_y':{s:sum(sole_points[i].y for i in ids)/len(ids) for s,ids in SOLE.items()},
      'airborne':not any(f['grounded'] for f in feet.values()),'mesh_min_z':min(v.z for v in p),
      'finite':all(math.isfinite(c) for v in allp for c in v),'body_bounds':bounds(p),'bounds':bounds(allp),'equipment':equipment,'attachment_errors':attachment_errors}

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
 'approved_attachments':{n:[list(row) for row in m] for n,m in RELATIVE.items()},
 'hero_scale':.85*2.6/2.35,'gaits':GAITS,'views':{},'poses':[],
 'limits':'Held poses and static contact/edge intersection checks; no full motion-range or physical-device guarantee.'}
single=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--check-pose=')),None)
if single:
    gait,index=single.split(':');entry=apply_pose(gait,int(index))
    folder=OUT.parents[3]/'artifacts/mycean-gaits';folder.mkdir(parents=True,exist_ok=True)
    (folder/'single-pose.json').write_text(json.dumps(entry,indent=2)+'\n')
    print('SINGLE_POSE',gait,index,entry['equipment'],flush=True);raise SystemExit(0)
for gait_index,gait in enumerate(GAITS):
    for i in range(8):
        frame=gait_index*8+i+1;scene.frame_set(frame);entry=apply_pose(gait,i);entry['frame']=frame;report['poses'].append(entry)
        print('POSE_CHECK',gait,i,'staff crossings',entry['equipment']['staff']['full_body_crossings'],flush=True)
        for p in arm.pose.bones:
            p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
        arm.keyframe_insert('location',frame=frame)
action=arm.animation_data.action;action.name='Mycean_Walk_Run_Held_Poses'
assert all(p['finite'] and p['mesh_min_z']>-.0001 and p['equipment']['staff']['full_body_crossings']==0 and p['equipment']['staff']['floor_min_z']>0 for p in report['poses']), 'Invalid pose: inspect POSE_CHECK output before rendering'
for layer in action.layers:
    for strip in layer.strips:
        if hasattr(strip,'channelbags'):
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=16;scene.render.fps=15
for view in VIEWS:report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view]}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
pilot='--pilot' in sys.argv
for view in ([] if '--poses-only' in sys.argv else ['se','nw'] if pilot else list(VIEWS)):
    camera(view)
    for entry in report['poses']:
        if pilot and entry['index'] not in (0,3):continue
        selected_gait=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--gait=')),None)
        if selected_gait and entry['gait']!=selected_gait:continue
        scene.frame_set(entry['frame']);bpy.context.view_layer.update()
        allp=[v for ob in [body,*props.values()] for v in geometry(ob)[0]]
        assert all(.015<(q:=world_to_camera_view(scene,cam,v)).x<.985 and .015<q.y<.985 for v in allp),(view,entry['frame'],'clipped')
        folder=OUT/'masters'/entry['gait']/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f"{entry['gait']}-{entry['index']:02d}.png");bpy.ops.render.render(write_still=True)
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mycean-gait-poses.blend'),compress=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('MYCEAN_GAITS_RENDERED', 'poses-only' if '--poses-only' in sys.argv else 'pilot' if pilot else 'full',json.dumps([{'gait':p['gait'],'i':p['index'],'soles':p['sole_min_z'],'hits':{n:e['full_body_crossings'] for n,e in p['equipment'].items()},'staff_floor':p['equipment']['staff']['floor_min_z']} for p in report['poses']]))
