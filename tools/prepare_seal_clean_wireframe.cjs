// Isolated geometry revision: clean wall joins and a reusable smooth leaf.
// No production export, painting generation, game run or original-source edit.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Seal=require('./isometric_seal_door.cjs');
const W=require('./prepare_seal_junction_wireframe.cjs');
const OUT=path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/wireframe-v6-clean-leaf');
const span=[1/3,2/3],rotations={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
const protectedFiles=['tools/isometric_seal_door.cjs','tools/seal_masonry_finish.cjs','scripts/door_wall_junction.gd','shaders/door_wall_junction.gdshader','assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/catalog.tres','assets/dungeon/isometric-kit/atlas-256.png','assets/dungeon/isometric-kit/traps/atlas-256.png',...Seal.referenceFiles];
const baseline=Object.fromEntries(protectedFiles.map(p=>[p,P.hash(p)]));
function seal(){
 const old=Seal.geometry('south');
 const hardware=f=>/^(metal|seal)/.test(f.kind)&&f.points.every(p=>p[2]<.57);
 const faces=old.faces.filter(f=>f.kind!=='junction'&&!f.kind.startsWith('leaf')&&!hardware(f));
 const door={id:'clean-door',faces:structuredClone(faces),edges:[],curvedStrips:[]};
 // Widen the receiving jamb depth to existing upper-wall joints, instead of
 // keeping fragments or leaving holes where the old fragments were removed.
 for(const [lo,hi]of [[-P.T/2,.17],[.83,1+P.T/2]])for(const [z,Z]of [[0,P.H/2],[P.H/2,P.H]])W.box(door,lo,hi,...span,z,Z,'junction');
 const leafFaces=old.faces.filter(f=>f.kind==='leaf'),sides=leafFaces.slice(2);
 const profile=sides.map(f=>[f.points[0][0],f.points[0][2]]);
 assert.equal(profile.length,leafFaces[0].points.length,'All leaf perimeter vertices recovered');
 const front=profile.map(([x,z])=>[x,.525,z]),back=profile.map(([x,z])=>[x,.475,z]);
 door.faces.push({kind:'leaf',points:front},{kind:'leaf',points:back.slice().reverse()});
 for(let i=0;i<profile.length;i++)door.faces.push({kind:'leaf-edge',points:[back[i],back[(i+1)%profile.length],front[(i+1)%profile.length],front[i]]});
 assert(!door.faces.some(hardware),'No leaf-specific hardware remains');
 assert.equal(door.faces.filter(f=>f.kind==='leaf').length,2,'One uninterrupted plane on each side of the leaf');
 door.edges=door.faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind})));
 return {door,profile,removedHardwareFaces:old.faces.filter(hardware).length,unchangedFrameFaces:faces.length};
}
function context(door,direction){
 const m=structuredClone(door),stones=[];
 for(const x of [0,1])for(const [row,cuts]of [[0,1/6,1/2,5/6,1],[0,1/3,2/3,1]].entries())for(let i=1;i<cuts.length;i++)for(const [lo,hi]of [[0,span[0]],[span[1],1]]){
  const a=Math.max(lo,cuts[i-1]),b=Math.min(hi,cuts[i]);if(b-a<1e-9)continue;
  W.box(m,x-P.T/2,x+P.T/2,a,b,row*P.H/2,(row+1)*P.H/2,'wall');stones.push({x,row,min:a,max:b,length:b-a});
 }
 const tr=rotations[direction];m.faces=m.faces.map(f=>({...f,points:f.points.map(tr)}));
 m.edges=m.faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind})));
 m.id=direction;return {...m,stones};
}
async function frontal(door,profile){
 const camera={x:[1,0,0],y:[0,0,-1],eye:[0,1,0]},project=([x,y,z])=>[512+(x-.5)*820,890-z*820];
 const visible=P.visibleEdges(door,camera),polys=door.faces.slice().sort((a,b)=>a.points.reduce((s,p)=>s+p[1]/a.points.length,0)-b.points.reduce((s,p)=>s+p[1]/b.points.length,0));
 const shapes=polys.map(f=>`<polygon points="${f.points.map(p=>project(p).join(',')).join(' ')}" fill="${f.kind.startsWith('leaf')?'#625d70':f.kind.startsWith('seal')?'#75618c':'#414e63'}"/>`).join('');
 const lines=visible.map(e=>`<path d="M${project(e.a)}L${project(e.b)}"/>`).join('');
 const document=body=>`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">${body}</svg>`;
 const svg=document(shapes+`<g fill="none" stroke="#ff00ff" stroke-width="1.5">${lines}</g>`);
 fs.writeFileSync(path.join(OUT,'face-guide-magenta.svg'),svg);
 await sharp(Buffer.from(svg)).png().toFile(path.join(OUT,'face-guide-magenta.png'));
 const mask=document(`<polygon points="${profile.map(([x,z])=>project([x,.525,z]).join(',')).join(' ')}" fill="white"/>`);
 fs.writeFileSync(path.join(OUT,'leaf-mask.svg'),mask);
 await sharp(Buffer.from(mask)).png().toFile(path.join(OUT,'leaf-mask.png'));
 // Convex contour plus two front/back planes, with no interior edge or ornament.
 const leafEdges=door.edges.filter(e=>e.kind==='leaf');
 assert.equal(leafEdges.length,profile.length*2);
 return {mapping:{size:[1024,1024],scale:820,xOrigin:512,xCentre:.5,zOrigin:890},frontalVisibleSegments:visible.length,leafPerimeterSegments:leafEdges.length};
}
async function main(){
 fs.mkdirSync(OUT,{recursive:true});const {door,profile,removedHardwareFaces,unchangedFrameFaces}=seal();
 const models=Object.fromEntries(Object.keys(rotations).map(d=>[d,context(door,d)]));
 assert.equal(models.south.stones.filter(s=>s.length<.04).length,0,'No small wall fragments');
 assert(models.south.stones.every(s=>s.min>=span[1]-1e-9||s.max<=span[0]+1e-9));
 // The two courses at every rail terminate on each full jamb face, with exact
 // coincident endpoints. Nothing is merely hidden or deleted leaving a void.
 const contacts=[];
 for(const x of [0,1])for(const y of span)for(const z of [0,P.H/2,P.H]){
  const stone=models.south.stones.find(s=>s.x===x&&(Math.abs(s.min-y)<1e-9||Math.abs(s.max-y)<1e-9));assert(stone);
  assert(door.faces.some(f=>f.kind==='junction'&&f.points.every(p=>Math.abs(p[1]-y)<1e-9)&&f.points.some(p=>Math.abs(p[2]-z)<1e-9)));
  contacts.push([x,y,z]);
 }
 fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify({status:'revised-wireframe-for-review',camera:P.camera,span,door,models,leaf:{profileXZ:profile,frontY:.525,backY:.475,textureRole:'one interchangeable painted image; no hardware geometry'}},null,2));
 for(const [d,m]of Object.entries(models))fs.writeFileSync(path.join(OUT,`wireframe-${d}-magenta.png`),await W.render(m,W.frame(m),3,{magenta:true}));
 const guide=await frontal(door,profile);
 const header=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="1040"><rect width="1400" height="1040" fill="#0c111b"/><g font-family="Segoe UI,sans-serif" fill="#e2e5ec"><text x="32" y="45" font-size="28">Wireframe corrigé — raccords propres, battant libre</text><text x="32" y="77" font-size="17" fill="#bcc7d6">Les pieds rejoignent les joints des murs. Le battant est une surface lisse, sans ferrure ni serrure imposée.</text><text x="32" y="116" font-size="20">Deux orientations · guide magenta issu des mêmes volumes</text><text x="32" y="641" font-size="20">Guide frontal pour la future texture</text><text x="610" y="700" font-size="21">Une zone de texture interchangeable</text><text x="610" y="742" font-size="18" fill="#bcc7d6">Seul le contour du battant est fixé.</text><text x="610" y="778" font-size="18" fill="#bcc7d6">Planches, métal, serrure, motifs : dans la texture.</text><text x="610" y="840" font-size="18" fill="#bcc7d6">Les petits fragments de mur sont supprimés.</text><text x="610" y="876" font-size="18" fill="#bcc7d6">Les pieds occupent leur place, sans laisser de trou.</text><text x="610" y="950" font-size="16" fill="#d1a8e4">Maquette de géométrie · aucune nouvelle peinture</text></g></svg>`);
 const layers=[{input:header,left:0,top:0}];
 for(const [i,d]of ['south','east'].entries())layers.push({input:await sharp(path.join(OUT,`wireframe-${d}-magenta.png`)).resize({width:640,height:470,fit:'inside'}).png().toBuffer(),left:32+i*678,top:133});
 layers.push({input:await sharp(path.join(OUT,'face-guide-magenta.png')).resize(350,350).png().toBuffer(),left:120,top:655});
 await sharp({create:{width:1400,height:1040,channels:4,background:'#0c111b'}}).composite(layers).png().toFile(path.join(OUT,'wireframe-board.png'));
 for(const [p,h]of Object.entries(baseline))assert.equal(P.hash(p),h,'Protected runtime/source changed: '+p);
 const checks={status:'isolated-wireframe-only',oldSpan:[.365,.635],newSpan:span,oldFragments:4,newFragments:0,minimumRetainedWallStoneLength:Math.min(...models.south.stones.map(s=>s.length)),coincidentContactChecks:contacts.length,removedHardwareFaces,unchangedFrameFaces,smoothLeafPlanes:2,guide,protectedFiles:baseline};
 fs.writeFileSync(path.join(OUT,'checks.json'),JSON.stringify(checks,null,2));
 fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><title>Porte — wireframe corrigé</title><style>body{margin:24px;background:#0c111b;color:#e2e5ec;font:17px system-ui}main{max-width:1400px;margin:auto}img{max-width:100%;height:auto}a{color:#dfb6ff}p{max-width:1050px;line-height:1.6}.guides{display:flex;gap:24px;flex-wrap:wrap}.guides img{width:450px}</style><main><h1>Raccords propres et battant lisse</h1><p>Les pieds de porte rejoignent maintenant les joints des murs à ⅓ et ⅔ de case. Les quatre petites bandes disparaissent, sans trou. Le battant garde son contour et une épaisseur, mais sa surface ne contient plus aucune ferrure, serrure, découpe de planches ou ornement.</p><a href="wireframe-board.png"><img src="wireframe-board.png" alt="Wireframe corrigé et guide frontal magenta"></a><h2>Guides pour la peinture</h2><p>Les tracés magenta proviennent de la même géométrie que les volumes. Le guide frontal et le masque du battant sont préparés pour la prochaine peinture ; aucune nouvelle texture n’a encore été générée ni intégrée.</p><div class="guides"><a href="face-guide-magenta.png"><img src="face-guide-magenta.png" alt="Guide frontal magenta"></a><a href="leaf-mask.png"><img src="leaf-mask.png" alt="Masque de la zone de texture libre"></a></div><p><a href="geometry.json">Géométrie</a> · <a href="checks.json">Contrôles</a> · <a href="../wireframe-v5-junctions/index.html">Version précédente</a></p></main>`);
 console.log(JSON.stringify({review:OUT,newFragments:0,contacts:contacts.length,removedHardwareFaces,protectedFiles:protectedFiles.length}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
