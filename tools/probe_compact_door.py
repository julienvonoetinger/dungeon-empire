"""Read-only fitting study: reduce crown height without resizing the hero."""
import bpy, json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/'docs/reference/door-redesign/seal-v1/hero-fit-v11-compact'
out.mkdir(parents=True,exist_ok=True)
geometry=json.loads((out.parent/'hero-fit-v9/geometry.json').read_text())
profile=geometry['leaf']['profileXZ']; wall=.3133333333333333
k=.85/(2.35*(.5**.5))
poses=[]
for version,file,count in [('v16-meshy-walk','vulpin-walk-poses.blend',8),('v17-meshy-run','vulpin-run-poses.blend',8),('v19-hurt-recoil','vulpin-hurt-poses.blend',1)]:
    bpy.ops.wm.open_mainfile(filepath=str(root/'docs/reference/vulpin-review'/version/file))
    for i in range(count):
        bpy.context.scene.frame_set(i+1)
        obj=bpy.data.objects['output_unwrapped'].evaluated_get(bpy.context.evaluated_depsgraph_get()); mesh=obj.to_mesh()
        points=[obj.matrix_world@v.co for v in mesh.vertices];obj.to_mesh_clear()
        poses.append((version,i,[(.5+p.x*k,p.z*k) for p in points if p.z>.00001]))
def inside(p,poly):
    signs=[(b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]) for a,b in zip(poly,poly[1:]+poly[:1])]
    return all(x<=.00002 for x in signs) or all(x>=-.00002 for x in signs)
results=[]
for scale in [.75,.78,.80,.82,.84,.86]:
    for width in [1,1.1,1.2,1.3]:
        new=[(.5+(x-.5)*width,z if z<=wall else wall+(z-wall)*scale) for x,z in profile]
        fails=[{'action':v,'pose':i,'outside':sum(not inside(p,new) for p in ps)} for v,i,ps in poses]
        results.append({'scale':scale,'width_factor':width,'opening_height':max(p[1] for p in new),'outer_height':wall+(1.445-wall)*scale,'failed': [f for f in fails if f['outside']]})
(out/'fit-study.json').write_text(json.dumps(results,indent=2))
print('COMPACT_FITS',json.dumps([r for r in results if not r['failed']]))
flatter=[]
for shoulder in [.80,.84,.88,.90]:
    for apex in [.92,.94,.96,.98]:
        def zmap(z):
            if z<=wall:return z
            if z<=.82:return wall+(z-wall)*(shoulder-wall)/(.82-wall)
            return shoulder+(z-.82)*(apex-shoulder)/(1.063-.82)
        new=[(x,zmap(z)) for x,z in profile]
        fails=[{'action':v,'pose':i,'outside':sum(not inside(p,new) for p in ps)} for v,i,ps in poses]
        flatter.append({'shoulder':shoulder,'apex':apex,'failed':[f for f in fails if f['outside']]})
(out/'flatter-arch-study.json').write_text(json.dumps(flatter,indent=2))
print('FLATTER_FITS',json.dumps([r for r in flatter if not r['failed']]))
