// Native screenshots only; unchanged existing core and Paladin art.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
async function main(){
 const root=path.resolve(__dirname,'../../../..'),art=path.join(root,'artifacts/paladin-core-attack');
 const registration=JSON.parse(fs.readFileSync(path.join(root,'assets/previews/paladin-attack/registration.json')));
 const frames=[];
 for(let i=0;i<10;i++)frames.push(await sharp(path.join(art,`frame-${String(i).padStart(2,'0')}.png`)).ensureAlpha().raw().toBuffer());
 const delay=registration.durations_ms.map((d,i)=>d+(i===9?1000:0));
 const file=path.join(__dirname,'preview.webp');
 await sharp(Buffer.concat(frames),{raw:{width:1280,height:7200,channels:4,pageHeight:720}}).webp({lossless:true,loop:0,delay}).toFile(file);
 const metadata=await sharp(file,{animated:true}).metadata();
 if(metadata.pages!==10||metadata.delay.reduce((a,b)=>a+b,0)!==1900)throw Error('Unexpected native animation timing');
 for(const [from,to]of [['frame-05.png','impact.png'],['ghost-contact.png','ghost-contact.png']])fs.copyFileSync(path.join(art,from),path.join(__dirname,to));
 console.log('PaladinCoreAttack native review: 10 frames / 1900ms including pause.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
