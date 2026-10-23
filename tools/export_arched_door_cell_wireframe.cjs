// Offline, line-only proposal. No runtime geometry or image generation.
// node tools/export_arched_door_cell_wireframe.cjs [--inline absolute-preview.html]
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const wallSource = 'docs/reference/two-course-square-room.json';
const floorSource = 'docs/reference/floor-periodic-cell.json';
const source = JSON.parse(fs.readFileSync(path.join(root, wallSource), 'utf8'));
const floor = JSON.parse(fs.readFileSync(path.join(root, floorSource), 'utf8')).floor;
const T = source.wallThickness, H = source.models.after.height;
const J = source.models.after.courses[0], up = source.projection.heightUp;
const round = n => Number(n.toFixed(8));
const project = ([x,y,z]) => [x+up[0]*z,y+up[1]*z];
const lerp = (a,b,t) => a.map((n,i) => n+(b[i]-n)*t);
const cross = (a,b) => a[0]*b[1]-a[1]*b[0];

// The side walls themselves support the arch. Its springing faces occupy the
// full wall thickness, instead of adding separate jambs inside the passage.
const frameDepth=T, archThickness=T, spring=H;
const centerX=.5, innerRadius=.5-T, outerRadius=innerRadius+archThickness;
const y0=.5-frameDepth/2, y1=.5+frameDepth/2;
const a=centerX-innerRadius, b=centerX+innerRadius;
// Both working faces have the same shallow recess. The old thin leaf sat near
// the front only, leaving its rear hidden deep inside the arch in the west view.
const leafRecess=.025, leafFront=y1-leafRecess, leafBack=y0+leafRecess;
const stoneCount=7, subdivisionsPerStone=8, arcSteps=stoneCount*subdivisionsPerStone;
const point=(radius,angle,y)=>[centerX+radius*Math.cos(angle),y,spring+radius*Math.sin(angle)];
const profilePoint=(radius,angle)=>[centerX+radius*Math.cos(angle),spring+radius*Math.sin(angle)];
const top=H+outerRadius, doorTop=H+innerRadius;
const volumes=[];
function prism(profile,yMin,yMax,part) {
  const area=profile.reduce((sum,p,i)=>sum+cross(p,profile[(i+1)%profile.length]),0);
  volumes.push({type:'convex_profile_extruded_along_y',part,profileXZ:area>0?profile:[...profile].reverse(),yMin,yMax});
}
function box(x0,x1,minY,maxY,z0,z1,part) {
  prism([[x0,z0],[x1,z0],[x1,z1],[x0,z1]],minY,maxY,part);
}
box(0,T,0,1,0,H,'west-wall');
box(1-T,1,0,1,0,H,'east-wall');
// Each convex sector is an occluder. Tessellation boundaries are NOT drawn;
// only the seven actual voussoir joints appear on the masonry.
for(let i=0;i<arcSteps;i++) {
  const u=i*Math.PI/arcSteps,v=(i+1)*Math.PI/arcSteps;
  prism([profilePoint(innerRadius,u),profilePoint(outerRadius,u),profilePoint(outerRadius,v),profilePoint(innerRadius,v)],y0,y1,'arch');
}
const leafProfile=[[a,0],[b,0]];
for(let i=0;i<=arcSteps;i++)leafProfile.push(profilePoint(innerRadius,i*Math.PI/arcSteps));
prism(leafProfile,leafBack,leafFront,'closed-door');
const edges=[];
const edge=(p,q,kind='outline',role)=>edges.push({a:p,b:q,kind,...(role?{role}:{})});

for(const [lo,hi] of [[0,T],[1-T,1]]) {
  for(const z of [0,J,H]) {
    const kind=z===J?'joint':'outline';
    for(const x of [lo,hi]) {
      if(z===H) {
        // These two top edges are internal at the arch's wall-top bearings.
        edge([x,0,z],[x,y0,z],kind);
        edge([x,y1,z],[x,1,z],kind);
      } else edge([x,0,z],[x,1,z],kind);
    }
    for(const y of [0,1])edge([lo,y,z],[hi,y,z],kind);
  }
  for(const x of [lo,hi])for(const y of [0,1])edge([x,y,0],[x,y,H]);
  for(const y of [1.6/6,3.5/6]) {
    edge([lo,y,H],[hi,y,H],'joint');
    for(const x of [lo,hi])edge([x,y,J],[x,y,H],'joint');
  }
  for(const y of [.7/6,2.6/6,4.5/6])for(const x of [lo,hi])
    edge([x,y,0],[x,y,J],'joint');
}

// No added jambs. The arch rises directly from the west/east wall tops.
for(const y of [y0,y1])for(const radius of [innerRadius,outerRadius]) {
  for(let i=0;i<arcSteps;i++)edge(point(radius,i*Math.PI/arcSteps,y),point(radius,(i+1)*Math.PI/arcSteps,y),'frame');
}
for(let i=0;i<=stoneCount;i++) {
  const angle=i*Math.PI/stoneCount;
  for(const y of [y0,y1])edge(point(innerRadius,angle,y),point(outerRadius,angle,y),'joint');
  // At each springing, these depth lines lie inside the smooth wall/arch
  // continuation. Retain front/back masonry seams, not a false exposed foot.
  if(i>0 && i<stoneCount)
    for(const radius of [innerRadius,outerRadius])edge(point(radius,angle,y0),point(radius,angle,y1),'joint');
}
// A curved extrusion also has an apparent contour where its surface turns
// away from the camera. Include the actual tessellation edge at that tangent;
// front/back arcs alone leave the left outer silhouette visibly unclosed.
for(let i=1;i<arcSteps;i++) {
  const before=(i-.5)*Math.PI/arcSteps,after=(i+.5)*Math.PI/arcSteps;
  const facing=angle=>-up[0]*Math.cos(angle)+Math.sin(angle);
  if(facing(before)*facing(after)<0) {
    for(const radius of [innerRadius,outerRadius])
      edge(point(radius,i*Math.PI/arcSteps,y0),point(radius,i*Math.PI/arcSteps,y1),'frame','apparent-contour');
  }
}

// Same arched profile for the wood leaf, recessed behind the frame.
for(const y of [leafBack,leafFront]) {
  for(let i=0;i<leafProfile.length;i++) {
    const p=leafProfile[i],q=leafProfile[(i+1)%leafProfile.length];
    edge([p[0],y,p[1]],[q[0],y,q[1]],'door');
  }
}
for(const x of [a,b])edge([x,leafBack,0],[x,leafFront,0],'door');
function leafHeight(x) {
  // Intersect with the actual tessellated profile, not an independently drawn
  // curve: the plank ends therefore meet the exact door boundary.
  for(let i=2;i<leafProfile.length-1;i++) {
    const p=leafProfile[i],q=leafProfile[i+1];
    if(x<=p[0]+1e-9 && x>=q[0]-1e-9)return p[1]+(q[1]-p[1])*(x-p[0])/(q[0]-p[0]);
  }
  return spring;
}
const bands=[{x0:a+.012,x1:a+(b-a)*.43,z:.30,half:.013},
             {x0:a+.012,x1:b-.012,z:.055,half:.013}];
const handle={x:b-.085,z:.23,radius:.028};
// One physical leaf, complete on BOTH sides. Keep the handles on the same
// spindle and the bands at the same physical x/z positions, not camera-facing.
function leafFace(face,y) {
  for(let i=1;i<5;i++) {
    const x=a+(b-a)*i/5;
    let start=0;
    for(const band of [...bands].sort((p,q)=>p.z-q.z)) {
      if(x>band.x0 && x<band.x1) {
        edge([x,y,start],[x,y,band.z-band.half],'detail',`${face}-plank-seam`);
        start=band.z+band.half;
      }
    }
    edge([x,y,start],[x,y,leafHeight(x)],'detail',`${face}-plank-seam`);
  }
  for(const band of bands) {
    const contour=[[band.x0,band.z-band.half],[band.x1,band.z-band.half],
                   [band.x1,band.z+band.half],[band.x0,band.z+band.half]];
    for(let i=0;i<4;i++) {
      const p=contour[i],q=contour[(i+1)%4];
      edge([p[0],y,p[1]],[q[0],y,q[1]],'detail',`${face}-band`);
    }
  }
  for(let i=0;i<40;i++) {
    const p=t=>[handle.x+handle.radius*Math.cos(t),y,handle.z+handle.radius*Math.sin(t)];
    edge(p(i*Math.PI/20),p((i+1)*Math.PI/20),'detail',`${face}-handle`);
  }
}
leafFace('front',leafFront+1e-6);
leafFace('rear',leafBack-1e-6);

// Unchanged normalized catalogue paving, on the ground at z=0.
const fw=floor.bounds[2]-floor.bounds[0],fh=floor.bounds[3]-floor.bounds[1];
let y=0;
edge([T,0,0],[1-T,0,0],'floor');
for(let r=0;r<floor.rowHeights.length;r++) {
  const nextY=y+floor.rowHeights[r]/fh;
  edge([T,nextY,0],[1-T,nextY,0],'floor');
  let x=0;
  for(const width of floor.rowWidths[r].slice(0,-1)) {
    x+=width/fw;
    if(x>T && x<1-T)edge([x,y,0],[x,nextY,0],'floor');
  }
  y=nextY;
}

// Convex-prism ray clipping, in world coordinates before projection. A curved
// opening is not approximated by a solid bounding box, which would hide it.
const direction=[-up[0],-up[1],1];
function hidden(p) {
  return volumes.some(volume=>{
    let enter=Math.max(0,(volume.yMin-p[1])/direction[1]);
    let exit=(volume.yMax-p[1])/direction[1];
    const profile=volume.profileXZ;
    for(let i=0;i<profile.length;i++) {
      const a=profile[i],b=profile[(i+1)%profile.length];
      const e=[b[0]-a[0],b[1]-a[1]];
      const value=cross(e,[p[0]-a[0],p[2]-a[1]]);
      const slope=cross(e,[direction[0],direction[2]]);
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
  id:'door-arch-cell-west-east-wireframe-v3-double-sided',status:'proposal_awaiting_user_review',
  generator:'tools/export_arched_door_cell_wireframe.cjs',wallSource,floorSource,
  projection:source.projection,cell:[1,1],walls:['west','east'],openSides:['north','south'],
  wallThickness:T,wallHeight:H,courseJoints:[J],
  frame:{shape:'semicircular-arch',support:'directly on the existing side walls, no additional jambs',
    centerY:.5,depth:frameDepth,archThickness,springHeight:spring,
    bearings:[{bounds:[0,y0,T,y1],z:H},{bounds:[1-T,y0,1,y1],z:H}],
    innerRadius,outerRadius,top,doorTop,stoneCount,subdivisionsPerStone,clearWidth:b-a},
  door:{state:'closed',leafCount:1,doubleSided:true,profileXZ:leafProfile,yMin:leafBack,yMax:leafFront,
    thickness:leafFront-leafBack,frontRecess:leafRecess,rearRecess:leafRecess,
    hardwareFaces:['front','rear'],handle,bands},
  floor:{z:0,motif:'Unchanged normalized 19-slab pattern'},
  policy:'Standalone line-only proposal. The arch springs directly from the existing side walls across their full thickness; there are no added jambs inside the passage. Exact proportions await visual review. Side walls remain two courses. No torches or Godot changes.',
  occludingVolumes:volumes,sourceEdges:edges,visibleEdges:visible,paths,viewport,
};
const scale=600,ox=-viewport.min[0]*scale,oy=-viewport.min[1]*scale;
const width=round((viewport.max[0]-viewport.min[0])*scale),height=round((viewport.max[1]-viewport.min[1])*scale);
const styles={floor:['#8794a3',1.2],joint:['#526171',1.4],outline:['#1c2a3a',2],frame:['#1c2a3a',2],door:['#1c2a3a',1.8],detail:['#526171',1.2]};
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
<title id="title">Case porte voûtée — murs à gauche et à droite</title>
<desc id="desc">Case carrée. L'arc à sept pierres repose directement sur les murs latéraux à deux assises, sans montants ajoutés dans le passage. Porte fermée, sans torches, projection commune.</desc>
<rect width="100%" height="100%" fill="white"/>
<g transform="translate(${ox} ${oy}) scale(${scale})" fill="none" stroke-linecap="round" stroke-linejoin="round">
${Object.entries(paths).map(([kind,d])=>`<path d="${d}" stroke="${styles[kind][0]}" stroke-width="${styles[kind][1]}" vector-effect="non-scaling-stroke"/>`).join('\n')}
</g></svg>\n`;
const out=path.join(root,'docs/reference/door-arch-cell-west-east-wireframe');
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
