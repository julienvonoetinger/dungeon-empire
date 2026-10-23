// Review only: smooth floor material on the accepted C geometry.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {ROOT,read,hash}=require('./painted_material_renderer.cjs');
const {floorStudy,OUT}=require('./prepare_material_variation_review.cjs');
const {corner}=require('./prepare_material_variety_c_review.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const SRC='assets/dungeon/shared-materials/proposals/variation-review/floor-smooth-v1.png';
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const freeze=(source,target)=>{if(!fs.existsSync(path.join(ROOT,target)))write(target,read(source));};

async function main(){
  const original=JSON.parse(read(OUT+'/appearance-c-recipe.json'));
  const materials=structuredClone(original.materials),names=Array.from({length:8},(_,i)=>'variation-wall-'+(i+1));
  const atlas=read(SRC),meta=await sharp(atlas).metadata(),w=Math.floor(meta.width/4),h=Math.floor(meta.height/2);
  for(let i=0;i<8;i++){
    const id='smooth-floor-'+(i+1),file='proposals/variation-review/'+id+'.png';
    const region={left:(i%4)*w+6,top:Math.floor(i/4)*h+6,width:w-12,height:h-12};
    const png=await sharp(atlas).extract(region).png().toBuffer();
    write('assets/dungeon/shared-materials/'+file,png);
    materials.entries[id]={file,family:'floor',source:SRC,sourceRegion:region,sha256:hash(png)};
    names.push(id);
  }
  // The material layer remains subordinate to the calm shared floor base color.
  // This is an offline recipe; it introduces no runtime tint or shader.
  materials.renderProfile.floor.opacity=.55;
  freeze(OUT+'/corner-c-proposal.png',OUT+'/source/corner-c-before-smooth.png');
  freeze(OUT+'/variety-c-proposal.png',OUT+'/source/floor-c-before-smooth.png');
  const cornerReport=await corner(materials,names,{prefix:'smooth-c',baseline:'source/corner-c-before-smooth.png',labels:['Proposition précédente','Sol plus lisse et discret','Même image + wireframe']});
  console.log('Smooth floor NW corner rendered.');
  const layout=JSON.parse(read('docs/reference/floor-periodic-cell.json')).floor;
  const floor=await floorStudy(materials,names,{id:'smooth-floor',cols:3,rows:3,layout,baselineFile:OUT+'/source/floor-c-before-materials.png',quietFloor:true});
  const layers=[],labels=[];
  for(const [i,file,label] of [[0,'source/floor-c-before-smooth.png','Précédent · facettes et marques visibles'],[1,'smooth-floor-proposal.png','Proposition · surface douce, peu contrastée']]){
    layers.push({input:await sharp(read(OUT+'/'+file)).resize(760,760).png().toBuffer(),left:40+i*800,top:125});
    labels.push(`<text x="${40+i*800}" y="99" font-size="25" fill="#dce5f4">${label}</text>`);
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1640" height="1000"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial"><text x="40" y="44" font-size="32" fill="#f1f4fb">Un sol discret pour laisser ressortir les objets</text>${labels.join('')}<text x="40" y="934" font-size="23" fill="#bdcbe0">Même dallage C, mêmes joints et même échelle · variation douce entre les dalles</text><text x="40" y="973" font-size="22" fill="#a7b8d0">Sans gros éclats, trous ni fissures au sol · aperçu avant intégration dans Godot</text></g></svg>`);
  write(OUT+'/smooth-floor-comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  json(OUT+'/smooth-floor-recipe.json',{status:'awaiting_appearance_approval',source:SRC,sourceSha256:hash(atlas),materials,corner:cornerReport,floor,sourceRecipe:OUT+'/appearance-c-recipe.json',sourceRecipeSha256:hash(read(OUT+'/appearance-c-recipe.json')),rules:['Only floor material IDs and floor layer opacity differ from the preceding corner.','C geometry, B finish and proposed wall materials unchanged.','Eight subtle matte surface variations; no pronounced chips, pits or fractures.','No runtime asset/catalog replacement.'],scope:'Visual material review, not a gameplay legibility test or approval of arbitrary tile joins.'});
  console.log(OUT+'/smooth-floor-comparison.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
