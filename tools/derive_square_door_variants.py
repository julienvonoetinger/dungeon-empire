import bpy
import bmesh
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/models/doors/wall_v2/door_square_closed.glb"
OPEN_OUTPUT = ROOT / "assets/models/doors/wall_v2/door_square_open_derived.glb"
DESTROYED_OUTPUT = ROOT / "assets/models/doors/wall_v2/door_square_destroyed_derived.glb"
EDITABLE_OUTPUT = ROOT / "assets/models/doors/wall_v2/door_square_editable.blend"

# The imported Meshy gate spans X [-0.5, 0.5] and Z [-0.47, 0.47].
# This central rectangle contains the two movable leaves, while keeping the
# stone surround and its purple details untouched.
LEAF_HALF_WIDTH = 0.235
LEAF_HALF_HEIGHT = 0.40


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def import_closed_gate() -> bpy.types.Object:
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != 1:
        raise RuntimeError(f"Expected one Meshy mesh, found {len(meshes)}")
    return meshes[0]


def in_leaf_region(co) -> bool:
    return abs(co.x) < LEAF_HALF_WIDTH and abs(co.z) < LEAF_HALF_HEIGHT


def keep_faces(obj: bpy.types.Object, keep) -> None:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    remove = [face for face in bm.faces if not keep(face.calc_center_median())]
    bmesh.ops.delete(bm, geom=remove, context="FACES")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def duplicate(obj: bpy.types.Object, name: str) -> bpy.types.Object:
    copy = obj.copy()
    copy.data = obj.data.copy()
    copy.name = name
    bpy.context.collection.objects.link(copy)
    return copy


def export_only(objects, destination: Path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(destination),
        export_format="GLB",
        use_selection=True,
        export_materials="EXPORT",
    )


def make_open() -> None:
    clear_scene()
    gate = import_closed_gate()
    keep_faces(gate, lambda center: not in_leaf_region(center))
    gate.name = "SquareDoorOpenFrame"
    export_only([gate], OPEN_OUTPUT)


def make_destroyed() -> None:
    clear_scene()
    gate = import_closed_gate()
    debris = duplicate(gate, "SquareDoorDebris")
    keep_faces(gate, lambda center: not in_leaf_region(center))
    keep_faces(debris, in_leaf_region)
    # Reuse the actual door leaves as fallen wreckage instead of inventing a
    # second art style. Flatten them into a compact pile at the threshold.
    debris.rotation_euler.x = math.radians(78.0)
    debris.scale = (0.88, 0.58, 0.42)
    debris.location = (0.0, -0.015, -0.37)
    export_only([gate, debris], DESTROYED_OUTPUT)


def make_editable() -> None:
    clear_scene()
    source = import_closed_gate()
    frame = duplicate(source, "DoorFrame")
    left = duplicate(source, "DoorLeft")
    right = duplicate(source, "DoorRight")
    bpy.data.objects.remove(source, do_unlink=True)
    keep_faces(frame, lambda center: not in_leaf_region(center))
    keep_faces(left, lambda center: in_leaf_region(center) and center.x < 0.0)
    keep_faces(right, lambda center: in_leaf_region(center) and center.x >= 0.0)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [frame, left, right]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = left
    bpy.ops.wm.save_as_mainfile(filepath=str(EDITABLE_OUTPUT))


make_open()
make_destroyed()
make_editable()
