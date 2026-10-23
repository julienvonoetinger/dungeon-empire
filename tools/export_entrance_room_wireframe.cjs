// Offline assembly review: replace the previous test room's north terminal cell.
// Run after export_entrance_stair_wireframe.cjs. Never called by Godot.
const fs=require('node:fs'), path=require('node:path');
const root=path.resolve(__dirname,'..');
const roomSource='docs/reference/two-course-square-room.json';
const stairSource='docs/reference/entrance-stairs-open-south-wireframe.json';
const room=JSON.parse(fs.readFileSync(path.join(root,roomSource),'utf8'));
const stair=JSON.parse(fs.readFileSync(path.join(root,stairSource),'utf8'));
const t=room.wallThickness,H=room.models.after.height,J=room.models.after.courses[0];
const up=room.projection.heightUp, origin=[1,-2,0];
const project=p=>[p[0]+up[0]*p[2],p[1]+up[1]*p[2]];
const world=p=>p.map((v,i)=>v+origin[i]);
const lerp=(a,b,s)=>a.map((v,i)=>v+(b[i]-v)*s);
const round=v=>Number(v.toFixed(8));
const edges=[], boxes=[], floors=[];
const wallBoxes={N:[[0,0,0],[1,t,H]],S:[[0,1-t,0],[1,1,H]],W:[[0,0,0],[t,1,H]],E:[[1-t,0,0],[1,1,H]]};
const interfaces=[];
for(const y of[-1,4])for(const[lo,hi]of[[1,1+t],[2-t,2]])interfaces.push({axis:1,value:y,tangent:0,lo,hi});
for(const x of[-1,4])for(const[lo,hi]of[[1,1+t],[2-t,2]])interfaces.push({axis:0,value:x,tangent:1,lo,hi});
const internal=e=>interfaces.some(f=>Math.abs(e.a[f.axis]-f.value)<1e-8&&Math.abs(e.b[f.axis]-f.value)<1e-8&&[e.a,e.b].every(p=>p[f.tangent]>=f.lo-1e-8&&p[f.tangent]<=f.hi+1e-8));
const isEntrance=m=>m.offset[0]===origin[0]&&m.offset[1]===origin[1];
if(room.modules.filter(isEntrance).length!==1)throw Error('Expected one north terminal cell at (1,-2).');
if(H!==stair.wallHeight||t!==stair.wallThickness||JSON.stringify(room.projection)!==JSON.stringify(stair.projection))throw Error('Room and entrance geometry contracts differ.');

// The other sixteen modules retain their original geometry.
for(const m of room.modules) {
  if(isEntrance(m))continue;
  const at=p=>p.map((v,i)=>v+m.offset[i]);
  for(const side of m.walls)boxes.push(wallBoxes[side].map(at));
  const add=(a,b,kind='outline')=>{const e={a:at(a),b:at(b),kind};if(!internal(e))edges.push(e);};
  for(const outline of m.outlines)for(let i=0;i<outline.length;i++) {
    const a=outline[i],b=outline[(i+1)%outline.length];
    for(const z of[0,J,H])add([...a,z],[...b,z],z===J?'joint':'outline');
    add([...a,0],[...a,H]);
  }
}

// Split old course lines at the substituted cell, retaining only their exterior.
function outsideEntrance(e) {
  const cuts=[0,1];
  for(let axis=0;axis<2;axis++)for(const boundary of[origin[axis],origin[axis]+1]) {
    const d=e.b[axis]-e.a[axis];
    if(Math.abs(d)>1e-9){const s=(boundary-e.a[axis])/d;if(s>0&&s<1)cuts.push(s);}
  }
  cuts.sort((a,b)=>a-b);
  const parts=[];
  for(let i=0;i<cuts.length-1;i++) {
    const p=lerp(e.a,e.b,(cuts[i]+cuts[i+1])/2);
    const inside=p[0]>=1-1e-8&&p[0]<=2+1e-8&&p[1]>=-2-1e-8&&p[1]<=-1+1e-8;
    if(!inside)parts.push({...e,a:lerp(e.a,e.b,cuts[i]),b:lerp(e.a,e.b,cuts[i+1])});
  }
  return parts;
}
function partition(start,end,widths,min) {
  const cuts=[start];let x=start,i=0;
  while(x+widths[i%widths.length]<end-min){x=Number((x+widths[i++%widths.length]).toFixed(9));cuts.push(x);}
  cuts.push(end);return cuts;
}
// Original whole-room masonry runs from the previous two-course study.
const runs=[
  [0,0,1,[0,t],[t,1]],[0,2,3,[0,t],[2,3-t]],
  [1,0,1,[0,t],[t,1]],[1,2,3,[0,t],[2,3-t]],
  [1,0,1,[3-t,3],[t,1]],[1,2,3,[3-t,3],[2,3-t]],
  [0,0,1,[3-t,3],[t,1]],[0,2,3,[3-t,3],[2,3-t]],
  [1,3,5,[1,1+t],[3,5-t]],[1,3,5,[2-t,2],[3,5-t]],
  [1,-2,0,[1,1+t],[-2+t,0]],[1,-2,0,[2-t,2],[-2+t,0]],
  [0,-2,0,[1,1+t],[-2+t,0]],[0,-2,0,[2-t,2],[-2+t,0]],
  [0,3,5,[1,1+t],[3,5-t]],[0,3,5,[2-t,2],[3,5-t]],
  [0,1,2,[-2,-2+t],[1+t,2-t]],[0,1,2,[5-t,5],[1+t,2-t]],
  [1,1,2,[-2,-2+t],[1+t,2-t]],[1,1,2,[5-t,5],[1+t,2-t]]
];
for(const[axis,start,end,cross,cap]of runs) {
  const p=(s,c,z)=>axis===0?[s,c,z]:[c,s,z];
  const add=(a,b)=>edges.push(...outsideEntrance({a,b,kind:'joint'}));
  const phase=.7/6,step=1.9/6;
  let s=phase+Math.ceil((start+.65/6-phase)/step)*step;
  for(;s<end-.65/6;s=Number((s+step).toFixed(9)))for(const c of cross)add(p(s,c,0),p(s,c,J));
  for(const s of partition(...cap,[1.6/6,1.9/6,1.7/6,1.8/6],.65/6)) {
    add(p(s,cross[0],H),p(s,cross[1],H));
    for(const c of cross)add(p(s,c,J),p(s,c,H));
  }
}
for(const[x,y]of room.pillars) {
  boxes.push([[x,y,0],[x+t,y+t,H]]);
  const outline=[[x,y],[x+t,y],[x+t,y+t],[x,y+t]];
  for(let i=0;i<4;i++) {
    const a=outline[i],b=outline[(i+1)%4];
    for(const z of[0,J,H])edges.push({a:[...a,z],b:[...b,z],kind:z===J?'joint':'outline'});
    edges.push({a:[...a,0],b:[...a,H],kind:'outline'});
  }
}

// Whole entrance geometry, translated only. Shared end faces become internal.
let entranceInternalEdgesOmitted=0;
boxes.push(...stair.occludingVolumes.map(box=>box.map(world)));
for(const e of stair.sourceEdges) {
  if(e.kind==='floor')continue; // Preserve the room study's continuous paving.
  const transformed={...e,a:world(e.a),b:world(e.b)};
  if(internal(transformed)){entranceInternalEdgesOmitted++;continue;}
  edges.push(transformed);
}
// Retain the original global paving, including the exposed bottom landing.
// The stair volume itself hides all floor lines under the five raised steps.
for(const row of room.floorRows.room) {
  const[x0,y0,x1,y1]=row.bounds;
  floors.push({a:[x0,y0,0],b:[x1,y0,0],kind:'floor'});
  for(const x of row.cuts.slice(1,-1))floors.push({a:[x,y0,0],b:[x,y1,0],kind:'floor'});
}
function hidden(p) {
  const d=[-up[0],-up[1],1];
  return boxes.some(([lo,hi])=>{
    let enter=0,exit=Infinity;
    for(let i=0;i<3;i++){enter=Math.max(enter,(lo[i]-p[i])/d[i]);exit=Math.min(exit,(hi[i]-p[i])/d[i]);}
    return exit>Math.max(enter,1e-8)+1e-9;
  });
}
const visible=[],seen=new Set();
for(const e of[...floors,...edges]) {
  const signature=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
  if(seen.has(signature))continue;seen.add(signature);
  const N=180;let start=0,old=hidden(lerp(e.a,e.b,.5/N));
  const add=(a,b)=>{if(b-a>1e-7)visible.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
  for(let k=1;k<N;k++) {
    const next=hidden(lerp(e.a,e.b,(k+.5)/N));if(next===old)continue;
    let lo=(k-.5)/N,hi=(k+.5)/N;
    for(let j=0;j<28;j++){const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
    const cut=(lo+hi)/2;if(!old)add(start,cut);start=cut;old=next;
  }
  if(!old)add(start,1);
}
const paths={};
const toPath=e=>`M${project(e.a).map(round).join(',')}L${project(e.b).map(round).join(',')}`;
for(const kind of['floor','joint','outline','stair'])paths[kind]=visible.filter(e=>e.kind===kind).map(toPath).join('');
for(const hidden of[false,true])paths[hidden?'characterHidden':'character']=room.assembly.after.characterSegments.filter(e=>e.hidden===hidden).map(e=>`M${e.a.map(round).join(',')}L${e.b.map(round).join(',')}`).join('');
const views={room:[-2.14,5.08,-2.40,5.07],north:[.80,2.12,-2.40,.22]};
const colors={floor:'#8794a3',joint:'#526171',outline:'#1c2a3a',stair:'#1c2a3a',character:'#315e9b',characterHidden:'#315e9b'};
function svg(bounds,width,height) {
  const[x0,x1,y0,y1]=bounds;
  const scale=Math.min((width-28)/(x1-x0),(height-28)/(y1-y0));
  const dx=(width-(x0+x1)*scale)/2,dy=(height-(y0+y1)*scale)/2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="Salle 3 par 3 avec escalier à l'extrémité du couloir nord"><rect width="100%" height="100%" fill="white"/><defs><clipPath id="frame"><rect x="14" y="14" width="${width-28}" height="${height-28}"/></clipPath></defs><g clip-path="url(#frame)"><g transform="translate(${dx} ${dy}) scale(${scale})" fill="none" stroke-linecap="round">${Object.entries(paths).map(([kind,d])=>`<path d="${d}" stroke="${colors[kind]}" stroke-width="${kind==='floor'?1:kind==='joint'?1.4:2}" vector-effect="non-scaling-stroke"${kind==='characterHidden'?' stroke-dasharray="4 4" opacity=".45"':''}/>`).join('')}</g></g></svg>\n`;
}
const ports=[];
for(const x of[0,t,1-t,1])for(const z of[0,J,H]) {
  const entrance=world([x,1,z]),corridor=[1+x,-1,z];
  ports.push({entrance,corridor,projectedMismatch:Math.hypot(...project(entrance).map((v,i)=>v-project(corridor)[i]))});
}
const metadata={id:'room-north-entrance-wireframe-v1',status:'assembly_proposal_awaiting_user_review',generator:'tools/export_entrance_room_wireframe.cjs',roomSource,stairSource,grid:room.grid,projection:room.projection,wallHeight:H,wallThickness:t,replacement:{previous:'openS terminal cell',offset:origin,stairs:stair.stairs},paving:'Original whole-room pattern, including landing; unchanged outside the staircase, hidden under raised steps. The isolated entrance uses the catalog floor motif instead.',entranceInternalEdgesOmitted,ports,maximumProjectedMismatch:Math.max(...ports.map(p=>p.projectedMismatch)),views,paths,visibleEdges:visible};
const out=path.join(root,'docs/reference/room-north-entrance-wireframe');
fs.writeFileSync(out+'.json',JSON.stringify(metadata,null,2)+'\n');
fs.writeFileSync(out+'.svg',svg(views.room,1504,1360));
fs.writeFileSync(out+'-north.svg',svg(views.north,800,1100));
const inlineIndex=process.argv.indexOf('--inline');
if(inlineIndex!==-1) {
  const destination=process.argv[inlineIndex+1];
  if(!destination)throw Error('Missing output path after --inline');
  const template=fs.readFileSync(path.join(root,'docs/reference/entrance-room-preview.template.html'),'utf8');
  fs.writeFileSync(destination,template.replace('__ASSEMBLY_DATA__',JSON.stringify({id:metadata.id,views,paths})));
}
console.log(`Wrote room and north-detail SVGs; ${ports.length} matched wall-port points, maximum mismatch ${metadata.maximumProjectedMismatch}; omitted ${entranceInternalEdgesOmitted} entrance end-face edges.`);
