// Read-only artifact integrity and captured-scene observations.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-prop-review/v1/integration';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const rect=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
async function main(){
 const baseline=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json'),current=read('assets/dungeon/isometric-kit/catalog.json');
 let retained=0;
 for(const [id,e] of Object.entries(baseline.atlas.regions)){
  const n=current.atlas.regions[id];if(!n)throw Error('Lost original region '+id);
  const a=await sharp(abs(OUT+'/before/assets/dungeon/isometric-kit/atlas-256.png')).extract(rect(e.region)).raw().toBuffer();
  const b=await sharp(abs('assets/dungeon/isometric-kit/atlas-256.png')).extract(rect(n.region)).raw().toBuffer();
  if(!a.equals(b))throw Error('Original pixels changed '+id);
  const {region:ar,...am}=e,{region:br,...bm}=n;
  if(JSON.stringify(am)!==JSON.stringify(bm))throw Error('Original metadata changed '+id);
  retained++;
 }
 const selection=read('docs/reference/isometric-prop-review/v1/selection.json');
 for(const [file,expected] of Object.entries(selection.reviewedFiles))if(hash(file)!==expected)throw Error('Selected reference changed '+file);
 const obs=read(OUT+'/observations.json').captures,find=n=>obs.find(o=>o.capture===n);
 const props=o=>o.sprites.filter(s=>s.id.startsWith('prop-')&&!s.id.endsWith('-shadow'));
 const shadows=o=>o.sprites.filter(s=>s.id.startsWith('prop-')&&s.id.endsWith('-shadow'));
 for(const o of obs){
  if(o.capture!=='invalid-authoring'&&o.issues.length)throw Error('Unexpected placement issue '+o.capture);
  if(props(o).length!==shadows(o).length)throw Error('Missing contact shadow '+o.capture);
  const firstSolid=Math.min(...o.sprites.filter(s=>s.z===1).map(s=>s.index));
  if(shadows(o).some(s=>s.z!==0||s.index>=firstSolid))throw Error('Ground effect after solid');
 }
 for(const name of ['gallery-mobile','gallery-unlit','gallery-restored','gallery-torches-disabled','DungeonPreview-heart-room','SixRoomPreview-heart-room'])if(props(find(name)).length!==6)throw Error('Missing selected prop '+name);
 if(props(find('MobileReference-native')).length!==3)throw Error('Missing mobile example');
 if(props(find('gallery-bare')).length||find('gallery-bare').lights.length)throw Error('Disabled props leave content');
 if(find('gallery-unlit').lights.length||find('gallery-mobile').lights.length!==1)throw Error('Candle light lifecycle');
 for(const name of ['gallery-restored','gallery-torches-disabled'])if(hash(OUT+'/'+name+'.png')!==hash(OUT+'/gallery-mobile.png'))throw Error('Gallery restoration differs '+name);
 if(find('invalid-authoring').issues.length!==6||props(find('invalid-authoring')).length!==1)throw Error('Unexpected invalid-authoring observations');
 const prepared=read(OUT+'/prepared.json');
 for(const item of prepared.items){
  if(!item.decoration)continue;
  const e=current.atlas.regions[item.id];
  if(!e.decoration||e.ground_effects.length!==1)throw Error('Missing prop metadata');
  for(const p of e.decoration.footprint)if(p[0]<e.bounds.min[0]||p[0]>e.bounds.max[0]||p[1]<e.bounds.min[1]||p[1]>e.bounds.max[1])throw Error('Foot outside support');
 }
 const result={date:'2026-10-25',selectedAppearances:6,selectedReferenceHashes:Object.keys(selection.reviewedFiles).length,
  retainedRegions:retained,retainedPixelsAndMetadataIdentical:true,decorations:current.decorations,
  atlas:{regions:current.spriteCount,size:[current.atlas.width,current.atlas.height],pngBytes:current.atlas.sourceBytes,deltaPNG:current.atlas.sourceBytes-baseline.atlas.sourceBytes,rgbaBytes:current.atlas.uncompressedRGBABytes,deltaRGBA:current.atlas.uncompressedRGBABytes-baseline.atlas.uncompressedRGBABytes},
  captures:obs.length,observations:obs.map(o=>({capture:o.capture,props:props(o).length,shadows:shadows(o).length,lights:o.lights.length,issues:o.issues})),restoredLightingIdentical:true,torchToggleIndependent:true,
  sourcePolicy:'Original selected pixels are immutable. Only native-alpha crop, uniform resize and separate prepared floor shadows; no reconstructed mesh or new camera claimed.'};
 fs.writeFileSync(abs(OUT+'/pixel-validation.json'),JSON.stringify(result,null,2)+'\n');
 console.log(JSON.stringify({retained,selectionHashes:result.selectedReferenceHashes,captures:obs.length,atlas:result.atlas}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
