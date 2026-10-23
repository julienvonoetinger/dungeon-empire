// Offline connected door textures. Godot only selects and places these images.
// Run the arched source and four-orientation exporters first.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
const sourcePath='docs/reference/door-arch-cell-west-east-wireframe.json';
const source=JSON.parse(fs.readFileSync(path.join(root,sourcePath),'utf8'));
const kit=JSON.parse(fs.readFileSync(path.join(root,'assets/dungeon/wireframe-cells/catalog.json'),'utf8'));
const out=path.join(root,'assets/dungeon/wireframe-doors');
fs.mkdirSync(out,{recursive:true});
const T=source.wallThickness,H=source.wallHeight,J=source.courseJoints[0];
const up=source.projection.heightUp,PX=kit.pixelsPerCell;
if(T!==kit.wallThickness || H!==kit.wallHeight || JSON.stringify(source.projection)!==JSON.stringify(kit.projection))
  throw Error('Door and wall kit geometry contracts differ.');
const transforms={
  north:{forward:([x,y,z])=>[1-x,1-y,z],inverse:([x,y,z])=>[1-x,1-y,z]},
  east:{forward:([x,y,z])=>[y,1-x,z],inverse:([x,y,z])=>[1-y,x,z]},
  south:{forward:p=>p,inverse:p=>p},
  west:{forward:([x,y,z])=>[1-y,x,z],inverse:([x,y,z])=>[y,1-x,z]},
};
const studies=Object.fromEntries(Object.keys(transforms).map(dir=>[dir,
  JSON.parse(fs.readFileSync(path.join(root,`docs/reference/door-arch-facing-${dir}-wireframe.json`),'utf8'))]));
const project=([x,y,z])=>[x+up[0]*z,y+up[1]*z];
const round=n=>Number(n.toFixed(6)),cross=(a,b)=>a[0]*b[1]-a[1]*b[0];
const lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
// A taller gutter accommodates the lateral arch, without scaling the cell.
const minY=Math.min(...Object.values(studies).flatMap(s=>s.sourceEdges.flatMap(e=>[project(e.a)[1],project(e.b)[1]])));
const anchor=[kit.wallImageAnchor[0],Math.max(kit.wallImageAnchor[1],Math.ceil((-minY*PX+8)/16)*16)];
const size=[kit.wallImageSize[0],anchor[1]+PX+8];
const point=p=>project(p).map((v,i)=>round(v*PX+anchor[i])).join(',');
const polygon=points=>`<polygon points="${points.map(point).join(' ')}" fill="#ffffff"/>`;
const entries={};
for(const [direction,transform] of Object.entries(transforms)) {
  const study=studies[direction],axis=['north','south'].includes(direction)?1:0;
  const ray=study.visibility.localCameraRay;
  // Both corridor ports meet real neighbours. Omit their end faces, retaining
  // only the masonry joint owned by this cell at its north/west boundary.
  const onPort=points=>[0,1].some(v=>points.every(p=>Math.abs(p[axis]-v)<1e-8));
  const internal=e=>onPort([e.a,e.b]) &&
    ([e.a,e.b].every(p=>p[1-axis]<=T+1e-8)||[e.a,e.b].every(p=>p[1-axis]>=1-T-1e-8));
  const edges=study.sourceEdges.filter(e=>!internal(e));
  for(const [lo,hi] of [[0,T],[1-T,1]]) {
    const at=(s,z)=>axis===1?[s,0,z]:[0,s,z];
    edges.push({a:at(lo,H),b:at(hi,H),kind:'joint',role:'port-masonry'});
    for(const s of [lo,hi])edges.push({a:at(s,J),b:at(s,H),kind:'joint',role:'port-masonry'});
  }
  function hidden(worldPoint) {
    const p=transform.inverse(worldPoint);
    return source.occludingVolumes.some(volume=>{
      const t0=(volume.yMin-p[1])/ray[1],t1=(volume.yMax-p[1])/ray[1];
      let enter=Math.max(0,Math.min(t0,t1)),exit=Math.max(t0,t1);
      for(let i=0;i<volume.profileXZ.length;i++) {
        const a=volume.profileXZ[i],b=volume.profileXZ[(i+1)%volume.profileXZ.length];
        const e=[b[0]-a[0],b[1]-a[1]],value=cross(e,[p[0]-a[0],p[2]-a[1]]),slope=cross(e,[ray[0],ray[2]]);
        if(Math.abs(slope)<1e-12){if(value<=1e-10)return false;}
        else if(slope>0)enter=Math.max(enter,-value/slope);
        else exit=Math.min(exit,-value/slope);
        if(exit<=Math.max(enter,1e-8)+1e-9)return false;
      }
      return exit>Math.max(enter,1e-8)+1e-9;
    });
  }
  // A paving boundary can coincide exactly with a wall foot. Preserve the
  // structural stroke, matching neighbouring wall cells, before deduplication.
  const priority={floor:0,detail:1,joint:2,door:3,frame:4,outline:5};
  edges.sort((a,b)=>priority[b.kind]-priority[a.kind]);
  const visible=[],seen=new Set();
  for(const e of edges) {
    const key=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
    if(seen.has(key))continue;seen.add(key);
    const N=240;let start=0,old=hidden(lerp(e.a,e.b,.5/N));
    const add=(lo,hi)=>{if(hi-lo>1e-7)visible.push({...e,a:lerp(e.a,e.b,lo),b:lerp(e.a,e.b,hi)});};
    for(let k=1;k<N;k++) {
      const next=hidden(lerp(e.a,e.b,(k+.5)/N));if(next===old)continue;
      let lo=(k-.5)/N,hi=(k+.5)/N;
      for(let j=0;j<28;j++){const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)add(start,cut);start=cut;old=next;
    }
    if(!old)add(start,1);
  }
  // Neutral face fills belong to this complete vector study. Only faces toward
  // the fixed camera are filled. Internal port faces must never cover neighbours.
  const faces=[];
  for(const v of source.occludingVolumes) {
    const profile=v.profileXZ;
    faces.push(profile.map(([x,z])=>[x,ray[1]>0?v.yMax:v.yMin,z]));
    for(let i=0;i<profile.length;i++) {
      const a=profile[i],b=profile[(i+1)%profile.length];
      if((b[1]-a[1])*ray[0]-(b[0]-a[0])*ray[2]<=1e-10)continue;
      faces.push([[a[0],v.yMin,a[1]],[b[0],v.yMin,b[1]],[b[0],v.yMax,b[1]],[a[0],v.yMax,a[1]]]);
    }
  }
  const fills=polygon([[0,0,0],[1,0,0],[1,1,0],[0,1,0]])+
    faces.map(face=>face.map(transform.forward)).filter(face=>!onPort(face)).map(polygon).join('');
  const lines=visible.map(e=>{
    const [x1,y1]=point(e.a).split(','),[x2,y2]=point(e.b).split(',');
    const fine=e.kind==='joint'||e.kind==='detail';
    const color=e.kind==='floor'?'#8794a3':fine?'#526171':'#1c2a3a';
    const width=e.kind==='floor'?1.5:fine?2:3;
    return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="${width}"/>`;
  }).join('');
  const file=direction+'.svg';
  fs.writeFileSync(path.join(out,file),`<svg xmlns="http://www.w3.org/2000/svg" width="${size[0]}" height="${size[1]}" viewBox="0 0 ${size.join(' ')}">${fills}<g fill="none" stroke-linecap="round" stroke-linejoin="round">${lines}</g></svg>\n`);
  entries[direction]={file,variant:axis===1?'w10_p00_e00':'w05_p00_e00',facing:direction,
    imageSize:size,anchor,internalEdgesOmitted:study.sourceEdges.filter(internal).length,
    worldTransform:study.worldTransform,visibleEdges:visible};
}
const metadata={id:'square-wireframe-doors-v1',source:sourcePath,generator:'tools/export_wireframe_doors.cjs',
  projection:source.projection,cell:[1,1],pixelsPerCell:PX,imageAnchor:anchor,imageSize:size,
  wallThickness:T,wallHeight:H,courseJoints:[J],door:source.door,
  policy:'Complete floor, walls, arch and closed double-sided leaf. Both ports require real neighbours. No runtime geometry, clipping, rotation, mirroring or tinting.',entries};
fs.writeFileSync(path.join(out,'catalog.json'),JSON.stringify(metadata,null,2)+'\n');
fs.writeFileSync(path.join(root,'scripts/wireframe_door_catalog.gd'),[
  '# Generated offline by tools/export_wireframe_doors.cjs. Complete connected door textures.',
  'extends RefCounted',`const CELL_PIXELS := ${PX}.0`,`const ANCHOR := Vector2(${anchor.join(', ')})`,
  'const TEXTURES := {',...Object.entries(entries).map(([dir,e])=>`\t"${dir}": preload("res://assets/dungeon/wireframe-doors/${e.file}"),`),'}',
  'const VARIANTS := {',...Object.entries(entries).map(([dir,e])=>`\t"${dir}": "${e.variant}",`),'}','',
].join('\n'));
console.log(`Exported four complete connected door textures, ${size.join('x')}, anchor ${anchor.join(',')}.`);
