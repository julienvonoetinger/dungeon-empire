// Export provenance and visual boards. No art generation or approval rewriting.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),REVIEW='docs/reference/mobile-light-review/painted-v2',OUT=REVIEW+'/integration';
const read=p=>fs.readFileSync(path.join(ROOT,p));
const json=p=>JSON.parse(read(p));
const save=(p,b)=>write(path.join(ROOT,OUT,p),b);
async function region(png,r){const [left,top,width,height]=r;return sharp(png).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();}
async function main(){
  const old=json(OUT+'/source/catalog.json'),current=json('assets/dungeon/mobile-kit/catalog.json');
  const oldAtlas=read(OUT+'/source/atlas-256.png'),atlas=read('assets/dungeon/mobile-kit/atlas-256.png');
  const retained=[];
  for(const [id,before] of Object.entries(old.atlas.regions)){
    const after=current.atlas.regions[id];
    retained.push({id,pixelsEqual:!!after&&(await region(oldAtlas,before.region)).equals(await region(atlas,after.region)),
      placementEqual:!!after&&['offset','size','bounds','companions'].every(k=>JSON.stringify(before[k])===JSON.stringify(after[k]))});
  }
  const recipe=json(REVIEW+'/prepared.json'),adopted=[];
  for(const entry of recipe.entries){
    const target=current.atlas.regions[entry.id];
    // Packing composites native-alpha PNGs once; compare at that same stage.
    const expected=await sharp({create:{width:entry.size[0],height:entry.size[1],channels:4,background:'#00000000'}})
      .composite([{input:read(entry.file),left:0,top:0}]).raw().toBuffer();
    adopted.push({id:entry.id,pixelsEqual:expected.equals(await region(atlas,target.region)),
      placementEqual:JSON.stringify(entry.offset)===JSON.stringify(target.offset)&&JSON.stringify(entry.bounds)===JSON.stringify(target.bounds),
      size:entry.size});
  }
  const lit=read(OUT+'/captures/MobileReference-lit.png'),relit=read(OUT+'/captures/MobileReference-relit.png');
  const sameAfterToggle=(await sharp(lit).raw().toBuffer()).equals(await sharp(relit).raw().toBuffer());
  const baseline=await sharp(read(REVIEW+'/captures/with-local-light.png')).raw().toBuffer();
  const adoptedRoom=await sharp(read(OUT+'/captures/approved-room-lit.png')).raw().toBuffer();
  let changed=0,max=0,total=0;
  for(let i=0;i<baseline.length;i++){const delta=Math.abs(baseline[i]-adoptedRoom[i]);if(delta){changed++;max=Math.max(max,delta);total+=delta;}}
  const summary={retained,adopted,sameAfterLightToggle:sameAfterToggle,
    approvedRoomRenderDifference:{changedChannels:changed,maxChannelDifference:max,meanChannelDifference:total/baseline.length},
    spriteCount:current.spriteCount,atlas:[current.atlas.width,current.atlas.height],atlasPngBytes:current.atlas.sourceBytes,
    atlasExtraPngBytes:current.atlas.sourceBytes-old.atlas.sourceBytes,atlasRgbaBytes:current.atlas.uncompressedRGBABytes,
    lightPngBytes:read('assets/dungeon/mobile-kit/light-falloff.png').length,lightRgbaBytes:128*128*4};
  save('atlas-report.json',JSON.stringify(summary,null,2)+'\n');
  const panels=[];
  for(const [i,crop] of [{left:576,top:133,width:110,height:110},{left:330,top:370,width:110,height:150}].entries())
    panels.push({input:await sharp(read(OUT+'/captures/approved-room-lit.png')).extract(crop).resize(crop.width*2,crop.height*2,{kernel:'nearest'}).png().toBuffer(),left:20+i*260,top:45});
  const labels=Buffer.from('<svg width="520" height="365"><g font-family="Segoe UI,Arial" font-size="17" fill="#e5edf7"><text x="20" y="28">Mur horizontal — ×2</text><text x="280" y="28">Mur vertical — ×2</text></g></svg>');
  save('attachment-details.png',await sharp({create:{width:520,height:365,channels:4,background:'#0b1019'}})
    .composite([...panels,{input:labels,left:0,top:0}]).png().toBuffer());
  save('game-view.png',lit);
  console.log(JSON.stringify({...summary,retained:retained.length,allRetainedEqual:retained.every(r=>r.pixelsEqual&&r.placementEqual)}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
