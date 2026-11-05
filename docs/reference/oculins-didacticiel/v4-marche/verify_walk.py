"""Reload one saved action and check its loop, foot support, tool depth and parenting."""
import math
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils.bvhtree import BVHTree

out = Path(__file__).resolve().parent
role = sys.argv[-1]
prop_name = {"mineur":"Pioche","menuisier":"Marteau","scientifique":"Diapason"}[role]
bpy.ops.wm.open_mainfile(filepath=str(out/role/(role+"-marche.blend")))
scene = bpy.context.scene
body, prop = scene.objects[role.capitalize()], scene.objects[prop_name]
arm = prop.parent
assert prop.parent_type == "BONE" and arm.animation_data.action.name == "Marche_"+role
hand = arm.pose.bones[prop.parent_bone]
shoulder = hand.parent.parent.parent

def mesh_data(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.data
    mesh.calc_loop_triangles()
    coords = np.empty(len(mesh.vertices)*3,dtype=np.float32)
    mesh.vertices.foreach_get("co",coords)
    matrix = np.asarray(evaluated.matrix_world)
    points = coords.reshape(-1,3) @ matrix[:3,:3].T + matrix[:3,3]
    tris = np.empty(len(mesh.loop_triangles)*3,dtype=np.int32)
    mesh.loop_triangles.foreach_get("vertices",tris)
    tree = BVHTree.FromPolygons(points.tolist(),tris.reshape(-1,3).tolist(),all_triangles=True)
    return points,tree

first = None
worst_ground = 0
for k in range(33):
    scene.frame_set(1+k//2,subframe=(k%2)*.5)
    # In the lowered carry, the hand hangs farther down than out to the side.
    reach = (arm.matrix_world @ hand.head) - (arm.matrix_world @ shoulder.head)
    assert -reach.z > abs(reach.x) + .03, (role,k,"raised tool arm",tuple(reach))
    points,skin = mesh_data(body)
    tool_points,tool = mesh_data(prop)
    hits = len(skin.overlap(tool))
    assert not hits,(role,k,"tool crossings",hits)
    assert tool_points[:,2].min()>.03
    worst_ground = max(worst_ground,abs(points[:,2].min()))
    transform = (arm.matrix_world@arm.pose.bones[prop.parent_bone].matrix).inverted()@prop.matrix_world
    if first is None:
        first = (points.copy(),tool_points.copy(),np.asarray(transform).copy())
    assert np.max(abs(np.asarray(transform)-first[2]))<.0001
    if k==16:
        assert np.max(abs(points-first[0]))>.16
    if k==32:
        assert np.max(abs(points-first[0]))<.0002
        assert np.max(abs(tool_points-first[1]))<.0002
assert worst_ground<.008,(role,worst_ground)
print("Verified",role,"33 samples, ground error",worst_ground)
