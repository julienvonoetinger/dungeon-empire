// Offline connected architecture. Runtime only selects these finished PNGs.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs'),{makeModel}=require('./export_painted_image_catalog.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {ROOT,read,hash,render,svg}=R,OUT='assets/dungeon/painted-connected';
const isolated=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json'));
const wire=JSON.parse(read('assets/dungeon/wireframe-cells/catalog.json'));
const materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json'));
const manifest={id:'painted-connected-shared-materials-v1',generator:'tools/export_painted_connected_kit.cjs',projection:wire.projection,cell:[1,1],cellPixels:256,textureScale:.25,wallAnchor:[24,88],floorAnchor:[4,4],doorAnchor:[24,128],sourcePixelScale:4,policy:'Prepared floor first, then at most one complete structural PNG per cell. Internal port faces omitted offline, no runtime painting, clipping, tint or flipping.',entries:{},aliases:{},emptyVariants:[]};
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
function importFile(p){
  // Godot supplies the UID on import. Keep predictable lossless+mipmap settings.
  const file=path.basename(p),dest=`res://.godot/imported/${file}-${crypto.createHash('md5').update('res://'+p).digest('hex')}.ctex`;
  const existing=fs.existsSync(path.join(ROOT,p+'.import'))?read(p+'.import').toString():'';
  if(existing){write(p+'.import',existing.replace('mipmaps/generate=false','mipmaps/generate=true'));return;}
  write(p+'.import',`[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="${dest}"\nmetadata={"vram_texture": false}\n\n[deps]\nsource_file="res://${p}"\ndest_files=["${dest}"]\n\n[params]\ncompress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=true\nprocess/premult_alpha=false\nprocess/size_limit=0\ndetect_3d/compress_to=1\n`);
}
function structuralSource(source,special){
  const allFills=[...source.matchAll(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)].map(m=>m[0]);
  if(special)allFills.shift(); // first polygon is the complete ground plane
  const lines=[...source.matchAll(/<line\b[^>]*\/>/g)].map(m=>m[0]).filter(l=>!l.includes('#8794a3')).map(l=>l.replace(/stroke="#[a-fA-F0-9]+"/,'stroke="#ff00ff"'));
  const header=source.match(/^<svg[^>]*>/)[0];
  // Give overlapping projected surfaces one consistent winding in the mask.
  // Otherwise a clip renderer can cancel opposite-facing source polygons.
  const polygons=allFills.flatMap(s=>s.startsWith('<polygon')?[s.match(/points="([^"]+)"/)[1].split(' ').map(p=>p.split(',').map(Number))]:s.match(/d="([^"]+)"/)[1].split('M').filter(Boolean).map(p=>p.replace(/Z$/,'').split('L').map(p=>p.split(',').map(Number))));
  const d=polygons.map(p=>{const a=p.reduce((s,q,i)=>s+q[0]*p[(i+1)%p.length][1]-q[1]*p[(i+1)%p.length][0],0);if(a<0)p.reverse();return 'M'+p.map(q=>q.join(',')).join('L')+'Z';}).join('');
  return {fill:`<path d="${d}" fill="#ffffff"/>`,guide:header+(special?'<g stroke-linecap="round" stroke-linejoin="round">':'')+lines.join('')+(special?'</g>':'')+'</svg>'};
}
async function main(){
  const floorOnly=process.argv.includes('--floor-only');
  if(floorOnly)Object.assign(manifest,JSON.parse(read(OUT+'/catalog.json')));
  manifest.emptyVariants=[];
  const jobs=Object.entries(wire.entries).filter(([id,e])=>{if(!e.hasWalls)manifest.emptyVariants.push(id);return e.hasWalls;}).map(([id,e])=>({id:'cells/'+id,source:'assets/dungeon/wireframe-cells/'+e.file}));
  for(const family of ['entrances','doors'])for(const dir of ['north','east','south','west'])jobs.push({id:family+'/'+dir,source:`assets/dungeon/wireframe-${family}/${dir}.svg`});
  const only=process.argv.find(a=>a.startsWith('--only='))?.slice(7).split(','),unique=new Map(),reports=[];
  for(const job of jobs){
    if(floorOnly)break;
    if(only&&!only.includes(job.id))continue;
    const input=read(job.source).toString(),key=hash(input),model=makeModel(job.id,isolated.entries[job.id]);
    if(unique.has(key)){manifest.aliases[job.id]=unique.get(key);continue;}unique.set(key,job.id);manifest.aliases[job.id]=job.id;
    const prepared=structuralSource(input,!job.id.startsWith('cells/'));
    model.floor=false;model.silhouette=prepared.fill;model.clipPaint=true;
    model.paintGuide=read('docs/reference/wireframe-overlays/'+isolated.entries[job.id].svg).toString();
    try{
      const result=await render(model,prepared.guide,materials),file=job.id+'.png';
      write(OUT+'/'+file,result.png);importFile(OUT+'/'+file);
      write('artifacts/painted-connected/'+job.id+'-overlay.png',result.overlay);
      write('artifacts/painted-connected/'+job.id+'-guide.svg',prepared.guide);
      const {faces,...report}=result.report;reports.push(report);
      manifest.entries[job.id]={file,source:job.source,sourceSha256:hash(input),paintGuide:isolated.entries[job.id].svg,paintGuideSha256:hash(model.paintGuide),sha256:hash(result.png),imageSize:report.canvas,imageAnchor:report.anchor,materials:report.materials};
      console.log(`${job.id}: ${report.segmentCount} segments, alpha ${report.alphaPixelsDifferentFromModel}`);
    }catch(e){if(e.diagnostic){const prefix='artifacts/painted-connected/failure-'+job.id.replaceAll('/','-');write(prefix+'.svg',e.diagnostic.drawing);write(prefix+'-model.svg',e.diagnostic.silhouette);await sharp(Buffer.from(e.diagnostic.drawing)).png().toFile(path.join(ROOT,prefix+'.png'));}throw e;}
  }
  if(only)return;
  // Copy only the connected floor's actual joints. Standalone review guides add
  // west/east/south outlines that must not become dark borders around each cell.
  const floorFile=OUT+'/floor.png',floorSource='assets/dungeon/wireframe-cells/floor.svg',floorInput=read(floorSource).toString();
  const floorLines=[...floorInput.matchAll(/<path d="M([\d.]+) ([\d.]+)(H|V)([\d.]+)"\/>/g)].map(m=>{
    const x=+m[1]+4,y=+m[2]+4,end=+m[4]+4;
    return `<line x1="${x}" y1="${y}" x2="${m[3]==='H'?end:x}" y2="${m[3]==='V'?end:y}" stroke="#ff00ff" stroke-width="1.5"/>`;
  });
  if(floorLines.length!==JSON.parse(read('docs/reference/floor-periodic-cell.json')).connectedSegmentCount)throw Error('Unexpected connected floor source joints');
  const floorGuide=`<svg xmlns="http://www.w3.org/2000/svg" width="264" height="264" viewBox="0 0 264 264">${floorLines.join('')}</svg>`;
  const floorModel=makeModel('floor',isolated.entries.floor);
  floorModel.paintGuide=read('docs/reference/wireframe-overlays/'+isolated.entries.floor.svg).toString();
  floorModel.wrapFloorX=true;
  floorModel.clipPaint=true;
  // An opaque exact-cell texture avoids alpha blending against transparent
  // gutters at minified sprite boundaries. The logical floor stays 1x1.
  floorModel.outputFrame=[4,4,256,256];
  floorModel.repeatInkY=256;
  const floorResult=await render(floorModel,floorGuide,materials);
  write(floorFile,floorResult.png);importFile(floorFile);
  write('artifacts/painted-connected/floor-overlay.png',floorResult.overlay);
  write('artifacts/painted-connected/floor-guide.svg',floorGuide);
  manifest.floor={file:'floor.png',sha256:hash(floorResult.png),source:floorSource,sourceSha256:hash(floorInput),guideSha256:hash(floorGuide),imageSize:floorResult.report.canvas,imageAnchor:floorResult.report.anchor,materialContinuity:'Periodic X: boundary fragments share one complete slab, material, texture coordinates and bevel seed; clip only at offline export.'};
  manifest.floorAnchor=[0,0];
  manifest.sourceHashes=Object.fromEntries(['docs/reference/floor-periodic-cell.json','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','tools/write_generated_file.cjs','assets/dungeon/shared-materials/stone-finish.json','tools/export_painted_connected_kit.cjs','tools/export_painted_image_catalog.cjs','assets/dungeon/shared-materials/catalog.json','assets/dungeon/wireframe-cells/catalog.json','assets/dungeon/wireframe-entrances/catalog.json','assets/dungeon/wireframe-doors/catalog.json'].map(p=>[p,hash(read(p))]));
  json(OUT+'/catalog.json',manifest);
  const validation=floorOnly?JSON.parse(read(OUT+'/validation.json')):{uniqueStructuralImages:reports.length,logicalStructuralVariants:jobs.length,emptyVariants:manifest.emptyVariants.length,allConstructionJointLayersMatch:reports.every(r=>r.constructionJointLayerMatchesGuide),alphaPixelsDifferentFromModel:reports.reduce((n,r)=>n+r.alphaPixelsDifferentFromModel,0),unpaintedInteriorPixels:reports.reduce((n,r)=>n+r.unpaintedInteriorPixels,0),extraInteriorPixels:reports.reduce((n,r)=>n+r.extraInteriorPixels,0),reports};
  const {faces:floorFaces,...floorReport}=floorResult.report;
  validation.floor=floorReport;
  json(OUT+'/validation.json',validation);
  const preload=id=>`preload("res://${OUT}/${manifest.entries[manifest.aliases[id]].file}")`;
  const lines=['# Generated by tools/export_painted_connected_kit.cjs. Finished PNGs only.','extends RefCounted','const CELL_PIXELS := 256.0','const TEXTURE_SCALE := 0.25','const WALL_ANCHOR := Vector2(24, 88)','const FLOOR_ANCHOR := Vector2(0, 0)','const ENTRANCE_ANCHOR := Vector2(24, 88)','const DOOR_ANCHOR := Vector2(24, 128)',`const FLOOR = preload("res://${floorFile}")`,`const EMPTY_VARIANTS := ${JSON.stringify(manifest.emptyVariants)}`,'const WALLS := {',...Object.keys(manifest.aliases).filter(id=>id.startsWith('cells/')).map(id=>`\t"${id.slice(6)}": ${preload(id)},`),'}','const TERMINALS := {'];
  const variants={north:'w14_p00_e00',east:'w13_p00_e00',south:'w11_p00_e00',west:'w07_p00_e00'};
  for(const [dir,v] of Object.entries(variants))lines.push(`\t"${v}": ${preload('entrances/'+dir)},`);
  lines.push('}','const DOORS := {',...Object.keys(variants).map(dir=>`\t"${dir}": ${preload('doors/'+dir)},`),'}','const DOOR_VARIANTS := {','\t"north": "w10_p00_e00", "south": "w10_p00_e00",','\t"east": "w05_p00_e00", "west": "w05_p00_e00",','}','');
  write('scripts/painted_cell_catalog.gd',lines.join('\n'));
  console.log(JSON.stringify({structuralImages:validation.uniqueStructuralImages,variants:jobs.length,empty:manifest.emptyVariants.length,floorSegments:floorLines.length}));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
