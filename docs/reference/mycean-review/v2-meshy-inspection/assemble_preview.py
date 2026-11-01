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

# Meshy assigned most palm/digit vertices to the forearm, leaving the serial
# hand bones ineffective. Only reweight the actual hand beyond its wrist plane.
hand_names=['Bone_031','Bone_030','Bone_029','Bone_028','Bone_027']
wrist_rest=H['Bone_031'];finger_rest=(H['Bone_030']-wrist_rest).normalized()
stations=[0]+[(H[n]-wrist_rest).dot(finger_rest) for n in hand_names[1:]]
corrected_vertices=[]
for v in body.data.vertices:
 dominant=body.vertex_groups[max(v.groups,key=lambda g:g.weight).group].name
 p=body.matrix_world@v.co;distance=(p-wrist_rest).dot(finger_rest)
 if dominant not in hand_names+['Bone_032'] or distance<=0 or (p-wrist_rest).length>.25:continue
 weights={'Bone_031':1}
 # Blend the first centimeter to preserve a smooth wrist/cuff boundary.
 blend=min(1,distance/.01);old={g.group:g.weight for g in v.groups}
 for g in body.vertex_groups:g.remove([v.index])
 for i,w in old.items():
  if w*(1-blend)>1e-6:body.vertex_groups[i].add([v.index],w*(1-blend),'REPLACE')
 for name,w in weights.items():
  if w*blend>1e-6:body.vertex_groups[name].add([v.index],w*blend,'ADD')
 corrected_vertices.append(v.index)
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
  tilt=math.radians(15)
  target_basis=Matrix((Vector((math.cos(tilt),0,-math.sin(tilt))),Vector((math.sin(tilt),0,math.cos(tilt))),Vector((0,-1,0)))).transposed()
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
set_world(distal,hand['wrist']+hand['q']@(H[distal]-H[hand['bone']]),hand['q'])
# A wrist-attached 3D corrective curls the mitten fingers into a C-shaped grip.
# It preserves topology/UVs and follows the existing wrist during future poses.
f=Vector((math.cos(math.radians(15)),0,-math.sin(math.radians(15))))
up=Vector((math.sin(math.radians(15)),0,math.cos(math.radians(15))))
side=Vector((0,1,0));basis=Matrix((f,side,up)).transposed().to_4x4()
lattice_data=bpy.data.lattices.new('MyceanGripCorrective');lattice_data.points_u=12;lattice_data.points_v=3;lattice_data.points_w=3
lattice_data.interpolation_type_u='KEY_LINEAR';lattice_data.interpolation_type_v='KEY_LINEAR';lattice_data.interpolation_type_w='KEY_LINEAR'
lattice=bpy.data.objects.new('MyceanGripCorrective',lattice_data);scene.collection.objects.link(lattice)
extent=Vector((.24,.24,.30));grip_start=.07;grip_radius=.08
lm=Matrix.Translation(hand['wrist']+f*.12)@basis@Matrix.Diagonal((extent.x/11,extent.y/2,extent.z/2,1))
lattice.matrix_world=lm
for p in lattice_data.points:
 x=(p.co.x/11+.5)*extent.x;y=p.co.y/2*extent.y
 if x<=grip_start:continue
 theta=2*(x-grip_start)/grip_radius;fade=min(1,(x-grip_start)/.05)
 radial=grip_radius+y*(1-.5*fade)
 newx=grip_start+radial*math.sin(theta);newy=-grip_radius+radial*math.cos(theta)
 p.co_deform.x=(newx/extent.x-.5)*11;p.co_deform.y=newy/extent.y*2
vg=body.vertex_groups.new(name='StaffGripCorrective')
for i in corrected_vertices:vg.add([i],1,'REPLACE')
subdivision=body.modifiers.new('GripSampling','SUBSURF');subdivision.subdivision_type='SIMPLE';subdivision.levels=2;subdivision.render_levels=2
modifier=body.modifiers.new('StaffGripCorrective','LATTICE');modifier.object=lattice;modifier.vertex_group=vg.name
contact=body.modifiers.new('GripOutsideStaff','SHRINKWRAP');contact.target=staff;contact.vertex_group=vg.name;contact.wrap_method='NEAREST_SURFACEPOINT';contact.wrap_mode='OUTSIDE';contact.offset=.002
lattice.parent=arm;lattice.parent_type='BONE';lattice.parent_bone=hand['bone'];lattice.matrix_world=lm
bpy.context.view_layer.update()
sp=points(staff);z_grip=-.13
slice_points=[p for p in sp if abs(p.z-z_grip)<.025]
grip=Vector(((min(p.x for p in slice_points)+max(p.x for p in slice_points))/2,(min(p.y for p in slice_points)+max(p.y for p in slice_points))/2,z_grip))
target=hand['wrist']+f*grip_start-side*grip_radius+up*.006
scale=1.60/(max(p.z for p in sp)-min(p.z for p in sp))
rotation=Matrix.Rotation(math.radians(0),4,'X')@Matrix.Rotation(math.radians(15),4,'Y')
world=Matrix.Translation(target)@rotation@Matrix.Scale(scale,4)@Matrix.Translation(-grip)@staff.matrix_world
staff.parent=arm;staff.parent_type='BONE';staff.parent_bone=hand['bone'];staff.matrix_world=world
staff.hide_render=False;staff.hide_set(False);body.hide_render=False
bpy.context.view_layer.update()
# The imported staff contains overlapping leather/wood shells. A closed grip
# envelope supplies unambiguous outside normals for the contact constraint.
grip_points=[p-target for p in points(staff) if abs((p-target).dot(up))<.18]
contact_radius=max((p-up*p.dot(up)).length for p in grip_points)+.001
bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=contact_radius,depth=.55,location=target)
proxy=bpy.context.object;proxy.name='StaffGripContactEnvelope';proxy.rotation_euler=up.to_track_quat('Z','Y').to_euler();bpy.context.view_layer.update()
pm=proxy.matrix_world.copy();proxy.parent=arm;proxy.parent_type='BONE';proxy.parent_bone=hand['bone'];proxy.matrix_world=pm
proxy.hide_render=True;proxy.hide_set(True);contact.target=proxy
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
report['grip_correction']={'reweighted_vertex_count':len(corrected_vertices),'reweighted_vertices':corrected_vertices,
 'method':'Local wrist weights + C-shaped lattice + closed contact envelope, all on the working copy.',
 'lattice_grid':[12,3,3],'start':grip_start,'radius':grip_radius,'curl_factor':2,
 'contact_radius':contact_radius,'contact_offset':contact.offset,'render_subdivision':2,
 'topology_and_uv_in_source_mesh':'unchanged; modifiers evaluated for offline rendering only'}
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
