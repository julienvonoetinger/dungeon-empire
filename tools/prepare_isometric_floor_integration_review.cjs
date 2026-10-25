// Read-only pixel/placement integrity evidence and presentation of actual art.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-floor-variation-review/v1/integration';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const region=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
const raw=p=>sharp(abs(p)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
async function main(){
 const old=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json'),current=read('assets/dungeon/isometric-kit/catalog.json');
 let retained=0;
 for(const [id,e] of Object.entries(old.atlas.regions)){
  const n=current.atlas.regions[id];if(!n)throw Error('Lost retained region '+id);
  const a=await sharp(abs(OUT+'/before/assets/dungeon/isometric-kit/atlas-256.png')).extract(region(e.region)).raw().toBuffer();
  const b=await sharp(abs('assets/dungeon/isometric-kit/atlas-256.png')).extract(region(n.region)).raw().toBuffer();
  if(!a.equals(b))throw Error('Retained pixels changed: '+id);
  const {region:ar,...am}=e,{region:br,...bm}=n;
  if(JSON.stringify(am)!==JSON.stringify(bm))throw Error('Retained metadata changed: '+id);
  retained++;
 }
 const selected=read('docs/reference/isometric-floor-variation-review/v1/selection.json');
 for(const [file,expected] of Object.entries(selected.reviewedFiles))if(hash(file)!==expected)throw Error('Selected reference changed: '+file);
 const images=await Promise.all([1,2,3,4].map(async v=>({v,...await raw(OUT+`/sprites/floor-b${v}.png`)})));
 const base=await raw('docs/reference/isometric-review/painted-v1/sprites/floor.png');
 for(const image of images){
  if(image.info.width!==270||image.info.height!==138)throw Error('Changed floor frame');
  for(let i=3;i<base.data.length;i+=4)if(base.data[i]!==image.data[i])throw Error('Changed floor alpha');
  const entry=current.atlas.regions['floor-b'+image.v];
  if(!entry)throw Error('Missing active floor region B'+image.v);
  const packed=await sharp(abs('assets/dungeon/isometric-kit/atlas-256.png')).extract(region(entry.region)).raw().toBuffer();
  // Atlas composition normalizes hidden RGB and rounds partial-alpha RGB.
  // Compare to the same transparent composition, then inspect packed pixels.
  const expected=await sharp({create:{width:270,height:138,channels:4,background:'#00000000'}})
   .composite([{input:abs(OUT+`/sprites/floor-b${image.v}.png`),left:0,top:0}]).raw().toBuffer();
  if(!packed.equals(expected))throw Error('Atlas does not contain current prepared floor B'+image.v);
  image.data=packed;
 }
 let samples=0,maxRGBDifference=0;
 for(const a of images)for(const b of images)for(const [dx,dy] of [[128,64],[-128,64],[0,128],[256,0]]){
  for(let y=0;y<138;y++)for(let x=0;x<270;x++){
   const X=x-dx,Y=y-dy;if(X<0||X>=270||Y<0||Y>=138)continue;
   const i=(y*270+x)*4,j=(Y*270+X)*4;
   if(a.data[i+3]<254||b.data[j+3]<254)continue;
   samples++;
   for(let c=0;c<3;c++)maxRGBDifference=Math.max(maxRGBDifference,Math.abs(a.data[i+c]-b.data[j+c]));
  }
 }
 if(maxRGBDifference>1||samples<8000)throw Error('Floor colour continuity failed: '+maxRGBDifference+'/'+samples);
 const observations=read(OUT+'/observations.json'),find=name=>observations.find(o=>o.capture===name);
 for(const pair of [['patch-seed17','patch-restored17'],['reference-seed17','reference-restored17']]){
  if(hash(OUT+'/'+pair[0]+'.png')!==hash(OUT+'/'+pair[1]+'.png'))throw Error('Seed restoration changed image: '+pair);
 }
 if(hash(OUT+'/patch-seed17.png')===hash(OUT+'/patch-seed43.png'))throw Error('Seed has no visible effect');
 for(const name of ['reference-seed17','reference-seed43','reference-restored17']){
  if(JSON.stringify(find(name).nonFloor)!==JSON.stringify(find('reference-before').nonFloor))throw Error('Non-floor placement changed '+name);
 }
 for(const o of observations.filter(o=>o.capture!=='reference-before')){
  if(Object.keys(o.counts).length!==4)throw Error('Arrangement missing from capture '+o.capture);
  const cells=new Map(o.placements.map(p=>{
   const x=p.position[0]+135,y=p.position[1]+5;
   return [[Math.round((x+2*y)/256),Math.round((-x+2*y)/256)].join(','),p.id];
  }));
  for(const [key,id] of cells){const [x,y]=key.split(',').map(Number);if(cells.get([x+1,y].join(','))===id)throw Error('Repeated horizontal neighbour '+key);}
 }
 const layers=[];let svg='<rect width="1320" height="580" fill="#0b1019"/><text x="24" y="36" font-size="25" fill="#edf1fa">Dalles B — quatre assemblages intégrés</text>';
 const labels=['B1 · Équilibré','B2 · Longues et courtes','B3 · Grande dalle','B4 · Assemblage composite'];
 for(let i=0;i<4;i++){
  const x=i*330;svg+=`<text x="${x+16}" y="80" font-size="19" fill="#edf1fa">${labels[i]}</text><text x="${x+16}" y="347" font-size="15" fill="#a5b0c7">Wireframe des joints</text>`;
  for(const [dir,top] of [['sprites',111],['overlays',367]])layers.push({input:await sharp(abs(OUT+`/${dir}/floor-b${i+1}.png`)).resize({width:306}).png().toBuffer(),left:x+12,top});
 }
 svg+='<text x="24" y="561" font-size="15" fill="#a5b0c7">Pierres entières aux raccords · Matière calme conservée · Même projection et même taille de case</text>';
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1320" height="580" style="font-family:Arial,sans-serif">${svg}</svg>`)).composite(layers).png().toFile(abs(OUT+'/prepared-comparison.png'));
 const comparison=[];let bg='<rect width="1280" height="830" fill="#0b1019"/>';
 for(const [i,name] of ['reference-before','reference-seed17'].entries()){
  bg+=`<text x="20" y="${i*415+30}" font-size="23" fill="#edf1fa">${i?'Après · assemblages B variés':'Avant · un seul motif'}</text>`;
  comparison.push({input:await sharp(abs(OUT+'/'+name+'.png')).extract({left:40,top:170,width:1200,height:490}).resize({width:900}).png().toBuffer(),left:190,top:i*415+42});
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="830" style="font-family:Arial,sans-serif">${bg}</svg>`)).composite(comparison).png().toFile(abs(OUT+'/scene-comparison.png'));
 const evidence={date:'2026-10-25',retainedRegions:retained,unchangedFloorSelectionFiles:Object.keys(selected.reviewedFiles).length,
  completeBoundaryPairs:32,diagonalCornerPairs:32,comparedOpaqueOverlapPixels:samples,maxRGBDifference,unchangedGeometricAlpha:true,
  seedRestorationIdentical:true,seed43Differs:true,nonFloorPlacementsUnchanged:true,captures:observations.length,
  negativePatchCounts:find('patch-seed17').counts,sixRoomCounts:find('six-room-native').counts,
  atlas:{regions:current.spriteCount,size:[current.atlas.width,current.atlas.height],pngBytes:current.atlas.sourceBytes,rgbaBytes:current.atlas.uncompressedRGBABytes}};
 fs.writeFileSync(abs(OUT+'/pixel-validation.json'),JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify(evidence));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
