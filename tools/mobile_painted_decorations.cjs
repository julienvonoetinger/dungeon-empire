// Offline preparation of native-alpha ImageGen proposals. No colour correction,
// background extraction, shape mask or perspective repair. Originals stay intact.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {hash}=require('./painted_material_renderer.cjs');
const ROOT=path.resolve(__dirname,'..'),REVIEW='docs/reference/mobile-decoration-review';

async function paintedDecorations() {
  const items=[];
  for(const variant of ['a','b','c']) {
    const source=`${REVIEW}/source/${variant}.png`,original=fs.readFileSync(path.join(ROOT,source));
    const {data,info}=await sharp(original).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let x0=info.width,y0=info.height,x1=-1,y1=-1;
    for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8) {
      x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
    }
    if(x1<x0)throw Error(`No visible decoration in ${source}`);
    // Threshold is used ONLY to measure/centre the visible subject. The complete
    // source (including every faint native-alpha pixel) is resized and retained.
    const frame=68,content=44,S=4,factor=content*S/Math.max(x1-x0+1,y1-y0+1);
    const w=Math.round(info.width*factor),h=Math.round(info.height*factor);
    const left=Math.round(frame*S/2-(x0+x1+1)/2*factor),top=Math.round(frame*S/2-(y0+y1+1)/2*factor);
    if(left<0||top<0||left+w>frame*S||top+h>frame*S)throw Error(`Source margin exceeds prepared frame: ${source}`);
    const reduced=await sharp(original).resize(w,h,{kernel:'lanczos3'}).png().toBuffer();
    const png=await sharp({create:{width:frame*S,height:frame*S,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:reduced,left,top}]).png().toBuffer();
    const id='decor-'+variant;
    const preview=await sharp(png).resize(frame,frame).png().toBuffer();
    writeGeneratedFile(path.join(ROOT,'docs/reference/mobile-optimization/sprites/'+id+'.png'),preview);
    writeGeneratedFile(path.join(ROOT,REVIEW,'prepared',id+'.png'),preview);
    items.push({id,png,frame:[-frame/2,-frame/2,frame,frame],decorationSource:{variant,source,sha256:hash(original),sourceSize:[info.width,info.height],visibleBounds:[x0,y0,x1-x0+1,y1-y0+1],nativeAlphaPreserved:true,framePixels:frame,subjectPixels:content,status:'appearance_proposal'}});
  }
  return items;
}
module.exports={paintedDecorations};
