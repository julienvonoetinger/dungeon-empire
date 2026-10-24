// Offline painted top replacement. The generated source supplies the recessed
// carving and surrounding stone; the existing pillar supplies the exact rim.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const {writeGeneratedFile} = require('./write_generated_file.cjs');
const {hash, SCALE} = require('./painted_material_renderer.cjs');
const ROOT = path.resolve(__dirname, '..');
const REVIEW = 'docs/reference/pillar-cap-review';
const write = (file, data) => writeGeneratedFile(path.join(ROOT, file), data);
const smooth = t => {t=Math.max(0,Math.min(1,t));return t*t*(3-2*t);};

async function paintedPillarCap(base, topFace) {
  const source = `${REVIEW}/source/carved-top.png`;
  const original = fs.readFileSync(path.join(ROOT, source));
  const [minX, minY, maxX, maxY] = [0,1,0,1].map((axis,i) => Math[i<2?'min':'max'](...topFace.points.map(p => p[axis])));
  // Same origin and even dimensions as the base: both atlas densities retain
  // the same pixel phase. No independent bounding-box alignment at runtime.
  const frame = [base.frame[0], base.frame[1], 68, 68];
  const width = frame[2]*SCALE, height = frame[3]*SCALE;
  const baseRaw = await sharp(base.png).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const material = await sharp(original).resize(1024,1024,{fit:'fill'}).removeAlpha().raw().toBuffer();
  const data = Buffer.alloc(width*height*4);
  for(let y=0;y<height;y++) for(let x=0;x<width;x++) {
    const wx=frame[0]+(x+.5)/SCALE, wy=frame[1]+(y+.5)/SCALE;
    const distance=Math.min(wx-minX,maxX-wx,wy-minY,maxY-wy);
    if(distance<=0)continue;
    const k=(y*width+x)*4,b=(y*baseRaw.info.width+x)*4;
    if(baseRaw.data[b+3]!==255)continue;
    const u=Math.min(1023,Math.max(0,Math.floor((wx-minX)/(maxX-minX)*1024)));
    const v=Math.min(1023,Math.max(0,Math.floor((wy-minY)/(maxY-minY)*1024)));
    // The same original bevel surrounds every cap. This narrow transition is
    // on quiet stone, outside the carved diamond; it never moves a guide line.
    const mix=smooth((distance-3)/3);
    for(let c=0;c<3;c++)data[k+c]=Math.round(baseRaw.data[b+c]*(1-mix)+material[(v*1024+u)*3+c]*mix);
    data[k+3]=255;
  }
  const png=await sharp(data,{raw:{width,height,channels:4}}).png().toBuffer();
  const densityPng={}, audits=[];
  for(const density of [128,256]) {
    const factor=density/256,w=frame[2]*factor,h=frame[3]*factor;
    const cap=await sharp(png).resize(w,h,{kernel:'lanczos3'}).raw().toBuffer();
    const basePNG=await sharp(base.png).resize(base.frame[2]*factor,base.frame[3]*factor,{kernel:'lanczos3'}).png().toBuffer();
    const basePixels=await sharp(basePNG).raw().toBuffer();
    const bw=base.frame[2]*factor;
    for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
      const wx=frame[0]+(x+.5)/factor,wy=frame[1]+(y+.5)/factor;
      const d=Math.min(wx-minX,maxX-wx,wy-minY,maxY-wy),k=(y*w+x)*4;
      // A cap cannot add alpha to a structural edge. Suppress resampling tails
      // at both export densities; underlying base already contains the rim.
      if(d<=3||basePixels[(y*bw+x)*4+3]!==255)cap.fill(0,k,k+4);
    }
    densityPng[density]=await sharp(cap,{raw:{width:w,height:h,channels:4}}).png().toBuffer();
    const combined=await sharp(basePNG).composite([{input:densityPng[density],left:0,top:0}]).png().toBuffer();
    const combinedRaw=await sharp(combined).raw().toBuffer();
    // Compare equal compositor paths: libvips can round RGB under partial alpha
    // even for a transparent overlay. Those edge changes are not cap pixels.
    const transparent=await sharp({create:{width:w,height:h,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).png().toBuffer();
    const referenceRaw=await sharp(basePNG).composite([{input:transparent,left:0,top:0}]).raw().toBuffer();
    let alphaDifferences=0,changedOutsideTop=0,changedPixels=0;
    for(let k=0;k<basePixels.length;k+=4) {
      if(basePixels[k+3]!==combinedRaw[k+3])alphaDifferences++;
      if(referenceRaw.subarray(k,k+4).equals(combinedRaw.subarray(k,k+4)))continue;
      changedPixels++;
      const x=(k/4)%bw,y=Math.floor(k/4/bw),wx=frame[0]+(x+.5)/factor,wy=frame[1]+(y+.5)/factor;
      if(Math.min(wx-minX,maxX-wx,wy-minY,maxY-wy)<=3)changedOutsideTop++;
    }
    audits.push({density,alphaDifferences,changedOutsideTop,changedPixels,rgbReference:'same compositor with a transparent cap'});
    write(`${REVIEW}/prepared/pillar-carved-${density}.png`,combined);
    write(`${REVIEW}/prepared/top-carved-${density}.png`,densityPng[density]);
  }
  write(`${REVIEW}/prepared/top-source-mapped.png`,png);
  write('docs/reference/mobile-optimization/sprites/pillar-top-carved.png',densityPng[256]);
  const capSource={source,sha256:hash(original),baseSha256:hash(base.png),frame,topBounds:[minX,minY,maxX,maxY],preservedRim:3,blendWidth:3,audits,status:'appearance_proposal'};
  write(`${REVIEW}/preparation.json`,JSON.stringify(capSource,null,2)+'\n');
  return {id:'pillar-top-carved',frame,png,densityPng,capSource};
}
module.exports={paintedPillarCap};
