// Review layout only. Whole native ImageGen paintings are not retouched.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const root=__dirname;
const variants=[['01-titan','A · Le Titan des profondeurs'],['02-roi-creux','B · Le Roi creux'],['03-presence','C · La Présence'],['04-primordial','D · L’Ancêtre primordial']];
(async()=>{
 const layers=[],records=[];
 for(const [i,[id,title]]of variants.entries()){
  const file=path.join(root,'source',id+'.png'),bytes=fs.readFileSync(file),m=await sharp(bytes).metadata();
  if(!m.hasAlpha)throw new Error(id+' lacks native alpha');
  const x=(i%2)*720,y=Math.floor(i/2)*790;
  layers.push({input:await sharp(bytes).resize(700,700,{fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer(),left:x+10,top:y+65});
  layers.push({input:Buffer.from(`<svg width="720" height="65"><text x="360" y="43" text-anchor="middle" fill="#eee9e1" font-family="Segoe UI,Arial" font-size="27">${title}</text></svg>`),left:x,top:y});
  records.push({id,title,file:'source/'+id+'.png',prompt:'source/prompt-'+id+'.txt',width:m.width,height:m.height,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
 }
 await sharp({create:{width:1440,height:1580,channels:4,background:'#343842'}}).composite(layers).png().toFile(path.join(root,'propositions.png'));
 fs.writeFileSync(path.join(root,'images.json'),JSON.stringify({tool:'built-in ImageGen',purpose:'exploratory design proposals, not Meshy turnaround views',records},null,2)+'\n');
 console.log('Four original concepts archived; review board created.');
})().catch(e=>{console.error(e);process.exitCode=1;});
