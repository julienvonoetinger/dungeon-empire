// Accepted paint fitted uniformly into the native floor socket. The source
// pavement is never used as a replacement tile: the periodic kit floor owns
// the border. Source silhouettes supply the separately ordered raised parts.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),FloorVariants=require('./isometric_floor_variants.cjs');
const REVIEW='docs/reference/trap-review/v7-integrated-paint';
const selection=JSON.parse(fs.readFileSync(path.join(P.ROOT,REVIEW,'selection.json')));
const referenceFiles=[REVIEW+'/selection.json',...Object.values(selection.sources)];
const states=['ready','triggered','spent'];
const fits={
 spike:{centres:[[334,406],[974,406],[1609,406]],width:310},
 snare:{centres:[[342,395],[975,395],[1606,395]],width:380},
 void:{centres:[[333,405],[972,405],[1609,405]],width:340}
};
const inside=(x,y,points)=>{
 let yes=false;
 for(let i=0,j=points.length-1;i<points.length;j=i++){
  const a=points[i],b=points[j];
  if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])yes=!yes;
 }return yes;
};
function silhouettes(kind,state){
 if(kind==='void'||kind==='spike'&&state==='spent')return [];
 if(kind==='spike'){
  const points=state==='ready'?[[334,353],[291,378],[377,379],[246,407],[334,406],[423,407],[290,433],[378,433],[334,461]]:[[975,336],[925,367],[1027,367],[875,394],[975,397],[1076,394],[925,425],[1025,425],[975,454]];
  const dx=state==='ready'?12:28,up=state==='ready'?12:48,down=state==='ready'?9:18;
  return points.map(([x,y])=>[[x,y-up],[x+dx,y+down*.5],[x,y+down],[x-dx,y+down*.5]]);
 }
 const shift=state==='ready'?0:state==='triggered'?633:1264;
 const open=[[250,280],[228,288],[206,308],[188,338],[181,365],[185,386],[204,404],[235,416],[244,432],[276,442],[323,452],[358,452],[401,443],[429,436],[443,418],[473,407],[493,387],[504,362],[495,336],[474,307],[451,287],[431,278],[445,307],[451,327],[418,324],[430,345],[400,343],[413,369],[388,375],[381,353],[361,353],[361,326],[323,326],[323,350],[300,351],[299,374],[270,370],[285,345],[252,349],[267,322],[237,330],[241,306]];
 const closed=[[340,272],[320,274],[295,292],[277,319],[264,353],[252,351],[240,360],[237,385],[246,405],[265,411],[279,430],[320,444],[324,452],[359,452],[361,445],[402,435],[423,415],[443,406],[450,386],[443,363],[429,354],[419,355],[407,320],[389,292],[363,275],[344,272],[342,285]];
 return [(state==='ready'?open:closed).map(([x,y])=>[x+shift,y])];
}
async function preparedInsetTraps(preparedFloor){
 for(const [file,hash] of Object.entries(selection.hashes))if(P.hash(file)!==hash)throw Error('Selected trap paint changed: '+file);
 // Every B arrangement shares these crossing stones. The older floor.png
 // does not share their boundary joints and would make notches around traps.
 const floor=preparedFloor||(await FloorVariants.preparedFloorVariants())[0];
 const base=await sharp(floor.png).ensureAlpha().raw().toBuffer();
 const items=[],report=[];
 const frame=floor.frame,mechanismFrame=[-80,-8,160,120];
 for(const kind of Object.keys(fits)){
  const fit=fits[kind],source=selection.sources[kind];
  const {data,info}=await sharp(path.join(P.ROOT,source)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  // One scale for every state. The native .22.. .78 receiving square remains
  // 2:1; source material is clipped there, never stretched to its rectangle.
  const ratio=256*.56/fit.width;
  for(let s=0;s<3;s++){
   const state=states[s],anchor=fit.centres[s],polys=silhouettes(kind,state);
   const sample=(x,y)=>{
    const X=anchor[0]+x/ratio,Y=anchor[1]+(y-64)/ratio;
    const sx=Math.max(0,Math.min(info.width-1,Math.round(X))),sy=Math.max(0,Math.min(info.height-1,Math.round(Y)));
    return {rgba:data.subarray((sy*info.width+sx)*4,(sy*info.width+sx)*4+4),x:X,y:Y};
   };
   const scale=4,W=frame[2]*scale,H=frame[3]*scale;
   // Supersampled aperture yields a thin clean flush join without pit walls.
   const overlay=Buffer.alloc(W*H*4);
   for(let y=0;y<H;y++)for(let x=0;x<W;x++){
    const X=frame[0]+(x+.5)/scale,Y=frame[1]+(y+.5)/scale,p=P.ground([X,Y]);
    if(p[0]<.22||p[0]>.78||p[1]<.22||p[1]>.78)continue;
    overlay.set(sample(X,Y).rgba,(y*W+x)*4);
   }
   const patch=await sharp(overlay,{raw:{width:W,height:H,channels:4}}).resize(frame[2],frame[3]).raw().toBuffer();
   const ground=Buffer.from(base);
   // Keep untouched border bytes exact; a full libvips over operation would
   // round-trip premultiplied alpha even where the patch is transparent.
   for(let i=0;i<ground.length;i+=4){
    const a=patch[i+3]/255;if(!a)continue;
    for(let c=0;c<3;c++)ground[i+c]=Math.round(patch[i+c]*a+ground[i+c]*(1-a));
   }
   const png=await sharp(ground,{raw:{width:frame[2],height:frame[3],channels:4}}).png().toBuffer();
   items.push({id:`trap-${kind}-${state}-floor`,frame,bounds:{min:[0,0,0],max:[1,1,0]},png,rasterScale:.75,trap:{kind,state,layer:'floor'},approvedSource:source});
   if(kind!=='void'){
    const sw=mechanismFrame[2]*scale,sh=mechanismFrame[3]*scale,raw=Buffer.alloc(sw*sh*4);
    for(let y=0;y<sh;y++)for(let x=0;x<sw;x++){
     const c=sample(mechanismFrame[0]+(x+.5)/scale,mechanismFrame[1]+(y+.5)/scale);
     if(polys.some(p=>inside(c.x,c.y,p)))raw.set(c.rgba,(y*sw+x)*4);
    }
    const png=await sharp(raw,{raw:{width:sw,height:sh,channels:4}}).resize(mechanismFrame[2],mechanismFrame[3]).png().toBuffer();
    items.push({id:`trap-${kind}-${state}-mechanism`,frame:mechanismFrame,bounds:{min:[.2,.2,0],max:[.8,.8,.24]},png,rasterScale:.75,trap:{kind,state,layer:'mechanism'},approvedSource:source});
   }
   report.push({kind,state,source,sourceCentre:anchor,uniformScale:ratio,sourceSilhouettes:polys,groundAnchor:[.5,.5,0]});
  }
 }
 fs.writeFileSync(path.join(P.ROOT,REVIEW,'preparation.json'),JSON.stringify({policy:'Uniform paint fit, geometric flush aperture, existing paving outside. Source PNGs immutable. Mechanism silhouettes are support/cutout proxies, not reconstructed XYZ.',states:report},null,2)+'\n');
 return items;
}
module.exports={preparedInsetTraps,referenceFiles};
