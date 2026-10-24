// Adopt the approved complete sprites. Never regenerate or reshape their fire.
const path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const REVIEW='docs/reference/mobile-light-review/painted-v2';
const FALLOFF='docs/reference/mobile-light-review/prepared/light-falloff.png';
async function approvedTorches(){
  const selected=JSON.parse(R.read(REVIEW+'/selection.json'));
  if(selected.status!=='appearance-approved')throw Error('Torch appearance is not approved.');
  for(const [file,hash] of Object.entries(selected.files))
    if(R.hash(R.read(REVIEW+'/'+file))!==hash)throw Error('Approved torch reference changed: '+file);
  if(R.hash(R.read(selected.geometry))!==selected.geometrySha256)throw Error('Approved torch geometry changed.');
  const recipe=JSON.parse(R.read(REVIEW+'/prepared.json'));
  const expected={'torch-horizontal':[58,84],'torch-vertical':[56,108]};
  const items=[];
  for(const [id,size] of Object.entries(expected)){
    const entry=recipe.entries.find(e=>e.id===id);
    if(!entry||JSON.stringify(entry.size)!==JSON.stringify(size))throw Error('Missing approved torch size: '+id);
    const png=R.read(entry.file),meta=await sharp(png).metadata();
    if(meta.width!==size[0]||meta.height!==size[1]||!meta.hasAlpha||R.hash(png)!==entry.sha256)
      throw Error('Approved torch pixels changed: '+id);
    if(entry.flame.worldPerPixel!==entry.flame.worldPerPixelX||entry.flame.solidWorldHeight!==.215||entry.flame.baseZ!==.20)
      throw Error('Approved flame proportions changed: '+id);
    writeGeneratedFile(path.join(R.ROOT,'docs/reference/mobile-kit/sprites/'+id+'.png'),png);
    items.push({id,png,densityPng:{256:png},frame:[...entry.offset,...entry.size],bounds:entry.bounds,
      light:{emission:entry.emission,radius:entry.radius,energy:entry.energy,color:entry.color}});
  }
  writeGeneratedFile(path.join(R.ROOT,'assets/dungeon/mobile-kit/light-falloff.png'),R.read(FALLOFF));
  return items;
}
module.exports={approvedTorches,REVIEW,FALLOFF};
