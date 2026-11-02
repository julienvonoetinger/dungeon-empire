"""Offensive spore orb wind-up and staff thrust; whole-model held poses and measured cap emitter."""
import sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from rig import *
OUT=Path(__file__).parent
TIMING=[100,100,120,130,200,100,100,100,100,100,130,120]
PHASES=['Ready','Draw back','Gather spores','Charge','Hold charge','Cast','Follow-through','Recoil','Impact','Recover','Lower staff','Ready']
# compression, body pitch, body yaw, wrist lift, wrist forward, wrist outward, staff pitch, staff outward
POSES=[(0,0,0,0,0,0,0,0),
 (.015,-2,-4,.06,.06,.04,8,0),
 (.03,-4,-8,.12,.12,.07,14,0),
 (.045,-6,-12,.18,.20,.10,20,0),
 (.045,-6,-12,.18,.20,.10,20,0),
 (.055,8,4,.15,-.23,.06,68,-15),
 (.045,6,3,.13,-.21,.06,62,-15),
 (.035,4,2,.12,-.17,.05,52,-15),
 (.025,2,0,.10,-.12,.04,40,-12),
 (.015,1,0,.07,-.08,.03,25,-8),
 (.005,0,0,.03,-.04,.01,10,-3),
 (0,0,0,0,0,0,0,0)]
STRENGTH=[max(abs(p[1])/8,p[3]/.18) for p in POSES]
PITCH=[p[1] for p in POSES]
SOURCE_INDICES=[POSES.index(p) for p in POSES]
staff=props['staff'];STAFF_BASIS=staff.matrix_basis.copy()
cap_z=max(v.co.z for v in staff.data.vertices)
cap_points=[v.co for v in staff.data.vertices if v.co.z>cap_z-.025]
EMITTER=sum(cap_points,Vector())/len(cap_points);EMITTER.z=cap_z+.012
base_feet,_=geometry(sole_probe)
CONTACTS={s:Vector((sum(base_feet[i].x for i in ids)/len(ids),sum(base_feet[i].y for i in ids)/len(ids),min(base_feet[i].z for i in ids))) for s,ids in SOLE.items()}

def reset():
    arm.location=(0,0,0)
    for p in arm.pose.bones:p.matrix_basis=APPROVED[p.name];p.rotation_mode='QUATERNION'
    staff.matrix_basis=STAFF_BASIS
    bpy.context.view_layer.update()

def feet_position(side):
    p,_=geometry(sole_probe);ids=SOLE[side]
    return Vector((sum(p[i].x for i in ids)/len(ids),sum(p[i].y for i in ids)/len(ids),min(p[i].z for i in ids)))

def pose(i):
    reset();s=STRENGTH[i]
    if not s:return
    compression,pitch,yaw,lift,forward,outward,staff_pitch,staff_out=POSES[i]
    q=rot((0,0,1),yaw)@rot((1,0,0),pitch)
    pivot=H['Bone_000'];shift=Vector((0,0,-compression))
    point=lambda p:pivot+q@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,q)
    for side,(upper,lower,foot) in LEGS.items():
        hip=point(H[upper]);target=H[foot].copy();sign=1 if side=='L' else -1
        for attempt in range(24):
            knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,Vector((sign*.5,-1,0)))
            aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,Quaternion())
            error=CONTACTS[side]-feet_position(side)
            if error.length<.00004:break
            target=end+error
    # Neck follows the impact, with less excursion than the trunk under the cap.
    neck=(arm.matrix_world@arm.pose.bones['Bone_017'].head).copy()
    set_world('Bone_017',neck,rot((0,0,1),yaw*.5)@rot((1,0,0),pitch*.7))
    for side,(upper,fore,wrist) in ARMS.items():
        sign=1 if side=='L' else -1;shoulder=(arm.matrix_world@arm.pose.bones[upper].head).copy()
        delta=Vector((outward,forward,lift)) if side=='L' else Vector((-.10*s,-.18*s,.14*s))
        target=point(WRISTS[side]+delta)
        elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector((sign,.1,-.1)))
        aim(upper,shoulder,elbow,H[fore])
        transport=(q@FORE_AXIS[side]).rotation_difference((end-elbow).normalized())
        set_world(fore,elbow,transport@q@FORE_Q[side])
        wrist_q=rot((0,1,0),staff_out)@rot((1,0,0),staff_pitch)@WRIST_Q[side] if side=='L' else q@rot((1,0,0),-35*s)@WRIST_Q[side]
        set_world(wrist,end,wrist_q)

def measure(i):
    p,tri=geometry(body);sp,st=geometry(staff)
    hits=crossings(p,tri,sp,st,True)|crossings(sp,st,p,tri,True)
    errors={}
    for name,obj in attachments.items():
        rel=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        errors[name]=max(abs(rel[j][k]-RELATIVE[name][j][k]) for j in range(4) for k in range(4))
    joints={n:list(arm.matrix_world@arm.pose.bones[n].head) for n in ['Bone_000','Bone_017','Bone_023','Bone_031']}
    return {'frame':i+1,'index':i,'phase':PHASES[i],'strength':STRENGTH[i],'pitch':PITCH[i],
      'body_bounds':bounds(p),'staff_bounds':bounds(sp),'bounds':bounds(p+sp),'joints':joints,
      'full_body_crossings':len(hits),'contact_bounds':bounds([Vector(x) for x in hits]) if hits else [],
      'emitter_world':list(staff.matrix_world@EMITTER),'feet':{s:list(feet_position(s)) for s in SOLE},'attachment_errors':errors,
      'finite':all(math.isfinite(c) for v in p+sp for c in v)}

scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.cycles.seed=0;scene.cycles.use_animated_seed=False
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=3.25
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy()) for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update();p=world_to_camera_view(scene,cam,root);return[p.x*640,(1-p.y)*640]

report={'source_scene_sha256':SOURCE_HASH,'durations_ms':TIMING,'phases':PHASES,'master_size':640,'sprite_size':320,'ortho_scale':3.25,'target_z':.72,
 'hero_scale':.85*2.6/2.35,'source_indices':SOURCE_INDICES,'poses':[],'views':{},'contacts':{s:list(p) for s,p in CONTACTS.items()},
 'approved_attachments':{n:[list(row) for row in m] for n,m in RELATIVE.items()}}
for i in range(12):
    scene.frame_set(i+1);pose(i);entry=measure(i);report['poses'].append(entry)
    print('POSE',i,'hits',entry['full_body_crossings'],entry['contact_bounds'],'feet',entry['feet'],'floor',entry['body_bounds'][0][2],entry['staff_bounds'][0][2],flush=True)
    for bone in arm.pose.bones:
        for channel in ('location','rotation_quaternion','scale'):bone.keyframe_insert(channel,frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
for layer in arm.animation_data.action.layers:
    for strip in layer.strips:
        if hasattr(strip,'channelbags'):
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=12;scene.render.fps=15
for view in VIEWS:
    report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view],'emitters':[]}
    for i in range(12):
        scene.frame_set(i+1);bpy.context.view_layer.update()
        e=world_to_camera_view(scene,cam,staff.matrix_world@EMITTER)
        report['views'][view]['emitters'].append([e.x*640,(1-e.y)*640])
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
assert all(p['finite'] and p['full_body_crossings']==0 and p['body_bounds'][0][2]>-.0001 and p['staff_bounds'][0][2]>0 for p in report['poses']), 'Invalid pose: inspect contact measurements'
assert all((Vector(p['feet'][s])-CONTACTS[s]).length<.0002 for p in report['poses'] for s in SOLE), 'Support slide'
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mycean-attack-poses.blend'),compress=True)
pilot='--pilot' in sys.argv
for view in ([] if '--poses-only' in sys.argv else ['se','nw'] if pilot else VIEWS):
    camera(view)
    for i in range(12):
        if SOURCE_INDICES[i]!=i:continue
        if pilot and i not in (3,5):continue
        scene.frame_set(i+1);bpy.context.view_layer.update()
        pts=[v for o in [body,staff] for v in geometry(o)[0]]
        assert all(.015<(q:=world_to_camera_view(scene,cam,v)).x<.985 and .015<q.y<.985 for v in pts),(view,i,'clipped')
        folder=OUT/'masters'/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f'attack-{i:02}.png');bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('MYCEAN_ATTACK_RENDERED',len(report['poses']),'poses',flush=True)
