"""Static Mycean equipment proposal; dedicated background Blender, original painting."""
import bpy,json,math,sys
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'inspection.blend'))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=bpy.data.objects['mycean_output_unwrapped'];staff=bpy.data.objects['staff_output_unwrapped']
for m in body.modifiers:
 if m.type=='ARMATURE':m.use_deform_preserve_volume=True
R={b.name:(arm.matrix_world@b.matrix_local).copy()for b in arm.data.bones}
H={b.name:arm.matrix_world@b.head_local for b in arm.data.bones}
AI=arm.matrix_world.inverted()
for b in arm.pose.bones:b.rotation_mode='QUATERNION';b.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
def xyz(v):return [float(x)for x in v]
def points(o):
 e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=e.to_mesh()
 p=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear();return p
def set_world(n,head,q):
 m=q.to_matrix().to_4x4()@R[n];m.translation=head
 arm.pose.bones[n].matrix=AI@m;bpy.context.view_layer.update()
def aim(n,head,end,rest_end):set_world(n,head,(rest_end-H[n]).normalized().rotation_difference((end-head).normalized()))
def joint(root,end,l1,l2,pole):
 d=end-root;dist=d.length;assert abs(l1-l2)+.001<dist<l1+l2-.001,'Unreachable wrist'
 d.normalize();a=(l1*l1-l2*l2+dist*dist)/(2*dist);p=pole-d*d.dot(pole)
 return root+d*a+p.normalized()*math.sqrt(max(0,l1*l1-a*a))
hands={}
for side,chain,target,pole in [('L',('Bone_033','Bone_032','Bone_031'),(.57,-.12,.70),(1,.2,-.1)),('R',('Bone_025','Bone_024','Bone_023'),(-.36,-.04,.48),(-1,.2,-.1))]:
 upper,fore,wrist=chain;w=Vector(target)
 elbow=joint(H[upper],w,(H[fore]-H[upper]).length,(H[wrist]-H[fore]).length,Vector(pole))
 aim(upper,H[upper],elbow,H[fore]);aim(fore,elbow,w,H[wrist])
 if side=='L':
  finger=(H['Bone_030']-H[wrist]).normalized();thumb=Vector((finger.z,0,-finger.x)).normalized()
  source=Matrix((finger,thumb,finger.cross(thumb))).transposed()
  target_basis=Matrix((Vector((1,0,0)),Vector((0,0,1)),Vector((0,-1,0)))).transposed()
  q=(target_basis@source.transposed()).to_quaternion()
  # Palm also carries forearm weights. Roll forearm, preserving its endpoints.
  m=arm.matrix_world@arm.pose.bones[fore].matrix;axis=(w-m.translation).normalized()
  current=(m@R[fore].inverted()).to_3x3()@Vector((0,1,0));current=(current-axis*axis.dot(current)).normalized()
  wanted=Vector((0,-1,0));wanted=(wanted-axis*axis.dot(wanted)).normalized()
  roll=math.atan2(axis.dot(current.cross(wanted)),current.dot(wanted))
  rolled=Quaternion(axis,roll).to_matrix().to_4x4()@m;rolled.translation=m.translation
  arm.pose.bones[fore].matrix=AI@rolled;bpy.context.view_layer.update()
 else:q=Quaternion((0,1,0),math.radians(-22))
 set_world(wrist,w,q);hands[side]={'bone':wrist,'wrist':w,'elbow':elbow,'q':q}
# The imported distal chain is serial, not independently articulated fingers.
# Fold the grouped digits modestly; preserve the original mesh and weights.
hand=hands['L'];distal='Bone_030'
set_world(distal,hand['wrist']+hand['q']@(H[distal]-H[hand['bone']]),Quaternion((0,0,1),math.radians(-48))@hand['q'])
sp=points(staff);z_grip=-.13
slice_points=[p for p in sp if abs(p.z-z_grip)<.025]
grip=Vector(((min(p.x for p in slice_points)+max(p.x for p in slice_points))/2,(min(p.y for p in slice_points)+max(p.y for p in slice_points))/2,z_grip))
target=hand['wrist']+Vector((.085,-.028,.006))
scale=1.60/(max(p.z for p in sp)-min(p.z for p in sp))
rotation=Matrix.Rotation(math.radians(0),4,'X')@Matrix.Rotation(math.radians(15),4,'Y')
world=Matrix.Translation(target)@rotation@Matrix.Scale(scale,4)@Matrix.Translation(-grip)@staff.matrix_world
staff.parent=arm;staff.parent_type='BONE';staff.parent_bone=hand['bone'];staff.matrix_world=world
staff.hide_render=False;staff.hide_set(False);body.hide_render=False
bpy.context.view_layer.update()
scene.render.resolution_x=768;scene.render.resolution_y=768;scene.cycles.samples=32
scene.render.film_transparent=True;camera=scene.camera
for name,pos,power,size in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
 light=bpy.data.objects[name];light.location=Vector((0,0,.85))+Vector(pos)*1.7
 light.rotation_euler=(Vector((0,0,.85))-light.location).to_track_quat('-Z','Y').to_euler()
 light.data.energy=power*1.7**2;light.data.size=size*1.7
allp=points(body)+points(staff);lo=Vector([min(p[i]for p in allp)for i in range(3)]);hi=Vector([max(p[i]for p in allp)for i in range(3)])
center=(lo+hi)*.5
views={'front':(0,-1,0),'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'back':(0,1,0),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
extents=[]
for d in views.values():
 camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
 inv=camera.rotation_euler.to_matrix().transposed();extents.append(2*max(abs(v[i])for p in allp for v in [inv@(p-center)]for i in (0,1)))
camera.data.ortho_scale=max(extents)*1.16
report={'staff':{'bone':hand['bone'],'source_grip':xyz(grip),'target':xyz(target),'scale':scale,'length_before_tilt':1.6,'tilt_x_deg':0,'tilt_y_deg':15,'world_matrix':[list(row)for row in staff.matrix_world]},'hands':{s:{'bone':v['bone'],'wrist':xyz(v['wrist']),'elbow':xyz(v['elbow'])}for s,v in hands.items()},'camera':{'ortho':camera.data.ortho_scale,'center':xyz(center)},'views':list(views),'limits':'Static proposal. Serial distal bones, no independent per-finger rig. Future animated clearances untested.'}
camera.location=center+Vector(views['front']).normalized()*8
camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
scene.frame_set(1);bpy.ops.file.pack_all();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mycean-equipped-review.blend'),compress=True)
render_views={} if '--no-render' in sys.argv else ({k:d for k,d in views.items()if k in ('front','sw','ne')}if '--pilot'in sys.argv else views)
report['views']=list(render_views)
report['closeups']=[]
for name,d in render_views.items():
 camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
 assert all(.02<(uv:=world_to_camera_view(scene,camera,p)).x<.98 and .02<uv.y<.98 for p in allp),'Camera clipping'
 scene.render.filepath=str(OUT/('equipped-'+name+'.png'));bpy.ops.render.render(write_still=True)
if render_views:
 for name,focus,d,ortho in [('grip-front',(.61,-.13,.72),(0,-1,0),.48),('grip-side',(.61,-.13,.72),(1,-1,.4),.48)]:
  focus=Vector(focus);camera.location=focus+Vector(d).normalized()*5
  camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
  camera.data.ortho_scale=ortho;bpy.context.view_layer.update()
  scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);report['closeups'].append(name)
(OUT/'equipment-fit.json').write_text(json.dumps(report,indent=2)+'\n')
print('MYCEAN_ASSEMBLED',json.dumps(report))
