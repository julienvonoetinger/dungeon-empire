const fs=require('node:fs'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const dir='docs/reference/trap-review/v12-approved-square';
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
async function main(){
 const baseline=JSON.parse(fs.readFileSync(dir+'/baseline.json'));
 const selected=JSON.parse(fs.readFileSync('docs/reference/trap-review/v7-integrated-paint/selection.json'));
 const catalog=JSON.parse(fs.readFileSync('assets/dungeon/isometric-kit/catalog.json'));
 for(const [file,h] of Object.entries({...baseline.hashes,...selected.hashes}))if(!file.startsWith('tools/'))assert.equal(hash(file),h,'Protected source/page changed: '+file);
 const unrelated=Object.entries(baseline.regions).filter(([id])=>!id.startsWith('trap-'));
 for(const [id,entry] of unrelated)assert.deepEqual(catalog.atlas.regions[id],entry,'Unrelated region changed: '+id);
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
   if(layer!=='floor'){
    const mechanism=await sharp(sprites+id+'.png').ensureAlpha().raw().toBuffer({resolveWithObject:true});
    const {width,height}=mechanism.info;
    for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(x<2||y<2||x>=width-2||y>=height-2)
     assert.equal(mechanism.data[(y*width+x)*4+3],0,'Mechanism touches frame: '+id);
    continue;
   }
   const image=await sharp(sprites+id+'.png').ensureAlpha().raw().toBuffer();
   assert.equal(image.length,normal.data.length);
   for(let y=0;y<normal.info.height;y++)for(let x=0;x<normal.info.width;x++){
    const p=P.ground([entry.offset[0]+x+.5,entry.offset[1]+y+.5]);
    if(p[0]>.06&&p[0]<.94&&p[1]>.06&&p[1]<.94)continue;
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
 const stones=require('./isometric_trap_receiver.cjs').rectangles;
 assert.equal(stones.length,12,'Receiver must match the approved complete stones');
 let area=0;
 for(let i=0;i<stones.length;i++){
  const [x,X,y,Y]=stones[i];area+=(Math.min(1,X)-Math.max(0,x))*(Math.min(1,Y)-Math.max(0,y));
  assert.ok(Math.min(X,.84)-Math.max(x,.16)<=1e-9||Math.min(Y,.84)-Math.max(y,.16)<=1e-9,'A stone crosses the socket');
  for(let j=0;j<i;j++){const [a,A,b,B]=stones[j];assert.ok(Math.min(X,A)-Math.max(x,a)<=1e-9||Math.min(Y,B)-Math.max(y,b)<=1e-9,'Receiver stones overlap');}
 }
 assert.ok(Math.abs(area-(1-.68*.68))<1e-9,'Receiver paving has a gap');
 // The holes must remain fixed, and no raised spike may be baked into this
 // shared ground layer. This catches the previous double-layer preparation.
 const images=await Promise.all(['ready','triggered','spent'].map(s=>sharp(sprites+`trap-spike-${s}-floor.png`).ensureAlpha().raw().toBuffer()));
 const before=await Promise.all(['ready','triggered','spent'].map(s=>sharp(`docs/reference/trap-review/v9-registered-sockets/before/trap-spike-${s}-floor.png`).ensureAlpha().raw().toBuffer()));
 let oldDifferences=0,registeredPixels=0;
 for(let y=0;y<normal.info.height;y++)for(let x=0;x<normal.info.width;x++){
  const entry=catalog.atlas.regions['trap-spike-ready-floor'],p=P.ground([entry.offset[0]+x+.5,entry.offset[1]+y+.5]);
  // Stay beyond the resampling footprint of the outer status-light marks.
  if(p[0]<.30||p[0]>.70||p[1]<.30||p[1]>.70)continue;
  const k=(y*normal.info.width+x)*4;
  for(let s=1;s<3;s++){
   assert.deepEqual(images[0].subarray(k,k+4),images[s].subarray(k,k+4),'Raised spike/shifted socket baked into ground');
   if(!before[0].subarray(k,k+4).equals(before[s].subarray(k,k+4)))oldDifferences++;
  }registeredPixels++;
 }
 assert.ok(oldDifferences>0,'Baseline did not reproduce old ground contamination');
 const report={preservedRegions:unrelated.length,preservedPages:2,sourceHashesUnchanged:true,identicalBorderPixels:samePixels,completeReceiverStones:12,registeredGroundPixels:registeredPixels,oldGroundDifferences:oldDifferences,newGroundDifferences:0,mechanismFramesPadded:true,trapRegions:trapIds.length,trapPage:page,totalRGBABytes:catalog.atlas.uncompressedRGBABytes};
 fs.writeFileSync(dir+'/export-validation.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e);process.exitCode=1});
