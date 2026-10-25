// Active painted kit. Frozen wireframe review is read-only; all new evidence
// and prepared PNGs go to painted-v1. Godot consumes the packed results only.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs'),Props=require('./isometric_prop_paint.cjs'),B=require('./prepare_mobile_reference.cjs');
const HeartLight=require('./isometric_approved_heart_light.cjs');
const Details=require('./isometric_approved_decorations.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const OUT='docs/reference/isometric-review/painted-v1',ASSETS='assets/dungeon/isometric-kit',GEOMETRY='docs/reference/isometric-review/migration-v1/geometry.json';
const write=(p,b)=>writeGeneratedFile(path.join(P.ROOT,p),b),json=(p,v)=>write(p,JSON.stringify(v,null,2)+'\n');
const fixedSources={
  [GEOMETRY]:'316151de97888a6418dd156af75a10f29b63ce497dd5c2e48e07cf45fbf646f0',
  'docs/reference/mobile-door-frame-review/painted-art-v2/source/door-face-fitted.png':'e69233ab8fb2421ed75ad9fd74ef97617ed29bf7d7bd4c008553cd797b859b55'
};
async function prepare(item,model) {
  write(`${OUT}/sprites/${item.id}.png`,item.png);
  if(item.groundEffect){console.log('Prepared '+item.id);return;}
  // Original visible guide, translated only if the effect needs a larger canvas.
  const sourceId=item.id==='pillar-top-carved'?'pillar':item.id;
  const original=fs.readFileSync(path.join(P.ROOT,`docs/reference/isometric-review/migration-v1/guides/${sourceId}.svg`),'utf8');
  const body=original.slice(original.indexOf('>')+1,original.lastIndexOf('</svg>'));
  const guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${item.frame[2]}" height="${item.frame[3]}"><g transform="translate(${model.frame[0]-item.frame[0]} ${model.frame[1]-item.frame[1]})">${body}</g></svg>`;
  const png=await sharp(Buffer.from(guide)).png().toBuffer();
  write(`${OUT}/guides/${item.id}.svg`,guide);write(`${OUT}/guides/${item.id}.png`,png);
  write(`${OUT}/overlays/${item.id}.png`,await sharp(item.png).composite([{input:png}]).png().toBuffer());
  if(item.metalPNG)write(`${OUT}/sprites/${item.id}-metal.png`,item.metalPNG);
  console.log('Prepared '+item.id);
}
async function main() {
  for(const [file,hash] of Object.entries(fixedSources))if(P.hash(file)!==hash)throw Error('Frozen source changed: '+file);
  const details=await Details.approvedDecorations();
  const items=[],byId=new Map(P.models.map(m=>[m.id,m]));
  for(const m of P.models) {
    if(m.id.startsWith('door-'))continue;
    const item=m.id==='heart'?await Props.heart(m):m.id.startsWith('torch-')?await Props.torch(m):await Stone.architecture(m);
    items.push(item);await prepare(item,m);
    if(m.id==='heart') {
      const effects=await HeartLight.approvedHeartLight();
      item.groundEffects=effects.effects;
      for(const effect of effects.items){items.push(effect);await prepare(effect,m);}
    }
    if(m.id==='pillar') {const cap=await Props.cap(m,item);items.push(cap);await prepare(cap,m);}
  }
  for(const d of ['north','east','south','west'])for(const item of await Stone.doors(d)) {items.push(item);await prepare(item,byId.get(item.id));}
  for(const item of details) {items.push(item);write(`${OUT}/sprites/${item.id}.png`,item.png);}
  const atlas=await B.pack(items,256,ASSETS,false);
  for(const item of items) {
    atlas.regions[item.id].bounds=item.bounds;
    if(item.light)atlas.regions[item.id].light=item.light;
    if(item.groundShadow)atlas.regions[item.id].ground_shadow=item.groundShadow;
    if(item.groundShadowDirections)atlas.regions[item.id].ground_shadow_directions=item.groundShadowDirections;
    if(item.groundEffect)atlas.regions[item.id].ground_effect=true;
    if(item.groundEffects)atlas.regions[item.id].ground_effects=item.groundEffects;
    if(item.groundBlend)atlas.regions[item.id].ground_blend=item.groundBlend;
    if(item.surfaceDetail)atlas.regions[item.id].surface_detail=item.surfaceDetail;
  }
  const manifest={id:'isometric-painted-v1',appearance:'approved material sources adapted to frozen isometric volumes',density:256,worldPixelsPerCell:256,sourceDiamond:[256,128],displayDiamond:[192,96],cameraZoom:.75,logicalCell:[1,1],camera:P.camera,wallThickness:P.T,wallHeight:P.H,pillarWidth:P.PILLAR,floorRows:3,spriteCount:items.length,optionalDetails:['pillar-top-carved',...details.map(d=>d.id)],lighting:true,atlas};
  json(`${ASSETS}/catalog.json`,manifest);
  const resources=items.map((m,i)=>`[sub_resource type="AtlasTexture" id="Sprite_${i}"]\natlas = ExtResource("2")\nregion = Rect2(${atlas.regions[m.id].region.join(', ')})\nfilter_clip = true\n`).join('\n');
  write(`${ASSETS}/catalog.tres`,`[gd_resource type="Resource" load_steps=${items.length+3} format=3]\n\n[ext_resource type="Script" path="res://scripts/mobile_kit_definition.gd" id="1"]\n[ext_resource type="Texture2D" path="res://${ASSETS}/atlas-256.png" id="2"]\n\n${resources}\n[resource]\nscript = ExtResource("1")\nprojection_x = Vector3(${P.camera.x.join(', ')})\nprojection_y = Vector3(${P.camera.y.join(', ')})\nview_direction = Vector3(${P.camera.eye.join(', ')})\nentries = ${JSON.stringify(atlas.regions)}\ntextures = {${items.map((p,i)=>JSON.stringify(p.id)+`: SubResource("Sprite_${i}")`).join(',\n')}}\n`);
  const sourceFiles=[...P.sourceFiles,GEOMETRY,...Object.keys(fixedSources),...Object.values(Props.sources).map(v=>v[0]),'assets/dungeon/shared-materials/catalog.json',
    'tools/export_isometric_painted_kit.cjs','tools/isometric_kit_geometry.cjs','tools/wireframe_geometry.cjs','tools/isometric_paint_geometry.cjs','tools/isometric_stone_paint.cjs','tools/isometric_prop_paint.cjs','tools/prepare_mobile_reference.cjs','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','assets/dungeon/shared-materials/stone-finish.json'];
  const materialCatalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/shared-materials/catalog.json')));
  sourceFiles.push('tools/isometric_approved_decorations.cjs',...Details.referenceFiles,...details.map(d=>d.approvedSource));
  sourceFiles.push('tools/isometric_approved_heart_light.cjs',...HeartLight.referenceFiles);
  for(const entry of Object.values(materialCatalog.entries))if(entry.file)sourceFiles.push(path.posix.normalize('assets/dungeon/shared-materials/'+entry.file));
  json(`${OUT}/recipe.json`,{...manifest,generator:'tools/export_isometric_painted_kit.cjs',geometry:GEOMETRY,sourceHashes:Object.fromEntries([...new Set(sourceFiles)].map(p=>[p,P.hash(p)])),
    items:items.map(({id,frame,bounds,report,adaptation,light,groundShadow,groundShadowDirections,groundEffect,groundEffects,groundBlend,surfaceDetail,approvedSource,png})=>({id,frame,bounds,report,adaptation,light,groundShadow,groundShadowDirections,groundEffect,groundEffects,groundBlend,surfaceDetail,approvedSource,bytes:png.length})),
    notes:['No approved source regenerated; wireframe snapshots unchanged.','The heart reuses source sculptural details on the rigid support and a camera-facing vortex; this adapted appearance is not a new approval.','Flame uses one screen scale with physical cup occlusion.','All 4 doors are painted as complete volumes, then split at wall height without an added seam.']});
  console.log(JSON.stringify({sprites:items.length,atlas:[atlas.width,atlas.height],pngBytes:atlas.sourceBytes,rgbaBytes:atlas.uncompressedRGBABytes}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
