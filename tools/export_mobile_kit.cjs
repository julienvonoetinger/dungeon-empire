const path=require('node:path');
const B=require('./prepare_mobile_reference.cjs');
const R=require('./painted_material_renderer.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const OUT='docs/reference/mobile-kit',ASSETS='assets/dungeon/mobile-kit';
const write=(p,b)=>writeGeneratedFile(path.join(R.ROOT,p),b);
const json=(p,v)=>write(p,JSON.stringify(v,null,2)+'\n');
// Frozen comparison figures survive removal of the retired high-resolution PNGs.
const legacy=JSON.parse(R.read('docs/reference/mobile-kit/legacy-catalog-inventory.json'));
async function main(){
  const items=[await B.paint('floor',B.floor(),OUT)];
  items[0].bounds={min:[0,0,0],max:[1,1,0]};
  for(const [axis,h] of [['h',true],['v',false]])for(let bits=0;bits<4;bits++){
    const item=await B.paint(`wall-${axis}-${bits}`,B.wall(h,bits&1,bits&2),OUT);
    const lo=bits&1?B.PILLAR/2:0,hi=bits&2?1-B.PILLAR/2:1;
    item.bounds={min:h?[lo,-B.T/2,0]:[-B.T/2,lo,0],max:h?[hi,B.T/2,B.H]:[B.T/2,hi,B.H]};items.push(item);
  }
  const geometry=B.pillar(),pillar=await B.paint('pillar',geometry,OUT);
  pillar.bounds={min:[-B.PILLAR/2,-B.PILLAR/2,0],max:[B.PILLAR/2,B.PILLAR/2,B.H+.035]};items.push(pillar);
  const cap=await require('./mobile_pillar_cap.cjs').paintedPillarCap(pillar,geometry.faces.find(f=>f.kind==='top'));
  cap.bounds=pillar.bounds;items.push(cap);
  items.push(...await require('./mobile_special_parts.cjs').specials());
  const atlas=await B.pack(items,256,ASSETS,false);
  for(const item of items)atlas.regions[item.id].bounds=item.bounds;
  const manifest={id:'mobile-kit-v1',density:256,worldPixelsPerCell:256,displayPixelsPerCell:192,cameraZoom:.75,
    logicalCell:[1,1],projection:[-.18,-.9],wallThickness:B.T,wallHeight:B.H,pillarWidth:B.PILLAR,
    floorRows:3,baseAppearanceCount:1,spriteCount:items.length,optionalDetails:['pillar-top-carved'],atlas};
  json(`${ASSETS}/catalog.json`,manifest);
  const resources=items.map((item,i)=>`[sub_resource type="AtlasTexture" id="Sprite_${i}"]\natlas = ExtResource("2")\nregion = Rect2(${atlas.regions[item.id].region.join(', ')})\nfilter_clip = true\n`).join('\n');
  write(`${ASSETS}/catalog.tres`,`[gd_resource type="Resource" load_steps=${items.length+3} format=3]\n\n[ext_resource type="Script" path="res://scripts/mobile_kit_definition.gd" id="1"]\n[ext_resource type="Texture2D" path="res://${ASSETS}/atlas-256.png" id="2"]\n\n${resources}\n[resource]\nscript = ExtResource("1")\nentries = ${JSON.stringify(atlas.regions)}\ntextures = {${items.map((p,i)=>JSON.stringify(p.id)+`: SubResource("Sprite_${i}")`).join(',\n')}}\n`);
  const sourceFiles=['tools/prepare_mobile_reference.cjs','tools/mobile_special_parts.cjs','tools/export_mobile_kit.cjs','tools/mobile_pillar_cap.cjs','tools/painted_material_renderer.cjs','assets/dungeon/shared-materials/catalog.json','assets/dungeon/shared-materials/stone-finish.json','docs/reference/door-arch-cell-west-east-wireframe.json','docs/reference/entrance-stairs-open-south-wireframe.json','docs/reference/pillar-cap-review/source/carved-top.png','docs/reference/mobile-kit/legacy-catalog-inventory.json'];
  json(`${OUT}/recipe.json`,{...manifest,generator:'tools/export_mobile_kit.cjs',sourceHashes:Object.fromEntries(sourceFiles.map(p=>[p,R.hash(R.read(p))])),materialProfile:B.materials.renderProfile,exports:items.filter(i=>i.report).map(i=>i.report),
    oldConnected:legacy.oldConnected,oldIsolated:legacy.oldIsolated,
    scope:'Architecture migration: common bare geometry plus optional cap. No old A/B/C/D2 appearances or rejected medallions shipped. Atlas bytes are not mobile device performance measurements.'});
  console.log(JSON.stringify({sprites:items.length,atlas:[atlas.width,atlas.height],pngBytes:atlas.sourceBytes,rgbaBytes:atlas.uncompressedRGBABytes}));
}
main().catch(e=>{console.error(e.stack);if(e.diagnostic){write('artifacts/mobile-export-drawing.svg',e.diagnostic.drawing);write('artifacts/mobile-export-silhouette.svg',e.diagnostic.silhouette);}process.exitCode=1;});
