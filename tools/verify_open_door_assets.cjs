const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const baseline=path.join(P.ROOT,'artifacts/open-door-assets-before.json');
async function inventory(){
 const catalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json'))),regions={};
 for(const [id,e]of Object.entries(catalog.atlas.regions)){
  const [left,top,width,height]=e.region,p=(e.atlas_path||catalog.atlas.pages[0].path).replace('res://','');
  const pixels=await sharp(path.join(P.ROOT,p)).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  regions[id]={entry:e,pixels:hash(pixels)};
 }
 return {regions,pages:catalog.atlas.pages.map(p=>({...p,hash:P.hash(p.path.replace('res://',''))})),rgbaBytes:catalog.atlas.uncompressedRGBABytes,pngBytes:catalog.atlas.sourceBytes};
}
async function main(){
 const now=await inventory();
 if(process.argv.includes('--record')){assert(!fs.existsSync(baseline));fs.writeFileSync(baseline,JSON.stringify(now,null,2));console.log('Recorded '+Object.keys(now.regions).length+' existing sprites');return;}
 const before=JSON.parse(fs.readFileSync(baseline));
 for(const [id,value]of Object.entries(before.regions))assert.deepEqual(now.regions[id],value,'Existing sprite changed: '+id);
 assert.deepEqual(now.pages.slice(0,before.pages.length),before.pages,'Existing atlas changed');
 const Door=require('./isometric_seal_door.cjs'),report=[];
 for(const d of ['north','east','south','west']){
  const original=Door.geometry(d),open=Door.geometry(d,true);
  assert.deepEqual(open.faces,original.faces.filter(f=>!f.kind.startsWith('leaf')),'Only wood geometry removed');
  assert(open.faces.length<original.faces.length);
  for(const layer of ['leaf','arch'])assert(now.regions[`door-${d}-open-${layer}`],'Missing frame layer');
  const r=await Door.paint(d,true),raw=await sharp(r.full.png).ensureAlpha().raw().toBuffer();
  const ray=P.raster(open,r.full.frame,1);let clear=0;
  // Interior aperture must genuinely reveal the floor, not contain old wood.
  const closedRay=P.raster(original,r.full.frame,1);
  for(let y=4;y<r.full.frame[3]-4;y++)for(let x=4;x<r.full.frame[2]-4;x++){
   const k=y*ray.width+x,fi=closedRay.owner[k];
   if(fi<0||!original.faces[fi].kind.startsWith('leaf'))continue;
   // Exclude the 3px Lanczos filtering support around stone silhouettes.
   let empty=true;for(let dy=-4;dy<=4;dy++)for(let dx=-4;dx<=4;dx++)if(ray.owner[k+dy*ray.width+dx]>=0)empty=false;
   if(empty){assert.equal(raw[k*4+3],0,'Wood remains in clear passage');clear++;}
  }
  assert(clear>500,'Visible empty aperture: '+d);report.push({direction:d,clearAperturePixels:clear});
 }
 const result={existingSpritesUnchanged:Object.keys(before.regions).length,addedSprites:Object.keys(now.regions).length-Object.keys(before.regions).length,rgbaDelta:now.rgbaBytes-before.rgbaBytes,pngDelta:now.pngBytes-before.pngBytes,report};
 fs.writeFileSync(path.join(P.ROOT,'artifacts/open-door-assets-results.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
}
main().catch(e=>{console.error(e);process.exitCode=1});
