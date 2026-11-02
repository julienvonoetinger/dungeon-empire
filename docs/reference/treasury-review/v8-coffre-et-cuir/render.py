"""Paint the existing isometric volume, using the real game coffer at the scale of its atlas entry."""
import importlib.util, json, math, random, sys
from pathlib import Path
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('treasury_volume',HERE.parent/'v7-reserve-en-relief/render.py')
V=importlib.util.module_from_spec(spec);spec.loader.exec_module(V)
WORK=V.ROOT/'artifacts/treasury-painted'
CHESTS=json.loads((WORK/'chest.json').read_text())

def linear(v):
    v=v/255
    return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4

def ink(name,code,image=None,contrast=1):
    # Use the same graphic hierarchy as the HUD: drawn outer edge, amber side,
    # pale gold upper bevel. Occlusion is sampled on the original geometry.
    col=tuple(linear(int(code[k:k+2],16)) for k in (0,2,4))+(1,)
    m=V.material(name,col[:3],0,.85)
    ns=m.node_tree.nodes; links=m.node_tree.links
    output=next(n for n in ns if n.type=='OUTPUT_MATERIAL')
    geom=ns.new('ShaderNodeNewGeometry');light=ns.new('ShaderNodeVectorMath');light.operation='DOT_PRODUCT'
    light.inputs[1].default_value=V.bp((-.28,-.38,.88)).normalized()
    links.new(geom.outputs['Normal'],light.inputs[0])
    levels=ns.new('ShaderNodeValToRGB'); cr=levels.color_ramp
    cr.elements[0].position=.02;cr.elements[0].color=(.59,.48,.62,1)
    cr.elements[1].position=.9;cr.elements[1].color=(1,.98,.95,1)
    stop=cr.elements.new(.5);stop.color=(.82,.77,.81,1)
    links.new(light.outputs['Value'],levels.inputs[0])
    color=ns.new('ShaderNodeMixRGB');color.blend_type='MULTIPLY';color.inputs[0].default_value=1
    color.inputs[1].default_value=col; links.new(levels.outputs[0],color.inputs[2])
    if image:
        tex=ns.new('ShaderNodeTexImage');tex.image=image;links.new(tex.outputs['Color'],color.inputs[1])
        if contrast<1:
            soft=ns.new('ShaderNodeMixRGB');soft.inputs[0].default_value=contrast;soft.inputs[1].default_value=col
            links.new(tex.outputs['Color'],soft.inputs[2]);links.new(soft.outputs[0],color.inputs[1])
    ao=ns.new('ShaderNodeAmbientOcclusion');ao.inputs['Distance'].default_value=.15;ao.samples=8
    shade=ns.new('ShaderNodeMixRGB');shade.blend_type='MULTIPLY';shade.inputs[0].default_value=.48
    links.new(color.outputs[0],shade.inputs[1]);links.new(ao.outputs['AO'],shade.inputs[2])
    # Read the bank as a mass. The recessed lower courses share cool ochre
    # shadow; only the crest and raised bevels get the brighter palette.
    xyz=ns.new('ShaderNodeSeparateXYZ');links.new(geom.outputs['Position'],xyz.inputs[0])
    height=ns.new('ShaderNodeMath');height.operation='MULTIPLY';height.inputs[1].default_value=2.5;links.new(xyz.outputs['Z'],height.inputs[0])
    wash=ns.new('ShaderNodeValToRGB');wash.color_ramp.elements[0].color=(.60,.47,.59,1);wash.color_ramp.elements[1].color=(1,.97,.93,1)
    links.new(height.outputs[0],wash.inputs['Fac'])
    local=ns.new('ShaderNodeMixRGB');local.blend_type='MULTIPLY';local.inputs[0].default_value=1
    links.new(shade.outputs[0],local.inputs[1]);links.new(wash.outputs[0],local.inputs[2])
    em=ns.new('ShaderNodeEmission');em.inputs['Strength'].default_value=2**.8
    links.new(local.outputs[0],em.inputs[0])
    diff=ns.new('ShaderNodeBsdfDiffuse');diff.inputs[0].default_value=col
    rays=ns.new('ShaderNodeLightPath');mix=ns.new('ShaderNodeMixShader')
    links.new(rays.outputs['Is Camera Ray'],mix.inputs[0]);links.new(diff.outputs[0],mix.inputs[1]);links.new(em.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],output.inputs['Surface'])
    return m

def paints():
    colors=['bd7824','e6a338','b56d21','ffcf6b','54343b','926026','643144','8d5351','381f32','9d6954']
    result=[ink('Paint '+str(i),col) for i,col in enumerate(colors)]
    image=bpy.data.images.load(str(WORK/'monnaie.png'))
    result.append(ink('Lozenge die','ed9e30',image))
    result.append(ink('Plain minted face','e7a735',bpy.data.images.load(str(WORK/'plain-coin.png'))))
    return result

def minted(mesh,stats,pos,r,slope,tone,rotation=0,thickness=None):
    # A few partially buried pieces break up the dark spaces between courses.
    if thickness is None and pos[2]>.08 and (len(stats)%3):
        offset=(-r*.43,r*.34,-r*.36)
        under=tuple(pos[i]+offset[i] for i in range(3))
        V.coin(mesh,stats,under,r*.94,slope,tone,rotation+1)
        idx=len(mesh.f)-1;mesh.mat[idx]=11
        mesh.stamps[idx]=[(.5+.46*math.cos(rotation+1+i*V.TAU/14),.5+.46*math.sin(rotation+1+i*V.TAU/14)) for i in range(14)]
    V.coin(mesh,stats,pos,r,slope,tone,rotation,thickness)
    n=14;index=len(mesh.f)-1
    mesh.mat[index]=10 if len(stats)%5==0 else 11
    mesh.stamps[index]=[(.5+.46*math.cos(rotation+i*V.TAU/n),.5+.46*math.sin(rotation+i*V.TAU/n)) for i in range(n)]

def art_material(image):
    m=V.material('Painted '+image.name,(.3,.2,.3),0,1)
    ns=m.node_tree.nodes;links=m.node_tree.links
    tex=ns.new('ShaderNodeTexImage');tex.image=image;tex.extension='CLIP'
    em=ns.new('ShaderNodeEmission');em.inputs['Strength'].default_value=2**.8
    links.new(tex.outputs['Color'],em.inputs[0])
    diffuse=ns.new('ShaderNodeBsdfDiffuse');links.new(tex.outputs['Color'],diffuse.inputs[0])
    rays=ns.new('ShaderNodeLightPath');eye=ns.new('ShaderNodeMixShader')
    links.new(rays.outputs['Is Camera Ray'],eye.inputs[0]);links.new(diffuse.outputs[0],eye.inputs[1]);links.new(em.outputs[0],eye.inputs[2])
    cut=ns.new('ShaderNodeMixShader');links.new(tex.outputs['Alpha'],cut.inputs[0])
    links.new(ns.new('ShaderNodeBsdfTransparent').outputs[0],cut.inputs[1]);links.new(eye.outputs[0],cut.inputs[2])
    links.new(cut.outputs[0],next(n for n in ns if n.type=='OUTPUT_MATERIAL').inputs['Surface'])
    return m

def painted_prop(file,position,frame,bounds):
    # Camera-registered proxy: each point maps to its exact native painted
    # pixel but has a depth for the surrounding coins and actual kit receivers.
    image=bpy.data.images.load(str(WORK/(file+'.png')),check_existing=True)
    material=art_material(image)
    mesh=V.Mesh();grid=[];cols=24;rows=20;ox,oy,w,h=frame
    slope=V.DATA['camera']['eye'][0]/V.DATA['camera']['eye'][2]
    for j in range(rows+1):
        row=[]
        for i in range(cols+1):
            sx=ox+w*i/cols;sy=oy+h*j/rows
            gx=(sx+2*sy)/256;gy=(-sx+2*sy)/256
            z=max(0,min(bounds[2],(bounds[0]-gx)/slope,(bounds[1]-gy)/slope))
            row.append(len(mesh.v));mesh.v.append((position[0]+gx+slope*z,position[1]+gy+slope*z,z))
        grid.append(row)
    for j in range(rows):
        for i in range(cols):
            ij=[(j,i),(j,i+1),(j+1,i+1),(j+1,i)]
            mesh.face([grid[y][x] for y,x in ij],0)
            mesh.stamps[len(mesh.f)-1]=[(x/cols,1-y/rows) for y,x in ij]
    return mesh.object(file,[material])

def chest_position(b,world):
    lo,hi=b['lo'],b['hi'];axis=0 if b['step'][0] else 1
    if abs(b['start'][1-axis]-world['slot']-.5)<.9:
        if (axis,world['side']) in [(0,'W'),(1,'N')]:lo=max(lo,.38)
        if (axis,world['side']) in [(0,'E'),(1,'S')]:hi=min(hi,1.62)
    mid=(lo+hi)/2
    sign=1 if mid>world['corner'][axis] else -1
    return mid+.095*sign,.385,sign,mid

def fit_world(b,u,v):
    return [b['start'][i]+u*b['step'][i]+v*b['inside'][i] for i in range(2)]

def run(id):
    sc=V.setup();sc.cycles.samples=24
    world=V.DATA['worlds'][id]
    wall,bvh=V.blocker(world);coin_mesh=V.Mesh();centres=[];stats=[];props=[]
    main=world['bays'][0]
    cu,cv,sign,mid=chest_position(main,world)
    chest=CHESTS[main['side']];cp=fit_world(main,cu,cv)
    chalf=(chest['bounds']['max'][0 if main['step'][0] else 1],chest['bounds']['max'][1 if main['step'][0] else 0])
    def chest_seat(u,v,z):
        # Occupy the same floor as the hoard. Low coins overlap the feet of
        # the chest, higher layers end at its flanks so the lock stays exposed.
        outside=max(abs(u-cu)-chalf[0],abs(v-cv)-chalf[1])
        f=max(0,min(1,(outside+.026)/.12));return min(z,.020+f*f*(3-2*f)*.6)
    for b in world['bays']:
        big=b['count']==2
        def bag(m,s,to_world,u,v,z,r,h,opened,rng):
            if big:
                # Different ends keep both silhouettes distinct at mobile scale.
                at=fit_world(b,max(.52,min(1.48,mid+sign*.47)),.52)
            else:
                at=fit_world(b,u,v+.025)
            file='sac-ouvert' if big else 'sac-lie'
            im=bpy.data.images.load(str(WORK/(file+'.png')),check_existing=True)
            width=53 if big else 46;height=width*im.size[1]/im.size[0]
            # The contact sits above the bottommost curve of the slouched leather.
            frame=[-width*.50,-height+7,width,height]
            painted_prop(file,at,frame,(.115,.115,.34))
            props.append((file,at,.125,.125))
        stats.append(V.fill(b,world,coin_mesh,centres,random.Random(177 if big else 373),
                       draw_coin=minted,draw_pouch=bag,shape_height=chest_seat if big else None))
    coin_mesh.object('Painted treasury coin banks',paints())
    painted_prop(chest['id']+'-master',cp,[*chest['offset'],*chest['size']],chest['bounds']['max'])
    props.append((chest['id'],cp,*chest['bounds']['max'][:2]))
    plane=V.Mesh();plane.face(plane.ring([(0,0,.001),(2,0,.001),(2,2,.001),(0,2,.001)]),0)
    plane.object('Receiving floor',[V.material('Receiver',(.33,.34,.36),0,.85)]).is_shadow_catcher=True
    def safe(x,y):
        near={'N':y,'S':2-y,'W':x,'E':2-x}[world['side']]
        along=x if world['side'] in ['N','S'] else y
        assert near>.35 or abs(along-world['slot']-.5)>.35,(id,x,y)
        assert max(abs(x-1),abs(y-1))>.25,(id,'centre',x,y)
    for x,y,z in coin_mesh.v:safe(x,y)
    for file,at,wx,wy in props:
        for dx in [-wx,0,wx]:
            for dy in [-wy,0,wy]:safe(at[0]+dx,at[1]+dy)
    eye=V.bp(V.DATA['camera']['eye']).normalized()
    hidden=sum(bvh.ray_cast(V.bp(p)+eye*.001,eye,3)[0] is not None for p in centres)
    assert hidden>0 and len(centres)>hidden
    chest_anchor=[*cp,0];pixel=V.DATA['density']
    lock_xy=[sum(chest_anchor[i]*V.DATA['camera'][axis][i] for i in range(3))*pixel for axis in ['x','y']]
    bpy.context.view_layer.update();sc.render.filepath=str(WORK/(id+'.png'));bpy.ops.render.render(write_still=True)
    report={'id':id,'originalChest':chest['id'],'facing':chest['facing'],'ground':cp,'projectedAnchor':lock_xy,'cofferPixelHash':chest['sha256'],'purses':[p[0] for p in props[:2]],'visibleCoinCentres':len(centres)-hidden,'hiddenCoinCentres':hidden,'peak':[p['peak'] for p in stats]}
    (WORK/(id+'.json')).write_text(json.dumps(report,indent=2))
    print('Painted treasury',id,report['originalChest'],report['peak'],flush=True)

for name in V.ARG or list(V.DATA['worlds']):run(name)
