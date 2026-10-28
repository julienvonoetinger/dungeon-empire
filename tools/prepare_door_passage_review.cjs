const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp'),assert=require('node:assert/strict');
const P=require('./isometric_paint_geometry.cjs'),DIR='docs/reference/door-redesign/seal-v1/hero-fit-v14-passage',OUT=path.join(P.ROOT,DIR);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const before=JSON.parse(fs.readFileSync(path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/before.json'))),catalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json')));let count=0;
 for(const[id,old]of Object.entries(before.regions)){
  if(id.startsWith('door-'))continue;
  const e=catalog.atlas.regions[id],[left,top,width,height]=e.region,p=(e.atlas_path||catalog.atlas.pages[0].path).replace('res://','');
  const pixels=await sharp(path.join(P.ROOT,p)).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  assert.equal(hash(pixels),old.pixels,'Unrelated sprite '+id);assert.deepEqual(e,old.metadata,'Unrelated metadata '+id);count++;
 }
 for(const[p,h]of Object.entries(before.actors))assert.equal(P.hash(p),h,'Hero asset '+p);
 const evidence={unchangedNonDoorSprites:count,unchangedHeroResources:Object.keys(before.actors).length,entries:Object.keys(catalog.atlas.regions).length,pngBytes:catalog.atlas.sourceBytes,rgbaBytes:catalog.atlas.uncompressedRGBABytes,previousPNG:2107174,previousRGBA:13631488};
 fs.writeFileSync(path.join(OUT,'preservation.json'),JSON.stringify(evidence,null,2));
 for(const revision of ['before','after']){
  fs.mkdirSync(path.join(OUT,revision,'frames'),{recursive:true});
  for(let frame=0;frame<49;frame++)await sharp(path.join(OUT,revision,'walk-'+String(frame).padStart(2,'0')+'.png')).webp({lossless:true,effort:4}).toFile(path.join(OUT,revision,'frames',String(frame).padStart(2,'0')+'.webp'));
 }
 console.log(JSON.stringify(evidence));
}
main().catch(e=>{console.error(e);process.exitCode=1});
