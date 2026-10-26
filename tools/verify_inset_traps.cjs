// Focused export contract: geometry opening, unchanged earlier pages/regions,
// mobile memory allocation, and the floor's periodic colour outside the cut.
const fs=require('node:fs'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Traps=require('./isometric_inset_traps.cjs');
const OUT='docs/reference/trap-review/v3-integrated/';
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
async function main(){
 const baseline=JSON.parse(fs.readFileSync(OUT+'baseline.json'));
 const current=JSON.parse(fs.readFileSync('assets/dungeon/isometric-kit/catalog.json'));
 for(const [p,h] of Object.entries(baseline.hashes))assert.equal(hash(p),h,'Existing atlas changed: '+p);
 for(const [id,entry] of Object.entries(baseline.catalog.atlas.regions))assert.deepEqual(current.atlas.regions[id],entry,'Previous region changed: '+id);
 const added=Object.keys(current.atlas.regions).filter(id=>!baseline.catalog.atlas.regions[id]);
 assert.equal(added.length,8);
 const page=current.atlas.pages.find(p=>p.path.includes('/traps/'));
 assert.ok(page&&page.uncompressedRGBABytes<=1024*1024,'Traps exceed 1 MiB RGBA');
 const normal=await sharp('docs/reference/isometric-review/painted-v1/sprites/floor.png').ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let samples=0;
 for(const kind of ['spike','snare','void'])for(const ready of [true,false]){
  const m=Traps.model(kind,ready);
  for(const f of m.faces.filter(f=>f.kind==='floor')){
   assert.ok(f.points.every(p=>p[2]===0));
   const x=f.points.map(p=>p[0]),y=f.points.map(p=>p[1]);
   assert.ok(Math.max(...x)<=.22||Math.min(...x)>=.78||Math.max(...y)<=.22||Math.min(...y)>=.78,'Floor fills opening');
  }
  const frame=current.atlas.regions[m.id+'-floor'];
  const image=await sharp('docs/reference/isometric-review/painted-v1/sprites/'+m.id+'-floor.png').ensureAlpha().raw().toBuffer();
  for(let y=0;y<normal.info.height;y++)for(let x=0;x<normal.info.width;x++){
   const p=P.ground([frame.offset[0]+x+.5,frame.offset[1]+y+.5]);
   if(p[0]>.15&&p[0]<.85&&p[1]>.15&&p[1]<.85)continue;
   const i=(y*normal.info.width+x)*4;
   assert.deepEqual(image.subarray(i,i+4),normal.data.subarray(i,i+4),'Paving mismatch outside socket');samples++;
  }
 }
 const report={unchangedPages:Object.keys(baseline.hashes).length,unchangedRegions:Object.keys(baseline.catalog.atlas.regions).length,newRegions:added,unchangedFloorPixelsChecked:samples,page,totalRGBABytes:current.atlas.uncompressedRGBABytes};
 fs.writeFileSync(OUT+'export-validation.json',JSON.stringify(report,null,2)+'\n');console.log(report);
}
main().catch(e=>{console.error(e);process.exitCode=1});
