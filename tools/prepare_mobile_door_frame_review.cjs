// Offline appearance proposal. Does not replace the active mobile atlas.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const B=require('./prepare_mobile_reference.cjs');
const {insetDoorParts}=require('./mobile_special_parts.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const OUT='docs/reference/mobile-door-frame-review';
const save=(p,data)=>write(path.join(R.ROOT,OUT,p),data);
const json=(p,data)=>save(p,JSON.stringify(data,null,2)+'\n');
const directions=['north','east','south','west'];
// Keep the existing arch exactly. Narrow only the wood; fill the sides below
// the same curved opening with two full-height stone jambs.
const shape={leafHalfWidth:.29,jambInner:.30,arch:'unchanged-existing-sprite'};
async function board(file,entries,columns){
  const w=400,h=450,layers=[];
  let labels='';
  for(const [i,item] of entries.entries()){
    const x=i%columns*w,y=Math.floor(i/columns)*h;
    layers.push({input:fs.readFileSync(path.join(R.ROOT,OUT,'captures',item.file+'.png')),left:x,top:y+30});
    labels+=`<text x="${x+14}" y="${y+21}" fill="#d7ddea" font-size="16">${item.label}</text>`;
  }
  const svg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${columns*w}" height="${Math.ceil(entries.length/columns)*h}"><rect width="100%" height="100%" fill="#080f1b"/><g font-family="Arial">${labels}</g></svg>`);
  save(file,await sharp(svg).composite(layers).png().toBuffer());
}
async function main(){
  if(process.argv.includes('--boards')){
    await board('before-after.png',[{file:'before-south',label:'Actuel'},{file:'proposal-south',label:'Même arche, bois réduit et montants'}],2);
    save('before-after-v2.png',R.read(`${OUT}/before-after.png`));
    await board('four-directions.png',directions.map((d,i)=>({file:'proposal-'+d,label:['Nord','Est','Sud','Ouest'][i]})),2);
    console.log('Prepared native-scale before/after and four directions.');return;
  }
  // Keep an immutable baseline so a later promotion cannot rewrite the comparison.
  for(const file of ['catalog.json','atlas-256.png']){
    const target=path.join(R.ROOT,OUT,'source',file);
    if(!fs.existsSync(target))write(target,R.read('assets/dungeon/mobile-kit/'+file));
  }
  const entries={},reports=[],archHashes={};
  for(const direction of directions){
    for(const item of await insetDoorParts(direction,{...shape,output:OUT})){
      entries[item.id]={offset:item.frame.slice(0,2),size:item.frame.slice(2),bounds:item.bounds,file:`${OUT}/sprites/${item.id}.png`};
      reports.push(item.report);
    }
    const id=`door-${direction}-arch`;
    // Replace the rejected proposal's smaller arches/guides with the originals.
    for(const [folder,ext] of [['sprites','png'],['overlays','png'],['guides','svg']])save(`${folder}/${id}.${ext}`,R.read(`docs/reference/mobile-kit/${folder}/${id}.${ext}`));
    archHashes[id]=R.hash(R.read(`${OUT}/sprites/${id}.png`));
  }
  const sources=['tools/mobile_special_parts.cjs','tools/prepare_mobile_door_frame_review.cjs','tools/prepare_mobile_reference.cjs','tools/painted_material_renderer.cjs','docs/reference/door-arch-cell-west-east-wireframe.json','assets/dungeon/shared-materials/catalog.json'];
  json('proposal.json',{status:'corrected_appearance_proposal',revision:2,shape,projection:[-.18,-.9],density:256,zoom:.75,entries,archHashes,
    woodWidth:{previous:2*(1/3+B.T/2),proposed:shape.leafHalfWidth*2},
    height:{previous:B.H+(.5+B.T/2),proposed:B.H+(.5+B.T/2)},
    sourceHashes:Object.fromEntries(sources.map(p=>[p,R.hash(R.read(p))])),reports,
    scope:'Original arch sprite, size and position preserved. Narrower wood, two upright stone jambs below its existing curve. Active kit and scenes unchanged.'});
  console.log('Prepared twelve inset parts; all four original arches preserved unchanged.');
}
main().catch(e=>{console.error(e.stack);if(e.diagnostic){save('diagnostic-drawing.svg',e.diagnostic.drawing);save('diagnostic-silhouette.svg',e.diagnostic.silhouette);}process.exitCode=1;});
