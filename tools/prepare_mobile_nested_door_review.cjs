// Review-only paint export of the approved smooth-leaf structure; no active atlas writes.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {nestedDoorParts}=require('./mobile_nested_door_parts.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const revision=process.argv.includes('--legacy-v7')?7:8;
const artRevision=process.argv.includes('--art-v2')?2:1;
const art=process.argv.includes('--art')||artRevision===2;
if(art&&revision!==8)throw Error('Painted artwork requires the approved v8 surface.');
const appearance=art?require('./mobile_door_art_material.cjs'):null;
const OUT=`docs/reference/mobile-door-frame-review/${art?'painted-art-v'+artRevision:'painted-v'+revision}`;
const save=(p,b)=>write(path.join(R.ROOT,OUT,p),b);
async function board(file,entries,columns=2) {
  const w=400,h=450,layers=[];let labels='';
  for(const [i,e] of entries.entries()) {
    const x=i%columns*w,y=Math.floor(i/columns)*h;
    layers.push({input:R.read(e[2]||`${OUT}/captures/${e[0]}.png`),left:x,top:y+30});
    labels+=`<text x="${x+14}" y="${y+21}" fill="#d7ddea" font-size="16">${e[1]}</text>`;
  }
  const svg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${columns*w}" height="${Math.ceil(entries.length/columns)*h}"><rect width="100%" height="100%" fill="#080f1b"/><g font-family="Arial">${labels}</g></svg>`);
  save(file,await sharp(svg).composite(layers).png().toBuffer());
}
async function main() {
  if(process.argv.includes('--boards')) {
    await board('before-after.png',art?[['proposal-south',artRevision===2?'Proposition précédente':'Base précédente',`docs/reference/mobile-door-frame-review/${artRevision===2?'painted-art-v1':'painted-v8'}/captures/proposal-south.png`],['proposal-south',artRevision===2?'Sommet en arche, ferrures en retrait':'Proposition : fer sombre et sceau violet']]:[['before-south','Actuel'],['proposal-south',revision>=8?'Vantail lisse, deux arches':'Deux arches et mur lisse en retrait']]);
    await board('paint-and-guide.png',[['proposal-south','Rendu à la distance de jeu'],['overlay-south','Avec le guide magenta']]);
    await board('four-directions.png',[['proposal-north','Nord'],['proposal-east','Est'],['proposal-south','Sud'],['proposal-west','Ouest']]);
    console.log('Prepared gameplay-scale review boards.');return;
  }
  const entries={},reports=[];
  const directions=process.argv.includes('--south-only')?['south']:['north','east','south','west'];
  for(const d of directions) {
    for(const item of await nestedDoorParts(d,OUT,{revision,leafAppearance:appearance?.leafAppearance})) {
      entries[item.id]={offset:item.frame.slice(0,2),size:item.frame.slice(2),bounds:item.bounds,file:`${OUT}/sprites/${item.id}.png`};
      reports.push(item.report);
    }
    console.log('Prepared nested door '+d);
  }
  const sources=[`docs/reference/mobile-door-frame-review/wireframe-v${revision}/geometry.json`,`docs/reference/mobile-door-frame-review/wireframe-v${revision}/selection.json`,'tools/mobile_nested_door_parts.cjs','tools/mobile_special_parts.cjs','tools/painted_material_renderer.cjs','assets/dungeon/shared-materials/catalog.json','assets/dungeon/shared-materials/door-oak.png'];
  if(art)sources.push(appearance.SOURCE,'tools/mobile_door_art_material.cjs',`${OUT}/generation.json`);
  if(art&&artRevision===2)sources.push(`${OUT}/source/door-artwork.png`,`${OUT}/source/fit.json`,'tools/prepare_mobile_door_arch_artwork.cjs');
  save('proposal.json',JSON.stringify({revision,status:'painted-appearance-awaiting-review',geometryApproval:`User: Ok after wireframe v${revision}`,density:256,zoom:.75,entries,reports,
    leafArtwork:art?'One ImageGen painting mapped to both broad faces of the v8 leaf. Geometry and guides unchanged.':revision>=8?'One continuous shared wood texture; no imposed plank joints or hardware.':'Historical plank guides and two-sided handle.',
    sourceHashes:Object.fromEntries(sources.map(p=>[p,R.hash(R.read(p))])),
    originalArches:'Unchanged frozen atlas regions from ../source/catalog.json and atlas-256.png',
    scope:'Prepared review parts only. Active kit, scenes and stairs unchanged.'},null,2)+'\n');
}
main().catch(e=>{console.error(e.stack);if(e.diagnostic){save('diagnostic-drawing.svg',e.diagnostic.drawing);save('diagnostic-silhouette.svg',e.diagnostic.silhouette);}process.exitCode=1;});
