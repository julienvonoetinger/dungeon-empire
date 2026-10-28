// Package existing prepared frames as animations; original image pixels untouched.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const dir=__dirname;
(async()=>{
 const raw=[];
 for(let i=0;i<8;i++)raw.push(await sharp(path.join(dir,`frames/walk-${i}.png`)).ensureAlpha().raw().toBuffer());
 for(const [name,delay] of [['walk-loop.webp',100],['walk-slow.webp',200]])
  await sharp(Buffer.concat(raw),{raw:{width:160,height:160*8,channels:4,pageHeight:160}}).webp({lossless:true,loop:0,delay}).toFile(path.join(dir,name));
 const native=[];
 for(let i=0;i<8;i++)native.push(await sharp(path.join(dir,`native/frame-${i}.png`)).ensureAlpha().raw().toBuffer());
 await sharp(Buffer.concat(native),{raw:{width:384,height:256*8,channels:4,pageHeight:256}}).webp({quality:92,loop:0,delay:100}).toFile(path.join(dir,'walk-in-dungeon.webp'));
 const m=await sharp(path.join(dir,'walk-loop.webp'),{animated:true}).metadata();
 if(m.pages!==8||m.pageHeight!==160||m.delay.some(d=>d!==100))throw Error('Incorrect animation timing');
 fs.writeFileSync(path.join(dir,'media-validation.json'),JSON.stringify({pages:m.pages,frameSize:[m.width,m.pageHeight],delays:m.delay,loop:m.loop,nativeFrames:8,animationBytes:fs.statSync(path.join(dir,'walk-loop.webp')).size},null,2));
 console.log('8-frame lossless WebP, 100ms/frame, infinite loop; native dungeon preview packaged.');
})().catch(e=>{console.error(e);process.exitCode=1});
