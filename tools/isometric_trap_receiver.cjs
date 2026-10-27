// Complete rectangular paving from the user-approved larger-square wireframe.
// Paint whole crossing stones before cropping; do not overlay a stone collar.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs');
const OUT='docs/reference/trap-review/v12-approved-square';
const selection=JSON.parse(fs.readFileSync(path.join(P.ROOT,OUT,'selection.json')));
for(const [file,hash]of Object.entries(selection.hashes))if(P.hash(file)!==hash)throw Error('Approved trap wireframe changed: '+file);
const geometry=JSON.parse(fs.readFileSync(path.join(P.ROOT,selection.review,'geometry.json')));
const [OPEN,FAR]=geometry.opening,SPAN=FAR-OPEN;
const stones=geometry.model.stones.filter(s=>s.rect[1]>0&&s.rect[0]<1&&s.rect[3]>0&&s.rect[2]<1);
const rectangles=stones.map(s=>s.rect);
const points=([x,X,y,Y])=>[[x,y,0],[X,y,0],[X,Y,0],[x,Y,0]];
const polygons=rectangles.map(points);
const referenceFiles=[OUT+'/selection.json',...Object.keys(selection.hashes)];
async function preparedReceiver(floor){
 const model=structuredClone(P.models.find(m=>m.id==='floor'));
 const edges=polygons.flatMap(ps=>ps.map((a,i)=>({a,b:ps[(i+1)%4],kind:'floor'})));
 const faces=stones.map(s=>{
  const ps=points(s.rect);
  return {points:ps.map(P.project),p:ps.reduce((sum,p)=>sum.map((v,j)=>v+p[j]/4),[0,0,0]),
   normal:[0,0,1],kind:'floor',part:'floor',materialId:'floors-calm',bevelSeed:s.seed,
   // Resized stones keep their material coordinates across neighbour cells.
   textureTransform:P.textureTransform(points(s.originalRect||s.rect),[0,0,1])};
 });
 // Hidden colour coverage for the painter's floor silhouette. The registered
 // trap plate replaces this entire area; this is not a surrounding frame.
 const centre=points([OPEN,FAR,OPEN,FAR]);
 faces.push({points:centre.map(P.project),p:[.5,.5,0],normal:[0,0,1],kind:'floor',part:'floor',
  materialId:'floors-calm',bevelSeed:0,textureTransform:P.textureTransform(centre,[0,0,1])});
 const paint=await Stone.paint(model,{faces,edges,floorGuard:6});
 const fresh=await sharp(paint.png).extract({left:floor.frame[0]-paint.frame[0],top:floor.frame[1]-paint.frame[1],width:floor.frame[2],height:floor.frame[3]}).ensureAlpha().raw().toBuffer();
 const original=await sharp(floor.png).ensureAlpha().raw().toBuffer();
 // The approved geometry matches ordinary paving near every cell boundary.
 // Preserve its filtering/bevel colours there: changing a complete stone's
 // width slightly changes the finish along its otherwise identical edge.
 // This band contains NO changed stone contour; it cannot restore the old
 // inner slab cuts or the rejected collar. Fade only these finish differences.
 for(let y=0;y<floor.frame[3];y++)for(let x=0;x<floor.frame[2];x++){
  const p=P.ground([floor.frame[0]+x+.5,floor.frame[1]+y+.5]);
  const distance=Math.min(p[0],1-p[0],p[1],1-p[1]);
  const t=Math.max(0,Math.min(1,(distance-.06)/.01)),a=t*t*(3-2*t),i=(y*floor.frame[2]+x)*4;
  for(let c=0;c<3;c++)fresh[i+c]=Math.round(fresh[i+c]*a+original[i+c]*(1-a));
  fresh[i+3]=original[i+3];
 }
 const png=await sharp(fresh,{raw:{width:floor.frame[2],height:floor.frame[3],channels:4}}).png().toBuffer();
 const dir=path.join(P.ROOT,OUT);fs.mkdirSync(dir,{recursive:true});
 fs.writeFileSync(path.join(dir,'receiver.png'),png);
 fs.writeFileSync(path.join(dir,'receiver-geometry.json'),JSON.stringify({camera:P.camera,planeZ:0,opening:geometry.opening,completeStones:stones,approvedGeometry:selection.review+'/geometry.json'},null,2)+'\n');
 const guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${floor.frame[2]}" height="${floor.frame[3]}" viewBox="${floor.frame.join(' ')}">${Stone.ink(edges)}</svg>`;
 fs.writeFileSync(path.join(dir,'receiver-wireframe.svg'),guide);
 fs.writeFileSync(path.join(dir,'receiver-wireframe.png'),await sharp(Buffer.from(guide)).png().toBuffer());
 return {...floor,png};
}
module.exports={preparedReceiver,stones,rectangles,polygons,OPEN,FAR,SPAN,referenceFiles};
