"""Rigid equipment fit review, derived from imported source meshes; no repaint."""
import bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'inspection.blend'))
scene=bpy.context.scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('paladin_') and o.type=='MESH' and any(m.type=='ARMATURE'for m in o.modifiers))
hammer=next(o for o in scene.objects if o.name.startswith('hammer_') and o.type=='MESH')
shield=next(o for o in scene.objects if o.name.startswith('shield_') and o.type=='MESH')
def xyz(v):return [round(float(x),6)for x in v]
def points(o):
    e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=e.to_mesh();p=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear();return p
def fit(o,height,source_grip,target,bone):
    # Build an unparented matrix in Blender world space, preserving import axes.
    initial=o.matrix_world.copy();p=points(o);size=max(v.z for v in p)-min(v.z for v in p);scale=height/size
    world=Matrix.Translation(Vector(target))@Matrix.Scale(scale,4)@Matrix.Translation(-Vector(source_grip))@initial
    o.parent=arm;o.parent_type='BONE';o.parent_bone=bone;o.matrix_world=world;o.hide_render=False
    bpy.context.view_layer.update()
    return {'bone':bone,'uniform_scale':scale,'height':height,'source_grip':source_grip,'world_grip':target,'matrix':[[float(x)for x in row]for row in world]}
# Character faces -Y; negative X is anatomical right. Infer hand chains from
# this model's bone positions, never reuse Vulpin numbers automatically.
mapping={'right_arm':['Bone_025','Bone_024','Bone_023','Bone_022'],'left_arm':['Bone_021','Bone_020','Bone_019','Bone_018'],'head':'Bone_015','right_leg':['Bone_009','Bone_008','Bone_007'],'left_leg':['Bone_014','Bone_013','Bone_012']}
attachments={
 'hammer':fit(hammer,1.04,(0,0,-.46),(-.753,.035,.465),'Bone_023'),
 'shield':fit(shield,1.16,(0,.245,-.12),(.746,-.08,.58),'Bone_019')}
body.hide_render=False
checks=[]
for name,obj in [('hammer',hammer),('shield',shield)]:
    bone=arm.pose.bones[attachments[name]['bone']];before=obj.matrix_world.copy();basis=bone.matrix_basis.copy();mode=bone.rotation_mode
    bone.rotation_mode='XYZ';bone.rotation_euler.x+=math.radians(8);bpy.context.view_layer.update()
    delta=max(abs(obj.matrix_world[i][j]-before[i][j])for i in range(4)for j in range(4))
    bone.matrix_basis=basis;bone.rotation_mode=mode;bpy.context.view_layer.update()
    error=max(abs(obj.matrix_world[i][j]-before[i][j])for i in range(4)for j in range(4))
    assert delta>1e-5 and error<1e-5
    checks.append({'object':name,'moved_with_bone':True,'matrix_delta':delta,'restore_error':error})
scene.render.resolution_x=960;scene.render.resolution_y=960
camera=scene.camera
all_points=[v for obj in (body,hammer,shield)for v in points(obj)]
lo=Vector([min(v[i]for v in all_points)for i in range(3)]);hi=Vector([max(v[i]for v in all_points)for i in range(3)]);center=(lo+hi)*.5
# One common camera scale for all directions. Elevation30deg matches the kit.
views={'front':(0,-1,0),'se':(-1,-1,math.sqrt(2/3)),'sw':(1,-1,math.sqrt(2/3)),'nw':(1,1,math.sqrt(2/3)),'ne':(-1,1,math.sqrt(2/3))}
extents=[]
for d in views.values():
    camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();inv=camera.rotation_euler.to_matrix().transposed()
    projected=[inv@(v-center)for v in all_points];extents.append(max(max(v[i]for v in projected)-min(v[i]for v in projected)for i in (0,1)))
camera.data.ortho_scale=max(extents)*1.16
# Reposition the inspection lights from the final imported prop to the hero.
for name,pos,power,size in [('Key',(-2,-3,4),180,3),('Fill',(3,-1,2),70,3),('Rim',(1,3,3),100,2)]:
    light=bpy.data.objects[name];light.location=Vector((0,0,.85))+Vector(pos)*1.7;light.rotation_euler=(Vector((0,0,.85))-light.location).to_track_quat('-Z','Y').to_euler();light.data.energy=power*1.7**2;light.data.size=size*1.7
for name,d in views.items():
    camera.location=center+Vector(d).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
    ndc=[world_to_camera_view(scene,camera,v)for v in all_points]
    assert all(.02<v.x<.98 and .02<v.y<.98 for v in ndc),'Clipped preview '+name
    scene.render.filepath=str(OUT/('equipped-'+name+'.png'));bpy.ops.render.render(write_still=True)
    checks.append({'view':name,'fully_in_frame':True})
camera.location=center+Vector(views['sw']).normalized()*8;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'paladin-equipped-review.blend'),compress=True)
report={'status':'static-equipment-fit-review','attachments':attachments,'bone_mapping':mapping,'checks':checks,'camera_elevation_isometric':30,'ortho_scale':camera.data.ortho_scale,'limits':'Initial A-pose fitting only. No closed grip pose, gait, combat or full collision-range validation; source mesh/materials unchanged.'}
(OUT/'equipment-fit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
for entry in json.loads((OUT.parent/'source/provenance.json').read_text())['files']:assert hashlib.sha256((OUT.parent/'source'/entry['file']).read_bytes()).hexdigest()==entry['sha256']
print('ASSEMBLY_OK',json.dumps(report))
