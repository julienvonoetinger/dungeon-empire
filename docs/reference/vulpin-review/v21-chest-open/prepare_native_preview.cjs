const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
(async()=>{
 const poses=JSON.parse(fs.readFileSync(path.join(__dirname,'poses.json'),'utf8'));
 const frames=[];
 for(let i=0;i<8;i++)frames.push(await sharp(path.join(__dirname,'native-scene',`pose-${String(i).padStart(2,'0')}.png`)).resize(960,675).ensureAlpha().raw().toBuffer());
 const delays=[...poses.durations_ms];delays[7]+=800;
 await sharp(Buffer.concat(frames),{raw:{width:960,height:675*8,channels:4,pageHeight:675}}).webp({lossless:true,loop:0,delay:delays}).toFile(path.join(__dirname,'native-preview.webp'));
 console.log('NATIVE_PREVIEW_OK');
})().catch(e=>{console.error(e);process.exitCode=1});
