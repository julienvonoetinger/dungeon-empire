// Material-only regression: preserve geometry, open frames, masonry and all other kit entries.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),S=require('./isometric_seal_door.cjs');
const DIR='docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf',OUT=path.join(P.ROOT,DIR);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const read=p=>JSON.parse(fs.readFileSync(path.join(P.ROOT,p)));
async function inventory(){
 const c=read('assets/dungeon/isometric-kit/catalog.json'),regions={};
 for(const[id,e]of Object.entries(c.atlas.regions)){
  const[left,top,width,height]=e.region,p=(e.atlas_path||c.atlas.pages[0].path).replace('res://','');
  const pixels=await sharp(path.join(P.ROOT,p)).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  regions[id]={metadata:e,pixels:hash(pixels)};
 }
 const actors={};for(const dir of fs.readdirSync(path.join(P.ROOT,'assets/previews')).filter(n=>n.startsWith('vulpin-'))){
  for(const name of fs.readdirSync(path.join(P.ROOT,'assets/previews',dir)).filter(n=>/\.(png|tres|json)$/.test(n))){
   const p='assets/previews/'+dir+'/'+name;actors[p]=P.hash(p);
  }
 }
 return {regions,actors,pages:c.atlas.pages,rgba:c.atlas.uncompressedRGBABytes,png:c.atlas.sourceBytes};
}
async function main(){
 const record=process.argv.includes('--record'),now=await inventory(),file=path.join(OUT,'before.json');
 if(record)assert(!fs.existsSync(file),'Never overwrite the baseline');
 const before=record?{...now,models:{}}:JSON.parse(fs.readFileSync(file)),results=[];
 for(const d of ['south','east','north','west']){
  const model=S.geometry(d),r=await S.paint(d),p=path.join(OUT,'before-'+d+'.png');
  if(record){before.models[d]=model;fs.writeFileSync(p,r.full.png);continue;}
  assert.deepEqual(model,before.models[d],'Approved geometry '+d);
  const old=await sharp(p).ensureAlpha().raw().toBuffer(),current=await sharp(r.full.png).ensureAlpha().raw().toBuffer();
  assert.equal(old.length,current.length);
  const ray=P.raster(model,r.full.frame,4),w=r.full.frame[2],h=r.full.frame[3],leaf=new Uint8Array(w*h);
  for(let i=0;i<ray.owner.length;i++)if(ray.owner[i]>=0&&model.faces[ray.owner[i]].kind.startsWith('leaf'))leaf[Math.floor(Math.floor(i/ray.width)/4)*w+Math.floor((i%ray.width)/4)]=1;
  let changed=0,unchangedOutsideLeaf=0;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const k=(y*w+x)*4;assert.equal(current[k+3],old[k+3],'Silhouette/alpha '+d);
   let nearLeaf=false;for(let dy=-3;dy<=3;dy++)for(let dx=-3;dx<=3;dx++){const X=x+dx,Y=y+dy;if(X>=0&&Y>=0&&X<w&&Y<h&&leaf[Y*w+X])nearLeaf=true;}
   if(!nearLeaf){assert(current.subarray(k,k+4).equals(old.subarray(k,k+4)),'Masonry changed '+d+' '+x+','+y);unchangedOutsideLeaf++;}
   else if(!current.subarray(k,k+4).equals(old.subarray(k,k+4)))changed++;
  }
  assert(changed>1000,'Leaf actually changed '+d);results.push({direction:d,changed,unchangedOutsideLeaf});
  fs.writeFileSync(path.join(OUT,'after-'+d+'.png'),r.full.png);
 }
 if(record){fs.writeFileSync(file,JSON.stringify(before,null,2));console.log('Recorded all kit regions, hero assets and four complete door models/renders');return;}
 assert.deepEqual(Object.keys(now.regions).sort(),Object.keys(before.regions).sort());
 let unchangedRegions=0;for(const[id,e]of Object.entries(before.regions)){
  assert.deepEqual(now.regions[id].metadata,e.metadata,'Atlas/geometry metadata '+id);
  if(!id.startsWith('door-')||id.includes('-open-')){assert.equal(now.regions[id].pixels,e.pixels,'Unchanged sprite '+id);unchangedRegions++;}
 }
 assert.deepEqual(now.actors,before.actors,'All hero frames/resources unchanged');assert.equal(now.rgba,before.rgba,'Same decoded atlas allocation');
 const selection=read(DIR+'/selection.json'),img=await sharp(path.join(P.ROOT,selection.leafPainting)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 assert.equal(img.info.width,1024);assert.equal(img.info.height,1536);
 const k=(1138*img.info.width+512)*4,keyhole=[...img.data.subarray(k,k+4)];
 assert(keyhole.slice(0,3).every(v=>v<35)&&keyhole[3]>240,'Source tool target remains inside the black keyhole');
 const report={unchangedRegions,unchangedHeroFiles:Object.keys(now.actors).length,results,keyhole,rgba:now.rgba,png:now.png,pngDelta:now.png-before.png};
 fs.writeFileSync(path.join(OUT,'validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e);process.exitCode=1});
