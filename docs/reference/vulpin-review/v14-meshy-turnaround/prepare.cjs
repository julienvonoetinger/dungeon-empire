const fs=require('fs');
const path=require('path');
const crypto=require('crypto');
const sharp=require('sharp');
const root=__dirname;
const brief=JSON.parse(fs.readFileSync(path.join(root,'brief.json'),'utf8'));
const chosen=[['front.png','01-face.png','FACE'],['left.png','02-profil-gauche.png','PROFIL GAUCHE'],['back.png','03-dos.png','DOS'],['right.png','04-profil-droit.png','PROFIL DROIT']];
async function main(){
 for(const s of brief.sources)fs.copyFileSync(s.generated,path.join(root,'source',s.file));
 const exportDir=path.join(root,'meshy'); fs.mkdirSync(exportDir,{recursive:true});
 const layers=[], stats=[];
 for(let i=0;i<chosen.length;i++){
  const [src,name,label]=chosen[i]; const source=path.join(root,'source',src); const output=path.join(exportDir,name);
  fs.copyFileSync(source,output);
  const m=await sharp(output).metadata(); const raw=await sharp(output).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let transparent=0,minX=m.width,minY=m.height,maxX=-1,maxY=-1;
  for(let y=0;y<m.height;y++)for(let x=0;x<m.width;x++){const a=raw.data[(y*m.width+x)*4+3];if(a===0)transparent++;if(a>8){minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}}
  const bytes=fs.statSync(output).size;
  if(!m.hasAlpha||transparent===0||bytes>=20*1024*1024)throw Error('Invalid Meshy image '+name);
  stats.push({name,width:m.width,height:m.height,bytes,transparentPixels:transparent,boundsAlpha8:[minX,minY,maxX,maxY],sha256:crypto.createHash('sha256').update(fs.readFileSync(output)).digest('hex')});
  const thumb=await sharp(output).resize(500,500,{fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
  layers.push({input:thumb,left:30+i*500,top:90});
  const labelSvg=Buffer.from(`<svg width="500" height="50"><text x="250" y="33" text-anchor="middle" font-family="Segoe UI,Arial" font-size="20" fill="#e9e8df">${label}</text></svg>`);
  layers.push({input:labelSvg,left:30+i*500,top:40});
 }
 await sharp({create:{width:2060,height:630,channels:4,background:'#202836'}}).composite(layers).png().toFile(path.join(root,'apercu.png'));
 fs.writeFileSync(path.join(root,'validation.json'),JSON.stringify({images:stats,export:'Byte-identical selected generated sources; no art edits or distortion in preparation.',inspection:'All four views inspected visually; front tail and rear heels corrected via ImageGen.',limits:brief.limits},null,2)+'\n');
 console.log(JSON.stringify(stats,null,2));
}
main().catch(e=>{console.error(e);process.exit(1)});
