// Artifact integrity and an offline montage of the actual atlas/scene inventory.
// This is not a GPU capture. No source pixels are repainted or alpha-masked.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/treasure-chest-review/v2/integration';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const rect=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
const write=(p,b)=>fs.writeFileSync(abs(OUT+'/'+p),b);
async function main(){
 const baseline=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json'),current=read('assets/dungeon/isometric-kit/catalog.json');
 const atlas='assets/dungeon/isometric-kit/atlas-256.png',regions=current.atlas.regions;
 let retained=0;
 for(const [id,e] of Object.entries(baseline.atlas.regions)){
  const n=regions[id];if(!n)throw Error('Lost original region '+id);
  const old=await sharp(abs(OUT+'/before/'+atlas)).extract(rect(e.region)).raw().toBuffer();
  const now=await sharp(abs(atlas)).extract(rect(n.region)).raw().toBuffer();
  if(!old.equals(now)||JSON.stringify(e)!==JSON.stringify(n))throw Error('Original art/metadata changed '+id);
  retained++;
 }
 const selection=read('docs/reference/treasure-chest-review/v2/selection.json');
 for(const [p,h] of Object.entries(selection.reviewedFiles))if(hash(p)!==h)throw Error('Selected chest changed '+p);
 if(hash('project.godot')!==hash(OUT+'/before/project.godot'))throw Error('User project settings changed');
 async function raster(id,scale){
  const e=regions[id],file=(e.atlas_path??'res://'+atlas).replace('res://','');
  return sharp(abs(file)).extract(rect(e.region)).resize(Math.max(1,Math.round(e.size[0]*scale)),Math.max(1,Math.round(e.size[1]*scale))).png().toBuffer();
 }
 async function sample(id,scale){
  const W=700,H=500,cx=350,cy=310,layers=[];
  const add=async(key,anchor)=>{const e=regions[key];layers.push({input:await raster(key,scale),left:Math.round(anchor[0]+e.offset[0]*scale),top:Math.round(anchor[1]+e.offset[1]*scale)});};
  await add('floor-b1',[cx,cy-64*scale]);
  await add(regions[id].ground_effects[0],[cx,cy]);
  await add(id,[cx,cy]);
  const buffer=await sharp({create:{width:W,height:H,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer();
  return sharp(buffer).extract({left:198,top:140,width:304,height:230}).png().toBuffer();
 }
 const W=660,H=650,layers=[];
 let svg='<rect width="660" height="650" fill="#0b1019"/><text x="24" y="35" fill="#f0e7d5" font-size="25">Deux coffres, deux états lisibles</text><text x="24" y="65" fill="#a8b1c5" font-size="15">Sprites et ombres préparés · même échelle de jeu</text>';
 for(const [i,id] of ['prop-chest-open','prop-chest'].entries()){
  const x=18+i*324,label=i?'Verrou actif · sceau violet':'Gratuit · sans protection';
  svg+=`<text x="${x+4}" y="105" font-size="18" fill="#f0e7d5">${label}</text><text x="${x+4}" y="130" font-size="13" fill="#a8b1c5">Échelle de jeu · corps ≈96 px</text><text x="${x+4}" y="386" font-size="13" fill="#a8b1c5">Agrandissement ×2</text>`;
  layers.push({input:await sample(id,.75),left:x,top:138});
  layers.push({input:await sample(id,1.5),left:x,top:395});
 }
 svg+='<text x="24" y="643" font-size="12" fill="#a8b1c5">Montage depuis l’atlas · pas une capture Godot · pièces redessinées plus petites</text>';
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" style="font-family:Arial,sans-serif">${svg}</svg>`)).composite(layers).png().toFile(abs(OUT+'/comparison.png'));
 const observations=read(OUT+'/scene-inventory.json').captures;
 const state=observations.find(s=>s.capture==='four-chests'),zoom=.75;
 const min=[0,1].map(a=>Math.min(...state.sprites.map(s=>s.position[a]))),max=[0,1].map(a=>Math.max(...state.sprites.map(s=>s.position[a]+s.size[a])));
 const width=Math.ceil((max[0]-min[0])*zoom)+48,height=Math.ceil((max[1]-min[1])*zoom)+90;
 const sceneLayers=[];
 for(const s of state.sprites){
  // Chest ground effects fit their host cell. Other effects here are the heart's
  // existing floor effects; the open review room contains their receivers.
  sceneLayers.push({input:await raster(s.id,zoom),left:Math.round((s.position[0]-min[0])*zoom)+24,top:Math.round((s.position[1]-min[1])*zoom)+24});
 }
 let captions='';
 for(const l of state.labels)captions+=`<text x="${(l.position[0]+l.width/2-min[0])*zoom+24}" y="${(l.position[1]-min[1])*zoom+38}" text-anchor="middle" fill="#f4e5bd" stroke="#101522" stroke-width="3" paint-order="stroke" font-size="13">${l.text}</text>`;
 captions+=`<text x="24" y="${height-18}" fill="#a8b1c5" font-size="14">Placement relevé dans Godot · montage atlas sans éclairage local ni HUD</text>`;
 sceneLayers.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" style="font-family:Arial,sans-serif">${captions}</svg>`),left:0,top:0});
 await sharp({create:{width,height,channels:4,background:'#080e18'}}).composite(sceneLayers).png().toFile(abs(OUT+'/layout-montage.png'));
 const report={date:'2026-10-25',retainedRegions:retained,retainedPixelsAndMetadataIdentical:true,mainAtlasByteIdentical:hash(atlas)===hash(OUT+'/before/'+atlas),selectionFiles:Object.keys(selection.reviewedFiles).length,userProjectSettingsUnchanged:true,
  atlas:{regions:current.spriteCount,pages:current.atlas.pages,pngBytes:current.atlas.sourceBytes,deltaPNG:current.atlas.sourceBytes-baseline.atlas.sourceBytes,rgbaBytes:current.atlas.uncompressedRGBABytes,deltaRGBA:current.atlas.uncompressedRGBABytes-baseline.atlas.uncompressedRGBABytes},
  observations:observations.map(s=>({state:s.capture,issues:s.issues,chests:s.sprites.filter(p=>['prop-chest','prop-chest-open'].includes(p.id)).map(p=>({id:p.id,atlas:p.atlas})),shadows:s.sprites.filter(p=>p.id.startsWith('prop-chest')&&p.id.endsWith('-shadow')).length,labels:s.labels.map(l=>l.text),heroIndex:s.hero_index,visualHashChanged:s.visual_hash_changed})),
  limits:['Offline montage, not a GPU capture. No native app control, automated test suite, device profile or full raid verification.','Coins are a fixed appearance for an unprotected chest; the numeric caption reports its actual contents.','Closed art was accepted; the newly requested open/smaller-coins appearance remains subject to feedback.']};
 write('validation.json',JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({retained,mainAtlasByteIdentical:report.mainAtlasByteIdentical,deltaPNG:report.atlas.deltaPNG,deltaRGBA:report.atlas.deltaRGBA,states:observations.length,board:OUT+'/comparison.png'}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
