// Offline XYZ geometry, projected and clipped with the dungeon wireframe exporter.
const path = require('node:path');
const {camera, PX, ROOT} = require('./isometric_kit_geometry.cjs');
const G = require('./wireframe_geometry.cjs');
const {writeGeneratedFile: write} = require('./write_generated_file.cjs');
const dir = 'assets/previews/sanctuary-wireframe';
const segments = [];
const parts = new Map();
const models = new Map();

const px = p => G.project(p,camera).map(v => v*PX);
const num = n => Number(n.toFixed(2));
const point = p => p.map(num).join(',');
const fresh = () => ({faces:[], edges:[], curvedStrips:[]});
function edge(m,a,b,kind='outline') {m.edges.push({a,b,kind});}
function face(m,points,kind='stone') {
  m.faces.push({points,kind});
  points.forEach((p,i) => edge(m,p,points[(i+1)%points.length]));
}
function loft(m,rings) {
  for (let i=1;i<rings.length;i++) {
    const lower=rings[i-1], upper=rings[i];
    lower.forEach((p,j) => {
      const k=(j+1)%lower.length;
      face(m,[p,lower[k],upper[k],upper[j]]);
    });
  }
  face(m,rings.at(-1));
}
function part(id,m) {
  // Irregular lofts have nonplanar faces. Match the triangulation used by the
  // hidden-line solver, including a diagonal when it becomes a silhouette.
  // Otherwise the opaque surface can extend beyond its drawn outline.
  const triangles=[], silhouette=[];
  for(const f of m.faces){
    const p=f.points, facing=[];
    for(let i=1;i<p.length-1;i++){
      const points=[p[0],p[i],p[i+1]];
      triangles.push({...f,points});
      facing.push(G.dot(G.cross(G.sub(p[i],p[0]),G.sub(p[i+1],p[0])),camera.eye));
    }
    for(let i=1;i<facing.length;i++){
      if(facing[i-1]*facing[i]<0)
        silhouette.push({a:p[0],b:p[i+1],kind:'outline'});
    }
  }
  const faces=triangles.map(f=>({...f,screen:f.points.map(px)}));
  const all=faces.flatMap(f=>f.screen);
  const x=Math.floor(Math.min(...all.map(p=>p[0])))-3, y=Math.floor(Math.min(...all.map(p=>p[1])))-3;
  const w=Math.ceil(Math.max(...all.map(p=>p[0])))-x+3, h=Math.ceil(Math.max(...all.map(p=>p[1])))-y+3;
  const fills={soil:'#26333d'};
  const body=faces.map(f=>`<polygon points="${f.screen.map(point).join(' ')}" fill="${fills[f.kind]||'#202a34'}"/>`).join('');
  const visibleEdges=G.visibleEdges({...m,edges:[...m.edges,...silhouette]},camera);
  const lines=visibleEdges.map(e=>{
    const ground=e.kind==='grid', carved=e.kind==='carving';
    return `<path d="M${point(px(e.a))} L${point(px(e.b))}" stroke="${ground?'#465663':carved?'#d1b28b':'#adc0cb'}" stroke-width="${ground?1.6:carved?2.4:2.8}"/>`;
  }).join('');
  write(path.join(ROOT,dir,id+'.svg'),`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="${x} ${y} ${w} ${h}">${body}<g fill="none" stroke-linecap="round" stroke-linejoin="round">${lines}</g></svg>\n`);
  parts.set(id,{x,y,w,h});
  models.set(id,{id,faces:m.faces,edges:m.edges,visibleEdges,frame:[x,y,w,h]});
}
function place(id,x,y,name) {
  segments.push({id,x,y,name,position:px([x,y,0])});
}
// Cover a rectangular camera field with complete, individually placed diamonds.
// Include a full tile beyond its edges so the camera never reveals the boundary.
const field={left:-1800,right:1800,top:-2000,bottom:2000};
const tile=fresh(), corners=[[0,0,0],[1,0,0],[1,1,0],[0,1,0]];
tile.faces.push({points:corners,kind:'soil'});
corners.forEach((a,i)=>edge(tile,a,corners[(i+1)%4],'grid'));
part('floor-0',tile);
const limit=Math.ceil(Math.max(-field.left,field.right)/PX+2*Math.max(-field.top,field.bottom)/PX)+3;
for(let y=-limit;y<=limit;y++)for(let x=-limit;x<=limit;x++){
  const [u,v]=px([x+.5,y+.5,0]);
  if(u>=field.left-PX/2 && u<=field.right+PX/2 && v>=field.top-PX/4 && v<=field.bottom+PX/4)
    place('floor-0',x,y,'Case_'+x+'_'+y);
}
const cellCount=segments.length;

// No constructed or worn path leads here. The approach uses the same ground
// as the clearing; gaps between scattered rocks leave room for the Oculins.
const polar=(rx,ry,z,n,angle=0)=>Array.from({length:n},(_,i)=>{
  const a=angle+i*2*Math.PI/n;return [rx*Math.cos(a),ry*Math.sin(a),z];});
const altar=fresh();
loft(altar,[polar(1.22,1.22,0,12),polar(1.22,1.22,.12,12),polar(1.13,1.13,.19,12)]);
loft(altar,[polar(.90,.90,.19,12),polar(.86,.86,.29,12)]);
// The same invented pact sigil is engraved on the dais and the standing stones.
// Coordinates describe a frontal drawing; every stroke is projected on its stone.
function pactSigil(stroke){
  stroke([[0,.83],[.60,0],[0,-.83],[-.60,0],[0,.83]]);
  const lid=sign=>Array.from({length:25},(_,i)=>{
    const t=i/24;return [-.43+.86*t,sign*.22*Math.sin(Math.PI*t)];});
  stroke(lid(1));stroke(lid(-1));
  stroke([[0,.16],[.07,0],[0,-.16],[-.07,0],[0,.16]]);
  stroke([[0,.83],[0,1.06]]);
  stroke([[-.23,1.04],[0,.91],[.23,1.04]]);
  stroke([[0,-.83],[0,-1.06]]);
  stroke([[-.20,-1.05],[0,-.92],[.20,-1.05]]);
}
const altarSurface=([u,v])=>[(u-v)*Math.SQRT1_2,( -u-v)*Math.SQRT1_2,.2902];
const altarStroke=points=>points.slice(1).forEach((p,i)=>edge(altar,altarSurface(points[i]),altarSurface(p),'carving'));
pactSigil(points=>altarStroke(points.map(([u,v])=>[u*.55,v*.55])));
altarStroke(Array.from({length:97},(_,i)=>{const a=i*Math.PI/48;return [.74*Math.cos(a),.74*Math.sin(a)];}));
// Six angular marks repeat the number of ritual pillars around the seal.
for(let i=0;i<6;i++){
  const a=i*Math.PI/3, radial=(r,t)=>[r*Math.cos(a)-t*Math.sin(a),r*Math.sin(a)+t*Math.cos(a)];
  altarStroke([radial(.64,-.045),radial(.68,0),radial(.64,.045)]);
  altarStroke([radial(.68,0),radial(.71,0)]);
}
part('altar',altar);place('altar',.4,.45,'Dalle');
// Each profile describes a different fracture, from a flat flake to a needle.
// Levels are [height, radius, lateral offset] in local stone coordinates.
const profiles={
  blade:[[0,1,0],[.70,.88,.06],[1,.49,.15]],
  tooth:[[0,1,0],[.38,.97,-.02],[1,.17,.29]],
  buttress:[[0,1,0],[.20,1.02,-.01],[.72,.65,-.15],[1,.48,-.22]],
  slab:[[0,.93,0],[.34,1,.03],[1,.88,-.03]],
  splinter:[[0,.86,0],[.52,1,.08],[.88,.67,.18],[1,.28,.22]],
  shoulder:[[0,1,0],[.66,.86,-.06],[1,.60,-.18]]
};

function stone(group,index,x,y,width,depth,height,style,heading,sides){
  const id=group+'-'+(index+1), m=fresh();
  const rotation=heading*Math.PI/180;
  const seed=index*1.73+rotation;
  const base=Array.from({length:sides},(_,j)=>{
    const a=2*Math.PI*j/sides;
    const angle=a+.11*Math.sin(3*a+seed);
    const radius=.49+.065*Math.cos(2*a-seed)+.035*Math.sin(5*a+seed);
    return [radius*Math.cos(angle),radius*Math.sin(angle)];
  });
  const levels=profiles[style];
  const rings=levels.map(([h,r,shift],level)=>base.map(([u,v])=>{
    const dx=(u*r+shift)*width, dy=v*r*depth;
    const slope=.42*Math.cos(seed+level*.64)*u+.31*Math.sin(seed+level*.64)*v;
    return [dx*Math.cos(rotation)-dy*Math.sin(rotation),dx*Math.sin(rotation)+dy*Math.cos(rotation),height*h*(1+slope)];
  }));
  loft(m,rings); part(id,m); place(id,x,y,group+(index+1));
}

// Hewn, bevelled ritual pillars close to the dais. The front sector stays open
// for the procession; their complete silhouettes fit the existing portrait view.
function pillar(index,angle,width,depth,height,heading){
  const m=fresh(), id='Menhir-'+(index+1), rotation=heading*Math.PI/180;
  const transform=([x,y,z])=>[x*Math.cos(rotation)-y*Math.sin(rotation),x*Math.sin(rotation)+y*Math.cos(rotation),z];
  const bevel=.065;
  const outline=[[-width/2+bevel,-depth/2],[width/2-bevel,-depth/2],
    [width/2,-depth/2+bevel],[width/2,depth/2-bevel],
    [width/2-bevel,depth/2],[-width/2+bevel,depth/2],
    [-width/2,depth/2-bevel],[-width/2,-depth/2+bevel]];
  const ring=(z,r,crown=false)=>outline.map(([x,y],j)=>transform([x*r,y*r,
    z+(crown?height*(.025*Math.sin(j*1.7+index)-.05*x/width):0)]));
  loft(m,[ring(0,1.04),ring(.065,1),ring(height*.88,.912),ring(height,.82,true)]);
  // Follow the actual tapered front plane, so the engraving belongs to the
  // stone face and is clipped by the same hidden-line pass as its bevels.
  const surface=(u,t)=>{const r=1-.088*(t*height-.065)/(height*.88-.065);
    return transform([u*r,depth*.5*r+.0002,t*height]);};
  const stroke=points=>points.slice(1).forEach((p,j)=>edge(m,surface(...points[j]),surface(...p),'carving'));
  const half=width*.31;
  stroke([[-half,.17],[-half,.77],[-half*.65,.83],[half*.65,.83],[half,.77],[half,.17],[-half,.17]]);
  pactSigil(points=>stroke(points.map(([u,v])=>[u*width*.42,.57+v*.18])));
  const runes=[
    [[-.12,.24],[0,.30],[.12,.24],[0,.20],[0,.30]],
    [[-.12,.21],[-.12,.29],[.12,.25],[-.12,.21]],
    [[-.12,.28],[0,.23],[.12,.28],[0,.23],[0,.19]],
    [[-.12,.21],[0,.29],[.12,.21],[-.12,.21]],
    [[-.12,.29],[.12,.29],[-.12,.21],[.12,.21]],
    [[-.12,.25],[.12,.25],[0,.30],[0,.20]]
  ];
  stroke(runes[index].map(([u,v])=>[u*width,v]));
  part(id,m);
  const a=angle*Math.PI/180;
  place(id,.4+1.50*Math.cos(a),.45+1.50*Math.sin(a),'Menhir'+(index+1));
}
const markers=[
  [100,.48,.35,1.04,-48],[150,.51,.36,1.22,-39],
  [200,.54,.38,1.40,-51],[250,.49,.35,1.30,-42],
  [300,.52,.37,1.16,-50],[350,.46,.34,.98,-40]
];
markers.forEach((spec,i)=>pillar(i,...spec));

const walls=[
  [-3.22,-1.65,1.94,1.44,2.34,'buttress',-32,7],[-3.40,-.28,1.53,1.28,1.71,'blade',28,5],
  [-3.54,1.09,1.66,.95,.92,'slab',-45,6],[-2.30,-2.70,1.72,1.32,1.47,'tooth',42,7],
  [.88,-3.48,2.13,1.65,2.30,'shoulder',-5,7],[2.38,-3.15,1.48,1.31,1.87,'splinter',-38,5],
  [3.28,-2.08,1.62,.94,1.08,'blade',18,6],[-.77,-3.23,1.88,1.45,1.84,'slab',24,7]
];
walls.forEach((spec,i)=>stone('Paroi',i,...spec));
const peaks=[
  [-8,-7,4.54,2.81,3.24,'shoulder',-22,7],[-6.8,-8.8,3.23,2.62,4.31,'tooth',30,5],
  [-5,-7.1,3.65,2.83,2.69,'slab',-4,6],[-3.5,-8.5,3.38,2.34,4.12,'splinter',8,7],
  [-1.4,-6.8,3.98,2.61,3.34,'buttress',-28,6],[.65,-7.7,3.12,2.4,2.88,'blade',18,5]
];
peaks.forEach((spec,i)=>stone('Crete',i,...spec));

// Scattered outcrops leave an irregular approach, without lining a road.
const scree=[
  [-4.3,2.3,1.62,.73,.50,'blade',-26,6],[-3.52,2.64,.52,.42,.32,'tooth',10,5],
  [-1.56,4.6,1.12,.87,.70,'shoulder',34,7],[-1.06,5.34,.59,.42,.24,'slab',16,5],
  [2.54,7.49,1.83,.72,.47,'slab',50,6],[5.14,9.85,.83,1.13,.66,'splinter',-37,5],
  [4.52,.94,.80,1.49,.79,'buttress',30,6],[4.91,1.64,.51,.63,.31,'shoulder',7,5],
  [5.91,3.57,1.83,.94,.42,'blade',-36,7],[7.83,4.73,.74,.60,.69,'tooth',-11,5],
  [9.18,7.48,1.52,.95,.38,'slab',14,6],[-5.,-3.5,1.20,.74,.67,'splinter',34,5],
  [-1.8,-5.,.65,1.13,.42,'shoulder',-20,7],[2.7,-5.25,1.47,.88,.62,'buttress',16,6]
];
scree.forEach((spec,i)=>stone('Eboulis',i,...spec));
const foreground=[
  [1.0,3.6,1.04,.73,.39,'shoulder',-18,7],
  [1.42,3.94,.35,.29,.16,'blade',35,5],
  [3.4,1.8,.88,1.16,.64,'buttress',23,6],
  [2.6,3.3,.38,.27,.13,'slab',-37,5],
  [4.5,6.3,1.48,.86,.54,'blade',-14,7],
  [4.11,6.72,.52,.41,.22,'tooth',21,5],
  [7.,4.8,1.21,.97,.73,'splinter',42,6],
  [7.18,5.48,.43,.52,.19,'slab',-12,5]
];
foreground.forEach((spec,i)=>stone('RocheApproche',i,...spec));

const header=['[gd_scene load_steps='+ (parts.size+2)+' format=3]','','[ext_resource type="Script" path="res://scripts/sanctuary_wireframe_view.gd" id="view"]'];
for(const id of parts.keys())header.push(`[ext_resource type="Texture2D" path="res://${dir}/${id}.svg" id="${id}"]`);
header.push('','[node name="SanctuaireWireframe" type="Node2D"]','script = ExtResource("view")',`terrain_bounds = Rect2(${field.left}, ${field.top}, ${field.right-field.left}, ${field.bottom-field.top})`);
const layer=id=>id==='floor-0'?0:1;
segments.sort((a,b)=>layer(a.id)-layer(b.id) || a.x+a.y-b.x-b.y);
for(const s of segments){
  const rect=parts.get(s.id);
  header.push('',`[node name="${s.name}" type="Sprite2D" parent="."]`,`position = Vector2(${point(s.position)})`,`texture = ExtResource("${s.id}")`,'centered = false',`offset = Vector2(${rect.x}, ${rect.y})`,`metadata/grid_position = Vector2(${s.x}, ${s.y})`);
}
write(path.join(ROOT,'scenes/SanctuaryWireframe.tscn'),header.join('\n')+'\n');
console.log(cellCount+' logical cells, '+segments.length+' placed elements.');
module.exports={models:[...models.values()],segments,field,camera,PX};
