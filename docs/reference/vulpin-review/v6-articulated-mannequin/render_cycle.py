"""Render the existing saved rig in four views. No fresh generation of poses."""
import bpy, math, json
from pathlib import Path
OUT=Path(__file__).resolve().parent
meta=json.loads((OUT/'rig.json').read_text())
scene=bpy.context.scene
root=bpy.data.objects['Vulpin_Ground_Root']
for direction,angle in meta['directions'].items():
    target=OUT/'renders'/direction;target.mkdir(exist_ok=True)
    root.rotation_euler.z=math.radians(angle)
    for i in range(meta['frames']):
        scene.frame_set(i+1)
        scene.render.filepath=str(target/f'{i:02d}.png')
        bpy.ops.render.render(write_still=True)
    print('DIRECTION_COMPLETE '+direction,flush=True)
print('ALL_96_FRAMES_RENDERED',flush=True)
