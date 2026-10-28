const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
async function main(){
  const dir=__dirname,poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'),'utf8'));
  const overview=[],detail=[];
  for(let i=0;i<10;i++){
    const input=path.join(dir,'native-scene',`pose-${String(i).padStart(2,'0')}.png`);
    overview.push(await sharp(input).extract({left:0,top:0,width:1280,height:826}).raw().toBuffer());
    detail.push(await sharp(input).extract({left:16,top:60,width:616,height:377}).raw().toBuffer());
  }
  const timing=poses.durations_ms.map((ms,i)=>ms+(i===9?1200:0));
  for(const [name,frames,width,height,delay] of [
    ['native-fall.webp',overview,1280,826,timing],
    ['native-fall-detail.webp',detail,616,377,timing],
    ['native-fall-slow.webp',detail,616,377,timing.map(ms=>ms*2)]]){
    await sharp(Buffer.concat(frames),{raw:{width,height:height*frames.length,channels:4,pageHeight:height}})
      .webp({lossless:true,loop:0,delay}).toFile(path.join(dir,name));
  }
  console.log('Native overview, detail and half-speed previews saved.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
