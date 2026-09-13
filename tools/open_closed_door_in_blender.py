import bpy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/models/doors/wall_v2/door_square_closed.glb"

bpy.ops.import_scene.gltf(filepath=str(SOURCE))
for obj in bpy.context.selected_objects:
    obj.select_set(True)
if bpy.context.selected_objects:
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
