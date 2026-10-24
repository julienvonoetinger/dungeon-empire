// Review only: unwrap one paint patch around a stone instead of repeating it
// on its top and upper facade. Existing shared connection stones stay fixed.
const path=require('node:path'),fs=require('node:fs'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs'),C=require('./connected_stone_context.cjs');
const B=require('./prepare_wall_variants_review.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {ROOT,read,hash,inside}=R,P=256,S=4;
const OUT='docs/reference/wall-corruption-review-v2',OLD='docs/reference/wall-variation-review';
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const freeze=(a,b)=>{if(!fs.existsSync(path.join(ROOT,b)))write(b,read(a));};
freeze(OLD+'/recipe.json',OUT+'/source/previous-recipe.json');
const materials=structuredClone(JSON.parse(read(OUT+'/source/previous-recipe.json')).materials);
materials.id='wall-corruption-review-v2';
const project=(p,anchor)=>[(p[0]-.18*p[2])*P+anchor[0],(p[1]-.9*p[2])*P+anchor[1]];

async function prepareMaterials(){
  const source='assets/dungeon/shared-materials/proposals/variation-review/atlas-calm.png';
  const regions=[{left:730,top:420,width:200,height:200},{left:1070,top:390,width:170,height:220}];
  for(const [i,sourceRegion] of regions.entries()){
    const png=await sharp(read(source)).extract(sourceRegion).png().toBuffer(),file=OUT+'/materials/D'+(i+1)+'.png';
    write(file,png);
    materials.entries['corruption-v2-'+i]={file:'../../../'+file,family:'wall',source,sourceRegion,sourceSha256:hash(read(source)),sha256:hash(png)};
  }
}

function unwrap(model,variant,filter=()=>true){
  const faces=model.renderData.faces;
  for(const cap of faces.filter(f=>f.kind==='top'&&!f.wallVariation?.common&&f.wallVariation&&filter(f))){
    const adjacent=faces.filter(f=>{
      if(f.kind==='top'||!f.wallVariation||f.p[2]<.94/6-1e-5)return false;
      const p=f.p.map((v,i)=>i===2?1.88/6:v-f.normal[i]*.0001);
      return inside(project(p,model.anchor),cap.points);
    });
    if(!adjacent.length)continue;
    const vertices=B.physicalPolygon(cap,model.anchor),horizontal=/north|south/.test(cap.part);
    const xs=vertices.map(p=>p[0]),ys=vertices.map(p=>p[1]),h=vertices[0][2];
    const minX=Math.min(...xs),maxX=Math.max(...xs),minY=Math.min(...ys),maxY=Math.max(...ys);
    const low=Math.min(...adjacent.flatMap(f=>B.physicalPolygon(f,model.anchor).map(p=>p[2])));
    const span=Math.max(maxX-minX+(horizontal?0:h-low),maxY-minY+(horizontal?h-low:0))*1.15;
    const origin=[minX-span*.065,minY-span*.065];
    for(const f of [cap,...adjacent]){
      const world=(u,v)=>f===cap?[u,v,h]:horizontal?[u,maxY,h-(v-maxY)]:[maxX,v,h-(u-maxX)];
      const a=project(world(...origin),model.anchor),u=project(world(origin[0]+span,origin[1]),model.anchor),v=project(world(origin[0],origin[1]+span),model.anchor);
      const matrix=[(u[0]-a[0])/350,(u[1]-a[1])/350,(v[0]-a[0])/350,(v[1]-a[1])/350,...a].map(n=>Number(n.toFixed(9)));
      f.materialId='corruption-v2-'+variant;
      f.textureTransform='matrix('+matrix.join(' ')+')';
      f.surfaceMapping={type:'single_unfolded_stone',origin,span,h,low,fold:horizontal?maxY:maxX,plane:f===cap?'top':horizontal?'positive_y':'positive_x',matrix};
    }
  }
}
async function save(id,model,guide){
  const result=await R.render(model,guide,materials);
  write(OUT+'/'+id+'.png',result.png);write(OUT+'/'+id+'-overlay.png',result.overlay);
  json(OUT+'/'+id+'-report.json',{...result.report,mappedFaces:model.renderData.faces.filter(f=>f.surfaceMapping).map(f=>({part:f.part,kind:f.kind,material:f.materialId,points:f.points,...f.surfaceMapping}))});
  return result;
}
async function straight(orientation,variant){
  const horizontal=orientation==='horizontal',id=horizontal?'w01_p00_e00':'w08_p00_e00';
  const tiles=[-1,0,1].map(q=>({x:horizontal?q:0,y:horizontal?0:q,id:'cells/'+id}));
  const prepared=await C.prepareContext(tiles),model=prepared.model;
  model.drawAccent=false;B.vary(model,model.renderData.faces,0);unwrap(model,variant);
  return save(orientation+'/D'+(variant+1),model,prepared.guide);
}
async function corner(){
  const id='cells/w09_p00_e00',entry=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json')).entries[id];
  const model=makeModel(id,entry),guide=read('docs/reference/wireframe-overlays/'+entry.svg).toString();
  model.floorFinish=B.active.floorFinish;model.floorMaterialPattern=B.active.floorPattern.cells;model.drawAccent=false;
  model.renderData=await R.prepareFaces(model,guide);
  B.vary(model,model.renderData.faces,f=>/north/.test(f.part)?0:2);
  unwrap(model,0,f=>/north/.test(f.part));
  return save('corner',model,guide);
}
async function assemble(sequence){
  const width=(304+(sequence.length-1)*P)*S,layers=[];
  for(let i=0;i<sequence.length;i++)layers.push({input:read(OLD+'/source/floor.png'),left:(24+i*P)*S,top:88*S});
  for(const [i,id] of sequence.entries())layers.push({input:read((id.startsWith('D')?OUT:OLD)+'/horizontal/'+id+'.png'),left:i*P*S,top:0});
  const full=await sharp({create:{width,height:352*S,channels:4,background:'#080e19'}}).composite(layers).png().toBuffer();
  write(OUT+'/mixed-wall.png',await sharp(full).extract({left:0,top:0,width,height:190*S}).png().toBuffer());
}
async function boards(){
  const layers=[],labels=['D précédente · motif doublé','D1 · une seule fissure','D2 · autre veine'];
  for(const [i,file] of ['source/D-before.png','horizontal/D1.png','horizontal/D2.png'].entries())layers.push({input:await sharp(read(OUT+'/'+file)).extract({left:0,top:0,width:304*S,height:145*S}).resize({width:550}).png().toBuffer(),left:35+i*595,top:120});
  layers.push({input:await sharp(read(OUT+'/mixed-wall.png')).resize({width:1730}).png().toBuffer(),left:35,top:565});
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1820" height="800"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4"><text x="35" y="44" font-size="29">Corruption · une peinture continue autour de la pierre</text>${labels.map((s,i)=>`<text x="${35+i*595}" y="100" font-size="24">${s}</text>`).join('')}<text x="35" y="520" font-size="25">Exemple de mélange · deux accents différents parmi douze cases</text><text x="35" y="755" font-size="23">Mêmes volumes, joints et raccords · le motif ne recommence plus sur la façade</text><text x="35" y="785" font-size="20" fill="#aebed5">Proposition à valider · sols et scènes Godot conservés</text></g></svg>`;
  write(OUT+'/comparison.png',await sharp(Buffer.from(svg)).composite(layers).png().toBuffer());
  const corners=[];
  for(const [i,file] of ['source/corner-before.png','corner.png','corner-overlay.png'].entries())corners.push({input:await sharp(read(OUT+'/'+file)).resize({width:560}).png().toBuffer(),left:30+i*590,top:100});
  const csvg=`<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="800"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4">${['Avant · doublon','Après · texture continue','Overlay de géométrie'].map((s,i)=>`<text x="${30+i*590}" y="65" font-size="27">${s}</text>`).join('')}</g></svg>`;
  write(OUT+'/corner-comparison.png',await sharp(Buffer.from(csvg)).composite(corners).png().toBuffer());
  const vertical=[];
  for(const [i,file] of ['source/vertical-before.png','vertical/D1.png','vertical/D2.png'].entries())vertical.push({input:await sharp(read(OUT+'/'+file)).extract({left:0,top:0,width:135*S,height:352*S}).resize({height:760}).png().toBuffer(),left:30+i*340,top:90});
  const vsvg=`<svg xmlns="http://www.w3.org/2000/svg" width="1050" height="880"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4">${['Avant','D1','D2'].map((s,i)=>`<text x="${30+i*340}" y="55" font-size="27">${s}</text>`).join('')}</g></svg>`;
  write(OUT+'/vertical-comparison.png',await sharp(Buffer.from(vsvg)).composite(vertical).png().toBuffer());
}
async function main(){
  freeze(OLD+'/horizontal/D.png',OUT+'/source/D-before.png');
  freeze(OLD+'/vertical/D.png',OUT+'/source/vertical-before.png');
  freeze(OLD+'/corner-after.png',OUT+'/source/corner-before.png');
  await prepareMaterials();
  const reports=[];
  for(const orientation of ['horizontal','vertical'])for(let v=0;v<2;v++){const r=await straight(orientation,v);reports.push(r.report);console.log(orientation+' D'+(v+1));}
  reports.push((await corner()).report);
  await assemble(['A','B','D1','A','C','B','A','D2','C','A','B','A']);await boards();
  const sources=['tools/prepare_wall_corruption_review.cjs','tools/prepare_wall_variants_review.cjs','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','tools/connected_stone_context.cjs'];
  json(OUT+'/recipe.json',{status:'pending_visual_review_not_integrated',source:'Existing generated atlas; no new AI generation.',materials,reports,sourceHashes:Object.fromEntries(sources.map(s=>[s,hash(read(s))])),mapping:'One unfolded UV rectangle shared by the top and upper facade of each selected interior stone. Same UV at their physical common edge. Separate lighting profiles remain. No texture reset per face; no geometry or boundary stone changes.',scope:'Two corrupted variants on horizontal/vertical straight sprites, NW D1 corner, twelve-cell mixed wall. Not a full production context family.'});
  console.log(OUT+'/comparison.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
