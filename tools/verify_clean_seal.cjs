// Regression checks against accepted images/geometry, not generator internals.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const BASE='docs/reference/door-redesign/seal-v1',OUT=path.join(P.ROOT,BASE,'painted-v8-integrated');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function inventory(){
 const catalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json'))),regions={};
 for(const [id,e]of Object.entries(catalog.atlas.regions)){
  const [left,top,width,height]=e.region,p=(e.atlas_path||catalog.atlas.pages[0].path).replace('res://','');
  const pixels=await sharp(path.join(P.ROOT,p)).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  const {region,...metadata}=e;regions[id]={metadata,pixels:hash(pixels)};
 }
 return {regions,rgbaBytes:catalog.atlas.uncompressedRGBABytes,pngBytes:catalog.atlas.sourceBytes,pages:catalog.atlas.pages};
}
async function main(){
 fs.mkdirSync(OUT,{recursive:true});
 if(process.argv.includes('--record')){
  assert(!fs.existsSync(path.join(OUT,'before.json')),'Do not overwrite baseline');
  fs.writeFileSync(path.join(OUT,'before.json'),JSON.stringify(await inventory(),null,2));
  const paths=[BASE+'/wireframe-v6-clean-leaf/geometry.json',BASE+'/wireframe-v6-clean-leaf/face-guide-magenta.png',BASE+'/wireframe-v6-clean-leaf/checks.json',BASE+'/painted-v7-clean-leaf/source/face-source.png',BASE+'/painted-v7-clean-leaf/preparation.json',BASE+'/painted-v7-clean-leaf/selection.json',BASE+'/painted-v7-clean-leaf/source/prompt.txt', 'tools/seal_masonry_finish.cjs'];
  const files=Object.fromEntries(paths.map(p=>[p,P.hash(p)]));
  fs.writeFileSync(path.join(OUT,'selection.json'),JSON.stringify({date:'2026-10-27',userApproval:"Oui c'est corrigé. Tu peux intégrer",status:'accepted-geometry-and-texture',files},null,2));
  console.log('Before inventory and accepted input hashes recorded');return;
 }
 const S=require('./isometric_seal_door.cjs'),ref=JSON.parse(fs.readFileSync(path.join(P.ROOT,BASE,'wireframe-v6-clean-leaf/geometry.json')));
 const approved=JSON.parse(fs.readFileSync(path.join(OUT,'selection.json')));
 for(const [p,h]of Object.entries(approved.files))assert.equal(P.hash(p),h,'Accepted input changed: '+p);
 const before=JSON.parse(fs.readFileSync(path.join(OUT,'before.json'))),now=await inventory();
 let nonDoor=0;for(const [id,v]of Object.entries(before.regions))if(!id.startsWith('door-')){assert.deepEqual(now.regions[id],v,'Unrelated sprite changed: '+id);nonDoor++;}
 assert.equal(now.rgbaBytes,before.rgbaBytes,'Texture allocation unchanged');
 assert.deepEqual(Object.keys(now.regions).sort(),Object.keys(before.regions).sort());
 const reports=[];
 for(const d of ['south','east','north','west']){
  const expected=ref.models[d].faces.slice(0,ref.door.faces.length),m=S.geometry(d);
  assert.deepEqual(m.faces,expected,'Runtime must use the accepted smooth-leaf geometry: '+d);
  assert.equal(m.faces.filter(f=>f.kind==='leaf').length,2);
  const r=await S.paint(d);assert.deepEqual(r.parts[0].wallJunction.span,[1/3,2/3]);
  if(!process.argv.includes('--before-export'))assert.deepEqual(now.regions[`door-${d}-leaf`].metadata.wall_junction.span,[1/3,2/3]);
  const joined=await sharp({create:{width:r.full.frame[2],height:r.full.frame[3],channels:4,background:'#0000'}}).composite(r.parts.map(p=>({input:p.png,left:p.frame[0]-r.full.frame[0],top:p.frame[1]-r.full.frame[1]}))).ensureAlpha().raw().toBuffer();
  const full=await sharp(r.full.png).ensureAlpha().raw().toBuffer();let splitAlpha=0,splitColor=0;
  for(let i=0;i<full.length;i+=4){splitAlpha=Math.max(splitAlpha,Math.abs(full[i+3]-joined[i+3]));for(let c=0;c<3;c++)splitColor=Math.max(splitColor,Math.abs(full[i+c]*full[i+3]-joined[i+c]*joined[i+3])/255);}
  assert(splitAlpha<=1&&splitColor<=1,'Layer split recomposition: '+d);
  const fr=JSON.parse(fs.readFileSync(path.join(P.ROOT,BASE,'painted-v7-clean-leaf/preparation.json'))).records.find(v=>v.direction===d).frame;
  const preview=await sharp(path.join(P.ROOT,BASE,`painted-v7-clean-leaf/door-${d}.png`)).ensureAlpha().raw().toBuffer();
  const ray=P.raster(ref.models[d],fr,1);let compared=0,maxDifference=0;
  for(let y=3;y<fr[3]-3;y++)for(let x=3;x<fr[2]-3;x++){
   let owned=true;for(let dy=-3;dy<=3;dy++)for(let dx=-3;dx<=3;dx++){const owner=ray.owner[(y+dy)*ray.width+x+dx];if(owner<0||owner>=ref.door.faces.length)owned=false;}if(!owned)continue;
   const X=x+fr[0]-r.full.frame[0],Y=y+fr[1]-r.full.frame[1];if(X<0||Y<0||X>=r.full.frame[2]||Y>=r.full.frame[3])continue;
   const a=(y*fr[2]+x)*4,b=(Y*r.full.frame[2]+X)*4;for(let c=0;c<4;c++)maxDifference=Math.max(maxDifference,Math.abs(preview[a+c]-full[b+c]));compared++;
  }
  assert(compared>5000,'Enough visible approved door pixels compared');assert(maxDifference<=1,'Approved paint changed: '+d+' max byte difference '+maxDifference);
  reports.push({direction:d,comparedPreviewPixels:compared,maxDifference,splitAlpha,splitColor,span:r.parts[0].wallJunction.span});
 }
 const report={nonDoor,rgbaBytes:now.rgbaBytes,pngDelta:now.pngBytes-before.pngBytes,acceptedFiles:Object.keys(approved.files).length,reports};
 fs.writeFileSync(path.join(OUT,process.argv.includes('--before-export')?'generator-validation.json':'export-validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e);process.exitCode=1});
