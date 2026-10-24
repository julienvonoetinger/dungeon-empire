// Offline preparation for an appearance proposal. Preserve whole native alpha.
const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto');
const sharp = require('sharp');
const {writeGeneratedFile} = require('./write_generated_file.cjs');
const ROOT = path.resolve(__dirname, '..');
const REVIEW = 'docs/reference/mobile-light-review';
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const save = (file, data) => writeGeneratedFile(path.join(ROOT, REVIEW, file), data);

async function prepare() {
  const entries = [];
  for (const item of [
    {id:'torch', subjectHeight:88, anchor:[.50,.858], emission:[.50,.40], radius:190, energy:2.4, color:[1,.44,.12]},
    {id:'crystal', subjectHeight:54, anchor:[.50,.50], emission:[.50,.50], radius:140, energy:1.6, color:[.65,.24,1]}
  ]) {
    const source = `${REVIEW}/source/${item.id}.png`;
    const original = fs.readFileSync(path.join(ROOT, source));
    const {data,info} = await sharp(original).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let x0=info.width,y0=info.height,x1=-1,y1=-1;
    for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) if(data[(y*info.width+x)*4+3]>128) {
      x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);
    }
    if(y1<y0) throw Error('No opaque subject: '+source);
    // This threshold measures the solid subject only; all pixels including glow
    // remain in the uniformly resized full source. No trimming or recolouring.
    const targetHeight = Math.round(info.height*item.subjectHeight/(y1-y0+1));
    const {data:png,info:prepared} = await sharp(original).resize({height:targetHeight,kernel:'lanczos3'}).png().toBuffer({resolveWithObject:true});
    const size = [prepared.width,prepared.height];
    save(`prepared/${item.id}.png`,png);
    entries.push({...item,source,sourceSha256:hash(original),sourceSize:[info.width,info.height],
      measuredOpaqueBounds:[x0,y0,x1-x0+1,y1-y0+1],file:`${REVIEW}/prepared/${item.id}.png`,
      size,anchor:item.anchor.map((v,i)=>v*size[i]),emission:item.emission.map((v,i)=>v*size[i]),
      sha256:hash(png),bytes:png.length,displayedSubjectHeight:item.subjectHeight*.75});
  }
  // A functional light falloff texture, separate from artwork; prepared offline.
  const n=128, pixels=Buffer.alloc(n*n*4);
  for(let y=0;y<n;y++) for(let x=0;x<n;x++) {
    const r=Math.hypot((x+.5-n/2)/(n/2),(y+.5-n/2)/(n/2));
    const i=(y*n+x)*4, a=Math.max(0,1-r);
    pixels[i]=pixels[i+1]=pixels[i+2]=255; pixels[i+3]=Math.round(255*a*a);
  }
  save('prepared/light-falloff.png',await sharp(pixels,{raw:{width:n,height:n,channels:4}}).png().toBuffer());
  const atlas = fs.readFileSync(path.join(ROOT,'assets/dungeon/mobile-kit/atlas-256.png'));
  save('prepared.json',JSON.stringify({status:'appearance proposal only',density:256,zoom:.75,
    nativeAlphaPreserved:true,productionAtlasSha256:hash(atlas),entries},null,2)+'\n');
  console.log(entries.map(e=>`${e.id}: ${e.size.join('x')} px, ${e.bytes} bytes; subject ${e.displayedSubjectHeight} display px`).join('\n'));
}

async function boards() {
  const captures=path.join(ROOT,REVIEW,'captures');
  const crop={left:210,top:100,width:850,height:260};
  const dark=await sharp(path.join(captures,'without-local-light.png')).extract(crop).png().toBuffer();
  const lit=await sharp(path.join(captures,'with-local-light.png')).extract(crop).png().toBuffer();
  const labels=Buffer.from(`<svg width="890" height="624"><style>text{font:17px sans-serif;fill:#e5e8f3}</style><text x="20" y="28">Sprites seuls — taille de jeu</text><text x="20" y="338">Avec lumière locale — taille de jeu</text></svg>`);
  const board=await sharp({create:{width:890,height:624,channels:4,background:'#101522'}})
    .composite([{input:dark,left:20,top:42},{input:lit,left:20,top:352},{input:labels,left:0,top:0}]).png().toBuffer();
  save('comparison.png',board);
}
(process.argv.includes('--boards')?boards():prepare()).catch(error=>{console.error(error);process.exitCode=1;});
