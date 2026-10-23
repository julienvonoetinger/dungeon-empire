// Offline whole-stone painting in a reusable 3x3 neighbourhood. No scene names.
const sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const {geometry}=require('./export_wireframe_cell_kit.cjs');
const {read,hash,parseLines,prepareFaces,svg,inside}=R;
const entries=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json')).entries;
const DIR=[[0,-1],[1,0],[0,1],[-1,0]],CORNERS=[[-1,-1],[1,-1],[1,1],[-1,1]],PAIRS=[[3,0],[0,1],[1,2],[2,3]];
const pos=([x,y])=>`${x},${y}`,id=(w,p,e)=>`w${('0'+w).slice(-2)}_p${('0'+p).slice(-2)}_e${('0'+e).slice(-2)}`;
const mod=x=>((x%1)+1)%1;
const round=x=>Math.round(x*100000)/100000;
const shapeCache=new Map(),maskCache=new Map();

function variant(cell,occupied,ends=0){
  const [x,y]=cell,n=DIR.reduce((n,[dx,dy],i)=>n|(occupied.has(pos([x+dx,y+dy]))?1<<i:0),0),e=ends&(15^n),w=15^(n|e);
  let p=0;
  PAIRS.forEach(([a,b],i)=>{if((n&(1<<a))&&(n&(1<<b))&&!occupied.has(pos([x+CORNERS[i][0],y+CORNERS[i][1]])))p|=1<<i;});
  return id(w,p,e);
}
function tilesFor(mask,ends=0){
  const cells=[[0,0],...[...DIR,...CORNERS].filter((_,i)=>mask&(1<<i))],occupied=new Set(cells.map(pos));
  return cells.map(([x,y])=>({x,y,id:'cells/'+variant([x,y],occupied,x===0&&y===0?ends:0)}));
}
function polygons(source,special){
  const fills=[...source.matchAll(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)].map(m=>m[0]);
  if(special)fills.shift();
  return fills.flatMap(xml=>xml.startsWith('<polygon')?[xml.match(/points="([^"]+)"/)[1].split(' ').map(p=>p.split(',').map(Number))]:xml.match(/d="([^"]*)"/)[1].split('M').filter(Boolean).map(p=>p.replace(/Z$/,'').split('L').map(p=>p.split(',').map(Number))));
}
function source(tile,anchor){
  const cacheKey=tile.id;
  if(!shapeCache.has(cacheKey)){
    const entry=entries[tile.id],special=!tile.id.startsWith('cells/');
    const file=special?`assets/dungeon/wireframe-${tile.id}.svg`:'assets/dungeon/wireframe-cells/'+tile.id.slice(6)+'.svg';
    // Special source directories are wireframe-doors and wireframe-entrances.
    const input=read(file).toString();
    shapeCache.set(cacheKey,{entry,model:makeModel(tile.id,entry),polys:polygons(input,special),lines:parseLines(input).filter(l=>!l.xml.includes('#8794a3'))});
  }
  const s=shapeCache.get(cacheKey),dx=tile.x*256+anchor[0]-s.entry.imageAnchor[0],dy=tile.y*256+anchor[1]-s.entry.imageAnchor[1];
  const point=p=>[round(p[0]+dx),round(p[1]+dy)];
  const polys=s.polys.map(ps=>ps.map(point));
  const d=polys.map(ps=>{if(ps.reduce((a,p,i)=>a+p[0]*ps[(i+1)%ps.length][1]-p[1]*ps[(i+1)%ps.length][0],0)<0)ps.reverse();return 'M'+ps.map(p=>p.join(',')).join('L')+'Z';}).join('');
  return {tile,model:s.model,polys,d,lines:s.lines.map(l=>({...l,a:point(l.a),b:point(l.b)})),surfaces:s.model.surfaces.map(f=>({...f,materialOwner:{model:s.model,offset:[tile.x,tile.y]},points:f.points.map(p=>[p[0]+tile.x,p[1]+tile.y,p[2]])}))};
}
function ink(lines){return lines.map(l=>`<line x1="${l.a[0]}" y1="${l.a[1]}" x2="${l.b[0]}" y2="${l.b[1]}" stroke="#ff00ff" stroke-width="${l.width}"/>`).join('');}
function uniqueLines(lines){
  const seen=new Set();return lines.filter(l=>{const k=JSON.stringify([...[l.a,l.b].sort((a,b)=>a[0]-b[0]||a[1]-b[1]),l.width]);if(seen.has(k))return false;seen.add(k);return true;});
}
// A neighbouring special volume can hide lines that are visible in an isolated
// guide (for example a stair behind an arch). Split at projected face boundaries
// and retain only segments whose source depth is visible in the assembled model.
function visibleContextLines(sources,model){
  R.prepareModel(model);
  const project=([x,y,z])=>[(x-.18*z)*256+model.anchor[0],(y-.9*z)*256+model.anchor[1]];
  const edges=model.surfaces.flatMap(s=>s.points.map((p,i)=>[project(p),project(s.points[(i+1)%s.points.length])]));
  const cross=(a,b)=>a[0]*b[1]-a[1]*b[0],sub=(a,b)=>a.map((v,i)=>v-b[i]),lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),visible=[];
  for(const source of sources){
    const local=R.prepareModel({...model,surfaces:source.surfaces,floor:false});
    for(const line of source.lines){
      const {a,b}=line,d=sub(b,a),len=Math.hypot(...d);if(len<1e-8)continue;
      const cuts=[0,1];
      for(const [c,f] of edges){const e=sub(f,c),den=cross(d,e);if(Math.abs(den)<1e-9)continue;const v=sub(c,a),t=cross(v,e)/den,u=cross(v,d)/den;if(t>1e-8&&t<1-1e-8&&u>=-1e-7&&u<=1+1e-7)cuts.push(t);}
      cuts.sort((a,b)=>a-b);let start=null,end=null;
      const flush=()=>{if(start!==null)visible.push({...line,a:lerp(a,b,start),b:lerp(a,b,end)});start=end=null;};
      for(let i=1;i<cuts.length;i++){
        if(cuts[i]-cuts[i-1]<1e-8)continue;
        const p=lerp(a,b,(cuts[i]+cuts[i-1])/2),normal=[-d[1]/len*.002,d[0]/len*.002];
        // At a silhouette edge sample just inside either adjoining source face.
        const probes=[p,p.map((v,i)=>v+normal[i]),p.map((v,i)=>v-normal[i])];
        const shown=probes.some(q=>{const own=R.cast(local,q),front=R.cast(model,q);return own&&(!front||front.t<=own.t+1e-6);});
        if(shown){if(start===null)start=cuts[i-1];end=cuts[i];}else flush();
      }
      flush();
    }
  }
  return uniqueLines(visible);
}
function canonicalStone(f,anchor,model){
  // Translation by a grid cell must not change the vertex order, seed or UV.
  const p=f.points.map(q=>q.map(round));let first=0;
  for(let i=1;i<p.length;i++)if(p[i][0]<p[first][0]||p[i][0]===p[first][0]&&p[i][1]<p[first][1])first=i;
  f.points=p.slice(first).concat(p.slice(0,first));
  const ox=Math.floor((Math.min(...p.map(q=>q[0]))-anchor[0]+.001)/256)*256+anchor[0],oy=Math.floor((Math.min(...p.map(q=>q[1]))-anchor[1]+.001)/256)*256+anchor[1];
  f.bevelSeed=parseInt(hash(JSON.stringify([f.kind,f.points.map(q=>[round(q[0]-ox),round(q[1]-oy)])])).slice(0,7),16)%100000;
  const hit=R.cast(model,R.probe(f.points));
  if(hit&&/wall|pillar/.test(f.part)&&/wall|pillar/.test(hit.part)){f.p=hit.p;f.part=hit.part;}
  if(f.part.includes('wall')){
    const horizontal=/north|south/.test(f.part),q=mod(f.p[horizontal?0:1]),upper=f.p[2]>=.94/6-1e-5;
    const k=Math.max(0,(upper?[0,1.6/6,3.5/6]:[0,.7/6,2.6/6,4.5/6]).filter(c=>q>=c-1e-5).length-1);
    f.materialId=['walls-planes','walls-fissures','walls-layers','walls-pits'][horizontal?(upper?[0,1,2]:[0,3,0,2])[k]:(upper?[0,3,1]:[0,2,0,3])[k]];
  }
}
function intersects(a,b){
  const bounds=p=>[Math.min(...p.map(q=>q[0])),Math.min(...p.map(q=>q[1])),Math.max(...p.map(q=>q[0])),Math.max(...p.map(q=>q[1]))];
  const A=bounds(a),B=bounds(b);if(A[2]<B[0]-.01||B[2]<A[0]-.01||A[3]<B[1]-.01||B[3]<A[1]-.01)return false;
  if(a.some(p=>inside(p,b))||b.some(p=>inside(p,a)))return true;
  const cross=(a,b)=>a[0]*b[1]-a[1]*b[0],sub=(a,b)=>[a[0]-b[0],a[1]-b[1]];
  for(let i=0;i<a.length;i++)for(let j=0;j<b.length;j++){
    const p=a[i],q=b[j],d=sub(a[(i+1)%a.length],p),e=sub(b[(j+1)%b.length],q),den=cross(d,e);if(Math.abs(den)<1e-9)continue;
    const v=sub(q,p),t=cross(v,e)/den,u=cross(v,d)/den;if(t>=-1e-6&&t<=1.000001&&u>=-1e-6&&u<=1.000001)return true;
  }
  return false;
}
function dilate(alpha,width,height,radius=8){
  const row=new Uint8Array(alpha.length),out=new Uint8Array(alpha.length),queue=new Int32Array(Math.max(width,height));
  function pass(input,output,start,stride,count){let head=0,tail=0,next=0;for(let i=0;i<count;i++){while(next<=Math.min(count-1,i+radius)){const v=input[start+next*stride];while(tail>head&&input[start+queue[tail-1]*stride]<=v)tail--;queue[tail++]=next++;}while(queue[head]<i-radius)head++;output[start+i*stride]=input[start+queue[head]*stride];}}
  for(let y=0;y<height;y++)pass(alpha,row,y*width,1,width);for(let x=0;x<width;x++)pass(row,out,x,width,height);return out;
}
async function alphaOf(size,body){
  const key=hash(body+size);if(!maskCache.has(key)){const b=await sharp(Buffer.from(svg(size,body))).ensureAlpha().extractChannel(3).raw().toBuffer();maskCache.set(key,b);if(maskCache.size>24)maskCache.delete(maskCache.keys().next().value);}
  return maskCache.get(key);
}
async function prepareContext(tiles){
  const center=tiles.find(t=>!t.x&&!t.y);if(!center)throw Error('Missing centre cell');
  const entry=entries[center.id],anchor=entry.imageAnchor,size=entry.imageSize;
  const sources=tiles.map(t=>source(t,anchor)),own=sources.find(s=>s.tile===center);
  const model={...makeModel(center.id,entry),floor:false,stableStones:true,clipPaint:true,surfaces:sources.flatMap(s=>s.surfaces),silhouette:`<path d="${sources.map(s=>s.d).join('')}" fill="#fff"/>`};
  const lines=sources.some(s=>!s.tile.id.startsWith('cells/'))?visibleContextLines(sources,model):uniqueLines(sources.flatMap(s=>s.lines)),guide=svg(size,ink(lines));
  model.resolveMaterials=fs=>fs.forEach(f=>canonicalStone(f,anchor,model));
  model.requirePartMasks=sources.some(s=>s.model.door);
  // Include full stones touching the central volume plus the filtering guard.
  const expanded=own.polys.map(p=>{const mid=p.reduce((a,b)=>a.map((v,i)=>v+b[i]/p.length),[0,0]);return p.map(q=>q.map((v,i)=>v+(v>=mid[i]?3:-3)));});
  model.filterFaces=f=>expanded.some(p=>intersects(f.points,p));
  model.renderData=await prepareFaces(model,guide);
  const whole=await alphaOf(size,model.silhouette+ink(lines));
  const base=await alphaOf(size,`<path d="${own.d}" fill="#fff"/>`+ink(own.lines)),width=size[0]*4,height=size[1]*4,guard=dilate(base,width,height),target=Buffer.alloc(width*height*4,255);
  let guardPixels=0,contourOwnershipPixels=0;
  // On the common contour one owner carries the geometric coverage. Opaque
  // interior guard pixels may overlap because their complete-stone RGB agrees.
  const otherMasks=[];
  for(const s of sources)if(s!==own)otherMasks.push({s,a:await alphaOf(size,`<path d="${s.d}" fill="#fff"/>`+ink(s.lines))});
  for(let k=0;k<base.length;k++){
    let alpha=base[k];
    if(whole[k]===255&&guard[k]>alpha){alpha=guard[k];guardPixels++;}
    else if(whole[k]>0&&whole[k]<255&&alpha){
      let owner=own,max=alpha;
      for(const {s,a} of otherMasks)if(a[k]>max||(a[k]===max&&(s.tile.y<owner.tile.y||s.tile.y===owner.tile.y&&s.tile.x<owner.tile.x))){owner=s;max=a[k];}
      const next=owner===own?whole[k]:0;if(alpha!==next)contourOwnershipPixels++;alpha=next;
    }
    target[k*4+3]=alpha;
  }
  model.alphaMask=target;
  const relevantLines=lines.filter(l=>expanded.some(p=>intersects([l.a,l.b],p)));
  const painting={faces:model.renderData.faces.map(f=>[f.points,f.kind,f.materialId,f.bevelSeed,f.partMask]),lines:relevantLines.map(l=>[l.a,l.b,l.width]).sort(),alpha:hash(target)};
  if(model.renderData.visibility){
    const v=model.renderData.visibility;
    painting.visibility=[v.parts,hash(Buffer.from(v.tags))];
    painting.woodFrames=model.renderData.faces.filter(f=>f.kind==='wood').map(f=>{
      const o=f.surface.materialOwner;
      return [[0,0,0],[1,0,0],[0,1,0],[0,0,1]].map(p=>o.model.forward(p).map((x,i)=>round(x+(o.offset[i]||0))));
    });
  }
  const signature=hash(JSON.stringify(painting));
  return {model,guide,signature,report:{policy:'Local 3x3 whole stones; stable periodic stone identity; 2px opaque filter guard; single contour owner.',context:tiles,guardPixels,contourOwnershipPixels,alphaSha256:hash(target),faceCount:model.renderData.faces.length}};
}
module.exports={tilesFor,variant,prepareContext,DIR,CORNERS,id};
