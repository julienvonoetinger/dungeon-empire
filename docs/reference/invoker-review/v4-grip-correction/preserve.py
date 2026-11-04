import bpy,json,hashlib,array
from pathlib import Path
OUT=Path(__file__).parent
def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def snapshot(path):
 bpy.ops.wm.open_mainfile(filepath=str(path))
 body=next(o for o in bpy.data.objects if o.type=='MESH' and any(m.type=='ARMATURE'for m in o.modifiers));staff=bpy.data.objects['Staff'];arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
 def mesh(o):
  return {'geometry':digest([[list(v.co)for v in o.data.vertices],[list(p.vertices)for p in o.data.polygons]]),'uv':digest([[list(d.uv)for d in layer.data]for layer in o.data.uv_layers]),'weights':digest([sorted((o.vertex_groups[g.group].name,round(g.weight,7))for g in v.groups if o.vertex_groups[g.group].name!='GripContact')for v in o.data.vertices]),'materials':[m.name for m in o.data.materials]}
 return {'body':mesh(body),'staff':mesh(staff),'rest_rig':digest([{'name':b.name,'parent':b.parent.name if b.parent else None,'matrix':[list(row)for row in b.matrix_local]}for b in arm.data.bones]),'textures':{i.name:hashlib.sha256(i.packed_file.data).hexdigest()for i in bpy.data.images if i.packed_file}}
original=snapshot(OUT.parent/'v3-meshy-inspection/combined-source.blend');final=snapshot(OUT/'invoker-equipped.blend')
assert original==final,'Source mesh, UV, skin weights, materials, rest skeleton or packed texture changed'
(OUT/'preservation.json').write_text(json.dumps({'unchanged':True,'snapshot':final},indent=2))
print('SOURCE_PRESERVATION_OK')
