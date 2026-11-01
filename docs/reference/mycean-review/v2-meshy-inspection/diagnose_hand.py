import bpy, math, json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent
DUMP=OUT.parents[3]/'artifacts/mycean-inspection/hand-diagnostics';DUMP.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(OUT/'mycean-equipped-review.blend'))
scene=bpy.context.scene;camera=scene.camera
bpy.data.objects['staff_output_unwrapped'].hide_render=True
body=bpy.data.objects['mycean_output_unwrapped'];lat=bpy.data.objects.get('MyceanGripCorrective')
if lat:
 print('LATTICE_EXTENTS',[[min(p.co[i] for p in lat.data.points),max(p.co[i] for p in lat.data.points)] for i in range(3)])
# Isolate the hand for genuine top-view diagnosis (the large cap occludes it).
ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());me=bpy.data.meshes.new_from_object(ev)
for p in me.vertices:p.co=body.matrix_world@p.co
vg=body.vertex_groups.get('StaffGripCorrective')
selected={v.index for v in me.vertices if vg and any(g.group==vg.index and g.weight>.5 for g in v.groups)}
verts=[tuple(v.co) for v in me.vertices];faces=[list(p.vertices) for p in me.polygons if any(i in selected for i in p.vertices)]
diagnostic=bpy.data.objects.new('IsolatedHand',me);scene.collection.objects.link(diagnostic)
import bmesh
bm=bmesh.new();bm.from_mesh(me)
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in selected],context='VERTS');bm.to_mesh(me);bm.free()
body.hide_render=True
focus=Vector((.64,-.15,.73));camera.data.ortho_scale=.46
for name,d in [('front',(0,-1,0)),('right',(1,0,0)),('top',(0,0,1)),('back',(0,1,0))]:
 camera.location=focus+Vector(d)*5
 camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(DUMP/('hand-diagnostic-'+name+'.png'));bpy.ops.render.render(write_still=True)
