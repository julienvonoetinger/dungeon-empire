// Door revision calibrated against the real Vulpin. Preserve the accepted rail
// junctions; lift the arch without stretching its stones or changing the hero.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),W=require('./prepare_seal_junction_wireframe.cjs');
const BASE='docs/reference/door-redesign/seal-v1',DIR=BASE+'/hero-fit-v9',OUT=path.join(P.ROOT,DIR);
const old=JSON.parse(fs.readFileSync(path.join(P.ROOT,BASE,'wireframe-v6-clean-leaf/geometry.json')));
const rise=.55,step=P.H/2,span=old.span;
const rotations={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
function edges(m){m.edges=m.faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind})));return m;}
function band(points,lo,hi){
 let p=points;
 for(const [z,up]of [[lo,true],[hi,false]]){
  const out=[];for(let i=0;i<p.length;i++){
   const a=p[i],b=p[(i+1)%p.length],inside=q=>up?q[2]>=z-1e-9:q[2]<=z+1e-9;
   if(inside(a))out.push(a);if(inside(a)!==inside(b))out.push(P.lerp(a,b,(z-a[2])/(b[2]-a[2])));
  }p=out;
 }
 return p;
}
function build(){
 const faces=[];
 for(const f of old.door.faces){
  if(f.kind.startsWith('leaf'))continue;
  if(f.kind==='junction'){faces.push(structuredClone(f));continue;}
  const points=f.points.map(([x,y,z])=>[x,y,z<.01?z:z+rise]);
  // Only the two long inner jambs acquire matching masonry courses. The
  // recessed smooth wall and interchangeable wooden receiver stay unsplit.
  if(f.kind==='inner'&&Math.max(...points.map(p=>p[2]))-Math.min(...points.map(p=>p[2]))>.4){
   const cuts=[0,step,P.H,P.H+rise/3,P.H+rise*2/3,P.H+rise,2];
   for(let i=1;i<cuts.length;i++){const q=band(points,cuts[i-1],cuts[i]);if(q.length>=3&&Math.hypot(...P.normal(q))>.9)faces.push({...f,points:q});}
  }else faces.push({...f,points});
 }
 const door={id:'hero-scale-door',faces,edges:[],curvedStrips:[]};
 for(const [lo,hi]of [[-P.T/2,.17],[.83,1+P.T/2]])for(let row=0;row<3;row++)W.box(door,lo,hi,...span,P.H+row*rise/3,P.H+(row+1)*rise/3,'stone');
 const profile=old.leaf.profileXZ.map(([x,z])=>[x,z===0?0:z+rise]);
 const front=profile.map(([x,z])=>[x,.525,z]),back=profile.map(([x,z])=>[x,.475,z]);
 door.faces.push({kind:'leaf',points:front},{kind:'leaf',points:back.slice().reverse()});
 for(let i=0;i<profile.length;i++)door.faces.push({kind:'leaf-edge',points:[back[i],back[(i+1)%profile.length],front[(i+1)%profile.length],front[i]]});
 edges(door);
 const models={};
 for(const [direction,rotate]of Object.entries(rotations)){
  const m=structuredClone(door),stones=[];
  for(const x of [0,1])for(const [row,cuts]of [[0,1/6,1/2,5/6,1],[0,1/3,2/3,1]].entries())for(let i=1;i<cuts.length;i++)for(const [lo,hi]of [[0,span[0]],[span[1],1]]){
   const a=Math.max(lo,cuts[i-1]),b=Math.min(hi,cuts[i]);if(b-a<1e-9)continue;
   W.box(m,x-P.T/2,x+P.T/2,a,b,row*step,(row+1)*step,'wall');stones.push({x,row,min:a,max:b,length:b-a});
  }
  m.faces=m.faces.map(f=>({...f,points:f.points.map(rotate)}));models[direction]={...edges(m),id:direction,stones};
 }
 return {door,models,leaf:{...old.leaf,profileXZ:profile}};
}
async function main(){
 fs.mkdirSync(OUT,{recursive:true});const {door,models,leaf}=build();
 const hero=JSON.parse(fs.readFileSync(path.join(P.ROOT,'docs/reference/vulpin-review/v19-hurt-recoil/poses.json')));
 const heroHeight=hero.poses[0].bounds[1][2]*.85/(2.35*Math.sqrt(.5));
 const oldHeight=Math.max(...old.leaf.profileXZ.map(p=>p[1])),newHeight=Math.max(...leaf.profileXZ.map(p=>p[1]));
 assert(newHeight>heroHeight+.1,'Opening must clear standing ears');
 assert.equal(door.faces.filter(f=>f.kind==='leaf').length,2);
 assert.deepEqual(door.faces.filter(f=>f.kind==='junction'&&Math.max(...f.points.map(p=>p[2]))<=P.H),old.door.faces.filter(f=>f.kind==='junction'),'Existing wall junctions remain exact');
 const mapping={size:[1024,1536],scale:820,xOrigin:512,xCentre:.5,zOrigin:1400};
 const project=([x,y,z])=>[mapping.xOrigin+(x-.5)*mapping.scale,mapping.zOrigin-z*mapping.scale];
 const visible=P.visibleEdges(door,{x:[1,0,0],y:[0,0,-1],eye:[0,1,0]});
 const polygons=door.faces.slice().sort((a,b)=>a.points.reduce((s,p)=>s+p[1]/a.points.length,0)-b.points.reduce((s,p)=>s+p[1]/b.points.length,0));
 const shapes=polygons.map(f=>`<polygon points="${f.points.map(p=>project(p).join(',')).join(' ')}" fill="${f.kind.startsWith('leaf')?'#635465':f.kind.startsWith('seal')?'#75618c':'#414e63'}"/>`).join('');
 const lines=visible.map(e=>`<path d="M${project(e.a)}L${project(e.b)}"/>`).join('');
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1536">${shapes}<g fill="none" stroke="#ff00ff" stroke-width="1.5">${lines}</g></svg>`;
 fs.writeFileSync(path.join(OUT,'face-guide-magenta.svg'),svg);
 await sharp(Buffer.from(svg)).png().toFile(path.join(OUT,'face-guide-magenta.png'));
 const lock=project([.5,.525,.275]),hinges=[.24,.70].map(z=>project([.255,.525,z]));
 const hardware=`<g stroke="#ffc96b" fill="none" stroke-width="4"><circle cx="${lock[0]}" cy="${lock[1]}" r="16"/>${hinges.map(([x,y])=>`<rect x="${x-10}" y="${y-25}" width="20" height="50"/>`).join('')}</g>`;
 await sharp(Buffer.from(svg.replace('</svg>',hardware+'</svg>'))).png().toFile(path.join(OUT,'hardware-placement-guide.png'));
 for(const [d,m]of Object.entries(models))fs.writeFileSync(path.join(OUT,`wireframe-${d}.png`),await W.render(m,W.frame(m),3,{magenta:true}));
 const geometry={status:'hero-height-revision',camera:P.camera,span,door,models,leaf};
 const checks={rise,oldOpeningHeight:oldHeight,openingHeight:newHeight,standingHeroHeight:heroHeight,apexHeightMinusStandingHeroHeight:newHeight-heroHeight,wallHeight:P.H,smoothLeafPlanes:2,originalJunctionsUnchanged:true,guide:{mapping},hardware:{lock:{x:.5,z:.275,pixel:lock},hinges:hinges.map((pixel,i)=>({x:.255,z:[.24,.70][i],pixel})),textureOnly:true}};
 fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify(geometry,null,2));
 fs.writeFileSync(path.join(OUT,'checks.json'),JSON.stringify(checks,null,2));
 console.log(JSON.stringify({rise,oldOpeningHeight:oldHeight,newOpeningHeight:newHeight,heroHeight,apexHeightDifference:checks.apexHeightMinusStandingHeroHeight,faces:door.faces.length}));
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1});
module.exports={build,OUT,DIR,rotations,edges,band};
