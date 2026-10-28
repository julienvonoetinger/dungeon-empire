const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
(async()=>{
 for(const [prefix,name] of [['pose','native-loop.webp'],['ghost-pose','native-ghost-loop.webp']]){
  const frames=[];
  for(let i=0;i<8;i++)frames.push(await sharp(path.join(__dirname,'native-scene',`${prefix}-${String(i).padStart(2,'0')}.png`)).resize(960,675).ensureAlpha().raw().toBuffer());
  await sharp(Buffer.concat(frames),{raw:{width:960,height:675*8,channels:4,pageHeight:675}}).webp({lossless:true,loop:0,delay:Array(8).fill(125)}).toFile(path.join(__dirname,name));
 }
 console.log('NATIVE_PREVIEWS_OK');
})().catch(e=>{console.error(e);process.exitCode=1});
