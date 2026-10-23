// Appearance study only. Uses the approved offline face compositor and geometry.
// No active PNG/catalog replacement, no whole-room production sprites.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {ROOT,read,hash,svg,render,parseLines}=R;
const OUT='docs/reference/material-variation-review',MAT='assets/dungeon/shared-materials';
const SRC=MAT+'/proposals/variation-review/atlas-calm.png',S=4,P=256,COLS=6,ROWS=3;
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const seed=p=>parseInt(hash(JSON.stringify(p)).slice(0,8),16)>>>0;
const ink=lines=>lines.map(l=>`<line x1="${l.a[0]}" y1="${l.a[1]}" x2="${l.b[0]}" y2="${l.b[1]}" stroke="#ff00ff" stroke-width="${l.width}"/>`).join('');

async function library(){
  const atlas=read(SRC),meta=await sharp(atlas).metadata(),w=Math.floor(meta.width/4),h=Math.floor(meta.height/4);
  const materials=JSON.parse(read(MAT+'/catalog.json')),names=[];
  for(let i=0;i<16;i++){
    const family=i<8?'wall':'floor',id=`variation-${family}-${i%8+1}`,region={left:(i%4)*w+6,top:Math.floor(i/4)*h+6,width:w-12,height:h-12};
    const file=`proposals/variation-review/${id}.png`,png=await sharp(atlas).extract(region).png().toBuffer();
    write(MAT+'/'+file,png);materials.entries[id]={file,family,source:SRC,sourceRegion:region,sha256:hash(png)};names.push(id);
  }
  // Slightly stronger painted floor detail, only in this proposal.
  materials.renderProfile.floor.opacity=.78;
  return {materials,names};
}

function sourceGeometry(input,x){
  const dx=x*P,lines=parseLines(input).map(l=>({...l,a:[l.a[0]+dx,l.a[1]],b:[l.b[0]+dx,l.b[1]]}));
  const polys=[...input.matchAll(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)].flatMap(([s])=>s.startsWith('<polygon')?[s.match(/points="([^"]+)"/)[1].split(' ').map(p=>p.split(',').map(Number))]:s.match(/d="([^"]*)"/)[1].split('M').filter(Boolean).map(p=>p.replace(/Z$/,'').split('L').map(p=>p.split(',').map(Number))));
  const d=polys.map(ps=>{if(ps.reduce((a,p,i)=>a+p[0]*ps[(i+1)%ps.length][1]-p[1]*ps[(i+1)%ps.length][0],0)<0)ps.reverse();return 'M'+ps.map(p=>[p[0]+dx,p[1]].join(',')).join('L')+'Z';}).join('');
  return {lines,d};
}

async function wallStudy(materials,names,options={}){
  const size=[304+(COLS-1)*P,352],anchor=[24,88],model={id:'variation-review/wall',size,anchor,surfaces:[],floor:false,clipPaint:true,stableStones:true,drawAccent:false};
  const entries=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json')).entries;
  let d='',lines=[];const old=[];
  for(let x=0;x<COLS;x++){
    const variant=x===0?'w01_p00_e08':x===COLS-1?'w01_p00_e02':'w01_p00_e00',id='cells/'+variant;
    const m=makeModel(id,entries[id]),g=sourceGeometry(read('assets/dungeon/wireframe-cells/'+variant+'.svg').toString(),x);
    model.surfaces.push(...m.surfaces.map(f=>({...f,points:f.points.map(p=>[p[0]+x,p[1],p[2]])})));
    lines.push(...g.lines);d+=g.d;
    old.push({input:read(options.baselineDirectory?options.baselineDirectory+'/'+variant+'.png':'assets/dungeon/painted-connected/'+id+'.png'),left:x*P*S,top:0});
  }
  const seen=new Set();lines=lines.filter(l=>{const k=JSON.stringify([l.a,l.b,l.width]);if(seen.has(k))return false;seen.add(k);return true;});
  model.silhouette=`<path d="${d}" fill="#fff"/>`;
  model.resolveMaterials=faces=>{for(const f of faces){const n=seed([f.kind,f.points.map(p=>p.map(v=>Math.round(v*1000)/1000))]);f.bevelSeed=n%100000;const choice=n%24;f.materialId=names[choice<22?choice%6:choice-16];}};
  const guide=svg(size,ink(lines)),result=await render(model,guide,materials);
  const frame={left:0,top:0,width:size[0]*S,height:142*S};
  const before=await sharp({create:{width:size[0]*S,height:size[1]*S,channels:4,background:'#080e19'}}).composite(old).png().toBuffer();
  write(OUT+'/wall-before.png',await sharp(before).extract(frame).png().toBuffer());
  write(OUT+'/wall-proposal.png',await sharp(result.png).extract(frame).flatten({background:'#080e19'}).png().toBuffer());
  write(OUT+'/wall-overlay.png',await sharp(result.overlay).extract(frame).flatten({background:'#080e19'}).png().toBuffer());
  write(OUT+'/wall-guide.svg',guide);
  return result.report;
}

async function floorStudy(materials,names,options={}){
  const layout=options.layout||JSON.parse(read(OUT+'/source/floor-periodic-cell-before-c.json')).floor;
  const cols=options.cols||COLS,rows=options.rows||ROWS,id=options.id||'floor';
  const size=[cols*P,rows*P],faces=[],lines=[];
  const add=(x0,x1,y0,y1,key)=>{
    const points=[[x0,y0],[x1,y0],[x1,y1],[x0,y1]].map(([x,y])=>[x/6*P,y/5*P]);
    const n=seed(key),pick=n%10;
    const materialIndex=options.quietFloor?[2,4,5,7,2,4,5,7,0,1,2,3,4,5,6,7][n%16]:(pick<8?pick:pick===8?0:3);
    const materialId=names[8+materialIndex];
    faces.push({points,kind:'floor',part:'floor',p:[(x0+x1)/12,(y0+y1)/10,0],normal:[0,0,1],materialId,bevelSeed:n%100000});
    points.forEach((p,i)=>lines.push({a:p,b:points[(i+1)%4],width:1.5}));
  };
  for(let cy=0;cy<rows;cy++){
    let y=cy*5;
    layout.rowWidths.forEach((widths,row)=>{
      const next=y+layout.rowHeights[row];
      for(let cx=0;cx<=cols;cx++)add(cx*6-widths.at(-1),cx*6+widths[0],y,next,[cy,row,cx,'crossing']);
      for(let cx=0;cx<cols;cx++){let x=cx*6+widths[0];for(let i=1;i<widths.length-1;i++){add(x,x+widths[i],y,next,[cy,row,cx,i]);x+=widths[i];}}
      y=next;
    });
  }
  const seen=new Set(),unique=lines.filter(l=>{const k=JSON.stringify([...[l.a,l.b].sort((a,b)=>a[0]-b[0]||a[1]-b[1]),l.width]);if(seen.has(k))return false;seen.add(k);return true;});
  // Render one logical row at a time: embedded raster data stays below the SVG
  // parser limit. Global stone identities are assigned before this framing.
  const strips=[],overlays=[],reports=[],old=[];
  for(let row=0;row<rows;row++){
    const offset=row*P,rowSize=[size[0],P];
    const rowFaces=faces.filter(f=>Math.min(...f.points.map(p=>p[1]))>=offset-.0001&&Math.max(...f.points.map(p=>p[1]))<=offset+P+.0001).map(f=>({...f,points:f.points.map(p=>[p[0],p[1]-offset])}));
    const rowLines=unique.filter(l=>Math.min(l.a[1],l.b[1])>=offset-.0001&&Math.max(l.a[1],l.b[1])<=offset+P+.0001).map(l=>({...l,a:[l.a[0],l.a[1]-offset],b:[l.b[0],l.b[1]-offset]}));
    const model={id:'variation-review/'+id+'-row-'+row,size:rowSize,anchor:[0,0],surfaces:[],floor:false,drawAccent:false,stableStones:true,clipPaint:true,silhouette:`<rect width="${rowSize[0]}" height="${rowSize[1]}" fill="#fff"/>`,renderData:{faces:rowFaces,lines:rowLines,visibility:null}};
    if(options.floorFinish)model.floorFinish=options.floorFinish;
    const result=await render(model,svg(rowSize,ink(rowLines)),materials);
    strips.push({input:result.png,left:0,top:offset*S});overlays.push({input:result.overlay,left:0,top:offset*S});reports.push(result.report);
  }
  for(let y=0;y<rows;y++)for(let x=0;x<cols;x++)old.push({input:read(options.baselineFile||OUT+'/source/floor-before-c.png'),left:x*P*S,top:y*P*S});
  const before=await sharp({create:{width:size[0]*S,height:size[1]*S,channels:4,background:'#080e19'}}).composite(old).png().toBuffer();
  const frame={create:{width:size[0]*S,height:size[1]*S,channels:4,background:'#080e19'}};
  write(OUT+'/'+id+'-before.png',before);write(OUT+'/'+id+'-proposal.png',await sharp(frame).composite(strips).png().toBuffer());write(OUT+'/'+id+'-overlay.png',await sharp(frame).composite(overlays).png().toBuffer());
  return {layout,grid:[cols,rows],rows:reports,wholeStoneCount:faces.length};
}

async function floorSizeStudy(materials,names){
  const variants=[
    {id:'size-6',label:'A · 6 rangées par case',detail:'Découpage précédent',layout:JSON.parse(read(OUT+'/source/floor-periodic-cell-before-c.json')).floor},
    {id:'size-3',label:'B · 3 rangées par case',detail:'Dalles moyennes',layout:{bounds:[0,0,6,5],z:0,rowHeights:[5/3,5/3,5/3],rowWidths:[[.9,2,2.2,.9],[1.6,2.15,2,.25],[.35,2.2,1.9,1.55]]}},
    {id:'size-2',label:'C · 2 rangées par case',detail:'Grandes dalles',layout:{bounds:[0,0,6,5],z:0,rowHeights:[2.5,2.5],rowWidths:[[1.15,3.05,1.8],[2.3,3.15,.55]]}}
  ];
  const layers=[],labels=[],reports=[];
  for(let i=0;i<variants.length;i++){
    const v=variants[i];reports.push({id:v.id,...await floorStudy(materials,names,{...v,cols:3,rows:3})});
    layers.push({input:await sharp(read(OUT+'/'+v.id+'-proposal.png')).resize(540,540).png().toBuffer(),left:30+i*570,top:170});
    labels.push(`<text x="${30+i*570}" y="116" font-size="27" fill="#f1f4fb">${v.label}</text><text x="${30+i*570}" y="150" font-size="22" fill="#aebed7">${v.detail}</text>`);
    console.log(v.id+' rendered.');
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1740" height="830"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial"><text x="30" y="46" font-size="32" fill="#f1f4fb">Taille des dalles · même surface de 3 × 3 cases</text>${labels.join('')}<text x="30" y="760" font-size="23" fill="#becce0">Même échelle, même gamme de matières et mêmes bords adoucis.</text><text x="30" y="797" font-size="22" fill="#9dafca">La grille logique reste en 1 × 1. Étude de découpage du sol, sans modification des scènes Godot.</text></g></svg>`);
  write(OUT+'/floor-size-comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  json(OUT+'/floor-size-proposals.json',{status:'geometry_appearance_proposal_not_integrated',source:SRC,sourceSha256:hash(read(SRC)),cell:[1,1],variants:reports,scope:'Same 3x3 cell area and material pool. Whole crossing stones painted before framing. Neither a production tile catalog nor artistic approval.'});
}

async function main(){
  const {materials,names}=await library();
  if(process.argv.includes('--floor-sizes-only')){await floorSizeStudy(materials,names);return;}
  const wall=await wallStudy(materials,names);console.log('Wall proposal rendered.');
  const floor=await floorStudy(materials,names);console.log('Floor proposal rendered.');
  const layers=[],labels=[];
  const W=1640,H=1220;
  for(const [file,y,label] of [['wall-before.png',112,'Mur actuel — séquence répétée'],['wall-proposal.png',338,'Proposition — matières variées, corruption ponctuelle']]){
    const img=await sharp(read(OUT+'/'+file)).resize({width:1560}).png().toBuffer();layers.push({input:img,left:40,top:y});labels.push(`<text x="40" y="${y-20}" font-size="24" fill="#dce5f4">${label}</text>`);
  }
  for(const [i,file,label] of [[0,'floor-before.png','Sol actuel'],[1,'floor-proposal.png','Proposition — usure et motifs répartis']]){
    const img=await sharp(read(OUT+'/'+file)).resize({width:760}).png().toBuffer();layers.push({input:img,left:40+i*800,top:620});labels.push(`<text x="${40+i*800}" y="590" font-size="24" fill="#dce5f4">${label}</text>`);
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial"><text x="40" y="46" font-size="30" fill="#f1f4fb">Variété des matières · aperçu à valider</text>${labels.join('')}<text x="40" y="1075" font-size="22" fill="#b6c4da">8 matières de mur · 8 matières de sol · mêmes joints, projection et finition B</text><text x="40" y="1115" font-size="20" fill="#a0b2cd">Le trait violet ajouté est retiré. Les petites lueurs font partie de la matière peinte.</text><text x="40" y="1155" font-size="20" fill="#a0b2cd">Étude d’apparence hors ligne · les scènes Godot utilisent encore le catalogue actuel.</text></g></svg>`);
  write(OUT+'/comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  json(OUT+'/recipe.json',{status:'appearance_proposal_not_integrated',source:SRC,sourceSha256:hash(read(SRC)),materials,wall,floor,rules:['No added violet branch strokes.','Eight independent painted wall surfaces; two corrupted samples are rare.','Eight floor surfaces, deterministic assignment per complete stone.','Whole-face paint before cuts; no per-fragment material randomization.','No geometry/layout changes or runtime texture generation.'],scope:'Wide appearance study only, not a reusable variant catalog or proof of arbitrary cell joins.'});
  console.log(OUT+'/comparison.png');
  await floorSizeStudy(materials,names);
}
module.exports={library,wallStudy,floorStudy,seed,OUT,SRC};
if(require.main===module)main().catch(e=>{if(e.diagnostic){write(OUT+'/failure.svg',e.diagnostic.drawing);write(OUT+'/failure-model.svg',e.diagnostic.silhouette);}console.error(e.stack);process.exitCode=1;});
