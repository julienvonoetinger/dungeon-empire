// Offline structural review. Exact kit projection, one object turned in 3D.
// No painted image edits and no runtime asset changes.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const B=require('./prepare_mobile_reference.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT=path.join(ROOT,'docs/reference/mobile-light-review/wireframe-v1');
const {T,H,PX}=B,eye=[.18,.9,1],N=32;
const colors={wall:'#8b99ad',joint:'#536178',plate:'#6ddfe9',arm:'#6ddfe9',bowl:'#f0bd76'};
const add=(a,b)=>a.map((v,i)=>v+b[i]),sub=(a,b)=>a.map((v,i)=>v-b[i]);
const mul=(a,s)=>a.map(v=>v*s),dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const lerp=(a,b,t)=>add(a,mul(sub(b,a),t)),fmt=n=>+n.toFixed(6);
const digest=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,file))).digest('hex');

function build(orientation) {
  const faces=[],edges=[];
  // u follows the wall, v points out of the wall, z is world height.
  // Rotate this volume 90 degrees BEFORE projecting; never rotate a PNG.
  const transform=([u,v,z])=>orientation==='horizontal'?[.5+u,T/2+v,z]:[T/2+v,.5-u,z];
  const edge=(a,b,kind,transformPoints=true)=>edges.push({a:transformPoints?transform(a):a,b:transformPoints?transform(b):b,kind});
  const face=(points,kind,transformPoints=true)=>faces.push({points:transformPoints?points.map(transform):points,kind});
  function prism(profile,back,front,kind) {
    const a=profile.map(([u,z])=>[u,back,z]),b=profile.map(([u,z])=>[u,front,z]);
    face(a,kind);face(b,kind);
    for(let i=0;i<a.length;i++) {
      const j=(i+1)%a.length;
      face([a[i],a[j],b[j],b[i]],kind);
      edge(a[i],a[j],kind);edge(b[i],b[j],kind);edge(a[i],b[i],kind);
    }
  }
  const box=(u,U,v,V,z,Z,kind)=>prism([[u,z],[U,z],[U,Z],[u,Z]],v,V,kind);
  // Same thickness, height and brick joints as prepare_mobile_reference.wall().
  box(-.5,.5,-T,0,0,H,'wall');
  const wallAt=(s,c,z)=>orientation==='horizontal'?[s,c,z]:[c,s,z];
  const wallLine=(a,b,kind='joint')=>edge(a,b,kind,false);
  wallLine(wallAt(0,T/2,H/2),wallAt(1,T/2,H/2));
  for(const s of [1/3,2/3]) {
    wallLine(wallAt(s,T/2,H/2),wallAt(s,T/2,H));
    wallLine(wallAt(s,-T/2,H),wallAt(s,T/2,H));
  }
  for(const s of [1/6,1/2,5/6])wallLine(wallAt(s,T/2,0),wallAt(s,T/2,H/2));
  // Chamfered mounting plate; its rear plane TOUCHES the facade (v=0).
  const w=.052,z=.037,Z=.215,c=.012;
  prism([[-w+c,z],[w-c,z],[w,z+c],[w,Z-c],[w-c,Z],[-w+c,Z],[-w,Z-c],[-w,z+c]],0,.012,'plate');
  // Short physical arm, with a vertical support under the bowl.
  box(-.013,.013,.012,.113,.095,.119,'arm');
  box(-.016,.016,.097,.129,.111,.169,'arm');

  const centre=.113;
  const ring=(r,z)=>Array.from({length:N},(_,i)=>[r*Math.cos(2*Math.PI*i/N),centre+r*Math.sin(2*Math.PI*i/N),z]);
  const bottom=ring(.031,.16),outer=ring(.074,.246),rimLow=ring(.079,.246),rimHigh=ring(.079,.264);
  const innerHigh=ring(.060,.264),innerTop=ring(.060,.246),innerBottom=ring(.025,.187);
  const ringEdges=points=>points.forEach((p,i)=>edge(p,points[(i+1)%N],'bowl'));
  function strip(a,b,contour=true) {
    const quads=a.map((p,i)=>[p,a[(i+1)%N],b[(i+1)%N],b[i]]);
    quads.forEach(q=>face(q,'bowl'));
    if(!contour)return;
    const facing=quads.map(q=>{
      const p=q.map(transform);return dot(cross(sub(p[1],p[0]),sub(p[3],p[0])),eye);
    });
    for(let i=0;i<N;i++)if(facing[i]*facing[(i+N-1)%N]<0)edge(a[i],b[i],'bowl');
  }
  strip(bottom,outer);strip(outer,rimLow,false);strip(rimLow,rimHigh);
  strip(rimHigh,innerHigh,false);strip(innerHigh,innerTop);strip(innerTop,innerBottom);
  face(bottom,'bowl');face(innerBottom,'bowl');
  for(const ring of [bottom,rimLow,rimHigh,innerHigh,innerBottom])ringEdges(ring);
  return {orientation,faces,edges,attachment:transform([0,0,.126]),bowlCentre:transform([0,centre,.246])};
}

function visibleEdges(model) {
  const triangles=model.faces.flatMap(f=>f.points.slice(1,-1).map((p,i)=>{
    const a=f.points[0],e1=sub(p,a),e2=sub(f.points[i+2],a),h=cross(eye,e2),det=dot(e1,h);
    return {a,e1,e2,h,det};
  })).filter(t=>Math.abs(t.det)>1e-12);
  const hidden=p=>triangles.some(t=>{
    const inv=1/t.det,s=sub(p,t.a),u=inv*dot(s,t.h);
    if(u< -1e-9||u>1+1e-9)return false;
    const q=cross(s,t.e1),v=inv*dot(eye,q);
    return v>=-1e-9&&u+v<=1+1e-9&&inv*dot(t.e2,q)>1e-7;
  });
  const result=[],seen=new Set(),samples=96;
  for(const e of model.edges) {
    const key=[e.a,e.b].map(p=>p.map(fmt).join(',')).sort().join('|');
    if(seen.has(key))continue;seen.add(key);
    let start=0,old=hidden(lerp(e.a,e.b,.5/samples));
    const emit=(a,b)=>{if(b-a>1e-7)result.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
    for(let i=1;i<samples;i++) {
      const next=hidden(lerp(e.a,e.b,(i+.5)/samples));
      if(next===old)continue;
      let lo=(i-.5)/samples,hi=(i+.5)/samples;
      for(let j=0;j<22;j++){const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)emit(start,cut);start=cut;old=next;
    }
    if(!old)emit(start,1);
  }
  return result;
}
const projected=p=>B.project(p).map(v=>v/PX);
const svg=(width,height,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">${body}</svg>`;
const text=(x,y,size,label,fill='#e9eef7')=>`<text x="${x}" y="${y}" font-family="Segoe UI,Arial,sans-serif" font-size="${size}" fill="${fill}">${label}</text>`;
function strokes(edges,project,width=1.6,mono=false) {
  return edges.map(e=>{
    const a=project(e.a),b=project(e.b);
    return `<line x1="${fmt(a[0])}" y1="${fmt(a[1])}" x2="${fmt(b[0])}" y2="${fmt(b[1])}" stroke="${mono?'#f34cff':colors[e.kind]}" stroke-width="${e.kind==='joint'?width*.65:width}" stroke-linecap="round"/>`;
  }).join('');
}
function centred(edges,cx,cy,scale) {
  const points=edges.flatMap(e=>[e.a,e.b]).map(projected);
  const mid=[0,1].map(i=>(Math.min(...points.map(p=>p[i]))+Math.max(...points.map(p=>p[i])))/2);
  return p=>projected(p).map((v,i)=>[cx,cy][i]+(v-mid[i])*scale);
}
async function main() {
  const models=['horizontal','vertical'].map(orientation=>{
    const model=build(orientation);model.visibleEdges=visibleEdges(model);return model;
  });
  let board='<rect width="1160" height="1000" fill="#0b1019"/>';
  board+=text(32,40,25,'Torche murale — structure et raccord');
  board+=text(32,69,15,'Un seul volume, deux orientations. Projection identique aux murs du kit.','#aebace');
  const boxes=[[24,126,548,466],[588,126,548,466]];
  for(let i=0;i<2;i++) {
    const m=models[i],[x,y,w,h]=boxes[i],project=centred(m.visibleEdges,x+w/2,y+h/2,350);
    board+=text(x+14,108,19,i===0?'A — Mur horizontal':'B — Mur vertical');
    board+=`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="9" fill="#111a28"/>`;
    board+=strokes(m.visibleEdges,project,1.8);
    // A close view of the physical attachment, clipped to a clear inset.
    const detail=[x,638,w,238];
    const propEdges=m.visibleEdges.filter(e=>!['wall','joint'].includes(e.kind));
    const points2d=propEdges.flatMap(e=>[e.a,e.b]).map(projected);
    const ranges=[0,1].map(axis=>Math.max(...points2d.map(p=>p[axis]))-Math.min(...points2d.map(p=>p[axis])));
    const detailScale=Math.min(950,(w-36)/ranges[0],(detail[3]-28)/ranges[1]);
    const dp=centred(propEdges,detail[0]+w/2,detail[1]+detail[3]/2,detailScale);
    board+=text(x+14,620,16,'Détail de la fixation et du bras','#b8c5d8');
    board+=`<defs><clipPath id="detail${i}"><rect x="${detail[0]}" y="${detail[1]}" width="${w}" height="${detail[3]}" rx="9"/></clipPath></defs>`;
    board+=`<rect x="${detail[0]}" y="${detail[1]}" width="${w}" height="${detail[3]}" rx="9" fill="#111a28"/><g clip-path="url(#detail${i})">${strokes(m.visibleEdges,dp,1.9)}</g>`;
    const points=m.visibleEdges.flatMap(e=>[e.a,e.b]).map(B.project);
    const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-3);
    const hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+3),size=hi.map((v,i)=>v-lo[i]);
    const native=p=>B.project(p).map((v,i)=>v-lo[i]);
    const guide=svg(...size,strokes(m.visibleEdges,native,1.2,true));
    write(path.join(OUT,`guide-${m.orientation}.svg`),guide);
    write(path.join(OUT,`guide-${m.orientation}.png`),await sharp(Buffer.from(guide)).png().toBuffer());
    const nativeSVG=svg(...size,`<rect width="${size[0]}" height="${size[1]}" fill="#0b1019"/>${strokes(m.visibleEdges,native,1.2)}`);
    write(path.join(OUT,`context-${m.orientation}.png`),await sharp(Buffer.from(nativeSVG)).resize({width:Math.round(size[0]*.75)}).png().toBuffer());
  }
  board+=text(34,918,16,'Cyan : plaque et bras fixés au mur',colors.plate);
  board+=text(600,918,16,'Ambre : coupelle creuse et rebord',colors.bowl);
  board+=text(34,950,15,'Traits cachés retirés. Flamme et peinture viendront après validation de la structure.','#aebace');
  const document=svg(1160,1000,board);
  write(path.join(OUT,'comparison.svg'),document);
  write(path.join(OUT,'comparison.png'),await sharp(Buffer.from(document)).png().toBuffer());
  write(path.join(OUT,'geometry.json'),JSON.stringify({status:'wireframe awaiting design approval',
    generator:'tools/prepare_mobile_torch_wireframe.cjs',projection:{x:[1,0,-.18],y:[0,1,-.9],pixelsPerCell:PX},
    wall:{thickness:T,height:H,facadeCourses:2},
    torch:{plateWidth:.104,plateHeight:.178,plateDepth:.012,plateRearPlane:0,bowlCentreNormalDistance:.113,bowlOuterRadius:.079,bowlTop:.264},
    localCoordinates:'u along wall, v normal outward, z height; horizontal (0.5+u,T/2+v,z), vertical (T/2+v,0.5-u,z)',
    occlusion:'ray/triangle intersection along (.18,.9,1), sampled edge intervals with bisection; no rear/hidden lines',
    activeAtlasSha256:digest('assets/dungeon/mobile-kit/atlas-256.png'),
    models},null,2)+'\n');
  console.log(JSON.stringify(models.map(m=>({orientation:m.orientation,faces:m.faces.length,sourceEdges:m.edges.length,visibleEdges:m.visibleEdges.length}))));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
