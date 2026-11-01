// Native-alpha ImageGen art: crop and uniform reduction, no repaint or recolor.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
async function prepareDigIcon(){
  const review=path.join(root,'docs/reference/interface-review/v23-dark-dig-icon');
  const source=path.join(review,'source/dig.png');
  const output=path.join(root,'assets/ui/master/dark-icons/dig.png');
  const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let left=info.width,top=info.height,right=-1,bottom=-1;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8){left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);}
  if(right<left)throw new Error('Empty source');
  left=Math.max(0,left-4);top=Math.max(0,top-4);right=Math.min(info.width-1,right+4);bottom=Math.min(info.height-1,bottom+4);
  const crop={left,top,width:right-left+1,height:bottom-top+1};
  fs.mkdirSync(path.dirname(output),{recursive:true});
  await sharp(source).extract(crop).resize(60,60,{fit:'contain',background:'#00000000'}).extend({left:2,right:2,top:2,bottom:2,background:'#00000000'}).png().toFile(output);
  const record={tool:'Built-in ImageGen',method:'alpha crop + uniform resize, no paint edits',source:'source/dig.png',prompt:'source/dig.prompt.txt',sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),crop,output:'assets/ui/master/dark-icons/dig.png',size:[64,64],pngBytes:fs.statSync(output).size,rgbaBytes:64*64*4};
  fs.writeFileSync(path.join(review,'preparation.json'),JSON.stringify(record,null,2)+'\n');
  return record;
}
module.exports={prepareDigIcon};
if(require.main===module)prepareDigIcon().then(r=>console.log(JSON.stringify(r))).catch(error=>{console.error(error);process.exitCode=1;});
