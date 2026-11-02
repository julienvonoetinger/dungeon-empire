"""Offline Blender render of the contents. All distances are in dungeon cells."""
import json, math, random, sys
from pathlib import Path
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
WORK = ROOT / 'artifacts/treasury-volume'
DATA = json.loads((WORK / 'geometry.json').read_text())
ARG = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
TAU = math.tau
FRAME = DATA['frame']

def bp(p):
    return Vector((p[0], -p[1], p[2]))

class Mesh:
    def __init__(self):
        self.v, self.f, self.mat, self.stamps = [], [], [], {}

    def ring(self, pts):
        base = len(self.v)
        self.v.extend(pts)
        return list(range(base, len(self.v)))

    def face(self, ids, mat):
        self.f.append(tuple(ids))
        self.mat.append(mat)

    def band(self, a, b, mat):
        for i in range(len(a)):
            j=(i+1)%len(a)
            self.face([a[i],a[j],b[j],b[i]],mat)

    def object(self, name, mats):
        mesh=bpy.data.meshes.new(name)
        # Reflect world Y into Blender and preserve flat/smooth face orientation.
        mesh.from_pydata([bp(v) for v in self.v],[],[f[::-1] for f in self.f])
        mesh.update()
        obj=bpy.data.objects.new(name,mesh)
        bpy.context.scene.collection.objects.link(obj)
        for mat in mats: mesh.materials.append(mat)
        mesh.polygons.foreach_set('material_index',self.mat)
        if self.stamps:
            uv=mesh.uv_layers.new(name='Mint marks')
            for face,coords in self.stamps.items():
                for loop,p in zip(mesh.polygons[face].loop_indices,coords[::-1]):
                    uv.data[loop].uv=p
            for poly in mesh.polygons:
                if self.mat[poly.index] in (6,7,8,9):
                    poly.use_smooth=True
        return obj

def material(name, color, metallic, roughness):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1)
    if m.node_tree is None:m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Metallic'].default_value=metallic
    bs.inputs['Roughness'].default_value=roughness
    return m

def area(name,pos,target,power,size,color):
    lamp=bpy.data.lights.new(name,'AREA');lamp.energy=power;lamp.shape='DISK';lamp.size=size;lamp.color=color
    obj=bpy.data.objects.new(name,lamp);bpy.context.scene.collection.objects.link(obj)
    obj.location=bp(pos)
    obj.rotation_euler=(bp(target)-obj.location).to_track_quat('-Z','Y').to_euler()

def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc=bpy.context.scene
    sc.render.engine='CYCLES'; sc.cycles.samples=24;sc.cycles.use_denoising=True
    prefs=bpy.context.preferences.addons['cycles'].preferences
    for mode in ['OPTIX','CUDA']:
        try:
            prefs.compute_device_type=mode;prefs.refresh_devices()
            devices=[dev for dev in prefs.devices if dev.type==mode]
            if devices:
                for dev in prefs.devices:dev.use=dev in devices
                sc.cycles.device='GPU';break
        except (TypeError,RuntimeError):
            continue
    sc.cycles.max_bounces=6;sc.cycles.transparent_max_bounces=8
    sc.render.film_transparent=True
    sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA'
    sc.render.resolution_x=FRAME[2]*2;sc.render.resolution_y=FRAME[3]*2;sc.render.resolution_percentage=100
    sc.world=bpy.data.worlds.new('Cool ambient')
    if sc.world.node_tree is None:sc.world.use_nodes=True
    bg=sc.world.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value=(.34,.40,.54,1);bg.inputs['Strength'].default_value=.35
    sc.view_settings.view_transform='Standard';sc.view_settings.exposure=-.80
    camdata=bpy.data.cameras.new('Kit projection');cam=bpy.data.objects.new('Kit camera',camdata);sc.collection.objects.link(cam)
    right=bp(DATA['camera']['x']).normalized(); up=-bp(DATA['camera']['y']).normalized(); eye=bp(DATA['camera']['eye']).normalized()
    cam.rotation_euler=Matrix((right,up,eye)).transposed().to_euler()
    factor=DATA['density']*Vector(DATA['camera']['x']).length
    centre=right*(FRAME[0]+FRAME[2]/2)/factor-up*(FRAME[1]+FRAME[3]/2)/factor
    cam.location=centre+eye*10
    camdata.type='ORTHO';camdata.ortho_scale=FRAME[2]/factor;sc.camera=cam
    bpy.context.view_layer.update()
    for pt in [(0,0,0),(1,0,0),(0,1,.5),(2,2,.87)]:
        uv=world_to_camera_view(sc,cam,bp(pt))
        for val,expected in [(uv.x*FRAME[2]+FRAME[0],Vector(pt).dot(Vector(DATA['camera']['x']))*DATA['density']),
                             ((1-uv.y)*FRAME[3]+FRAME[1],Vector(pt).dot(Vector(DATA['camera']['y']))*DATA['density'])]:
            assert abs(val-expected)<.001,(pt,val,expected)
    area('Large softbox',(-2,-3,5),(1,1,.2),430,3.2,(1,.90,.76))
    area('Cool fill',(3,2,3.8),(1,1,0),165,4.2,(.73,.81,1))
    area('Rim',(-1.2,3.2,3.4),(1,1,.1),155,2.4,(1,.87,.65))
    return sc

def materials():
    mats=[
        material('Antique gold',(.44,.194,.030),.67,.37),
        material('Honey gold',(.59,.287,.045),.66,.34),
        material('Cool brass',(.35,.156,.025),.60,.41),
        material('Minted rim',(.73,.39,.072),.66,.30),
        material('Coin edge',(.25,.091,.015),.54,.39),
        material('Buried umber',(.15,.052,.010),.40,.50),
        material('Oxblood leather',(.139,.045,.022),.03,.70),
        material('Leather edge',(.265,.107,.047),.08,.59),
        material('Lining',(.047,.022,.019),0,.78),
        material('Waxed cord',(.39,.156,.049),.09,.51),
    ]
    # The die impressions are actual isolated coins from the approved V6 floor painting.
    mint=material('Stamped faces',(.6,.3,.05),.30,.44)
    tile=mint.node_tree.nodes.new('ShaderNodeTexImage')
    tile.image=bpy.data.images.load(str(HERE.parent/'v6-textures/source/monnaie-plan.png'))
    mint.node_tree.links.new(tile.outputs['Color'],mint.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    mats.append(mint)
    # Fine warm/cool mottling on leather breaks up the smooth folds like the kit artwork.
    for m in mats[6:8]:
        ns=m.node_tree.nodes;links=m.node_tree.links
        noise=ns.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=11
        noise.inputs['Detail'].default_value=2
        ramp=ns.new('ShaderNodeValToRGB');cs=ramp.color_ramp.elements
        cs[0].position=.20;cs[0].color=(.072,.018,.013,1)
        cs[1].position=.82;cs[1].color=(.25,.085,.026,1)
        links.new(noise.outputs['Fac'],ramp.inputs[0]);links.new(ramp.outputs[0],ns.get('Principled BSDF').inputs['Base Color'])
    return mats

STAMPS=[(157,796,202,839),(1056,168,1101,211),(52,995,96,1038),(248,651,291,693),(654,260,698,301),(317,460,359,500)]

def coin(mesh, stats, pos, r, slope, tone, rotation=0, thickness=None):
    # Flat face, minted bevel, dark vertical edge and small lozenge struck into the die.
    thickness=thickness or r*.21
    n=14
    def ring(radius,z,count=n):
        pts=[]
        for i in range(count):
            angle=rotation+i*TAU/count;dx=math.cos(angle)*radius;dy=math.sin(angle)*radius
            pts.append((pos[0]+dx,pos[1]+dy,pos[2]+z+dx*slope[0]+dy*slope[1]))
        return mesh.ring(pts)
    prev=ring(r*.92,0)
    mesh.face(prev[::-1],4)
    for radius,z,mat in [(1,.16,4),(1,.70,4),(.94,1,3),(.83,.98,tone)]:
        nex=ring(r*radius,thickness*z);mesh.band(prev,nex,mat);prev=nex
    mesh.face(prev,10)
    l,t,rr,bb=STAMPS[len(stats)%len(STAMPS)]
    mesh.stamps[len(mesh.f)-1]=[((l+rr+(rr-l)*.87*math.cos(i*TAU/n))/2508,
                                  1-(t+bb+(bb-t)*.87*math.sin(i*TAU/n))/2508) for i in range(n)]
    stats.append(tuple(pos))

def pouch(mesh,stats,to_world,u,v,z,r,h,opened,rng):
    n=24; phase=rng.random()*TAU
    profile=[(.0,.61),(.08,.89),(.36,1.05),(.58,.97),(.74,.79)]
    profile+=([(.88,.72),(1.0,.84)] if opened else [(.80,.48),(.84,.30),(.92,.40),(1.0,.61)])
    def hoop(t,rad,lip=False):
        pts=[]
        for i in range(n):
            a=i*TAU/n
            folds=.075*math.sin(3*a+phase)+(.033+.12*t)*math.cos(6*a+1.3*t+phase)
            if not opened and t>.73:folds+=.05*math.cos(8*a)
            radius=r*rad*(1+folds)
            wave=(.018 if opened else .025) * math.cos(5*a+phase)*t if lip else .009*math.cos(5*a+phase)*t
            pts.append(to_world(u+radius*math.cos(a)+r*.09*t,v+radius*.83*math.sin(a),z+h*t+wave))
        return mesh.ring(pts)
    prev=hoop(*profile[0]);mesh.face(prev[::-1],6)
    for i,(t,rad) in enumerate(profile[1:]):
        cur=hoop(t,rad,i==len(profile)-2);mesh.band(prev,cur,6);prev=cur
    lip=hoop(1,.73 if opened else .49,True);mesh.band(prev,lip,7)
    inner=hoop(.74,.57 if opened else .24);mesh.band(lip,inner,8);mesh.face(inner,8)
    if opened:
        for row in range(3):
            for k in range(5-row):
                dx=(k-(4-row)/2)*r*.22;dy=(row-1)*r*.26
                coin(mesh,stats,to_world(u+dx,v+dy,z+h*(.87+.035*row)),r*.23,(.04,-.07),rng.randrange(3),rng.random())
    else:
        for j in range(2):
            a=hoop(.798+j*.027,.555-j*.07);b=hoop(.827+j*.027,.525-j*.07)
            mesh.band(a,b,9)
        # Cord ends hang down the front of the gathered bag.
        for sign in [-1,1]:
            prev=None
            for k in range(8):
                t=k/7; xx=u+sign*r*(.16+.45*t+.14*math.sin(t*4)); yy=v+r*(.40+.53*t)
                cur=mesh.ring([to_world(xx+.008*math.cos(a*TAU/7),yy+.008*math.sin(a*TAU/7),z+h*(.82-.38*t)) for a in range(7)])
                if prev:mesh.band(prev,cur,9)
                prev=cur
    # Two stitched gores strengthen the read of leather at mobile size.
    for angle in [.14,2.72]:
        def edge(a,t,rad):
            radius=r*rad*(1+.045*math.sin(3*a+phase)+(.025+.09*t)*math.cos(6*a+.4+phase))+.0006
            return to_world(u+radius*math.cos(a)+r*.09*t,v+radius*.83*math.sin(a),z+h*t+.009*math.cos(5*a+phase)*t)
        rows=[mesh.ring([edge(angle-.015,t,rad),edge(angle+.015,t,rad)]) for t,rad in profile[:5]]
        for a,b in zip(rows,rows[1:]): mesh.face([a[0],a[1],b[1],b[0]],7)

def ingot(mesh,world,u,v,z,angle):
    # Cast bars taper toward the stamped top. Build in local coordinates so
    # they can be stacked flat, even where the loose coins form a slope.
    prev=None
    for height,l,w in [(0,.111,.052),(.008,.119,.055),(.064,.104,.045),(.071,.099,.041)]:
        corners=[(-l+.014,-w),(l-.014,-w),(l,-w+.011),(l,w-.011),
                 (l-.014,w),(-l+.014,w),(-l,w-.011),(-l,-w+.011)]
        cur=mesh.ring([world(u+x*math.cos(angle)-y*math.sin(angle),v+x*math.sin(angle)+y*math.cos(angle),z+height) for x,y in corners])
        if prev:mesh.band(prev,cur,3 if height==.071 else 1)
        prev=cur
    mesh.face(prev,1)
    stamp=mesh.ring([world(u+x,v+y,z+.072) for x,y in [(0,-.020),(.028,0),(0,.020),(-.028,0)]])
    mesh.face(stamp,4)

def fill(b,world_data,mesh,stats,rng,draw_coin=coin,draw_pouch=pouch,shape_height=None):
    full=b['count']==2;lo,hi=b['lo'],b['hi']
    axis=0 if b['step'][0] else 1
    # When the corridor meets the end of this wall, its approach runs across
    # our pile's toe. Shorten that end of the contents, never the stone socket.
    mouth=world_data['side']
    if abs(b['start'][1-axis]-world_data['slot']-.5)<.9:
        if (axis,mouth) in [(0,'W'),(1,'N')]:lo=max(lo,.38)
        if (axis,mouth) in [(0,'E'),(1,'S')]:hi=min(hi,1.62)
    mid=(lo+hi)/2
    inner=(hi-lo)*(.425 if full else .40)-(.115 if full else .086)
    def world(u,v,z):
        return (*[b['start'][i]+u*b['step'][i]+v*b['inside'][i] for i in range(2)],z)
    def run(s):
        return (.67 if full else .46)*math.sqrt(max(0,1-s*s))*(.93+.10*math.sin(6*s+.44))
    def height(u,v):
        s=(u-mid)/inner; dist=run(s)
        if abs(s)>=1 or v<-.053 or v>=dist:return 0.
        crown=(.49 if full else .34)*max(0,1-s*s)**.62*(.67+.33*math.exp(-((s+.23)/.37)**2)+.23*math.exp(-((s-.60)/.18)**2))
        tread=1-max(0,v-.032)/max(.001,dist-.032)
        z=max(.002,crown*max(0,tread)**.87)
        return shape_height(u,v,z) if shape_height else z
    # Buried fill is a closed bank, including the irregular foot of the pile.
    prev=None;front=[];back=[]
    for i in range(33):
        s=-.995+1.99*i/32;u=mid+s*inner; verts=[]
        for j in range(15):
            v=-.049+(run(s)+.049)*j/14
            verts.append(world(u,v,max(.002,height(u,v)-.024)))
        row=mesh.ring(verts)
        front.append(verts[-1]);back.append(verts[0])
        if prev:
            for j in range(14):mesh.face([prev[j],row[j],row[j+1],prev[j+1]],5)
        prev=row
    for edge in [front,back]:
        a=mesh.ring(edge);bottom=mesh.ring([(x,y,0.) for x,y,z in edge])
        for i in range(len(a)-1):mesh.face([a[i],a[i+1],bottom[i+1],bottom[i]],5)
    # Overlapping coins form a surface following the slope and break its outline.
    pitch=.048 if full else .043;v=-.017;line=0
    start=len(stats)
    while v<( .73 if full else .53):
        u=mid-inner+rng.uniform(.006,pitch)
        while u<mid+inner-.016:
            uu=u+rng.uniform(-.011,.011);vv=v+rng.uniform(-.017,.017)
            z=height(uu,vv)
            if z>.004 and abs(uu-mid)<inner-.034:
                slopeU=(height(uu+.006,vv)-height(uu-.006,vv))/.012
                slopeV=(height(uu,vv+.006)-height(uu,vv-.006))/.012
                slopeU=max(-.45,min(.45,slopeU))*.45+rng.uniform(-.17,.17)
                slopeV=max(-.78,min(.3,slopeV))*.50+rng.uniform(-.14,.14)
                slope=tuple(slopeU*b['step'][i]+slopeV*b['inside'][i] for i in range(2))
                draw_coin(mesh,stats,world(uu,vv,max(z,.047 if vv<.085 else 0)+rng.uniform(-.003,.013)),rng.uniform(.026,.038),slope,rng.randrange(3),rng.random()*TAU)
            u+=rng.uniform(.84,1.15)*pitch
        line+=1;v+=pitch*.85
    # Orderly columns at one side contrast with the slumped heap.
    for uoff,vv,count in ([(.62,.33,15),(.79,.28,10),(-.47,.55,15),(-.32,.59,11),(-.65,.51,8)] if full else [(-.49,.28,11),(.39,.30,7)]):
        uu=mid+uoff*inner;base=height(uu,vv);r=.040 if full else .035;thick=.011
        for k in range(count):
            draw_coin(mesh,stats,world(uu+rng.uniform(-.002,.002),vv+rng.uniform(-.002,.002),base+k*thick),r,(.01,-.015),rng.randrange(3),.17*k,thick)
    # Bags stand on the floor at the toe of the bank, not on the treasure-room centre.
    bag_u=mid+inner*(.55 if full else -.38)
    bag_v=(.50 if full else .43)
    draw_pouch(mesh,stats,world,bag_u,bag_v,0,.16 if full else .12,.25 if full else .26,full,rng)
    if not full:
        # The short recess holds cast bullion below the coins. Keep the small
        # stack beyond the foot of the bank so the supporting bars are visible.
        uu=mid+inner*.53;vv=.44
        for off in [-.055,.055]:ingot(mesh,world,uu,vv+off,0,.045)
        ingot(mesh,world,uu,vv,.072,-.025)
    return {'side':b['side'],'count':len(stats)-start,'peak':max(p[2] for p in stats[start:])}

def blocker(world):
    mesh=Mesh()
    for f in world['faces']:mesh.face(mesh.ring(f),0)
    obj=mesh.object('Actual kit masonry · shadow receiver',[material('Neutral receiving surface',(.32,.32,.34),0,.80)])
    obj.is_shadow_catcher=True
    # Their existing kit shadow is already in the receiving surface. Only
    # contents cast a new shadow into the transparent catcher.
    obj.visible_shadow=False
    return obj, BVHTree.FromPolygons([bp(v) for v in mesh.v],mesh.f)

def write_section(b,mesh):
    # Intersect real faces halfway along the main alcove. The profile uses
    # the same scale for height and depth, independent of the game camera.
    u=(b['hi']+b['lo'])*.5-.1
    def coords(p):
        dx=p[0]-b['start'][0];dy=p[1]-b['start'][1]
        return dx*b['step'][0]+dy*b['step'][1]-u, dx*b['inside'][0]+dy*b['inside'][1], p[2]
    def cuts(poly):
        pts=[coords(p) for p in poly];hits=[]
        for a,c in zip(pts,pts[1:]+pts[:1]):
            if (a[0]<0)==(c[0]<0):continue
            t=-a[0]/(c[0]-a[0])
            hits.append([a[i]+(c[i]-a[i])*t for i in (1,2)])
        return hits if len(hits)==2 else None
    lines=[cuts([mesh.v[i] for i in face]) for face in mesh.f]
    rock=[cuts(f) for f in DATA['worlds']['S1']['faces']]
    # Restrict the section to the blind vault and the part of its floor that receives the heap.
    (WORK/'section.json').write_text(json.dumps({'gold':[l for l in lines if l],
      'stone':[l for l in rock if l and all(-.10<x<.9 for x,z in l)]}))

def render_world(name):
    sc=setup()
    mats=materials(); world=DATA['worlds'][name]
    wall,bvh=blocker(world)
    mesh=Mesh(); centres=[];reports=[]
    for b in world['bays']:
        reports.append(fill(b,world,mesh,centres,random.Random(177 if b['count']==2 else 373)))
    obj=mesh.object('Coins, stacks and leather purses',mats)
    if name=='S1':write_section(world['bays'][0],mesh)
    # Sunken floor receiver. It cannot draw a shadow in the rock or in the corridor.
    plane=Mesh();plane.face(plane.ring([(0,0,.001),(2,0,.001),(2,2,.001),(0,2,.001)]),0)
    ground=plane.object('Floor contact shadow',[material('Grey receiver',(.33,.34,.36),0,.85)])
    ground.is_shadow_catcher=True
    eye=bp(DATA['camera']['eye']).normalized()
    for report,b in zip(reports,world['bays']):
        assert report['peak']>(.36 if b['count']==2 else .24),report
    hidden=sum(bvh.ray_cast(bp(p)+eye*.001,eye,3)[0] is not None for p in centres)
    assert 0<hidden<len(centres)
    for p in mesh.v:
        depth={'N':p[1],'S':2-p[1],'W':p[0],'E':2-p[0]}[world['side']]
        along=p[0] if world['side'] in ('N','S') else p[1]
        assert depth>.35 or abs(along-world['slot']-.5)>.35,('entrance',name,p)
        assert min(max(abs(p[0]-1),abs(p[1]-1)),1)>.25,('centre',name,p)
    bpy.context.view_layer.update()
    sc.render.filepath=str(WORK/(name+'.png'));bpy.ops.render.render(write_still=True)
    out={'slot':name,'coins':len(centres),'blockedCentres':hidden,'visibleCentres':len(centres)-hidden,'bays':reports}
    (WORK/(name+'.json')).write_text(json.dumps(out,indent=2))
    print('TREASURY',json.dumps(out),flush=True)

if __name__ == '__main__':
    for name in ARG or list(DATA['worlds']):
        render_world(name)
