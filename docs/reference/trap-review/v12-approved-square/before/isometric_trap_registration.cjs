// Ground paint is registered to the actual XYZ socket, separately from relief.
// These source landmarks are calibration data, not a deformation of a whole sprite.
const sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const OPEN=.22,SPAN=.56,Z=0,SCALE=4;
const centres={spike:[[334,406],[975,406],[1609,406]],snare:[[342,395],[975,395],[1606,395]],void:[[333,405],[972,405],[1609,405]]};
const half={spike:[153,88],snare:[190,130],void:[172,110]};
function registration(kind,state){
 const [cx,cy]=centres[kind][state], [rx,ry]=half[kind];
 return {cx,cy,rx,ry,vertical:Math.sqrt(2*(rx*rx-ry*ry))/SPAN};
}
function sourceUV(reg,p){
 const u=(p[0]-OPEN)/SPAN,v=(p[1]-OPEN)/SPAN;
 return [reg.cx+reg.rx*(u-v),reg.cy+reg.ry*(u+v-1)];
}
function sourcePoint(reg,uv,z=Z){
 const a=(uv[0]-reg.cx)/reg.rx,b=(uv[1]+(z-Z)*reg.vertical-reg.cy)/reg.ry;
 return [OPEN+SPAN*(1+a+b)/2,OPEN+SPAN*(1-a+b)/2,z];
}
function inside(x,y,points){
 let yes=false;
 for(let i=0,j=points.length-1;i<points.length;j=i++){
  const a=points[i],b=points[j];
  if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])yes=!yes;
 }return yes;
}
function sample(source,uv){
 const x=Math.max(0,Math.min(source.info.width-2,uv[0])),y=Math.max(0,Math.min(source.info.height-2,uv[1]));
 const X=Math.floor(x),Y=Math.floor(y),u=x-X,v=y-Y;
 return [0,1,2,3].map(c=>{
  const at=(a,b)=>source.data[(b*source.info.width+a)*4+c];
  return Math.round(at(X,Y)*(1-u)*(1-v)+at(X+1,Y)*u*(1-v)+at(X,Y+1)*(1-u)*v+at(X+1,Y+1)*u*v);
 });
}
function mechanism(kind,state,reg,polys){
 const faces=[];
 const face=(points,uv)=>faces.push({points,uv});
 if(kind==='spike'){
  const slots=[[0,0],[0,1],[1,0],[0,2],[1,1],[2,0],[1,2],[2,1],[2,2]];
  for(let i=0;i<polys.length;i++){
   const [tip,right,front,left]=polys[i], [u,v]=slots[i];
   const x=.25+(u+.5)/6,y=.25+(v+.5)/6;
   const r=state==='ready'?.026:.062,h=state==='ready'?.055:.23;
   const peak=[x,y,h],L=[x-r,y+r,Z],F=[x+r,y+r,Z],R=[x+r,y-r,Z];
   face([peak,L,F],[tip,left,front]);face([peak,F,R],[tip,front,right]);
  }
 }else if(kind==='snare'){
  // Height-aware surface proxy for the approved painted jaws. Contact stays on
  // the registered plane; raised metal keeps a separate vertical component.
  // This is a 2.5D paint surface, not a reconstruction of its hidden volume.
  const poly=polys[0],xs=poly.map(p=>p[0]),ys=poly.map(p=>p[1]);
  const point=uv=>sourcePoint(reg,uv,Z+Math.max(0,reg.cy-uv[1])/reg.vertical);
  for(let y=Math.min(...ys);y<Math.max(...ys);y+=5)for(let x=Math.min(...xs);x<Math.max(...xs);x+=5){
   const uv=[[x,y],[x+5,y],[x+5,y+5],[x,y+5]];
   face([point(uv[0]),point(uv[1]),point(uv[2])],[uv[0],uv[1],uv[2]]);
   face([point(uv[0]),point(uv[2]),point(uv[3])],[uv[0],uv[2],uv[3]]);
  }
 }
 return {faces};
}
async function renderMechanism(model,source,polys,frame){
 const mesh=P.raster(model,frame,SCALE),raw=Buffer.alloc(mesh.width*mesh.height*4);
 const triangles=model.faces.map(f=>{
  const [a,b,c]=f.points.map(P.project),det=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);
  return {a,b,c,det,uv:f.uv};
 });
 for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++){
  const k=y*mesh.width+x,fi=mesh.owner[k];if(fi<0)continue;
  const {a,b,c,det,uv}=triangles[fi],X=frame[0]+(x+.5)/SCALE,Y=frame[1]+(y+.5)/SCALE;
  const u=((b[1]-c[1])*(X-c[0])+(c[0]-b[0])*(Y-c[1]))/det,v=((c[1]-a[1])*(X-c[0])+(a[0]-c[0])*(Y-c[1]))/det;
  const at=[0,1].map(i=>uv[0][i]*u+uv[1][i]*v+uv[2][i]*(1-u-v));
  if(polys.some(p=>inside(at[0],at[1],p)))raw.set(sample(source,at),k*4);
 }
 return sharp(raw,{raw:{width:mesh.width,height:mesh.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
}
async function renderFloor(kind,state,source,polys,frame,base){
 const reg=registration(kind,state),spent=registration(kind,2);
 const W=frame[2]*SCALE,H=frame[3]*SCALE,raw=Buffer.alloc(W*H*4);
 const low=sample(source,sourceUV(reg,[.34,.26,0])).slice(0,3);
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
  const X=frame[0]+(x+.5)/SCALE,Y=frame[1]+(y+.5)/SCALE;
  const p=P.ground([X,Y]);
  const edge=Math.min(p[0]-OPEN,.78-p[0],p[1]-OPEN,.78-p[1]);
  if(edge<-.009)continue;
  let color;
  if(edge<0){
   // A real cut edge through the paving. Only a thin joint; no deep pit wall.
   const front=Math.min(.78-p[0],.78-p[1])<Math.min(p[0]-OPEN,p[1]-OPEN);
   color=front?[65,78,101,255]:[18,24,36,255];
  }else if(edge<.006){color=[13,17,26,255];}
  else{
   const uv=sourceUV(reg,p);color=sample(source,uv);
   if(kind==='spike'){
    // One registered 3x3 socket layout across all three states. Each socket
    // uses the selected empty-pocket paint; no painted spike survives in it.
    color=sample(source,sourceUV(spent,p));
    if(p[0]>=.25&&p[0]<.75&&p[1]>=.25&&p[1]<.75){
     const u=((p[0]-.25)*6)%1,v=((p[1]-.25)*6)%1;
     color=sample(source,[spent.cx+45*(u-v),spent.cy+27*(u+v-1)]);
    }else if(state<2 && Math.abs(p[0]+p[1]-1)<.06 && Math.abs(p[0]-p[1])>.40){
     color=sample(source,uv); // Original violet ready/triggered corner marks.
    }
   }
   // Raised paint is not baked into the floor too. A passing actor must be
   // able to occlude a mechanism without leaving a second copy underneath.
   if(kind==='snare'&&polys.some(poly=>inside(uv[0],uv[1],poly))){
     const variation=Math.sin(p[0]*91+p[1]*47)*1.5;
     color=low.map(c=>Math.max(12,Math.min(48,Math.round(c*.65+variation))));color.push(255);
   }
  }
  raw.set(color,(y*W+x)*4);
 }
 const patch=await sharp(raw,{raw:{width:W,height:H,channels:4}}).resize(frame[2],frame[3]).raw().toBuffer();
 const result=Buffer.from(base);
 for(let i=0;i<result.length;i+=4){
  const a=patch[i+3]/255;if(!a)continue;
  for(let c=0;c<3;c++)result[i+c]=Math.round(patch[i+c]*a+result[i+c]*(1-a));
 }
 return sharp(result,{raw:{width:frame[2],height:frame[3],channels:4}}).png().toBuffer();
}
module.exports={registration,sourceUV,sourcePoint,mechanism,renderFloor,renderMechanism,OPEN,SPAN,Z};
