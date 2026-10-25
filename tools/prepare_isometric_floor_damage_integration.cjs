// Read-only integrity observations and presentation of integrated floor artwork.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-floor-damage-review/v1/integration';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const region=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
async function main(){
 const old=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json'),current=read('assets/dungeon/isometric-kit/catalog.json');
 let retained=0;
 for(const [id,e] of Object.entries(old.atlas.regions)){
  const n=current.atlas.regions[id];if(!n)throw Error('Lost region '+id);
  const a=await sharp(abs(OUT+'/before/assets/dungeon/isometric-kit/atlas-256.png')).extract(region(e.region)).raw().toBuffer();
  const b=await sharp(abs('assets/dungeon/isometric-kit/atlas-256.png')).extract(region(n.region)).raw().toBuffer();
  if(!a.equals(b))throw Error('Retained pixels changed '+id);
  const {region:ar,...am}=e,{region:br,...bm}=n;
  if(JSON.stringify(am)!==JSON.stringify(bm))throw Error('Retained metadata changed '+id);
  retained++;
 }
 const selected=read('docs/reference/isometric-floor-damage-review/v1/selection.json');
 for(const [file,expected] of Object.entries(selected.reviewedFiles))if(hash(file)!==expected)throw Error('Selected source changed '+file);
 const prepared=read(OUT+'/prepared.json').items;
 let changedPixels=0,borderPixels=0,maxReconstructionRGBDifference=0;
 for(const item of prepared){
  const basePath='docs/reference/isometric-floor-variation-review/v1/integration/sprites/'+item.floorDamage.base+'.png';
  const base=await sharp(abs(basePath)).raw().toBuffer({resolveWithObject:true});
  const full=await sharp(abs(OUT+'/full-sprites/'+item.id+'.png')).raw().toBuffer();
  const {crop,hostFrame}=item.adaptation;
  const reconstructed=await sharp(abs(basePath)).composite([{input:abs(OUT+'/sprites/'+item.id+'.png'),left:crop.left,top:crop.top}]).raw().toBuffer();
  const normalized=await sharp({create:{width:270,height:138,channels:4,background:'#00000000'}}).composite([{input:abs(OUT+'/full-sprites/'+item.id+'.png')}]).raw().toBuffer();
  for(let k=0;k<normalized.length;k+=4){
   if(normalized[k+3]!==reconstructed[k+3])throw Error('Patch composition changed alpha '+item.id);
   if(normalized[k+3]===0)continue; // Hidden RGB is normalized differently by Sharp.
   for(let c=0;c<3;c++)maxReconstructionRGBDifference=Math.max(maxReconstructionRGBDifference,Math.abs(normalized[k+c]-reconstructed[k+c]));
  }
  if(maxReconstructionRGBDifference>1)throw Error('Visible patch reconstruction differs '+item.id);
  const packed=await sharp(abs('assets/dungeon/isometric-kit/atlas-256.png')).extract(region(current.atlas.regions[item.id].region)).raw().toBuffer();
  const expected=await sharp({create:{width:crop.width,height:crop.height,channels:4,background:'#00000000'}}).composite([{input:abs(OUT+'/sprites/'+item.id+'.png')}]).raw().toBuffer();
  if(!packed.equals(expected))throw Error('Patch atlas pixels differ '+item.id);
  for(let y=0;y<crop.height;y++)for(let x=0;x<crop.width;x++){
   const k=(y*crop.width+x)*4,j=((y+crop.top)*270+x+crop.left)*4;
   if(packed[k+3]>0&&base.data[j+3]!==255)throw Error('Overlay repeats host silhouette alpha '+item.id);
  }
  for(let y=0;y<138;y++)for(let x=0;x<270;x++){
   const k=(y*270+x)*4;
   if(full[k+3]!==base.data[k+3])throw Error('Host alpha changed');
   const changed=full[k]!==base.data[k]||full[k+1]!==base.data[k+1]||full[k+2]!==base.data[k+2];
   const X=x+.5+hostFrame[0],Y=y+.5+hostFrame[1],u=(X+2*Y)/256,v=(-X+2*Y)/256;
   if(Math.min(u,v,1-u,1-v)<.10){borderPixels++;if(changed)throw Error('Cell border changed');}
   if(changed){changedPixels++;if(x<crop.left+2||x>=crop.left+crop.width-2||y<crop.top+2||y>=crop.top+crop.height-2)throw Error('Changed overlay filter edge');}
  }
 }
 const evidence=read(OUT+'/observations.json'),obs=evidence.captures,find=n=>obs.find(o=>o.capture===n);
 if(!evidence.dictionaryOrderStable)throw Error('Dictionary order affected selection');
 for(const [a,b] of [['patch-seed17','patch-restored17'],['reference-seed17','reference-restored17']])if(hash(OUT+'/'+a+'.png')!==hash(OUT+'/'+b+'.png'))throw Error('Restored seed differs');
 if(hash(OUT+'/patch-seed17.png')===hash(OUT+'/patch-seed43.png'))throw Error('Seed has no effect');
 const anchor=p=>{const e=current.atlas.regions[p.id],x=p.position[0]-e.offset[0],y=p.position[1]-e.offset[1];return [(x+2*y)/256,(-x+2*y)/256];};
 for(const o of obs){
  const bases=o.placements.filter(p=>!p.id.includes('-damage-')),patches=o.placements.filter(p=>p.id.includes('-damage-'));
  const cells=new Set();
  for(const patch of patches){
   const at=anchor(patch),key=at.join(','),entry=current.atlas.regions[patch.id];
   if(!bases.some(b=>b.id===entry.floor_damage.base&&anchor(b).join(',')===key))throw Error('Missing matching B host');
   cells.add(key);
   for(const other of o.nonFloor){
    if(other.id==='heart'){
     const a=anchor(other),b=current.atlas.regions.heart.bounds;
     if(at[0]<a[0]+b.max[0]&&at[0]+1>a[0]+b.min[0]&&at[1]<a[1]+b.max[1]&&at[1]+1>a[1]+b.min[1])throw Error('Detail under heart');
    }else if(other.id.startsWith('door-')||other.id.startsWith('stair-')){
     if(anchor(other).join(',')===key)throw Error('Detail under special');
    }
   }
  }
  if(!['patch-samples','samples-close'].includes(o.capture))for(const key of cells){const [x,y]=key.split(',').map(Number);for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++)if((dx||dy)&&cells.has([x+dx,y+dy].join(',')))throw Error('Adjacent damage accents');}
  if(o.capture.startsWith('reference-')){
   const before=find('reference-before');
   if(JSON.stringify(o.nonFloor)!==JSON.stringify(before.nonFloor))throw Error('Nonfloor placement changed');
   if(JSON.stringify(bases)!==JSON.stringify(before.placements))throw Error('Clean host placement changed');
  }
 }
 if(find('reference-before').placements.some(p=>p.id.includes('-damage-')))throw Error('Disabled detail drawn');
 if(find('reference-no-corruption').placements.some(p=>/damage-[cd]$/.test(p.id)))throw Error('Disabled corruption drawn');
 const layers=[];let bg='<rect width="1320" height="490" fill="#0b1019"/><text x="22" y="35" font-size="24" fill="#edf1fa">Dalles B — quatre décors intégrés</text>';
 const labels=['A · Fissures courtes','B · Fracture ramifiée','C · Veine corrompue','D · Racines corrompues'];
 for(let i=0;i<4;i++){
  const x=i*330;bg+=`<text x="${x+16}" y="78" font-size="19" fill="#edf1fa">${labels[i]}</text><text x="${x+16}" y="310" font-size="15" fill="#a5b0c7">À l’échelle de jeu</text>`;
  for(const [width,top] of [[310,115],[203,337]])layers.push({input:await sharp(abs(OUT+'/full-sprites/'+prepared[i].id+'.png')).resize({width}).png().toBuffer(),left:x+Math.round((330-width)/2),top});
 }
 bg+='<text x="22" y="475" font-size="14" fill="#a5b0c7">Sources validées adaptées aux pierres B · Bords inchangés · Décors séparés dans le même atlas</text>';
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1320" height="490" style="font-family:Arial,sans-serif">${bg}</svg>`)).composite(layers).png().toFile(abs(OUT+'/prepared-comparison.png'));
 const sceneLayers=[];let scene='<rect width="1280" height="830" fill="#0b1019"/>';
 for(const [i,name] of ['reference-before','reference-seed17'].entries()){
  scene+=`<text x="20" y="${i*415+30}" font-size="23" fill="#edf1fa">${i?'Après · détails clairsemés':'Avant · dalles intactes'}</text>`;
  sceneLayers.push({input:await sharp(abs(OUT+'/'+name+'.png')).extract({left:40,top:170,width:1200,height:490}).resize({width:900}).png().toBuffer(),left:190,top:i*415+42});
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="830" style="font-family:Arial,sans-serif">${scene}</svg>`)).composite(sceneLayers).png().toFile(abs(OUT+'/scene-comparison.png'));
 const result={date:'2026-10-25',retainedRegions:retained,selectedHashes:Object.keys(selected.reviewedFiles).length,patches:prepared.length,changedPixels,unchangedBoundaryPixels:borderPixels,patchReconstructionAlphaExact:true,maxReconstructionRGBDifference,matchingHosts:true,seedRestorationIdentical:true,dictionaryOrderStable:true,nonFloorUnchanged:true,heartAndSpecialExclusions:true,neighbourExclusion:true,captures:obs.length,patchCounts:find('patch-seed17').counts,sixRoomCounts:find('six-room-native').counts,atlas:{regions:current.spriteCount,size:[current.atlas.width,current.atlas.height],pngBytes:current.atlas.sourceBytes,rgbaBytes:current.atlas.uncompressedRGBABytes}};
 fs.writeFileSync(abs(OUT+'/pixel-validation.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
