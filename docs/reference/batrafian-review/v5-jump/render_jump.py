"""Twelve whole-mesh held poses. Altitude/travel are separate sprite motion.
Run in a dedicated background Blender; never in the user's live scene.
"""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,bounds,crossings
SOURCE=OUT.parent/'v3-equipment-orientation/batrafian-equipped-review.blend'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and o.name.startswith('batrafian_')and any(m.type=='ARMATURE'for m in o.modifiers))
props={n:next(o for o in scene.objects if o.type=='MESH'and o.name.startswith(n+'_'))for n in ('bow','quiver')}
arm.animation_data_clear()
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
APPROVED={p.name:p.matrix_basis.copy()for p in arm.pose.bones}
ARMS={'R':('Bone_021','Bone_020','Bone_019'),'L':('Bone_025','Bone_024','Bone_023')}
LEGS={'R':('Bone_009','Bone_008','Bone_007'),'L':('Bone_014','Bone_013','Bone_012')}
WRISTS={s:arm.matrix_world@arm.pose.bones[n[2]].head for s,n in ARMS.items()}
WRIST_Q={s:(arm.matrix_world@arm.pose.bones[n[2]].matrix).to_quaternion()@R[n[2]].to_quaternion().inverted()for s,n in ARMS.items()}
FORE_Q={s:(arm.matrix_world@arm.pose.bones[n[1]].matrix).to_quaternion()@R[n[1]].to_quaternion().inverted()for s,n in ARMS.items()}
FORE_AXIS={s:(WRISTS[s]-arm.matrix_world@arm.pose.bones[n[1]].head).normalized()for s,n in ARMS.items()}
RELATIVE={n:(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world for n,o in props.items()}
SOLE={s:[v.index for v in body.data.vertices if (p:=body.matrix_world@v.co).z<.13 and (p.x>0)==(s=='L')]for s in LEGS}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,tri=geometry(body)
NONHAND={'bow':[t for t in tri if not any(dominant[i]in ('Bone_023','Bone_022')for i in t)],'quiver':tri}
# One second including anticipation/recovery, matching the existing ranger rule.
DURATIONS=[60,70,70,60,80,90,90,80,70,70,100,160]
PHASES=['Ready','Gather','Crouch','Push off','Rise','Tuck','Apex','Descend','Reach','Land','Absorb','Ready']
# bob, lean, foot_y, foot_lift, foot_pitch, outward_offset, wrist_raise, free_hand_forward
POSES=[(0,0,0,0,0,0,0,0),(-.07,5,0,0,0,.01,.07,-.02),
 (-.17,10,.02,0,0,.03,.16,-.06),(-.035,12,.04,0,7,.02,.10,-.07),
 (0,9,.10,.10,8,.035,.08,-.05),(0,5,.06,.18,5,.045,.06,-.04),
 (0,2,.03,.23,0,.05,.04,-.03),(0,0,-.04,.14,-3,.035,.03,-.02),
 (0,-3,-.10,.04,-4,.01,.03,-.02),(-.05,4,-.04,0,0,.01,.06,-.03),
 (-.14,8,0,0,0,.025,.13,-.04),(0,0,0,0,0,0,0,0)]
STARTS=[sum(DURATIONS[:i])/1000 for i in range(len(DURATIONS))]
LAUNCH=.2;LAND=.67;APEX=.55

def height(t):
    u=max(0,min(1,(t-LAUNCH)/(LAND-LAUNCH)))
    return 4*APEX*u*(1-u)

def set_world(name,head,q):
    m=q.to_matrix().to_4x4()@R[name];m.translation=head
    arm.pose.bones[name].matrix=AI@m;bpy.context.view_layer.update()

def aim(name,head,end,rest_end):
    set_world(name,head,(rest_end-H[name]).normalized().rotation_difference((end-head).normalized()))

def solve(root,end,l1,l2,pole):
    delta=end-root;distance=delta.length
    if distance>=l1+l2-.001:end=root+delta.normalized()*(l1+l2-.001);delta=end-root;distance=delta.length
    direction=delta.normalized();a=(l1*l1-l2*l2+distance*distance)/(2*distance)
    p=pole-direction*direction.dot(pole)
    return root+direction*a+p.normalized()*math.sqrt(max(0,l1*l1-a*a)),end

def apply_pose(i):
    for p in arm.pose.bones:p.rotation_mode='QUATERNION';p.matrix_basis=APPROVED[p.name]
    arm.location=(0,0,0);bpy.context.view_layer.update()
    bob,tilt,fy,lift,pitch,width,hand_up,hand_forward=POSES[i]
    lean=Quaternion((1,0,0),math.radians(tilt));pivot=H['Bone_000'];shift=Vector((0,0,bob))
    def bodypoint(p):return pivot+lean@(p-pivot)+shift
    set_world('Bone_000',pivot+shift,lean)
    for side,(upper,lower,foot)in LEGS.items():
        sign=1 if side=='L'else -1
        hip=bodypoint(H[upper]);target=H[foot]+Vector((sign*width,fy,lift))
        pole=Vector((sign*1.2,-1,0))
        knee,end=solve(hip,target,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,pole)
        foot_q=Quaternion((1,0,0),math.radians(pitch))
        for attempt in range(16):
            aim(upper,hip,knee,H[lower]);aim(lower,knee,end,H[foot]);set_world(foot,end,foot_q)
            p,_=geometry(body);error=lift-min(p[j].z for j in SOLE[side])
            if abs(error)<.00005:break
            end.z+=error
            knee,end=solve(hip,end,(H[lower]-H[upper]).length,(H[foot]-H[lower]).length,pole)
    for side,(upper,fore,wrist)in ARMS.items():
        sign=1 if side=='L'else -1
        shoulder=bodypoint(H[upper])
        target=bodypoint(WRISTS[side])+Vector((0,hand_forward if side=='R'else -.015*tilt/10,hand_up))
        elbow,end=solve(shoulder,target,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector((sign,.1,-.1)))
        aim(upper,shoulder,elbow,H[fore])
        transport=(lean@FORE_AXIS[side]).rotation_difference((end-elbow).normalized())
        set_world(fore,elbow,transport@lean@FORE_Q[side]);set_world(wrist,end,lean@WRIST_Q[side])
    p,_=geometry(body);allp=p.copy();equipment={}
    for n,o in props.items():
        q,qt=geometry(o);allp+=q
        rel=(arm.matrix_world@arm.pose.bones[o.parent_bone].matrix).inverted()@o.matrix_world
        equipment[n]={'bounds':bounds(q),'grip_error':max(abs(rel[j][k]-RELATIVE[n][j][k])for j in range(4)for k in range(4)),
          'nonhand_crossings':crossings(q,qt,p,NONHAND[n])+crossings(p,NONHAND[n],q,qt)}
    return {'frame':i+1,'phase':PHASES[i],'time':STARTS[i],'root_height':height(STARTS[i]),'local_sole_target':lift,
      'soles':{s:min(p[j].z for j in ids)for s,ids in SOLE.items()},'body_bounds':bounds(p),'bounds':bounds(allp),
      'finite':all(math.isfinite(c)for v in allp for c in v),'equipment':equipment}

scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
cam=scene.camera;cam.data.type='ORTHO';cam.data.ortho_scale=2.6
root=Vector((0,-.20,0));target=root+Vector((0,0,.72))
VIEWS={'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
lights=[(bpy.data.objects[n],bpy.data.objects[n].matrix_world.copy())for n in ('Key','Fill','Rim')]
def camera(view):
    cam.location=target+Vector(VIEWS[view]).normalized()*8;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    angle=math.atan2(VIEWS[view][1],VIEWS[view][0])-math.atan2(-1,-1)
    for light,base in lights:light.matrix_world=Matrix.Rotation(angle,4,'Z')@base
    bpy.context.view_layer.update();q=world_to_camera_view(scene,cam,root)
    return [q.x*512,(1-q.y)*512]

report={'source_scene_sha256':SOURCE_HASH,'master_size':512,'sprite_size':256,'ortho_scale':2.6,'hero_scale':.85*2.6/2.35,
 'target_z':.72,'durations_ms':DURATIONS,'phases':PHASES,'launch_time':LAUNCH,'land_time':LAND,'apex_height':APEX,
 'root_motion':'Unbaked: continuous two-cell ground travel and parabolic altitude only during flight',
 'approved_attachments':{n:[list(row)for row in m]for n,m in RELATIVE.items()},'poses':[],'views':{}}
for i in range(12):
    scene.frame_set(i+1);report['poses'].append(apply_pose(i))
    for p in arm.pose.bones:
        for channel in ('location','rotation_quaternion','scale'):p.keyframe_insert(channel,frame=i+1)
    arm.keyframe_insert('location',frame=i+1)
action=arm.animation_data.action;action.name='Batrafian_Jump_Held_Poses'
for layer in action.layers:
    for strip in layer.strips:
        if hasattr(strip,'channelbags'):
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:key.interpolation='CONSTANT'
scene.frame_start=1;scene.frame_end=12;scene.render.fps=12
for view in VIEWS:report['views'][view]={'anchor_px':camera(view),'camera_vector':VIEWS[view]}
(OUT/'poses.json').write_text(json.dumps(report,indent=2)+'\n')
pilot='--pilot'in sys.argv
for view in ([]if '--poses-only'in sys.argv else ['sw','ne']if pilot else VIEWS):
    camera(view)
    for i in range(12):
        if pilot and i not in (2,6,10):continue
        scene.frame_set(i+1);bpy.context.view_layer.update()
        allp=[v for o in [body,*props.values()]for v in geometry(o)[0]]
        assert all(.015<(q:=world_to_camera_view(scene,cam,v)).x<.985 and .015<q.y<.985 for v in allp),(view,i,'clipped')
        folder=OUT/'masters'/view;folder.mkdir(parents=True,exist_ok=True)
        scene.render.filepath=str(folder/f'jump-{i:02}.png');bpy.ops.render.render(write_still=True)
scene.frame_set(1);camera('se');bpy.ops.file.pack_all()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'batrafian-jump-poses.blend'),compress=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH
print('BATRAFIAN_JUMP_POSES',json.dumps([{'frame':p['frame'],'soles':p['soles'],'min_z':p['bounds'][0][2],
 'hits':{n:e['nonhand_crossings']for n,e in p['equipment'].items()}}for p in report['poses']]))
