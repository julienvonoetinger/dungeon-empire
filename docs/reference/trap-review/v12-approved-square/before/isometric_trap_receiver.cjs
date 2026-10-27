// Eight complete framing stones around a square socket, all on the floor plane.
// This is purpose-built paving, not a square crop through the B floor pattern.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs');
const OUT='docs/reference/trap-review/v9-registered-sockets';
const outer=.10,inner=.22,far=.78,end=.90;
const rectangles=[
 [outer,inner,outer,inner],[inner,far,outer,inner],[far,end,outer,inner],
 [outer,inner,inner,far],[far,end,inner,far],
 [outer,inner,far,end],[inner,far,far,end],[far,end,far,end],
];
const polygons=rectangles.map(([x,X,y,Y])=>[[x,y,0],[X,y,0],[X,Y,0],[x,Y,0]]);
async function preparedReceiver(floor){
 const model=structuredClone(P.models.find(m=>m.id==='floor'));
 const edges=polygons.flatMap(ps=>ps.map((a,i)=>({a,b:ps[(i+1)%4],kind:'floor'})));
 // The stone painter validates coverage over its padded floor canvas. These
 // surrounding faces only supply that colour guard; final outer paving is
 // copied unchanged from the B host, and the centre receives the trap.
 const guard=[[-.18,outer,-.18,1.18],[end,1.18,-.18,1.18],[outer,end,-.18,outer],[outer,end,end,1.18],[inner,far,inner,far]]
  .map(([x,X,y,Y])=>[[x,y,0],[X,y,0],[X,Y,0],[x,Y,0]]);
 const faces=[...polygons,...guard].map((ps,i)=>({points:ps.map(P.project),p:ps.reduce((s,p)=>s.map((v,j)=>v+p[j]/4),[0,0,0]),normal:[0,0,1],kind:'floor',part:'floor',materialId:'floors-calm',bevelSeed:420+i,textureTransform:P.textureTransform(ps,[0,0,1])}));
 const paint=await Stone.paint(model,{faces,edges,floorGuard:6});
 const fresh=await sharp(paint.png).extract({left:floor.frame[0]-paint.frame[0],top:floor.frame[1]-paint.frame[1],width:floor.frame[2],height:floor.frame[3]}).ensureAlpha().raw().toBuffer();
 const old=await sharp(floor.png).ensureAlpha().raw().toBuffer();
 const result=Buffer.from(old), W=floor.frame[2],H=floor.frame[3];
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
  const p=P.ground([floor.frame[0]+x+.5,floor.frame[1]+y+.5]);
  const margin=Math.min(p[0]-outer,end-p[0],p[1]-outer,end-p[1]);
  if(margin<-.012)continue;
  const a=Math.max(0,Math.min(1,(margin+.012)/.012)),k=(y*W+x)*4;
  for(let c=0;c<3;c++)result[k+c]=Math.round(fresh[k+c]*a+old[k+c]*(1-a));
 }
 const png=await sharp(result,{raw:{width:W,height:H,channels:4}}).png().toBuffer();
 const dir=path.join(P.ROOT,OUT);fs.mkdirSync(dir,{recursive:true});
 fs.writeFileSync(path.join(dir,'receiver.png'),png);
 fs.writeFileSync(path.join(dir,'receiver-geometry.json'),JSON.stringify({camera:P.camera,planeZ:0,outer:[outer,outer,end,end],opening:[inner,inner,far,far],completeStones:rectangles,unchangedBoundaryStrip:.06},null,2)+'\n');
 const guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="${floor.frame.join(' ')}">${Stone.ink(edges)}</svg>`;
 fs.writeFileSync(path.join(dir,'receiver-wireframe.svg'),guide);
 fs.writeFileSync(path.join(dir,'receiver-wireframe.png'),await sharp(Buffer.from(guide)).png().toBuffer());
 return {...floor,png};
}
module.exports={preparedReceiver,rectangles,polygons};
