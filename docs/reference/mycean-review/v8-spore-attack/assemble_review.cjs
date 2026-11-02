const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const root=path.resolve(__dirname,'../../../..'),native=path.join(root,'artifacts/mycean-attack/native');
async function main(){
 const frames=[];
 for(let i=0;i<36;i++)frames.push(await sharp(path.join(native,`motion-${String(i).padStart(2,'0')}.png`)).ensureAlpha().raw().toBuffer());
 for(const slow of [1,2]){
  const pages=[],delays=[];
  for(let i=0;i<frames.length;i++){
   // Samples0..1400ms. The last endpoint is held1s between review loops.
   const delay=i===frames.length-1?1000:40*slow;
   if(pages.length&&pages.at(-1).equals(frames[i]))delays[delays.length-1]+=delay;
   else{pages.push(frames[i]);delays.push(delay);}
  }
  const dest=path.join(__dirname,slow===1?'native-preview.webp':'native-slow.webp');
  await sharp(Buffer.concat(pages),{raw:{width:1280,height:720*pages.length,channels:4,pageHeight:720}}).webp({lossless:true,loop:0,delay:delays}).toFile(dest);
  const m=await sharp(dest,{animated:true}).metadata();
  if(m.delay.reduce((a,b)=>a+b,0)!==1400*slow+1000)throw Error('Review timeline changed');
 }
 for(const [source,dest] of [['shot-1280x720-550.png','charge.png'],['shot-1280x720-810.png','flight.png'],['shot-1280x720-1080.png','impact.png'],['shot-720x960-550.png','portrait.png'],['shot-844x390-650.png','landscape.png']])fs.copyFileSync(path.join(native,source),path.join(__dirname,dest));
 console.log('Native review:36samples, 2400/3800ms including1s endpoint pause.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
