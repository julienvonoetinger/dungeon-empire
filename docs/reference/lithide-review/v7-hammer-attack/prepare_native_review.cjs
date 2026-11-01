// Assemble unedited native review screenshots with the real SpriteFrames timing.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
async function main(){
 const root=path.resolve(__dirname,'../../../..'),art=path.join(root,'artifacts/paladin-attack');
 const cfg=JSON.parse(fs.readFileSync(path.join(__dirname,'poses.json'))).actions.attack;
 const frames=[];
 for(let i=0;i<10;i++)frames.push(await sharp(path.join(art,`frame-${String(i).padStart(2,'0')}.png`)).ensureAlpha().raw().toBuffer());
 for(const [name,rate]of [['native-preview',1],['native-slow',2]])
  await sharp(Buffer.concat(frames),{raw:{width:1280,height:720*10,channels:4,pageHeight:720}})
   .webp({lossless:true,loop:0,delay:cfg.durations.map((d,i)=>d*rate+(i===9?1000:0))}).toFile(path.join(__dirname,name+'.webp'));
 for(const [i,name]of [[3,'native-windup.png'],[5,'native-impact.png']])fs.copyFileSync(path.join(art,`frame-${String(i).padStart(2,'0')}.png`),path.join(__dirname,name));
 console.log('Native attack review assembled');
}
main().catch(e=>{console.error(e);process.exitCode=1});
