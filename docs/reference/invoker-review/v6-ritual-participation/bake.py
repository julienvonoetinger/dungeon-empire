"""Whole-model rear-view ritual actors, preserving the equipped source modifiers."""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector, Quaternion
OUT = Path(__file__).resolve().parent
REPO = OUT.parents[3]
kind = sys.argv[-1]
assert kind in ['invoker','oculin']
if kind == 'invoker':
    src = OUT.parent/'v4-grip-correction/invoker-equipped.blend'
    bpy.ops.wm.open_mainfile(filepath=str(src))
else:
    src = REPO/'docs/reference/summoner-race-review/source/Meshy_AI_Grumgaze_20261102_character.glb'
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(src))
digest = hashlib.sha256(src.read_bytes()).hexdigest()
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type=='ARMATURE')
body = next(o for o in scene.objects if o.type=='MESH' and o.find_armature())
baseline = {b.name:b.matrix_basis.copy() for b in arm.pose.bones}
for obj in list(scene.objects):
    if obj.type in ['CAMERA','LIGHT']: bpy.data.objects.remove(obj,do_unlink=True)
scene.render.engine = 'CYCLES'
scene.cycles.samples = 8
scene.cycles.use_denoising = True
scene.world = bpy.data.worlds.new('ProcessionLight')
scene.world.color = (.32,.32,.4)
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
focus = Vector((0,0,.8))
for pos,power in [((-3,4,5),400),((3,1,3),180),((0,-3,4),250)]:
    bpy.ops.object.light_add(type='AREA',location=pos)
    lamp = bpy.context.object
    lamp.data.energy=power; lamp.data.size=4
    lamp.rotation_euler=(focus-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add()
camera = bpy.context.object
scene.camera=camera
camera.data.type='ORTHO'; camera.data.ortho_scale=3.0
camera.data.clip_start=.01
camera.location=focus+Vector((0,math.sqrt(3),1)).normalized()*7
camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
camera_base=camera.location.copy()
scene.render.resolution_x=scene.render.resolution_y=384
scene.render.resolution_percentage=100
scene.render.film_transparent=True
scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGBA'
folder=OUT/kind
folder.mkdir(exist_ok=True)
records=[]
def bend(index, degrees):
    bone=arm.pose.bones[f'Bone_{index:03d}']
    axis=(arm.matrix_world@bone.bone.matrix_local).to_quaternion().inverted()@Vector((1,0,0))
    bone.matrix_basis=baseline[bone.name]@Quaternion(axis,math.radians(degrees)).to_matrix().to_4x4()
def points():
    obj=body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh=obj.to_mesh()
    result=[obj.matrix_world@v.co for v in mesh.vertices]
    obj.to_mesh_clear()
    return result
clips=[('chant',48)]
index=0
for clip,count in clips:
    for frame in range(count):
        scene.frame_set(index)
        for b in arm.pose.bones: b.matrix_basis=baseline[b.name].copy()
        phase=math.tau*frame/24
        if clip=='walk':
            legs=[(10,9,1),(15,14,-1)] if kind=='invoker' else [(13,12,1),(18,17,-1)]
            for thigh,shin,sign in legs:
                swing=math.sin(phase)*sign
                lift=max(0,math.cos(phase)*sign)
                bend(thigh,17*swing+7*lift); bend(shin,-22*lift)
            if kind=='invoker': bend(27,-6*math.sin(phase))
            else:
                bend(33,-9*math.sin(phase)); bend(28,9*math.sin(phase))
        elif clip=='chant':
            # Keep the corrected staff hand intact; gesture with the free arm.
            f=frame/(count-1)
            envelope=min(1,f*5,(1-f)*5)
            envelope=envelope*envelope*(3-2*envelope)
            if kind=='invoker':
                bend(27,(-72-7*math.sin(phase*.5))*envelope)
                bend(26,(-55-5*math.sin(phase*.5-.5))*envelope)
                bend(18,(-7-3*math.sin(phase*.5))*envelope)
            else:
                for joint in [28,33]: bend(joint,(-72-7*math.sin(phase*.5))*envelope)
                for joint in [27,32]: bend(joint,(-55-5*math.sin(phase*.5-.5))*envelope)
        elif clip=='bow':
            f=frame/(count-1); f=f*f*(3-2*f)
            bend(18,24*f)
        elif clip=='kneel':
            f=frame/(count-1); f=f*f*(3-2*f)
            for joint in [13,18]: bend(joint,-47*f)
            for joint in [12,17]: bend(joint,85*f)
            for joint in [11,16]: bend(joint,-22*f)
            bend(8,29*f); bend(22,18*f)
            for joint in [27,32]: bend(joint,-38*f)
        bpy.context.view_layer.update()
        ground=min(p.z for p in points())
        camera.location=camera_base+Vector((0,0,ground))
        for b in arm.pose.bones:
            b.keyframe_insert('location',frame=index)
            b.keyframe_insert('rotation_quaternion',frame=index)
            b.keyframe_insert('rotation_euler',frame=index)
        camera.keyframe_insert('location',frame=index)
        path=folder/f'{clip}-{frame:02d}.png'
        scene.render.filepath=str(path)
        bpy.ops.render.render(write_still=True)
        records.append(dict(clip=clip,frame=frame,index=index,ground=ground,file=path.name))
        index+=1
scene.frame_start=0;scene.frame_end=index-1
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'{kind}-poses.blend'),compress=True)
assert hashlib.sha256(src.read_bytes()).hexdigest()==digest
(OUT/f'{kind}.json').write_text(json.dumps(dict(source=str(src),sha256=digest,frames=records,anchor=[192,192+.8*math.cos(math.pi/6)*384/3],ortho=3),indent=2),encoding='utf8')
print('ACTOR_RENDER_OK',kind,len(records),flush=True)
