// Review prepared sprites and static Godot inventory. No pixel painting or runtime capture.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/treasure-chest-review/v4-directions';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const rect=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
const svg=(w,h,body)=>Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="'+w+'" height="'+h+'" style="font-family:Arial,sans-serif">'+body+'</svg>');
const text=(x,y,s,size=16,color='#e6dcc8')=>'<text x="'+x+'" y="'+y+'" fill="'+color+'" font-size="'+size+'">'+s+'</text>';
async function main(){
 const baseline=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json'),current=read('assets/dungeon/isometric-kit/catalog.json');
 const atlas='assets/dungeon/isometric-kit/atlas-256.png',regions=current.atlas.regions,config=read('tools/chest_direction_sources.json');
 let retained=0;
 for(const [id,e] of Object.entries(baseline.atlas.regions)){
  if(id.startsWith('prop-chest'))continue;
  const n=regions[id];if(!n)throw Error('Lost original region '+id);
  const old=await sharp(abs(OUT+'/before/'+atlas)).extract(rect(e.region)).raw().toBuffer();
  const now=await sharp(abs(atlas)).extract(rect(n.region)).raw().toBuffer();
  if(!old.equals(now)||JSON.stringify(e)!==JSON.stringify(n))throw Error('Original art/metadata changed '+id);
  retained++;
 }
 const selection=read('docs/reference/treasure-chest-review/v2/selection.json');
 for(const [p,h] of Object.entries(selection.reviewedFiles))if(hash(p)!==h)throw Error('Selected chest history changed '+p);
 for(const f of config.items)if(hash(f.source)!==f.sha256)throw Error('Direction source changed '+f.source);
 if(hash('project.godot')!==hash(OUT+'/before/project.godot'))throw Error('User project settings changed');
 async function raster(id,scale,old=false){
  const e=(old?baseline:current).atlas.regions[id],file=(e.atlas_path??'res://'+atlas).replace('res://','');
  return sharp(abs((old?OUT+'/before/':'')+file)).extract(rect(e.region)).resize(Math.max(1,Math.round(e.size[0]*scale)),Math.max(1,Math.round(e.size[1]*scale))).png().toBuffer();
 }
 async function sample(id,scale,old=false){
  const W=440,H=340,cx=220,cy=215,layers=[],entries=(old?baseline:current).atlas.regions;
  const add=async(key,anchor)=>{const e=entries[key];layers.push({input:await raster(key,scale,old),left:Math.round(anchor[0]+e.offset[0]*scale),top:Math.round(anchor[1]+e.offset[1]*scale)});};
  await add('floor-b1',[cx,cy-64*scale]);
  await add(entries[id].ground_effects[0],[cx,cy]);
  await add(id,[cx,cy]);
  return sharp(await sharp({create:{width:W,height:H,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer()).extract({left:60,top:40,width:320,height:280}).png().toBuffer();
 }
 // Eight views at their actual .75 game scale, followed by the same pixels at x2.
 const directions=[['south','Sud · vers bas-gauche'],['east','Est · vers bas-droite'],['north','Nord · vers haut-droite'],['west','Ouest · vers haut-gauche']];
 for(const zoom of [.75,1.5]){
  const W=1280,H=690,layers=[];
  let labels=text(22,32,zoom===.75?'Quatre orientations · corps 72 px à l’échelle du jeu':'Quatre orientations · agrandissement ×2',24);
  labels+=text(22,57,'Chevron d’origine · serrure conservée sur la caisse · charnières vues de dos',15,'#a8b1c5');
  for(let col=0;col<4;col++){
   const [dir,label]=directions[col];labels+=text(col*320+20,92,label,17);
   for(let row=0;row<2;row++){
    const id='prop-chest'+(row?'-open':'')+(dir==='south'?'':'-'+dir),top=110+row*280;
    layers.push({input:await sample(id,zoom),left:col*320,top});
    labels+=text(col*320+20,top+25,row?'Ouvert':'Fermé',15);
   }
  }
  layers.push({input:svg(W,H,labels+text(22,681,'Montage depuis l’atlas : sans éclairage local ni HUD, pas une capture GPU.',13,'#a8b1c5')),left:0,top:0});
  await sharp({create:{width:W,height:H,channels:4,background:'#0b1019'}}).composite(layers).png().toFile(abs(OUT+(zoom===.75?'/directions.png':'/directions-detail.png')));
 }
 const sizeLayers=[];
 for(let i=0;i<2;i++)sizeLayers.push({input:await sample('prop-chest-open',.75,i===0),left:i*320,top:50});
 sizeLayers.push({input:svg(640,350,text(20,32,'Avant · 96 px',21)+text(340,32,'Maintenant · 72 px (−25 %)',21)+text(20,338,'Même dalle et même zoom. Nouvelle serrure conservée.',14,'#a8b1c5')),left:0,top:0});
 await sharp({create:{width:640,height:350,channels:4,background:'#0b1019'}}).composite(sizeLayers).png().toFile(abs(OUT+'/size-comparison.png'));
 const observations=read(OUT+'/scene-inventory.json').captures,zoom=.75;
 for(const name of ['corners-mixed','corners-open']){
  const state=observations.find(s=>s.capture===name);
  const min=[0,1].map(a=>Math.min(...state.sprites.map(s=>s.position[a]))),max=[0,1].map(a=>Math.max(...state.sprites.map(s=>s.position[a]+s.size[a])));
  const width=Math.ceil((max[0]-min[0])*zoom)+48,height=Math.ceil((max[1]-min[1])*zoom)+90,layers=[];
  // Stable traversal records actual host ordering; z=0 grounds precede z=1 solids.
  for(const s of state.sprites.slice().sort((a,b)=>a.z-b.z))layers.push({input:await raster(s.id,zoom),left:Math.round((s.position[0]-min[0])*zoom)+24,top:Math.round((s.position[1]-min[1])*zoom)+24});
  let captions='';
  for(const l of state.labels)captions+=text((l.position[0]-min[0])*zoom+24,(l.position[1]-min[1])*zoom+38,l.text,13);
  captions+=text(24,height-18,'Placement Godot · montage atlas sans lumière locale/HUD',14,'#a8b1c5');
  layers.push({input:svg(width,height,captions),left:0,top:0});
  await sharp({create:{width,height,channels:4,background:'#080e18'}}).composite(layers).png().toFile(abs(OUT+'/'+name+'.png'));
 }
 const report={date:'2026-10-25',retainedNonChestRegions:retained,nonChestPixelsAndMetadataIdentical:true,mainAtlasByteIdentical:hash(atlas)===hash(OUT+'/before/'+atlas),preservedSelectionFiles:Object.keys(selection.reviewedFiles).length,userProjectSettingsUnchanged:true,
  size:{before:96,after:72,ratio:.75},atlas:{regions:current.spriteCount,pages:current.atlas.pages,pngBytes:current.atlas.sourceBytes,deltaPNG:current.atlas.sourceBytes-baseline.atlas.sourceBytes,rgbaBytes:current.atlas.uncompressedRGBABytes,deltaRGBA:current.atlas.uncompressedRGBABytes-baseline.atlas.uncompressedRGBABytes},
  observations:observations.map(s=>({state:s.capture,issues:s.issues,facings:s.facings,chests:s.sprites.filter(p=>regions[p.id]?.decoration?.chest_state).map(p=>p.id),shadows:s.sprites.filter(p=>p.id.startsWith('prop-chest')&&p.id.endsWith('-shadow')).length,labels:s.labels.map(l=>l.text),unlockChangesStructure:s.unlock_changes_structure})),
  limits:['Static headless inventory and offline atlas composites, not GPU capture. No native app control, automated test suite, device profile or full raid verification.','Direction favours local clearance; if all four sides are blocked, accessible=false and south fallback. No placement/economy/raid rule changes.','Coins remain fixed artwork; gold captions report actual contents.','Contact is a painted-source support proxy, not reconstructed3D. New art/scale remains subject to user feedback.']};
 fs.writeFileSync(abs(OUT+'/validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({retained,mainAtlasByteIdentical:report.mainAtlasByteIdentical,deltaPNG:report.atlas.deltaPNG,deltaRGBA:report.atlas.deltaRGBA,states:observations.length,pages:current.atlas.pages}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
