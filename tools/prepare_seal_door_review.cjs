const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const Seal=require('./isometric_seal_door.cjs'),P=require('./isometric_paint_geometry.cjs');
const DIR=path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/painted-v2');
const BASE=path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/painted-v1/baseline.json');
fs.mkdirSync(DIR,{recursive:true});
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function inventory(){
 const catalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json'))),regions={};
 for(const [id,e] of Object.entries(catalog.atlas.regions)){
  const file=path.join(P.ROOT,(e.atlas_path||'res://assets/dungeon/isometric-kit/atlas-256.png').replace('res://',''));
  const region=e.region;
  const pixels=await sharp(file).extract({left:region[0],top:region[1],width:region[2],height:region[3]}).ensureAlpha().raw().toBuffer();
  const metadata={...e};delete metadata.region;delete metadata.atlas_path;
  regions[id]={sha256:hash(pixels),metadata};
 }
 return {regions,pages:catalog.atlas.pages,sourceBytes:catalog.atlas.sourceBytes,rgbaBytes:catalog.atlas.uncompressedRGBABytes};
}
async function main(){
 if(process.argv.includes('--baseline')){
  const target=path.join(DIR,'baseline.json');if(fs.existsSync(target))throw Error('Preserve existing baseline; refusing overwrite');
  fs.writeFileSync(target,JSON.stringify(await inventory(),null,2)+'\n');console.log('Baseline stored');return;
 }
 if(process.argv.includes('--verify')){
  const before=JSON.parse(fs.readFileSync(BASE)),after=await inventory();
  const unexpected=Object.keys(before.regions).filter(id=>!id.startsWith('door-')&&JSON.stringify(before.regions[id])!==JSON.stringify(after.regions[id]));
  const result={unrelatedRegions:Object.keys(before.regions).filter(id=>!id.startsWith('door-')).length,unexpected,allIdsUnchanged:Object.keys(before.regions).sort().join()===Object.keys(after.regions).sort().join(),beforeRGBA:before.rgbaBytes,afterRGBA:after.rgbaBytes,pngDelta:after.sourceBytes-before.sourceBytes,pages:after.pages};
  fs.writeFileSync(path.join(DIR,'integration-integrity.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));
  if(unexpected.length||!result.allIdsUnchanged||after.rgbaBytes>before.rgbaBytes)throw Error('Integration changes unrelated sprites or increases atlas allocation');return;
 }
 const list=[],checks=[];fs.mkdirSync(path.join(DIR,'sprites'),{recursive:true});
 for(const d of ['south','west','north','east']){
  const r=await Seal.paint(d);fs.writeFileSync(path.join(DIR,'sprites',d+'.png'),r.full.png);
  for(const p of r.parts)fs.writeFileSync(path.join(DIR,'sprites',p.id+'.png'),p.png);
  const join=await sharp({create:{width:r.full.frame[2],height:r.full.frame[3],channels:4,background:'#0000'}}).composite(r.parts.map(p=>({input:p.png,left:p.frame[0]-r.full.frame[0],top:p.frame[1]-r.full.frame[1]}))).png().toBuffer();
  const [a,b]=await Promise.all([sharp(join).raw().toBuffer(),sharp(r.full.png).raw().toBuffer()]);let different=0,maxAlpha=0,maxPremultiplied=0;
  for(let i=0;i<a.length;i+=4){maxAlpha=Math.max(maxAlpha,Math.abs(a[i+3]-b[i+3]));for(let c=0;c<3;c++)maxPremultiplied=Math.max(maxPremultiplied,Math.abs(a[i+c]*a[i+3]-b[i+c]*b[i+3])/255);for(let c=0;c<4;c++)if(a[i+c]!==b[i+c])different++;}
  // libvips composites in premultiplied alpha; low-alpha roundoff is not a seam.
  if(maxAlpha>1||maxPremultiplied>1)throw Error('Split recomposition differs: '+d+' '+JSON.stringify({maxAlpha,maxPremultiplied}));
  checks.push({direction:d,splitRGBABytesDifferent:different,maxSplitAlphaError:maxAlpha,maxSplitPremultipliedError:maxPremultiplied,parts:r.parts.map(p=>({id:p.id,frame:p.frame,bounds:p.bounds})),report:r.parts[0].report});
  list.push(r.full);
 }
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1300" height="680"><rect width="1300" height="680" fill="#090f19"/><g fill="#dde1ed" font-family="Segoe UI,sans-serif"><text x="38" y="50" font-size="29">C — Sceau interdit · pierre assortie aux murs</text><text x="38" y="85" font-size="17">Bases pleines ajustées aux murs · bois prune · sceaux violets</text>${['Sud','Ouest','Nord','Est'].map((d,i)=>`<text x="${65+i*315}" y="125" font-size="18">${d}</text>`).join('')}<text x="38" y="499" font-size="17">Échelle du jeu (.75) — aperçus hors scène</text></g></svg>`;
 const layers=[{input:Buffer.from(svg),left:0,top:0}];
 for(const [i,r] of list.entries()){
  const large=await sharp(r.png).resize({width:290,height:330,fit:'inside'}).png().toBuffer(),info=await sharp(large).metadata();
  layers.push({input:large,left:Math.round(170+i*315-info.width/2),top:150});
  const tiny=await sharp(r.png).resize(Math.round(r.frame[2]*.75),Math.round(r.frame[3]*.75)).png().toBuffer();
  layers.push({input:tiny,left:Math.round(170+i*315-r.frame[2]*.75/2),top:510});
 }
 await sharp({create:{width:1300,height:680,channels:4,background:'#090f19'}}).composite(layers).png().toFile(path.join(DIR,'painted-board.png'));
 fs.writeFileSync(path.join(DIR,'projection-checks.json'),JSON.stringify(checks,null,2)+'\n');console.log(JSON.stringify(checks.map(c=>({direction:c.direction,parts:c.parts.map(p=>({id:p.id,frame:p.frame})),splitDifference:c.splitRGBABytesDifferent})),null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1});
