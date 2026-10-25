// Offline, disposable wireframe proposal. No production kit or runtime edits.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const {writeGeneratedFile} = require('./write_generated_file.cjs');
const {T, H, PILLAR, PX} = require('./prepare_mobile_reference.cjs');
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'docs/reference/ground-perspective-review/wireframe-v1');
const angle = 35 * Math.PI / 180, s = Math.sin(angle), c = Math.cos(angle);
const cameras = {
  current: {x: [1, 0, -.18], y: [0, 1, -.9], eye: [.18, .9, 1]},
  proposed: {x: [1, 0, 0], y: [0, s, -c], eye: [0, c, s]},
};
const colors = {wall: '#d7dfea', joint: '#8a99ae', floor: '#51b4c9', heart: '#f4bd78', vortex: '#ce84ff'};
const add = (a,b) => a.map((v,i) => v+b[i]);
const sub = (a,b) => a.map((v,i) => v-b[i]);
const mul = (a,t) => a.map(v => v*t);
const dot = (a,b) => a.reduce((n,v,i) => n+v*b[i],0);
const cross = (a,b) => [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const lerp = (a,b,t) => add(a,mul(sub(b,a),t));
const fmt = n => +n.toFixed(6);
const key = p => p.map(fmt).join(',');
const project = (p, camera) => [dot(p,camera.x),dot(p,camera.y)];
const write = (file, data) => writeGeneratedFile(path.join(OUT,file),data);
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,file))).digest('hex');

function build() {
  const faces = [], edges = [], cells = [];
  const face = (points, kind) => faces.push({points,kind});
  const edge = (a,b,kind) => edges.push({a,b,kind});
  function box(x,X,y,Y,z,Z,kind) {
    const p = [[x,y,z],[X,y,z],[X,Y,z],[x,Y,z],[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]];
    for(const indexes of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])
      face(indexes.map(i=>p[i]),kind);
    for(const [a,b] of [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]])
      edge(p[a],p[b],kind);
  }
  // Same logical occupancy as MobileReference.tscn / wireframe_cell_layout.gd.
  for(let y=0;y<2;y++)for(let x=0;x<3;x++)cells.push([x,y]);
  for(let x=3;x<6;x++)cells.push([x,1]);
  for(let y=2;y<6;y++)cells.push([1,y]);
  const occupied = new Set(cells.map(key));
  const walls = [], cornerAxes = new Map();
  const dirs = [[0,-1],[1,0],[0,1],[-1,0]];
  for(const cell of cells)for(let side=0;side<4;side++) {
    if(occupied.has(key(add(cell,dirs[side]))))continue;
    const horizontal = side%2===0;
    const a = side===1?add(cell,[1,0]):side===2?add(cell,[0,1]):cell;
    const b = add(a,horizontal?[1,0]:[0,1]);
    walls.push({a,b,horizontal});
    for(const p of [a,b])cornerAxes.set(key(p),(cornerAxes.get(key(p))||0)|(horizontal?1:2));
  }
  const pillars = [...cornerAxes].filter(([,axes])=>axes===3).map(([k])=>k.split(',').map(Number));
  const pillarSet = new Set(pillars.map(key));
  // The exact quiet mobile floor joint pattern; no artificial cell-border seam.
  const widths = [[.18,.35,.33,.14],[.30,.34,.32,.04],[.07,.33,.35,.25]];
  for(const [x,y] of cells) {
    face([[x,y,0],[x+1,y,0],[x+1,y+1,0],[x,y+1,0]],'floor');
    for(let r=0;r<=3;r++)edge([x,y+r/3,0],[x+1,y+r/3,0],'floor');
    for(let r=0;r<3;r++) {
      const [a,b,d] = widths[r];
      for(const cut of [a,a+b,a+b+d])edge([x+cut,y+r/3,0],[x+cut,y+(r+1)/3,0],'floor');
    }
  }
  for(const wall of walls) {
    const {a,b,horizontal} = wall;
    const lo = pillarSet.has(key(a))?PILLAR/2:0;
    const hi = pillarSet.has(key(b))?1-PILLAR/2:1;
    const at = (u,v,z) => horizontal?[a[0]+u,a[1]+v,z]:[a[0]+v,a[1]+u,z];
    if(horizontal)box(a[0]+lo,a[0]+hi,a[1]-T/2,a[1]+T/2,0,H,'wall');
    else box(a[0]-T/2,a[0]+T/2,a[1]+lo,a[1]+hi,0,H,'wall');
    for(const v of [-T/2,T/2]) {
      edge(at(lo,v,H/2),at(hi,v,H/2),'joint');
      for(const u of [1/3,2/3])edge(at(u,v,H/2),at(u,v,H),'joint');
      for(const u of [1/6,1/2,5/6])edge(at(u,v,0),at(u,v,H/2),'joint');
    }
    for(const u of [1/3,2/3])edge(at(u,-T/2,H),at(u,T/2,H),'joint');
  }
  for(const [x,y] of pillars) {
    const q=PILLAR/2,h=H+.035;
    box(x-q,x+q,y-q,y+q,0,h,'wall');
    const p=[[x-q,y-q,h/2],[x+q,y-q,h/2],[x+q,y+q,h/2],[x-q,y+q,h/2]];
    p.forEach((a,i)=>edge(a,p[(i+1)%4],'joint'));
  }
  // Schematic replacement for the painted heart, NOT a tracing/approved remodel.
  // All rigid parts are expressed in the same XYZ coordinates as the dungeon.
  const centre=[1.5,1], footprint=.8125;
  const slab=(size,z,Z)=>box(centre[0]-size/2,centre[0]+size/2,centre[1]-size/2,centre[1]+size/2,z,Z,'heart');
  slab(footprint,0,.065); slab(.75,.065,.115); slab(.65,.115,.15);
  for(const dx of [-.295,.295])for(const dy of [-.295,.295]) {
    const x=centre[0]+dx,y=centre[1]+dy;
    box(x-.075,x+.075,y-.075,y+.075,.065,.23,'heart');
    box(x-.085,x+.085,y-.085,y+.085,.23,.255,'heart');
  }
  function ring(radius,z) {
    return Array.from({length:64},(_,i)=>[centre[0]+radius*Math.cos(i*2*Math.PI/64),centre[1]+radius*Math.sin(i*2*Math.PI/64),z]);
  }
  function ringEdges(p) {p.forEach((a,i)=>edge(a,p[(i+1)%p.length],'heart'));}
  const lower=ring(.205,.15),upper=ring(.205,.19),inner=ring(.148,.19),innerLow=ring(.148,.152);
  for(const [a,b] of [[lower,upper],[upper,inner],[inner,innerLow]])for(let i=0;i<64;i++)
    face([a[i],a[(i+1)%64],b[(i+1)%64],b[i]],'heart');
  [lower,upper,inner].forEach(ringEdges);
  // Concentric octagonal carving on the horizontal stone surface.
  for(const radius of [.26,.29]) {
    const p=Array.from({length:8},(_,i)=>[centre[0]+radius*Math.cos(i*Math.PI/4+Math.PI/8),centre[1]+radius*Math.sin(i*Math.PI/4+Math.PI/8),.15]);
    p.forEach((a,i)=>edge(a,p[(i+1)%8],'heart'));
  }
  return {faces,edges,cells,pillars,walls,curvedStrips:[{a:lower,b:upper},{a:inner,b:innerLow}],heart:{centre,footprint,orbCentre:[1.5,1,.56],orbRadius:.20}};
}

function visibleEdges(model,camera) {
  const triangles=model.faces.flatMap(f=>f.points.slice(1,-1).map((p,i)=>{
    const a=f.points[0],b=p,d=f.points[i+2],e1=sub(b,a),e2=sub(d,a),h=cross(camera.eye,e2),det=dot(e1,h);
    const q=[a,b,d].map(p=>project(p,camera));
    return {a,e1,e2,h,det,box:[Math.min(...q.map(p=>p[0])),Math.min(...q.map(p=>p[1])),Math.max(...q.map(p=>p[0])),Math.max(...q.map(p=>p[1]))]};
  })).filter(t=>Math.abs(t.det)>1e-12);
  function hidden(p) {
    const xy=project(p,camera);
    for(const t of triangles) {
      if(xy[0]<t.box[0]-1e-9||xy[0]>t.box[2]+1e-9||xy[1]<t.box[1]-1e-9||xy[1]>t.box[3]+1e-9)continue;
      const inv=1/t.det,v0=sub(p,t.a),u=inv*dot(v0,t.h);
      if(u< -1e-9||u>1+1e-9)continue;
      const q=cross(v0,t.e1),v=inv*dot(camera.eye,q);
      if(v>=-1e-9&&u+v<=1+1e-9&&inv*dot(t.e2,q)>1e-7)return true;
    }
    return false;
  }
  const result=[],seen=new Set(),candidates=[...model.edges];
  // Silhouettes of the circular socket depend on the camera; they are not
  // arbitrary vertical divisions in the smooth cylindrical stone.
  for(const {a,b} of model.curvedStrips) {
    const n=a.length;
    const facing=a.map((p,i)=>dot(cross(sub(a[(i+1)%n],p),sub(b[i],p)),camera.eye));
    for(let i=0;i<n;i++)if(facing[i]*facing[(i+n-1)%n]<0)
      candidates.push({a:a[i],b:b[i],kind:'heart'});
  }
  for(const e of candidates) {
    const k=[key(e.a),key(e.b)].sort().join('|');
    if(seen.has(k))continue;seen.add(k);
    const samples=Math.max(16,Math.ceil(Math.hypot(...sub(e.b,e.a))*240));
    let start=0,old=hidden(lerp(e.a,e.b,.5/samples));
    const emit=(a,b)=>{if(b-a>1e-7)result.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
    for(let i=1;i<samples;i++) {
      const next=hidden(lerp(e.a,e.b,(i+.5)/samples));
      if(next===old)continue;
      let lo=(i-.5)/samples,hi=(i+.5)/samples;
      for(let j=0;j<22;j++) {const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)emit(start,cut);start=cut;old=next;
    }
    if(!old)emit(start,1);
  }
  return result;
}

const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
const text=(x,y,size,value,fill='#e6edf5')=>`<text x="${x}" y="${y}" font-family="Segoe UI,Arial,sans-serif" font-size="${size}" fill="${fill}">${value}</text>`;
function drawing(model,edges,camera,origin,scale,width=1.3) {
  const p=v=>project(v,camera).map((a,i)=>a*scale+origin[i]);
  let body=edges.map(e=>{
    const a=p(e.a),b=p(e.b);
    return `<line x1="${fmt(a[0])}" y1="${fmt(a[1])}" x2="${fmt(b[0])}" y2="${fmt(b[1])}" stroke="${colors[e.kind]}" stroke-width="${e.kind==='joint'?width*.75:width}" stroke-linecap="round"/>`;
  }).join('');
  // The vortex is a camera-facing magical effect. Only the rigid support is projected.
  // Its opaque disc hides rear floor lines in the wireframe, as the painted core does.
  const o=p(model.heart.orbCentre),r=model.heart.orbRadius*scale;
  const maskId='orb'+origin.map(v=>Math.round(v*100)).join('_').replaceAll('-','m');
  body=`<defs><mask id="${maskId}" maskUnits="userSpaceOnUse" x="-10000" y="-10000" width="20000" height="20000"><rect x="-10000" y="-10000" width="20000" height="20000" fill="white"/><circle cx="${fmt(o[0])}" cy="${fmt(o[1])}" r="${fmt(r)}" fill="black"/></mask></defs><g mask="url(#${maskId})">${body}</g>`;
  body+=`<circle cx="${fmt(o[0])}" cy="${fmt(o[1])}" r="${fmt(r)}" fill="none" stroke="${colors.vortex}" stroke-width="${width*1.35}"/>`;
  const spiral=Array.from({length:160},(_,i)=>{const t=i/159,a=t*Math.PI*5,q=r*(.08+.79*t);return [o[0]+q*Math.cos(a),o[1]+q*Math.sin(a)].map(fmt).join(',');}).join(' ');
  body+=`<polyline points="${spiral}" fill="none" stroke="${colors.vortex}" stroke-width="${width}"/>`;
  return body;
}
async function save(name,w,h,body) {
  const source=svg(w,h,body);write(`${name}.svg`,source);
  write(`${name}.png`,await sharp(Buffer.from(source)).png().toBuffer());
}
async function main() {
  const model=build();
  const edges=Object.fromEntries(Object.entries(cameras).map(([id,camera])=>[id,visibleEdges(model,camera)]));
  const bg=(w,h)=>`<rect width="${w}" height="${h}" fill="#0b1019"/>`;
  let body=bg(1280,890)+text(32,38,25,'Sol et cœur — proposition en wireframe');
  body+=text(32,66,15,'Vue inclinée à 35° · grille logique 1 × 1 · mêmes axes pour les murs, le dallage et le socle','#b2bdce');
  body+=drawing(model,edges.proposed,cameras.proposed,[54,164],PX*.75);
  body+=text(32,863,14,'Cyan : dallage',colors.floor)+text(215,863,14,'Blanc : murs',colors.wall)+text(390,863,14,'Ambre : socle',colors.heart)+text(565,863,14,'Violet : vortex schématique',colors.vortex);
  await save('room',1280,890,body);
  // Transparent construction overlay, ready to compare future artwork at this scale.
  await save('room-transparent',1280,890,drawing(model,edges.proposed,cameras.proposed,[54,164],PX*.75));

  body=bg(1400,760)+text(32,39,25,'Même salle, même largeur de case : deux projections');
  body+=text(32,66,15,'Géométrie identique dans les deux dessins. Le cœur est représenté par un volume de travail.','#b2bdce');
  for(const [i,id] of ['current','proposed'].entries()) {
    const x=24+i*698;
    body+=text(x+14,109,20,i?'Proposition — sol raccourci en profondeur':'Projection actuelle — sol vu de dessus');
    body+=`<defs><clipPath id="p${i}"><rect x="${x}" y="130" width="676" height="570"/></clipPath></defs><g clip-path="url(#p${i})">`;
    body+=drawing(model,edges[id],cameras[id],[x+52,235],174,1.4)+'</g>';
  }
  body+=text(38,733,15,'Les dimensions des cases et la hauteur des murs ne changent pas dans le modèle. Seule la projection change.','#b2bdce');
  await save('comparison',1400,760,body);

  body=bg(1080,690)+text(32,40,24,'Socle du cœur — raccord au plan du sol');
  body+=text(32,69,15,'Carré de 0,8125 case · marches horizontales · quatre pierres d’angle · cercle projeté en ellipse','#b2bdce');
  body+='<defs><clipPath id="detail"><rect x="28" y="100" width="1024" height="530"/></clipPath></defs><g clip-path="url(#detail)">';
  const scale=550,focus=project([1.5,1,.25],cameras.proposed);
  body+=drawing(model,edges.proposed,cameras.proposed,[540-focus[0]*scale,375-focus[1]*scale],scale,1.7)+'</g>';
  body+=text(32,660,15,'Étude de volumes uniquement : le dessin détaillé du cœur sera adapté après validation de cette vue.','#b2bdce');
  await save('heart-detail',1080,690,body);
  const record={status:'wireframe proposal, awaiting visual feedback',generator:'tools/prepare_ground_perspective_review.cjs',
    cameras,proposedElevationDegrees:35,logicalCell:[1,1],sourcePixelsPerCell:PX,displayScale:.75,
    displayGroundCell:[192,192*s],wall:{thickness:T,height:H,facadeCourses:2},pillar:{width:PILLAR,height:H+.035},
    heart:model.heart,heartStatus:'schematic volumes, not traced from or a replacement for approved painted artwork',
    floorWidths:[[.18,.35,.33,.14],[.30,.34,.32,.04],[.07,.33,.35,.25]],
    occlusion:'Closed solid faces; ray/triangle occlusion with sampled/bisected visible intervals. Only visible lines exported.',
    limits:['Orthographic parallel camera, not finite vanishing points. Ground depth is foreshortened.','No production scene/assets/atlas changes or visual approval.','Torch/door/stair reprojection and sprite migration are outside this proposal.','Wireframe review, not a Godot gameplay capture or a device test.'],
    baselineHashes:Object.fromEntries(['assets/dungeon/mobile-kit/atlas-256.png','assets/dungeon/mobile-kit/catalog.tres','scenes/MobileReference.tscn','docs/reference/mobile-heart-review/ritual-v3/selection.json'].map(p=>[p,hash(p)])),
    model,visibleEdges:edges};
  write('geometry.json',JSON.stringify(record,null,2)+'\n');
  console.log(JSON.stringify({output:OUT,cells:model.cells.length,faces:model.faces.length,edges:Object.fromEntries(Object.entries(edges).map(([k,v])=>[k,v.length])),displayGroundCell:record.displayGroundCell}));
}
if(require.main===module) main().catch(error=>{console.error(error);process.exitCode=1;});
module.exports={build,visibleEdges,drawing,cameras,project};
