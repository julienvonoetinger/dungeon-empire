"""Correct physical camera headings; measure gait travel from the original feet."""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
OUT=Path(__file__).resolve().parent
SRC=OUT.parent/'v5-procession'
source=SRC/'invoker-poses.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene; camera=scene.camera
camera.animation_data_clear()
arm=next(o for o in scene.objects if o.type=='ARMATURE')
records=[r for r in json.loads((SRC/'invoker.json').read_text())['frames'] if r['clip'] in ['idle','walk']]
scene.render.resolution_x=scene.render.resolution_y=384
scene.render.resolution_percentage=100
directions={'n':0,'ne':315,'e':270,'se':225,'s':180,'sw':135,'w':90,'nw':45}
existing={'n':'v5-procession/invoker','ne':'v8-follow-master/nw','se':'v8-follow-master/sw','sw':'v8-follow-master/se','nw':'v8-follow-master/ne'}
result={}
for name,angle in directions.items():
    a=math.radians(angle)
    ray=Vector((math.sin(a)*math.sqrt(3),math.cos(a)*math.sqrt(3),1)).normalized()
    foot_tracks=[[],[]]
    for record in records:
        scene.frame_set(record['index'])
        focus=Vector((0,0,.8+record['ground']))
        camera.location=focus+ray*7
        camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
        bpy.context.view_layer.update()
        origin=world_to_camera_view(scene,camera,Vector((0,0,0)))
        forward=world_to_camera_view(scene,camera,Vector((0,-1,0)))
        heading=Vector((forward.x-origin.x,origin.y-forward.y)).normalized()
        if record['clip']=='walk':
            for i,bone in enumerate(['Bone_008','Bone_013']):
                p=arm.matrix_world@arm.pose.bones[bone].head
                p.z=0
                q=world_to_camera_view(scene,camera,p)
                foot_tracks[i].append(Vector(((q.x-origin.x)*256,(origin.y-q.y)*256)).dot(heading))
        if name not in existing:
            folder=OUT/name; folder.mkdir(parents=True,exist_ok=True)
            scene.render.filepath=str(folder/record['file'])
            bpy.ops.render.render(write_still=True)
    stride=sum(2*(max(t)-min(t)) for t in foot_tracks)/2
    result[name]=dict(angle=angle,heading=list(heading),stride_pixels=stride,masters=existing.get(name,'v9-facing/'+name))
(OUT/'directions.json').write_text(json.dumps(dict(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),directions=result),indent=2))
print('FACING_RENDER_OK',json.dumps(result),flush=True)
