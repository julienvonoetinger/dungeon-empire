// Review presentation only: native alpha is preserved; no painted pixels are edited.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = __dirname;
const repo = path.resolve(root, '../../../..');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const readJSON = file => JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
const esc = value => value.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const entries = [
 ['a1', 'A1 · Rythme irrégulier', 'Concept retenu'],
 ['a2', 'A2 · Pierre longue en haut', 'Nouvelle proposition'],
 ['a3', 'A3 · Pierre longue en bas', 'Nouvelle proposition'],
 ['c1', 'C1 · Relief central', 'Concept retenu'],
 ['c2', 'C2 · Deux reliefs décalés', 'Nouvelle proposition'],
 ['c3', 'C3 · Relief large en bas', 'Nouvelle proposition'],
 ['f1', 'F1 · Racines ramifiées', 'Concept retenu'],
 ['f2', 'F2 · Racines étalées', 'Nouvelle proposition'],
 ['f3', 'F3 · Bouquet de cristaux', 'Nouvelle proposition'],
];
async function inspect(file) {
 const {data, info} = await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let x0=info.width,y0=info.height,x1=-1,y1=-1,transparent=0,partial=0;
 for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
  const a=data[(y*info.width+x)*4+3];
  if(a===0){transparent++;continue;}
  if(a<255)partial++;
  x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);
 }
 if(!transparent || x1<0) throw Error('Missing usable native alpha: '+file);
 return {nativeSize:[info.width,info.height],transparentPixels:transparent,partialAlphaPixels:partial,previewCrop:{left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}};
}
function svg(w,h,body){return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><style>text{font-family:Arial,sans-serif;fill:#e8eaf2}.small{font-size:15px;fill:#aeb8ca}</style>${body}</svg>`);}
async function main(){
 const generation=readJSON(path.join(root,'generation.json'));
 const validation={date:'2026-10-25',scope:'Concept art comparison only; no Godot rendering, wireframe matching or production integration',sources:{},preservedSelectionFiles:0,preservedActiveFiles:0};
 for(const entry of entries){
  const [id]=entry,file=path.join(root,'source',id+'.png');
  const original=generation.jobs.find(j=>j.id===id)?.generatedPath;
  if(original && hash(file)!==hash(original))throw Error('Source copy differs: '+id);
  validation.sources[id]={file:'source/'+id+'.png',sha256:hash(file),...await inspect(file)};
 }
 const selection=readJSON(path.join(root,'../v1/selection.json'));
 for(const [file,expected] of Object.entries(selection.sha256)){
  if(hash(path.join(repo,file))!==expected)throw Error('Selected reference changed: '+file);
  validation.preservedSelectionFiles++;
 }
 const active=readJSON(path.join(repo,'docs/reference/isometric-review/painted-v1/heart-self-light-v1/integration/validation.json'));
 for(const [file,expected] of Object.entries(active.sha256)){
  if(hash(path.join(repo,file))!==expected)throw Error('Active file changed: '+file);
  validation.preservedActiveFiles++;
 }
 let body='<rect width="1340" height="1450" fill="#0c111c"/><text x="26" y="39" font-size="28" font-weight="bold">A · C · F — Trois déclinaisons par famille</text><text x="26" y="66" class="small">Colonne 1 : concepts retenus · Colonnes 2 et 3 : nouvelles propositions</text>';
 const layers=[];
 for(let i=0;i<entries.length;i++){
  const [id,label,status]=entries[i],x=24+(i%3)*436,y=91+Math.floor(i/3)*440;
  body+=`<rect x="${x}" y="${y}" width="420" height="424" rx="12" fill="#151e2d" stroke="#354257"/><text x="${x+16}" y="${y+29}" font-size="20" font-weight="bold">${esc(label)}</text><text x="${x+16}" y="${y+52}" class="small">${status}</text><text x="${x+156}" y="${y+369}" class="small">Miniature : 114 px</text><text x="${x+156}" y="${y+392}" class="small">Même échelle de lecture</text>`;
  const source=path.join(root,'source',id+'.png'),crop=validation.sources[id].previewCrop;
  const large=await sharp(source).extract(crop).resize({width:388,height:264,fit:'inside'}).png().toBuffer({resolveWithObject:true});
  layers.push({input:large.data,left:x+Math.round((420-large.info.width)/2),top:y+64+Math.round((264-large.info.height)/2)});
  const small=await sharp(source).extract(crop).resize({width:114}).png().toBuffer({resolveWithObject:true});
  layers.push({input:small.data,left:x+20,top:y+332+Math.round((86-small.info.height)/2)});
 }
 body+='<text x="26" y="1436" class="small">Étude visuelle · raccords et deux orientations à valider en wireframe avant intégration</text>';
 await sharp(svg(1340,1450,body)).composite(layers).png().toFile(path.join(root,'comparison.png'));
 let mobile='<rect width="720" height="454" fill="#0c111c"/><text x="24" y="31" font-size="23" font-weight="bold">Lecture à petite taille — 114 px par mur</text><text x="24" y="54" class="small">Vignettes de concept ; pas une capture du jeu</text>';
 const tinyLayers=[];
 for(let i=0;i<entries.length;i++){
  const [id]=entries[i],x=54+(i%3)*228,y=76+Math.floor(i/3)*120;
  mobile+=`<text x="${x}" y="${y+16}" font-size="17">${id.toUpperCase()}</text>`;
  const small=await sharp(path.join(root,'source',id+'.png')).extract(validation.sources[id].previewCrop).resize({width:114}).png().toBuffer();
  tinyLayers.push({input:small,left:x+46,top:y+12});
 }
 await sharp(svg(720,454,mobile)).composite(tinyLayers).png().toFile(path.join(root,'mobile-scale.png'));
 validation.notes=['C3 shows a dominant lower relief plus a smaller upper relief, despite the prompt requesting a flush upper course. Retained as a distinct concept proposal; not a geometry specification.','Source drawings are native alpha and unchanged. Preview uses alpha-positive bounding rectangle and uniform downscaling only.','F decorations are illustrated on their hosts for review; they are not yet separate production overlays.'];
 validation.sha256={};
 for(const name of ['comparison.png','mobile-scale.png','generation.json','prepare-board.cjs'])validation.sha256[name]=hash(path.join(root,name));
 fs.writeFileSync(path.join(root,'validation.json'),JSON.stringify(validation,null,2)+'\n');
 console.log(JSON.stringify({sources:entries.length,selectedReferencesUnchanged:validation.preservedSelectionFiles,activeFilesUnchanged:validation.preservedActiveFiles,board:'comparison.png',small:'mobile-scale.png'}));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
