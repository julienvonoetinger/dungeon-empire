// Disposable design study: shared 2:1 camera, true floor opening and recessed
// insert. No painted asset is transformed and no production resource is edited.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const DIR=path.join(P.ROOT,'docs/reference/trap-review/v2-inset-floor');
const CUT=[.22,.22,.78,.78],INNER=[.235,.235,.765,.765],DEPTH=.09,INSERT_Z=-.025;
const WIDTHS=[[.18,.35,.33,.14],[.30,.34,.32,.04],[.07,.33,.35,.25]];
function face(m,points,kind,group=kind){m.faces.push({points,kind,group});}
function rect(m,r,z,kind,group){face(m,[[r[0],r[1],z],[r[2],r[1],z],[r[2],r[3],z],[r[0],r[3],z]],kind,group);}
function subtract(r,h){
 const x=Math.max(r[0],h[0]),y=Math.max(r[1],h[1]),X=Math.min(r[2],h[2]),Y=Math.min(r[3],h[3]);
 if(x>=X||y>=Y)return [r];
 return [[r[0],r[1],x,r[3]],[X,r[1],r[2],r[3]],[x,r[1],X,y],[x,Y,X,r[3]]].filter(q=>q[2]-q[0]>1e-9&&q[3]-q[1]>1e-9);
}
function corners(r,z){return [[r[0],r[1],z],[r[2],r[1],z],[r[2],r[3],z],[r[0],r[3],z]];}
function floorModel(id){
 const m={id,faces:[]},context=[-.18,-.18,1.18,1.18];
 for(let cy=-1;cy<=1;cy++)for(let cx=-1;cx<=2;cx++)for(let row=0;row<3;row++){
  const w=WIDTHS[row],stones=[[-w[3],w[0]],[w[0],w[0]+w[1]],[w[0]+w[1],1-w[3]]];
  for(let i=0;i<stones.length;i++){
   // Keep crossing stones whole, as the active periodic floor exporter does.
   const r=[Math.max(context[0],cx+stones[i][0]),Math.max(context[1],cy+row/3),Math.min(context[2],cx+stones[i][1]),Math.min(context[3],cy+(row+1)/3)];
   if(r[0]>=r[2]||r[1]>=r[3])continue;
   for(const q of subtract(r,CUT))rect(m,q,0,'floor',`stone:${cx}:${cy}:${row}:${i}`);
  }
 }
 const outer=corners(CUT,0),inner=corners(INNER,-.02),bottom=corners(INNER,-DEPTH);
 for(let i=0;i<4;i++){
  const j=(i+1)%4;
  face(m,[outer[i],outer[j],inner[j],inner[i]],'bevel','bevel:'+i);
  face(m,[inner[i],inner[j],bottom[j],bottom[i]],'recess','recess:'+i);
 }
 rect(m,INNER,-DEPTH,'bottom');return m;
}
function box(m,r,z,Z,kind,group){
 const a=corners(r,z),b=corners(r,Z);face(m,b,kind,group+':top');
 for(let i=0;i<4;i++){const j=(i+1)%4;face(m,[a[i],a[j],b[j],b[i]],kind,group+':'+i);}
}
function insert(m,raised){
 rect(m,INNER,INSERT_Z,'insert');
 for(let x=0;x<3;x++)for(let y=0;y<3;y++){
  const X=.34+x*.16,Y=.34+y*.16,a=.052,g=`socket:${x}:${y}`;
  box(m,[X-a,Y-a,X+a,Y+a],INSERT_Z,-.02,'socket',g);
  if(raised){const r=.042,z=-.02,p=[[X-r,Y-r,z],[X+r,Y-r,z],[X+r,Y+r,z],[X-r,Y+r,z]],tip=[X,Y,.12];for(let i=0;i<4;i++)face(m,[p[i],p[(i+1)%4],tip],'spike',g+':spike:'+i);}
  else rect(m,[X-.034,Y-.034,X+.034,Y+.034],-.019,'slot',g+':slot');
 }
}
function color(f){
 const n=P.normal(f.points),top=n[2]>.7,shade=top?1:Math.abs(n[0])>Math.abs(n[1])?.68:.84;
 const colors={floor:[64,76,96],bevel:[114,127,155],recess:[34,42,60],bottom:[20,26,40],insert:[63,64,88],socket:[77,86,106],slot:[16,23,36],spike:[145,160,184]};
 let c=colors[f.kind];if(f.kind==='floor'){let h=0;for(const ch of f.group)h=(h*31+ch.charCodeAt(0))>>>0;c=c.map(v=>v+(h%7)-3);}
 return c.map(v=>Math.round(v*shade));
}
async function render(m,scale){
 const frame=[-180,-42,360,212],mesh=P.raster(m,frame,scale),raw=Buffer.alloc(mesh.width*mesh.height*4),colors=m.faces.map(color);
 for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++){
  const k=y*mesh.width+x,fi=mesh.owner[k];if(fi<0)continue;
  let edge=false;for(const [dx,dy] of [[-1,0],[1,0],[0,-1],[0,1]]){const X=x+dx,Y=y+dy;if(X<0||Y<0||X>=mesh.width||Y>=mesh.height)continue;const other=mesh.owner[Y*mesh.width+X];if(other<0||m.faces[other].group!==m.faces[fi].group)edge=true;}
  const c=edge?(m.faces[fi].kind==='floor'?[98,112,138]:[149,159,183]):colors[fi];raw.set([...c,255],k*4);
 }
 return sharp(raw,{raw:{width:mesh.width,height:mesh.height,channels:4}}).png().toBuffer();
}
async function main(){
 fs.mkdirSync(DIR,{recursive:true});const empty=floorModel('dalle-reservation'),ready=floorModel('insert-affleurant'),active=floorModel('pointes-deployees');insert(ready,false);insert(active,true);
 const models=[empty,ready,active];
 // Geometry checks are design invariants, not gameplay tests.
 const floorFaces=empty.faces.filter(f=>f.kind==='floor');
 const noFloorInside=floorFaces.every(f=>{const x=f.points.map(p=>p[0]),y=f.points.map(p=>p[1]);return Math.max(...x)<=CUT[0]+1e-9||Math.min(...x)>=CUT[2]-1e-9||Math.max(...y)<=CUT[1]+1e-9||Math.min(...y)>=CUT[3]-1e-9;});
 const plane=P.project([1,0,0]),axesRatio=Math.abs(plane[0]/plane[1]);
 const checks={floorAtZero:floorFaces.every(f=>f.points.every(p=>p[2]===0)),noFloorInsideOpening:noFloorInside,openingIsSquare:CUT[2]-CUT[0]===CUT[3]-CUT[1],groundAxesRatio:axesRatio,insertBelowFloor:INSERT_Z<0,frameNeverAboveFloor:empty.faces.every(f=>f.points.every(p=>p[2]<=0)),widthAtGameScale:(CUT[2]-CUT[0])*256*.75,spikeHeight:.12};
 if(!checks.floorAtZero||!checks.noFloorInsideOpening||!checks.openingIsSquare||axesRatio!==2||!checks.insertBelowFloor||!checks.frameNeverAboveFloor)throw Error('Inset geometry failed');
 for(const m of models){fs.writeFileSync(path.join(DIR,m.id+'.png'),await render(m,3));const mobile=await sharp(await render(m,3)).resize(270,159).png().toBuffer();fs.writeFileSync(path.join(DIR,m.id+'-mobile.png'),mobile);}
 const W=1320,H=1030,layers=[];
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="Segoe UI,Arial,sans-serif"><rect width="${W}" height="${H}" fill="#0c121d"/><g fill="#e2e8f4"><text x="32" y="46" font-size="29">Une dalle qui accueille le piège</text><text x="32" y="80" font-size="17" fill="#a9b7cf">Wireframe de principe · grille isométrique du donjon · ouverture réelle au centre</text><text x="32" y="127" font-size="22">1. Dallage découpé</text><text x="690" y="127" font-size="22">2. Mécanisme encastré</text><text x="32" y="158" font-size="16" fill="#a9b7cf">Les pierres s’arrêtent sur le bord de la réservation.</text><text x="690" y="158" font-size="16" fill="#a9b7cf">Le support est sous le sol ; seules les pointes dépassent.</text></g>`;
 for(const [i,m] of [empty,active].entries())layers.push({input:await sharp(await render(m,3)).resize(610).png().toBuffer(),left:25+i*660,top:170});
 svg+='<line x1="32" y1="555" x2="1288" y2="555" stroke="#2b3850"/><g fill="#e2e8f4"><text x="32" y="597" font-size="22">Coupe de principe</text><text x="900" y="597" font-size="22">Sans pointes déployées</text></g>';
 // Section across the opening: floor top is the same y on both sides;
 // the receiving plate and chamber are below it, never a floating pedestal.
 svg+='<path d="M60 740H250L270 759V838H610V759L630 740H820V883H60Z" fill="#35435b" stroke="#a6b2ca" stroke-width="2"/><rect x="270" y="770" width="340" height="15" fill="#6b6a89" stroke="#b7a3d1" stroke-width="2"/><path d="M310 770L340 655L370 770M410 770L440 655L470 770M510 770L540 655L570 770" fill="#788aa5" stroke="#bdc9dc" stroke-width="2"/><line x1="45" y1="740" x2="840" y2="740" stroke="#bc8ded" stroke-width="2" stroke-dasharray="8 6"/><text x="61" y="720" font-size="16" fill="#d1b3f0">Niveau du sol</text><path d="M713 801H629L612 779" fill="none" stroke="#cbb4e7"/><text x="640" y="824" font-size="15" fill="#cbb4e7">Insert en retrait</text><text x="282" y="864" font-size="15" fill="#9aaac3">Logement du mécanisme</text>';
 layers.push({input:await sharp(await render(ready,3)).resize(390).png().toBuffer(),left:897,top:635});
 svg+='<g fill="#a9b7cf" font-size="17"><text x="32" y="946">Même réservation pour Pointes, Entrave et Néant : le contour extérieur reste celui du dallage.</text><text x="32" y="976">La texture du piège se place dans l’ouverture. Aucun cadre ou socle supplémentaire sur les pierres.</text><text x="32" y="1008" font-size="14" fill="#788ba8">Étude de géométrie proposée, non intégrée au jeu. Dimensions de l’ouverture et profondeur ajustables.</text></g></svg>';
 const board=await sharp(Buffer.from(svg)).composite(layers).png().toBuffer();fs.writeFileSync(path.join(DIR,'wireframe-board.png'),board);
 fs.writeFileSync(path.join(DIR,'geometry.json'),JSON.stringify({status:'Unapproved design study',camera:P.camera,cell:[0,0,1,1],opening:CUT,inner:INNER,depth:DEPTH,insertZ:INSERT_Z,models},null,2)+'\n');
 fs.writeFileSync(path.join(DIR,'validation.json'),JSON.stringify({kind:'Offline wireframe geometry checks; no Godot integration',checks,productionChanged:false,sourceArtworkChanged:false},null,2)+'\n');console.log(checks);
}
main().catch(e=>{console.error(e);process.exitCode=1});
