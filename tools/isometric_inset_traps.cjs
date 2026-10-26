// Offline geometry-native paint. The approved socket stays in the common 2:1
// camera; mechanisms are never fitted by distorting a generated sprite.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs');
const REVIEW='docs/reference/trap-review/v2-inset-floor';
const MATERIAL='docs/reference/trap-review/v3-integrated/source/forged-iron.png';
const referenceFiles=[`${REVIEW}/geometry.json`,`${REVIEW}/selection.json`,MATERIAL,'docs/reference/trap-review/v3-integrated/source/generation.json'];
const spec=JSON.parse(fs.readFileSync(path.join(P.ROOT,referenceFiles[0])));
const INNER=spec.inner,Z=spec.insertZ;
const above=new Set(['spike','jaw','tooth','hinge']);
function face(m,points,kind,group=kind){m.faces.push({points,kind,group});}
const corners=(r,z)=>[[r[0],r[1],z],[r[2],r[1],z],[r[2],r[3],z],[r[0],r[3],z]];
const rect=(m,r,z,kind,group)=>face(m,corners(r,z),kind,group);
function box(m,r,z,Z,kind,group){const a=corners(r,z),b=corners(r,Z);face(m,b,kind,group+':top');for(let i=0;i<4;i++){const j=(i+1)%4;face(m,[a[i],a[j],b[j],b[i]],kind,group+':'+i);}}
const polar=(a,r,z)=>[.5+Math.cos(a)*r,.5+Math.sin(a)*r,z];
function band(m,r,R,z,Z,start,end,kind,group){
 const n=Math.ceil((end-start)*14);
 for(let i=0;i<n;i++){
  const a=start+(end-start)*i/n,b=start+(end-start)*(i+1)/n;
  face(m,[polar(a,r,Z),polar(a,R,Z),polar(b,R,Z),polar(b,r,Z)],kind,group+':top');
  face(m,[polar(a,R,z),polar(b,R,z),polar(b,R,Z),polar(a,R,Z)],kind,group+':outer');
  face(m,[polar(a,r,z),polar(b,r,z),polar(b,r,Z),polar(a,r,Z)],kind,group+':inner');
 }
}
function disk(m,r,z,kind){face(m,Array.from({length:64},(_,i)=>polar(i*Math.PI/32,r,z)),kind);}
function model(kind,ready){
 const m=structuredClone(spec.models[0]);m.id=`trap-${kind}-${ready?'ready':'spent'}`;
 rect(m,INNER,Z,'insert');
 if(kind==='spike'){
  // Preserve the nine sockets and raised pyramids from the approved wireframe.
  const source=spec.models[ready?2:1];
  m.faces.push(...structuredClone(source.faces.filter(f=>['socket','slot','spike'].includes(f.kind))));
 }else if(kind==='snare'){
  disk(m,.212,Z+.001,'slot');
  band(m,.18,.207,Z+.001,Z+.006,0,2*Math.PI,'socket','track');
  rect(m,[.435,.435,.565,.565],Z+.007,'trigger','trigger');
  if(ready){
   for(let side=0;side<2;side++){
    const start=side*Math.PI+.14,end=(side+1)*Math.PI-.14;
    band(m,.175,.204,Z+.005,.04,start,end,'jaw','jaw:'+side);
    for(let i=0;i<5;i++){
     const a=start+(end-start)*(i+.5)/5;
     const p=[polar(a-.12,.179,.04),polar(a+.12,.179,.04),polar(a,.118,.07)];
     face(m,p,'tooth',`tooth:${side}:${i}`);
     face(m,[p[0],p[2],polar(a,.172,.017)],'jaw',`toothside:${side}:${i}`);
    }
   }
   for(const x of [.282,.718])box(m,[x-.022,.462,x+.022,.538],Z,.045,'hinge','hinge:'+x);
  }
 }else{
  disk(m,.203,Z+.001,'void-dark');
  band(m,.184,.211,Z+.001,Z+.006,0,Math.PI*2,'socket','seal');
  band(m,.168,.176,Z+.002,Z+.003,0,Math.PI*2,ready?'violet':'etch','inner-ring');
  for(let i=0;i<8;i++){
   const a=i*Math.PI/4;
   face(m,[polar(a-.075,.195,Z+.007),polar(a,.207,Z+.007),polar(a+.075,.195,Z+.007),polar(a,.184,Z+.007)],ready?'violet':'etch','rune:'+i);
  }
 }
 // Four recessed fastening heads, inside the insert, never a raised stone rim.
 for(const x of [.255,.745])for(const y of [.255,.745]){
  rect(m,[x-.009,y-.009,x+.009,y+.009],Z+.001,'rivet','rivet:'+x+':'+y);
 }
 return m;
}
function paintColor(f,p,ready,edge,material){
 const n=P.normal(f.points),light=[-.42,-.55,.72],lambert=Math.abs(P.dot(n,light));
 const palettes={bevel:[67,82,108],recess:[25,32,48],bottom:[14,20,31],insert:[37,43,57],socket:[63,72,90],slot:[15,20,30],spike:[125,143,171],jaw:[91,107,134],tooth:[140,155,184],hinge:[77,91,114],trigger:[78,85,103],rivet:[103,113,137],etch:[54,44,69],'void-dark':[19,15,33],violet:[147,67,213]};
 let c=palettes[f.kind].slice();
 const shade=.48+.7*lambert;
 let variation=Math.sin(p[0]*71+p[1]*39+p[2]*41)*1.3+Math.sin(p[0]*157-p[1]*117)*.9;
 if(f.kind==='void-dark'&&ready){
  const x=p[0]-.5,y=p[1]-.5,r=Math.hypot(x,y),a=Math.atan2(y,x);
  const tendril=Math.pow(Math.max(0,Math.sin(a*3+r*72)),14)*Math.max(0,1-r/.2);
  c=[19+tendril*55,14+tendril*10,32+tendril*92];
 }
 if(['insert','socket','spike','jaw','tooth','hinge','trigger'].includes(f.kind)){
  const u=n[2]>.7?p[0]:Math.abs(n[0])>Math.abs(n[1])?p[1]:p[0];
  const v=n[2]>.7?p[1]:p[2];
  const X=((Math.floor(u*512)%128)+128)%128,Y=((Math.floor(v*512)%128)+128)%128;
  const index=(Y*128+X)*3;
  variation+=(material[index]+material[index+1]+material[index+2]-180)*.16;
 }
 if(edge&&['spike','tooth','jaw','hinge','socket','trigger','rivet'].includes(f.kind))variation+=24;
 return c.map(v=>Math.max(0,Math.min(255,Math.round(v*shade+variation))));
}
async function render(m,floor,ready,material){
 const scale=4,frame=floor.frame,mesh=P.raster(m,frame,scale);
 const texture=await sharp(floor.rawHigh).ensureAlpha().raw().toBuffer();
 const ground=Buffer.alloc(texture.length),solid=Buffer.alloc(texture.length);
 for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++){
  const k=y*mesh.width+x,i=k*4,fi=mesh.owner[k];if(fi<0)continue;
  const f=m.faces[fi];
  if(f.kind==='floor'){texture.copy(ground,i,i,i+4);continue;}
  const p=Array.from(mesh.xyz.subarray(k*3,k*3+3));
  let edge=false;
  for(const [dx,dy] of [[-2,0],[2,0],[0,-2],[0,2]]){
   const X=x+dx,Y=y+dy;if(X<0||Y<0||X>=mesh.width||Y>=mesh.height)continue;
   const other=mesh.owner[Y*mesh.width+X];
   if(other<0||m.faces[other].group!==f.group){edge=true;break;}
  }
  const color=paintColor(f,p,ready,edge,material);
  (above.has(f.kind)?solid:ground).set([...color,255],i);
 }
 const png=raw=>sharp(raw,{raw:{width:mesh.width,height:mesh.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
 return {ground:await png(ground),solid:await png(solid)};
}
async function preparedInsetTraps(){
 const selection=JSON.parse(fs.readFileSync(path.join(P.ROOT,`${REVIEW}/selection.json`)));
 for(const [p,h] of Object.entries(selection.hashes))if(crypto.createHash('sha256').update(fs.readFileSync(path.join(P.ROOT,p))).digest('hex')!==h)throw Error('Approved socket changed: '+p);
 const floor=await Stone.architecture(P.models.find(m=>m.id==='floor')),items=[];
 const material=await sharp(path.join(P.ROOT,MATERIAL)).removeAlpha().resize(128,128).raw().toBuffer();
 for(const kind of ['spike','snare','void'])for(const ready of [true,false]){
  const m=model(kind,ready);
  // Render the receiving floor without the raised mechanism: no transparent
  // spike-shaped holes remain when the actor covers the separate solid.
  const low={...m,faces:m.faces.filter(f=>!above.has(f.kind))};
  const ground=await render(low,floor,ready,material);
  const id=m.id+'-floor';
  items.push({id,frame:floor.frame,bounds:{min:[0,0,-spec.depth],max:[1,1,0]},png:ground.ground,rasterScale:.75,trap:{kind,ready,layer:'floor'}});
  if(ready&&kind!=='void'){
   const full=await render(m,floor,ready,material);
   const frame=[-80,15,160,100];
   const png=await sharp(full.solid).extract({left:frame[0]-floor.frame[0],top:frame[1]-floor.frame[1],width:frame[2],height:frame[3]}).png().toBuffer();
   const points=m.faces.filter(f=>above.has(f.kind)).flatMap(f=>f.points);
   items.push({id:`trap-${kind}-mechanism`,frame,bounds:{min:[0,1,2].map(a=>Math.min(...points.map(p=>p[a]))),max:[0,1,2].map(a=>Math.max(...points.map(p=>p[a])))},png,rasterScale:1,trap:{kind,ready:true,layer:'mechanism'}});
  }
 }
 return items;
}
module.exports={preparedInsetTraps,referenceFiles,model};
