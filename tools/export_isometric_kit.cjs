// Offline wireframe sprites, complete alpha silhouettes, and matching bright guides.
const path=require('node:path'),sharp=require('sharp');
const B=require('./prepare_mobile_reference.cjs');
const K=require('./isometric_kit_geometry.cjs'),G=require('./wireframe_geometry.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const OUT='docs/reference/isometric-review/migration-v1',ASSETS='assets/dungeon/isometric-kit';
const write=(p,b)=>writeGeneratedFile(path.join(K.ROOT,p),b);
const json=(p,v)=>write(p,JSON.stringify(v,null,2)+'\n');
const colors={wall:'#d7dfea',joint:'#8394ae',floor:'#51b4c9',door:'#e4af72',stair:'#79c9db',heart:'#f4bd78',plate:'#6ddfe9',arm:'#6ddfe9',bowl:'#f0bd76'};
const fmt=G.fmt,svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
async function prepare(m) {
  const points=m.faces.flatMap(f=>f.points),project=p=>G.project(p,K.camera).map(v=>v*K.PX);
  const screen=points.map(project);
  if(m.orb) {const c=project(m.orb.centre),r=m.orb.radius*K.PX;screen.push([c[0]-r,c[1]-r],[c[0]+r,c[1]+r]);}
  const lo=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-2),hi=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+2),size=hi.map((v,i)=>v-lo[i]);
  const p=v=>project(v).map((x,i)=>fmt(x-lo[i]));
  const visible=m.visibleEdges||G.visibleEdges(m,K.camera);
  const lines=mono=>visible.map(e=>{const a=p(e.a),b=p(e.b);return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="${mono?'#f34cff':colors[e.kind]}" stroke-width="${e.kind==='joint'||e.kind==='floor'?1:1.4}" stroke-linecap="round"/>`;}).join('');
  // All solid faces use one opaque fill, so their union occludes lower sprites.
  // Actual arch holes stay open: never replace the union with a convex hull.
  const fill=m.faces.map(f=>`<polygon points="${f.points.map(v=>p(v).join(',')).join(' ')}" fill="#0b1019"/>`).join('');
  function drawing(mono) {
    let body=(mono?'':fill)+lines(mono);
    if(m.orb) {
      const c=p(m.orb.centre),r=m.orb.radius*K.PX;
      const circle=`<circle cx="${c[0]}" cy="${c[1]}" r="${r}"`;
      // Remove hidden support edges also in the transparent comparison guide.
      body=`<defs><mask id="orb"><rect width="${size[0]}" height="${size[1]}" fill="white"/>${circle} fill="black"/></mask></defs><g mask="url(#orb)">${body}</g>`;
      body+=`${circle} fill="${mono?'none':'#0b1019'}" stroke="${mono?'#f34cff':'#ce84ff'}" stroke-width="1.8"/>`;
      const spiral=Array.from({length:160},(_,i)=>{const t=i/159,a=t*Math.PI*5,q=r*(.08+.79*t);return [c[0]+q*Math.cos(a),c[1]+q*Math.sin(a)].map(fmt).join(',');}).join(' ');
      body+=`<polyline points="${spiral}" fill="none" stroke="${mono?'#f34cff':'#ce84ff'}" stroke-width="1.4"/>`;
    }
    return svg(...size,body);
  }
  const source=drawing(false),guide=drawing(true),png=await sharp(Buffer.from(source)).png().toBuffer();
  write(`${OUT}/sprites/${m.id}.png`,png);write(`${OUT}/guides/${m.id}.svg`,guide);
  write(`${OUT}/guides/${m.id}.png`,await sharp(Buffer.from(guide)).png().toBuffer());
  const bounds={min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};
  if(m.orb)bounds.max[2]=m.orb.centre[2]+m.orb.radius;
  return {id:m.id,png,frame:[...lo,...size],bounds,companions:m.companions,visibleEdges:visible};
}
async function main() {
  const models=K.allModels(),items=[];
  for(const m of models) {items.push(await prepare(m));console.log('Prepared '+m.id);}
  const atlas=await B.pack(items,256,ASSETS,false);
  for(const item of items) {
    atlas.regions[item.id].bounds=item.bounds;
    if(item.companions)atlas.regions[item.id].companions=item.companions;
  }
  const manifest={id:'isometric-wireframe-v1',appearance:'structural wireframe, painted migration pending',
    density:256,worldPixelsPerCell:256,sourceDiamond:[256,128],displayDiamond:[192,96],cameraZoom:.75,
    logicalCell:[1,1],camera:K.camera,wallThickness:K.T,wallHeight:K.H,pillarWidth:K.PILLAR,
    floorRows:3,spriteCount:items.length,optionalDetails:[],lighting:false,atlas};
  json(`${ASSETS}/catalog.json`,manifest);
  const resources=items.map((m,i)=>`[sub_resource type="AtlasTexture" id="Sprite_${i}"]\natlas = ExtResource("2")\nregion = Rect2(${atlas.regions[m.id].region.join(', ')})\nfilter_clip = true\n`).join('\n');
  write(`${ASSETS}/catalog.tres`,`[gd_resource type="Resource" load_steps=${items.length+3} format=3]\n\n[ext_resource type="Script" path="res://scripts/mobile_kit_definition.gd" id="1"]\n[ext_resource type="Texture2D" path="res://${ASSETS}/atlas-256.png" id="2"]\n\n${resources}\n[resource]\nscript = ExtResource("1")\nprojection_x = Vector3(${K.camera.x.join(', ')})\nprojection_y = Vector3(${K.camera.y.join(', ')})\nview_direction = Vector3(${K.camera.eye.join(', ')})\nentries = ${JSON.stringify(atlas.regions)}\ntextures = {${items.map((p,i)=>JSON.stringify(p.id)+`: SubResource("Sprite_${i}")`).join(',\n')}}\n`);
  json(`${OUT}/geometry.json`,{camera:K.camera,pixelsPerCell:256,models:models.map((m,i)=>({...m,visibleEdges:items[i].visibleEdges,frame:items[i].frame,bounds:items[i].bounds}))});
  json(`${OUT}/recipe.json`,{...manifest,generator:'tools/export_isometric_kit.cjs',
    sourceHashes:Object.fromEntries([...K.sourceFiles,'tools/isometric_kit_geometry.cjs','tools/wireframe_geometry.cjs','tools/export_isometric_kit.cjs','tools/prepare_mobile_reference.cjs'].map(p=>[p,K.hash(p)])),
    notes:['Prepared complete alpha sprites: Godot places/sorts them only.','Source guides include visible edges only; filled sprites occlude lower objects.','Heart is schematic, torches are rigid mounts without flame/light; original approved artwork is retained for the painted phase.','Bare pillar has no painted carved cap. No new artistic approval is inferred.']});
  console.log(JSON.stringify({sprites:items.length,atlas:[atlas.width,atlas.height],pngBytes:atlas.sourceBytes,rgbaBytes:atlas.uncompressedRGBABytes}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
