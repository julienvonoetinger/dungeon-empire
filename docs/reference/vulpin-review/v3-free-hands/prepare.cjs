// Presentation assets only: preserve generated pixels/alpha, crop and resize uniformly.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname, source=path.join(dir,'source/vulpin-original.png');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
(async()=>{
  const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let left=info.width,top=info.height,right=0,bottom=0,transparent=0;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
    const alpha=data[(y*info.width+x)*4+3];
    if(alpha===0)transparent++;
    if(alpha>8){left=Math.min(left,x);top=Math.min(top,y);right=Math.max(right,x);bottom=Math.max(bottom,y);}
  }
  if(!transparent)throw Error('Native alpha missing');
  left=Math.max(0,left-8);top=Math.max(0,top-8);right=Math.min(info.width-1,right+8);bottom=Math.min(info.height-1,bottom+8);
  // Preserve the preceding full source-frame registration when removing weapons.
  const base=JSON.parse(fs.readFileSync(path.join(dir,'../v2-approved-design/asset.json')));
  // Allow the one-pixel canvas change; registration remains visually estimated.
  if(Math.abs(info.width-base.source_size[0])>2||info.height!==base.source_size[1])throw Error('Edited canvas changed; review anchor first');
  const crop={left:Math.min(left,base.crop.left),top:Math.min(top,base.crop.top)};
  crop.width=Math.max(right+1,base.crop.left+base.crop.width)-crop.left;
  crop.height=Math.max(bottom+1,base.crop.top+base.crop.height)-crop.top;
  left=crop.left;top=crop.top;
  const scale=base.scale;
  const width=Math.round(crop.width*scale),height=Math.round(crop.height*scale);
  if(width>128||height>128)throw Error('Shared scale exceeds sprite canvas');
  const padLeft=Math.floor((128-width)/2),padTop=Math.floor((128-height)/2);
  const sprite=await sharp(source).extract(crop).resize(width,height,{fit:'inside'}).png().toBuffer();
  await sharp({create:{width:128,height:128,channels:4,background:'#00000000'}}).composite([{input:sprite,left:padLeft,top:padTop}]).png().toFile(path.join(dir,'vulpin-128.png'));
  await sharp(source).extract(crop).resize({height:420}).png().toFile(path.join(dir,'vulpin-detail.png'));
  // Artist-estimated midpoint of the two visible boot soles, not calibrated 3D.
  const sourceAnchor=[700,1055];
  const anchor=[padLeft+(sourceAnchor[0]-left)*scale,padTop+(sourceAnchor[1]-top)*scale];
  const record={status:'User-requested empty hands; static proposal, not yet approved or integrated',tool:'Built-in ImageGen',source:'source/vulpin-original.png',source_sha256:hash(source),prompt:'source/prompt.txt',source_size:[info.width,info.height],crop,sprite:'vulpin-128.png',sprite_size:[128,128],sprite_bytes:fs.statSync(path.join(dir,'vulpin-128.png')).size,rgba_bytes:128*128*4,anchor,sourceAnchor,scale,visible_height:height,native_alpha:true,preparation:'Uniform resize and transparent framing only; no repaint, warp or mirroring',reference_images:['docs/reference/hero-concepts-2d-2026-10-21/heroes-comparison.png','docs/reference/hero-concepts-2d-2026-10-21/vulpin-scene.png','docs/reference/vulpin-review/v2-approved-design/source/vulpin-original.png']};
  fs.writeFileSync(path.join(dir,'asset.json'),JSON.stringify(record,null,2)+'\n');
  console.log(record);
})().catch(error=>{console.error(error);process.exitCode=1;});
