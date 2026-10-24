// Disposable visual prototype. Does not promote materials or rewrite production kits.
// Uses the approved offline mask/material workflow and the existing projection.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const R = require('./painted_material_renderer.cjs');
const {writeGeneratedFile} = require('./write_generated_file.cjs');
const {ROOT, read, hash, render, svg} = R;
const OUT = 'docs/reference/mobile-optimization';
const ASSETS = 'assets/dungeon/mobile-reference';
const PX = 256, T = 1 / 6, H = 1.88 / 6, PILLAR = .24;
const write = (file, bytes) => writeGeneratedFile(path.join(ROOT, file), bytes);
const json = (file, value) => write(file, JSON.stringify(value, null, 2) + '\n');
const fmt = n => Number(n.toFixed(6));
const project = ([x, y, z]) => [(x - .18 * z) * PX, (y - .9 * z) * PX];
const winding = points => points.reduce((s, p, i) => s + p[0] * points[(i+1)%points.length][1] - p[1] * points[(i+1)%points.length][0], 0);
const poly = points => `<polygon points="${points.map(p => p.map(fmt).join(',')).join(' ')}" fill="#ffffff"/>`;
const materials = JSON.parse(read('assets/dungeon/shared-materials/catalog.json'));
// Local overrides only. Quiet common paint, with less surface contrast.
for (const kind of ['top', 'north', 'west']) {
  materials.renderProfile[kind].opacity = kind === 'top' ? .58 : .52;
  materials.renderProfile[kind].blur = 1.2;
}
materials.renderProfile.floor.opacity = .28;
materials.renderProfile.floor.blur = 2;
delete materials.wallVariation;

function face(points3d, kind, seed, materialId = 'walls-planes') {
  let points = points3d.map(project);
  if (winding(points) < 0) points.reverse();
  return {points, kind, part: kind === 'floor' ? 'floor' : 'wall',
    p: points3d.reduce((s,p) => s.map((v,i) => v+p[i]/points3d.length), [0,0,0]),
    normal: kind === 'top' || kind === 'floor' ? [0,0,1] : kind === 'north' ? [0,1,0] : [1,0,0],
    materialId, bevelSeed: seed};
}

function linesFor(faces, width = 1.6) {
  const seen = new Set(), lines = [];
  for (const f of faces) f.points.forEach((a,i) => {
    const b = f.points[(i+1)%f.points.length];
    const key = [a,b].map(p => p.map(fmt).join(',')).sort().join('|');
    if (seen.has(key)) return;
    seen.add(key); lines.push({a,b,width});
  });
  return lines;
}
const ink = lines => lines.map(l => `<line x1="${fmt(l.a[0])}" y1="${fmt(l.a[1])}" x2="${fmt(l.b[0])}" y2="${fmt(l.b[1])}" stroke="#ff00ff" stroke-width="${l.width}"/>`).join('');

// Each wall has just two courses. The top is part of the upper stone.
// Trimming at a pillar is a physical termination, not a texture splice.
function wall(horizontal, trimStart, trimEnd) {
  const lo = trimStart ? PILLAR/2 : 0, hi = trimEnd ? 1-PILLAR/2 : 1;
  const upper = [lo, 1/3, 2/3, hi], lower = [lo, 1/6, 1/2, 5/6, hi];
  const at = (s,c,z) => horizontal ? [s,c,z] : [c,s,z];
  const faces = [];
  for (const [j, cuts] of [lower,upper].entries()) {
    const z0 = j*H/2, z1 = (j+1)*H/2;
    for (let i=0;i<cuts.length-1;i++) {
      const a=cuts[i], b=cuts[i+1];
      faces.push(face([at(a,T/2,z0),at(b,T/2,z0),at(b,T/2,z1),at(a,T/2,z1)], horizontal?'north':'west', 10+j*5+i));
    }
  }
  // The visible terminal face is hidden by a touching pillar/next wall in assembly.
  for (let j=0;j<2;j++) faces.push(face([at(hi,-T/2,j*H/2),at(hi,T/2,j*H/2),at(hi,T/2,(j+1)*H/2),at(hi,-T/2,(j+1)*H/2)],horizontal?'west':'north',30+j));
  for (let i=0;i<upper.length-1;i++) faces.push(face([at(upper[i],-T/2,H),at(upper[i+1],-T/2,H),at(upper[i+1],T/2,H),at(upper[i],T/2,H)],'top',15+i));
  const hull = [
    [at(lo,-T/2,H),at(hi,-T/2,H),at(hi,T/2,H),at(lo,T/2,H)],
    [at(lo,T/2,0),at(hi,T/2,0),at(hi,T/2,H),at(lo,T/2,H)],
    [at(hi,-T/2,0),at(hi,T/2,0),at(hi,T/2,H),at(hi,-T/2,H)]
  ].map(p => p.map(project));
  return {faces, hull};
}

function pillar() {
  const a=-PILLAR/2,b=PILLAR/2,h=H+.035, faces=[];
  for(let j=0;j<2;j++) {
    const z=j*h/2,Z=(j+1)*h/2;
    faces.push(face([[a,b,z],[b,b,z],[b,b,Z],[a,b,Z]],'north',70+j));
    faces.push(face([[b,a,z],[b,b,z],[b,b,Z],[b,a,Z]],'west',70+j));
  }
  faces.push(face([[a,a,h],[b,a,h],[b,b,h],[a,b,h]],'top',72));
  return {faces,hull:faces.map(f=>f.points)};
}

function floor() {
  // Nine complete stones per periodic cell; whole crossing stones are painted
  // before cropping. Left/right samples therefore share paint, finish and UVs.
  const widths=[[.18,.35,.33,.14],[.30,.34,.32,.04],[.07,.33,.35,.25]];
  const faces=[];
  for(let r=0;r<3;r++) {
    const y=r/3,Y=(r+1)/3,w=widths[r];
    const add=(x,X,seed)=>faces.push(face([[x,y,0],[X,y,0],[X,Y,0],[x,Y,0]],'floor',seed,'floors-calm'));
    for(let cell=0;cell<2;cell++) add(cell-w[3],cell+w[0],100+r*10);
    add(w[0],w[0]+w[1],101+r*10);
    add(w[0]+w[1],1-w[3],102+r*10);
  }
  return {faces,hull:[[[0,0],[PX,0],[PX,PX],[0,PX]]],frame:[0,0,PX,PX],widths};
}

async function paint(id, geometry, output = OUT) {
  const all=geometry.hull.flat();
  const x=Math.floor(Math.min(...all.map(p=>p[0])))-3,y=Math.floor(Math.min(...all.map(p=>p[1])))-3;
  const X=Math.ceil(Math.max(...all.map(p=>p[0])))+3,Y=Math.ceil(Math.max(...all.map(p=>p[1])))+3;
  const frame=geometry.frame||[x,y,Math.ceil((X-x)/2)*2,Math.ceil((Y-y)/2)*2],lines=linesFor(geometry.faces,id==='floor'?1.4:1.6);
  const model={id:'mobile-reference/'+id,size:frame.slice(2),anchor:[0,0],outputFrame:frame,surfaces:[],floor:false,
    clipPaint:true,drawAccent:false,stableStones:true,floorFinish:materials.floorFinish,
    silhouette:geometry.hull.map(poly).join(''),renderData:{faces:geometry.faces,lines,visibility:null}};
  const guide=svg(model.size,ink(lines)),result=await render(model,guide,materials);
  write(`${output}/guides/${id}.svg`,`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]}" height="${frame[3]}" viewBox="${frame.join(' ')}">${ink(lines)}</svg>`);
  write(`${output}/sprites/${id}.png`,await sharp(result.png).resize(frame[2],frame[3]).png().toBuffer());
  write(`${output}/overlays/${id}.png`,await sharp(result.overlay).resize(frame[2],frame[3]).png().toBuffer());
  return {id,png:result.png,frame,report:result.report};
}

async function pack(items,density,assets = ASSETS, writeResources = true) {
  const factor=density/PX,gutter=4,width=density===256?1024:512;
  const orders=[
    [...items].sort((a,b)=>b.frame[3]-a.frame[3]),
    [...items].sort((a,b)=>b.frame[2]*b.frame[3]-a.frame[2]*a.frame[3]),
    [...items].sort((a,b)=>Math.max(b.frame[2],b.frame[3])-Math.max(a.frame[2],a.frame[3])),
    [...items].sort((a,b)=>b.frame[2]-a.frame[2]),
  ];
  // Reuse holes beneath shorter sprites instead of growing a shelf atlas for
  // one small cap. Free rectangles include the unchanged 4px filter guards.
  function arrange(height, sorted) {
    let free=[{x:0,y:0,w:width,h:height}];const placed=[];
    for(const item of sorted) {
      const w=Math.ceil(item.frame[2]*factor),h=Math.ceil(item.frame[3]*factor),W=w+2*gutter,H=h+2*gutter;
      const choices=free.filter(r=>r.w>=W&&r.h>=H).sort((a,b)=>
        Math.min(a.w-W,a.h-H)-Math.min(b.w-W,b.h-H)||a.y-b.y||a.x-b.x);
      if(!choices.length)return null;
      const used={x:choices[0].x,y:choices[0].y,w:W,h:H},next=[];
      for(const r of free) {
        if(used.x>=r.x+r.w||used.x+W<=r.x||used.y>=r.y+r.h||used.y+H<=r.y){next.push(r);continue;}
        if(used.x>r.x)next.push({x:r.x,y:r.y,w:used.x-r.x,h:r.h});
        if(used.x+W<r.x+r.w)next.push({x:used.x+W,y:r.y,w:r.x+r.w-used.x-W,h:r.h});
        if(used.y>r.y)next.push({x:r.x,y:r.y,w:r.w,h:used.y-r.y});
        if(used.y+H<r.y+r.h)next.push({x:r.x,y:used.y+H,w:r.w,h:r.y+r.h-used.y-H});
      }
      free=next.filter((r,i)=>!next.some((q,j)=>j!==i&&r.x>=q.x&&r.y>=q.y&&r.x+r.w<=q.x+q.w&&r.y+r.h<=q.y+q.h&&(r.x!==q.x||r.y!==q.y||r.w!==q.w||r.h!==q.h||j<i)));
      placed.push({...item,x:used.x+gutter,y:used.y+gutter,w,h});
    }
    return placed;
  }
  const fit=height=>orders.map(order=>arrange(height,order)).find(Boolean);
  let height=width/2,placements=fit(height);
  while(!placements){height*=2;placements=fit(height);}
  const layers=[],regions={};
  for(const p of placements) {
    const resized=p.densityPng?.[density]||await sharp(p.png).resize(p.w,p.h,{kernel:'lanczos3'}).png().toBuffer();
    // Extruded pixels protect atlas regions; filtering remains clipped in Godot.
    const padded=await sharp(resized).extend({top:gutter,bottom:gutter,left:gutter,right:gutter,extendWith:'copy'}).png().toBuffer();
    layers.push({input:padded,left:p.x-gutter,top:p.y-gutter});
    regions[p.id]={region:[p.x,p.y,p.w,p.h],offset:p.frame.slice(0,2),size:p.frame.slice(2)};
    if(writeResources)write(`${assets}/${density}/${p.id}.tres`,`[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://${assets}/atlas-${density}.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(${[p.x,p.y,p.w,p.h].join(', ')})\nfilter_clip = true\n`);
  }
  const png=await sharp({create:{width,height,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toBuffer();
  write(`${assets}/atlas-${density}.png`,png);
  return {density,width,height,sourceBytes:png.length,uncompressedRGBABytes:width*height*4,regions};
}

async function main() {
  const items=[await paint('floor',floor())];
  for(const [direction,horizontal] of [['h',true],['v',false]]) for(let bits=0;bits<4;bits++) {
    items.push(await paint(`wall-${direction}-${bits}`,wall(horizontal,bits&1,bits&2)));
    console.log(`Prepared wall-${direction}-${bits}`);
  }
  const pillarGeometry=pillar(),pillarItem=await paint('pillar',pillarGeometry);
  items.push(pillarItem);
  items.push(...await require('./mobile_painted_decorations.cjs').paintedDecorations());
  items.push(await require('./mobile_pillar_cap.cjs').paintedPillarCap(pillarItem,pillarGeometry.faces.find(f=>f.kind==='top')));
  const atlases=[];
  for(const density of [128,256]) atlases.push(await pack(items,density));
  const manifest={status:'visual_prototype_not_promoted',projection:[-.18,-.9],logicalCell:1,worldPixelsPerCell:PX,
    referenceViewport:[1280,720],displayPixelsPerCell:192,cameraZoom:.75,wallThickness:T,wallHeight:H,pillarWidth:PILLAR,
    layout:{room:[3,2],corridorWidth:1,eastLength:3,southLength:4},
    floor:{rows:3,fullWidthRange:[.32,.35],previousRows:2,previousWidthRange:[.475,.525]},
    wallAppearanceCount:1,geometryCount:10,decorationCount:4,defaultPillarDetail:'pillar-top-carved',historicalDecorations:['decor-a','decor-b','decor-c'],atlases};
  json(`${ASSETS}/catalog.json`,manifest);
  json(`${OUT}/recipe.json`,{...manifest,generator:'tools/prepare_mobile_reference.cjs',materialOverrides:materials.renderProfile,
    sourceHashes:Object.fromEntries(['assets/dungeon/shared-materials/catalog.json','assets/dungeon/shared-materials/walls-planes.png','assets/dungeon/shared-materials/floors-calm.png','assets/dungeon/shared-materials/stone-finish.json','tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','tools/prepare_mobile_reference.cjs','tools/mobile_painted_decorations.cjs','docs/reference/mobile-decoration-review/generation.json','tools/mobile_pillar_cap.cjs','docs/reference/pillar-cap-review/generation.json','docs/reference/pillar-cap-review/source/carved-top.png'].map(p=>[p,hash(read(p))])),
    exports:items.filter(i=>i.report).map(i=>i.report),decorationSources:items.filter(i=>i.decorationSource).map(i=>i.decorationSource),capSources:items.filter(i=>i.capSource).map(i=>i.capSource),limits:['New pillar/wall geometry is a proposal, not approved production geometry.','No gameplay, device-performance, arbitrary-layout or door/stair compatibility claim.','Resolution comparison changes raster density only; both use simplified materials.']});
  console.log(JSON.stringify({sprites:items.length,atlases:atlases.map(({density,width,height,sourceBytes})=>({density,width,height,sourceBytes}))}));
}
if(require.main===module) main().catch(e=>{console.error(e.stack);process.exitCode=1;});

module.exports={paint,pack,materials,wall,pillar,floor,face,project,linesFor,PX,T,H,PILLAR};
