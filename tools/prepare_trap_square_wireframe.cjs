// Isolated revision of the trap paving study: larger square, rectangular stones.
// No game export, source painting, texture, scene or runtime edit.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const Floor=require('./isometric_floor_variants.cjs');
const OUT=path.join(P.ROOT,'docs/reference/trap-review/v11-larger-square');
const OPEN=[.16,.84,.16,.84],OLD=[.22,.78,.22,.78];
const round=n=>+n.toFixed(8),key=r=>r.map(round).join(',');
const points=([x,X,y,Y])=>[[x,y],[X,y],[X,Y],[x,Y]];
const area=r=>Math.max(0,r[1]-r[0])*Math.max(0,r[3]-r[2]);
const intersection=(a,b)=>[Math.max(a[0],b[0]),Math.min(a[1],b[1]),Math.max(a[2],b[2]),Math.min(a[3],b[3])];
const replacements=[
 {before:[-.08,.28,.50,.84],after:[-.08,.16,.50,.84]},
 {before:[.92,1.28,.50,.84],after:[.84,1.28,.50,.84]},
];

function build(){
 const source=Floor.geometry(1).stones,all=new Map();
 for(let y=-1;y<=1;y++)for(let x=-1;x<=1;x++)for(const s of source){
  const r=s.rect.map((v,i)=>round(v+(i<2?x:y)));
  all.set(key(r),{rect:r,seed:s.seed});
 }
 const removed=source.filter(s=>s.rect[0]>=0&&s.rect[1]<=1&&s.rect[2]>=0&&s.rect[3]<=1).map(s=>s.rect);
 for(const r of removed)all.delete(key(r));
 for(const r of replacements){
  const stone=all.get(key(r.before));if(!stone)throw Error('Missing original slab');
  all.delete(key(r.before));all.set(key(r.after),{...stone,rect:r.after,originalRect:r.before});
 }
 return {stones:[...all.values()],removed};
}

function validate(model){
 let sum=0,edgeCount=0;
 const patch=[-1,2,-1,2];
 for(let i=0;i<model.stones.length;i++){
  const a=model.stones[i].rect;
  if(area(intersection(a,OPEN))>1e-9)throw Error('Stone in opening');
  sum+=area(intersection(a,patch));
  for(let j=0;j<i;j++)if(area(intersection(intersection(a,model.stones[j].rect),patch))>1e-9)throw Error('Overlapping stones');
  const ps=points(a);
  for(let j=0;j<4;j++){
   const p=ps[j],q=ps[(j+1)%4];
   if(p[0]!==q[0]&&p[1]!==q[1])throw Error('Skewed ground joint');
   const u=P.project([...p,0]),v=P.project([...q,0]),dx=v[0]-u[0],dy=v[1]-u[1];
   if(Math.abs(Math.abs(dx)-2*Math.abs(dy))>1e-8)throw Error('Joint outside the two isometric directions');
   edgeCount++;
  }
 }
 if(Math.abs(sum-(9-area(OPEN)))>1e-8)throw Error('Missing paving');
 for(const r of replacements){
  // Difference between the two rectangles must be entirely inside this cell.
  const change=area(r.before)+area(r.after)-2*area(intersection(r.before,r.after));
  const cell=[0,1,0,1];
  const insideChange=area(intersection(r.before,cell))+area(intersection(r.after,cell))-2*area(intersection(intersection(r.before,r.after),cell));
  if(Math.abs(change-insideChange)>1e-9)throw Error('Neighbour stone changed outside trap cell');
 }
 return {opening:OPEN,oldSide:.56,newSide:.68,sideIncreasePercent:round((.68/.56-1)*100),
  removedWholeInnerSlabs:model.removed.length,resizedRectangularSlabs:replacements.length,
  squareCentred:round((OPEN[0]+OPEN[1])/2)===.5&&round((OPEN[2]+OPEN[3])/2)===.5,
  rectangularStones:model.stones.length,checkedProjectedEdges:edgeCount,
  overlapArea:0,uncoveredPavingArea:0,pavingAreaInCell:round(1-area(OPEN)),
  neighbourGeometryUnchanged:true,planeZ:0,productionIntegrated:false};
}

function draw(model,map,{crop=[-1,2,-1,2],id='view',oldGuide=false}={}){
 const pp=ps=>ps.map(p=>map(p).map(round).join(',')).join(' ');
 let svg=`<defs><clipPath id="${id}"><polygon points="${pp(points(crop))}"/></clipPath></defs><g clip-path="url(#${id})" stroke-linejoin="miter">`;
 for(const s of model.stones)svg+=`<polygon points="${pp(points(s.rect))}" fill="#243245" stroke="#8292a8" stroke-width="1.3"/>`;
 svg+=`<polygon points="${pp(points(OPEN))}" fill="#111620" stroke="#c6a0e8" stroke-width="2.5"/>`;
 if(oldGuide)svg+=`<polygon points="${pp(points(OLD))}" fill="none" stroke="#6c7788" stroke-width="1.2" stroke-dasharray="5 5"/>`;
 return svg+'</g>';
}

async function main(){
 const watched=['assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/catalog.tres',
  'assets/dungeon/isometric-kit/traps/atlas-256.png','tools/isometric_trap_receiver.cjs',
  'tools/isometric_trap_registration.cjs','tools/isometric_painted_traps.cjs',
  'docs/reference/trap-review/v10-paving-wireframe/geometry.json',
  'docs/reference/trap-review/v10-paving-wireframe/wireframe-board.png'];
 const before=Object.fromEntries(watched.map(f=>[f,P.hash(f)]));
 const model=build(),checks=validate(model);
 fs.mkdirSync(OUT,{recursive:true});
 const iso=p=>{const q=P.project([...p,0]);return[465+q[0]*1.08,290+q[1]*1.08];};
 const top=p=>[1000+(p[0]+.2)*220,205+(p[1]+.2)*220];
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1380" height="790" font-family="Segoe UI,Arial,sans-serif"><rect width="1380" height="790" fill="#0c111b"/><g fill="#e6eaf3"><text x="36" y="48" font-size="28">Un carré plus grand, des joints droits</text><text x="36" y="81" font-size="17" fill="#a9b6c9">Wireframe proposé · même grille isométrique · toutes les pierres restent rectangulaires</text><text x="36" y="142" font-size="21">Avec le dallage voisin</text><text x="975" y="142" font-size="21">Vue de dessus</text><text x="975" y="172" font-size="15" fill="#a9b6c9">Pointillés : ancienne taille du carré.</text></g>`;
 svg+=draw(model,iso,{id:'iso'})+draw(model,top,{id:'top',crop:[-.2,1.2,-.2,1.2],oldGuide:true});
 const c=iso([.5,.5]);
 svg+=`<g fill="#dbc5ef" text-anchor="middle" font-size="15"><text x="${c[0]}" y="${c[1]-3}">Logement</text><text x="${c[0]}" y="${c[1]+19}">du piège</text></g>`;
 svg+='<g fill="#a9b6c9" font-size="16"><text x="975" y="555">Carré centré : 68 % de la case</text><text x="975" y="582">contre 56 % auparavant (+21 % de côté).</text></g>';
 svg+='<line x1="36" y1="635" x2="1344" y2="635" stroke="#2c394d"/><g fill="#e6eaf3" font-size="20"><text x="36" y="679">L’ouverture rejoint les rangées de dalles</text></g><g fill="#a9b6c9" font-size="17"><text x="36" y="711">Les deux pierres latérales du bas sont ajustées en largeur ; leurs côtés restent parallèles aux axes du sol.</text><text x="36" y="754" font-size="15" fill="#8393ad">Proposition de géométrie uniquement. Les textures et le jeu restent inchangés à cette étape.</text></g></svg>';
 fs.writeFileSync(path.join(OUT,'wireframe-board.svg'),svg);
 fs.writeFileSync(path.join(OUT,'wireframe-board.png'),await sharp(Buffer.from(svg)).png().toBuffer());
 const zoom=p=>{const q=P.project([...p,0]);return[600+q[0]*2.7,215+q[1]*2.7];};
 const detail=`<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="780"><rect width="1200" height="780" fill="#0c111b"/>${draw(model,zoom,{id:'detail',crop:[-.3,1.3,-.3,1.3]})}</svg>`;
 fs.writeFileSync(path.join(OUT,'wireframe-detail.png'),await sharp(Buffer.from(detail)).png().toBuffer());
 fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify({status:'Unapproved larger-square wireframe',camera:P.camera,planeZ:0,opening:OPEN,previousOpening:OLD,replacements,model},null,2)+'\n');
 for(const [f,h]of Object.entries(before))if(P.hash(f)!==h)throw Error('Unexpected modification: '+f);
 fs.writeFileSync(path.join(OUT,'validation.json'),JSON.stringify({...checks,unchangedFiles:before},null,2)+'\n');
 fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pièges — carré agrandi et joints droits</title><style>body{margin:0;padding:20px;background:#0c111b;color:#dfe8f6;font:16px system-ui}img{display:block;max-width:100%;height:auto;margin:auto}a{color:#c4acdf}p{max-width:1000px;margin:20px auto}</style><img src="wireframe-board.png" alt="Carré central agrandi, entouré de pierres rectangulaires avec des joints alignés sur la grille isométrique"><p><a href="wireframe-detail.png">Agrandir le détail</a> · <a href="geometry.json">Géométrie</a> · <a href="validation.json">Vérifications</a></p><p>Le carré passe de 56 à 68 % de la largeur de la case. Les deux pierres latérales du bas changent de largeur pour rejoindre son bord droit. Aucun joint oblique dans le plan du sol. Proposition à valider avant de revenir aux textures.</p></html>`);
 console.log(JSON.stringify(checks,null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
