// Appearance study only. Uniform reduction of complete native-alpha paintings;
// no perspective warp, thresholded cutout, recolouring or production replacement.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT=path.join(ROOT,'docs/reference/mobile-heart-review');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const names={a:'A · Vortex',b:'B · Noyau fissuré',c:'C · Éclipse'};
async function prepare(){
  const entries=[];
  for(const id of Object.keys(names)){
    const file=path.join(OUT,'source',id+'.png'),input=fs.readFileSync(file);
    const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    // Measure only opaque lower-half masonry, excluding the floating glow.
    // This never modifies alpha; every source pixel is retained by the resize.
    let left=info.width,right=-1,bottom=-1,transparent=0,partial=0;
    for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
      const alpha=data[(y*info.width+x)*4+3];
      if(alpha===0)transparent++;else if(alpha<255)partial++;
      if(y>=info.height*.58&&alpha>200){left=Math.min(left,x);right=Math.max(right,x);bottom=Math.max(bottom,y);}
    }
    if(right<left||transparent===0||partial===0)throw Error('Invalid native-alpha source '+id);
    const baseWidth=right-left+1,scale=208/baseWidth;
    const sourceAnchor=[(left+right+1)/2,bottom+1-256*.28/scale];
    const entry={id,name:names[id],source:'docs/reference/mobile-heart-review/source/'+id+'.png',sourceSha256:hash(file),sourceSize:[info.width,info.height],measuredBase:[left,right,bottom],sourceAnchor,footprint:[.8125,.56],supportHeight:.98,variants:[]};
    for(const density of [256,128]){
      const factor=scale*density/256,w=Math.round(info.width*factor),h=Math.round(info.height*factor);
      const png=await sharp(input).resize(w,h,{kernel:'lanczos3',fit:'inside'}).png().toBuffer();
      const output=`prepared/${id}-${density}.png`;
      write(path.join(OUT,output),png);
      entry.variants.push({density,file:'docs/reference/mobile-heart-review/'+output,size:[w,h],anchor:sourceAnchor.map(v=>v*w/info.width),bytes:png.length,rgbaBytes:w*h*4,displayBaseWidth:156,sourcePixelsPerCell:density});
    }
    entries.push(entry);
  }
  const baselinePaths=['assets/dungeon/mobile-kit/atlas-256.png','assets/dungeon/mobile-kit/catalog.tres','assets/dungeon/heart/heart.png','scenes/DungeonHeart.tscn'];
  const report={status:'unapproved-appearance-study',method:'Complete native-alpha source uniformly resized. No crop, alpha threshold, colour adjustment or perspective deformation.',worldPixelsPerCell:256,cameraZoom:.75,displayPixelsPerCell:192,baseWidthPixels:156,entries,baselineHashes:Object.fromEntries(baselinePaths.map(p=>[p,hash(path.join(ROOT,p))]))};
  write(path.join(OUT,'prepared.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({sprites:entries.length*2,entries:entries.map(e=>({id:e.id,variants:e.variants}))}));
}
async function boards(){
  const panels=[],width=1260,height=1154;
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Segoe UI,Arial,sans-serif" fill="#e7eaf4"><text x="20" y="30" font-size="23">Cœur du donjon · captures Godot à la taille de jeu</text>${Object.entries(names).map(([id,name],i)=>`<text x="${20+i*420}" y="66" font-size="21">${name}</text>`).join('')}<text x="20" y="602" font-size="19">Même cadrage · textures réduites de moitié (128 px/case au lieu de 256)</text><text x="20" y="1140" font-size="16" fill="#afbed4">192 pixels affichés par case · socle ≈ 156 pixels · aucune déformation du sprite</text></g></svg>`);
  for(const [i,id]of Object.keys(names).entries())for(const [row,density]of [256,128].entries()){
    panels.push({input:fs.readFileSync(path.join(OUT,`captures/${id}-${density}-center.png`)),left:i*420,top:row===0?82:620});
  }
  write(path.join(OUT,'comparison.png'),await sharp(bg).composite(panels).png().toBuffer());
  // First row alone: readable comparison without enlarged source art.
  write(path.join(OUT,'gameplay-comparison.png'),await sharp(path.join(OUT,'comparison.png')).extract({left:0,top:0,width,height:582}).png().toBuffer());
  const occlusion=[];
  for(const [i,id]of Object.keys(names).entries())for(const [row,placement]of ['north','south'].entries())occlusion.push({input:fs.readFileSync(path.join(OUT,`captures/${id}-256-${placement}.png`)),left:i*420,top:60+row*500});
  const ocbg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1260" height="1060"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" font-size="19" fill="#e7eaf4"><text x="20" y="27">Superpositions · près du mur arrière (haut), derrière le mur avant (bas)</text>${Object.values(names).map((n,i)=>`<text x="${20+i*420}" y="52">${n}</text>`).join('')}</g></svg>`);
  write(path.join(OUT,'occlusion-comparison.png'),await sharp(ocbg).composite(occlusion).png().toBuffer());
  console.log('Saved gameplay, density and wall-overlap comparisons.');
}
(process.argv.includes('--boards')?boards():prepare()).catch(e=>{console.error(e.stack);process.exitCode=1;});
