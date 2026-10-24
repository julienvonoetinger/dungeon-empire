// Compare one revised complete sprite, retaining the rejected A/B/C sources.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const RITUAL=process.argv.includes('--ritual-v3');
const ROOT=path.resolve(__dirname,'..'),BASE='docs/reference/mobile-heart-review',REL=BASE+(RITUAL?'/ritual-v3':'/perspective-v2'),OUT=path.join(ROOT,REL);
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,p))).digest('hex');
async function prepare(){
  const file=path.join(OUT,'source/a.png'),original=fs.readFileSync(file);
  const {data,info}=await sharp(original).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let left=info.width,right=-1,bottom=-1;
  for(let y=Math.floor(info.height*.60);y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>200){left=Math.min(left,x);right=Math.max(right,x);bottom=Math.max(bottom,y);}
  if(right<left)throw Error('No opaque base found');
  const factor=208/(right-left+1),anchor=[(left+right+1)/2,bottom+1-104/factor];
  const entry={id:'a',name:RITUAL?'A · Socle rituel sculpté':'A · Socle à plat',source:REL+'/source/a.png',sourceSha256:hash(REL+'/source/a.png'),sourceSize:[info.width,info.height],measuredBase:[left,right,bottom],sourceAnchor:anchor,footprint:[.8125,.8125],supportHeight:.98,variants:[]};
  for(const density of [256,128]){
    const width=Math.round(info.width*factor*density/256);
    const png=await sharp(original).resize({width,kernel:'lanczos3'}).png().toBuffer();
    const dimensions=await sharp(png).metadata();
    const file=`${REL}/prepared/a-${density}.png`;
    write(path.join(ROOT,file),png);
    entry.variants.push({density,file,size:[dimensions.width,dimensions.height],anchor:anchor.map(v=>v*width/info.width),bytes:png.length,rgbaBytes:dimensions.width*dimensions.height*4,displayBaseWidth:156,sourcePixelsPerCell:density});
  }
  const baseline=JSON.parse(fs.readFileSync(path.join(ROOT,BASE,'prepared.json'))).baselineHashes;
  for(const [p,h]of Object.entries(baseline))if(hash(p)!==h)throw Error('Active reference changed '+p);
  write(path.join(OUT,'prepared.json'),JSON.stringify({status:RITUAL?'unapproved-sculpted-pedestal':'unapproved-perspective-correction',method:'Uniform reduction of entire native-alpha sprite; measured base and square support bounds, no runtime perspective warp.',cameraZoom:.75,displayPixelsPerCell:192,entries:[entry],baselineHashes:baseline},null,2)+'\n');
  console.log(JSON.stringify(entry.variants));
}
async function boards(){
  const before=RITUAL?'Avant · socle simple':'Avant · dessus écrasé en profondeur';
  const after=RITUAL?'Proposition · socle rituel sculpté':'Proposition · dessus vu à plat';
  const svg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="840" height="620"><rect width="100%" height="100%" fill="#080e19"/><g fill="#e7eaf4" font-family="Segoe UI,Arial,sans-serif"><text x="20" y="30" font-size="23">Même largeur de socle · même distance de jeu</text><text x="20" y="66" font-size="20">${before}</text><text x="440" y="66" font-size="20">${after}</text><text x="20" y="606" font-size="16" fill="#adbbd1">Socle ≈ 156 px · 192 px par case · captures Godot sans redimensionnement</text></g></svg>`);
  const previous=path.join(ROOT,BASE,RITUAL?'perspective-v2':'','captures/a-256-center.png');
  const panels=[{input:fs.readFileSync(previous),left:0,top:82},{input:fs.readFileSync(path.join(OUT,'captures/a-256-center.png')),left:420,top:82}];
  write(path.join(OUT,'before-after.png'),await sharp(svg).composite(panels).png().toBuffer());
  console.log('Saved '+REL+'/before-after.png');
}
(process.argv.includes('--boards')?boards():prepare()).catch(e=>{console.error(e.stack);process.exitCode=1;});
