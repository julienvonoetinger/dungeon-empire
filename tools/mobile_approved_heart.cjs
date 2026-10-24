// Adopt the selected complete sprite unchanged; no material projection is needed.
const sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const path=require('node:path');
const REVIEW='docs/reference/mobile-heart-review/ritual-v3';
async function approvedHeart(){
  const selection=JSON.parse(R.read(REVIEW+'/selection.json'));
  if(selection.status!=='appearance-approved')throw Error('Heart appearance is not approved.');
  for(const [file,hash] of Object.entries(selection.files))
    if(R.hash(R.read(REVIEW+'/'+file))!==hash)throw Error('Approved heart reference changed: '+file);
  const prepared=JSON.parse(R.read(REVIEW+'/prepared.json'));
  const entry=prepared.entries.find(e=>e.id==='a');
  const variant=entry.variants.find(v=>v.density===256);
  const png=R.read(REVIEW+'/prepared/a-256.png'),metadata=await sharp(png).metadata();
  if(metadata.width!==289||metadata.height!==289||!metadata.hasAlpha)
    throw Error('Approved heart must retain its complete 289x289 alpha sprite.');
  if(JSON.stringify(variant.size)!=='[289,289]'||JSON.stringify(variant.anchor)!=='[144.5,155.792663476874]'||
    JSON.stringify(entry.footprint)!=='[0.8125,0.8125]'||entry.supportHeight!==.98)
    throw Error('Approved heart placement changed.');
  const half=entry.footprint.map(v=>v/2);
  writeGeneratedFile(path.join(R.ROOT,'docs/reference/mobile-kit/sprites/heart.png'),png);
  return {id:'heart',png,densityPng:{256:png},frame:[-variant.anchor[0],-variant.anchor[1],...variant.size],
    bounds:{min:[-half[0],-half[1],0],max:[half[0],half[1],entry.supportHeight]}};
}
module.exports={approvedHeart,REVIEW};
