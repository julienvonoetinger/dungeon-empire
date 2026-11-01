// Package actual Godot captures into an animated review. No painting or compositing.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname,root=path.resolve(dir,'../../../..');
const source=path.join(root,'artifacts/batrafian-attack/native');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const frames=[],sources=[];
 for(let i=0;i<30;i++){
  const file=`motion-${String(i).padStart(2,'0')}.png`,input=fs.readFileSync(path.join(source,file));
  const meta=await sharp(input).metadata();
  if(meta.width!==1280||meta.height!==720)throw Error('Unexpected capture size: '+file);
  frames.push(await sharp(input).resize(1024,576).ensureAlpha().raw().toBuffer());
  sources.push({file,time_ms:Math.min(i*40,1150),sha256:sha(input)});
 }
 const outputs=[];
 for(const speed of [1,2]){
  const delay=Array.from({length:30},(_,i)=>i===29?800:(i===28?30:40)*speed);
  const file=speed===1?'core-attack.webp':'core-attack-slow.webp';
  await sharp(Buffer.concat(frames),{raw:{width:1024,height:576*30,channels:4,pageHeight:576}})
   .webp({lossless:true,loop:0,delay}).toFile(path.join(dir,file));
  const metadata=await sharp(path.join(dir,file),{animated:true}).metadata();
  // WebP combines consecutive identical captures. Check the decoded timeline,
  // not the encoded frame count, so every source image still holds exactly as long.
  const duration=delay.reduce((a,b)=>a+b,0);
  if(metadata.delay.reduce((a,b)=>a+b,0)!==duration)throw Error('Review duration mismatch');
  const decoded=await sharp(path.join(dir,file),{animated:true}).ensureAlpha().raw().toBuffer();
  let elapsed=0,page=0,pageEnd=metadata.delay[0];
  for(let i=0;i<frames.length;i++){
   while(elapsed>=pageEnd){page++;pageEnd+=metadata.delay[page];}
   if(!decoded.subarray(page*frames[i].length,(page+1)*frames[i].length).equals(frames[i]))throw Error('Decoded review mismatch at sample '+i);
   elapsed+=delay[i];
  }
  outputs.push({file,source_samples:30,frames:metadata.pages,duration_ms:duration,delay:metadata.delay,
   bytes:fs.statSync(path.join(dir,file)).size,sha256:sha(fs.readFileSync(path.join(dir,file)))});
 }
 fs.copyFileSync(path.join(source,'shot-1280x720-820.png'),path.join(dir,'native-flight.png'));
 fs.writeFileSync(path.join(dir,'native-review-validation.json'),JSON.stringify({source:'Godot verify_batrafian_attack.gd',sources,outputs},null,2)+'\n');
 console.log(JSON.stringify(outputs.map(({file,frames,duration_ms,bytes})=>({file,frames,duration_ms,bytes}))));
}
main().catch(e=>{console.error(e);process.exitCode=1});
