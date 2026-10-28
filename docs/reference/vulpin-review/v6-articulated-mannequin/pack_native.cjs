const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const dir=__dirname;
(async()=>{
 const frames=[];
 for(let i=0;i<49;i++)frames.push(await sharp(path.join(dir,`native/frame-${String(i).padStart(2,'0')}.png`)).extract({left:0,top:0,width:800,height:520}).ensureAlpha().raw().toBuffer());
 const delays=Array.from({length:49},(_,i)=>i===48?800:Math.round((i+1)*1000/30)-Math.round(i*1000/30));
 await sharp(Buffer.concat(frames),{raw:{width:800,height:520*49,channels:4,pageHeight:520}}).webp({quality:92,loop:1,delay:delays}).toFile(path.join(dir,'walk-in-dungeon.webp'));
 await sharp(frames[0],{raw:{width:800,height:520,channels:4}}).png().toFile(path.join(dir,'in-dungeon.png'));
 const meta=await sharp(path.join(dir,'walk-in-dungeon.webp'),{animated:true}).metadata();
 if(meta.pages!==49||meta.loop!==1||meta.delay.reduce((a,b)=>a+b,0)!==2400)throw Error('Native clip timing incorrect');
 console.log('Native WebP: 2 walk cycles then hold; one playback, no teleporting loop.');
})().catch(e=>{console.error(e);process.exitCode=1});
