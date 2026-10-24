// Review-only straight-wall variants. All geometry comes from the approved kit.
// Stones touching a connection use common quiet paint, so interior variations
// can be combined without changing the paint of a stone shared by two cells.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const C=require('./connected_stone_context.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {ROOT,read,hash,render,inside}=R;
const OUT='docs/reference/wall-variation-review',P=256,S=4;
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const freeze=(source,target)=>{if(!fs.existsSync(path.join(ROOT,target)))write(target,read(source));};
const names=['A · calme','B · usée','C · ébréchée','D · corrompue'];
freeze('assets/dungeon/shared-materials/catalog.json',OUT+'/source/materials-before.json');
freeze('docs/reference/material-variation-review/appearance-c-recipe.json',OUT+'/source/earlier-proposal.json');
const active=JSON.parse(read(OUT+'/source/materials-before.json'));
const materials=structuredClone(active);
materials.id='wall-variation-review';materials.status='appearance_review_not_integrated';
delete materials.approval;delete materials.approvedReview;
materials.purpose='Pending wall appearance proposal using frozen active floor settings and shared generated wall paint.';
const proposal=JSON.parse(read(OUT+'/source/earlier-proposal.json')).materials;
for(let i=1;i<=8;i++)materials.entries['variation-wall-'+i]=proposal.entries['variation-wall-'+i];
const ray=[.18,.9,1],dot=(a,b)=>a.reduce((n,v,i)=>n+v*b[i],0);
const round=n=>Math.round(n*10000)/10000;

async function prepareCrops(){
  // Crop the existing generated paint only; keep the original atlas unchanged.
  // The renderer samples the upper/left part of a square on narrow wall faces.
  const source='assets/dungeon/shared-materials/proposals/variation-review/atlas-calm.png';
  for(const [id,region] of Object.entries({
    quiet:{left:400,top:420,width:190,height:190},
    violet:{left:730,top:420,width:200,height:200},
    chip:{left:820,top:10,width:110,height:110}
  })){
    const file=OUT+'/materials/'+id+'.png',png=await sharp(read(source)).extract(region).png().toBuffer();
    write(file,png);
    materials.entries['wall-review-'+id]={file:'../../../'+file,family:'wall',source,sourceRegion:region,sourceSha256:hash(read(source)),sha256:hash(png)};
  }
}

function physicalPolygon(f,anchor){
  // Invert the fixed camera ray against this face's unchanged physical plane.
  return f.points.map(q=>{
    const o=[(q[0]-anchor[0])/P,(q[1]-anchor[1])/P,0];
    const t=dot(f.normal,f.p.map((v,i)=>v-o[i]))/dot(f.normal,ray);
    return o.map((v,i)=>round(v+t*ray[i]));
  });
}
function vary(model,faces,style){
  for(const f of faces){
    if(!/wall|pillar/.test(f.part))continue;
    const horizontal=/north|south/.test(f.part),axis=horizontal?0:1;
    const world=physicalPolygon(f,model.anchor),lo=Math.min(...world.map(p=>p[axis])),hi=Math.max(...world.map(p=>p[axis]));
    // Include stones ENDING on a cell boundary: their common paint also covers
    // the existing interior filtering guard. No rotated/mirrored source images.
    const common=Math.ceil(lo-1e-4)<=Math.floor(hi+1e-4);
    const phase=typeof style==='function'?style(f):style;
    let material='wall-review-quiet';
    if(!common){
      if(f.kind==='top'||f.p[2]>=.94/6-1e-5)material=['variation-wall-6','variation-wall-2','wall-review-chip','wall-review-violet'][phase];
      else{
        const second=(lo+hi)/2-Math.floor(lo)>.5;
        material=[['variation-wall-6','wall-review-quiet'],['variation-wall-2','variation-wall-6'],['variation-wall-3','wall-review-quiet'],['wall-review-quiet','variation-wall-1']][phase][Number(second)];
      }
    }
    f.materialId=material;
    f.wallVariation={phase,common,longitudinalBounds:[lo,hi]};
  }
  // Copy each top stone's new material onto its upper facade, as in production.
  for(const f of faces.filter(f=>f.kind!=='top'&&/wall/.test(f.part)&&f.p[2]>=.94/6-1e-5)){
    const p=f.p.map((v,i)=>i===2?1.88/6:v-f.normal[i]*.0001);
    const screen=[(p[0]-.18*p[2])*P+model.anchor[0],(p[1]-.9*p[2])*P+model.anchor[1]];
    const cap=faces.find(t=>t.kind==='top'&&inside(screen,t.points));
    if(cap){f.materialId=cap.materialId;f.wallVariation=cap.wallVariation;}
  }
}

async function straight(orientation,phase){
  const horizontal=orientation==='horizontal',variant=horizontal?'w01_p00_e00':'w08_p00_e00';
  const tiles=[-1,0,1].map(q=>({x:horizontal?q:0,y:horizontal?0:q,id:'cells/'+variant}));
  const prepared=await C.prepareContext(tiles),model=prepared.model;
  model.drawAccent=false;
  vary(model,model.renderData.faces,phase);
  const result=await render(model,prepared.guide,materials);
  const id=orientation+'/'+String.fromCharCode(65+phase);
  write(OUT+'/'+id+'.png',result.png);write(OUT+'/'+id+'-overlay.png',result.overlay);
  json(OUT+'/'+id+'-report.json',{...result.report,wallFaces:model.renderData.faces.filter(f=>f.wallVariation).map(f=>({points:f.points,material:f.materialId,...f.wallVariation}))});
  return {id,png:result.png,overlay:result.overlay,report:result.report};
}

async function assembly(orientation,sequence,variants){
  const horizontal=orientation==='horizontal',count=sequence.length;
  const size=horizontal?[304+(count-1)*P,352]:[304,352+(count-1)*P];
  const layers=[],overlays=[],old=[];
  const original='assets/dungeon/painted-connected/cells/'+(horizontal?'w01_p00_e00':'w08_p00_e00')+'.png';
  freeze(original,OUT+'/source/'+orientation+'-before.png');
  freeze('assets/dungeon/painted-connected/floor.png',OUT+'/source/floor.png');
  const floor=read(OUT+'/source/floor.png');
  for(let i=0;i<count;i++){
    const x=horizontal?i*P*S:0,y=horizontal?0:i*P*S;
    const ground={input:floor,left:x+24*S,top:y+88*S};
    layers.push(ground);overlays.push(ground);old.push(ground);
  }
  for(let i=0;i<count;i++){
    const x=horizontal?i*P*S:0,y=horizontal?0:i*P*S,v=variants[sequence[i]];
    layers.push({input:v.png,left:x,top:y});overlays.push({input:v.overlay,left:x,top:y});
    old.push({input:read(OUT+'/source/'+orientation+'-before.png'),left:x,top:y});
  }
  const frame={create:{width:size[0]*S,height:size[1]*S,channels:4,background:'#080e19'}};
  const crop=horizontal?{left:0,top:0,width:size[0]*S,height:190*S}:{left:0,top:0,width:200*S,height:size[1]*S};
  for(const [label,items] of [['after',layers],['overlay',overlays],['before',old]]){
    const full=await sharp(frame).composite(items).png().toBuffer();
    const png=await sharp(full).extract(crop).png().toBuffer();
    write(OUT+'/'+orientation+'-'+label+'.png',png);
  }
}

async function corner(){
  const id='cells/w09_p00_e00',entry=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json')).entries[id];
  const guide=read('docs/reference/wireframe-overlays/'+entry.svg).toString(),model=makeModel(id,entry);
  model.floorFinish=active.floorFinish;model.floorMaterialPattern=active.floorPattern.cells;
  model.drawAccent=false;
  model.resolveMaterials=faces=>vary(model,faces,f=>/north/.test(f.part)?3:2);
  const result=await render(model,guide,materials);
  freeze('assets/dungeon/painted-cells/'+id+'.png',OUT+'/source/corner-before.png');
  write(OUT+'/corner-after.png',result.png);write(OUT+'/corner-overlay.png',result.overlay);
  json(OUT+'/corner-report.json',result.report);
  const layers=[],labels=['Coin actuel','Murs variés · sol conservé','Même image + wireframe'];
  for(const [i,file] of ['source/corner-before.png','corner-after.png','corner-overlay.png'].entries())layers.push({input:await sharp(read(OUT+'/'+file)).resize({width:560}).png().toBuffer(),left:30+i*590,top:110});
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="850"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4">${labels.map((l,i)=>`<text x="${30+i*590}" y="70" font-size="26">${l}</text>`).join('')}<text x="30" y="807" font-size="23">Géométrie et finition conservées · accents peints dans la pierre · aucun trait violet ajouté</text></g></svg>`);
  write(OUT+'/corner-comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  return result.report;
}

async function boards(horizontal){
  const layers=[],labels=[];
  for(const [i,file,label] of [[0,'horizontal-before.png','Actuel · même séquence à chaque case'],[1,'horizontal-after.png','Proposition · A, B, A, C, B, D, A, C']]){
    layers.push({input:await sharp(read(OUT+'/'+file)).resize({width:1720}).png().toBuffer(),left:40,top:110+i*240});
    labels.push(`<text x="40" y="${88+i*240}" font-size="26">${label}</text>`);
  }
  for(let i=0;i<4;i++){
    const image=await sharp(horizontal[i].png).extract({left:0,top:0,width:304*S,height:145*S}).resize({width:410}).png().toBuffer();
    layers.push({input:image,left:40+i*435,top:655});
    labels.push(`<text x="${40+i*435}" y="628" font-size="24">${names[i]}</text>`);
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="940"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4"><text x="40" y="40" font-size="30">Quatre variantes de murs · une palette commune</text>${labels.join('')}<text x="40" y="894" font-size="22">Pierres de raccord communes · variantes préparées séparément puis assemblées</text><text x="40" y="925" font-size="20" fill="#aebed5">Proposition visuelle avant intégration · le sol lisse aux coins arrondis reste inchangé</text></g></svg>`);
  write(OUT+'/comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  const vlayers=[],vlabels=['Mur vertical actuel','Variantes A, C, B, D'];
  for(const [i,file] of ['vertical-before.png','vertical-after.png'].entries())vlayers.push({input:await sharp(read(OUT+'/'+file)).resize({height:1050}).png().toBuffer(),left:55+i*400,top:105});
  const vbg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="850" height="1210"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4">${vlabels.map((l,i)=>`<text x="${35+i*400}" y="70" font-size="23">${l}</text>`).join('')}<text x="35" y="1190" font-size="21">Même caméra · mêmes briques · PNG distincts</text></g></svg>`);
  write(OUT+'/vertical-comparison.png',await sharp(vbg).composite(vlayers).png().toBuffer());
  // Inspect a real B/A tile interface at the same enlarged framing.
  const detail=[];
  for(const [i,file] of ['horizontal-before.png','horizontal-after.png'].entries()){
    detail.push({input:await sharp(read(OUT+'/'+file)).extract({left:2*P*S-130,top:90,width:520,height:520}).resize(650,650).png().toBuffer(),left:35+i*700,top:100});
  }
  const dbg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1435" height="810"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial" fill="#dce5f4"><text x="35" y="65" font-size="27">Raccord actuel</text><text x="735" y="65" font-size="27">Raccord B / A · pierres communes</text><text x="35" y="791" font-size="21">Détail du même assemblage de PNG · revue visuelle des matières et des joints</text></g></svg>`);
  write(OUT+'/join-detail.png',await sharp(dbg).composite(detail).png().toBuffer());
}

async function main(){
  await prepareCrops();
  const output={};
  for(const orientation of ['horizontal','vertical']){
    output[orientation]=[];
    for(let phase=0;phase<4;phase++){output[orientation].push(await straight(orientation,phase));console.log(orientation+' '+names[phase]);}
    await assembly(orientation,orientation==='horizontal'?[0,1,0,2,1,3,0,2]:[0,2,1,3],output[orientation]);
  }
  const cornerReport=await corner();await boards(output.horizontal);
  const inputs=['tools/prepare_wall_variants_review.cjs','tools/connected_stone_context.cjs','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','tools/export_painted_image_catalog.cjs','docs/reference/floor-periodic-cell.json','assets/dungeon/shared-materials/stone-finish.json',OUT+'/source/materials-before.json',OUT+'/source/earlier-proposal.json'];
  const reports=Object.fromEntries(Object.entries(output).map(([k,vs])=>[k,vs.map(v=>v.report)]));
  const usedMaterials=[...new Set([...Object.values(reports).flat(),cornerReport].flatMap(r=>r.faces.map(f=>f.materialId)))];
  const materialHashes=Object.fromEntries(usedMaterials.map(id=>[id,hash(read('assets/dungeon/shared-materials/'+materials.entries[id].file))]));
  json(OUT+'/recipe.json',{status:'appearance_review_not_integrated',source:'assets/dungeon/shared-materials/proposals/variation-review/atlas-calm.png',sourceSha256:hash(read('assets/dungeon/shared-materials/proposals/variation-review/atlas-calm.png')),sourceHashes:Object.fromEntries(inputs.map(p=>[p,hash(read(p))])),materialHashes,materials,variants:names,reports,corner:cornerReport,rules:['Four variations of each connected straight-wall orientation, exported as separate PNGs.','Quiet common material for whole stones touching a longitudinal cell boundary, including filter guard.','Same material on upper facade and top plane of one stone.','No added procedural violet branch stroke.','No new runtime asset/catalog replacement.'],scope:'Horizontal A/B/A/C/B/D/A/C and vertical A/C/B/D review assemblies, plus NW corner. Not a complete production context family; arbitrary corners, doors and stairs are not yet covered.'});
  console.log(OUT+'/comparison.png');
}
module.exports={vary,physicalPolygon,materials,active,prepareCrops};
if(require.main===module)main().catch(e=>{console.error(e.stack);process.exitCode=1;});
