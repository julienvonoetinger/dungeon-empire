"""Blender background: complete held meshes swept through the opening in XZ."""
import bpy, json, hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
base=root/'docs/reference/door-redesign/seal-v1'
old=json.loads((base/'wireframe-v6-clean-leaf/geometry.json').read_text())['leaf']['profileXZ']
geometry=json.loads((base/'hero-fit-v11-compact/geometry.json').read_text())
new=geometry['leaf']['profileXZ']
k=.85/(2.35*(.5**.5))
def inside(p,poly):
    signs=[(b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]) for a,b in zip(poly,poly[1:]+poly[:1])]
    return all(x<=.00002 for x in signs) or all(x>=-.00002 for x in signs)
def view_bounds(points):
    result={}
    for facing,tr in {'se':lambda x,y,z:(-y,-x,z),'sw':lambda x,y,z:(x,-y,z),'nw':lambda x,y,z:(y,x,z),'ne':lambda x,y,z:(-x,y,z)}.items():
        ps=[tuple(v*k for v in tr(p.x,p.y+.2,p.z)) for p in points]
        result[facing]={'min':[min(p[j] for p in ps) for j in range(3)],'max':[max(p[j] for p in ps) for j in range(3)]}
    return result
result=[]
for action,name,count,kind in [
('v16-meshy-walk','vulpin-walk-poses.blend',8,'walk'),
('v17-meshy-run','vulpin-run-poses.blend',8,'run'),
('v19-hurt-recoil','vulpin-hurt-poses.blend',1,'idle')]:
    bpy.ops.wm.open_mainfile(filepath=str(root/'docs/reference/vulpin-review'/action/name))
    for i in range(count):
        bpy.context.scene.frame_set(i+1)
        obj=bpy.data.objects['output_unwrapped'].evaluated_get(bpy.context.evaluated_depsgraph_get())
        me=obj.to_mesh();points=[obj.matrix_world@v.co for v in me.vertices];obj.to_mesh_clear()
        transverse=[(.5+p.x*k,p.z*k) for p in points if p.z>.00001]
        fails=[p for p in transverse if not inside(p,new)]
        result.append({'action':action,'kind':kind,'pose':i,'old_outside':sum(not inside(p,old) for p in transverse),'new_outside':len(fails),'bounds':view_bounds(points)})
source=root/'docs/reference/vulpin-review/source/Meshy_AI_Character_output.glb'
# Lockpicking is performed in front of the leaf, not by translating the
# crouched/picking body through it. Clip each body triangle to each masonry
# face's conservative XZ box, then require separation from its frontmost Y.
# Using one global tier front plane gives false positives in the new tall
# empty opening, since only the side posts extend to that plane.
def clip_axis(poly,axis,bound,greater):
    result=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        inside=lambda p:p[axis]>=bound-1e-10 if greater else p[axis]<=bound+1e-10
        if inside(a):result.append(a)
        if inside(a)!=inside(b):
            t=(bound-a[axis])/(b[axis]-a[axis])
            result.append(tuple(x+(y-x)*t for x,y in zip(a,b)))
    return result
lock_checks=[]
bpy.ops.wm.open_mainfile(filepath=str(root/'docs/reference/vulpin-review/v26-lower-lock-review/vulpin-lockpick-poses.blend'))
faces=[f for f in geometry['door']['faces'] if not f['kind'].startswith('leaf')]
boxes=[([min(p[j] for p in f['points']) for j in range(3)],[max(p[j] for p in f['points']) for j in range(3)]) for f in faces]
leaf=max(p[1] for f in geometry['door']['faces'] if f['kind']=='leaf' for p in f['points'])
for i in range(8):
    bpy.context.scene.frame_set(i+1)
    obj=bpy.data.objects['output_unwrapped'].evaluated_get(bpy.context.evaluated_depsgraph_get())
    me=obj.to_mesh();me.calc_loop_triangles()
    tip=bpy.data.objects['Pick'].data.splines[0].points[-1].co
    points=[obj.matrix_world@v.co for v in me.vertices]
    points=[(.5+p.x*k,leaf+(p.y-tip.y)*k,p.z*k) for p in points]
    clearances=[]
    for triangle in me.loop_triangles:
        original=[points[n] for n in triangle.vertices]
        lo=[min(p[j] for p in original) for j in range(3)]
        hi=[max(p[j] for p in original) for j in range(3)]
        for lower,upper in boxes:
            if any(hi[j]<lower[j]-1e-9 or lo[j]>upper[j]+1e-9 for j in [0,2]):continue
            clipped=original
            for j in [0,2]:
                clipped=clip_axis(clipped,j,lower[j],True)
                clipped=clip_axis(clipped,j,upper[j],False)
            if clipped:clearances.append(min(p[1] for p in clipped)-upper[1])
    # A wider opening can make every triangle's XZ footprint disjoint from
    # masonry. That is separated geometry, not an untested contact distance.
    lock_checks.append({'pose':i,'triangle_face_pairs':len(clearances),'xz_disjoint':not clearances,'clearance_cells':min(clearances) if clearances else None})
    obj.to_mesh_clear()
report={'method':'All evaluated mesh vertices projected onto convex transverse XZ opening; conservative translational sweep through leaf plane. No self-collision, hinge mechanics or continuous animation claim.',
        'geometry_sha256':hashlib.sha256((base/'hero-fit-v11-compact/geometry.json').read_bytes()).hexdigest(),
        'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'samples':result,
        'lock_masonry_method':'Clip body triangles to each masonry face XZ bounding rectangle, then require every clipped point in front of that face maximum Y. This conservative rectangle/plane check includes triangle interiors. Tools intentionally contact leaf and are excluded.',
        'lock_masonry':lock_checks}
(base/'hero-fit-v11-compact/passage-validation.json').write_text(json.dumps(report,indent=2))
assert all(r['new_outside']==0 for r in result), 'Hero still exceeds new opening'
assert all(r['old_outside']>0 for r in result), 'Regression baseline must reproduce undersized door'
assert all(c['xz_disjoint'] or c['clearance_cells']>.003 for c in lock_checks), 'Lockpicking mesh intersects masonry'
print(f'PASSAGE: {len(result)} full-mesh held poses fit; all fail old opening.')
distances=[c['clearance_cells'] for c in lock_checks if not c['xz_disjoint']]
print('LOCK MASONRY:',len(lock_checks),'checks;',sum(c['xz_disjoint'] for c in lock_checks),'XZ-disjoint; minimum tested separation',min(distances) if distances else 'not applicable')

