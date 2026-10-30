// Preserve native alpha; crop and uniformly reduce ImageGen source art only.
const fs=require('fs'), path=require('path'), crypto=require('crypto'), sharp=require('sharp');
const root=path.resolve(__dirname,'..');
async function prepareHeaderIcons(){
  const review=path.join(root,'docs/reference/interface-review/v15-dark-insignia');
  const out=path.join(root,'assets/ui/master/dark-icons'); fs.mkdirSync(out,{recursive:true});
  const records=[];
  for(const name of ['hourglass','raid','coins']){
    const source=path.join(review,'source',name+'.png');
    const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let left=info.width,top=info.height,right=-1,bottom=-1;
    for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8){left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y)}
    if(right<left)throw new Error('Empty source '+name);
    left=Math.max(0,left-4);top=Math.max(0,top-4);right=Math.min(info.width-1,right+4);bottom=Math.min(info.height-1,bottom+4);
    const crop={left,top,width:right-left+1,height:bottom-top+1};
    const file=path.join(out,name+'.png');
    await sharp(source).extract(crop).resize(60,60,{fit:'contain',background:'#00000000'}).extend({top:2,bottom:2,left:2,right:2,background:'#00000000'}).png().toFile(file);
    records.push({name,sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),crop,output:[64,64],pngBytes:fs.statSync(file).size});
  }
  const fontOut=path.join(root,'assets/ui/master/fonts');
  fs.mkdirSync(fontOut,{recursive:true});
  for(const file of ['Grenze.ttf','Grenze-OFL.txt'])fs.copyFileSync(path.join(review,'source',file),path.join(fontOut,file));
  const fontBytes=fs.readFileSync(path.join(fontOut,'Grenze.ttf'));
  const font={source:'https://github.com/google/fonts/tree/main/ofl/grenze',bytes:fontBytes.length,sha256:crypto.createHash('sha256').update(fontBytes).digest('hex'),license:'SIL OFL 1.1; Grenze-OFL.txt'};
  fs.writeFileSync(path.join(review,'preparation.json'),JSON.stringify({method:'alpha crop + uniform resize; no paint or color edits',records,rgbaBytes:3*64*64*4,font},null,2)+'\n');
  return records;
}
module.exports={prepareHeaderIcons};
if(require.main===module)prepareHeaderIcons().then(r=>console.log(JSON.stringify(r))).catch(e=>{console.error(e);process.exitCode=1});
