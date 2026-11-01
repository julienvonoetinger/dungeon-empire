// Package native ImageGen outputs without editing their pixels.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const ROOT=__dirname;
const items=[['front.png','character/01-front.png'],['left.png','character/02-left.png'],['back.png','character/03-back.png'],['right.png','character/04-right.png'],['hammer-initial.png','equipment/hammer.png'],['shield.png','equipment/shield.png']];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const records=[];
 for(const [source,target]of items){
  const input=path.join(ROOT,'source',source),output=path.join(ROOT,'meshy',target),bytes=fs.readFileSync(input);
  const meta=await sharp(bytes).metadata(),{data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  assert(meta.hasAlpha,'Native alpha required: '+source);
  let zero=0,visible=0,bounds=[info.width,info.height,-1,-1],edgeVisible=0;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
   const a=data[(y*info.width+x)*4+3];
   if(a===0)zero++;
   if(a>240){visible++;bounds[0]=Math.min(bounds[0],x);bounds[1]=Math.min(bounds[1],y);bounds[2]=Math.max(bounds[2],x);bounds[3]=Math.max(bounds[3],y);if(x===0||y===0||x===info.width-1||y===info.height-1)edgeVisible++;}
  }
  assert(zero>info.width*info.height*.2&&visible>info.width*info.height*.1,'Expected isolated subject: '+source);
  assert.equal(edgeVisible,0,'Subject clipped to image edge: '+source);
  assert(bytes.length<20*1024*1024,'PNG must stay below20MiB');
  if(target.startsWith('character/')){assert.equal(info.width,1254);assert.equal(info.height,1254);}
  fs.mkdirSync(path.dirname(output),{recursive:true});fs.copyFileSync(input,output);assert.equal(sha(fs.readFileSync(output)),sha(bytes));
  records.push({source:'source/'+source,file:'meshy/'+target,width:info.width,height:info.height,bytes:bytes.length,sha256:sha(bytes),nativeAlpha:true,transparentPixels:zero,solidBounds:bounds,noClippedSolidPixels:true,byteIdenticalToSource:true});
 }
 const bodies=records.filter(r=>r.file.includes('/character/')),tops=bodies.map(r=>r.solidBounds[1]),bottoms=bodies.map(r=>r.solidBounds[3]);
 const report={status:'prepared-not-reconstructed',tool:'built-in image_gen',records,characterTopSpreadPixels:Math.max(...tops)-Math.min(...tops),characterSoleSpreadPixels:Math.max(...bottoms)-Math.min(...bottoms),limits:'Independent illustrations, not calibrated mesh renders. Meshy result untested. No game assets replaced.'};
 fs.writeFileSync(path.join(ROOT,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(report,null,2));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
