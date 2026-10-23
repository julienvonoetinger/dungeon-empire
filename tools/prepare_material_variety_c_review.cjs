// Appearance proposal only: current C geometry, shared proposed material samples.
// This produces review images, not a runtime variant catalogue.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const {library,wallStudy,floorStudy,seed,OUT,SRC}=require('./prepare_material_variation_review.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {ROOT,read,hash,render}=R;
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const freeze=(source,target)=>{if(!fs.existsSync(path.join(ROOT,target)))write(target,read(source));};

async function corner(materials,names,options={}){
  const prefix=options.prefix||'corner-c';
  const id='cells/w09_p00_e00',entry=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json')).entries[id];
  const guidePath='docs/reference/wireframe-overlays/'+entry.svg,guide=read(guidePath).toString();
  const model=makeModel(id,entry);model.drawAccent=false;model.stableStones=true;
  if(options.floorFinish)model.floorFinish=options.floorFinish;
  model.resolveMaterials=faces=>{
    for(const f of faces){
      const n=seed([f.kind,f.points.map(p=>p.map(v=>Math.round(v*1000)/1000))]);
      f.bevelSeed=n%100000;
      if(f.kind==='floor'){
        // World-aligned, near-square C slabs; the large field review below
        // handles full crossing stones before any framing.
        const upper=f.p[1]<.5;
        const material=upper?(f.p[0]<.7?5:1):(f.p[0]<2.3/6||f.p[0]>(2.3+3.15)/6?3:2);
        f.materialId=names[8+material];
      }else{
        const choice=n%24;f.materialId=names[choice<22?choice%6:choice-16];
        // A deliberate small sample of the shared palette for this review:
        // one corrupted cap, weathered side stone, calm planes and sparse pits.
        // The compositor carries each cap's material onto its upper facade.
        if(f.kind==='top'){
          const material=f.p[1]<1/6?(f.p[0]<1.6/6?5:f.p[0]<3.5/6?6:2):(f.p[1]<3.5/6?1:4);
          f.materialId=names[material];
        }
      }
    }
  };
  const result=await render(model,guide,materials);
  freeze('assets/dungeon/painted-cells/'+id+'.png',OUT+'/source/corner-c-before-materials.png');
  write(OUT+'/'+prefix+'-proposal.png',result.png);
  write(OUT+'/'+prefix+'-overlay.png',result.overlay);
  write(OUT+'/'+prefix+'-guide.svg',guide);
  write(OUT+'/'+prefix+'-regions.svg',result.recipe);
  json(OUT+'/'+prefix+'-report.json',result.report);
  const layers=[],labels=[],files=[options.baseline||'source/corner-c-before-materials.png',prefix+'-proposal.png',prefix+'-overlay.png'];
  for(let i=0;i<files.length;i++){
    layers.push({input:await sharp(read(OUT+'/'+files[i])).resize({width:560}).png().toBuffer(),left:30+i*590,top:115});
    labels.push(`<text x="${30+i*590}" y="90" font-size="26" fill="#dce5f4">${(options.labels||['Matières actuelles','Proposition variée','Même image + wireframe'])[i]}</text>`);
  }
  const footer=options.footer||'Géométrie et finition B conservées · petit trait violet supprimé · aperçu avant intégration';
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="850"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial"><text x="30" y="42" font-size="31" fill="#f1f4fb">Coin supérieur gauche · grandes dalles C</text>${labels.join('')}<text x="30" y="800" font-size="23" fill="#b6c4da">${footer}</text></g></svg>`);
  write(OUT+'/'+prefix+'-comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  return {guide:guidePath,guideSha256:hash(guide),...result.report};
}

async function main(){
  const {materials,names}=await library();
  const cornerReport=await corner(materials,names);console.log('NW corner and overlay rendered.');
  const wallBaseline=OUT+'/source/walls-before-materials';
  for(const variant of ['w01_p00_e08','w01_p00_e00','w01_p00_e02'])freeze('assets/dungeon/painted-connected/cells/'+variant+'.png',wallBaseline+'/'+variant+'.png');
  const wall=await wallStudy(materials,names,{baselineDirectory:wallBaseline});console.log('Wall appearance field rendered.');
  const baseline=OUT+'/source/floor-c-before-materials.png';
  freeze('assets/dungeon/painted-connected/floor.png',baseline);
  const layout=JSON.parse(read('docs/reference/floor-periodic-cell.json')).floor;
  const floor=await floorStudy(materials,names,{id:'variety-c',cols:3,rows:3,layout,baselineFile:baseline,quietFloor:true});
  const layers=[],labels=[];
  for(const [file,y,label] of [['wall-before.png',108,'Mur actuel'],['wall-proposal.png',318,'Mur proposé · motifs variés, violet ponctuel']]){
    layers.push({input:await sharp(read(OUT+'/'+file)).resize({width:1560}).png().toBuffer(),left:40,top:y});
    labels.push(`<text x="40" y="${y-18}" font-size="25" fill="#dce5f4">${label}</text>`);
  }
  for(const [i,file,label] of [[0,'variety-c-before.png','Sol C actuel'],[1,'variety-c-proposal.png','Sol C proposé · usure variée']]){
    layers.push({input:await sharp(read(OUT+'/'+file)).resize(760,760).png().toBuffer(),left:40+i*800,top:568});
    labels.push(`<text x="${40+i*800}" y="540" font-size="25" fill="#dce5f4">${label}</text>`);
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1640" height="1420"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial"><text x="40" y="44" font-size="31" fill="#f1f4fb">Variété des matières · découpage C inchangé</text>${labels.join('')}<text x="40" y="1374" font-size="22" fill="#b6c4da">8 matières de mur + 8 de sol · compositions de revue, pas encore appliquées dans Godot</text></g></svg>`);
  write(OUT+'/appearance-c-comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  json(OUT+'/appearance-c-recipe.json',{status:'awaiting_appearance_approval',source:SRC,sourceSha256:hash(read(SRC)),floorSource:'docs/reference/floor-periodic-cell.json',floorSourceSha256:hash(read('docs/reference/floor-periodic-cell.json')),materials,corner:cornerReport,wall,floor,rules:['Same C geometry and B finish.','No procedural violet branch stroke.','Top and upper facade share one material ID.','Material choices are made per complete stone in the wall/floor appearance fields.','New material family is not promoted to active catalogs.'],scope:'Appearance study including isolated NW overlay. Not a production cell-variant catalog or proof of arbitrary joins.'});
  console.log(OUT+'/corner-c-comparison.png');
  console.log(OUT+'/appearance-c-comparison.png');
}
module.exports={corner};
if(require.main===module)main().catch(e=>{if(e.diagnostic){write(OUT+'/corner-c-failure.svg',e.diagnostic.drawing);write(OUT+'/corner-c-failure-model.svg',e.diagnostic.silhouette);}console.error(e.stack);process.exitCode=1;});
