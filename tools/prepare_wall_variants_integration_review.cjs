// Assemble existing Godot captures for human review; no rendering assertions.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/wall-variants-integration';
const read=p=>fs.readFileSync(path.join(ROOT,p));
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const scenes=fs.readdirSync(path.join(ROOT,'scenes')).filter(p=>p.endsWith('.tscn')&&(p==='EntranceVariants.tscn'||read('scenes/'+p).toString().includes('wireframe_cell_study.gd'))).map(p=>p.slice(0,-5)).sort();
const details=[
  ...['north','east','south','west'].map(d=>['Porte '+d,'wireframe-door-'+d+'-detail.png']),
  ...['north','east','south','west'].map(d=>['Escalier '+d,'wireframe-entrance-'+d+'-detail.png']),
  ...['entry','crossing','west-join','southwest-join','lower-join'].map(d=>['SixRoom '+d,'wireframe-six-rooms-'+d+'.png']),
];
async function board(items,file,columns,width,height){
  const rows=Math.ceil(items.length/columns),layers=[];
  for(const [i,[name,src]]of items.entries()){
    const left=(i%columns)*width,top=Math.floor(i/columns)*height;
    layers.push({input:await sharp(read(src)).resize(width-12,height-34,{fit:'contain',background:'#080d16'}).png().toBuffer(),left:left+6,top:top+28});
    layers.push({input:Buffer.from('<svg width="'+width+'" height="28"><text x="8" y="19" fill="#dae2ee" font-family="sans-serif" font-size="15">'+name+'</text></svg>'),left,top});
  }
  write(OUT+'/'+file,await sharp({create:{width:columns*width,height:rows*height,channels:4,background:'#080d16'}}).composite(layers).png().toBuffer());
}
async function main(){
  await board(scenes.map(n=>[n,'artifacts/wireframe-'+n+'.png']),'scenes.png',4,480,390);
  await board(details.map(([n,p])=>[n,'artifacts/'+p]),'details.png',3,600,610);
  for(const [name,src]of [
    ['six-rooms.png','wireframe-SixRoomPreview.png'],
    ['room-5x5.png','wireframe-5x5RoomVerticalCornerCorridors.png'],
    ['wide-join.png','wireframe-six-rooms-west-join.png'],
  ])write(OUT+'/'+name,read('artifacts/'+src));
  const catalog=JSON.parse(read('assets/dungeon/painted-connected/catalog.json'));
  const validation=JSON.parse(read('assets/dungeon/painted-connected/validation.json'));
  const isolated=JSON.parse(read('docs/reference/painted-kit-review/validation.json'));
  const captures=[...scenes.flatMap(n=>['wireframe-'+n+'.png','wireframe-'+n+'-2x.png']),...details.map(d=>d[1])];
  const report={date:'2026-10-23',recipe:hash(read('assets/dungeon/shared-materials/active-recipe.json')),catalogId:catalog.id,wallStyles:catalog.wallStyles,uniqueStructuralImages:validation.uniqueStructuralImages,logicalContexts:validation.logicalContexts,emptyContexts:validation.emptyContexts,allConstructionJointLayersMatch:validation.allConstructionJointLayersMatch,alphaPixelsDifferentFromContextModel:validation.alphaPixelsDifferentFromContextModel,unpaintedInteriorPixels:validation.unpaintedInteriorPixels,isolated:{images:isolated.imageCount,aliases:isolated.guideEntryCount,alphaPixelsDifferentFromModel:isolated.alphaPixelsDifferentFromModel,unpaintedInteriorPixels:isolated.unpaintedInteriorPixels},floorSha256:hash(read('assets/dungeon/painted-connected/floor.png')),previousFloorSha256:hash(read('docs/reference/wall-variation-review/source/floor.png')),scenes,captures:Object.fromEntries(captures.map(p=>[p,hash(read('artifacts/'+p))])),scope:'Existing export audits and actual Godot scene captures for human review. No automated tests, arbitrary future joins or gameplay readability validation.'};
  write(OUT+'/review.json',JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({scenes:scenes.length,captures:captures.length,output:OUT}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
