// Package captured native frames only; never paints or changes game textures.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),out=path.join(root,'docs/reference/interface-review/v16-living-eye');
const names=['veille','observe','traque','jubile','blesse','fauche','colere'];
(async()=>{
  const report=[];
  for(const name of names){
    const count=name==='traque'?60:20, frames=[];
    for(let i=0;i<count;i++) frames.push(await sharp(path.join(root,`artifacts/master-eye/frames/${name}-${String(i).padStart(3,'0')}.png`)).ensureAlpha().raw().toBuffer({resolveWithObject:true}));
    const {width,height}=frames[0].info;
    await sharp(Buffer.concat(frames.map(f=>f.data)),{raw:{width,height:height*count,channels:4,pageHeight:height}}).webp({lossless:true,loop:0,delay:Array(count).fill(100)}).toFile(path.join(out,`${name}.webp`));
    report.push({name,width,height,frames:count,bytes:fs.statSync(path.join(out,`${name}.webp`)).size});
  }
  fs.writeFileSync(path.join(out,'media.json'),JSON.stringify(report,null,2)+'\n');
  console.log(report);
})().catch(e=>{console.error(e);process.exit(1)});
