// Appearance review only: retain native ImageGen pixels and alpha.
// Crop transparent margins and scale uniformly; never paint or change the kit.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-floor-damage-review/v1';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const xml=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
async function inspect(file){
 const {data,info}=await sharp(abs(file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let x0=info.width,y0=info.height,x1=-1,y1=-1,transparent=0,partial=0;
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
  const a=data[(y*info.width+x)*4+3];
  if(a===0){transparent++;continue;} if(a<255)partial++;
  x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
 }
 if(x1<0||transparent===0)throw Error('Missing artwork or native alpha: '+file);
 return {nativeSize:[info.width,info.height],transparentPixels:transparent,partialAlphaPixels:partial,
  crop:{left:x0,top:y0,width:x1-x0+1,height:y1-y0+1},sha256:hash(file)};
}
async function main(){
 const generation=read(OUT+'/generation.json');
 const baseline=read('docs/reference/isometric-floor-variation-review/v1/integration/validation.json').sha256;
 for(const [file,expected] of Object.entries(baseline))if(hash(file)!==expected)throw Error('Active baseline changed: '+file);
 const selectionFiles={};
 for(const file of ['docs/reference/isometric-floor-variation-review/v1/selection.json','docs/reference/isometric-wall-variation-review/v2-subvariants/selection.json']){
  const selection=read(file);
  const files=selection.reviewedFiles;
  if(!files)throw Error('Missing selected references: '+file);
  for(const [source,expected] of Object.entries(files)){
   if(hash(source)!==expected)throw Error('Accepted reference changed: '+source);
   selectionFiles[source]=expected;
  }
 }
 const entries=[];
 for(const job of generation.jobs){
  const entry={...job,inspection:await inspect(job.file)};
  if(hash(job.generatedPath)!==entry.inspection.sha256)throw Error('Generated original modified: '+job.file);
  entries.push(entry);
 }
 const W=1536,H=620,layers=[];
 let body=`<rect width="${W}" height="${H}" fill="#0b1019"/>
 <text x="28" y="40" font-size="26" fill="#edf1fa">Dalles B — fissures et corruption</text>
 <text x="28" y="69" font-size="16" fill="#a5b0c7">Quatre propositions localisées, à mélanger avec une majorité de dalles intactes.</text>`;
 for(const [i,e] of entries.entries()){
  const x=i*384;
  body+=`<rect x="${x+14}" y="94" width="356" height="470" rx="12" fill="#101722" stroke="#263146"/>
  <text x="${x+28}" y="129" font-size="21" fill="#edf1fa">${xml(e.label)}</text>
  <text x="${x+28}" y="157" font-size="14" fill="#a5b0c7">${xml(e.description)}</text>
  <text x="${x+28}" y="400" font-size="15" fill="#a5b0c7">Aperçu réduit · largeur 192 px</text>`;
  for(const [width,top] of [[332,185],[192,429]]){
   const input=await sharp(abs(e.file)).extract(e.inspection.crop).resize({width}).png().toBuffer();
   layers.push({input,left:x+Math.round((384-width)/2),top});
  }
 }
 body+='<text x="28" y="596" font-size="15" fill="#a5b0c7">Concepts ImageGen · Échelle indicative · Raccords à adapter au wireframe avant intégration</text>';
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" style="font-family:Arial,sans-serif">${body}</svg>`)).composite(layers).png().toFile(abs(OUT+'/comparison.png'));
 const mobileLayers=[];
 let mobile='<rect width="1024" height="240" fill="#0b1019"/><text x="20" y="31" font-size="18" fill="#edf1fa">Comparaison à 192 px de large — échelle indicative d’une case</text>';
 for(const [i,e] of entries.entries()){
  mobile+=`<text x="${i*256+22}" y="65" font-size="16" fill="#edf1fa">${xml(e.label)}</text>`;
  mobileLayers.push({input:await sharp(abs(e.file)).extract(e.inspection.crop).resize({width:192}).png().toBuffer(),left:i*256+32,top:94});
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="240" style="font-family:Arial,sans-serif">${mobile}</svg>`)).composite(mobileLayers).png().toFile(abs(OUT+'/mobile-scale.png'));
 const evidence={date:generation.date,status:'Appearance proposals only; not selected or integrated',entries,
  unchangedActiveHashes:baseline,unchangedSelectionHashes:selectionFiles,
  scalePolicy:'Only alpha-zero margin cropping and uniform resizing for presentation. All originals preserved byte-for-byte. 192px approximates a logical cell at zoom .75; not a Godot capture.',
  limitations:['Exact B wireframe, edge compatibility, palette calibration and distribution remain integration work.','No production atlas, scripts or scenes changed; no automated tests, Godot import/export, device profile, commit or push.']};
 fs.writeFileSync(abs(OUT+'/validation.json'),JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify({variants:entries.length,unchangedActiveFiles:Object.keys(baseline).length,unchangedSelectedFiles:Object.keys(selectionFiles).length,board:OUT+'/comparison.png'}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
