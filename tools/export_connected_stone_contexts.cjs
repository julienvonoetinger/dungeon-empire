// Prepared PNG catalogue: ordinary occupancy contexts + authored special contexts.
const fs=require('node:fs'),path=require('node:path'),{spawnSync}=require('node:child_process');
const R=require('./painted_material_renderer.cjs'),C=require('./connected_stone_context.cjs');
const {applyWallVariation}=require('./wall_material_variation.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {importFile}=require('./export_painted_connected_kit.cjs');
const {ROOT,read,hash}=R,OUT='assets/dungeon/painted-connected';
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b),json=(p,o)=>write(p,JSON.stringify(o,null,2)+'\n');
const key=(m,e)=>`n${String(m).padStart(3,'0')}_e${String(e).padStart(2,'0')}`;
const terminal={north:'w14_p00_e00',east:'w13_p00_e00',south:'w11_p00_e00',west:'w07_p00_e00'};
const doorVariants={north:'w10_p00_e00',south:'w10_p00_e00',east:'w05_p00_e00',west:'w05_p00_e00'};
function ordinaryJobs(){
  const jobs=new Map(),defaults={};
  const wire=JSON.parse(read('assets/dungeon/wireframe-cells/catalog.json'));
  for(const [variant,v] of Object.entries(wire.entries)){
    if(!v.hasWalls)continue;
    let mask=15^(v.walls|v.exposedEnds);
    for(const [i,sides]of [9,3,6,12].entries())if((mask&sides)===sides&&!(v.piers&(1<<i)))mask|=1<<(i+4);
    const k=key(mask,v.exposedEnds),id='cells/'+variant;
    jobs.set(k,{tiles:C.tilesFor(mask,v.exposedEnds),preferred:id+'.png'});defaults[id]=k;
  }
  for(let mask=0;mask<256;mask++)for(let e=0;e<16;e++)if(!(mask&e&15)){
    const k=key(mask,e);if(!jobs.has(k))jobs.set(k,{tiles:C.tilesFor(mask,e)});
  }
  for(const family of ['doors','entrances'])for(const dir of ['north','east','south','west']){
    const variant=(family==='doors'?doorVariants:terminal)[dir],w=Number(variant.slice(1,3)),n=15^w,id=family+'/'+dir;
    for(let d=0;d<16;d++){
      const mask=n|(d<<4),k=key(mask,0)+'|0='+id,tiles=C.tilesFor(mask,0);tiles[0].id=id;
      jobs.set(k,{tiles,...(d===0?{preferred:id+'.png'}:{})});if(d===0)defaults[id]=k;
    }
  }
  // The same key is reused in every scene. The inventory supplies exact special
  // neighbours (including opposing entrances); it never names a painted room.
  const inventory=JSON.parse(read('docs/reference/painted-scene-contexts.json'));
  for(const [k,v] of Object.entries(inventory.contexts))jobs.set(k,{...jobs.get(k),tiles:v.tiles,scenes:v.scenes});
  return {jobs,defaults,wire};
}
async function exportKit(){
  const start=Date.now();
  const floor=spawnSync(process.execPath,[path.join(__dirname,'export_painted_connected_kit.cjs'),'--floor-only'],{cwd:ROOT,encoding:'utf8'});
  if(floor.status!==0)throw Error(floor.stderr||floor.stdout);console.log(floor.stdout.trim());
  const old=JSON.parse(read(OUT+'/catalog.json')),materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json'));
  const {jobs,defaults,wire}=ordinaryJobs(),specialsOnly=process.argv.includes('--specials-only');
  const styles=materials.wallVariation?.styles||['A'];
  if(specialsOnly&&!old.contexts)throw Error('A complete context export is required before a special-only refresh.');
  if(specialsOnly&&styles.length>1&&!old.contextStyles)throw Error('Wall variation promotion requires a complete export first.');
  const contexts=specialsOnly?Object.fromEntries(Object.entries(old.contexts).filter(([k])=>!k.includes('|'))):{};
  const contextStyles=specialsOnly?Object.fromEntries(Object.entries(old.contextStyles||{}).filter(([k])=>!k.includes('|'))):{};
  const kept=new Set([...Object.values(contexts),...Object.values(contextStyles).flat()].filter(Boolean));
  const entries=specialsOnly?Object.fromEntries(Object.entries(old.contextEntries).filter(([file])=>kept.has(file))):{};
  const signatures=new Map(),pixels=new Map(Object.values(entries).map(e=>[e.sha256,e.file]));
  const reports=specialsOnly?JSON.parse(read(OUT+'/validation.json')).reports.filter(r=>kept.has(r.file)):[];
  const sourcePaths=['tools/connected_stone_context.cjs','tools/export_connected_stone_contexts.cjs','tools/export_painted_connected_kit.cjs','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','tools/write_generated_file.cjs','tools/export_painted_image_catalog.cjs','tools/export_wireframe_cell_kit.cjs','assets/dungeon/shared-materials/catalog.json','assets/dungeon/shared-materials/stone-finish.json','docs/reference/painted-scene-contexts.json','docs/reference/wireframe-overlays/catalog.json','assets/dungeon/wireframe-cells/catalog.json','assets/dungeon/wireframe-entrances/catalog.json','assets/dungeon/wireframe-doors/catalog.json'];
  sourcePaths.push('tools/wall_material_variation.cjs');
  const sourceHashes={...old.sourceHashes,...Object.fromEntries(sourcePaths.map(p=>[p,hash(read(p))]))};
  const cacheVersion=hash(JSON.stringify(sourceHashes)),cacheDir='artifacts/stone-context-cache/'+cacheVersion.slice(0,16);
  let count=0,empty=Object.values(contexts).filter(v=>v===null).length;
  for(const [k,job]of jobs){
    if(specialsOnly&&!k.includes('|'))continue;
    const center=job.tiles.find(t=>!t.x&&!t.y);
    if(center.id.startsWith('cells/w00_p00')){contexts[k]=null;contextStyles[k]=styles.map(()=>null);empty++;continue;}
    const prepared=await C.prepareContext(job.tiles),files=[];
    for(const [phase,style]of styles.entries()){
      // Geometry is resolved once; each style changes only material choices/UV.
      const model={...prepared.model,renderData:{...prepared.model.renderData,faces:prepared.model.renderData.faces.map(f=>({...f}))}};
      if(materials.wallVariation)applyWallVariation(model,model.renderData.faces,phase,materials.wallVariation);
      const sig=hash(prepared.signature+JSON.stringify(model.renderData.faces.map(f=>[f.materialId,f.textureTransform||null])));
      if(signatures.has(sig)){files.push(signatures.get(sig));continue;}
      const cache=cacheDir+'/'+sig;let result;
      if(fs.existsSync(path.join(ROOT,cache+'.json')))result={png:read(cache+'.png'),report:JSON.parse(read(cache+'.json'))};
      else{
        try{result=await R.render(model,prepared.guide,materials);}
        catch(e){if(e.diagnostic){write('artifacts/context-failure.svg',e.diagnostic.drawing);write('artifacts/context-failure-model.svg',e.diagnostic.silhouette);json('artifacts/context-failure.json',{key:k,style,job,holes:e.diagnostic.holes,excess:e.diagnostic.excess});}throw e;}
        write(cache+'.png',result.png);const {faces,...report}=result.report;json(cache+'.json',report);
      }
      const sha=hash(result.png);let file=pixels.get(sha);
      if(!file){
        file=job.preferred?(phase===0?job.preferred:'variants/'+style+'/'+job.preferred):'contexts/'+sig.slice(0,20)+'.png';
        write(OUT+'/'+file,result.png);importFile(OUT+'/'+file);pixels.set(sha,file);
        const {faces,...report}=result.report;
        entries[file]={file,sha256:sha,imageSize:report.canvas,imageAnchor:report.anchor,materials:report.materials,contextSignature:sig,exampleContext:k,style};
        reports.push({...report,file,style,...prepared.report});
      }
      files.push(file);signatures.set(sig,file);
      if(++count%40===0)console.log(JSON.stringify({rendered:count,unique:Object.keys(entries).length,processedContexts:Object.keys(contexts).length,total:jobs.size,seconds:Math.round((Date.now()-start)/1000)}));
    }
    contextStyles[k]=files;contexts[k]=files[0];
  }
  const aliases={},legacyEntries={};
  for(const [id,k]of Object.entries(defaults)){
    const file=contexts[k];aliases[id]=id;legacyEntries[id]={...entries[file],defaultContext:k};
  }
  const manifest={...old,id:'painted-connected-wall-variants-d2-v3',generator:'tools/export_painted_connected_kit.cjs',contextGenerator:'tools/export_connected_stone_contexts.cjs',policy:'Finished per-cell PNGs painted from complete local stone faces. Runtime selects occupancy/special-neighbour context and prepared wall style; no runtime paint or geometry.',wallStyles:styles,sourceHashes,entries:legacyEntries,aliases,contextEntries:entries,contexts,contextStyles,emptyVariants:Object.entries(wire.entries).filter(([,v])=>!v.hasWalls).map(([id])=>id)};
  // Partial exports must retain the ordinary walls' original provenance.
  if(specialsOnly){manifest.sourceHashes=old.sourceHashes;manifest.specialSourceHashes=sourceHashes;}
  else delete manifest.specialSourceHashes;
  json(OUT+'/catalog.json',manifest);
  json(OUT+'/validation.json',{uniqueStructuralImages:Object.keys(entries).length,logicalContexts:Object.keys(contexts).length,emptyContexts:empty,allConstructionJointLayersMatch:reports.every(r=>r.constructionJointLayerMatchesGuide),alphaPixelsDifferentFromContextModel:reports.reduce((n,r)=>n+r.alphaPixelsDifferentFromModel,0),unpaintedInteriorPixels:reports.reduce((n,r)=>n+r.unpaintedInteriorPixels,0),reports,floor:JSON.parse(read(OUT+'/validation.json')).floor,scope:'Prepared geometry/mask export audit. Individual alpha includes interior filter guards; visual captures remain necessary.'});
  const gd=['# Generated by tools/export_connected_stone_contexts.cjs. Prepared PNG paths only.','extends RefCounted','const CELL_PIXELS := 256.0','const TEXTURE_SCALE := 0.25','const WALL_ANCHOR := Vector2(24, 88)','const FLOOR_ANCHOR := Vector2(0, 0)','const ENTRANCE_ANCHOR := Vector2(24, 88)','const DOOR_ANCHOR := Vector2(24, 128)',`const FLOOR = preload("res://${OUT}/floor.png")`,`const EMPTY_VARIANTS := ${JSON.stringify(manifest.emptyVariants)}`,`const TERMINAL_DIRECTIONS := ${JSON.stringify(Object.fromEntries(Object.entries(terminal).map(([dir,v])=>[v,dir])))}`,`const DOOR_VARIANTS := ${JSON.stringify(doorVariants)}`,'# String paths avoid eagerly loading every local configuration into VRAM.','const CONTEXT_PATHS := {',...Object.entries(contexts).map(([k,file])=>`\t${JSON.stringify(k)}: ${file?JSON.stringify('res://'+OUT+'/'+file):'""'},`),'}',''];
  gd.push('# Authoring fallback for a new special-neighbour arrangement; export its context before review.','const FALLBACK_PATHS := {',...Object.entries(legacyEntries).map(([id,e])=>`\t${JSON.stringify(id)}: ${JSON.stringify('res://'+OUT+'/'+e.file)},`),'}','');
  const paths=files=>JSON.stringify(files.map(file=>file?'res://'+OUT+'/'+file:''));
  gd.push(`const WALL_STYLES := ${JSON.stringify(styles)}`,'const CONTEXT_STYLE_PATHS := {',...Object.entries(contextStyles).map(([k,files])=>`\t${JSON.stringify(k)}: ${paths(files)},`),'}','const FALLBACK_STYLE_PATHS := {',...Object.entries(defaults).map(([id,k])=>`\t${JSON.stringify(id)}: ${paths(contextStyles[k])},`),'}','');
  write('scripts/painted_cell_catalog.gd',gd.join('\n'));
  console.log(JSON.stringify({done:true,uniqueImages:Object.keys(entries).length,contexts:Object.keys(contexts).length,seconds:Math.round((Date.now()-start)/1000)}));
}
module.exports={exportKit,ordinaryJobs};
if(require.main===module)exportKit().catch(e=>{console.error(e.stack);process.exitCode=1;});
