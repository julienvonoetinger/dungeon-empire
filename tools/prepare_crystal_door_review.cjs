// Before/after paint review on the accepted geometry; never exports the active kit.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Door=require('./isometric_seal_door.cjs');
const OUT='docs/reference/door-redesign/seal-v1/hero-fit-v15-iron-crystals';
const leafPainting=OUT+'/source/face-source.png';
const previousPainting='docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/source/face-source.png';
function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):[path.join(dir,e.name)]);}
async function main(){
 const source=await sharp(path.join(P.ROOT,leafPainting)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 assert.equal(source.info.width,1024);assert.equal(source.info.height,1536);
 const contact=(1138*source.info.width+512)*4,keyhole=[...source.data.subarray(contact,contact+4)];
 assert(keyhole.slice(0,3).every(v=>v<35)&&keyhole[3]>240,'The original tool contact must remain inside the black keyhole');
 const protectedFiles=files(path.join(P.ROOT,'assets/dungeon/isometric-kit')).map(p=>path.relative(P.ROOT,p).replaceAll('\\','/'));
 const before=Object.fromEntries(protectedFiles.map(p=>[p,P.hash(p)]));
 fs.mkdirSync(path.join(P.ROOT,OUT,'parts'),{recursive:true});
 const catalog={},previousCatalog={},preserved=[];
 for(const direction of ['south','north','east','west']){
  const original=await Door.paint(direction,false,previousPainting),proposal=await Door.paint(direction,false,leafPainting);
  assert.deepEqual(proposal.model,original.model);
  const panel=original.parts.find(p=>p.doorPart==='panel');
  const mask=await sharp(panel.png).ensureAlpha().raw().toBuffer();
  for(let i=0;i<proposal.parts.length;i++){
   const part=proposal.parts[i],old=original.parts[i];
   for(const field of ['frame','bounds','doorPart','wallJunction','companions'])assert.deepEqual(part[field],old[field]);
   if(part.doorPart!=='panel'){
    // The existing split copies opaque pixels across a 2px part seam. Those
    // deliberately shared panel pixels change with the leaf, not the stone.
    const a=await sharp(part.png).ensureAlpha().raw().toBuffer(),b=await sharp(old.png).ensureAlpha().raw().toBuffer();
    let sharedPanelPixels=0;
    for(let k=0;k<a.length;k+=4)if(!a.subarray(k,k+4).equals(b.subarray(k,k+4))){
     const pixel=k/4,x=pixel%part.frame[2]+part.frame[0]-panel.frame[0],y=Math.floor(pixel/part.frame[2])+part.frame[1]-panel.frame[1];
     let nearPanel=false;
     for(let dy=-3;dy<=3;dy++)for(let dx=-3;dx<=3;dx++){
      const X=x+dx,Y=y+dy;
      if(X>=0&&X<panel.frame[2]&&Y>=0&&Y<panel.frame[3]&&mask[(Y*panel.frame[2]+X)*4+3]>0)nearPanel=true;
     }
     assert(nearPanel,'Stone outside the shared panel seam/filter fringe changed: '+part.id);
     sharedPanelPixels++;
    }
    preserved.push({id:part.id,stonePixelIdenticalOutsidePanelFringe:true,sharedPanelPixels,filterFringePixels:3});
   }
   const file='parts/'+part.id+'.png'; fs.writeFileSync(path.join(P.ROOT,OUT,file),part.png);
   catalog[part.id]={file,offset:part.frame.slice(0,2),size:part.frame.slice(2),bounds:part.bounds,door_part:part.doorPart,companions:part.companions,wall_junction:part.wallJunction};
   const previousFile='parts/previous-'+part.id+'.png';fs.writeFileSync(path.join(P.ROOT,OUT,previousFile),old.png);
   previousCatalog[part.id]={...catalog[part.id],file:previousFile};
  }
  fs.writeFileSync(path.join(P.ROOT,OUT,`door-${direction}.png`),proposal.full.png);
 }
 for(const [p,hash]of Object.entries(before))assert.equal(P.hash(p),hash,'Runtime changed: '+p);
 fs.writeFileSync(path.join(P.ROOT,OUT,'preview-catalog.json'),JSON.stringify(catalog,null,2)+'\n');
 fs.writeFileSync(path.join(P.ROOT,OUT,'previous-catalog.json'),JSON.stringify(previousCatalog,null,2)+'\n');
 fs.writeFileSync(path.join(P.ROOT,OUT,'preservation.json'),JSON.stringify({status:'review-generated-runtime-unchanged',leafPainting,sourceHash:P.hash(leafPainting),generator:'built-in ImageGen',keyhole,geometryUnchanged:true,framesAndSupportsUnchanged:true,stonePartsPixelIdentical:preserved,production:before,limits:'This review generator does not install or test gameplay. Installation and native validation are recorded separately in selection.json, integration.json and README.md. Crystal relief is painted onto the existing smooth leaf receiver.'},null,2)+'\n');
 console.log('4 orientations, 16 review parts; masonry unchanged outside shared panel seams; runtime assets unchanged.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
