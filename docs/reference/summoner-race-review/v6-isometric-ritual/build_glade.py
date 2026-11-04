"""Build the clearing and its animated celebrant from the original rig in background Blender."""
import math
import random
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

repo = Path(__file__).resolve().parents[4]
source = repo / "docs/reference/summoner-race-review/source/Meshy_AI_Grumgaze_20261102_character.glb"
dest = Path(__file__).resolve().parent / "source_project/assets/game/introduction/ritual-glade.glb"
rng = random.Random(480)
tau = math.tau
sin, cos = math.sin, math.cos
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
arm, = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
body, = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.find_armature()]
# Keep skin, UVs and painting. Fit on the actual altar-side flagstone.
actor = bpy.data.objects.new("Oculin", None)
bpy.context.collection.objects.link(actor)
for obj in (body, arm):
    if obj.parent is None: obj.parent = actor
actor.location = (-.22, 1.57, .147)
actor.rotation_euler.z = math.radians(12)
for image in bpy.data.images:
    if image.packed_file and max(image.size)>1024:
        image.scale(1024,1024)
        image.pack()

# Animate shoulders, elbows and spine in their original rest bases; soles stay planted.
for frame,reach,bow in [(1,0,0),(20,.45,-2),(46,1,-5),(63,1,-5),(85,.38,5),(110,0,12),(130,0,10)]:
    for index, axis, angle in [(33,(0,1,0),-20*reach),(28,(0,1,0),20*reach),
                               (32,(1,0,0),-44*reach),(27,(1,0,0),-44*reach),
                               (8,(1,0,0),bow),(22,(1,0,0),bow*.25)]:
        bone = arm.pose.bones['Bone_%03d' % index]
        local = (arm.matrix_world @ bone.bone.matrix_local).to_quaternion().inverted() @ Vector(axis)
        bone.rotation_quaternion = Quaternion(local,math.radians(angle))
        bone.keyframe_insert(data_path='rotation_quaternion',frame=frame)
arm.animation_data.action.name = "Invocation"
bpy.context.scene.render.fps = 30
bpy.context.scene.frame_set(1)

# Batch the painted facets by material. The scenery uses three draw surfaces.
surfaces = {}
def rgb(hex_value):
    vals = [int(hex_value[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(((v+.055)/1.055)**2.4 if v>.04045 else v/12.92 for v in vals)
def face(points, color, kind='Stone', tone=1):
    vertices, faces, colors = surfaces.setdefault(kind,([],[],[]))
    faces.append(tuple(range(len(vertices),len(vertices)+len(points))))
    vertices.extend(points)
    colors.extend([tuple(min(1,c*tone) for c in rgb(color))+(1,)]*len(points))
def rings(cx,cy,layers,colors,kind='Stone',phase=0,shape=None):
    shape = shape or [1]*9
    count=len(shape)
    rows=[]
    for z,rx,ry,ox,oy in layers:
        rows.append([(cx+ox+rx*v*cos(phase+i*tau/count),cy+oy+ry*v*sin(phase+i*tau/count),z) for i,v in enumerate(shape)])
    for j,(a,b) in enumerate(zip(rows,rows[1:])):
        for i in range(count):
            k=(i+1)%count
            face([a[i],a[k],b[k],b[i]],colors[min(j,len(colors)-1)],kind,rng.uniform(.83,1.10))
    face(rows[-1],colors[-1],kind)
def taper(a,b,r1,r2,color,kind='Stone',n=6):
    a,b=Vector(a),Vector(b)
    u=(b-a).normalized().cross(Vector((0,0,1)))
    if u.length<.01: u=Vector((1,0,0))
    u.normalize()
    v=(b-a).normalized().cross(u)
    rim=[u*cos(i*tau/n)+v*sin(i*tau/n) for i in range(n)]
    for i in range(n):
        k=(i+1)%n; face([a+rim[i]*r1,a+rim[k]*r1,b+rim[k]*r2,b+rim[i]*r2],color,kind,rng.uniform(.85,1.1))
def stroke(a,b,width,color,kind='Etching'):
    taper(a,b,width,width,color,kind,4)
def polar(r,a,z):
    return (r*cos(a), r*sin(a),z)

# Broken deep rock shelf with a grass lip, on a broad sloping forest floor.
rings(0,0,[(-2.1,6.5,5.9,0,0),(-1.0,6.9,6.3,0,0),(-.30,6.85,6.3,.04,0),(-.10,6.8,6.25,0,0)],
      ['282837','4a4047','5b5350','414a40'],shape=[rng.uniform(.87,1.11) for _ in range(40)])
rings(0,0,[(-.125,45,45,0,0),(-.108,45,45,0,0)],['293838','283b39'],shape=[1]*48)
# Concentric segmented weathered stone pavement.
def paving(inner,outer,count,offset,base,top,palette):
    for i in range(count):
        a=offset+i*tau/count+.012; b=offset+(i+1)*tau/count-.012
        pts=[polar(inner,a,base),polar(outer,a,base),polar(outer,b,base),polar(inner,b,base)]
        mid=[(x,y,top-.021) for x,y,z in pts]
        center=sum((Vector(p) for p in mid),Vector())/4
        cap=[(x+(center.x-x)*.045,y+(center.y-y)*.045,top) for x,y,z in mid]
        c=rng.choice(palette)
        for j in range(4):
            k=(j+1)%4
            face([pts[j],pts[k],mid[k],mid[j]],'45424b')
            face([mid[j],mid[k],cap[k],cap[j]],c,tone=1.23)
        face(cap,c)
rings(0,0,[(-.1,2.27,2.27,0,0),(.05,2.27,2.27,0,0)],['494550','423c46'],shape=[1]*64)
paving(1.24,2.24,20,0,.045,.147,['69716c','62686b','74706e','687273'])
paving(.55,1.22,14,.17,.05,.159,['535365','66616b','656473'])
rings(0,0,[(.05,.55,.55,0,0),(.16,.53,.53,0,0)],['403c50','575462'],shape=[1]*18)
# Copper orbit and twelve distinct engraved sigils set in the stone.
for r in (.63,1.13,1.32,2.13):
    for i in range(72): stroke(polar(r,i*tau/72,.163),polar(r,(i+1)*tau/72,.163),.011,'af905c')
for i in range(20):
    a=(i+.5)*tau/20
    def mark(off,side):return (off*cos(a)-side*sin(a),off*sin(a)+side*cos(a),.156)
    for v,w in [((1.52,0),(1.77,.11)),((1.77,.11),(1.98,0)),((1.98,0),(1.77,-.11)),((1.77,-.11),(1.52,0)),((1.72,-.12),(1.63,-.17))]:
        stroke(mark(*v),mark(*w),.018,'cfaa70')
    if i%2: stroke(mark(1.72,0),mark(1.88,0),.018,'f1b880')
# Tilted carved standing stones. Gold bands and vertical runes wrap the front faces.
for i,a in enumerate([.28,.98,1.63,2.49,3.22,4.04,4.82,5.65]):
    x,y,_=polar(2.55,a,0)
    front=(x-y)>1.8
    h=(.49 if front else rng.uniform(1.15,1.94))
    dx,dy=.15*cos(a),.15*sin(a)
    layers=[(-.11,.38,.31,0,0),(.10,.39,.34,0,0),(.23,.32,.27,0,0),
            (h*.72,.27,.24,dx,dy),(h*.82,.30,.255,dx,dy),(h*.86,.28,.23,dx,dy),(h,.12,.17,dx+.07,dy)]
    rings(x,y,layers,['514b54','777467','595463','6f6873','ba9562','78727c','92917c'],phase=a,shape=[1,.86,1.05,.92,1,.94])
    def rune(z,s): return (x+dx*(z/h)-.296*cos(a)-s*sin(a),y+dy*(z/h)-.296*sin(a)+s*cos(a),z)
    for aa,bb in [((.29,0),(.57,0)),((.46,0),(.53,.095)),((.36,0),(.41,-.07))]:
        stroke(rune(aa[0]*h,aa[1]),rune(bb[0]*h,bb[1]),.019,'f5b780','Glow')
# Low cast-bronze offering bowls flank the circle. Split flames tilt inward.
for a in (2.89,5.91):
    x,y,_=polar(2.90,a,0)
    rings(x,y,[(-.1,.28,.28,0,0),(.035,.31,.31,0,0),(.10,.22,.22,0,0),
          (.32,.12,.12,0,0),(.39,.23,.23,0,0),(.56,.37,.37,0,0),(.60,.38,.38,0,0),
          (.62,.31,.31,0,0)],['443f43','987b54','494351','8c6547','473d42','bd8750','69523e','2e2534'])
    for j in range(5):
        b=j*tau/5;dx,dy=.16*cos(b),.16*sin(b)
        h=rng.uniform(.19,.40)
        rings(x+dx,y+dy,[(.61,.054,.054,0,0),(.66,.076,.067,0,0),(.64+h,.01,.012,-dx*.46,-dy*.6)],
              ['fa9848','ffd78e','fff3c8'],'Glow',phase=b,shape=[1]*5)
# Spore caps and curling fern blades form small clusters on the damp ground.
for i in range(48):
    a=rng.uniform(0,tau);r=rng.uniform(3.1,7.)
    cx,cy,_=polar(r,a,0)
    for j in range(rng.randint(3,6)):
        x,y=cx+rng.uniform(-.24,.24),cy+rng.uniform(-.23,.23);h=rng.uniform(.09,.26)
        taper((x,y,-.11),(x+.016,y,h-.11),.031,.021,'d7bc97',n=5)
        rings(x+.016,y,[(h-.13,.09,.08,0,0),(h-.095,.13,.12,0,0),(h-.035,.077,.072,-.014,0),(h-.02,.018,.018,-.016,0)],
              ['d4a983','aa6451','b77660','d29470'],shape=[rng.uniform(.86,1.12) for _ in range(8)])
# Beeswax candle clusters nestle between the megaliths.
for i in range(8):
    a=(i+.55)*tau/8
    for j in range(3):
        x,y,_=polar(2.31+j*.13,a+j*.049,0)
        h=rng.uniform(.22,.45)
        rings(x,y,[(-.09,.074,.074,0,0),(h,.067,.067,0,0)],['d8b27e','f1d69a'])
        rings(x,y,[(h,.025,.025,0,0),(h+.048,.035,.035,0,0),(h+.14,.004,.004,.022,0)],['ff952c','ffe59a','fff4b1'],'Glow')
# Faceted layered conifers, boulders and fern rosettes make a forest edge.
for i in range(115):
    a=rng.uniform(0,tau); r=rng.uniform(5.2,16);x,y,_=polar(r,a,0)
    if (x-y)>.6 and abs(x+y)<7.3: continue
    h=rng.uniform(1.8,4.7); w=h*rng.uniform(.17,.26)
    taper((x,y,-.13),(x,y,h*.84),w*.15,.03,'584942')
    for j in range(4):
        z=h*(.16+j*.18); radius=w*(1-j*.19)
        shape=[rng.uniform(.77,1.17) for _ in range(9)]
        rings(x,y,[(z,radius*.71,radius*.71,0,0),(z+.10,radius,radius,0,0),(z+h*.42,radius*.035,radius*.035,.05,0)],
              ['283f43',rng.choice(['36564f','416254','486557','384f52']),'5d7460'],phase=j*.5,shape=shape)
for i in range(180):
    a=rng.uniform(0,tau);r=rng.uniform(2.94,11);x,y,_=polar(r,a,0);w=rng.uniform(.12,.61)
    rings(x,y,[(-.13,w,w*.64,0,0),(w*.25,w*.94,w*.66,0,0),(w*.57,w*.47,w*.31,.04,.02)],
          ['474956','676a68','777e70'],phase=a,shape=[rng.uniform(.65,1.22) for _ in range(7)])
for i in range(740):
    a=rng.uniform(0,tau);r=rng.uniform(2.65,12);x,y,_=polar(r,a,0)
    for j in range(5):
        angle=a+j*tau/5; h=rng.uniform(.11,.35); b=Vector((x,y,-.105))
        d=Vector((cos(angle),sin(angle),0)); side=Vector((-d.y,d.x,0))*h*.13
        mid=b+d*h*.31+Vector((0,0,h*.58));tip=b+d*h*.91+Vector((0,0,h*.83))
        face([b,mid+side,tip,mid],'657b50',tone=rng.uniform(.7,1.25));face([b,mid,tip,mid-side],'405f4d')

for name,(verts,polys,cols) in surfaces.items():
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],polys);mesh.update()
    attr=mesh.color_attributes.new(name='Tint',type='FLOAT_COLOR',domain='POINT')
    attr.data.foreach_set('color',[v for col in cols for v in col])
    mesh.color_attributes.active_color=attr
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    nodes=mat.node_tree.nodes; bs=nodes.get('Principled BSDF')
    color=nodes.new('ShaderNodeVertexColor');color.layer_name='Tint'
    mat.node_tree.links.new(color.outputs['Color'],bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value=.82
    if name=='Glow':
        bs.inputs['Emission Color'].default_value=(1,.44,.10,1);bs.inputs['Emission Strength'].default_value=1.35
    mesh.materials.append(mat);obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
bpy.ops.export_scene.gltf(filepath=str(dest), export_format='GLB', export_animations=True, export_animation_mode='ACTIONS', export_yup=True)
