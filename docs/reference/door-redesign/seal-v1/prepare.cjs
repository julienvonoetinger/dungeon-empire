// Isolated design study. No production export or approved source is modified.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const ROOT = path.resolve(__dirname, '../../../..');
const P = require(path.join(ROOT, 'tools/isometric_paint_geometry.cjs'));
const G = require(path.join(ROOT, 'tools/wireframe_geometry.cjs'));
const OUT = __dirname;
const digest = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const protectedPaths = [...P.sourceFiles,
  'docs/reference/isometric-review/migration-v1/geometry.json',
  'assets/dungeon/isometric-kit/catalog.json',
  'assets/dungeon/isometric-kit/catalog.tres',
  'tools/mobile_approved_doors.cjs', 'tools/isometric_stone_paint.cjs',
  'project.godot'];
const before = Object.fromEntries(protectedPaths.map(p => [p, digest(path.join(ROOT, p))]));
const model = id => ({id, faces: [], edges: [], curvedStrips: []});
function face(m, points, kind, edges = true) {
  m.faces.push({points, kind});
  if (edges) points.forEach((a, i) => m.edges.push({a, b: points[(i + 1) % points.length], kind}));
}
// A convex XZ prism, with a narrow planar bevel on each visible end face.
function prism(m, profile, y0, y1, kind = 'stone', bevel = .04) {
  const cx = profile.reduce((s, p) => s + p[0], 0) / profile.length;
  const cz = profile.reduce((s, p) => s + p[1], 0) / profile.length;
  const inset = profile.map(([x,z]) => [cx+(x-cx)*(1-bevel), cz+(z-cz)*(1-bevel)]);
  const b = bevel ? Math.min(.008, (y1-y0)*.2) : 0;
  const front = inset.map(([x,z]) => [x,y1,z]);
  const rear = inset.map(([x,z]) => [x,y0,z]);
  const a = profile.map(([x,z]) => [x,y0+b,z]);
  const c = profile.map(([x,z]) => [x,y1-b,z]);
  face(m, front, kind); face(m, rear.slice().reverse(), kind);
  for (let i=0; i<profile.length; i++) {
    const j=(i+1)%profile.length;
    face(m, [a[i],a[j],c[j],c[i]], kind);
    if (bevel) {
      face(m, [front[i],c[i],c[j],front[j]], kind+'-bevel');
      face(m, [rear[i],rear[j],a[j],a[i]], kind+'-bevel');
    }
  }
}
const box = (m,x,X,y,Y,z,Z,kind='stone') => prism(m, [[x,z],[X,z],[X,Z],[x,Z]],y,Y,kind);
function strip(m, outer, inner, y0, y1, kind, separate=false) {
  for (let i=0; i<outer.length-1; i++) {
    const q=[outer[i],outer[i+1],inner[i+1],inner[i]];
    const center=q.reduce((a,p)=>[a[0]+p[0]/4,a[1]+p[1]/4],[0,0]);
    const inset=separate?q.map(p=>p.map((v,k)=>center[k]+(v-center[k])*.987)):q;
    prism(m,inset,y0,y1,kind,separate?.055:0);
  }
}
const outer=[[-.06,0],[-.04,.36],[.015,.57],[.18,.72],[.33,.785],[.67,.785],[.82,.72],[.985,.57],[1.04,.36],[1.06,0]];
const inner=[[.17,0],[.17,.32],[.20,.45],[.30,.56],[.41,.625],[.59,.625],[.70,.56],[.80,.45],[.83,.32],[.83,0]];
const surround=[[.21,0],[.21,.29],[.23,.395],[.31,.49],[.425,.56],[.575,.56],[.69,.49],[.77,.395],[.79,.29],[.79,0]];
const opening=[[.255,0],[.255,.27],[.272,.365],[.34,.45],[.44,.513],[.56,.513],[.66,.45],[.728,.365],[.745,.27],[.745,0]];
function door(m, leaf=true) {
  strip(m,outer,inner,.385,.615,'stone',true);
  // A continuous recessed stone field; no masonry joint lines across this band.
  const start=m.edges.length;
  strip(m,inner,surround,.425,.575,'recess');
  m.edges.splice(start);
  strip(m,surround,opening,.405,.595,'inner',true);
  // Heavy feet and two short crooked horn stones, part of the same architecture.
  prism(m,[[-.075,0],[.19,0],[.18,.075],[-.065,.075]],.365,.635,'stone');
  prism(m,[[.81,0],[1.075,0],[1.065,.075],[.82,.075]],.365,.635,'stone');
  for (const mirror of [false,true]) {
    const tr = p => p.map(([x,z]) => [mirror?1-x:x,z]);
    prism(m,tr([[.06,.66],[.185,.69],[.245,.79],[.125,.785]]),.415,.605,'horn');
    prism(m,tr([[.125,.785],[.245,.79],[.25,.895],[.195,.875]]),.415,.605,'horn');
  }
  const crown=[[.402,.8],[.598,.8],[.582,.638],[.5,.578],[.418,.638]];
  prism(m,crown,.367,.633,'metal');
  const seal=[[.5,.765],[.542,.718],[.536,.637],[.5,.607],[.464,.637],[.458,.718]];
  prism(m,seal,.360,.640,'seal',.08);
  // The leaf remains smooth and has no plank/seam wireframe.
  if (leaf) {
    prism(m,opening,.475,.525,'leaf',.02);
    const clasp=[[.48,.05],[.52,.05],[.53,.12],[.526,.435],[.5,.472],[.474,.435],[.47,.12]];
    prism(m,clasp,.458,.542,'metal');
    box(m,.491,.509,.452,.548,.10,.425,'seal');
    const jewel=[[.5,.225],[.55,.29],[.5,.355],[.45,.29]];
    prism(m,jewel,.443,.557,'metal',.14);
    prism(m,[[.5,.25],[.529,.29],[.5,.33],[.471,.29]],.437,.563,'seal');
    for (const right of [false,true]) {
      const tr=p=>p.map(([x,z])=>[right?1-x:x,z]);
      prism(m,tr([[.28,.255],[.42,.24],[.45,.265],[.43,.302],[.28,.32]]),.451,.549,'metal');
      prism(m,tr([[.395,.237],[.424,.211],[.442,.247],[.433,.315],[.404,.341]]),.443,.557,'metal');
    }
  }
}
function floor(m,x0,x1,y0,y1) {
  face(m,[[x0,y0,-.001],[x1,y0,-.001],[x1,y1,-.001],[x0,y1,-.001]],'floor');
  let row=0;
  for(let y=y0;y<y1-1e-5;y+=1/3,row++) {
    const Y=Math.min(y1,y+1/3);
    m.edges.push({a:[x0,y,0],b:[x1,y,0],kind:'floor'});
    for(let x=x0+(row%2?.17:.33);x<x1;x+=1/3)
      m.edges.push({a:[x,y,0],b:[x,Y,0],kind:'floor'});
  }
}
function wall(m,x0,x1,y0,y1) {
  box(m,x0,x1,y0,y1,0,P.H,'wall');
  const horizontal=x1-x0>y1-y0;
  const a=horizontal?x0:y0,b=horizontal?x1:y1;
  const p=(u,v,z)=>horizontal?[u,v,z]:[v,u,z];
  for(const v of horizontal?[y0,y1]:[x0,x1]) {
    m.edges.push({a:p(a,v,P.H/2),b:p(b,v,P.H/2),kind:'joint'});
    for(let u=a+1/3;u<b-.01;u+=1/3) m.edges.push({a:p(u,v,P.H/2),b:p(u,v,P.H),kind:'joint'});
    for(let u=a+1/6;u<b-.01;u+=1/3) m.edges.push({a:p(u,v,0),b:p(u,v,P.H/2),kind:'joint'});
  }
}
function make(type,leaf=true) {
  const m=model(type+(leaf?'':'-opening'));
  if(type==='facade') {
    floor(m,-.68,1.68,.15,1.18);
    wall(m,-.68,-.035,.5-P.T/2,.5+P.T/2);
    wall(m,1.035,1.68,.5-P.T/2,.5+P.T/2);
  } else {
    floor(m,0,1,-.38,1.38);
    for(const x of [0,1]) {
      wall(m,x-P.T/2,x+P.T/2,-.38,.365);
      wall(m,x-P.T/2,x+P.T/2,.635,1.38);
    }
  }
  door(m,leaf); return m;
}
const rotations={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
function rotate(m,d) {
  const tr=rotations[d];return {...m,id:m.id+'-'+d,faces:m.faces.map(f=>({...f,points:f.points.map(tr)})),edges:m.edges.map(e=>({...e,a:tr(e.a),b:tr(e.b)}))};
}
const palette={stone:[87,98,115],inner:[65,76,92],recess:[48,58,72],horn:[102,113,131],metal:[99,107,122],seal:[128,97,165],leaf:[36,42,54],floor:[32,43,55],wall:[55,68,84]};
const light=P.mul([-.6,-.9,1.4],1/Math.hypot(.6,.9,1.4));
const fmt=n=>+n.toFixed(4);
async function render(m,name) {
  const pts=m.faces.flatMap(f=>f.points.map(P.project));
  const lo=[0,1].map(i=>Math.floor(Math.min(...pts.map(p=>p[i])))-8);
  const hi=[0,1].map(i=>Math.ceil(Math.max(...pts.map(p=>p[i])))+8);
  const frame=[...lo,hi[0]-lo[0],hi[1]-lo[1]],r=P.raster(m,frame,3);
  const colors=m.faces.map(f=>{
    const base=palette[f.kind.replace('-bevel','')]||palette.stone;
    const n=P.normal(f.points),lit=.72+.32*Math.max(0,P.dot(n,light))+(f.kind.endsWith('-bevel')?.04:0);
    return base.map(v=>Math.round(v*lit));
  });
  const pixels=Buffer.alloc(r.width*r.height*4);
  for(let k=0;k<r.owner.length;k++)if(r.owner[k]>=0) {
    pixels.set(colors[r.owner[k]],k*4);pixels[k*4+3]=255;
  }
  const edges=G.visibleEdges(m,P.camera);
  const lines=edges.map(e=>{
    const a=P.project(e.a).map((v,i)=>fmt(v-frame[i])),b=P.project(e.b).map((v,i)=>fmt(v-frame[i]));
    const ground=e.kind==='floor',joint=e.kind==='joint';
    return `<path d="M${a}L${b}" stroke="${ground?'#607b88':joint?'#8996a5':'#c7cfdb'}" stroke-opacity="${ground?.4:joint?.6:.8}" stroke-width="${ground?.36:joint?.4:.48}"/>`;
  }).join('');
  const svg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${r.width}" height="${r.height}" viewBox="0 0 ${frame[2]} ${frame[3]}"><g fill="none" stroke-linecap="round" stroke-linejoin="round">${lines}</g></svg>`);
  const raw=await sharp(pixels,{raw:{width:r.width,height:r.height,channels:4}}).png().toBuffer();
  const png=await sharp(raw).composite([{input:svg}]).png().toBuffer();
  fs.writeFileSync(path.join(OUT,name+'.png'),png);
  return {png,frame,faces:m.faces.length,edges:edges.length};
}
const text=(x,y,s,size=18,color='#c3cbd7')=>`<text x="${x}" y="${y}" fill="${color}" font-size="${size}" font-family="Segoe UI, sans-serif">${s}</text>`;
async function fit(r,w,h){return sharp(r.png).resize({width:w,height:h,fit:'inside'}).png().toBuffer();}
async function main() {
  const facade=make('facade'),openingModel=make('facade',false);
  const a=await render(facade,'volume-closed'),b=await render(openingModel,'volume-opening');
  const contexts={};
  for(const d of Object.keys(rotations)) contexts[d]=await render(rotate(make('corridor'),d),'corridor-'+d);
  const heading=`<rect width="1500" height="1080" fill="#0b101a"/>
    <path d="M40 110H1460M40 720H1460" stroke="#2e394c"/>
    ${text(42,50,'C — SCEAU INTERDIT',30,'#e7e3f2')}
    ${text(42,84,'Étude de volumes · projection isométrique du kit · textures à venir',18)}
    ${text(42,150,'Porte fermée',22,'#f0edf7')}${text(830,150,'Sans le battant',22,'#f0edf7')}
    ${text(830,181,'Le renfoncement et l’épaisseur du cadre restent visibles.',16)}
    ${text(42,696,'Deux pointes de pierre · épaules brisées · battant lisse · sceau en relief',18)}
    ${text(42,760,'Lecture à l’échelle actuelle du jeu (.75)',21,'#f0edf7')}
    ${text(42,1058,'Proposition de géométrie, sans intégration au jeu. Les grandes vues sont agrandies.',16,'#8d9aad')}`;
  const parts=[{input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1080">${heading}</svg>`),left:0,top:0}];
  const mainImage=await fit(a,750,500),openingImage=await fit(b,610,430);
  parts.push({input:mainImage,left:28,top:190},{input:openingImage,left:820,top:230});
  let labelSvg='';
  const titles={south:'Sud',north:'Nord',east:'Est',west:'Ouest'};
  for(const [i,d] of Object.keys(rotations).entries()) {
    const r=contexts[d],width=Math.round(r.frame[2]*.75),height=Math.round(r.frame[3]*.75);
    const png=await sharp(r.png).resize(width,height).png().toBuffer();
    fs.writeFileSync(path.join(OUT,'game-scale-'+d+'.png'),png);
    const cx=190+i*370;
    parts.push({input:png,left:Math.round(cx-width/2),top:810});
    labelSvg+=text(cx-30,792,titles[d],16);
  }
  parts.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1080">${labelSvg}</svg>`),left:0,top:0});
  await sharp({create:{width:1500,height:1080,channels:4,background:'#0b101a'}}).composite(parts).png().toFile(path.join(OUT,'wireframe-board.png'));
  const allModels={facade,opening:openingModel,...Object.fromEntries(Object.keys(rotations).map(d=>[d,rotate(make('corridor'),d)]))};
  const after=Object.fromEntries(protectedPaths.map(p=>[p,digest(path.join(ROOT,p))]));
  if(JSON.stringify(before)!==JSON.stringify(after))throw Error('A protected input changed during this review export.');
  fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify({status:'proposed-geometry',camera:P.camera,sourcePixelsPerCell:P.PX,displayZoom:.75,wallHeight:P.H,wallThickness:P.T,doorMaximumHeight:.895,leafHasPlankLines:false,models:allModels}));
  fs.writeFileSync(path.join(OUT,'validation.json'),JSON.stringify({status:'offline-geometric-review-only',protectedInputsUnchanged:after,projection:P.camera,orientations:Object.fromEntries(Object.entries(contexts).map(([d,r])=>[d,{frame:r.frame,faces:r.faces,visibleEdges:r.edges,nativeSize:r.frame.slice(2).map(v=>Math.round(v*.75))}])),limitations:['Geometry and proportions await user feedback.','No runtime sprite, atlas, placement, animation or mobile device validation.','Existing game and approved sources are unchanged by this generator.']},null,2)+'\n');
  fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>C — Sceau interdit · volumes</title><style>body{margin:0;background:#0b101a;color:#d2d6e0;font:17px system-ui}main{max-width:1500px;margin:auto;padding:20px}img{display:block;width:100%;height:auto}details{padding:20px;background:#141c2a;border-radius:12px}summary{cursor:pointer;padding:12px}p{line-height:1.6}a{color:#c5b0ee}</style><main><img src="wireframe-board.png" alt="Étude isométrique du portail Sceau interdit, battant fermé et retiré, quatre orientations à l’échelle du jeu"><p>La direction C est retenue. Cette adaptation géométrique est proposée pour vérifier sa silhouette et son raccord aux murs. La porte en bois reste lisse ; seuls les volumes de pierre et les ferrures structurantes sont représentés. Le violet identifie le sceau, sans préjuger de sa future texture.</p><details><summary>Revoir le concept sélectionné</summary><img src="concept-selected.png" alt="Concept C sélectionné"></details><p><a href="wireframe-board.png">Ouvrir la planche en taille réelle</a> · Étude hors jeu, aucune modification des sprites de production.</p></main></html>`);
  console.log(JSON.stringify({output:path.join(OUT,'wireframe-board.png'),protectedInputs:Object.keys(after).length,orientations:Object.keys(contexts),gameScaleSizes:Object.fromEntries(Object.entries(contexts).map(([d,r])=>[d,r.frame.slice(2).map(v=>Math.round(v*.75))]))},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
