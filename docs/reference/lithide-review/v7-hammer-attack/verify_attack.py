"""Independent reload validation, including collision with the physical target."""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
sys.path.insert(0,str(OUT.parent/'v4-locomotion'))
from mesh_checks import geometry,crossings
bpy.ops.wm.open_mainfile(filepath=str(OUT/'paladin-attack-poses.blend'))
scene=bpy.context.scene
report=json.loads((OUT/'poses.json').read_text())
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH'and any(m.type=='ARMATURE'for m in o.modifiers))
props={n:next(o for o in scene.objects if o.name.startswith(n+'_')and o.type=='MESH')for n in ('hammer','shield')}
dominant=[body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name for v in body.data.vertices]
_,tri=geometry(body);nonhand={}
for name,ids in [('hammer',[22,23,*range(38,50)]),('shield',[18,19,*range(26,38)])]:
    allowed={f'Bone_{i:03}'for i in ids};nonhand[name]=[t for t in tri if not any(dominant[i]in allowed for i in t)]
rest=[body.matrix_world@v.co for v in body.data.vertices]
soles={s:[i for i,p in enumerate(rest)if p.z<.13 and (p.x>0)==(s=='L')]for s in ['L','R']}
contact=Vector(report['poses'][5]['hammer_contact']);failures=[];checks=0;grips={};first=None
def check(condition,msg):
    global checks
    checks+=1
    if not condition:failures.append(msg);print('FAIL',msg,flush=True)
for row in report['poses']:
    i=row['index'];scene.frame_set(row['frame']);bpy.context.view_layer.update()
    bp,bt=geometry(body);allp=bp.copy()
    if first is None:first=[p.copy()for p in bp]
    if i==9:check(max((p-q).length for p,q in zip(first,bp))<.00001,'final guard matches initial body')
    for side,ids in soles.items():
        check(abs(min(bp[j].z for j in ids))<.001,f'{i} planted {side} sole')
        # SOLE includes the boot cuff, which bends with the shin. Only actual
        # ground-contact vertices must keep their XY position while planted.
        contact_ids=[j for j in ids if first[j].z<.008]
        displacement=max(math.hypot(bp[j].x-first[j].x,bp[j].y-first[j].y)for j in contact_ids)
        check(len(contact_ids)>10 and displacement<.008,f'{i} {side} planted sole XY shift {displacement:.6f}')
    for name,obj in props.items():
        pp,pt=geometry(obj);allp+=pp
        relative=(arm.matrix_world@arm.pose.bones[obj.parent_bone].matrix).inverted()@obj.matrix_world
        if name not in grips:grips[name]=relative.copy()
        err=max(abs(relative[j][k]-grips[name][j][k])for j in range(4)for k in range(4))
        check(err<.00001,f'{i} stable {name} grip')
        check(crossings(pp,pt,bp,nonhand[name])+crossings(bp,nonhand[name],pp,pt)==0,f'{i} {name} outside non-hand body')
        if name=='hammer':
            inside=[p for p in pp if abs(p.x-contact.x)<.20 and abs(p.y-contact.y)<.20]
            check(not inside or min(p.z for p in inside)>contact.z-.012,f'{i} hammer does not penetrate target top')
            if i==9:
                check(max(abs(pp[j][k]-guard_hammer[j][k])for j in range(len(pp))for k in range(3))<.00001,'final hammer returns to guard')
            if i==0:guard_hammer=pp
    hp,ht=geometry(props['hammer']);sp,st=geometry(props['shield'])
    check(crossings(hp,ht,sp,st)+crossings(sp,st,hp,ht)==0,f'{i} equipment separated')
    check(all(math.isfinite(c)for p in allp for c in p),f'{i} finite geometry')
    for view,cfg in report['views']['attack'].items():
        target=Vector((0,-.20,report['actions']['attack']['target_z']));cam=scene.camera
        cam.location=target+Vector(cfg['camera_vector']).normalized()*8
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
        projected=[world_to_camera_view(scene,cam,p)for p in allp]
        check(all(.015<p.x<.985 and .015<p.y<.985 for p in projected),f'{i} {view} no clipping')
        if i==5:
            p=world_to_camera_view(scene,cam,props['hammer'].matrix_world@Vector(report['contact_local']))
            expected=cfg['impact_px'];actual=[p.x*640,(1-p.y)*640]
            check(max(abs(x-y)for x,y in zip(actual,expected))<.001,view+' contact reprojects')
check(report['poses'][3]['hammer_contact'][2]-contact.z>1,'readable raised hammer before strike')
check(report['poses'][5]['face_normal'][2]<-.95,'strike face points toward target')
check(abs(sum(report['actions']['attack']['durations'])-900)<.001,'900ms one-shot')
check(len(body.data.vertices)==14680 and len(arm.data.bones)==50,'original topology and rig')
check(sum(1 for i in bpy.data.images if i.packed_file)==9,'nine original packed textures')
source=OUT.parent/'v3-equipment-grips/paladin-equipped-review.blend'
check(hashlib.sha256(source.read_bytes()).hexdigest()==report['source_scene_sha256'],'source scene unchanged')
for row in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:
    check(hashlib.sha256((OUT.parent/'source'/row['file']).read_bytes()).hexdigest()==row['sha256'],'source GLB '+row['file'])
(OUT/'saved-pose-validation.json').write_text(json.dumps({'checks':checks,'failures':failures,'limits':'Held poses and target contact. Edge/triangle checks do not exclude all containment or armour self-intersections; no continuous runtime 3D.'},indent=2)+'\n')
print('PALADIN_ATTACK_RELOAD',checks,'checks',len(failures),'failures',flush=True)
if failures:raise RuntimeError('Attack validation failed')
