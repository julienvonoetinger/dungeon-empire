// Focused regression/evidence checks for the v4 door masonry correction.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),S=require('./isometric_seal_door.cjs');
const OUT=path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/painted-v4-masonry');
const hash=data=>crypto.createHash('sha256').update(data).digest('hex');
async function inventory(){
 const c=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json'))),regions={};
 for(const [id,e] of Object.entries(c.atlas.regions)){
  const png=path.join(P.ROOT,(e.atlas_path||c.atlas.pages[0].path).replace('res://',''));
  const [left,top,width,height]=e.region;
  const pixels=await sharp(png).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  const {region,...metadata}=e;regions[id]={metadata,hash:hash(pixels)};
 }
 return {regions,sourceHashes:Object.fromEntries(S.referenceFiles.map(p=>[p,P.hash(p)]))};
}
async function main(){
 if(process.argv.includes('--record')){
  if(fs.existsSync(path.join(OUT,'before.json')))throw Error('Baseline already exists');
  fs.mkdirSync(path.join(OUT,'before'),{recursive:true});
  fs.writeFileSync(path.join(OUT,'before.json'),JSON.stringify(await inventory(),null,2));
  fs.writeFileSync(path.join(OUT,'before/geometry.json'),JSON.stringify(S.geometry('south')));
  fs.copyFileSync(path.join(P.ROOT,'tools/isometric_seal_door.cjs'),path.join(OUT,'before/isometric_seal_door.cjs.txt'));
  for(const d of ['south','north','east','west'])fs.copyFileSync(path.join(P.ROOT,`docs/reference/door-redesign/seal-v1/painted-v3/native/door-${d}-detail.png`),path.join(OUT,`before/door-${d}-detail.png`));
  console.log('Recorded immutable before evidence');return;
 }
 const g=S.geometry('south'),junction=g.faces.filter(f=>f.kind==='junction'),mid=P.H/2;
 const crossing=junction.filter(f=>Math.min(...f.points.map(p=>p[2]))<mid-1e-8&&Math.max(...f.points.map(p=>p[2]))>mid+1e-8);
 if(crossing.length)throw Error(`${crossing.length} lower jamb faces cross the wall's middle mortar joint instead of following its courses`);
 for(const x of [-P.T/2,1+P.T/2])if(!junction.some(f=>f.points.every(p=>Math.abs(p[0]-x)<1e-8)&&f.points.some(p=>Math.abs(p[2]-mid)<1e-8)))throw Error('Missing horizontal masonry joint at outer rail contact');
 const before=JSON.parse(fs.readFileSync(path.join(OUT,'before.json'))),now=await inventory();let protectedRegions=0;
 for(const [id,e]of Object.entries(before.regions))if(!id.startsWith('door-')){
  if(JSON.stringify(e)!==JSON.stringify(now.regions[id]))throw Error('Unrelated prepared region changed: '+id);protectedRegions++;
 }
 if(JSON.stringify(before.sourceHashes)!==JSON.stringify(now.sourceHashes))throw Error('Original source/provenance changed');
 const report={jambCourses:2,jointHeight:mid,protectedRegions,immutableSources:Object.keys(before.sourceHashes).length};
 fs.writeFileSync(path.join(OUT,'verification.json'),JSON.stringify(report,null,2));console.log(report);
}
main().catch(e=>{console.error(e);process.exitCode=1});
