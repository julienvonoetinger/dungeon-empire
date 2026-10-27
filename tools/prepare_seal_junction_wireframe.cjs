// Read-only review of current door geometry + the masonry joints intersected
// by the runtime rail cut. Writes review evidence, never production assets.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Seal=require('./isometric_seal_door.cjs');
const OUT=path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/wireframe-v5-junctions');
const protectedFiles=['tools/isometric_seal_door.cjs','tools/seal_masonry_finish.cjs','scripts/door_wall_junction.gd','shaders/door_wall_junction.gdshader','assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/atlas-256.png'];
const before=Object.fromEntries(protectedFiles.map(p=>[p,P.hash(p)]));
const cuts={lower:[0,1/6,1/2,5/6,1],upper:[0,1/3,2/3,1]},span=[.365,.635];
function box(m,x,X,y,Y,z,Z,kind){
 const p=[[x,y,z],[X,y,z],[X,Y,z],[x,Y,z],[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]];
 for(const ids of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])m.faces.push({points:ids.map(i=>p[i]),kind});
}
function model(direction){
 const door=Seal.geometry('south'),m={faces:structuredClone(door.faces),edges:[],curvedStrips:[]};
 const fragments=[];
 for(const x of [0,1])for(const [row,joints]of [cuts.lower,cuts.upper].entries())for(let i=1;i<joints.length;i++)for(const [lo,hi]of [[0,span[0]],[span[1],1]]){
  const a=Math.max(joints[i-1],lo),b=Math.min(joints[i],hi);if(b<=a)continue;
  const fragment=b-a<.04;
  if(fragment)fragments.push({x,row,min:a,max:b,width:b-a,fractionOfUpperBrick:(b-a)*3});
  box(m,x-P.T/2,x+P.T/2,a,b,row*P.H/2,(row+1)*P.H/2,fragment?'fragment':'wall');
 }
 const tr=direction==='south'?p=>p:([x,y,z])=>[y,1-x,z];
 m.faces=m.faces.map(f=>({...f,points:f.points.map(tr)}));
 m.edges=m.faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind})));
 return {...m,id:direction,fragments};
}
function frame(m){
 const ps=m.faces.flatMap(f=>f.points.map(P.project)),lo=[0,1].map(i=>Math.floor(Math.min(...ps.map(p=>p[i])))-12),hi=[0,1].map(i=>Math.ceil(Math.max(...ps.map(p=>p[i])))+12);
 return [...lo,hi[0]-lo[0],hi[1]-lo[1]];
}
async function render(m,fr,scale=3,{magenta=false}={}){
 const r=P.raster(m,fr,scale),raw=Buffer.alloc(r.width*r.height*4),normals=m.faces.map(f=>P.normal(f.points));
 for(let i=0;i<r.owner.length;i++){
  const fi=r.owner[i];let rgb=[12,17,27];
  if(fi>=0){const f=m.faces[fi],n=normals[fi],base=f.kind==='fragment'?[218,133,49]:f.kind==='wall'?[65,91,111]:['leaf','metal','seal'].some(k=>f.kind.startsWith(k))?[55,57,68]:[81,84,111];
   const light=.60+.25*Math.max(0,n[2])+.15*Math.abs(n[1]);rgb=base.map(v=>Math.round(v*light));}
  raw.set([...rgb,255],i*4);
 }
 const edges=P.visibleEdges(m,P.camera),lines=edges.map(e=>`<path d="M${P.project(e.a)}L${P.project(e.b)}" stroke="${magenta?'#ff00ff':e.kind==='fragment'?'#ffbd70':e.kind==='wall'?'#9ab3c5':'#b4b4d0'}"/>`).join('');
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${r.width}" height="${r.height}" viewBox="${fr.join(' ')}"><g fill="none" stroke-width=".55" stroke-linejoin="round">${lines}</g></svg>`;
 return sharp(raw,{raw:{width:r.width,height:r.height,channels:4}}).composite([{input:Buffer.from(svg)}]).png().toBuffer();
}
async function main(){
 fs.mkdirSync(OUT,{recursive:true});const s=model('south'),e=model('east'),a=frame(s),b=frame(e);
 fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify({camera:P.camera,wallHeight:P.H,wallThickness:P.T,cuts,span,models:{south:s,east:e}},null,2));
 for(const [m,f]of [[s,a],[e,b]])fs.writeFileSync(path.join(OUT,`wireframe-${m.id}.png`),await render(m,f));
 const closeFrame=[48,-10,140,132];
 fs.writeFileSync(path.join(OUT,'junction-closeup.png'),await render(s,closeFrame,4));
 const top=(x,y)=>[60+y*430,160+x*110];
 const rect=(x,X,y,Y,color)=>{const [a,b]=top(x,y),[c,d]=top(X,Y);return `<rect x="${a}" y="${b}" width="${c-a}" height="${d-b}" fill="${color}" stroke="#a6b6c7"/>`;};
 let diagram='';
 for(const x of [0,1]){for(let i=1;i<cuts.upper.length;i++)for(const [lo,hi]of [[0,span[0]],[span[1],1]]){
  const a=Math.max(cuts.upper[i-1],lo),b=Math.min(cuts.upper[i],hi);if(b>a)diagram+=rect(x-P.T/2,x+P.T/2,a,b,b-a<.04?'#c67d37':'#33485a');
 }}
 for(const [lo,hi]of [[-P.T/2,.17],[.83,1+P.T/2]])diagram+=rect(lo,hi,...span,'#5a537c');
 diagram+=rect(.17,.83,.475,.525,'#393644');
 for(const [v,label,y]of [[1/3,'joint du mur',106],[.365,'coupe',127],[.635,'coupe',127],[2/3,'joint du mur',106]]){const x=top(0,v)[0];diagram+=`<path d="M${x} ${y+5}V${150}" stroke="#d7ab78"/><text x="${x}" y="${y}" text-anchor="${v<.5?'end':'start'}" fill="#d8c9b9" font-size="12">${label}</text>`;}
 diagram+='<text x="275" y="328" text-anchor="middle" fill="#ffbd70" font-size="16">Fragments orange : 9,5 % d’une brique</text>';
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="560" height="365"><rect width="560" height="365" fill="#0c111b"/><g font-family="Segoe UI,sans-serif"><text x="30" y="35" fill="#e2e5ec" font-size="21">Plan au niveau du dessus des murs</text><text x="30" y="64" fill="#b8c3d0" font-size="14">Violet : pieds de porte · bleu : murs</text>${diagram}</g></svg>`;
 await sharp(Buffer.from(svg)).png().toFile(path.join(OUT,'top-view.png'));
 const header=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="1020"><rect width="1400" height="1020" fill="#0c111b"/><g font-family="Segoe UI,sans-serif" fill="#e2e5ec"><text x="32" y="45" font-size="28">Porte — wireframe des raccords actuels</text><text x="32" y="77" font-size="17" fill="#bcc7d6">Géométrie de la porte + joints des murs et coupe réelle à .365 / .635. Aucune nouvelle correction.</text><text x="32" y="115" font-size="19">Vue A</text><text x="710" y="115" font-size="19">Vue B — autre orientation</text><text x="32" y="628" font-size="20">Gros plan du raccord</text><text x="32" y="991" font-size="17" fill="#ffbd70">Orange : petits fragments de la rangée haute laissés entre le joint d’une brique et la coupe du mur.</text></g></svg>`);
 const layers=[{input:header,left:0,top:0}];
 for(const [i,d]of ['south','east'].entries())layers.push({input:await sharp(path.join(OUT,`wireframe-${d}.png`)).resize({width:640,height:470,fit:'inside'}).png().toBuffer(),left:32+i*678,top:130});
 layers.push({input:await sharp(path.join(OUT,'junction-closeup.png')).resize({width:560,height:315,fit:'inside'}).png().toBuffer(),left:85,top:647});
 layers.push({input:await sharp(path.join(OUT,'top-view.png')).png().toBuffer(),left:740,top:605});
 await sharp({create:{width:1400,height:1020,channels:4,background:'#0c111b'}}).composite(layers).png().toFile(path.join(OUT,'wireframe-board.png'));
 for(const [p,h]of Object.entries(before))if(P.hash(p)!==h)throw Error('Wireframe review changed production: '+p);
 fs.writeFileSync(path.join(OUT,'checks.json'),JSON.stringify({protectedFiles:before,fragments:s.fragments,source:'Current door geometry and base wall masonry course positions; runtime wall clipping interval; no texture and no renderer change',limits:'Masonry line schematic uses the base wall courses; it does not draw painted erosion, rounding or raster-filter fringes.'},null,2));
 fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><title>Porte — wireframe des raccords</title><style>body{margin:24px;background:#0c111b;color:#e2e5ec;font:17px system-ui}main{max-width:1400px;margin:auto}img{max-width:100%;height:auto}a{color:#c6b4ff}p{max-width:1000px;line-height:1.5}</style><main><h1>Les raccords actuels, sans texture</h1><p>Les fragments orange proviennent d’une coupe à .365 / .635, décalée par rapport aux joints des briques à ⅓ / ⅔. Ils mesurent 9,5 % de la longueur d’une brique de la rangée haute. Les volumes violets représentent la porte, les volumes bleus les murs. Les joints de texture sont représentés en lignes droites ; les biseaux peints sont masqués.</p><a href="wireframe-board.png"><img src="wireframe-board.png" alt="Wireframes actuels et vue de dessus"></a><p>Cette planche montre le problème actuel. Aucune correction de ces raccords n’a été appliquée lors de sa génération.</p><p><a href="geometry.json">Géométrie</a> · <a href="checks.json">Contrôles</a></p></main>`);
 console.log(JSON.stringify({review:OUT,fragmentCount:s.fragments.length,width:s.fragments[0].width,protectedFiles:protectedFiles.length}));
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1});
module.exports={box,model,frame,render};
