// Art direction proposals: generated materials on unchanged approved masks.
// Each variant runs in its own process, so compositor texture caches are isolated.
// No runtime assets, source geometry, or active material catalogs are overwritten.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {ROOT,read,hash,render}=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const OUT='docs/reference/corruption-material-review';
const generation=JSON.parse(read(OUT+'/generation.json'));
const guides=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json'));
function write(file,data){fs.mkdirSync(path.dirname(path.join(ROOT,file)),{recursive:true});fs.writeFileSync(path.join(ROOT,file),data);}
function json(file,data){write(file,JSON.stringify(data,null,2)+'\n');}
async function variant(id){
  const spec=generation.variants.find(v=>v.id===id);if(!spec)throw Error('Unknown proposal '+id);
  const atlas=read(spec.source),meta=await sharp(atlas).metadata(),qw=Math.floor(meta.width/2),qh=Math.floor(meta.height/2);
  const materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json')),swatches={};
  for(const [i,kind] of ['wall','floor','wood','iron'].entries()){
    const region={left:(i%2)*qw+8,top:Math.floor(i/2)*qh+8,width:qw-16,height:qh-16};
    const png=await sharp(atlas).extract(region).png().toBuffer(),file='proposals/corruption/'+id+'/'+kind+'.png';
    write('assets/dungeon/shared-materials/'+file,png);swatches[kind]={file,source:spec.source,sourceRegion:region,sha256:hash(png)};
  }
  const windows=[[.36,.03,.6],[.02,.30,.64],[.34,.35,.63],[.01,.03,.57]];
  const familyIndex={wall:0,floor:0};
  for(const key of Object.keys(materials.entries)){
    const kind=key.startsWith('walls-')?'wall':key.startsWith('floors-')?'floor':key==='door-oak'?'wood':'iron';
    let entry=swatches[kind];
    if(kind==='wall'||kind==='floor'){
      // Different rectangular surface samples from the SAME generated material.
      // No rotation or mirror: retain its painted lighting and mineral direction.
      const [x,y,size]=windows[familyIndex[kind]++],bounds=entry.sourceRegion;
      const region={left:bounds.left+Math.round(bounds.width*x),top:bounds.top+Math.round(bounds.height*y),width:Math.floor(bounds.width*size),height:Math.floor(bounds.height*size)};
      const png=await sharp(atlas).extract(region).png().toBuffer(),file='proposals/corruption/'+id+'/'+key+'.png';
      write('assets/dungeon/shared-materials/'+file,png);
      entry={file,source:spec.source,sourceRegion:region,sha256:hash(png)};
    }
    materials.entries[key]={...materials.entries[key],...entry};
  }
  // Common presentation profile for all three directions: source painting carries
  // the differences. No per-theme brightness rescue or runtime recoloring.
  materials.renderProfile.wood={color:'#343132',brightness:.86,saturation:.92,opacity:.96,blur:.3};
  materials.renderProfile.metal={color:'#252b38',brightness:.88,opacity:.9,blur:.3};
  const reports=[];
  for(const [label,key] of [['corner','cells/w09_p00_e00'],['door','doors/north']]){
    const entry=guides.entries[key],guide=read('docs/reference/wireframe-overlays/'+entry.svg).toString();
    const result=await render(makeModel(key,entry),guide,materials);
    write(OUT+'/'+id+'/'+label+'.png',result.png);write(OUT+'/'+id+'/'+label+'-overlay.png',result.overlay);
    const {faces,...report}=result.report;reports.push({...report,file:label+'.png',sha256:hash(result.png)});
  }
  json(OUT+'/'+id+'/recipe.json',{status:'proposal_only',source:spec.source,sourceSha256:hash(atlas),materials,reports,limitations:['One stone and one floor swatch per direction, reused to judge mood; a production library needs additional matching variants.','Embedded roots and cracks are surface studies, not a verified connected decoration system.']});
  console.log(JSON.stringify({variant:id,reports:reports.map(r=>({id:r.id,alphaDifference:r.alphaPixelsDifferentFromModel,constructionJointsMatch:r.constructionJointLayerMatchesGuide}))}));
}
async function sheet(){
  const columns=[{id:'current',name:'Actuel',subtitle:'Pour comparaison'},...generation.variants.map(v=>({id:v.id,name:v.name,subtitle:({'01-humide':'Humidité · pierre rongée','02-fissures':'Fissures · énergie violette','03-racines':'Racines · matière infectée'})[v.id]}))];
  const width=1728,height=1130,pitch=428,layers=[];
  let labels='';
  for(const [i,c] of columns.entries()){
    const left=8+i*pitch;
    labels+=`<text x="${left+14}" y="40" font-size="23" fill="#edf0fa">${c.name}</text><text x="${left+14}" y="68" font-size="16" fill="#aebcd0">${c.subtitle}</text>`;
    for(const [j,label] of ['corner','door'].entries()){
      const source=c.id==='current'?'assets/dungeon/painted-cells/'+(label==='corner'?'cells/w09_p00_e00.png':'doors/north.png'):OUT+'/'+c.id+'/'+label+'.png';
      const png=await sharp(read(source)).resize({width:408,height:472,fit:'inside'}).toBuffer(),meta=await sharp(png).metadata();
      layers.push({input:png,left:left+Math.round((416-meta.width)/2),top:92+j*486});
    }
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="100%" height="100%" fill="#0a101b"/><g font-family="Arial,sans-serif">${labels}<text x="22" y="1090" font-size="18" fill="#c3cee0">Même géométrie, même éclairage de composition · matières générées puis appliquées aux masques</text><text x="22" y="1116" font-size="16" fill="#96a6be">Propositions de style · coin de salle en haut, porte en bas · aucune variante intégrée dans Godot</text></g></svg>`);
  write(OUT+'/comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  console.log(OUT+'/comparison.png');
}
const id=process.argv.find(v=>v.startsWith('--variant='))?.slice(10);
(id?variant(id):sheet()).catch(e=>{console.error(e);process.exitCode=1;});
