// Prepared sprite geometry: logical XYZ, one approved 2:1 camera for every part.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const G=require('./wireframe_geometry.cjs');
const ROOT=path.resolve(__dirname,'..');
const read=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p),'utf8'));
const selection=read('docs/reference/isometric-review/wireframe-v1/selection.json');
const camera=selection.camera,PX=256,T=1/6,H=1.88/6,PILLAR=.24;
const sourceFiles=['docs/reference/isometric-review/wireframe-v1/selection.json',
  'docs/reference/isometric-review/wireframe-v1/geometry.json',
  'docs/reference/mobile-door-frame-review/wireframe-v8/geometry.json',
  'docs/reference/entrance-stairs-open-south-wireframe.json',
  'docs/reference/mobile-light-review/wireframe-v1/geometry.json'];
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,p))).digest('hex');
// The reviewed board/model is an immutable source, not an export destination.
for(const [file,record] of Object.entries(selection.reviewedFiles))
  if(hash(file)!==record.sha256)throw Error('Approved isometric reference changed: '+file);
const model=(id)=>({id,faces:[],edges:[],curvedStrips:[]});
const edge=(m,a,b,kind='wall')=>m.edges.push({a,b,kind});
const face=(m,points,kind='wall')=>m.faces.push({points,kind});
function box(m,x,X,y,Y,z,Z,kind='wall') {
  const p=[[x,y,z],[X,y,z],[X,Y,z],[x,Y,z],[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]];
  for(const is of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])face(m,is.map(i=>p[i]),kind);
  for(const [a,b] of [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]])edge(m,p[a],p[b],kind);
}
function floor() {
  const m=model('floor');face(m,[[0,0,0],[1,0,0],[1,1,0],[0,1,0]],'floor');
  const widths=[[.18,.35,.33,.14],[.30,.34,.32,.04],[.07,.33,.35,.25]];
  for(let r=0;r<=3;r++)edge(m,[0,r/3,0],[1,r/3,0],'floor');
  for(let r=0;r<3;r++) {let x=0;for(const w of widths[r].slice(0,-1)) {x+=w;edge(m,[x,r/3,0],[x,(r+1)/3,0],'floor');}}
  return m;
}
function wall(h,bits) {
  const m=model(`wall-${h?'h':'v'}-${bits}`),lo=bits&1?PILLAR/2:0,hi=bits&2?1-PILLAR/2:1;
  const p=(u,v,z)=>h?[u,v,z]:[v,u,z];
  if(h)box(m,lo,hi,-T/2,T/2,0,H);else box(m,-T/2,T/2,lo,hi,0,H);
  for(const v of [-T/2,T/2]) {
    edge(m,p(lo,v,H/2),p(hi,v,H/2),'joint');
    for(const u of [1/3,2/3])edge(m,p(u,v,H/2),p(u,v,H),'joint');
    for(const u of [1/6,1/2,5/6])edge(m,p(u,v,0),p(u,v,H/2),'joint');
  }
  for(const u of [1/3,2/3])edge(m,p(u,-T/2,H),p(u,T/2,H),'joint');
  return m;
}
function pillar() {
  const m=model('pillar'),q=PILLAR/2,h=H+.035;
  box(m,-q,q,-q,q,0,h);
  const ring=[[-q,-q,h/2],[q,-q,h/2],[q,q,h/2],[-q,q,h/2]];
  ring.forEach((p,i)=>edge(m,p,ring[(i+1)%4],'joint'));
  return m;
}
const forward={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
const inverse={south:forward.south,north:forward.north,east:forward.west,west:forward.east};
function rotate(m,direction) {
  const tr=forward[direction];m.faces=m.faces.map(f=>({...f,points:f.points.map(tr)}));
  m.edges=m.edges.map(e=>({...e,a:tr(e.a),b:tr(e.b)}));return m;
}
function prismFaces(m,v,kind) {
  const a=v.profileXZ.map(([x,z])=>[x,v.yMin,z]),b=v.profileXZ.map(([x,z])=>[x,v.yMax,z]);
  face(m,a,kind);face(m,b,kind);
  a.forEach((p,i)=>face(m,[p,a[(i+1)%a.length],b[(i+1)%a.length],b[i]],kind));
}
function door(direction) {
  const geometry=read(sourceFiles[2]),{smallInnerRadius:ri,smallOuterRadius:ro,wallBack,wallFront}=geometry.proposal;
  const inv=inverse[direction],o=inv([0,0,0]),ray=G.sub(inv(camera.eye),o),N=56;
  const arc=(r,a,y)=>[.5+r*Math.cos(a),y,H+r*Math.sin(a)];
  function ring(m,lo,hi,y0,y1,stones) {
    for(const y of [y0,y1])for(const r of [lo,hi])for(let i=0;i<N;i++)edge(m,arc(r,i*Math.PI/N,y),arc(r,(i+1)*Math.PI/N,y));
    for(const y of [y0,y1])if(stones)for(let i=0;i<=stones;i++)edge(m,arc(lo,i*Math.PI/stones,y),arc(hi,i*Math.PI/stones,y),i&&i<stones?'joint':'wall');
    for(const r of [lo,hi]) {
      if(stones)for(const a of [0,Math.PI])edge(m,arc(r,a,y0),arc(r,a,y1));
      const facing=a=>ray[0]*Math.cos(a)+ray[2]*Math.sin(a);
      for(let i=1;i<N;i++)if(facing((i-.5)*Math.PI/N)*facing((i+.5)*Math.PI/N)<0)edge(m,arc(r,i*Math.PI/N,y0),arc(r,i*Math.PI/N,y1));
    }
  }
  function lowerEdges(m,v,smooth) {
    const xs=v.profileXZ.map(p=>p[0]),lo=Math.min(...xs),hi=Math.max(...xs);
    for(const y of [v.yMin,v.yMax]) {
      for(const z of smooth?[0]:[0,H/2,H])edge(m,[lo,y,z],[hi,y,z],z===H/2?'joint':'wall');
      for(const x of [lo,hi])edge(m,[x,y,0],[x,y,H]);
    }
    for(const x of [lo,hi])for(const z of smooth?[0]:[0,H/2,H])edge(m,[x,v.yMin,z],[x,v.yMax,z],z===H/2?'joint':'wall');
  }
  const items=[],upper=v=>Math.min(...v.profileXZ.map(p=>p[1]))>=H-1e-8;
  function part(suffix,volumes) {
    const m=model(`door-${direction}-${suffix}`);volumes.forEach(v=>prismFaces(m,v,v.part==='wood'?'door':'wall'));items.push(m);return m;
  }
  const main=geometry.volumes.filter(v=>v.part==='main'),a=part('arch',main);
  ring(a,geometry.originalArch.innerRadius,geometry.originalArch.outerRadius,.5-T/2,.5+T/2,7);
  const leaf=geometry.volumes.find(v=>v.part==='wood'),l=part('leaf',[leaf]),ps=leaf.profileXZ;
  for(const y of [leaf.yMin,leaf.yMax])ps.forEach((p,i)=>edge(l,[p[0],y,p[1]],[ps[(i+1)%ps.length][0],y,ps[(i+1)%ps.length][1]],'door'));
  ps.forEach((p,i)=>{
    const a=ps[(i-1+ps.length)%ps.length],b=ps[(i+1)%ps.length],f=(a,b)=>ray[0]*(b[1]-a[1])-ray[2]*(b[0]-a[0]);
    if(p[1]<=H+1e-8||f(a,p)*f(p,b)<0)edge(l,[p[0],leaf.yMin,p[1]],[p[0],leaf.yMax,p[1]],'door');
  });
  for(const [kind,prefix,lo,hi,y0,y1,stones] of [
    ['masonry','inner-arch',ri,ro,.5-T/2,.5+T/2,7],
    ['smooth-wall','smooth-upper',ro,geometry.originalArch.innerRadius,wallBack,wallFront,0]]) {
    const vs=geometry.volumes.filter(v=>v.part===kind),m=part(prefix,vs.filter(upper));ring(m,lo,hi,y0,y1,stones);
    vs.filter(v=>!upper(v)).forEach((v,i)=>lowerEdges(part((stones?'jamb-':'smooth-')+(i?'right':'left'),[v]),v,!stones));
  }
  l.companions=items.filter(m=>m!==a&&m!==l).map(m=>m.id);
  const parts=items.map(m=>rotate(m,direction));
  const complete={faces:parts.flatMap(m=>m.faces),edges:parts.flatMap(m=>m.edges),curvedStrips:[]};
  const visible=G.visibleEdges(complete,camera);
  // Interlocking rings cannot be ordered as whole sprites with overlapping AABBs.
  // Bake their mutual visibility together, then split at the physical wall height.
  // This gives a lower support between the rails and an upper arch above them.
  // The split adds NO visible seam and changes NO source vertex or arch profile.
  return [false,true].map(upper=>{
    const m=model(`door-${direction}-${upper?'arch':'leaf'}`),inside=p=>upper?p[2]>=H:p[2]<=H;
    const intersect=(a,b)=>G.lerp(a,b,(H-a[2])/(b[2]-a[2]));
    for(const f of complete.faces) {
      const out=[];
      f.points.forEach((a,i)=>{const b=f.points[(i+1)%f.points.length];if(inside(a))out.push(a);if(inside(a)!==inside(b))out.push(intersect(a,b));});
      if(out.length>=3)m.faces.push({...f,points:out});
    }
    for(const e of visible) {
      if(inside(e.a)&&inside(e.b))m.edges.push(e);
      else if(inside(e.a)!==inside(e.b))m.edges.push({...e,a:inside(e.a)?e.a:intersect(e.a,e.b),b:inside(e.b)?e.b:intersect(e.a,e.b)});
    }
    m.visibleEdges=m.edges;
    m.note=upper?'Complete door above spring height; mutual component occlusion baked offline.':'Complete door below spring height; legacy leaf ID, includes jambs and smooth infill.';
    return m;
  });
}
function stair(direction) {
  const source=read(sourceFiles[3]),m=model('stair-'+direction);
  // Same tread volumes used by the mobile exporter, including its widened first tread.
  source.stairs.steps.forEach((s,i)=>box(m,T/2,1-T/2,i?s.y0:T/2,s.y1,0,s.top,'stair'));
  return rotate(m,direction);
}
function heart() {
  const source=read(sourceFiles[1]).model,m=model('heart'),tr=p=>[p[0]-source.heart.centre[0],p[1]-source.heart.centre[1],p[2]];
  m.faces=source.faces.filter(f=>f.kind==='heart').map(f=>({...f,points:f.points.map(tr)}));
  m.edges=source.edges.filter(e=>e.kind==='heart').map(e=>({...e,a:tr(e.a),b:tr(e.b)}));
  m.curvedStrips=source.curvedStrips.map(s=>({a:s.a.map(tr),b:s.b.map(tr)}));
  m.orb={centre:tr(source.heart.orbCentre),radius:source.heart.orbRadius};
  m.note='Schematic support and vortex; approved painted heart is preserved, pending adaptation.';return m;
}
function torch(orientation) {
  const source=read(sourceFiles[4]).models.find(m=>m.orientation===orientation),m=model('torch-'+orientation);
  m.faces=source.faces.filter(f=>!['wall','joint'].includes(f.kind));
  // Retain ring edges, but derive curved silhouettes anew for the isometric eye.
  m.edges=source.edges.filter(e=>!['wall','joint'].includes(e.kind)&&(e.kind!=='bowl'||Math.abs(e.a[2]-e.b[2])<1e-9));
  const adjacency=new Map();
  for(const f of m.faces.filter(f=>f.kind==='bowl'))for(let i=0;i<f.points.length;i++) {
    const a=f.points[i],b=f.points[(i+1)%f.points.length];if(Math.abs(a[2]-b[2])<1e-9)continue;
    const k=[G.key(a),G.key(b)].sort().join('|');if(!adjacency.has(k))adjacency.set(k,{a,b,faces:[]});adjacency.get(k).faces.push(f);
  }
  for(const e of adjacency.values())if(e.faces.length===2) {
    const a=G.project(e.a,camera),b=G.project(e.b,camera);
    const sides=e.faces.map(f=>f.points.map(p=>G.project(p,camera)).map(p=>(b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0])).sort((a,b)=>Math.abs(b)-Math.abs(a))[0]);
    if(sides[0]*sides[1]>=0)edge(m,e.a,e.b,'bowl');
  }
  m.note='Rigid mount/cup only. Approved flame and lighting remain appearance references for later painting.';return m;
}
function allModels() {
  const ms=[floor()];for(const h of [true,false])for(let i=0;i<4;i++)ms.push(wall(h,i));
  ms.push(pillar());for(const d of ['north','east','south','west'])ms.push(stair(d),...door(d));
  ms.push(heart(),torch('horizontal'),torch('vertical'));return ms;
}
module.exports={allModels,camera,PX,T,H,PILLAR,sourceFiles,hash,ROOT};
