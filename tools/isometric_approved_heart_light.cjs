// Adopt the accepted self-light PNGs. Only exactly transparent padding is removed.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const REVIEW='docs/reference/isometric-review/painted-v1/heart-self-light-v1';
const read=p=>fs.readFileSync(path.join(P.ROOT,p));
async function approvedHeartLight(){
  const selection=JSON.parse(read(`${REVIEW}/selection.json`));
  if(selection.status!=='accepted appearance')throw Error('Heart self-light appearance is not accepted.');
  for(const [p,h] of Object.entries(selection.sha256))if(P.hash(p)!==h)throw Error('Accepted heart-light reference changed: '+p);
  const prepared=JSON.parse(read(`${REVIEW}/prepared.json`)),items=[];
  if(prepared.entries.length!==2)throw Error('Expected shadow and glow.');
  for(const entry of prepared.entries){
    if(!['shadow','glow'].includes(entry.id))throw Error('Unknown self-light effect.');
    const {data,info}=await sharp(read(entry.file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    if(info.width!==entry.frame[2]||info.height!==entry.frame[3])throw Error('Accepted effect frame mismatch.');
    let minX=info.width,minY=info.height,maxX=-1,maxY=-1;
    for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]){
      minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);
      // The fixed 4x4 receiving mask must cover every filtered nontransparent pixel.
      for(const dx of [-1,2])for(const dy of [-1,2]){
        const world=P.ground([entry.frame[0]+x+dx,entry.frame[1]+y+dy]);
        if(Math.abs(world[0])>1.5||Math.abs(world[1])>1.5)throw Error('Self-light exceeds receiving mask: '+entry.id);
      }
    }
    if(maxX<0)throw Error('Empty accepted effect.');
    const left=Math.max(0,minX-2),top=Math.max(0,minY-2);
    const width=Math.min(info.width,maxX+3)-left,height=Math.min(info.height,maxY+3)-top;
    const png=await sharp(read(entry.file)).extract({left,top,width,height}).png().toBuffer();
    items.push({id:'heart-self-'+entry.id,png,densityPng:{256:png},
      frame:[entry.frame[0]+left,entry.frame[1]+top,width,height],
      bounds:{min:[-1.5,-1.5,0],max:[1.5,1.5,0]},groundEffect:true,groundBlend:entry.blend,
      approvedSource:entry.file,adaptation:{sourceCrop:[left,top,width,height],sourceFrame:entry.frame,receivingHalfExtent:1.5,source:'accepted native-resolution effect; alpha-zero crop only'}});
  }
  return {items,effects:items.map(i=>i.id)};
}
module.exports={approvedHeartLight,referenceFiles:[`${REVIEW}/selection.json`,`${REVIEW}/prepared.json`,`${REVIEW}/shadow.png`,`${REVIEW}/glow.png`]};
