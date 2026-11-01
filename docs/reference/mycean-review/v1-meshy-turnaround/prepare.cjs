// Package original ImageGen PNG bytes. No image repainting, resizing or mirroring.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const root=__dirname;
const items=[['front','character/01-front.png'],['left','character/02-left.png'],['back','character/03-back.png'],['right','character/04-right.png'],['staff','equipment/staff.png']];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const provenance=JSON.parse(fs.readFileSync(path.join(root,'provenance.json'))),records=[];
 for(const asset of provenance.assets){
  const bytes=fs.readFileSync(path.join(root,asset.file));
  assert.equal(sha(bytes),asset.sha256,'Source differs from archived native hash: '+asset.id);
 }
 for(const [id,target]of items){
  const source=path.join(root,'source',id+'.png'),bytes=fs.readFileSync(source);
  const meta=await sharp(bytes).metadata(),{data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  assert(meta.hasAlpha,'Native alpha missing: '+id);
  let clear=0,visible=0,edge=0,bounds=[info.width,info.height,-1,-1];
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
   const a=data[(y*info.width+x)*4+3];
   if(a===0)clear++;
   if(a>240){visible++;bounds[0]=Math.min(bounds[0],x);bounds[1]=Math.min(bounds[1],y);bounds[2]=Math.max(bounds[2],x);bounds[3]=Math.max(bounds[3],y);if(!x||!y||x===info.width-1||y===info.height-1)edge++;}
  }
  assert(clear>info.width*info.height*.2&&visible>info.width*info.height*(id==='staff'?.02:.1),'Expected isolated subject: '+id);
  assert(bounds[3]-bounds[1]>info.height*.8,'Full-height figure/equipment: '+id);
  if(id==='staff')assert(bounds[2]-bounds[0]<info.width*.35,'Expected slender complete staff');
  assert.equal(edge,0,'Clipped solid silhouette: '+id);
  assert(bytes.length<20*1024*1024,'PNG exceeds20MiB: '+id);
  assert.equal(info.width,info.height,'Square canvas: '+id);
  const dest=path.join(root,'meshy',target);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(source,dest);
  assert.equal(sha(fs.readFileSync(dest)),sha(bytes));
  records.push({id,file:'meshy/'+target,width:info.width,height:info.height,bytes:bytes.length,sha256:sha(bytes),nativeAlpha:true,transparentPixels:clear,solidBounds:bounds,byteIdenticalToSource:true,noClippedSolidPixels:true});
 }
 const bodies=records.filter(r=>r.file.includes('/character/'));
 assert.equal(new Set(bodies.map(r=>r.width+'x'+r.height)).size,1,'Common character canvas');
 const spread=index=>Math.max(...bodies.map(r=>r.solidBounds[index]))-Math.min(...bodies.map(r=>r.solidBounds[index]));
 const report={status:'prepared-not-reconstructed',tool:'built-in image_gen',records,characterTopSpreadPixels:spread(1),characterSoleSpreadPixels:spread(3),totalPngBytes:records.reduce((a,r)=>a+r.bytes,0),sources:provenance.assets.map(a=>({id:a.id,file:a.file,sha256:sha(fs.readFileSync(path.join(root,a.file))),selected:a.selected})),limits:'Illustrations, not calibrated mesh views. Meshy reconstruction, rigging and animation untested. Native outputs copied without pixel edits.'};
 fs.writeFileSync(path.join(root,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({files:records.length,size:records[0].width,totalPngBytes:report.totalPngBytes,topSpread:spread(1),soleSpread:spread(3)}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
