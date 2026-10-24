const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/mobile-heart-review/ritual-v3/integration';
const read=p=>fs.readFileSync(path.join(ROOT,p));
const json=p=>JSON.parse(read(p));
async function pixels(atlas,region){
  const [left,top,width,height]=region;
  return sharp(atlas).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
}
async function main(){
  if(process.argv.includes('--publish-captures')){
    const option=process.argv.find(a=>a.startsWith('--capture-root='));
    const source=option?option.slice('--capture-root='.length):OUT+'/scenes';
    const checks=[];
    for(const scene of ['MobileReference','SixRoomPreview','DungeonPreview']){
      const runtime=await sharp(read(`${source}/captures/${scene}-heart-0.png`)).raw().toBuffer();
      const editor=await sharp(read(`${source}/editor-captures/${scene}-heart-0.png`)).raw().toBuffer();
      checks.push({scene,sameCameraEditorRuntimeEqual:runtime.equals(editor)});
    }
    for(const folder of ['captures','editor-captures'])for(const file of fs.readdirSync(path.join(ROOT,source,folder)))
      if(file.endsWith('.png'))write(path.join(ROOT,'docs/reference/mobile-kit',folder,file),read(`${source}/${folder}/${file}`));
    for(const file of ['scene-inventory.json','editor-scene-inventory.json'])
      write(path.join(ROOT,'docs/reference/mobile-kit',file),read(source+'/'+file));
    write(path.join(ROOT,OUT,'editor-report.json'),JSON.stringify({
      runtimeScenes:json(source+'/scene-inventory.json').length,runtimeCaptures:fs.readdirSync(path.join(ROOT,source,'captures')).filter(f=>f.endsWith('.png')).length,
      editorScenes:checks.length,editorCaptures:fs.readdirSync(path.join(ROOT,source,'editor-captures')).filter(f=>f.endsWith('.png')).length,checks},null,2)+'\n');
  }
  const before=json(OUT+'/source/catalog.json'),after=json('assets/dungeon/mobile-kit/catalog.json');
  const oldAtlas=read(OUT+'/source/atlas-256.png'),newAtlas=read('assets/dungeon/mobile-kit/atlas-256.png');
  const retained=[];
  for(const [id,old] of Object.entries(before.atlas.regions)){
    const next=after.atlas.regions[id];
    if(!next)throw Error('Missing retained sprite '+id);
    for(const field of ['size','offset','bounds','companions'])if(JSON.stringify(old[field])!==JSON.stringify(next[field]))throw Error('Changed '+id+' '+field);
    if(!(await pixels(oldAtlas,old.region)).equals(await pixels(newAtlas,next.region)))throw Error('Repacking changed pixels '+id);
    retained.push(id);
  }
  const heart=after.atlas.regions.heart;
  if(!heart)throw Error('Missing heart');
  // Same alpha-compositing stage as packing, so partial-alpha rounding is comparable.
  const approved=await sharp({create:{width:289,height:289,channels:4,background:'#00000000'}})
    .composite([{input:read('docs/reference/mobile-heart-review/ritual-v3/prepared/a-256.png'),left:0,top:0}]).raw().toBuffer();
  if(!approved.equals(await pixels(newAtlas,heart.region)))throw Error('Heart differs from approved pixels');
  const baseline=read('docs/reference/mobile-heart-review/ritual-v3/captures/a-256-center.png');
  const current=read(OUT+'/captures/center.png');
  const old=await sharp(baseline).raw().toBuffer(),now=await sharp(current).raw().toBuffer();
  if(old.length!==now.length)throw Error('Gameplay capture dimensions changed');
  let max=0,count=0,sum=0;
  for(let i=0;i<old.length;i++)if(old[i]!==now[i]){const difference=Math.abs(old[i]-now[i]);count++;sum+=difference;max=Math.max(max,difference);}
  // Informational: imported atlas filtering differs from the review ImageTexture.
  // Exact packed source pixels are checked above; rendered appearance is inspected.
  const report={retainedSprites:retained.length,retained,approvedHeartPixels:true,retainedPlacement:true,
    comparisonWithApprovedGodotCapture:{differentChannels:count,maxChannelDifference:max,meanAbsoluteChannelDifference:sum/old.length},
    spriteCount:after.spriteCount,atlas:[after.atlas.width,after.atlas.height],pngBytes:after.atlas.sourceBytes,rgbaBytes:after.atlas.uncompressedRGBABytes,
    previousPngBytes:before.atlas.sourceBytes,extraPngBytes:after.atlas.sourceBytes-before.atlas.sourceBytes};
  write(path.join(ROOT,OUT,'atlas-report.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
