// Review only: stronger rounding on the smooth floor; shared walls retain B.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {ROOT,read,hash}=require('./painted_material_renderer.cjs');
const {floorStudy,OUT}=require('./prepare_material_variation_review.cjs');
const {corner}=require('./prepare_material_variety_c_review.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const freeze=(source,target)=>{if(!fs.existsSync(path.join(ROOT,target)))write(target,read(source));};

async function main(){
  const sourceRecipe=OUT+'/smooth-floor-recipe.json';
  const source=JSON.parse(read(sourceRecipe)),materials=structuredClone(source.materials);
  const names=[...Array.from({length:8},(_,i)=>'variation-wall-'+(i+1)),...Array.from({length:8},(_,i)=>'smooth-floor-'+(i+1))];
  // Reference pixels at 256 px/cell, with existing floorFactor .63 applied.
  // Only the radius changes: no wider joints or stronger edge highlight.
  const floorFinish={id:'smooth-floor-rounded-review-v1',status:'awaiting_appearance_approval',approval:null,reference:OUT+'/rounded-smooth-floor-detail.png',radius:10.5};
  freeze(OUT+'/smooth-c-proposal.png',OUT+'/source/corner-c-before-rounding.png');
  freeze(OUT+'/smooth-floor-proposal.png',OUT+'/source/floor-c-before-rounding.png');
  const cornerReport=await corner(materials,names,{prefix:'rounded-smooth-c',floorFinish,baseline:'source/corner-c-before-rounding.png',labels:['Sol lisse précédent','Coins des dalles arrondis','Même image + wireframe'],footer:'Même texture douce et découpage C · arrondi du sol accentué · murs conservés'});
  console.log('Rounded smooth floor corner rendered.');
  const layout=JSON.parse(read('docs/reference/floor-periodic-cell.json')).floor;
  const floor=await floorStudy(materials,names,{id:'rounded-smooth-floor',cols:3,rows:3,layout,floorFinish,baselineFile:OUT+'/source/floor-c-before-materials.png',quietFloor:true});
  const layers=[],labels=[];
  for(const [i,file,label] of [[0,'source/floor-c-before-rounding.png','Précédent · arrondi discret'],[1,'rounded-smooth-floor-proposal.png','Proposition · coins plus doux']]){
    layers.push({input:await sharp(read(OUT+'/'+file)).resize(760,760).png().toBuffer(),left:40+i*800,top:125});
    labels.push(`<text x="${40+i*800}" y="99" font-size="25" fill="#dce5f4">${label}</text>`);
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1640" height="1000"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial"><text x="40" y="44" font-size="32" fill="#f1f4fb">Grandes dalles lisses · coins arrondis</text>${labels.join('')}<text x="40" y="934" font-size="23" fill="#bdcbe0">Même texture, mêmes joints et même échelle · arrondi limité aux coins des pierres</text><text x="40" y="973" font-size="22" fill="#a7b8d0">Pierres entières peintes avant découpe des cases · aperçu avant intégration dans Godot</text></g></svg>`);
  write(OUT+'/rounded-smooth-floor-comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  const detailLayers=[];
  for(const [i,file] of [[0,'source/floor-c-before-rounding.png'],[1,'rounded-smooth-floor-proposal.png']]){
    // Same junction between four large stones, magnified without a geometry fit.
    detailLayers.push({input:await sharp(read(OUT+'/'+file)).extract({left:120,top:310,width:620,height:620}).resize(700,700).png().toBuffer(),left:35+i*735,top:100});
  }
  const detailBg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1505" height="870"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4"><text x="35" y="65" font-size="28">Avant</text><text x="770" y="65" font-size="28">Coins arrondis</text><text x="35" y="844" font-size="23">Détail agrandi · le joint reste fin entre les parties droites</text></g></svg>`);
  write(OUT+'/rounded-smooth-floor-detail.png',await sharp(detailBg).composite(detailLayers).png().toBuffer());
  json(OUT+'/rounded-smooth-floor-recipe.json',{status:'awaiting_corner_rounding_approval',sourceRecipe,sourceRecipeSha256:hash(read(sourceRecipe)),materialApproval:'User accepted smooth floor direction, requesting rounded corners before final appearance approval.',materials,floorFinish:cornerReport.floorFinish,corner:cornerReport,floor,rules:['Only floor finish radius differs from the smooth proposal.','Wall finish B, material assignment, C geometry, alpha and guide joints unchanged.','Whole floor stones are painted before framing; no rounding at artificial cell cuts.','No active asset or Godot catalogue replacement.'],scope:'Appearance preview; no gameplay readability test or proof of arbitrary prepared tile joins.'});
  console.log(OUT+'/rounded-smooth-floor-comparison.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
