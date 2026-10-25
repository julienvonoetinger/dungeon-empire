// Presentation only: retain original ImageGen pixels/alpha, trim empty margins
// and scale uniformly for comparison. No atlas or runtime changes.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-floor-variation-review/v1';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const xml=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
async function inspect(file){
 const {data,info}=await sharp(abs(file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let x0=info.width,y0=info.height,x1=-1,y1=-1,transparent=0,partial=0;
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
  const a=data[(y*info.width+x)*4+3];
  if(a===0){transparent++;continue;}
  if(a<255)partial++;
  x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
 }
 if(x1<0||transparent===0)throw Error('Missing visible artwork or native transparency: '+file);
 return {nativeSize:[info.width,info.height],transparentPixels:transparent,partialAlphaPixels:partial,
  crop:{left:x0,top:y0,width:x1-x0+1,height:y1-y0+1},sha256:hash(file)};
}
async function main(){
 const generation=read(OUT+'/generation.json');
 const baseline=read('docs/reference/isometric-decoration-review/remove-chip-2026-10-25/validation.json');
 for(const [file,expected] of Object.entries(baseline.sha256))if(hash(file)!==expected)throw Error('Active file changed: '+file);
 const selectedWalls=read('docs/reference/isometric-wall-variation-review/v2-subvariants/selection.json');
 for(const [file,expected] of Object.entries(selectedWalls.reviewedFiles))if(hash(file)!==expected)throw Error('Selected wall source changed: '+file);
 const entries=[{label:'Actuel',file:'docs/reference/isometric-review/painted-v1/sprites/floor.png',description:'Le sol en place'},
  ...generation.jobs.map((j,i)=>({...j,description:['Contours légèrement asymétriques','Pierres longues, carrées et courtes','Coins arrondis et biseaux plus doux'][i]}))];
 for(const entry of entries){
  entry.inspection=await inspect(entry.file);
  if(entry.generatedPath&&hash(entry.generatedPath)!==entry.inspection.sha256)throw Error('Generated source modified: '+entry.file);
 }
 const W=1536,H=670,layers=[];
 let body=`<rect width="${W}" height="${H}" fill="#0b1019"/>
  <text x="28" y="43" font-size="27" fill="#edf1fa">Variations de dalles — trois propositions</text>
  <text x="28" y="72" font-size="16" fill="#a5b0c7">Surfaces calmes et même famille de pierre. Comparer les formes et l’assemblage.</text>`;
 for(const [i,entry] of entries.entries()){
  const x=i*384;
  body+=`<rect x="${x+14}" y="98" width="356" height="520" rx="12" fill="#101722" stroke="#263146"/>
   <text x="${x+30}" y="131" font-size="21" fill="#edf1fa">${xml(entry.label)}</text>
   <text x="${x+30}" y="159" font-size="14" fill="#a5b0c7">${xml(entry.description)}</text>
   <text x="${x+30}" y="415" font-size="15" fill="#a5b0c7">Aperçu réduit · largeur 192 px</text>`;
  for(const [width,top] of [[332,189],[192,449]]){
   const pic=await sharp(abs(entry.file)).extract(entry.inspection.crop).resize({width}).png().toBuffer();
   layers.push({input:pic,left:x+Math.round((384-width)/2),top});
  }
 }
 body+='<text x="28" y="650" font-size="15" fill="#a5b0c7">Concepts ImageGen · Raccords à préparer dans le wireframe · Aucun changement dans les scènes</text>';
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" style="font-family:Arial,sans-serif">${body}</svg>`;
 await sharp(Buffer.from(svg)).composite(layers).png().toFile(abs(OUT+'/comparison.png'));
 const mobileLayers=[];
 let mobile='<rect width="1024" height="240" fill="#0b1019"/><text x="20" y="30" font-size="18" fill="#edf1fa">Dalles — comparaison à 192 px de large par case</text>';
 for(const [i,entry] of entries.entries()){
  mobile+=`<text x="${i*256+25}" y="65" font-size="16" fill="#edf1fa">${xml(entry.label)}</text>`;
  mobileLayers.push({input:await sharp(abs(entry.file)).extract(entry.inspection.crop).resize({width:192}).png().toBuffer(),left:i*256+32,top:90});
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="240" style="font-family:Arial,sans-serif">${mobile}</svg>`)).composite(mobileLayers).png().toFile(abs(OUT+'/mobile-scale.png'));
 const evidence={date:generation.date,status:'appearance proposals only',entries,unchangedActiveHashes:baseline.sha256,
  unchangedWallSelectionFiles:Object.keys(selectedWalls.reviewedFiles).length,
  scalePolicy:'Uniform scaling only; trim alpha-zero gutters, preserve all original native alpha. 192px width approximates one cell at fixed .75 zoom, not a Godot capture.',
  limitations:['Seam compatibility and exact projection are not established by concept art.','No production integration, automated tests, Godot import/export, commit or push.']};
 fs.writeFileSync(abs(OUT+'/validation.json'),JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify({variants:entries.length-1,unchangedActiveFiles:Object.keys(baseline.sha256).length,unchangedSelectedWallFiles:evidence.unchangedWallSelectionFiles,board:OUT+'/comparison.png'}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
