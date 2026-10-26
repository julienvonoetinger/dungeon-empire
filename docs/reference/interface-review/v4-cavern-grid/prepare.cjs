const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
async function main(){
 const report=[];
 for(const [name,size] of [['ground',256],['dust',256],['outcrop',256],['rubble',256]]){
  const input=path.join(__dirname,`source/${name}-original.png`),{data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=info.width,y0=info.height,x1=-1,y1=-1,zero=0,partial=0;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){const a=data[(y*info.width+x)*4+3];if(a>0){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}else zero++;if(a>0&&a<255)partial++;}
  const crop={left:x0,top:y0,width:x1-x0+1,height:y1-y0+1};
  await sharp(input).extract(crop).resize({width:size}).png().toFile(path.join(__dirname,`assets/${name}.png`));
  report.push({name,source:[info.width,info.height],crop,nativeZeroAlphaPixels:zero,nativePartialAlphaPixels:partial,prepared:await sharp(path.join(__dirname,`assets/${name}.png`)).metadata()});
 }
 fs.writeFileSync(path.join(__dirname,'preparation.json'),JSON.stringify({method:'Native-alpha bounding crop and uniform downsample only. Ground is mapped once to XY in the review renderer; no raster painting.',assets:report},null,2));
 const tile=await sharp(path.join(__dirname,'assets/ground.png')).png().toBuffer();await sharp({create:{width:512,height:512,channels:4,background:'#202b3f'}}).composite([{input:tile,left:0,top:0},{input:tile,left:256,top:0},{input:tile,left:0,top:256},{input:tile,left:256,top:256}]).png().toFile(path.join(__dirname,'ground-repeat-check.png'));
 console.log(report.map(r=>({name:r.name,zero:r.nativeZeroAlphaPixels,partial:r.nativePartialAlphaPixels,size:[r.prepared.width,r.prepared.height]})));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
