"""Static equipment review from immutable GLBs; dedicated background Blender only."""
import bpy, json, math, hashlib, sys
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from bpy_extras.object_utils import world_to_camera_view

OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'v2-meshy-inspection/inspection.blend'))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
def mesh(prefix):
    return next(o for o in scene.objects if o.type=='MESH' and o.name.startswith(prefix+'_') and (prefix!='batrafian' or any(m.type=='ARMATURE' for m in o.modifiers)))
body,bow,quiver,arrow=[mesh(n) for n in ('batrafian','bow','quiver','arrow')]
for modifier in body.modifiers:
    if modifier.type=='ARMATURE':modifier.use_deform_preserve_volume=True
R={b.name:(arm.matrix_world@b.matrix_local).copy() for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
for b in arm.pose.bones:b.rotation_mode='QUATERNION';b.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
def xyz(v):return [round(float(x),6) for x in v]
def points(o):
    e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=e.to_mesh()
    p=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear();return p
def set_world(name,head,q):
    m=q.to_matrix().to_4x4()@R[name];m.translation=head
    arm.pose.bones[name].matrix=AI@m;bpy.context.view_layer.update()
def aim(name,head,end,rest_end):
    set_world(name,head,(rest_end-H[name]).normalized().rotation_difference((end-head).normalized()))
def joint(root,end,l1,l2,pole):
    delta=end-root;dist=delta.length
    assert abs(l1-l2)+.001<dist<l1+l2-.001,'Unreachable wrist'
    d=delta/dist;a=(l1*l1-l2*l2+dist*dist)/(2*dist)
    p=pole-d*d.dot(pole)
    return root+d*a+p.normalized()*math.sqrt(max(0,l1*l1-a*a))
hands={}
for side,chain,target,pole in [
    ('L',('Bone_025','Bone_024','Bone_023'),(.49,-.20,.82),(1,.15,-.2)),
    ('R',('Bone_021','Bone_020','Bone_019'),(-.40,-.06,.66),(-1,.2,-.1))]:
    upper,fore,wrist=chain;w=Vector(target)
    elbow=joint(H[upper],w,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector(pole))
    aim(upper,H[upper],elbow,H[fore]);aim(fore,elbow,w,H[wrist])
    if side=='L':
        # Source fingers run diagonally outward/down. Map the hand's own basis
        # to forward fingers, upward thumb and inward palm, not a flat tray.
        finger=(H['Bone_022']-H[wrist]).normalized()
        thumb=Vector((finger.z,0,-finger.x)).normalized()
        source_basis=Matrix((finger,thumb,finger.cross(thumb))).transposed()
        target_basis=Matrix((Vector((0,-1,0)),Vector((0,0,1)),Vector((-1,0,0)))).transposed()
        q=(target_basis@source_basis.transposed()).to_quaternion()
        # Imported palm weights also include the forearm. Rotating only the
        # wrist wrings that shared surface; roll the forearm to the same palm
        # plane while retaining the elbow/wrist positions and segment length.
        fore_world=arm.matrix_world@arm.pose.bones[fore].matrix
        axis=(w-fore_world.translation).normalized()
        current=(fore_world@R[fore].inverted()).to_3x3()@Vector((0,1,0))
        current=(current-axis*axis.dot(current)).normalized()
        wanted=Vector((-1,0,0));wanted=(wanted-axis*axis.dot(wanted)).normalized()
        roll=math.atan2(axis.dot(current.cross(wanted)),current.dot(wanted))
        updated=Quaternion(axis,roll).to_matrix().to_4x4()@fore_world
        updated.translation=fore_world.translation
        arm.pose.bones[fore].matrix=AI@updated;bpy.context.view_layer.update()
    else:q=Quaternion((0,1,0),math.radians(-30))
    set_world(wrist,w,q)
    hands[side]={'wrist':wrist,'head':w,'q':q,'elbow':elbow}
# Meshy supplies one distal hand bone, not independently articulated fingers.
# A grouped curl is a static grip preview, not a calibrated release pose.
hand=hands['L'];distal='Bone_022'
set_world(distal,hand['head']+hand['q']@(H[distal]-H[hand['wrist']]),
          Quaternion((0,0,1),math.radians(-40))@hand['q'])
grip=hand['head']+Vector((-.037,-.125,.012))
attachments={}
def attach(obj,source_grip,target,rotation,height,bone):
    p=points(obj);scale=height/(max(v.z for v in p)-min(v.z for v in p))
    world=Matrix.Translation(target)@rotation@Matrix.Scale(scale,4)@Matrix.Translation(-source_grip)@obj.matrix_world
    obj.parent=arm;obj.parent_type='BONE';obj.parent_bone=bone;obj.matrix_world=world;obj.hide_render=False
    bpy.context.view_layer.update()
    attachments[obj.name]={'bone':bone,'source_grip':xyz(source_grip),'target':xyz(target),'uniform_scale':scale,'requested_height':height}
    return scale
bow_scale=attach(bow,Vector((-.248,0,-.015)),grip,Matrix.Rotation(math.radians(60),4,'Z'),1.25,'Bone_023')
quiver_scale=attach(quiver,Vector((0,0,-.20)),Vector((-.14,.435,.91)),
                    Matrix.Rotation(math.radians(-12),4,'X')@Matrix.Rotation(math.radians(-24),4,'Y')@Matrix.Rotation(math.pi,4,'Z'),.92,'Bone_003')
# Arrow remains an independent, hidden object for later hand/projectile switching.
# Normalize its complete length without putting a spare arrow through the body.
ap=points(arrow);arrow_scale=.79/(max(v.z for v in ap)-min(v.z for v in ap))
arrow.matrix_world=Matrix.Scale(arrow_scale,4)@arrow.matrix_world
arrow.hide_render=True;arrow.hide_set(True)
arrow['role']='independent projectile; not nocked in this resting pose'
body.hide_render=False
for obj in (bow,quiver):obj.hide_set(False)
scene.render.resolution_x=768;scene.render.resolution_y=768;scene.cycles.samples=32
camera=scene.camera
for name,pos,power,size in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
    light=bpy.data.objects[name];light.location=Vector((0,0,.85))+Vector(pos)*1.7
    light.rotation_euler=(Vector((0,0,.85))-light.location).to_track_quat('-Z','Y').to_euler()
    light.data.energy=power*1.7**2;light.data.size=size*1.7
all_points=[p for o in (body,bow,quiver) for p in points(o)]
lo=Vector([min(v[i] for v in all_points) for i in range(3)]);hi=Vector([max(v[i] for v in all_points) for i in range(3)])
center=(lo+hi)*.5
views={'front':(0,-1,0),'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),
       'back':(0,1,0),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
extents=[]
for d in views.values():
    camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    inv=camera.rotation_euler.to_matrix().transposed();p=[inv@(v-center) for v in all_points]
    # Keep one shared centre: an asymmetric bow/quiver silhouette is not centred
    # on the midpoint of its projected min/max in every camera orientation.
    extents.append(2*max(abs(v[i]) for v in p for i in (0,1)))
camera.data.ortho_scale=max(extents)*1.18
render_views={k:v for k,v in views.items() if k in ('sw','ne','back')} if '--pilot' in sys.argv else views
for name,d in render_views.items():
    camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
    assert all(.02<(uv:=world_to_camera_view(scene,camera,p)).x<.98 and .02<uv.y<.98 for p in all_points)
    scene.render.filepath=str(OUT/('equipped-'+name+'.png'));bpy.ops.render.render(write_still=True)
camera.location=center+Vector(views['sw']).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
bpy.context.view_layer.update();bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'batrafian-equipped-review.blend'),compress=True)
report={'attachments':attachments,'arrow_length':.79,'arrow_scale':arrow_scale,'views':list(render_views),
        'hands':{k:{'wrist':v['wrist'],'head':xyz(v['head']),'elbow':xyz(v['elbow'])} for k,v in hands.items()},
        'limits':'Static review only. No independent finger bones, no deformable bow/string setup, no full animation collision validation.'}
(OUT/'equipment-fit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print('ASSEMBLY_OK',json.dumps(report))
