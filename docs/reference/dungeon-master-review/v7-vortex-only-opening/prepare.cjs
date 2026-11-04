// Encode native Godot viewport captures; no generated-painting animation.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const root=__dirname,repo=path.resolve(root,'../../../..');
(async()=>{
 const frames=[],delays=[];
 for(let i=0;i<360;i++){
  frames.push(await sharp(path.join(repo,'artifacts/energy-master/frames',String(i).padStart(3,'0')+'.png')).ensureAlpha().raw().toBuffer());
  delays.push(Math.round((i+1)*1000/15)-Math.round(i*1000/15));
 }
 const out=path.join(root,'animation.webp');
 await sharp(Buffer.concat(frames),{raw:{width:480,height:480*360,channels:4,pageHeight:480}}).webp({quality:85,effort:3,loop:0,delay:delays}).toFile(out);
 const meta=await sharp(out,{animated:true}).metadata();
 if(meta.delay.reduce((a,b)=>a+b,0)!==24000)throw new Error('Animation duration changed');
 fs.copyFileSync(path.join(repo,'artifacts/energy-master/1280x720.png'),path.join(root,'landscape.png'));
 fs.copyFileSync(path.join(repo,'artifacts/energy-master/390x844.png'),path.join(root,'portrait.png'));
 console.log(JSON.stringify({file:out,bytes:fs.statSync(out).size,frames:meta.pages,duration:meta.delay.reduce((a,b)=>a+b,0)}));
})().catch(e=>{console.error(e);process.exitCode=1;});
