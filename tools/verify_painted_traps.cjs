const fs=require('node:fs'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const dir='docs/reference/trap-review/v7-integrated-paint';
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
async function main(){
 const baseline=JSON.parse(fs.readFileSync(dir+'/baseline.json'));
 const selected=JSON.parse(fs.readFileSync(dir+'/selection.json'));
 const catalog=JSON.parse(fs.readFileSync('assets/dungeon/isometric-kit/catalog.json'));
 for(const [file,h] of Object.entries({...baseline.hashes,...selected.hashes}))assert.equal(hash(file),h,'Protected source/page changed: '+file);
 for(const [id,entry] of Object.entries(baseline.regions))assert.deepEqual(catalog.atlas.regions[id],entry,'Unrelated region changed: '+id);
 const sprites='docs/reference/isometric-review/painted-v1/sprites/';
 const normal=await sharp(sprites+'floor-b1.png').ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let samePixels=0;
 for(const kind of ['spike','snare','void'])for(const layer of (kind==='void'?['floor']:['floor','mechanism'])){
  let previous;
  for(const state of ['ready','triggered','spent']){
   const id=`trap-${kind}-${state}-${layer}`,entry=catalog.atlas.regions[id];
   assert.ok(entry,'Missing '+id);
   assert.equal(entry.trap.state,state);
   const placement={offset:entry.offset,size:entry.size,bounds:entry.bounds};
   if(previous)assert.deepEqual(placement,previous,'State change moves sprite: '+id);
   previous=placement;
   if(layer!=='floor')continue;
   const image=await sharp(sprites+id+'.png').ensureAlpha().raw().toBuffer();
   assert.equal(image.length,normal.data.length);
   for(let y=0;y<normal.info.height;y++)for(let x=0;x<normal.info.width;x++){
    const p=P.ground([entry.offset[0]+x+.5,entry.offset[1]+y+.5]);
    if(p[0]>.17&&p[0]<.83&&p[1]>.17&&p[1]<.83)continue;
    const i=(y*normal.info.width+x)*4;
    assert.deepEqual(image.subarray(i,i+4),normal.data.subarray(i,i+4),'Outside paving changed: '+id);
    samePixels++;
   }
  }
 }
 const trapIds=Object.keys(catalog.atlas.regions).filter(id=>id.startsWith('trap-'));
 assert.equal(trapIds.length,15);
 const page=catalog.atlas.pages.find(p=>p.path.includes('/traps/'));
 assert.ok(page.uncompressedRGBABytes<=2*1024*1024,'Unexpected trap memory growth');
 const report={preservedRegions:Object.keys(baseline.regions).length,preservedPages:2,sourceHashesUnchanged:true,identicalBorderPixels:samePixels,trapRegions:trapIds.length,trapPage:page,totalRGBABytes:catalog.atlas.uncompressedRGBABytes};
 fs.writeFileSync(dir+'/export-validation.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e);process.exitCode=1});
