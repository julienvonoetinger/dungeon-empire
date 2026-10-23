// Deterministic vector GEOMETRY study. Does not read or repair painted images.
// Run with Node from the repository root. Godot imports the SVGs as textures.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'assets/dungeon/wireframe-cells');
fs.mkdirSync(out, { recursive: true });
const reference = JSON.parse(fs.readFileSync(path.join(root, 'docs/reference/two-course-square-room.json'), 'utf8'));
const T = reference.wallThickness, H = reference.models.after.height;
const J = reference.models.after.courses[0];
const PX = 256, anchor = [24, 88], size = [304, 352], floorGutter = 4;
const direction = [1, 2, 4, 8]; // N E S W
const cornerSides = [9, 3, 6, 12]; // NW NE SE SW
const cornerCells = [[0,0], [5,0], [5,5], [0,5]];
const projection = reference.projection.heightUp;
const project = ([x,y,z]) => [x + projection[0]*z, y + projection[1]*z];
const fmt = v => Number(v.toFixed(5));
const point = p => project(p).map((v,i) => fmt(v*PX + anchor[i])).join(',');
const key = (w,p,e) => `w${String(w).padStart(2,'0')}_p${String(p).padStart(2,'0')}_e${String(e).padStart(2,'0')}`;
const header = (w,h) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">`;
const polygon = points => `<polygon points="${points.map(point).join(' ')}" fill="#ffffff"/>`;
const line = (a,b,course=false) => `<line x1="${point(a).split(',')[0]}" y1="${point(a).split(',')[1]}" x2="${point(b).split(',')[0]}" y2="${point(b).split(',')[1]}" stroke="${course?'#526171':'#1c2a3a'}" stroke-width="${course?2:3}"/>`;

function occupied(w,p,x,y) {
  if (x<0 || x>5 || y<0 || y>5) return false;
  if ((w&1 && y===0) || (w&2 && x===5) || (w&4 && y===5) || (w&8 && x===0)) return true;
  return cornerCells.some(([cx,cy],i) => p&(1<<i) && x===cx && y===cy);
}

function geometry(w,p,e) {
  const cells=[], boxes=[], groups=new Map();
  const realNeighbours = 15 ^ (w|e);
  const isPort = (side,x,y) => (realNeighbours&direction[side]) &&
    [y===0,x===5,y===5,x===0][side];
  for(let y=0;y<6;y++) for(let x=0;x<6;x++) if(occupied(w,p,x,y)) {
    cells.push([x,y]); boxes.push([[x*T,y*T,0],[(x+1)*T,(y+1)*T,H]]);
    for(const [side,dx,dy] of [[0,0,-1],[1,1,0],[2,0,1],[3,-1,0]]) {
      if(occupied(w,p,x+dx,y+dy) || isPort(side,x,y)) continue;
      const axis = side%2===0 ? 0:1;
      const cross = axis===0 ? y+(side===2?1:0):x+(side===1?1:0);
      const start = axis===0 ? x:y;
      const group = `${side}:${cross}`;
      if(!groups.has(group)) groups.set(group,{side,axis,cross,starts:[]});
      groups.get(group).starts.push(start);
    }
  }
  const boundaries=[];
  for(const g of groups.values()) {
    g.starts.sort((a,b)=>a-b);
    let start=g.starts[0], end=start+1;
    const append=()=>boundaries.push({side:g.side,axis:g.axis,cross:g.cross*T,start:start*T,end:end*T});
    for(const s of g.starts.slice(1)) { if(s===end) end++; else {append();start=s;end=s+1;} }
    append();
  }
  const pos=(b,s,z)=>b.axis===0?[s,b.cross,z]:[b.cross,s,z];
  const edges=[], faces=[];
  const edge=(a,b,course=false)=>edges.push({a,b,course});
  const portPoint = a => ((realNeighbours&1)&&Math.abs(a[1])<1e-8) ||
    ((realNeighbours&2)&&Math.abs(a[0]-1)<1e-8) ||
    ((realNeighbours&4)&&Math.abs(a[1]-1)<1e-8) ||
    ((realNeighbours&8)&&Math.abs(a[0])<1e-8);
  for(const b of boundaries) {
    const a=pos(b,b.start,0), c=pos(b,b.end,0);
    if(b.side===1 || b.side===2) faces.push({points:[a,c,pos(b,b.end,H),pos(b,b.start,H)],depth:(a[0]+c[0])*.18+(a[1]+c[1])*.9});
    for(const z of [0,J,H]) edge(pos(b,b.start,z),pos(b,b.end,z),z===J);
    for(const s of [b.start,b.end]) if(!portPoint(pos(b,s,0))) edge(pos(b,s,0),pos(b,s,H));
    // Piers are one square stone in plan, with a horizontal joint only.
    const wallRunsAlong = b.axis===0 ? (w&(b.cross<=T+1e-8?1:4)) : (w&(b.cross<=T+1e-8?8:2));
    if(!wallRunsAlong) continue;
    for(const s of [.7/6, .7/6+1.9/6, .7/6+3.8/6]) if(s>b.start+1e-8 && s<b.end-1e-8) edge(pos(b,s,0),pos(b,s,J),true);
    for(const s of [0,1.6/6,3.5/6]) if(s>=b.start-1e-8 && s<b.end-1e-8 && (s>0 || portPoint(pos(b,s,0)))) edge(pos(b,s,J),pos(b,s,H),true);
  }
  for(let side=0;side<4;side++) if(w&direction[side]) {
    const axis=side%2===0?0:1, lo=(side===1||side===2)?1-T:0, hi=lo+T;
    const at=(s,c)=>axis===0?[s,c,H]:[c,s,H];
    for(const s of [0,1.6/6,3.5/6]) {
      if(s===0 && !(realNeighbours&(axis===0?8:1))) continue;
      edge(at(s,lo),at(s,hi),true);
    }
  }
  // Ray visibility uses the accepted common camera direction, for all orientations.
  function hidden(p) {
    const eye=p.map((v,i)=>v+[-projection[0],-projection[1],1][i]*100);
    const d=p.map((v,i)=>v-eye[i]);
    return boxes.some(([lo,hi])=>{
      let enter=0,exit=1;
      for(let i=0;i<3;i++){const a=(lo[i]-eye[i])/d[i],b=(hi[i]-eye[i])/d[i];enter=Math.max(enter,Math.min(a,b));exit=Math.min(exit,Math.max(a,b));}
      return enter<exit-1e-9 && enter<1-1e-8 && exit>0;
    });
  }
  const lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
  const lines=[], seen=new Set();
  for(const ed of edges) {
    const signature=[ed.a,ed.b].map(p=>p.map(fmt).join(',')).sort().join('|');
    if(seen.has(signature)) continue; seen.add(signature);
    const N=48; let start=0, old=hidden(lerp(ed.a,ed.b,.5/N));
    for(let k=1;k<N;k++) {
      const next=hidden(lerp(ed.a,ed.b,(k+.5)/N));
      if(next===old) continue;
      let lo=(k-.5)/N,hi=(k+.5)/N;
      for(let j=0;j<24;j++){const mid=(lo+hi)/2;if(hidden(lerp(ed.a,ed.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;
      if(!old) lines.push(line(lerp(ed.a,ed.b,start),lerp(ed.a,ed.b,cut),ed.course));
      start=cut;old=next;
    }
    if(!old) lines.push(line(lerp(ed.a,ed.b,start),ed.b,ed.course));
  }
  faces.sort((a,b)=>a.depth-b.depth);
  // Fill the same mathematical volume before drawing its visible edges. No painted input.
  const tops=cells.map(([x,y])=>'M'+[[x*T,y*T,H],[(x+1)*T,y*T,H],[(x+1)*T,(y+1)*T,H],[x*T,(y+1)*T,H]].map(point).join('L')+'Z').join('');
  return {svg:header(...size)+faces.map(f=>polygon(f.points)).join('')+`<path d="${tops}" fill="#ffffff"/>`+lines.join('')+'</svg>',hasWalls:cells.length>0};
}

// Copy the authored floor-only cell's 19-slab pattern. Normalize its former
// 6x5 drawing frame to the subsequently requested square cell; invent no joints.
const floorSourcePath='docs/reference/floor-only-cell-wireframe.json';
const floorSource=JSON.parse(fs.readFileSync(path.join(root,floorSourcePath),'utf8')).floor;
const fw=floorSource.bounds[2]-floorSource.bounds[0], fh=floorSource.bounds[3]-floorSource.bounds[1];
const rows=[0];
for(const height of floorSource.rowHeights)rows.push(rows.at(-1)+height/fh);
let floor=header(PX+2*floorGutter,PX+2*floorGutter)+`<g transform="translate(${floorGutter} ${floorGutter})"><rect width="${PX}" height="${PX}" fill="#ffffff"/><g fill="none" stroke="#8794a3" stroke-width="1.5">`;
for(let r=0;r<floorSource.rowWidths.length;r++) {
  const y0=rows[r]*PX,y1=rows[r+1]*PX;
  floor+=`<path d="M0 ${fmt(y0)}H${PX}"/>`;
  let cut=0;
  for(const width of floorSource.rowWidths[r].slice(0,-1)) {
    cut+=width/fw;
    floor+=`<path d="M${fmt(cut*PX)} ${fmt(y0)}V${fmt(y1)}"/>`;
  }
}
floor+='</g></g></svg>';
fs.writeFileSync(path.join(out,'floor.svg'),floor);
const entries={};
for(let w=0;w<16;w++) for(let e=0;e<16;e++) {
  if(w&e)continue;
  let allowed=0; cornerSides.forEach((s,i)=>{if(!((w|e)&s))allowed|=1<<i;});
  for(let p=0;p<16;p++) {
    if(p&~allowed)continue;
    const name=key(w,p,e), result=geometry(w,p,e);
    fs.writeFileSync(path.join(out,name+'.svg'),result.svg);
    entries[name]={file:name+'.svg',walls:w,piers:p,exposedEnds:e,hasWalls:result.hasWalls};
  }
}
const manifest={id:'square-two-course-cell-kit-v1',status:'wireframe_placeholder',source:'docs/reference/two-course-square-room.json',generator:'tools/export_wireframe_cell_kit.cjs',projection:reference.projection,cell:[1,1],pixelsPerCell:PX,wallThickness:T,wallHeight:H,courseJoints:[J],wallImageSize:size,wallImageAnchor:anchor,wallBits:{north:1,east:2,south:4,west:8},pierBits:{northwest:1,northeast:2,southeast:4,southwest:8},selection:'Cardinal absent neighbours create walls. Two real cardinal neighbours with an absent diagonal create a pier. Explicit open endpoints remove a wall but preserve exposed end faces. No image rotation or reflection.',floor:{file:'floor.svg',source:floorSourcePath,imageAnchor:[floorGutter,floorGutter],rows,pattern:'authored 19-slab floor-only motif, normalized from drawing frame 6x5 to square 1x1; no newly invented joint pattern; repeated cell motif, not the whole-room paving study'},entries};
fs.writeFileSync(path.join(out,'catalog.json'),JSON.stringify(manifest,null,2)+'\n');
// Explicit preloads keep every selected texture in Godot's dependency/export graph.
const gd=['# Generated by tools/export_wireframe_cell_kit.cjs. Wireframe placeholders only.','extends RefCounted',`const CELL_PIXELS := ${PX}.0`,`const WALL_ANCHOR := Vector2(${anchor.join(', ')})`,`const FLOOR_ANCHOR := Vector2(${floorGutter}, ${floorGutter})`,'const FLOOR = preload("res://assets/dungeon/wireframe-cells/floor.svg")',`const EMPTY_VARIANTS := ${JSON.stringify(Object.entries(entries).filter(([,entry])=>!entry.hasWalls).map(([id])=>id))}`,'const WALLS := {',...Object.entries(entries).filter(([,entry])=>entry.hasWalls).map(([id,entry])=>`\t"${id}": preload("res://assets/dungeon/wireframe-cells/${entry.file}"),`),'}',''];
fs.writeFileSync(path.join(root,'scripts/wireframe_cell_catalog.gd'),gd.join('\n'));
console.log(`Exported ${Object.keys(entries).length} complete wall variants and one floor texture to ${out}`);
