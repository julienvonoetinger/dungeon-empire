"""Render the Oculin's short entrance walk from the original rig in background Blender."""
from pathlib import Path
from math import sin, cos, tau, radians
from mathutils import Vector, Quaternion
import bpy

repo = Path(__file__).resolve().parents[4]
source = repo / 'docs/reference/summoner-race-review/source/Meshy_AI_Grumgaze_20261102_character.glb'
out = repo / 'artifacts/introduction'
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
scene = bpy.context.scene
arm, = [o for o in scene.objects if o.type == 'ARMATURE']
body, = [o for o in scene.objects if o.type == 'MESH' and o.find_armature()]
scene.render.engine = 'CYCLES'
scene.cycles.samples = 12
scene.cycles.use_denoising = True
scene.world = bpy.data.worlds.new('Dusk')
scene.world.color = (.35,.31,.38)
center = Vector((0,0,.82))
for position, power in [((-3,-4,5),500),((2,-2,3),180),((1,3,4),340)]:
    bpy.ops.object.light_add(type='AREA', location=position)
    light = bpy.context.object
    light.rotation_euler = (center-light.location).to_track_quat('-Z','Y').to_euler()
    light.data.energy = power
    light.data.size = 4
bpy.ops.object.camera_add()
scene.camera = cam = bpy.context.object
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 2.2
cam.location = center + Vector((-1,-1,.8165)).normalized()*6
cam.rotation_euler = (center-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
for frame in range(9):
    phase = frame*tau/8
    for thigh,shin,shoulder,sign in [(13,12,33,1),(18,17,28,-1)]:
        swing = 0 if frame == 8 else sin(phase)*sign
        lift = 0 if frame == 8 else max(0,cos(phase)*sign)
        for index,angle in [(thigh,24*swing+10*lift),(shin,-26*lift),(shoulder,-12*swing)]:
            bone = arm.pose.bones['Bone_%03d' % index]
            basis = arm.matrix_world @ bone.bone.matrix_local
            axis = basis.to_quaternion().inverted() @ Vector((1,0,0))
            bone.rotation_mode = 'QUATERNION'
            bone.rotation_quaternion = Quaternion(axis, radians(angle))
    bpy.context.view_layer.update()
    mesh = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    ground = min((mesh.matrix_world @ v.co).z for v in mesh.data.vertices)
    cam.location.z += ground
    scene.render.filepath = str(out / ('stride-%d.png' % frame))
    bpy.ops.render.render(write_still=True)
    cam.location.z -= ground
