// Offline preparation only. Godot selects these complete textures as authored.
// First run export_entrance_stair_wireframe.cjs to update the reviewed source.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
const sourcePath='docs/reference/entrance-stairs-open-south-wireframe.json';
const source=JSON.parse(fs.readFileSync(path.join(root,sourcePath),'utf8'));
const kit=JSON.parse(fs.readFileSync(path.join(root,'assets/dungeon/wireframe-cells/catalog.json'),'utf8'));
const floorSourcePath='docs/reference/floor-periodic-cell.json';
const floor=JSON.parse(fs.readFileSync(path.join(root,floorSourcePath),'utf8')).floor;
const out=path.join(root,'assets/dungeon/wireframe-entrances');
fs.mkdirSync(out,{recursive:true});
const T=source.wallThickness,H=source.wallHeight,J=source.courseJoints[0];
const up=source.projection.heightUp,PX=kit.pixelsPerCell,anchor=kit.wallImageAnchor,size=kit.wallImageSize;
if(T!==kit.wallThickness||H!==kit.wallHeight||JSON.stringify(source.projection)!==JSON.stringify(kit.projection))throw Error('Entrance and wall kit geometry contracts differ.');
const transforms={
  north:([x,y,z])=>[1-x,1-y,z],
  east:([x,y,z])=>[y,1-x,z],
  south:([x,y,z])=>[x,y,z],
  west:([x,y,z])=>[1-y,x,z],
};
const variants={north:'w14_p00_e00',east:'w13_p00_e00',south:'w11_p00_e00',west:'w07_p00_e00'};
const project=([x,y,z])=>[x+up[0]*z,y+up[1]*z];
const round=v=>Number(v.toFixed(6));
const point=p=>project(p).map((v,i)=>round(v*PX+anchor[i])).join(',');
const lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
const polygon=points=>`<polygon points="${points.map(point).join(' ')}" fill="#ffffff"/>`;
const header=`<svg xmlns="http://www.w3.org/2000/svg" width="${size[0]}" height="${size[1]}" viewBox="0 0 ${size.join(' ')}">`;
const cuboidFaces=([a,b])=>[
  [[a[0],a[1],a[2]],[b[0],a[1],a[2]],[b[0],b[1],a[2]],[a[0],b[1],a[2]]],
  [[a[0],a[1],b[2]],[b[0],a[1],b[2]],[b[0],b[1],b[2]],[a[0],b[1],b[2]]],
  [[a[0],a[1],a[2]],[b[0],a[1],a[2]],[b[0],a[1],b[2]],[a[0],a[1],b[2]]],
  [[a[0],b[1],a[2]],[b[0],b[1],a[2]],[b[0],b[1],b[2]],[a[0],b[1],b[2]]],
  [[a[0],a[1],a[2]],[a[0],b[1],a[2]],[a[0],b[1],b[2]],[a[0],a[1],b[2]]],
  [[b[0],a[1],a[2]],[b[0],b[1],a[2]],[b[0],b[1],b[2]],[b[0],a[1],b[2]]],
];
// The ground motif remains world-aligned; rotating an entrance does not rotate paving.
const floorEdges=[],fw=floor.bounds[2]-floor.bounds[0],fh=floor.bounds[3]-floor.bounds[1];
let y=0;
for(let r=0;r<floor.rowHeights.length;r++) {
  const nextY=y+floor.rowHeights[r]/fh;
  floorEdges.push({a:[0,y,0],b:[1,y,0],kind:'floor'});
  let x=0;
  for(const width of floor.rowWidths[r].slice(0,-1)){x+=width/fw;floorEdges.push({a:[x,y,0],b:[x,nextY,0],kind:'floor'});}
  y=nextY;
}
const entries={};
for(const[direction,transform]of Object.entries(transforms)) {
  const boxes=source.occludingVolumes.map(([a,b])=>{
    const p=transform(a),q=transform(b);
    return [p.map((v,i)=>Math.min(v,q[i])),p.map((v,i)=>Math.max(v,q[i]))];
  });
  const openAxis=['north','south'].includes(direction)?1:0;
  const openValue=['north','west'].includes(direction)?0:1;
  const internal=e=>[e.a,e.b].every(p=>Math.abs(p[openAxis]-openValue)<1e-8)&&
    ([e.a,e.b].every(p=>p[1-openAxis]<=T+1e-8)||[e.a,e.b].every(p=>p[1-openAxis]>=1-T-1e-8));
  const sourceEdges=source.sourceEdges.filter(e=>e.kind!=='floor').map(e=>({...e,a:transform(e.a),b:transform(e.b)}));
  const internalEdgesOmitted=sourceEdges.filter(internal).length;
  const edges=[...floorEdges,...sourceEdges.filter(e=>!internal(e))];
  // Like the main wall catalogue, the cell on the +X/+Y side owns the masonry
  // joint at a real north/west connection. It is a stone joint, not an end face.
  // Rotating the isolated stair source alone would lose that shared port joint.
  if(openValue===0)for(const[lo,hi]of[[0,T],[1-T,1]]) {
    const at=(cross,z)=>openAxis===1?[cross,0,z]:[0,cross,z];
    edges.push({a:at(lo,H),b:at(hi,H),kind:'joint'});
    for(const cross of[lo,hi])edges.push({a:at(cross,J),b:at(cross,H),kind:'joint'});
  }
  const hidden=p=>boxes.some(([lo,hi])=>{
    const d=[-up[0],-up[1],1];let enter=0,exit=Infinity;
    for(let i=0;i<3;i++){enter=Math.max(enter,(lo[i]-p[i])/d[i]);exit=Math.min(exit,(hi[i]-p[i])/d[i]);}
    return exit>Math.max(enter,1e-8)+1e-9;
  });
  const seen=new Set(),visible=[];
  for(const e of edges) {
    const key=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
    if(seen.has(key))continue;seen.add(key);
    const N=240;let start=0,old=hidden(lerp(e.a,e.b,.5/N));
    const add=(a,b)=>{if(b-a>1e-7)visible.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
    for(let k=1;k<N;k++) {
      const next=hidden(lerp(e.a,e.b,(k+.5)/N));if(next===old)continue;
      let lo=(k-.5)/N,hi=(k+.5)/N;
      for(let j=0;j<28;j++){const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)add(start,cut);start=cut;old=next;
    }
    if(!old)add(start,1);
  }
  const lines=visible.map(e=>{
    const a=point(e.a).split(','),b=point(e.b).split(',');
    const color=e.kind==='floor'?'#8794a3':e.kind==='joint'?'#526171':'#1c2a3a';
    const width=e.kind==='floor'?1.5:e.kind==='joint'?2:3;
    return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="${color}" stroke-width="${width}"/>`;
  }).join('');
  // Neutral vector face fills are part of the prepared complete texture.
  // All line visibility is solved above, jointly, before writing this image.
  // Back and internal contact faces must not cover a neighbouring cell's lines.
  // Match the shared wall kit: only top, +Y and +X face fills, no open-port face.
  const fills=polygon([[0,0,0],[1,0,0],[1,1,0],[0,1,0]])+
    boxes.flatMap(box=>{const faces=cuboidFaces(box);return [faces[1],faces[3],faces[5]];})
      .filter(face=>!face.every(p=>Math.abs(p[openAxis]-openValue)<1e-8))
      .map(polygon).join('');
  const file=direction+'.svg';
  fs.writeFileSync(path.join(out,file),header+fills+`<g fill="none" stroke-linejoin="round" stroke-linecap="round">${lines}</g></svg>\n`);
  entries[direction]={file,variant:variants[direction],openSide:direction,downhill:direction,
    imageSize:size,anchor,internalEdgesOmitted,volumes:boxes,visibleEdges:visible,
    worldTransform:{north:'(1-x,1-y,z)',east:'(y,1-x,z)',south:'(x,y,z)',west:'(1-y,x,z)'}[direction]};
  const reviewFile=path.join(root,`docs/reference/entrance-stairs-open-${direction}-connected.svg`);
  fs.writeFileSync(reviewFile,header+fills+`<g fill="none" stroke-linejoin="round" stroke-linecap="round">${lines}</g></svg>\n`);
}
const metadata={id:'square-wireframe-entrances-v1',source:sourcePath,generator:'tools/export_wireframe_entrances.cjs',
  status:'four-direction_godot_visual_review',projection:source.projection,cell:[1,1],wallHeight:H,wallThickness:T,courseJoints:[J],stairs:source.stairs,
  pixelsPerCell:PX,imageAnchor:anchor,imageSize:size,policy:'Complete floor/walls/stairs texture. Directions label the open/downhill side. Rotate only world geometry offline. No runtime geometry, flipping, clipping or tinting.',entries};
fs.writeFileSync(path.join(out,'catalog.json'),JSON.stringify(metadata,null,2)+'\n');
fs.writeFileSync(path.join(root,'scripts/wireframe_entrance_catalog.gd'),[
  '# Generated offline by tools/export_wireframe_entrances.cjs. Complete entrance textures.',
  'extends RefCounted',`const CELL_PIXELS := ${PX}.0`,`const ANCHOR := Vector2(${anchor.join(', ')})`,
  'const TERMINALS := {',...Object.entries(entries).map(([name,e])=>`\t"${e.variant}": preload("res://assets/dungeon/wireframe-entrances/${name}.svg"),`),'}','',
].join('\n'));
console.log('Exported four complete connected entrance textures, manifest and Godot preload catalogue.');
