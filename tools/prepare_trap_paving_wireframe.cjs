// Isolated, unapproved geometry study. This does not export any game asset.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const P = require('./isometric_paint_geometry.cjs');
const Floor = require('./isometric_floor_variants.cjs');

const OUT = path.join(P.ROOT, 'docs/reference/trap-review/v10-paving-wireframe');
const HOLE = [.22, .22, .78, .78];
const round = v => +v.toFixed(8);
const key = p => p.map(round).join(',');
const rectKey = r => r.map(round).join(',');
const rectPoly = ([x, X, y, Y]) => [[x,y],[X,y],[X,Y],[x,Y]];
const cross = (a,b,c) => (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
const area = ps => Math.abs(ps.reduce((s,p,i) => {
  const q=ps[(i+1)%ps.length]; return s+p[0]*q[1]-p[1]*q[0];
},0))/2;

// Each replacement is the INSIDE portion of an existing boundary-crossing
// stone. Its outside portion belongs to the same complete stone, not a trim.
// The twelve pieces together cover the entire cell except the square socket.
const replacements = [
  {rect:[-.15,.18,-.16,.16], inside:[[0,0],[.18,0],[.22,.22],[0,.16]]},
  {rect:[.18,.52,-.16,.16], inside:[[.18,0],[.52,0],[.52,.22],[.22,.22]]},
  {rect:[.52,.85,-.16,.16], inside:[[.52,0],[.85,0],[.78,.22],[.52,.22]]},
  {rect:[.85,1.18,-.16,.16], inside:[[.85,0],[1,0],[1,.16],[.78,.22]]},
  {rect:[-.16,.16,.16,.50], inside:[[0,.16],[.22,.22],[.22,.50],[0,.50]]},
  {rect:[.84,1.16,.16,.50], inside:[[.78,.22],[1,.16],[1,.50],[.78,.50]]},
  {rect:[-.08,.28,.50,.84], inside:[[0,.50],[.22,.50],[.22,.78],[0,.84]]},
  {rect:[.92,1.28,.50,.84], inside:[[.78,.50],[1,.50],[1,.84],[.78,.78]]},
  {rect:[-.15,.18,.84,1.16], inside:[[0,.84],[.22,.78],[.18,1],[0,1]]},
  {rect:[.18,.52,.84,1.16], inside:[[.22,.78],[.52,.78],[.52,1],[.18,1]]},
  {rect:[.52,.85,.84,1.16], inside:[[.52,.78],[.78,.78],[.85,1],[.52,1]]},
  {rect:[.85,1.18,.84,1.16], inside:[[.78,.78],[1,.84],[1,1],[.85,1]]},
];

function outsideCell([x,X,y,Y]) {
  const a=Math.max(0,x), A=Math.min(1,X), b=Math.max(0,y), B=Math.min(1,Y);
  return [[x,a,y,Y],[A,X,y,Y],[a,A,y,b],[a,A,B,Y]]
    .filter(r=>r[1]-r[0]>1e-8 && r[3]-r[2]>1e-8).map(rectPoly);
}

// Split collinear edges at all shared endpoints before canceling internal
// fragment edges. Thus no logical-cell boundary is drawn through a stone.
function boundary(polys) {
  const allPoints=polys.flat(), edges=new Map();
  for(const poly of polys)for(let i=0;i<poly.length;i++) {
    const a=poly[i],b=poly[(i+1)%poly.length],d=[b[0]-a[0],b[1]-a[1]],l=d[0]**2+d[1]**2;
    const splits=new Map([[0,a],[1,b]]);
    for(const p of allPoints) {
      const t=((p[0]-a[0])*d[0]+(p[1]-a[1])*d[1])/l;
      if(t>1e-8&&t<1-1e-8&&Math.abs(cross(a,b,p))<1e-8)splits.set(round(t),p);
    }
    const points=[...splits].sort((a,b)=>a[0]-b[0]).map(p=>p[1]);
    for(let j=1;j<points.length;j++) {
      const e=[points[j-1],points[j]],k=e.map(key).sort().join('|');
      if(edges.has(k))edges.delete(k);else edges.set(k,e);
    }
  }
  return [...edges.values()];
}

function outline(polys) {
  const edges=boundary(polys), result=[edges[0][0]], unused=edges.slice();
  while(unused.length) {
    const last=result.at(-1),i=unused.findIndex(e=>e.some(p=>key(p)===key(last)));
    if(i<0)throw Error('Disconnected paving stone');
    const e=unused.splice(i,1)[0],next=key(e[0])===key(last)?e[1]:e[0];
    result.push(next);
  }
  if(key(result[0])!==key(result.at(-1)))throw Error('Open stone outline');
  result.pop();
  return result.filter((p,i,ps)=>Math.abs(cross(ps[(i+ps.length-1)%ps.length],p,ps[(i+1)%ps.length]))>1e-8);
}

function build() {
  const stones=new Map(), local=Floor.geometry(1).stones;
  for(let y=-1;y<=1;y++)for(let x=-1;x<=1;x++)for(const s of local) {
    const r=s.rect.map((v,i)=>round(v+(i<2?x:y)));
    const k=rectKey(r);if(!stones.has(k))stones.set(k,{id:k,seed:s.seed,points:rectPoly(r),modified:false});
  }
  // All four former inner slabs are removed, not hidden under a frame.
  const removed=[];
  for(const s of local)if(s.rect[0]>=0&&s.rect[1]<=1&&s.rect[2]>=0&&s.rect[3]<=1) {
    removed.push(rectKey(s.rect));stones.delete(rectKey(s.rect));
  }
  for(const r of replacements) {
    const k=rectKey(r.rect),old=stones.get(k);if(!old)throw Error('Missing source stone '+k);
    old.points=outline([...outsideCell(r.rect),r.inside]);old.modified=true;
  }
  return {stones:[...stones.values()],removed};
}

function contains(ps,[x,y]) {
  let c=false;for(let i=0,j=ps.length-1;i<ps.length;j=i++) {
    const a=ps[i],b=ps[j];
    if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])c=!c;
  }return c;
}
function clip(poly,axis,value,greater) {
  const out=[];for(let i=0;i<poly.length;i++) {
    const a=poly[i],b=poly[(i+1)%poly.length],A=greater?a[axis]>=value:a[axis]<=value,B=greater?b[axis]>=value:b[axis]<=value;
    if(A)out.push(a);
    if(A!==B){const t=(value-a[axis])/(b[axis]-a[axis]);out.push(a.map((v,k)=>v+t*(b[k]-v)));}
  }return out;
}
function insideRect(poly,[x,X,y,Y]) {for(const [a,v,g]of [[0,x,true],[0,X,false],[1,y,true],[1,Y,false]])poly=clip(poly,a,v,g);return poly;}

function check(model) {
  const sum=replacements.reduce((s,r)=>s+area(r.inside),0),expected=1-(HOLE[2]-HOLE[0])**2;
  if(Math.abs(sum-expected)>1e-8)throw Error('Wrong paving area');
  for(let i=0;i<replacements.length;i++) {
    const a=replacements[i].inside;
    if(area(insideRect(a,[.22,.78,.22,.78]))>1e-8)throw Error('Stone intersects opening');
    for(let j=0;j<i;j++) {
      let overlap=a;
      const b=replacements[j].inside;
      // Convex clipping against every edge of the other paving polygon.
      for(let e=0;e<b.length;e++) {
        const p=b[e],q=b[(e+1)%b.length],next=[];
        for(let t=0;t<overlap.length;t++) {
          const u=overlap[t],v=overlap[(t+1)%overlap.length],du=cross(p,q,u),dv=cross(p,q,v);
          if(du>=-1e-9)next.push(u);
          if((du>0&&dv<0)||(du<0&&dv>0)){const f=du/(du-dv);next.push(u.map((n,k)=>n+f*(v[k]-n)));}
        }overlap=next;
      }
      if(area(overlap)>1e-8)throw Error('Overlapping new paving stones');
    }
  }
  let probes=0;
  for(const r of replacements) {
    const s=model.stones.find(s=>s.id===rectKey(r.rect));
    // Fine samples confirm the complete outline equals the designed union,
    // including the parts extending into neighbouring logical cells.
    for(let y=-.18+.0017;y<1.29;y+=.007)for(let x=-.18+.0023;x<1.29;x+=.007) {
      const inside=x>0&&x<1&&y>0&&y<1;
      const expected=inside?contains(r.inside,[x,y]):contains(rectPoly(r.rect),[x,y]);
      if(contains(s.points,[x,y])!==expected)throw Error('Changed neighbour geometry '+s.id);
      probes++;
    }
  }
  return {completeReshapedStones:12,removedInteriorStones:model.removed.length,pavingArea:round(sum),openingArea:.56**2,overlappingPieces:0,neighbourAgreementProbes:probes,planeZ:0,groundProjectionRatio:2,productionIntegration:false};
}

const xml=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;');
function world(model,map,{crop=[-1,2,-1,2],grid=false,id='view'}={}) {
  const pp=ps=>ps.map(p=>map(p).map(round).join(',')).join(' ');
  const cropPoints=rectPoly(crop);
  let svg=`<defs><clipPath id="${id}"><polygon points="${pp(cropPoints)}"/></clipPath></defs><g clip-path="url(#${id})" stroke-linejoin="round">`;
  for(const s of model.stones)svg+=`<polygon points="${pp(s.points)}" fill="${s.modified?'#354c60':'#202d3e'}" stroke="${s.modified?'#a1cbd8':'#657389'}" stroke-width="${s.modified?1.5:1.1}"/>`;
  svg+=`<polygon points="${pp(rectPoly([.22,.78,.22,.78]))}" fill="#111520" stroke="#c6a0e8" stroke-width="2.4"/>`;
  if(grid)for(const axis of[0,1])for(let v=-1;v<=2;v++) {
    const a=axis===0?[v,-1]:[-1,v],b=axis===0?[v,2]:[2,v];
    svg+=`<polyline points="${pp([a,b])}" fill="none" stroke="#c6a665" stroke-opacity=".55" stroke-width="1" stroke-dasharray="5 5"/>`;
  }
  return svg+'</g>';
}

async function main(){
  fs.mkdirSync(OUT,{recursive:true});
  const model=build(),checks=check(model);
  const iso=p=>{const q=P.project([...p,0]);return [520+q[0]*1.22,350+q[1]*1.22];};
  const top=p=>[1110+(p[0]+.24)*260,215+(p[1]+.24)*260];
  let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1560" height="930" font-family="Segoe UI,Arial,sans-serif"><rect width="1560" height="930" fill="#0c111b"/><g fill="#e6eaf3"><text x="40" y="54" font-size="30">Repenser les pierres autour du piège</text><text x="40" y="88" font-size="18" fill="#a9b6c9">Wireframe proposé · aucune texture · projection isométrique du jeu</text><text x="40" y="147" font-size="22">Raccords avec les cases voisines</text><text x="1080" y="147" font-size="22">Vue de dessus</text><text x="1080" y="178" font-size="15" fill="#a9b6c9">Pointillés : limites des cases, pas des joints.</text></g>`;
  svg+=world(model,iso,{id:'iso'})+world(model,top,{crop:[-.24,1.24,-.24,1.24],grid:true,id:'top'});
  const centre=iso([.5,.5]);
  svg+=`<g fill="#d8c0ef" text-anchor="middle" font-size="15"><text x="${centre[0]}" y="${centre[1]-4}">Logement</text><text x="${centre[0]}" y="${centre[1]+17}">du piège</text></g>`;
  svg+='<g fill="#a9b6c9" font-size="16"><text x="1080" y="650">La pierre traverse la limite de la case.</text><text x="1080" y="675">Son contour intérieur rejoint le piège.</text></g>';
  svg+='<line x1="40" y1="740" x2="1520" y2="740" stroke="#2c394d"/><g fill="#e6eaf3" font-size="21"><text x="40" y="787">12 pierres redessinées d’un seul tenant</text><text x="810" y="787">Un seul niveau de sol</text></g><g fill="#a9b6c9" font-size="18"><text x="40" y="822">Elles prolongent les pierres voisines jusqu’au carré central.</text><text x="40" y="851">Les quatre anciennes dalles intérieures sont retirées.</text><text x="810" y="822">Le logement reste au même emplacement et à la même taille.</text><text x="810" y="851">Les côtés légèrement biaisés sont des coupes de pierre proposées.</text><text x="40" y="899" font-size="15" fill="#8393ad">Étude à valider avant les textures. Le jeu et les sprites actuels ne sont pas modifiés par cette proposition.</text></g></svg>';
  fs.writeFileSync(path.join(OUT,'wireframe-board.svg'),svg);
  fs.writeFileSync(path.join(OUT,'wireframe-board.png'),await sharp(Buffer.from(svg)).png().toBuffer());
  const detailMap=p=>{const q=P.project([...p,0]);return[600+q[0]*2.7,230+q[1]*2.7];};
  const detail=`<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800"><rect width="1200" height="800" fill="#0c111b"/>${world(model,detailMap,{crop:[-.3,1.3,-.3,1.3],id:'detail'})}</svg>`;
  fs.writeFileSync(path.join(OUT,'wireframe-detail.png'),await sharp(Buffer.from(detail)).png().toBuffer());
  fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify({status:'Proposed wireframe; not integrated or approved',camera:P.camera,opening:HOLE,planeZ:0,replacements,model},null,2)+'\n');
  fs.writeFileSync(path.join(OUT,'validation.json'),JSON.stringify(checks,null,2)+'\n');
  fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><meta charset="utf-8"><title>Pièges — wireframe du dallage</title><style>body{margin:0;padding:24px;background:#0c111b;color:#dfe8f6;font:16px system-ui}img{display:block;max-width:100%;height:auto;margin:auto}a{color:#b4cfee}p{max-width:1000px;margin:18px auto}</style><img src="wireframe-board.png" alt="Pierres complètes autour du carré central, vues en isométrie et de dessus"><p><a href="wireframe-detail.png">Agrandir le détail</a> · <a href="geometry.json">Géométrie</a> · <a href="validation.json">Vérifications</a></p><p>${xml('Proposition de wireframe uniquement. Les contours de pierre en bleu clair sont redessinés depuis les cases voisines jusqu’au logement du piège. La pente de certains joints est une proposition de découpe, à valider avant les textures.')}</p>`);
  console.log(JSON.stringify(checks,null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
