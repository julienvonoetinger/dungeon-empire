// Approved compact v11 geometry, frozen masonry and independently painted leaf.
// Shared UV registration keeps tools and hardware at the accepted positions.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),M=require('./seal_masonry_finish.cjs'),Palette=require('./isometric_wall_palette.cjs');
const BASE='docs/reference/door-redesign/seal-v1',SELECTION=BASE+'/hero-fit-v13-malefic-leaf/selection.json';
const read=p=>JSON.parse(fs.readFileSync(path.join(P.ROOT,p)));
const selection=read(SELECTION);
for(const [p,h]of Object.entries(selection.files))if(P.hash(p)!==h)throw Error('Accepted door input changed: '+p);
const modelSource=read(selection.geometry);
if(JSON.stringify(modelSource.camera)!==JSON.stringify(P.camera))throw Error('Accepted door projection differs from kit');
const preparation=read(selection.preparation);
const mapping=read(selection.mapping);
const referenceFiles=[SELECTION,...Object.keys(selection.files)];
const inverses={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[1-y,x,z],west:([x,y,z])=>[y,1-x,z]};
const directionKind=n=>n[2]>.7?'top':Math.abs(n[0])>Math.abs(n[1])?'west':'north';
function geometry(d,open=false){
 if(!inverses[d])throw Error('Unknown seal direction '+d);
 let faces=structuredClone(modelSource.models[d].faces.slice(0,modelSource.door.faces.length));
 if(open){
  // The smooth leaf and its perimeter are last in the accepted model. Retain
  // the exact masonry indices so its paint registration and edge seeds match.
  const firstLeaf=faces.findIndex(f=>f.kind.startsWith('leaf'));
  if(firstLeaf<0||faces.slice(firstLeaf).some(f=>!f.kind.startsWith('leaf')))throw Error('Expected terminal leaf geometry');
  faces=faces.slice(0,firstLeaf);
 }
 return {id:'door-'+d+(open?'-open':''),faces,edges:faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind}))),curvedStrips:[]};
}
let imagePromise;
function image(){return imagePromise??=sharp(path.join(P.ROOT,selection.painting)).ensureAlpha().raw().toBuffer({resolveWithObject:true});}
let leafPromise;
function leafImage(){return leafPromise??=sharp(path.join(P.ROOT,selection.leafPainting||selection.painting)).ensureAlpha().raw().toBuffer({resolveWithObject:true});}
function sample(image,x,y){
 const {data,info}=image;x=Math.max(0,Math.min(info.width-1,x));y=Math.max(0,Math.min(info.height-1,y));
 const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,c=[0,0,0,0];
 for(const [u,v,w]of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]){const k=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[k+3]/255;c[3]+=a*w;for(let n=0;n<3;n++)c[n]+=data[k+n]*a*w;}
 if(c[3])for(let n=0;n<3;n++)c[n]/=c[3];return c;
}
async function render(d,m,frame){
 const source=await image(),leafSource=await leafImage(),maps=await M.prepare(m),r=P.raster(m,frame,4),raw=Buffer.alloc(r.width*r.height*4);
 const fit=preparation.fit,palette=preparation.palette,inv=inverses[d];
 const uv=p=>[(mapping.xOrigin+(p[0]-mapping.xCentre)*mapping.scale-fit.translation[0])/fit.uniformScale,(mapping.zOrigin-p[2]*mapping.scale-fit.translation[1])/fit.uniformScale];
 const faceSample=(p,isLeaf)=>sample(isLeaf?leafSource:source,...uv(p));
 const hingeSteel=(p,c)=>{const[x,y]=uv(p);return preparation.hardware.hingeRegions.some(([a,b,w,h])=>x>=a&&x<=a+w&&y>=b&&y<=b+h)&&Math.abs(c[0]-c[1])<12&&Math.abs(c[2]-c[1])<15;};
 const normals=m.faces.map(f=>P.normal(f.points)),localNormals=modelSource.door.faces.map(f=>P.normal(f.points));
 for(let k=0;k<r.owner.length;k++){
  const fi=r.owner[k];if(fi<0)continue;const f=m.faces[fi],world=Array.from(r.xyz.subarray(k*3,k*3+3)),p=inv(world),n=normals[fi];let rgb;
  const isLeaf=f.kind.startsWith('leaf');
  if(Math.abs(localNormals[fi][1])>.99){const c=faceSample(p,isLeaf);if(c[3]>.1){
   if(M.masonry(f.kind)&&!hingeSteel(p,c))rgb=Palette.grade(c,palette.source,palette.targets[directionKind(n)]).slice(0,3);
   else if(f.kind.startsWith('seal'))rgb=c.slice(0,3);
   else rgb=c.slice(0,3).map(v=>v*(directionKind(n)==='west'?.60:.79));
  }}
  if(!rgb&&maps[fi])rgb=M.sample(maps[fi],P.project(world));
  if(!rgb){const q=faceSample(p,isLeaf);rgb=q[3]>.1?q.slice(0,3).map(v=>v*.66):[24,29,43];}
  raw.set([...rgb.map(v=>Math.round(Math.max(0,Math.min(255,v)))),255],k*4);
 }
 const png=await sharp(raw,{raw:{width:r.width,height:r.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
 return {png,mesh:r};
}
module.exports={geometry,render,referenceFiles,span:modelSource.span,report:{geometry:selection.geometry,painting:selection.painting,leafPainting:selection.leafPainting,approval:SELECTION,fit:preparation.fit,hardware:preparation.hardware,stone:'unchanged v12 fronts and shared B sides/tops',leaf:'smooth interchangeable receiver; unified two-hinge iron lattice and violet seal; keyhole at unchanged contact'}};
