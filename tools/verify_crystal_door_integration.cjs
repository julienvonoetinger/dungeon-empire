// Compare the installed atlas to the approved review, and preserve unrelated art.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),OUT=path.join(ROOT,'artifacts/crystal-door-integration');
const REVIEW='docs/reference/door-redesign/seal-v1/hero-fit-v15-iron-crystals';
const read=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p))),hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function inventory(){
 const catalog=read('assets/dungeon/isometric-kit/catalog.json'),regions={},actors={};
 for(const[id,entry]of Object.entries(catalog.atlas.regions)){
  const [left,top,width,height]=entry.region,file=(entry.atlas_path||catalog.atlas.pages[0].path).replace('res://','');
  const pixels=await sharp(path.join(ROOT,file)).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  regions[id]={entry,pixels:hash(pixels)};
 }
 for(const dir of fs.readdirSync(path.join(ROOT,'assets/previews')).filter(n=>n.startsWith('vulpin-'))){
  for(const name of fs.readdirSync(path.join(ROOT,'assets/previews',dir)).filter(n=>/\.(png|tres|json)$/.test(n))){
   const p='assets/previews/'+dir+'/'+name;actors[p]=hash(fs.readFileSync(path.join(ROOT,p)));
  }
 }
 return{regions,actors,png:catalog.atlas.sourceBytes,rgba:catalog.atlas.uncompressedRGBABytes,pages:catalog.atlas.pages.map(p=>[p.path,p.width,p.height])};
}
async function main(){
 fs.mkdirSync(OUT,{recursive:true});const now=await inventory(),baseline=path.join(OUT,'before.json');
 if(process.argv.includes('--record')){assert(!fs.existsSync(baseline),'Do not overwrite the pre-install baseline');fs.writeFileSync(baseline,JSON.stringify(now,null,2));console.log('Recorded active kit and hero baseline.');return;}
 const before=JSON.parse(fs.readFileSync(baseline)),expected=read(REVIEW+'/preview-catalog.json'),failures=[];let checks=0,unchanged=0;
 const check=(ok,message)=>{checks++;if(!ok)failures.push(message);};
 check(JSON.stringify(Object.keys(now.regions).sort())===JSON.stringify(Object.keys(before.regions).sort()),'Same sprite IDs');
 check(JSON.stringify(now.pages)===JSON.stringify(before.pages)&&now.rgba===before.rgba,'Same atlas pages and decoded memory');
 check(JSON.stringify(now.actors)===JSON.stringify(before.actors),'Hero art/resources unchanged');
 for(const[id,old]of Object.entries(before.regions)){
  check(JSON.stringify(now.regions[id]?.entry)===JSON.stringify(old.entry),'Unchanged metadata '+id);
  if(!Object.hasOwn(expected,id)){check(now.regions[id]?.pixels===old.pixels,'Unchanged non-closed-door art '+id);unchanged++;}
 }
 for(const[id,review]of Object.entries(expected)){
  const entry=now.regions[id].entry,[left,top,width,height]=entry.region;
  check(JSON.stringify(entry.offset)===JSON.stringify(review.offset)&&JSON.stringify(entry.size)===JSON.stringify(review.size),'Approved frame '+id);
  const actual=await sharp(path.join(ROOT,entry.atlas_path.replace('res://',''))).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  const target=await sharp(path.join(ROOT,REVIEW,review.file)).resize(width,height,{kernel:'lanczos3'}).ensureAlpha().raw().toBuffer();
  let error=0;
  for(let k=0;k<actual.length;k+=4){error=Math.max(error,Math.abs(actual[k+3]-target[k+3]));for(let c=0;c<3;c++)error=Math.max(error,Math.abs(actual[k+c]*actual[k+3]-target[k+c]*target[k+3])/255);}
  check(error<=1,'Installed approved crystal paint '+id+' (max premultiplied error '+error.toFixed(2)+')');
 }
 const report={checks,failures,unchangedRegions:unchanged,unchangedHeroFiles:Object.keys(now.actors).length,png:now.png,pngDelta:now.png-before.png,rgba:now.rgba,rgbaDelta:now.rgba-before.rgba};
 fs.writeFileSync(path.join(OUT,'report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));if(failures.length)process.exitCode=1;
}
main().catch(e=>{console.error(e);process.exitCode=1;});
