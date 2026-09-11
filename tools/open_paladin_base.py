import bpy
import math

SOURCE = r"C:\Users\A\AppData\Local\Temp\Meshy_AI_Gilded_Stone_Colossus_biped_Character_output.glb"

bpy.ops.import_scene.gltf(filepath=SOURCE)
armature = next((obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"), None)

bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    obj.select_set(True)
if armature:
    armature.name = "PaladinBaseRig"
    armature.show_in_front = True
    bpy.context.view_layer.objects.active = armature

    bpy.ops.object.mode_set(mode="POSE")
    right_hand = armature.pose.bones.get("RightHand")
    if right_hand:
        right_hand.rotation_mode = "XYZ"
        right_hand.rotation_euler.z += math.radians(10.0)
    bpy.ops.object.mode_set(mode="OBJECT")

for window in bpy.context.window_manager.windows:
    for area in window.screen.areas:
        if area.type != "VIEW_3D":
            continue
        region = next((region for region in area.regions if region.type == "WINDOW"), None)
        if region:
            with bpy.context.temp_override(window=window, area=area, region=region):
                bpy.ops.view3d.view_selected(use_all_regions=False)

bpy.ops.wm.save_as_mainfile(
    filepath=r"C:\Users\A\Documents\GitHub\dungeon-empire\art\blender\paladin_base_right_hand_outward.blend"
)

if armature:
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="POSE")

print("Paladin base with right hand outward rotation loaded:", SOURCE)
