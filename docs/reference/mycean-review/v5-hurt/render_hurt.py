"""Backward whole-model recoil; planted boots, retained staff and exact recovery."""
import sys
from pathlib import Path
OUT=Path(__file__).parent;sys.path.insert(0,str(OUT))
from rig import *
OUT=Path(__file__).parent
TIMING=[65,65,90,115,100,95,90,100]
PHASES=['Ready','Impact','Recoil','Brace','Return','Recover','Balance','Ready']
STRENGTH=[0,.35,.85,1,.82,.45,.15,0]
PITCH=[0,-5,-12,-17,-14,-8,-3,0]
staff=props['staff'];STAFF_BASIS=staff.matrix_basis.copy()
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
    q=rot((0,0,1),-2*s)@rot((1,0,0),PITCH[i])
    pivot=H['Bone_000'];shift=Vector((0,.026*s,-.070*s))
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
    set_world('Bone_017',neck,rot((0,0,1),-2*s)@rot((1,0,0),PITCH[i]*.75))
    for side,(upper,fore,wrist) in ARMS.items():
        sign=1 if side=='L' else -1;shoulder=(arm.matrix_world@arm.pose.bones[upper].head).copy()
        delta=Vector((sign*.025*s,-.05*s,.10*s)) if side=='L' else Vector((.035*s,-.10*s,.13*s))
        target=point(WRISTS[side]+delta)
        elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector((sign,.1,-.1)))
        aim(upper,shoulder,elbow,H[fore])
        transport=(q@FORE_AXIS[side]).rotation_difference((end-elbow).normalized())
        set_world(fore,elbow,transport@q@FORE_Q[side])
        wrist_q=rot((1,0,0),8*s)@WRIST_Q[side] if side=='L' else q@rot((1,0,0),-12*s)@WRIST_Q[side]
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
      'feet':{s:list(feet_position(s)) for s in SOLE},'attachment_errors':errors,
      'finite':all(math.isfinite(c) for v in p+sp for c in v)}

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
    bpy.context.view_layer.update();p=world_to_camera_view(scene,cam,root);return[p.x*512,(1-p.y)*512]

report={'source_scene_sha256':SOURCE_HASH,'durations_ms':TIMING,'phases':PHASES,'master_size':512,'sprite_size':256,'ortho_scale':2.6,'target_z':.72,
 'hero_scale':.85*2.6/2.35,'poses':[],'views':{},'contacts':{s:list(p) for s,p in CONTACTS.items()},
 'approved_attachments':{n:[list(row) for row in m] for n,m in RELATIVE.items()}}
for i in range(8):
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
scene.frame_start=1;scene.frame_end=8;scene.render.fps=15
for view in VIEWS:report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view]}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
assert all(p['finite'] and p['full_body_crossings']==0 and p['body_bounds'][0][2]>-.0001 and p['staff_bounds'][0][2]>0 for p in report['poses']), 'Invalid pose: inspect contact measurements'
assert all((Vector(p['feet'][s])-CONTACTS[s]).length<.0002 for p in report['poses'] for s in SOLE), 'Support slide'
scene.frame_set(1);camera('se');bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mycean-hurt-poses.blend'),compress=True)
pilot='--pilot' in sys.argv
for view in ([] if '--poses-only' in sys.argv else ['se','nw'] if pilot else VIEWS):
    camera(view)
    for i in range(8):
        if pilot and i not in (0,3,5):continue
        scene.frame_set(i+1);bpy.context.view_layer.update()
        pts=[v for o in [body,staff] for v in geometry(o)[0]]
        assert all(.015<(q:=world_to_camera_view(scene,cam,v)).x<.985 and .015<q.y<.985 for v in pts),(view,i,'clipped')
        folder=OUT/'masters'/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f'hurt-{i:02}.png');bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('MYCEAN_HURT_RENDERED',len(report['poses']),'poses',flush=True)
