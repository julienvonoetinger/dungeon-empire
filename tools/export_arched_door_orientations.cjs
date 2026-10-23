// Four standalone wireframe proposals, prepared offline. No Godot integration.
// First: node tools/export_arched_door_cell_wireframe.cjs
// Then: node tools/export_arched_door_orientations.cjs [--inline absolute.html]
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
const sourcePath='docs/reference/door-arch-cell-west-east-wireframe.json';
const source=JSON.parse(fs.readFileSync(path.join(root,sourcePath),'utf8'));
const floorSourcePath='docs/reference/floor-periodic-cell.json';
const floor=JSON.parse(fs.readFileSync(path.join(root,floorSourcePath),'utf8')).floor;
const T=source.wallThickness,H=source.wallHeight,up=source.projection.heightUp;
const frame=source.frame,leaf=source.door;
const round=n=>Number(n.toFixed(8));
const project=([x,y,z])=>[x+up[0]*z,y+up[1]*z];
const lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
const cross=(a,b)=>a[0]*b[1]-a[1]*b[0];
const worldRay=[-up[0],-up[1],1];
const transforms={
  north:{label:'Nord',description:'Face arrière',formula:'(1-x, 1-y, z)',forward:([x,y,z])=>[1-x,1-y,z],inverse:([x,y,z])=>[1-x,1-y,z]},
  east:{label:'Est',description:'Face avant, de profil',formula:'(y, 1-x, z)',forward:([x,y,z])=>[y,1-x,z],inverse:([x,y,z])=>[1-y,x,z]},
  south:{label:'Sud',description:'Orientation de référence',formula:'(x, y, z)',forward:([x,y,z])=>[x,y,z],inverse:([x,y,z])=>[x,y,z]},
  west:{label:'Ouest',description:'Face arrière, de profil',formula:'(1-y, x, z)',forward:([x,y,z])=>[1-y,x,z],inverse:([x,y,z])=>[y,1-x,z]},
};
if(!source.sourceEdges.some(e=>e.role==='apparent-contour'))
  throw Error('Regenerate the source with the current exporter: its camera-dependent contours must be identified.');

// All leaf details, including two handles, belong to the shared source model.
if(!leaf.doubleSided || leaf.hardwareFaces.length!==2)
  throw Error('Regenerate the source with the complete double-sided leaf.');

function paving(direction) {
  const vertical=['north','south'].includes(direction);
  const x0=vertical?T:0,x1=vertical?1-T:1,y0=vertical?0:T,y1=vertical?1:1-T;
  const edges=[];
  const add=(a,b)=>edges.push({a,b,kind:'floor'});
  add([x0,y0,0],[x1,y0,0]);add([x0,y1,0],[x1,y1,0]);
  const fw=floor.bounds[2]-floor.bounds[0],fh=floor.bounds[3]-floor.bounds[1];
  let y=0;
  for(let r=0;r<floor.rowHeights.length;r++) {
    const nextY=y+floor.rowHeights[r]/fh;
    if(nextY>y0+1e-9 && nextY<y1-1e-9)add([x0,nextY,0],[x1,nextY,0]);
    const lo=Math.max(y,y0),hi=Math.min(nextY,y1);
    let x=0;
    for(const width of floor.rowWidths[r].slice(0,-1)) {
      x+=width/fw;
      if(hi>lo && x>x0 && x<x1)add([x,lo,0],[x,hi,0]);
    }
    y=nextY;
  }
  return edges;
}
const entries={};
for(const [direction,transform] of Object.entries(transforms)) {
  const origin=transform.inverse([0,0,0]);
  const ray=transform.inverse(worldRay).map((v,i)=>v-origin[i]);
  const localEdges=source.sourceEdges.filter(e=>e.kind!=='floor' && e.role!=='apparent-contour');
  const steps=frame.stoneCount*frame.subdivisionsPerStone;
  const arcPoint=(r,angle,y)=>[.5+r*Math.cos(angle),y,frame.springHeight+r*Math.sin(angle)];
  for(let i=1;i<steps;i++) {
    const facing=angle=>ray[0]*Math.cos(angle)+ray[2]*Math.sin(angle);
    if(facing((i-.5)*Math.PI/steps)*facing((i+.5)*Math.PI/steps)<0) {
      for(const radius of [frame.innerRadius,frame.outerRadius])
        localEdges.push({a:arcPoint(radius,i*Math.PI/steps,.5-frame.depth/2),
          b:arcPoint(radius,i*Math.PI/steps,.5+frame.depth/2),kind:'frame',role:'apparent-contour'});
    }
  }
  const edges=[...paving(direction),...localEdges.map(e=>({...e,a:transform.forward(e.a),b:transform.forward(e.b)}))];
  function hidden(worldPoint) {
    const p=transform.inverse(worldPoint);
    return source.occludingVolumes.some(volume=>{
      const p0=(volume.yMin-p[1])/ray[1],p1=(volume.yMax-p[1])/ray[1];
      let enter=Math.max(0,Math.min(p0,p1)),exit=Math.max(p0,p1);
      for(let i=0;i<volume.profileXZ.length;i++) {
        const a=volume.profileXZ[i],b=volume.profileXZ[(i+1)%volume.profileXZ.length];
        const e=[b[0]-a[0],b[1]-a[1]];
        const value=cross(e,[p[0]-a[0],p[2]-a[1]]),slope=cross(e,[ray[0],ray[2]]);
        if(Math.abs(slope)<1e-12) { if(value<=1e-10)return false; }
        else if(slope>0)enter=Math.max(enter,-value/slope);
        else exit=Math.min(exit,-value/slope);
        if(exit<=Math.max(enter,1e-8)+1e-9)return false;
      }
      return exit>Math.max(enter,1e-8)+1e-9;
    });
  }
  const visible=[],seen=new Set();
  for(const e of edges) {
    const key=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
    if(seen.has(key))continue;seen.add(key);
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
  for(const kind of ['floor','joint','outline','frame','door','detail'])
    paths[kind]=visible.filter(e=>e.kind===kind).map(e=>`M${project(e.a).map(round).join(',')}L${project(e.b).map(round).join(',')}`).join('');
  const vertical=['north','south'].includes(direction);
  entries[direction]={id:`door-arch-facing-${direction}-wireframe-v2-double-sided`,status:'proposal_awaiting_user_review',
    source:sourcePath,generator:'tools/export_arched_door_orientations.cjs',directionMeaning:'Direction of the door front normal',
    facing:direction,label:transform.label,description:transform.description,worldTransform:transform.formula,
    projection:source.projection,cell:[1,1],walls:vertical?['west','east']:['north','south'],
    openSides:vertical?['north','south']:['west','east'],
    wallThickness:T,wallHeight:H,frame:{...frame,sourceLocalCoordinates:true},
    floorPolicy:'Unchanged normalized motif in WORLD axes, trimmed to the current wall feet. Never rotate paving.',
    door:{...leaf,sourceLocalCoordinates:true},
    doorFaces:'One centered physical leaf, equal front/rear recess, with plank seams, two bands and a handle on EACH face. Hardware remains in its true face plane.',
    visibility:{method:'Inverse-transform world points and camera ray into the source convex prisms',localCameraRay:ray},
    bearings:frame.bearings.map(bearing=>({corners:[
      [bearing.bounds[0],bearing.bounds[1],bearing.z],[bearing.bounds[2],bearing.bounds[1],bearing.z],
      [bearing.bounds[2],bearing.bounds[3],bearing.z],[bearing.bounds[0],bearing.bounds[3],bearing.z],
    ].map(transform.forward)})),
    sourceEdges:edges,visibleEdges:visible,paths,
  };
}
// One common framing and scale, derived from ALL orientations; lateral arches
// extend farther up-screen and must not be cropped by the source's viewport.
const points=Object.values(entries).flatMap(entry=>entry.sourceEdges.flatMap(e=>[project(e.a),project(e.b)]));
const viewport={min:[0,1].map(i=>round(Math.min(...points.map(p=>p[i]))-.04)),
  max:[0,1].map(i=>round(Math.max(...points.map(p=>p[i]))+.04))};
const styles={floor:['#8794a3',1.2],joint:['#526171',1.4],outline:['#1c2a3a',2],frame:['#1c2a3a',2],door:['#1c2a3a',1.8],detail:['#526171',1.2]};
const group=(entry,scale,tx,ty)=>`<g transform="translate(${tx} ${ty}) scale(${scale})" fill="none" stroke-linecap="round" stroke-linejoin="round">\n${Object.entries(entry.paths).map(([kind,d])=>`<path d="${d}" stroke="${styles[kind][0]}" stroke-width="${styles[kind][1]}" vector-effect="non-scaling-stroke"/>`).join('\n')}\n</g>`;
const scale=600,width=Math.ceil((viewport.max[0]-viewport.min[0])*scale),height=Math.ceil((viewport.max[1]-viewport.min[1])*scale);
for(const [direction,entry] of Object.entries(entries)) {
  entry.viewport=viewport;entry.previewSize=[width,height];
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="Porte voûtée orientée vers ${entry.label}">\n<rect width="100%" height="100%" fill="white"/>\n${group(entry,scale,-viewport.min[0]*scale,-viewport.min[1]*scale)}\n</svg>\n`;
  const out=path.join(root,`docs/reference/door-arch-facing-${direction}-wireframe`);
  fs.writeFileSync(out+'.svg',svg);fs.writeFileSync(out+'.json',JSON.stringify(entry,null,2)+'\n');
  console.log(`${direction}: ${entry.visibleEdges.length} visible segments; ${width}x${height} preview.`);
}
const combined={id:'door-arch-four-orientations-v2-double-sided',source:sourcePath,projection:source.projection,viewport,
  convention:'Orientation names indicate the front of the door; the game camera stays fixed.',entries};
fs.writeFileSync(path.join(root,'docs/reference/door-arch-four-orientations.json'),JSON.stringify(combined,null,2)+'\n');
const cw=420,ch=620,comparisonScale=350;
const comparison=Object.values(entries).map((entry,i)=>{
  const x=(i%2)*cw,y=Math.floor(i/2)*ch;
  const tx=x+(cw-(viewport.max[0]-viewport.min[0])*comparisonScale)/2-viewport.min[0]*comparisonScale;
  return `<text x="${x+20}" y="${y+24}" font-family="Arial,sans-serif" font-size="16" fill="#1c2a3a">${entry.label} — ${entry.description}</text>\n${group(entry,comparisonScale,tx,y+50-viewport.min[1]*comparisonScale)}`;
}).join('\n');
fs.writeFileSync(path.join(root,'docs/reference/door-arch-four-orientations.svg'),
  `<svg xmlns="http://www.w3.org/2000/svg" width="840" height="1240" viewBox="0 0 840 1240" role="img" aria-label="Les quatre orientations de la porte voûtée">\n<rect width="100%" height="100%" fill="white"/>\n${comparison}\n</svg>\n`);
const inlineIndex=process.argv.indexOf('--inline');
if(inlineIndex>=0) {
  const target=process.argv[inlineIndex+1];
  if(!target || !path.isAbsolute(target))throw Error('--inline requires an absolute HTML path');
  const template=fs.readFileSync(path.join(root,'docs/reference/door-orientations-preview.template.html'),'utf8');
  const inline={id:combined.id,viewport,entries:Object.fromEntries(Object.entries(entries).map(([key,e])=>[key,{label:e.label,description:e.description,paths:e.paths}]))};
  fs.writeFileSync(target,template.replace('__DOOR_ORIENTATIONS__',JSON.stringify(inline)));
}
