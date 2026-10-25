// Read-only integrity evidence for retiring the legacy crack sprites.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'../../../..');
const json=file=>JSON.parse(fs.readFileSync(file,'utf8').replace(/^\uFEFF/,''));
const frame=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
async function main(){
 const old=json(path.join(__dirname,'before/assets/dungeon/isometric-kit/catalog.json'));
 const current=json(path.join(root,'assets/dungeon/isometric-kit/catalog.json'));
 const retired=['corner-split','vertical-hairline','edge-fork','crack-corrupt'];
 const expected=retired.flatMap(m=>['floor','wall-h','wall-v'].map(s=>'detail-'+m+'-'+s));
 const removed=Object.keys(old.atlas.regions).filter(id=>!current.atlas.regions[id]);
 if(JSON.stringify([...removed].sort())!==JSON.stringify([...expected].sort()))throw Error('Unexpected removed inventory');
 let preserved=0;
 for(const [id,entry] of Object.entries(current.atlas.regions)){
  const previous=old.atlas.regions[id];if(!previous)throw Error('Unexpected new region '+id);
  const a=await sharp(path.join(__dirname,'before/assets/dungeon/isometric-kit/atlas-256.png')).extract(frame(previous.region)).raw().toBuffer();
  const b=await sharp(path.join(root,'assets/dungeon/isometric-kit/atlas-256.png')).extract(frame(entry.region)).raw().toBuffer();
  if(!a.equals(b))throw Error('Retained pixels changed '+id);
  const {region:oldRegion,...oldMeta}=previous,{region:newRegion,...newMeta}=entry;
  if(JSON.stringify(oldMeta)!==JSON.stringify(newMeta))throw Error('Retained metadata changed '+id);
  preserved++;
 }
 const deleted=json(path.join(__dirname,'deleted-files.json'));
 for(const entry of deleted)if(fs.existsSync(entry.file))throw Error('Retired prepared file still present '+entry.file);
 const evidence={date:'2026-10-25',removedRegions:removed,preservedRegions:preserved,
  deletedPreparedFiles:deleted.length,deletedPreparedBytes:deleted.reduce((n,e)=>n+e.bytes,0),
  atlas:{regions:current.spriteCount,size:[current.atlas.width,current.atlas.height],pngBytes:current.atlas.sourceBytes,rgbaBytes:current.atlas.uncompressedRGBABytes},
  keptDecorations:current.optionalDetails,sourcePolicy:'Original approval/review archives remain historical; active crack regions and generated production copies are removed.'};
 fs.writeFileSync(path.join(__dirname,'pixel-validation.json'),JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify(evidence));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
