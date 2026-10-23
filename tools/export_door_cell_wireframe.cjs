// Offline, line-only proposal. Never loaded or executed by Godot.
// node tools/export_door_cell_wireframe.cjs [--inline absolute-preview.html]
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const wallSource = 'docs/reference/two-course-square-room.json';
const floorSource = 'docs/reference/floor-only-cell-wireframe.json';
const source = JSON.parse(fs.readFileSync(path.join(root, wallSource), 'utf8'));
const floor = JSON.parse(fs.readFileSync(path.join(root, floorSource), 'utf8')).floor;
const T = source.wallThickness, H = source.models.after.height;
const J = source.models.after.courses[0], up = source.projection.heightUp;
const round = n => Number(n.toFixed(8));
const project = ([x,y,z]) => [x + up[0]*z, y + up[1]*z];
const lerp = (a,b,t) => a.map((n,i) => n+(b[i]-n)*t);

// Proposed dimensions: a rectangular frame at the SAME height as both walls.
// No perspective change, enlarged base, raised threshold or third wall course.
const frameDepth = T, jambWidth = .05, lintelHeight = .05;
const y0 = .5-frameDepth/2, y1 = .5+frameDepth/2;
const a = T+jambWidth, b = 1-T-jambWidth, head = H-lintelHeight;
const leafFront = y1-.025, leafBack = leafFront-.025;
const boxes = [
  [[0,0,0],[T,1,H]], [[1-T,0,0],[1,1,H]],
  [[T,y0,0],[a,y1,H]], [[b,y0,0],[1-T,y1,H]],
  [[a,y0,head],[b,y1,H]],
  [[a,leafBack,0],[b,leafFront,head]],
];
const edges = [];
const edge = (p,q,kind='outline') => edges.push({a:p,b:q,kind});

// Constant-section west/east walls. Omit their inner surface where the frame
// joins it, including the coplanar top edge: the frame and walls are one union.
for (const [lo,hi] of [[0,T],[1-T,1]]) {
  const inner = lo===0 ? hi : lo, outer = lo===0 ? lo : hi;
  for (const z of [0,J,H]) {
    const kind = z===J ? 'joint' : 'outline';
    edge([outer,0,z],[outer,1,z],kind);
    edge([inner,0,z],[inner,y0,z],kind);
    edge([inner,y1,z],[inner,1,z],kind);
    for (const y of [0,1]) edge([lo,y,z],[hi,y,z],kind);
  }
  for (const x of [lo,hi]) for (const y of [0,1]) edge([x,y,0],[x,y,H]);
  for (const y of [1.6/6,3.5/6]) {
    edge([lo,y,H],[hi,y,H],'joint');
    for (const x of [lo,hi])
      if(x===outer || y<=y0 || y>=y1) edge([x,y,J],[x,y,H],'joint');
  }
  for (const y of [.7/6,2.6/6,4.5/6]) for (const x of [lo,hi])
    if(x===outer || y<=y0 || y>=y1) edge([x,y,0],[x,y,J],'joint');
}

// Front/back frame contours and opening reveal. Coplanar internal edges of
// the jamb/lintel union are omitted; the horizontal lines are real stone joints.
for (const y of [y0,y1]) {
  const contour = [[T,0],[a,0],[a,head],[b,head],[b,0],[1-T,0],[1-T,H],[T,H]];
  for (let i=0;i<contour.length;i++) {
    const p=contour[i], q=contour[(i+1)%contour.length];
    edge([p[0],y,p[1]],[q[0],y,q[1]],'frame');
  }
  for (const [x0,x1] of [[T,a],[b,1-T]]) {
    edge([x0,y,J],[x1,y,J],'joint');
    edge([x0,y,head],[x1,y,head],'joint');
  }
}
for (const x of [a,b]) for (const z of [0,head]) edge([x,y0,z],[x,y1,z],'frame');

// Closed single leaf, slightly recessed from the stone front. Every height
// edge uses the common projection; plank lines are not screen-vertical.
for (const y of [leafBack,leafFront]) {
  for (const z of [0,head]) edge([a,y,z],[b,y,z],'door');
  for (const x of [a,b]) edge([x,y,0],[x,y,head],'door');
}
for (const x of [a,b]) for (const z of [0,head]) edge([x,leafBack,z],[x,leafFront,z],'door');
for (let i=1;i<4;i++) {
  const x=a+(b-a)*i/4;
  edge([x,leafFront,0],[x,leafFront,head],'detail');
}
// Minimal door hardware, drawn on the leaf plane, not an interface icon.
const front = leafFront+1e-6;
for (const z of [head*.25,head*.75]) {
  const x0=a+.012, x1=a+(b-a)*.30, half=.006;
  const outline=[[x0,z-half],[x1,z-half],[x1,z+half],[x0,z+half]];
  for(let i=0;i<4;i++) {
    const p=outline[i],q=outline[(i+1)%4];
    edge([p[0],front,p[1]],[q[0],front,q[1]],'detail');
  }
}
const handle={x:b-.06,z:head*.50,radius:.014};
for(let i=0;i<24;i++) {
  const point = angle => [handle.x+handle.radius*Math.cos(angle),front,handle.z+handle.radius*Math.sin(angle)];
  edge(point(i*Math.PI/12),point((i+1)*Math.PI/12),'detail');
}

// Existing floor pattern, world-aligned at z=0. Trim at the wall feet; the
// combined wall/frame/leaf volume decides which remaining lines can be seen.
const fw=floor.bounds[2]-floor.bounds[0], fh=floor.bounds[3]-floor.bounds[1];
let y=0;
edge([T,0,0],[1-T,0,0],'floor');
for(let r=0;r<floor.rowHeights.length;r++) {
  const nextY=y+floor.rowHeights[r]/fh;
  edge([T,nextY,0],[1-T,nextY,0],'floor');
  let x=0;
  for(const width of floor.rowWidths[r].slice(0,-1)) {
    x+=width/fw;
    if(x>T && x<1-T) edge([x,y,0],[x,nextY,0],'floor');
  }
  y=nextY;
}

function hidden(p) {
  const direction=[-up[0],-up[1],1];
  return boxes.some(([lo,hi])=>{
    let enter=0,exit=Infinity;
    for(let i=0;i<3;i++) {
      enter=Math.max(enter,(lo[i]-p[i])/direction[i]);
      exit=Math.min(exit,(hi[i]-p[i])/direction[i]);
    }
    return exit>Math.max(enter,1e-8)+1e-9;
  });
}
const visible=[],seen=new Set();
for(const e of edges) {
  const signature=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
  if(seen.has(signature))continue;
  seen.add(signature);
  const N=240;
  let start=0,old=hidden(lerp(e.a,e.b,.5/N));
  const append=(lo,hi)=>{if(hi-lo>1e-7)visible.push({...e,a:lerp(e.a,e.b,lo),b:lerp(e.a,e.b,hi)});};
  for(let k=1;k<N;k++) {
    const next=hidden(lerp(e.a,e.b,(k+.5)/N));
    if(next===old)continue;
    let lo=(k-.5)/N,hi=(k+.5)/N;
    for(let j=0;j<28;j++) {
      const mid=(lo+hi)/2;
      if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;
    }
    const cut=(lo+hi)/2;
    if(!old)append(start,cut);
    start=cut;old=next;
  }
  if(!old)append(start,1);
}
const paths={};
for(const kind of ['floor','joint','outline','frame','door','detail']) {
  paths[kind]=visible.filter(e=>e.kind===kind).map(e=>
    `M${project(e.a).map(round).join(',')}L${project(e.b).map(round).join(',')}`).join('');
}
const viewport={min:[-.10,-.34],max:[1.06,1.05]};
const metadata={
  id:'door-cell-west-east-wireframe-v1',status:'proposal_awaiting_user_review',
  generator:'tools/export_door_cell_wireframe.cjs',wallSource,floorSource,
  projection:source.projection,cell:[1,1],walls:['west','east'],openSides:['north','south'],
  wallThickness:T,wallHeight:H,courseJoints:[J],
  frame:{centerY:.5,depth:frameDepth,jambWidth,lintelHeight,top:H,opening:[a,b,0,head]},
  door:{state:'closed',leafCount:1,bounds:[[a,leafBack,0],[b,leafFront,head]],frontRecess:.025,handle},
  floor:{z:0,motif:'Unchanged normalized 19-slab floor pattern, occluded by the combined architecture'},
  policy:'Standalone line-only proposal, no Godot or painted-asset changes. Rectangular frame and single leaf are proposed choices, not yet artistically approved.',
  occludingVolumes:boxes,sourceEdges:edges,visibleEdges:visible,paths,viewport,
};
const scale=600,ox=-viewport.min[0]*scale,oy=-viewport.min[1]*scale;
const width=round((viewport.max[0]-viewport.min[0])*scale),height=round((viewport.max[1]-viewport.min[1])*scale);
const styles={floor:['#8794a3',1.2],joint:['#526171',1.4],outline:['#1c2a3a',2],frame:['#1c2a3a',2],door:['#1c2a3a',1.8],detail:['#526171',1.2]};
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
<title id="title">Case porte — murs à gauche et à droite</title>
<desc id="desc">Case carrée ouverte au nord et au sud. Une porte fermée et son encadrement traversent le milieu du passage. Deux assises de murs et projection commune au catalogue.</desc>
<rect width="100%" height="100%" fill="white"/>
<g transform="translate(${ox} ${oy}) scale(${scale})" fill="none" stroke-linecap="round" stroke-linejoin="round">
${Object.entries(paths).map(([kind,d])=>`<path d="${d}" stroke="${styles[kind][0]}" stroke-width="${styles[kind][1]}" vector-effect="non-scaling-stroke"/>`).join('\n')}
</g></svg>\n`;
const out=path.join(root,'docs/reference/door-cell-west-east-wireframe');
fs.writeFileSync(out+'.svg',svg);
fs.writeFileSync(out+'.json',JSON.stringify(metadata,null,2)+'\n');
const inlineIndex=process.argv.indexOf('--inline');
if(inlineIndex>=0) {
  const target=process.argv[inlineIndex+1];
  if(!target || !path.isAbsolute(target))throw new Error('--inline requires an absolute HTML path');
  const template=fs.readFileSync(path.join(root,'docs/reference/door-cell-preview.template.html'),'utf8');
  fs.writeFileSync(target,template.replace('__DOOR_DATA__',JSON.stringify({id:metadata.id,paths,viewport})));
}
console.log(`Wrote ${path.relative(root,out)}.svg and .json (${visible.length} visible segments).`);
