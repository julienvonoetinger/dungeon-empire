// Selected source artwork projected onto existing B stone faces offline.
// Geometric masks retain the clean host's joints, silhouette and all cell edges.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),B=require('./isometric_floor_variants.cjs'),Palette=require('./isometric_wall_palette.cjs');
const ROOT='docs/reference/isometric-floor-damage-review/v1',OUT=ROOT+'/integration';
const read=p=>JSON.parse(fs.readFileSync(path.join(P.ROOT,p),'utf8').replace(/^\uFEFF/,''));
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const save=(file,data)=>writeGeneratedFile(path.join(P.ROOT,OUT,file),data);
const json=(file,data)=>save(file,JSON.stringify(data,null,2)+'\n');
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const smooth=v=>{v=clamp(v);return v*v*(3-2*v);};
// Source quadrilaterals: top, right, bottom, left on a painted stone face.
// Target rectangles are exact complete interior stones from B.geometry().
const designs=[
 {key:'a',source:'a-fissures-courtes',base:1,patches:[
  {rect:[.53,.84,.16,.50],quad:[[1101,150],[1269,242],[1109,331],[947,241]]},
  {rect:[.28,.62,.50,.84],quad:[[869,477],[1074,590],[932,673],[718,559]]}]},
 {key:'b',source:'b-fracture-ramifiee',base:2,patches:[
  {rect:[.16,.66,.16,.50],quad:[[1091,381],[1249,469],[1067,562],[916,482]]},
  {rect:[.47,.92,.50,.84],quad:[[1287,496],[1405,558],[1226,664],[1098,597]]}]},
 {key:'c',source:'c-veine-corrompue',base:3,patches:[
  {rect:[.44,.72,.16,.84],quad:[[885,247],[1052,342],[815,480],[612,368]]}]},
 {key:'d',source:'d-racines-corrompues',base:4,patches:[
  {joint:true,rect:[.72,.90,.36,.64],parent:1},
  {rect:[.28,.84,.38,.62],quad:[[1091,360],[1302,470],[1066,588],[886,484]]},
  {rect:[.28,.50,.62,.84],quad:[[1286,498],[1403,560],[1225,664],[1099,598]]}]}
];
function sample(image,x,y){
 const {data,info}=image; x=clamp(x,0,info.width-1);y=clamp(y,0,info.height-1);
 const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,c=[0,0,0,0];
 for(const [u,v,w] of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]){
  const i=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[i+3]/255;
  c[3]+=a*w;for(let j=0;j<3;j++)c[j]+=data[i+j]*a*w;
 }
 if(c[3])for(let j=0;j<3;j++)c[j]/=c[3];return c;
}
function sourcePoint(quad,u,v){return [0,1].map(c=>quad[0][c]*(1-u)*(1-v)+quad[1][c]*u*(1-v)+quad[2][c]*u*v+quad[3][c]*(1-u)*v);}
function profile(image,quad){
 const samples=[];
 for(let y=0;y<32;y++)for(let x=0;x<32;x++){
  const p=sourcePoint(quad,.1+.8*(x+.5)/32,.1+.8*(y+.5)/32),c=sample(image,...p);
  if(c[3]>.9&&Palette.accent(c)<.05)samples.push(c);
 }
 return Palette.profile(samples);
}
async function preparedFloorDamage(hosts){
 const selected=read(ROOT+'/selection.json');
 if(selected.selected.length!==4)throw Error('Expected all four selected floor appearances');
 for(const [file,expected] of Object.entries(selected.reviewedFiles))if(P.hash(file)!==expected)throw Error('Selected floor art changed: '+file);
 const items=[];
 for(const d of designs){
  const host=hosts.find(i=>i.id==='floor-b'+d.base);if(!host)throw Error('Missing clean B host');
  const source=await sharp(path.join(P.ROOT,ROOT,'source',d.source+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const base=await sharp(host.png).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const hostSamples=[];
  for(let k=0;k<base.data.length;k+=4)if(base.data[k+3]===255)hostSamples.push(Array.from(base.data.subarray(k,k+4)));
  const hostProfile=Palette.profile(hostSamples);
  const stones=B.geometry(d.base).stones;
  for(const patch of d.patches)if(patch.joint){
   const parent=d.patches[patch.parent],[x,X,y,Y]=parent.rect,[a,A,b,B]=patch.rect;
   patch.quad=[[a,b],[A,b],[A,B],[a,B]].map(([u,v])=>sourcePoint(parent.quad,(u-x)/(X-x),(v-y)/(Y-y)));
  }
  for(const patch of d.patches){
   if(!patch.joint&&!stones.some(s=>JSON.stringify(s.rect)===JSON.stringify(patch.rect)))throw Error('Patch is not an existing B stone');
   patch.profile=profile(source,patch.quad);
  }
  for(const patch of d.patches)if(patch.joint)patch.profile=d.patches[patch.parent].profile;
  const buffer=Buffer.from(base.data),width=base.info.width,height=base.info.height;
  let changed=0,minX=width,minY=height,maxX=-1,maxY=-1;
  // Average four samples per source pixel for the already-filtered mobile host.
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
   const k=(y*width+x)*4;if(base.data[k+3]!==255)continue;
   const screen=[host.frame[0]+x+.5,host.frame[1]+y+.5];
   const world=[(screen[0]+2*screen[1])/256,(-screen[0]+2*screen[1])/256];
   // Far wider than the common filtered boundary strip, including corners.
   if(Math.min(world[0],world[1],1-world[0],1-world[1])<.10)continue;
   const patch=d.patches.find(p=>world[0]>p.rect[0]&&world[0]<p.rect[1]&&world[1]>p.rect[2]&&world[1]<p.rect[3]);
   if(!patch)continue;
   const [x0,x1,y0,y1]=patch.rect;
   const distance=Math.min(world[0]-x0,x1-world[0],world[1]-y0,y1-world[1]);
   const mask=patch.joint?smooth((distance-.004)/.018):d.key==='d'?smooth((distance-.025)/.035):smooth((distance-.012)/.022);if(!mask)continue;
   const colour=[0,0,0,0];
   for(const [dx,dy] of [[-.25,-.25],[.25,-.25],[-.25,.25],[.25,.25]]){
    const X=world[0]+(dx+2*dy)/256,Y=world[1]+(-dx+2*dy)/256;
    const p=sourcePoint(patch.quad,(X-x0)/(x1-x0),(Y-y0)/(y1-y0)),c=sample(source,...p);
    for(let i=0;i<4;i++)colour[i]+=c[i]/4;
   }
   const sy=Palette.luma(colour),median=patch.profile.luma[2],accent=Palette.accent(colour);
   // Preserve painted dark fissures/bevels; match broad stone colour to host.
   const delta=(sy-median)*(sy<median?.95:.60),mix=mask*colour[3];
   for(let c=0;c<3;c++){
    const stone=(patch.joint?hostProfile.rgb[c]:base.data[k+c])+delta;
    const value=stone*(1-accent)+colour[c]*accent;
    buffer[k+c]=Math.round(clamp(base.data[k+c]*(1-mix)+value*mix,0,255));
   }
   if(buffer[k]!==base.data[k]||buffer[k+1]!==base.data[k+1]||buffer[k+2]!==base.data[k+2]){changed++;minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}
  }
  const fullPNG=await sharp(buffer,{raw:{width,height,channels:4}}).png().toBuffer();
  if(!changed)throw Error('No visible source detail for '+d.key);
  const crop={left:Math.max(0,minX-2),top:Math.max(0,minY-2),width:Math.min(width-1,maxX+2)-Math.max(0,minX-2)+1,height:Math.min(height-1,maxY+2)-Math.max(0,minY-2)+1};
  // A rectangular backing must not repeat the host's translucent silhouette.
  // Keep the overlay strictly inside the floor, with a geometric transition
  // over identical opaque host colours before the first changed pixel.
  const overlay=Buffer.from(buffer);
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
   const X=host.frame[0]+x+.5,Y=host.frame[1]+y+.5;
   const u=(X+2*Y)/256,v=(-X+2*Y)/256;
   overlay[(y*width+x)*4+3]=Math.round(255*smooth((Math.min(u,v,1-u,1-v)-.06)/.025));
  }
  const png=await sharp(overlay,{raw:{width,height,channels:4}}).extract(crop).png().toBuffer();
  const id='floor-b'+d.base+'-damage-'+d.key;
  const item={id,frame:[host.frame[0]+crop.left,host.frame[1]+crop.top,crop.width,crop.height],bounds:host.bounds,png,
   floorDamage:{appearance:d.key,base:host.id,corruption:d.key==='c'||d.key==='d'},approvedSource:ROOT+'/source/'+d.source+'.png',
   adaptation:{mapping:'Selected stone faces sampled on exact existing B stone rectangles; D joint continues the parent face UVs over an interior mortar joint. No artwork regeneration.',sourcePatches:d.patches,unchangedBoundary:.10,stoneMask:d.key==='d'?[.025,.060]:[.012,.034],jointMask:d.key==='d'?[.004,.022]:null,changedPixels:changed,palette:'Host colour plus source luminance variation; joint uses host stone median to avoid doubling dark mortar. Violet accent retained.',alpha:'Full decorated image retains host alpha. Overlay fades geometrically inside .06-.085 cell margin, over opaque identical backing only; no doubled host silhouette. Crop has 2px unchanged colour border; draw only above matching B host.',overlayMargin:[.06,.085],crop,hostFrame:host.frame}};
  save('full-sprites/'+id+'.png',fullPNG);save('sprites/'+id+'.png',png);items.push(item);
 }
 json('prepared.json',{sourceSelection:ROOT+'/selection.json',items:items.map(({png,...i})=>({...i,bytes:png.length}))});
 return items;
}
module.exports={preparedFloorDamage,designs,referenceFiles:[ROOT+'/selection.json',...designs.map(d=>ROOT+'/source/'+d.source+'.png')]};
if(require.main===module)B.preparedFloorVariants().then(preparedFloorDamage).then(items=>console.log(JSON.stringify({items:items.map(i=>({id:i.id,bytes:i.png.length,changed:i.adaptation.changedPixels}))}))).catch(e=>{console.error(e.stack);process.exitCode=1;});
