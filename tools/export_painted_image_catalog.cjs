// OFFLINE review sprites. Preserve the standalone guides; never edit Godot scenes.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs'),{geometry}=require('./export_wireframe_cell_kit.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {ROOT,SCALE,read,hash,polygon,render}=R;
const GUIDE='docs/reference/wireframe-overlays',OUT='assets/dungeon/painted-cells',REVIEW='docs/reference/painted-kit-review';
const catalog=JSON.parse(read(GUIDE+'/catalog.json')),T=1/6,H=1.88/6;
const stairs=JSON.parse(read('docs/reference/entrance-stairs-open-south-wireframe.json'));
const door=JSON.parse(read('docs/reference/door-arch-cell-west-east-wireframe.json'));
const transforms={north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],south:p=>p,west:([x,y,z])=>[1-y,x,z]};
const inverses={north:transforms.north,east:transforms.west,south:transforms.south,west:transforms.east};
function write(p,b){writeGeneratedFile(path.join(ROOT,p),b);}
function json(p,obj){write(p,JSON.stringify(obj,null,2)+'\n');}
function boxFaces(lo,hi,part,index=0){
  const [x,y,z]=lo,[X,Y,Z]=hi,a=[x,y,z],b=[X,y,z],c=[X,Y,z],d=[x,Y,z],e=[x,y,Z],f=[X,y,Z],g=[X,Y,Z],h=[x,Y,Z];
  return [[a,b,c,d],[e,f,g,h],[a,b,f,e],[b,c,g,f],[c,d,h,g],[d,a,e,h]].map(points=>({points,part,index}));
}
function wallPart(lo,hi){return hi[1]-lo[1]<hi[0]-lo[0]?(lo[1]<.5?'north-wall':'south-wall'):(lo[0]<.5?'west-wall':'east-wall');}
function silhouette(model){
  // One nonzero path, with every projected polygon wound in the same direction,
  // is a union without antialias cracks along internal source-box interfaces.
  const polys=model.surfaces.map(s=>s.points.map(([x,y,z])=>[(x-.18*z)*256+model.anchor[0],(y-.9*z)*256+model.anchor[1]]));
  if(model.floor)polys.push([[0,0],[256,0],[256,256],[0,256]].map(p=>p.map((v,i)=>v+model.anchor[i])));
  const d=polys.map(p=>{const a=p.reduce((s,q,i)=>s+q[0]*p[(i+1)%p.length][1]-q[1]*p[(i+1)%p.length][0],0);if(a<0)p.reverse();return 'M'+p.map(q=>q.join(',')).join('L')+'Z';}).join('');
  return `<path d="${d}" fill="#ffffff"/>`;
}
function makeModel(id,entry){
  const m={id,size:entry.imageSize,anchor:entry.imageAnchor,surfaces:[],floor:id!=='pillar'};
  if(id.startsWith('cells/')||id==='pillar'){
    const [w,p,e]=id==='pillar'?[0,1,0]:entry.variant.match(/\d+/g).map(Number),corners=[[0,0],[5,0],[5,5],[0,5]];
    for(let y=0;y<6;y++)for(let x=0;x<6;x++){
      const part=w&1&&y===0?'north-wall':w&4&&y===5?'south-wall':w&8&&x===0?'west-wall':w&2&&x===5?'east-wall':corners.some(([cx,cy],i)=>p&(1<<i)&&cx===x&&cy===y)?'pillar':null;
      if(part)m.surfaces.push(...boxFaces([x*T,y*T,0],[(x+1)*T,(y+1)*T,H],part));
    }
    const g=geometry(w,p,e,{standalone:true}).svg;
    m.silhouette=(m.floor?`<rect x="24" y="88" width="256" height="256" fill="#ffffff"/>`:'')+[...g.matchAll(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)].map(x=>x[0]).join('');
  }else if(id.startsWith('entrances/')){
    const tr=transforms[entry.direction];
    stairs.occludingVolumes.forEach(([a,b],i)=>{const A=tr(a),B=tr(b),lo=A.map((v,j)=>Math.min(v,B[j])),hi=A.map((v,j)=>Math.max(v,B[j]));m.surfaces.push(...boxFaces(lo,hi,hi[2]<H-1e-5?'step':wallPart(lo,hi),i));});
  }else if(id.startsWith('doors/')){
    const tr=transforms[entry.direction];m.forward=tr;m.inverse=inverses[entry.direction];m.door=door.door;
    door.occludingVolumes.forEach((v,index)=>{
      const a=v.profileXZ.map(([x,z])=>tr([x,v.yMin,z])),b=v.profileXZ.map(([x,z])=>tr([x,v.yMax,z]));
      let part=v.part;
      if(part.includes('wall')){const all=[...a,...b],lo=[0,1,2].map(i=>Math.min(...all.map(p=>p[i]))),hi=[0,1,2].map(i=>Math.max(...all.map(p=>p[i])));part=wallPart(lo,hi);}
      m.surfaces.push({points:a,part,index},{points:b,part,index},...a.map((p,i)=>({points:[p,a[(i+1)%a.length],b[(i+1)%b.length],b[i]],part,index})));
    });
  }
  if(!m.silhouette)m.silhouette=silhouette(m);
  return m;
}
async function sheet(ids,file,title,{overlay=false,columns=4}={}){
  const width=columns*320+32,height=Math.ceil(ids.length/columns)*420+76,layers=[];
  let labels='';
  for(const [i,id] of ids.entries()){
    const x=16+(i%columns)*320,y=68+Math.floor(i/columns)*420;
    const src=overlay?`${REVIEW}/${id}-overlay.png`:`${OUT}/${id}.png`;
    const thumb=await sharp(read(src)).resize({width:304,height:392,fit:'inside'}).toBuffer();
    const meta=await sharp(thumb).metadata();layers.push({input:thumb,left:x+Math.round((304-meta.width)/2),top:y+Math.round((392-meta.height)/2)});
    labels+=`<text x="${x+8}" y="${y+407}" font-size="15" fill="#b7c3d8">${id}</text>`;
  }
  const bg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="100%" height="100%" fill="#0a101c"/><g font-family="Arial,sans-serif"><text x="24" y="34" font-size="24" fill="#e5edff">${title}</text>${labels}</g></svg>`;
  await sharp(Buffer.from(bg)).composite(layers).png().toFile(path.join(ROOT,REVIEW,file));
}
async function main(){
  const materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json')),unique=new Map(),aliases={};
  for(const [id,entry] of Object.entries(catalog.entries)){const guide=read(GUIDE+'/'+entry.svg).toString(),key=hash(guide);if(!unique.has(key))unique.set(key,{id,entry,guide});aliases[id]=unique.get(key).id;}
  const only=process.argv.find(a=>a.startsWith('--only='))?.slice(7).split(','),reports=[],entries={};
  for(const {id,entry,guide} of unique.values()){
    if(only&&!only.includes(id))continue;
    try{
      const result=await render(makeModel(id,entry),guide,materials);
      write(`${OUT}/${id}.png`,result.png);write(`${REVIEW}/${id}-overlay.png`,result.overlay);
      write(`${REVIEW}/${id}-regions.svg`,result.recipe);
      json(`${REVIEW}/${id}-report.json`,result.report);reports.push(result.report);
      entries[id]={file:id+'.png',imageSize:result.report.canvas,imageAnchor:result.report.anchor,guide:GUIDE+'/'+entry.svg,guideSha256:hash(guide),sha256:hash(result.png),materials:result.report.materials,overlay:REVIEW+'/'+id+'-overlay.png',report:REVIEW+'/'+id+'-report.json'};
      console.log(`${id}: ${result.report.segmentCount} segments, alpha difference ${result.report.alphaPixelsDifferentFromModel}`);
    }catch(err){
      if(err.diagnostic){const {drawing,silhouette,model,faces,holes,excess}=err.diagnostic,prefix='artifacts/painted-export/'+id;
        write(prefix+'-drawing.svg',drawing);write(prefix+'-model.svg',silhouette);
        await sharp(Buffer.from(drawing)).png().toFile(path.join(ROOT,prefix+'-drawing.png'));
        await sharp(Buffer.from(silhouette)).png().toFile(path.join(ROOT,prefix+'-model.png'));
        json(prefix+'-diagnostic.json',{id,faces:faces.map(f=>({points:f.points,part:f.part,kind:f.kind})),holes,excess});
      }
      throw err;
    }
  }
  if(only)return;
  const hashes={};for(const p of ['tools/painted_material_renderer.cjs','tools/stone_edge_finish.cjs','tools/write_generated_file.cjs','assets/dungeon/shared-materials/stone-finish.json','tools/export_painted_image_catalog.cjs','tools/export_wireframe_cell_kit.cjs','docs/reference/two-course-square-room.json','docs/reference/floor-periodic-cell.json','docs/reference/entrance-stairs-open-south-wireframe.json','docs/reference/door-arch-cell-west-east-wireframe.json',GUIDE+'/catalog.json','assets/dungeon/shared-materials/catalog.json'])hashes[p]=hash(read(p));
  json(OUT+'/catalog.json',{id:'painted-isolated-shared-materials-v1',status:'awaiting_user_visual_review',purpose:'Isolated sprites with complete visible ends. Do not substitute into connected Godot scenes.',generator:'tools/export_painted_image_catalog.cjs',cell:[1,1],pixelsPerCell:256*SCALE,projection:catalog.projection,wallHeight:H,courseJoints:[.94/6],sourceHashes:hashes,uniqueImageCount:reports.length,guideEntryCount:Object.keys(aliases).length,entries,aliases});
  json(REVIEW+'/validation.json',{imageCount:reports.length,guideEntryCount:Object.keys(aliases).length,allConstructionJointLayersMatch:reports.every(r=>r.constructionJointLayerMatchesGuide),alphaPixelsDifferentFromModel:reports.reduce((s,r)=>s+r.alphaPixelsDifferentFromModel,0),unpaintedInteriorPixels:reports.reduce((s,r)=>s+r.unpaintedInteriorPixels,0),extraInteriorPixels:reports.reduce((s,r)=>s+r.extraInteriorPixels,0),sourceHashes:hashes,images:reports.map(({faces,...r})=>r),scope:'Source line coordinates, stroke widths, framing, model alpha and coverage. Not a claim of user artistic approval or assembled-scene validation.'});
  const cells=Object.keys(entries).filter(id=>id.startsWith('cells/'));
  for(let page=0;page<Math.ceil(cells.length/16);page++)await sheet(cells.slice(page*16,(page+1)*16),`cells-${page+1}.png`,`Cases · planche ${page+1}`);
  const special=['floor','pillar',...['entrances','doors'].flatMap(f=>['north','east','south','west'].map(d=>f+'/'+d))];
  await sheet(special,'specials.png','Sol, pilier, escaliers et portes');
  await sheet(special,'specials-overlay.png','Contrôle géométrique · lignes magenta',{overlay:true});
  const selection=['cells/w09_p00_e00','cells/w01_p00_e00','cells/w03_p00_e00','cells/w10_p00_e00','cells/w05_p00_e00','pillar','entrances/south','doors/south'];
  await sheet(selection,'overview.png','Matières communes · variantes du donjon');
  await sheet(selection,'overview-overlay.png','Même sélection · contrôle des contours et joints',{overlay:true});
  console.log(JSON.stringify({uniqueImages:reports.length,guideAliases:Object.keys(aliases).length,review:REVIEW},null,2));
}
module.exports={makeModel};
if(require.main===module)main().catch(e=>{console.error(e.message);process.exitCode=1;});
