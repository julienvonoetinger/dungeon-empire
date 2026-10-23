// Offline, line-only review proposal. Never imported or executed by Godot.
// Run: node tools/export_entrance_stair_wireframe.cjs
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const sourcePath = 'docs/reference/two-course-square-room.json';
const floorPath = 'docs/reference/floor-only-cell-wireframe.json';
const source = JSON.parse(fs.readFileSync(path.join(root, sourcePath), 'utf8'));
const floor = JSON.parse(fs.readFileSync(path.join(root, floorPath), 'utf8')).floor;
const T = source.wallThickness, H = source.models.after.height;
const J = source.models.after.courses[0], up = source.projection.heightUp;
// Proposed stair dimensions, awaiting human review. Walls use the current kit.
const count = 5, rise = .05, firstY = T, lastY = .84;
const tread = (lastY - firstY) / count;
const round = n => Number(n.toFixed(8));
const project = ([x, y, z]) => [x + up[0] * z, y + up[1] * z];
const lerp = (a, b, t) => a.map((n, i) => n + (b[i] - n) * t);
const wallOutline = [[0,0], [1,0], [1,1], [1-T,1], [1-T,T], [T,T], [T,1], [0,1]];
const boxes = [
  [[0,0,0], [1,T,H]],
  [[0,T,0], [T,1,H]],
  [[1-T,T,0], [1,1,H]],
];
const stairs = Array.from({length: count}, (_, i) => ({
  y0: firstY + i * tread, y1: firstY + (i + 1) * tread,
  top: (count - i) * rise, next: (count - i - 1) * rise,
}));
for (const s of stairs) boxes.push([[T,s.y0,0], [1-T,s.y1,s.top]]);
const edges = [];
const edge = (a,b,kind='outline') => edges.push({a,b,kind});

// Union outline of the N/W/E walls: no internal edges through their corners.
for (let i=0; i<wallOutline.length; i++) {
  const a=wallOutline[i], b=wallOutline[(i+1)%wallOutline.length];
  for (const z of [0,J,H]) edge([...a,z], [...b,z], z===J?'joint':'outline');
  edge([...a,0], [...a,H]);
  const axis = a[0]===b[0]?1:0, cross=a[1-axis];
  const start=Math.min(a[axis],b[axis]), end=Math.max(a[axis],b[axis]);
  const at=(s,z)=>axis===0?[s,cross,z]:[cross,s,z];
  // The two exposed south-facing ends are short: no vertical masonry cuts.
  if (axis===0 && Math.abs(cross-1)<1e-8) continue;
  for (const s of [.7/6,2.6/6,4.5/6])
    if(s>start+1e-8 && s<end-1e-8) edge(at(s,0),at(s,J),'joint');
  for (const s of [1.6/6,3.5/6])
    if(s>start+1e-8 && s<end-1e-8) edge(at(s,J),at(s,H),'joint');
}
for (const s of [1.6/6,3.5/6]) {
  edge([s,0,H],[s,T,H],'joint');
  edge([0,s,H],[T,s,H],'joint');
  edge([1-T,s,H],[1,s,H],'joint');
}

// Five flat treads and five risers, all using the SAME height projection.
// Stair sides meet the wall feet exactly; no side gaps or widening at the base.
for (const s of stairs) {
  edge([T,s.y0,s.top],[1-T,s.y0,s.top],'stair');
  edge([T,s.y1,s.top],[1-T,s.y1,s.top],'stair');
  edge([T,s.y1,s.next],[1-T,s.y1,s.next],'stair');
  for (const x of [T,1-T]) {
    edge([x,s.y0,s.top],[x,s.y1,s.top],'stair');
    edge([x,s.y1,s.top],[x,s.y1,s.next],'stair');
  }
}

// Retain only the existing floor motif on the landing, at z=0.
const fw=floor.bounds[2]-floor.bounds[0], fh=floor.bounds[3]-floor.bounds[1];
let y=0;
for (let r=0; r<floor.rowHeights.length; r++) {
  const nextY=y+floor.rowHeights[r]/fh;
  if (y>lastY+1e-8) edge([T,y,0],[1-T,y,0],'floor');
  if (nextY>lastY+1e-8) {
    let x=0;
    for (const width of floor.rowWidths[r].slice(0,-1)) {
      x+=width/fw;
      if(x>T && x<1-T) edge([x,Math.max(y,lastY),0],[x,nextY,0],'floor');
    }
  }
  y=nextY;
}
edge([T,1,0],[1-T,1,0],'floor'); // Boundary of this isolated proposal, not a raised lip.

// Visibility is solved against walls AND stairs before any line is drawn.
// Parametric rays point toward the shared oblique camera, without side mirroring.
function hidden(p) {
  const direction=[-up[0],-up[1],1];
  return boxes.some(([lo,hi])=>{
    let enter=0, exit=Infinity;
    for(let i=0;i<3;i++) {
      enter=Math.max(enter,(lo[i]-p[i])/direction[i]);
      exit=Math.min(exit,(hi[i]-p[i])/direction[i]);
    }
    return exit>Math.max(enter,1e-8)+1e-9;
  });
}
const visible=[], seen=new Set();
for(const e of edges) {
  const signature=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
  if(seen.has(signature)) continue;
  seen.add(signature);
  const N=240; let start=0, old=hidden(lerp(e.a,e.b,.5/N));
  const append=(a,b)=>{if(b-a>1e-7)visible.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
  for(let k=1;k<N;k++) {
    const next=hidden(lerp(e.a,e.b,(k+.5)/N));
    if(next===old)continue;
    let lo=(k-.5)/N, hi=(k+.5)/N;
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
for(const kind of ['floor','joint','outline','stair']) {
  paths[kind]=visible.filter(e=>e.kind===kind).map(e=>
    `M${project(e.a).map(round).join(',')}L${project(e.b).map(round).join(',')}`).join('');
}
const viewport={min:[-.1,-.34],max:[1.06,1.05]};
const scale=600, ox=-viewport.min[0]*scale, oy=-viewport.min[1]*scale;
const width=round((viewport.max[0]-viewport.min[0])*scale), height=round((viewport.max[1]-viewport.min[1])*scale);
const styles={floor:['#8794a3',1.2],joint:['#526171',1.4],outline:['#1c2a3a',2],stair:['#1c2a3a',2]};
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
<title id="title">Entrée du donjon — escalier descendant vers le sud</title>
<desc id="desc">Case carrée, murs au nord, à l'ouest et à l'est. Cinq marches descendent du haut vers le palier ouvert au sud. Projection commune à tout le catalogue.</desc>
<rect width="100%" height="100%" fill="white"/>
<g transform="translate(${ox} ${oy}) scale(${scale})" fill="none" stroke-linejoin="round" stroke-linecap="round">
${Object.entries(paths).map(([kind,d])=>`<path d="${d}" stroke="${styles[kind][0]}" stroke-width="${styles[kind][1]}" vector-effect="non-scaling-stroke"/>`).join('\n')}
</g></svg>\n`;
const metadata={
  id:'entrance-stairs-open-south-wireframe-v1',status:'proposal_awaiting_user_review',
  generator:'tools/export_entrance_stair_wireframe.cjs',wallSource:sourcePath,floorSource:floorPath,
  projection:source.projection,cell:[1,1],walls:['north','east','west'],openSide:'south',
  wallThickness:T,wallHeight:H,courseJoints:[J],
  stairs:{count,rise,treadDepth:tread,width:1-2*T,highestZ:count*rise,direction:'descending +Y (top to bottom)',bounds:[T,firstY,1-T,lastY],steps:stairs},
  landing:{bounds:[T,lastY,1-T,1],z:0,motif:'Existing floor-only pattern clipped to the exposed landing'},
  policy:'Standalone line-only proposal. No scene, runtime catalogue, gameplay or painted-asset changes. All orientations must use this same projection; never mirror the drawing.',
  wallOutline,occludingVolumes:boxes,sourceEdges:edges,visibleEdges:visible,paths,viewport,
};
const out=path.join(root,'docs/reference/entrance-stairs-open-south-wireframe');
fs.writeFileSync(out+'.svg',svg);
fs.writeFileSync(out+'.json',JSON.stringify(metadata,null,2)+'\n');
console.log(`Wrote ${path.relative(root,out)}.svg and .json (${visible.length} visible line segments).`);
