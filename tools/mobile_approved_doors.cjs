// Production promotion of the exact appearance approved in painted-art-v2.
// Source artwork and geometry are authoring inputs, never runtime dependencies.
const sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {doorPart}=require('./mobile_special_parts.cjs');
const {nestedDoorParts}=require('./mobile_nested_door_parts.cjs');
const {approvedLeafAppearance}=require('./mobile_door_art_material.cjs');
const REVIEW='docs/reference/mobile-door-frame-review/painted-art-v2';
const GEOMETRY='docs/reference/mobile-door-frame-review/wireframe-v8';
const OUT='docs/reference/mobile-kit';
const extraParts=['inner-arch','jamb-left','jamb-right','smooth-upper','smooth-left','smooth-right'];
let approvalChecked=false;
function verifyApprovals(){
  if(approvalChecked)return;
  const selection=JSON.parse(R.read(REVIEW+'/selection.json'));
  if(selection.status!=='user-approved-appearance')throw Error('Door appearance is not approved.');
  for(const [file,hash] of Object.entries(selection.sourceHashes))
    if(R.hash(R.read(REVIEW+'/'+file))!==hash)throw Error('Approved door reference changed: '+file);
  const geometrySelection=JSON.parse(R.read(GEOMETRY+'/selection.json'));
  if(geometrySelection.status!=='user-approved-structure'||R.hash(R.read(GEOMETRY+'/geometry.json'))!==geometrySelection.source.geometrySha256)
    throw Error('Approved door geometry changed.');
  approvalChecked=true;
}
async function approvedDoorParts(direction){
  verifyApprovals();
  const originalArch=await doorPart(direction,'arch',{output:OUT});
  const frozen=JSON.parse(R.read('docs/reference/mobile-door-frame-review/source/catalog.json'));
  const [left,top,width,height]=frozen.atlas.regions[originalArch.id].region;
  const original=await sharp(R.read('docs/reference/mobile-door-frame-review/source/atlas-256.png')).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  // Compare at the same compositing stage as the frozen atlas. Packing onto
  // transparency rounds a few partially transparent RGB values by one level.
  const exported=await sharp({create:{width,height,channels:4,background:'#00000000'}})
    .composite([{input:R.read(`${OUT}/sprites/${originalArch.id}.png`),left:0,top:0}]).raw().toBuffer();
  if(!original.equals(exported))throw Error('Original main arch pixels changed: '+direction);
  const added=await nestedDoorParts(direction,OUT,{revision:8,leafAppearance:approvedLeafAppearance});
  const proposal=JSON.parse(R.read(REVIEW+'/proposal.json'));
  for(const item of added){
    const file=`sprites/${item.id}.png`,reference=proposal.entries[item.id];
    if(R.hash(R.read(OUT+'/'+file))!==R.hash(R.read(REVIEW+'/'+file)))throw Error('Approved door pixels changed: '+item.id);
    if(JSON.stringify(item.frame)!==JSON.stringify([...reference.offset,...reference.size])||JSON.stringify(item.bounds)!==JSON.stringify(reference.bounds))
      throw Error('Approved door placement changed: '+item.id);
    if(item.id.endsWith('-leaf'))item.companions=extraParts.map(suffix=>`door-${direction}-${suffix}`);
  }
  return [originalArch,...added];
}
module.exports={approvedDoorParts,REVIEW,GEOMETRY};
