// Design review only: two nested arches, with masonry beside AND above the wood.
// The original main arch uses the same source coordinates/expansion as the kit.
// Lines plus a flat schematic fill for the solid smooth wall; no textures or
// runtime assets are painted/exported by this design-review script.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const {writeGeneratedFile: write} = require('./write_generated_file.cjs');
const ROOT = path.resolve(__dirname, '..');
const legacyThreeRings = process.argv.includes('--legacy-three-rings');
const legacyJoined = process.argv.includes('--legacy-joined');
const legacyOpenGap = process.argv.includes('--legacy-open-gap');
const legacyFlushWall = process.argv.includes('--legacy-flush-wall');
const legacyDetailedLeaf = process.argv.includes('--legacy-detailed-leaf');
const revision = legacyThreeRings ? 3 : legacyJoined ? 4 : legacyOpenGap ? 5 : legacyFlushWall ? 6 : legacyDetailedLeaf ? 7 : 8;
const OUT = path.join(ROOT, `docs/reference/mobile-door-frame-review/wireframe-v${revision}`);
const sourcePath = 'docs/reference/door-arch-cell-west-east-wireframe.json';
const source = JSON.parse(fs.readFileSync(path.join(ROOT, sourcePath)));
const T = 1 / 6, H = 1.88 / 6, N = 56;
const mainInner = source.frame.innerRadius + T / 2;
const mainOuter = source.frame.outerRadius + T / 2;
// Arch/infill proportions approved in v7; v8 only removes leaf detail guides.
// Two distinct arches separated by a SOLID SMOOTH WALL. Its surface has no
// brick joints; do not turn it into empty space or merge the two arch rings.
const smallInner = .27, smallOuter = legacyJoined ? mainInner : .35, woodRadius = .26;
const front = .5 + T / 2, back = .5 - T / 2;
const wallDepth = revision>=7 ? T*.8 : T;
const wallFront = .5+wallDepth/2, wallBack = .5-wallDepth/2;
const color = {main:'#f1f4fa', masonry:'#62d7e9', wood:'#efbc76', smooth:'#535c6c', recess:'#9faabc', context:'#77849a', floor:'#465368'};
const edges = [], volumes = [];
const fmt = n => +n.toFixed(6);
const lerp = (a,b,t) => a.map((v,i)=>v+(b[i]-v)*t);
const cross = (a,b) => a[0]*b[1]-a[1]*b[0];
const arc = (r,a,y=front) => [.5+r*Math.cos(a),y,H+r*Math.sin(a)];
const line = (a,b,kind='masonry',detail=false) => edges.push({a,b,kind,detail});
const vol = (profileXZ,yMin=back,yMax=front,part='masonry') => volumes.push({profileXZ,yMin,yMax,part});
const faceLine = (a,b,kind='masonry',detail=false) => {
  for(const y of [back,front])line([a[0],y,a[1]],[b[0],y,b[1]],kind,detail);
};
function curve(r,kind,y) {
  for(let i=0;i<N;i++)line(arc(r,i*Math.PI/N,y),arc(r,(i+1)*Math.PI/N,y),kind);
}
function ring(lo,hi,kind,stones) {
  for(let i=0;i<N;i++) {
    const a=i*Math.PI/N,b=(i+1)*Math.PI/N;
    vol([arc(lo,a),arc(hi,a),arc(hi,b),arc(lo,b)].map(p=>[p[0],p[2]]),back,front,kind);
  }
  for(const y of [back,front]) {
    curve(lo,kind,y);
    if(hi < mainInner - 1e-8)curve(hi,kind,y); // Shared boundary already belongs to the main arch.
    for(let i=0;i<=stones;i++)line(arc(lo,i*Math.PI/stones,y),arc(hi,i*Math.PI/stones,y),kind,true);
  }
  for(const r of [lo,hi]) {
    for(const a of [0,Math.PI])line(arc(r,a,back),arc(r,a,front),kind);
    // Exact polygonal silhouette, as in the current offline door exporter.
    const facing=a=>.18*Math.cos(a)/r+Math.sin(a)/r;
    for(let i=1;i<N;i++)if(facing((i-.5)*Math.PI/N)*facing((i+.5)*Math.PI/N)<0)
      line(arc(r,i*Math.PI/N,back),arc(r,i*Math.PI/N,front),kind);
  }
}

// Existing main arch: reuse its original 56 expanded prisms and source lines.
const expand=([x,y,z])=>{
  const dx=x-.5,dz=z-H,r=Math.hypot(dx,dz),s=(r+T/2)/r;
  return [.5+dx*s,y,H+dz*s];
};
for(const v of source.occludingVolumes.filter(v=>v.part==='arch'))
  vol(v.profileXZ.map(([x,z])=>{const p=expand([x,0,z]);return [p[0],p[2]];}),v.yMin,v.yMax,'main');
for(const e of source.sourceEdges.filter(e=>(e.kind==='frame'||e.kind==='joint'&&Math.min(e.a[2],e.b[2])>=H-1e-8&&[e.a,e.b].every(p=>p[1]>=back-1e-8&&p[1]<=front+1e-8))&&e.role!=='apparent-contour'))
  line(expand(e.a),expand(e.b),'main',e.kind==='joint');
for(const r of [mainInner,mainOuter]) {
  for(const a of [0,Math.PI])line(arc(r,a,back),arc(r,a,front),'main');
  const facing=a=>.18*Math.cos(a)/r+Math.sin(a)/r;
  for(let i=1;i<N;i++)if(facing((i-.5)*Math.PI/N)*facing((i+.5)*Math.PI/N)<0)
    line(arc(r,i*Math.PI/N,back),arc(r,i*Math.PI/N,front),'main');
}

// The small arch has its own ring; the intervening wall is continuous and plain.
ring(smallInner,smallOuter,'masonry',7);
// Solid infill has volume for occlusion, but no construction/brick lines in v6.
if(legacyThreeRings || revision>=6)for(let i=0;i<N;i++) {
  const a=i*Math.PI/N,b=(i+1)*Math.PI/N;
  vol([arc(smallOuter,a),arc(mainInner,a),arc(mainInner,b),arc(smallOuter,b)].map(p=>[p[0],p[2]]),wallBack,wallFront,revision>=6?'smooth-wall':'masonry');
}
if(legacyThreeRings)for(const y of [back,front])for(let i=1;i<6;i++)
  line(arc(smallOuter,i*Math.PI/6,y),arc(mainInner,i*Math.PI/6,y),'masonry',true);
for(const sign of [-1,1]) {
  const jambOuter=revision>=5?smallOuter:mainInner;
  const lo=.5+(sign<0?-jambOuter:smallInner),hi=.5+(sign<0?-smallInner:jambOuter);
  vol([[lo,0],[hi,0],[hi,H],[lo,H]]);
  faceLine([lo,0],[hi,0]);faceLine([lo,H],[hi,H]);
  for(const x of legacyThreeRings ? [lo,hi,.5+sign*smallOuter] : [lo,hi])faceLine([x,0],[x,H]);
  faceLine([lo,H/2],[hi,H/2],'masonry',true);
  for(const x of [lo,hi])for(const z of [0,H/2,H])line([x,back,z],[x,front,z],'masonry',z===H/2);
}
if(revision>=6)for(const sign of [-1,1]) {
  const lo=.5+(sign<0?-mainInner:smallOuter),hi=.5+(sign<0?-smallOuter:mainInner);
  vol([[lo,0],[hi,0],[hi,H],[lo,H]],wallBack,wallFront,'smooth-wall');
  // The smooth wall continues around the crown without a horizontal seam.
  for(const y of [wallBack,wallFront]) {
    line([lo,y,0],[hi,y,0],'context');
    line([.5+sign*mainInner,y,0],[.5+sign*mainInner,y,H],'context');
  }
}
if(revision>=7) {
  // Contacts at the actual recessed plane show depth, never brick joints.
  for(const y of [wallBack,wallFront])for(const r of [mainInner,smallOuter]) {
    for(let i=0;i<N;i++)line(arc(r,i*Math.PI/N,y),arc(r,(i+1)*Math.PI/N,y),'recess',true);
    for(const sign of [-1,1])line([.5+sign*r,y,0],[.5+sign*r,y,H],'recess',true);
  }
}

// Small inset wooden leaf: its own reduced semicircular crown, not a wide crown
// clipped only on the sides. Minimal lines suffice for this geometry review.
const doorBack=source.door.yMin,doorFront=source.door.yMax;
const woodProfile=[[.5-woodRadius,0],[.5+woodRadius,0],...Array.from({length:N+1},(_,i)=>{
  const p=arc(woodRadius,i*Math.PI/N);return [p[0],p[2]];
})];
vol(woodProfile,doorBack,doorFront,'wood');
for(const y of [doorBack,doorFront]) {
  for(let i=0;i<woodProfile.length;i++) {
    const a=woodProfile[i],b=woodProfile[(i+1)%woodProfile.length];
    line([a[0],y,a[1]],[b[0],y,b[1]],'wood');
  }
  // Planks and hardware are artwork choices, not structural constraints.
  // Preserve them only when reproducing the historical detailed-leaf review.
  if(revision<8)for(const dx of [-.156,-.052,.052,.156]) {
    const top=H+Math.sqrt(woodRadius**2-dx**2);
    line([.5+dx,y,.015],[.5+dx,y,top-.005],'wood',true);
  }
  if(revision<8)for(let i=0;i<32;i++) {
    const at=a=>[.5+.16+.022*Math.cos(a),y,.215+.022*Math.sin(a)];
    line(at(i*Math.PI/16),at((i+1)*Math.PI/16),'wood',true);
  }
}

// Straight corridor rails, with the unchanged two facade courses.
const railStart=.12,railEnd=.98;
for(const center of [0,1]) {
  const lo=center-T/2,hi=center+T/2;
  vol([[lo,0],[hi,0],[hi,H],[lo,H]],railStart,railEnd,'context');
  for(const y of [railStart,railEnd]) {
    for(const z of [0,H/2,H])line([lo,y,z],[hi,y,z],'context',z===H/2);
    for(const x of [lo,hi])line([x,y,0],[x,y,H],'context');
  }
  for(const x of [lo,hi])for(const z of [0,H/2,H])line([x,railStart,z],[x,railEnd,z],'context',z===H/2);
  for(const y of [.28,.70]) {
    line([lo,y,H],[hi,y,H],'context',true);
    for(const x of [lo,hi])line([x,y,H/2],[x,y,H],'context',true);
  }
  for(const y of [.18,.54,.87])for(const x of [lo,hi])line([x,y,0],[x,y,H/2],'context',true);
}
for(const y of [railStart,1/3,2/3,railEnd])line([T/2,y,0],[1-T/2,y,0],'floor',true);
for(const [y,Y,x] of [[railStart,1/3,.44],[1/3,2/3,.62],[2/3,railEnd,.37]])line([x,y,0],[x,Y,0],'floor',true);

// Hidden-line removal by ray/convex-prism intersection. Same projection and
// clipping convention as mobile_special_parts; coplanar edges remain visible.
function hidden(p) {
  const ray=[.18,.9,1];
  return volumes.some(v=>{
    const a=(v.yMin-p[1])/ray[1],b=(v.yMax-p[1])/ray[1];
    let enter=Math.max(0,Math.min(a,b)),exit=Math.max(a,b);
    for(let i=0;i<v.profileXZ.length;i++) {
      const a=v.profileXZ[i],b=v.profileXZ[(i+1)%v.profileXZ.length],e=[b[0]-a[0],b[1]-a[1]];
      const value=cross(e,[p[0]-a[0],p[2]-a[1]]),slope=cross(e,[ray[0],ray[2]]);
      if(Math.abs(slope)<1e-12){if(value<=1e-10)return false;}
      else if(slope>0)enter=Math.max(enter,-value/slope);else exit=Math.min(exit,-value/slope);
      if(exit<=Math.max(enter,1e-8)+1e-9)return false;
    }
    return exit>Math.max(enter,1e-8)+1e-9;
  });
}
function visibleEdges() {
  const result=[],seen=new Set(),steps=120;
  for(const e of edges) {
    const key=[e.a,e.b].map(p=>p.map(fmt).join(',')).sort().join('|');
    if(seen.has(key))continue;seen.add(key);
    let start=0,old=hidden(lerp(e.a,e.b,.5/steps));
    const add=(a,b)=>{if(b-a>1e-7)result.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
    for(let k=1;k<steps;k++) {
      const next=hidden(lerp(e.a,e.b,(k+.5)/steps));if(next===old)continue;
      let lo=(k-.5)/steps,hi=(k+.5)/steps;
      for(let j=0;j<24;j++){const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)add(start,cut);start=cut;old=next;
    }
    if(!old)add(start,1);
  }
  return result;
}
const projected=p=>[p[0]-.18*p[2],p[1]-.9*p[2]];
const text=(x,y,size,str,fill='#f1f4fa',anchor='start')=>`<text x="${x}" y="${y}" fill="${fill}" font-size="${size}" text-anchor="${anchor}" font-family="Segoe UI,Arial,sans-serif">${str}</text>`;
function strokes(items,project) {
  return items.map(e=>{
    const a=project(e.a),b=project(e.b);
    return `<line x1="${fmt(a[0])}" y1="${fmt(a[1])}" x2="${fmt(b[0])}" y2="${fmt(b[1])}" stroke="${color[e.kind]}" stroke-width="${e.detail?1.25:1.8}" stroke-linecap="round"/>`;
  }).join('');
}
function fit(items,box) {
  const points=items.flatMap(e=>[projected(e.a),projected(e.b)]);
  const lo=[0,1].map(i=>Math.min(...points.map(p=>p[i]))),hi=[0,1].map(i=>Math.max(...points.map(p=>p[i])));
  const scale=Math.min(box[2]/(hi[0]-lo[0]),box[3]/(hi[1]-lo[1]));
  return p=>projected(p).map((v,i)=>box[i]+box[i+2]/2+(v-(lo[i]+hi[i])/2)*scale);
}
function smoothWallFill(project,maskId,occlude=false) {
  if(revision<6)return '';
  const profile=r=>[[.5-r,wallFront,0],[.5+r,wallFront,0],...Array.from({length:N+1},(_,i)=>arc(r,i*Math.PI/N,wallFront))];
  const polygon=points=>'M'+points.map(project).map(p=>p.map(fmt).join(',')).join('L')+'Z';
  const shape=polygon(profile(mainInner))+polygon(profile(smallOuter));
  let mask='';
  if(occlude) {
    // Arches as well as corridor walls occlude the recessed surface. Clip
    // occluding volumes to the part physically in front of the wall plane.
    const covers=volumes.filter(v=>v.part!=='smooth-wall'&&v.yMax>wallFront+1e-8).map(v=>{
      const a=v.profileXZ.map(([x,z])=>[x,Math.max(wallFront,v.yMin),z]);
      const b=v.profileXZ.map(([x,z])=>[x,v.yMax,z]);
      return [a,b,...a.map((p,i)=>[p,a[(i+1)%a.length],b[(i+1)%b.length],b[i]])]
        .map(points=>`<path d="${polygon(points)}" fill="black"/>`).join('');
    }).join('');
    mask=`<defs><mask id="${maskId}" maskUnits="userSpaceOnUse" x="0" y="0" width="1240" height="730"><rect width="1240" height="730" fill="white"/>${covers}</mask></defs>`;
  }
  return mask+`<path d="${shape}" fill="${color.smooth}" fill-rule="evenodd"${occlude?` mask="url(#${maskId})"`:''}/>`;
}
async function main() {
  const visible=visibleEdges();
  const frontEdges=edges.filter(e=>!['context','floor'].includes(e.kind)&&[e.a,e.b].every(p=>Math.abs(p[1]-(e.kind==='wood'?doorFront:front))<1e-7));
  // Front elevation context: supports only; no misleading projection of rails.
  for(const c of [0,1]) {
    const lo=c-T/2,hi=c+T/2;
    for(const z of [0,H/2,H])frontEdges.push({a:[lo,front,z],b:[hi,front,z],kind:'context',detail:z===H/2});
    for(const x of [lo,hi])frontEdges.push({a:[x,front,0],b:[x,front,H],kind:'context'});
  }
  let body=`<rect width="1240" height="730" fill="#0b1019"/>`;
  body+=text(38,44,26,'Porte — proposition de structure');
  body+=text(38,75,16,revision>=8 ? 'Vantail lisse : contour seul · texture libre · deux arches et mur en retrait conservés' : legacyThreeRings ? 'Grande arche conservée · petite arche intérieure · pierre sur les côtés et au-dessus du bois' : legacyJoined ? 'Deux arches directement jointives · grande arche conservée · bois réduit' : legacyOpenGap ? 'Deux arches séparées par un espace · aucune brique dans cet espace' : revision>=7 ? 'Mur lisse 20 % moins épais · léger retrait sur les deux faces · deux arches conservées' : 'Deux arches distinctes · un mur lisse et plein entre elles · aucun joint dans ce mur','#b7c2d4');
  const legend=revision>=6?[[38,'main','Grande arche conservée'],[352,'masonry','Petite arche'],[625,'smooth',revision>=7?'Mur lisse en retrait':'Mur lisse plein'],[955,'wood',revision>=8?'Vantail lisse':'Porte en bois réduite']]:[[38,'main','Arche principale existante'],[446,'masonry',legacyThreeRings?'Nouvelle maçonnerie + petite arche':legacyJoined?'Petite arche, directement contre la grande':'Petite arche distincte'],[955,'wood','Porte en bois réduite']];
  for(const [x,key,label] of legend) {
    body+=key==='smooth'?`<rect x="${x}" y="99" width="24" height="15" fill="${color[key]}"/>`:`<line x1="${x}" y1="107" x2="${x+24}" y2="107" stroke="${color[key]}" stroke-width="3"/>`;
    body+=text(x+34,113,14,label,key==='smooth'?'#b7c2d4':color[key]);
  }
  body+=text(305,158,18,'Vue de face — structure','#b7c2d4','middle');
  body+=text(925,158,18,'Perspective du jeu — dans le couloir','#b7c2d4','middle');
  body+=`<line x1="620" y1="145" x2="620" y2="662" stroke="#263142"/>`;
  const frontProject=p=>[305+(p[0]-.5)*440,602-p[2]*440];
  const gameProject=fit(visible,[662,190,532,450]);
  body+=smoothWallFill(frontProject,'front-fill')+strokes(frontEdges,frontProject);
  body+=smoothWallFill(gameProject,'game-fill',true)+strokes(visible,gameProject);
  body+=text(305,657,15,legacyThreeRings?'La zone entre les deux arches est pleine de pierre.':legacyJoined?'Deux arches · aucune rangée intermédiaire':legacyOpenGap?'Un espace libre sépare les deux arches.':'En gris : mur plein, lisse, sans joints de briques.','#b7c2d4','middle');
  body+=text(925,657,15,revision>=8?'Aucun joint de planche ni accessoire imposé.':revision>=7?'Les rebords visibles montrent le retrait du mur.':'Lignes visibles uniquement · même projection que le kit','#b7c2d4','middle');
  body+=text(38,705,14,'Wireframe de validation — proportions proposées, sans textures ni modification du kit actif.','#8f9db3');
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1240" height="730" viewBox="0 0 1240 730">${body}</svg>`;
  write(path.join(OUT,'wireframe.svg'),svg);
  write(path.join(OUT,'wireframe.png'),await sharp(Buffer.from(svg)).png().toBuffer());
  const projection=fit(visible,[24,24,552,552]);
  const single=`<svg xmlns="http://www.w3.org/2000/svg" width="600" height="600"><rect width="600" height="600" fill="#0b1019"/>${smoothWallFill(projection,'single-fill',true)}${strokes(visible,projection)}</svg>`;
  write(path.join(OUT,'perspective.png'),await sharp(Buffer.from(single)).png().toBuffer());
  const digest=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,p))).digest('hex');
  write(path.join(OUT,'geometry.json'),JSON.stringify({revision,status:revision<7?'superseded-wireframe':'wireframe-awaiting-user-design-approval',
    originalArch:{source:sourcePath,sourceSha256:digest(sourcePath),innerRadius:mainInner,outerRadius:mainOuter,springHeight:H,expansion:T/2,unchanged:true},
    proposal:{smallInnerRadius:smallInner,smallOuterRadius:smallOuter,woodRadius,springHeight:H,depth:T,woodInset:front-doorFront,intermediateBrickBand:legacyThreeRings,openGap:revision===5,smoothSolidWall:revision>=6,separationWidth:mainInner-smallOuter,wallDepth,wallBack,wallFront,recessPerSide:front-wallFront,schematicFill:revision>=6?color.smooth:null},
    ...(revision>=8?{leafSurface:{structuralOutlineOnly:true,internalDetailGuides:false,planksAndHardware:'optional artwork; not geometry constraints'}}:{}),
    projection:{x:[1,0,-.18],y:[0,1,-.9]},volumes,sourceEdges:edges,visibleEdges:visible,
    activeAtlasSha256:digest('assets/dungeon/mobile-kit/atlas-256.png'),
    generator:'tools/prepare_mobile_nested_arch_wireframe.cjs'},null,2)+'\n');
  console.log(JSON.stringify({output:path.relative(ROOT,OUT),volumes:volumes.length,sourceEdges:edges.length,visibleEdges:visible.length}));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
