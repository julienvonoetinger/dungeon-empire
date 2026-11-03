// Active painted kit. Frozen wireframe review is read-only; all new evidence
// and prepared PNGs go to painted-v1. Godot consumes the packed results only.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs'),Props=require('./isometric_prop_paint.cjs'),B=require('./prepare_mobile_reference.cjs');
const HeartLight=require('./isometric_approved_heart_light.cjs');
const WallVariants=require('./isometric_wall_variants.cjs');
const FloorVariants=require('./isometric_floor_variants.cjs');
const FloorDamage=require('./isometric_floor_damage.cjs');
const RitualProps=require('./isometric_ritual_props.cjs');
const TreasureChest=require('./isometric_treasure_chest.cjs');
const InsetTraps=require('./isometric_painted_traps.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const OUT='docs/reference/isometric-review/painted-v1',ASSETS='assets/dungeon/isometric-kit',GEOMETRY='docs/reference/isometric-review/migration-v1/geometry.json';
const write=(p,b)=>writeGeneratedFile(path.join(P.ROOT,p),b),json=(p,v)=>write(p,JSON.stringify(v,null,2)+'\n');
const doorReview='docs/reference/door-redesign/seal-v1';
const frameCatalog=doorReview+'/v16-segmental-frame/parts.json',hingeCatalog=doorReview+'/v17-door-materials/hinges.json';
async function reviewedDoors() {
  const frames=JSON.parse(fs.readFileSync(path.join(P.ROOT,frameCatalog)));
  const hinges=JSON.parse(fs.readFileSync(path.join(P.ROOT,hingeCatalog))).parts;
  const closed=[],open=[],variants=[],files=new Map();
  async function part(id,meta,file,doorPart) {
    const approvedSource=doorReview+'/v17-door-materials/parts/'+file;
    if(!files.has(file)){
      const png=fs.readFileSync(path.join(P.ROOT,approvedSource));
      const {width,height}=await sharp(png).metadata();
      if(width!==meta.size[0]||height!==meta.size[1])throw Error('Door source size mismatch: '+file);
      files.set(file,png);
    }
    return {id,frame:[...meta.offset,...meta.size],bounds:meta.bounds,doorPart,approvedSource,png:files.get(file)};
  }
  for(const d of ['north','east','south','west']){
    const prefix='door-'+d+'-';
    for(const [suffix,role] of [['leaf','jamb-left'],['arch','crown'],['jamb-right','jamb-right']]){
      const stone=await part(prefix+suffix,frames[prefix+suffix],d+'-'+suffix+'.png',role);
      const openStone={...stone,id:prefix+'open-'+suffix};
      if(suffix==='leaf'){
        stone.companions=[prefix+'jamb-right',prefix+'panel'];
        openStone.companions=[prefix+'open-jamb-right'];
      }
      closed.push(stone);open.push(openStone);
    }
    for(const material of ['wood','arcane','iron','grille']){
      const panel=await part(prefix+(material==='wood'?'':material+'-')+'panel',frames[prefix+'panel'],material+'-'+d+'-panel.png','panel');
      (material==='wood'?closed:variants).push(panel);
      if(material==='grille')continue;
      for(const side of ['left','right']){
        const suffix='panel-'+side;
        variants.push(await part(prefix+material+'-'+suffix,hinges[prefix+suffix],material+'-'+d+'-'+suffix+'.png','panel'));
      }
    }
  }
  return {closed,open,variants};
}
async function packDoors(doors) {
  // Frame state aliases and identical masonry PNGs share texels. Placement
  // and physical sorting bounds still belong to each individual resource.
  const unique=new Map(),sourceId=new Map();
  for(const item of doors){
    const hash=crypto.createHash('sha256').update(item.png).digest('hex');
    if(!unique.has(hash))unique.set(hash,item);
    sourceId.set(item.id,unique.get(hash).id);
  }
  const packed=await B.pack([...unique.values()],256,ASSETS+'/open-doors',false,1024);
  const regions={};
  for(const item of doors)regions[item.id]={...packed.regions[sourceId.get(item.id)],offset:item.frame.slice(0,2),size:item.frame.slice(2)};
  return {...packed,regions};
}
const fixedSources={
  [GEOMETRY]:'316151de97888a6418dd156af75a10f29b63ce497dd5c2e48e07cf45fbf646f0',
  'docs/reference/mobile-door-frame-review/painted-art-v2/source/door-face-fitted.png':'e69233ab8fb2421ed75ad9fd74ef97617ed29bf7d7bd4c008553cd797b859b55'
};
async function prepare(item,model) {
  write(`${OUT}/sprites/${item.id}.png`,item.png);
  if(item.groundEffect){console.log('Prepared '+item.id);return;}
  // Original visible guide, translated only if the effect needs a larger canvas.
  const sourceId=item.id==='pillar-top-carved'?'pillar':item.id;
  let guide=item.guide;
  if(!guide){
    const original=fs.readFileSync(path.join(P.ROOT,`docs/reference/isometric-review/migration-v1/guides/${sourceId}.svg`),'utf8');
    const body=original.slice(original.indexOf('>')+1,original.lastIndexOf('</svg>'));
    guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${item.frame[2]}" height="${item.frame[3]}"><g transform="translate(${model.frame[0]-item.frame[0]} ${model.frame[1]-item.frame[1]})">${body}</g></svg>`;
  }
  const png=await sharp(Buffer.from(guide)).png().toBuffer();
  write(`${OUT}/guides/${item.id}.svg`,guide);write(`${OUT}/guides/${item.id}.png`,png);
  write(`${OUT}/overlays/${item.id}.png`,await sharp(item.png).composite([{input:png}]).png().toBuffer());
  if(item.metalPNG)write(`${OUT}/sprites/${item.id}-metal.png`,item.metalPNG);
  console.log('Prepared '+item.id);
}
async function main() {
  for(const [file,hash] of Object.entries(fixedSources))if(P.hash(file)!==hash)throw Error('Frozen source changed: '+file);
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
  const doors=await reviewedDoors();
  items.push(...doors.closed);
  const wallVariants=await WallVariants.approvedWallVariants();
  items.push(...wallVariants);
  const floorVariants=await FloorVariants.preparedFloorVariants();
  for(const item of floorVariants){items.push(item);write(`${OUT}/sprites/${item.id}.png`,item.png);}
  const floorDamage=await FloorDamage.preparedFloorDamage(floorVariants);
  for(const item of floorDamage){items.push(item);write(`${OUT}/sprites/${item.id}.png`,item.png);}
  const ritualProps=await RitualProps.preparedRitualProps();
  for(const item of ritualProps){items.push(item);write(`${OUT}/sprites/${item.id}.png`,item.png);}
  // Keep the near-full architecture page unchanged; gameplay props get a small page.
  // Taller closed doors share the existing door page with their open frames,
  // instead of doubling the nearly full architecture page.
  const atlas=await B.pack(items.filter(item=>!item.id.startsWith('door-')),256,ASSETS,false);
  const treasureChest=await TreasureChest.preparedTreasureChest();
  for(const item of treasureChest){items.push(item);write(`${OUT}/sprites/${item.id}.png`,item.png);}
  const chestPath=`res://${ASSETS}/chests/atlas-256.png`;
  const chestAtlas=await B.pack(treasureChest,256,ASSETS+'/chests',false,256);
  atlas.pages=[{path:`res://${ASSETS}/atlas-256.png`,width:atlas.width,height:atlas.height,sourceBytes:atlas.sourceBytes,uncompressedRGBABytes:atlas.uncompressedRGBABytes},
    {path:chestPath,width:chestAtlas.width,height:chestAtlas.height,sourceBytes:chestAtlas.sourceBytes,uncompressedRGBABytes:chestAtlas.uncompressedRGBABytes}];
  atlas.sourceBytes+=chestAtlas.sourceBytes;
  atlas.uncompressedRGBABytes+=chestAtlas.uncompressedRGBABytes;
  for(const [id,entry] of Object.entries(chestAtlas.regions))atlas.regions[id]={...entry,atlas_path:chestPath};
  const traps=await InsetTraps.preparedInsetTraps(floorVariants[0]);
  const trapPath=`res://${ASSETS}/traps/atlas-256.png`;
  for(const item of traps){items.push(item);write(`${OUT}/sprites/${item.id}.png`,item.png);}
  const trapAtlas=await B.pack(traps,256,ASSETS+'/traps',false,512);
  atlas.pages.push({path:trapPath,width:trapAtlas.width,height:trapAtlas.height,sourceBytes:trapAtlas.sourceBytes,uncompressedRGBABytes:trapAtlas.uncompressedRGBABytes});
  atlas.sourceBytes+=trapAtlas.sourceBytes;
  atlas.uncompressedRGBABytes+=trapAtlas.uncompressedRGBABytes;
  for(const [id,entry] of Object.entries(trapAtlas.regions))atlas.regions[id]={...entry,atlas_path:trapPath};
  items.push(...doors.open,...doors.variants);
  const openPath=`res://${ASSETS}/open-doors/atlas-256.png`;
  const openAtlas=await packDoors([...doors.closed,...doors.open,...doors.variants]);
  atlas.pages.push({path:openPath,width:openAtlas.width,height:openAtlas.height,sourceBytes:openAtlas.sourceBytes,uncompressedRGBABytes:openAtlas.uncompressedRGBABytes});
  atlas.sourceBytes+=openAtlas.sourceBytes;
  atlas.uncompressedRGBABytes+=openAtlas.uncompressedRGBABytes;
  for(const [id,entry] of Object.entries(openAtlas.regions))atlas.regions[id]={...entry,atlas_path:openPath};
  for(const item of items) {
    atlas.regions[item.id].bounds=item.bounds;
    if(item.light)atlas.regions[item.id].light=item.light;
    if(item.groundShadow)atlas.regions[item.id].ground_shadow=item.groundShadow;
    if(item.groundShadowDirections)atlas.regions[item.id].ground_shadow_directions=item.groundShadowDirections;
    if(item.groundEffect)atlas.regions[item.id].ground_effect=true;
    if(item.groundEffects)atlas.regions[item.id].ground_effects=item.groundEffects;
    if(item.groundBlend)atlas.regions[item.id].ground_blend=item.groundBlend;
    if(item.wallVariant)atlas.regions[item.id].wall_variant=item.wallVariant;
    if(item.floorVariant)atlas.regions[item.id].floor_variant=item.floorVariant;
    if(item.floorDamage)atlas.regions[item.id].floor_damage=item.floorDamage;
    if(item.decoration)atlas.regions[item.id].decoration=item.decoration;
    if(item.vortex)atlas.regions[item.id].vortex=item.vortex;
    if(item.wallJunction)atlas.regions[item.id].wall_junction=item.wallJunction;
    if(item.companions)atlas.regions[item.id].companions=item.companions;
    if(item.doorPart)atlas.regions[item.id].door_part=item.doorPart;
    if(item.trap)atlas.regions[item.id].trap=item.trap;
  }
  const manifest={id:'isometric-painted-v1',appearance:'shared dungeon stone, segmental arches and wood, arcane, iron and grille doors',density:256,worldPixelsPerCell:256,sourceDiamond:[256,128],displayDiamond:[192,96],cameraZoom:.75,logicalCell:[1,1],camera:P.camera,wallThickness:P.T,wallHeight:P.H,pillarWidth:P.PILLAR,floorRows:3,spriteCount:items.length,optionalDetails:['pillar-top-carved'],lighting:true,atlas};
  manifest.wallVariants=wallVariants.filter(v=>!v.wallVariant.ornament).map(v=>v.id);
  manifest.optionalWallOrnaments=wallVariants.filter(v=>v.wallVariant.ornament).map(v=>v.id);
  manifest.floorVariants=floorVariants.map(v=>v.id);
  manifest.floorDamage=floorDamage.map(v=>v.id);
  manifest.decorations=[...ritualProps,...treasureChest].filter(v=>v.decoration).map(v=>v.id);
  json(`${ASSETS}/catalog.json`,manifest);
  const pageIds=new Map(atlas.pages.map((p,i)=>[p.path,String(i+2)]));
  const resources=items.map((m,i)=>`[sub_resource type="AtlasTexture" id="Sprite_${i}"]\natlas = ExtResource("${pageIds.get(atlas.regions[m.id].atlas_path||atlas.pages[0].path)}")\nregion = Rect2(${atlas.regions[m.id].region.join(', ')})\nfilter_clip = true\n`).join('\n');
  const pageResources=atlas.pages.map(p=>`[ext_resource type="Texture2D" path="${p.path}" id="${pageIds.get(p.path)}"]`).join('\n');
  write(`${ASSETS}/catalog.tres`,`[gd_resource type="Resource" load_steps=${items.length+atlas.pages.length+2} format=3]\n\n[ext_resource type="Script" path="res://scripts/mobile_kit_definition.gd" id="1"]\n${pageResources}\n\n${resources}\n[resource]\nscript = ExtResource("1")\nprojection_x = Vector3(${P.camera.x.join(', ')})\nprojection_y = Vector3(${P.camera.y.join(', ')})\nview_direction = Vector3(${P.camera.eye.join(', ')})\nentries = ${JSON.stringify(atlas.regions)}\ntextures = {${items.map((p,i)=>JSON.stringify(p.id)+`: SubResource("Sprite_${i}")`).join(',\n')}}\n`);
  const sourceFiles=[...P.sourceFiles,GEOMETRY,...Object.keys(fixedSources),...Object.values(Props.sources).map(v=>v[0]),'assets/dungeon/shared-materials/catalog.json',
    'tools/export_isometric_painted_kit.cjs','tools/isometric_kit_geometry.cjs','tools/wireframe_geometry.cjs','tools/isometric_paint_geometry.cjs','tools/isometric_stone_paint.cjs','tools/isometric_prop_paint.cjs','tools/prepare_mobile_reference.cjs','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','assets/dungeon/shared-materials/stone-finish.json'];
  const materialCatalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/shared-materials/catalog.json')));
  sourceFiles.push('tools/isometric_approved_heart_light.cjs',...HeartLight.referenceFiles);
  sourceFiles.push('tools/isometric_wall_variants.cjs','tools/isometric_wall_palette.cjs',...WallVariants.referenceFiles);
  sourceFiles.push('tools/isometric_floor_variants.cjs',...FloorVariants.referenceFiles);
  sourceFiles.push('tools/isometric_floor_damage.cjs',...FloorDamage.referenceFiles);
  sourceFiles.push('tools/isometric_ritual_props.cjs',...RitualProps.referenceFiles);
  sourceFiles.push('tools/isometric_treasure_chest.cjs',...TreasureChest.referenceFiles);
  sourceFiles.push(frameCatalog,hingeCatalog,...[...doors.closed,...doors.variants].map(item=>item.approvedSource));
  sourceFiles.push('tools/isometric_painted_traps.cjs',...InsetTraps.referenceFiles);
  for(const entry of Object.values(materialCatalog.entries))if(entry.file)sourceFiles.push(path.posix.normalize('assets/dungeon/shared-materials/'+entry.file));
  json(`${OUT}/recipe.json`,{...manifest,generator:'tools/export_isometric_painted_kit.cjs',geometry:GEOMETRY,sourceHashes:Object.fromEntries([...new Set(sourceFiles)].map(p=>[p,P.hash(p)])),
    items:items.map(({id,frame,bounds,report,adaptation,light,groundShadow,groundShadowDirections,groundEffect,groundEffects,groundBlend,wallVariant,floorVariant,floorDamage,approvedSource,png})=>({id,frame,bounds,report,adaptation,light,groundShadow,groundShadowDirections,groundEffect,groundEffects,groundBlend,wallVariant,floorVariant,floorDamage,approvedSource,bytes:png.length})),
    notes:['Historical approved sources and wireframe snapshots remain unchanged.','The heart reuses source sculptural details on the rigid support and a camera-facing vortex; this adapted appearance is not a new approval.','Flame uses one screen scale with physical cup occlusion.','Doors use v16 segmental-frame placement and v17 reviewed raster parts at native density. Open and closed frames share masonry. Each hinged half uses its reviewed offset and sorting bounds.']});
  console.log(JSON.stringify({sprites:items.length,atlas:[atlas.width,atlas.height],pngBytes:atlas.sourceBytes,rgbaBytes:atlas.uncompressedRGBABytes}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
