// Compare complete ImageGen concepts without repainting their content.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const root=__dirname;
const items=[['01-singularite','A · La Singularité'],['02-vortex','B · Le Vortex vivant'],['03-faille','C · La Faille vivante']];
(async()=>{
 const layers=[],records=[];
 for(const [i,[id,title]]of items.entries()){
  const bytes=fs.readFileSync(path.join(root,'source',id+'.png')),meta=await sharp(bytes).metadata();
  layers.push({input:await sharp(bytes).resize(600,600,{fit:'contain',background:'#30343e'}).png().toBuffer(),left:i*600,top:70});
  layers.push({input:Buffer.from(`<svg width="600" height="70"><text x="300" y="46" text-anchor="middle" fill="#eee9e1" font-family="Segoe UI,Arial" font-size="27">${title}</text></svg>`),left:i*600,top:0});
  records.push({id,title,file:'source/'+id+'.png',prompt:'source/prompt-'+id+'.txt',width:meta.width,height:meta.height,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
 }
 await sharp({create:{width:1800,height:670,channels:4,background:'#30343e'}}).composite(layers).png().toFile(path.join(root,'propositions.png'));
 fs.writeFileSync(path.join(root,'images.json'),JSON.stringify({tool:'built-in ImageGen',purpose:'energy-being concept exploration, not runtime assets',records},null,2)+'\n');
 console.log('Three concepts archived and comparison prepared.');
})().catch(e=>{console.error(e);process.exitCode=1;});
