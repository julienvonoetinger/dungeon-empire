import bpy,json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'invoker-inspection.blend'))
previous=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(OUT.parent/'source/staff-original.glb'))
staff=[o for o in bpy.data.objects if o not in previous and o.type=='MESH']
report={'meshes':[]}
for o in staff:
    p=[o.matrix_world@v.co for v in o.data.vertices];o.data.calc_loop_triangles()
    report['meshes'].append({'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'min':[min(v[i] for v in p)for i in range(3)],'max':[max(v[i] for v in p)for i in range(3)],'matrix':[list(row)for row in o.matrix_world]})
    o.name='Staff'
report['images']=[{'name':i.name,'size':list(i.size),'packed':bool(i.packed_file)}for i in bpy.data.images]
(OUT/'staff-inspection.json').write_text(json.dumps(report,indent=2))
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'combined-source.blend'),compress=True)
print(json.dumps(report))
