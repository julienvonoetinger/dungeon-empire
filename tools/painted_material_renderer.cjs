// Shared OFFLINE material compositor. Architectural edges are copied from the
// approved guide; no scene/runtime rendering or generative geometry here.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {stoneFinish}=require('./stone_edge_finish.cjs');
const ROOT=path.resolve(__dirname,'..'),SCALE=4;
const read=p=>fs.readFileSync(path.join(ROOT,p));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const finish=JSON.parse(read('assets/dungeon/shared-materials/stone-finish.json'));
const body=s=>s.replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
const sub=(a,b)=>a.map((v,i)=>v-b[i]),dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const cross=(a,b)=>a[0]*b[1]-a[1]*b[0],cross3=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),dist=(a,b)=>Math.hypot(...sub(a,b));
const area=p=>p.reduce((s,a,i)=>s+cross(a,p[(i+1)%p.length]),0)/2;
const inside=(p,ps)=>{let yes=false;for(let i=0,j=ps.length-1;i<ps.length;j=i++){const a=ps[i],b=ps[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])yes=!yes;}return yes;};
const polygon=(p,a='')=>`<polygon points="${p.map(q=>q.join(',')).join(' ')}" ${a}/>`;
const svg=(size,b)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${size[0]*SCALE}" height="${size[1]*SCALE}" viewBox="0 0 ${size.join(' ')}">${b}</svg>`;
function parseLines(guide){return [...guide.matchAll(/<line\b[^>]*\/>/g)].map(([xml])=>{const a=Object.fromEntries([...xml.matchAll(/([\w-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));return {a:[+a.x1,+a.y1],b:[+a.x2,+a.y2],width:+a['stroke-width'],xml};});}
function regionsFromLines(lines){
  const vertices=[],edges=new Set();
  const vertex=p=>{let k=vertices.findIndex(q=>dist(p,q)<.00015);if(k<0){k=vertices.length;vertices.push(p);}return k;};
  for(const l of lines){const d=sub(l.b,l.a),l2=dot(d,d);if(l2<1e-12)continue;const cuts=[0,1];
    for(const m of lines){const e=sub(m.b,m.a),den=cross(d,e),v=sub(m.a,l.a);
      if(Math.abs(den)>1e-10){const t=cross(v,e)/den,u=cross(v,d)/den;if(t>1e-8&&t<1-1e-8&&u>=-1e-6&&u<=1+1e-6)cuts.push(t);}
      else if(Math.abs(cross(v,d))<.00015){for(const p of [m.a,m.b]){const t=dot(sub(p,l.a),d)/l2;if(t>0&&t<1)cuts.push(t);}}
    }
    cuts.sort((a,b)=>a-b);for(let i=1;i<cuts.length;i++){const a=vertex(lerp(l.a,l.b,cuts[i-1])),b=vertex(lerp(l.a,l.b,cuts[i]));if(a!==b)edges.add([a,b].sort((a,b)=>a-b).join(':'));}
  }
  const ns=vertices.map(()=>[]);for(const e of edges){const [a,b]=e.split(':').map(Number);ns[a].push(b);ns[b].push(a);}
  for(let i=0;i<ns.length;i++)ns[i].sort((a,b)=>Math.atan2(vertices[a][1]-vertices[i][1],vertices[a][0]-vertices[i][0])-Math.atan2(vertices[b][1]-vertices[i][1],vertices[b][0]-vertices[i][0]));
  const seen=new Set(),regions=[];
  for(let u=0;u<ns.length;u++)for(const v of ns[u]){if(seen.has(`${u}:${v}`))continue;let a=u,b=v,p=[];
    for(let guard=0;guard<lines.length*8;guard++){const k=`${a}:${b}`;if(seen.has(k))break;seen.add(k);p.push(vertices[a]);const adj=ns[b],c=adj[(adj.indexOf(a)-1+adj.length)%adj.length];a=b;b=c;if(a===u&&b===v)break;}
    if(area(p)>.0001){p=p.filter((b,i)=>Math.abs(cross(sub(b,p[(i-1+p.length)%p.length]),sub(p[(i+1)%p.length],b)))>.00001);if(p.length>=3)regions.push(p);}
  }
  return regions.sort((a,b)=>area(b)-area(a));
}
function probe(p){for(let i=0;i<p.length;i++){const a=p[i],b=p[(i+1)%p.length],d=sub(b,a),n=Math.hypot(...d);if(n<.1)continue;const q=[(a[0]+b[0])/2-d[1]/n*.025,(a[1]+b[1])/2+d[0]/n*.025];if(inside(q,p))return q;}return p.reduce((a,b)=>a.map((v,i)=>v+b[i]/p.length),[0,0]);}
const ray=[.18,.9,1];
function triangleHit(origin,a,b,c){const e1=sub(b,a),e2=sub(c,a),p=cross3(ray,e2),det=dot(e1,p);if(Math.abs(det)<1e-11)return null;const tvec=sub(origin,a),u=dot(tvec,p)/det;if(u<-.000001||u>1.000001)return null;const q=cross3(tvec,e1),v=dot(ray,q)/det;if(v<-.000001||u+v>1.000001)return null;const t=dot(e2,q)/det;if(t<-1e-8)return null;const n=cross3(e1,e2),len=Math.hypot(...n);return {t,normal:n.map(v=>v/len)};}
function prepareModel(model){model.triangles=model.surfaces.flatMap(s=>s.points.slice(1,-1).map((_,i)=>({a:s.points[0],b:s.points[i+1],c:s.points[i+2],surface:s})));return model;}
function cast(model,p){const origin=[(p[0]-model.anchor[0])/256,(p[1]-model.anchor[1])/256,0];let best=null;
  for(const tri of model.triangles){const h=triangleHit(origin,tri.a,tri.b,tri.c);if(h&&(!best||h.t>best.t+1e-8))best={...h,part:tri.surface.part,index:tri.surface.index,p:origin.map((v,i)=>v+ray[i]*h.t),surface:tri.surface};}
  if(!best&&model.floor&&origin[0]>=-1e-6&&origin[0]<=1.000001&&origin[1]>=-1e-6&&origin[1]<=1.000001)best={t:0,part:'floor',normal:[0,0,1],p:origin};
  if(best&&dot(best.normal,ray)<0)best.normal=best.normal.map(v=>-v);
  return best;
}
const slot=(q,upper)=>(upper?[0,1.6/6,3.5/6]:[0,.7/6,2.6/6,4.5/6]).filter(x=>q>=x-1e-5).length-1;
const wallIds=['walls-planes','walls-fissures','walls-layers','walls-pits'];
const floorSource=JSON.parse(read('docs/reference/floor-periodic-cell.json')).floor;
const floorRows=[0];for(const h of floorSource.rowHeights)floorRows.push(floorRows.at(-1)+h/5);
const oldFaces=JSON.parse(read('docs/reference/nw-material-review-v2/validation.json')).faces;
function floorKey(p){const count=floorSource.rowHeights.length;let r=floorRows.findIndex((y,i)=>i<count&&p[1]>=y-1e-7&&p[1]<floorRows[i+1]-1e-7);if(r<0)r=p[1]<0?0:count-1;let x=0,c=0;for(const w of floorSource.rowWidths[r]){x+=w/6;if(p[0]<x-1e-7)break;c++;}return `${r}:${c}`;}
const floorMap=new Map(oldFaces.filter(f=>f.kind==='floor').map(f=>{const p=probe(f.points);return [floorKey([(p[0]-24)/256,(p[1]-88)/256]),f.materialId];}));
function classify(model,p){const h=cast(model,p);if(!h)return null;const n=h.normal,top=n[2]>.7;
  let kind=top?'top':Math.abs(n[0])>Math.abs(n[1])?'west':'north',materialId;
  if(h.part==='floor'){kind='floor';materialId=model.floorMaterialPattern?.[floorKey(h.p)]||floorMap.get(floorKey(h.p))||'floors-calm';}
  else if(h.part==='step'){kind=top?'floor':kind;materialId=top?'floors-worn':'walls-planes';}
  else if(h.part==='closed-door'){
    const owner=h.surface.materialOwner||{model,offset:[0,0]},materialModel=owner.model;
    const local=materialModel.inverse(h.p.map((v,i)=>v-(owner.offset[i]||0))),d=materialModel.door;
    const metal=Math.abs(local[1]-d.yMin)<1e-5||Math.abs(local[1]-d.yMax)<1e-5;
    const onBand=metal&&d.bands.some(b=>local[0]>b.x0-1e-6&&local[0]<b.x1+1e-6&&Math.abs(local[2]-b.z)<b.half+1e-6);
    const onHandle=metal&&Math.hypot(local[0]-d.handle.x,local[2]-d.handle.z)<d.handle.radius+1e-6;
    kind=onBand||onHandle?'metal':'wood';materialId=kind==='wood'?'door-oak':'door-iron';
  }else if(h.part==='arch'){materialId=wallIds[Math.floor((h.index-2)/8)%4];}
  else if(h.part==='pillar'){materialId='walls-planes';}
  else {const axis=/north|south/.test(h.part)?'north':'west',q=h.p[axis==='north'?0:1],upper=h.p[2]>=.94/6-1e-5,k=Math.max(0,Math.min(upper?2:3,slot(q,upper)));materialId=wallIds[axis==='north'?(upper?[0,1,2]:[0,3,0,2])[k]:(upper?[0,3,1]:[0,2,0,3])[k]];}
  return {...h,kind,materialId};
}
const textureCache=new Map();
async function visiblePartMasks(model){
  // A guide is line art, not necessarily a watertight material subdivision.
  // Rasterize source 3D triangles to keep wood, arch, wall and floor separate
  // even where touching volumes do not have an inked intersection line.
  const width=model.size[0]*SCALE,height=model.size[1]*SCALE,depth=new Float32Array(width*height).fill(-Infinity),tags=new Uint8Array(width*height),parts=['void','floor',...new Set(model.surfaces.map(s=>s.part))];
  const project=([x,y,z])=>[((x-.18*z)*256+model.anchor[0])*SCALE,((y-.9*z)*256+model.anchor[1])*SCALE,z];
  if(model.floor)for(let y=model.anchor[1]*SCALE;y<(model.anchor[1]+256)*SCALE;y++)for(let x=model.anchor[0]*SCALE;x<(model.anchor[0]+256)*SCALE;x++){const k=y*width+x;depth[k]=0;tags[k]=1;}
  for(const tri of model.triangles){
    const a=project(tri.a),b=project(tri.b),c=project(tri.c),den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);if(Math.abs(den)<1e-10)continue;
    const minx=Math.max(0,Math.floor(Math.min(a[0],b[0],c[0]))),maxx=Math.min(width-1,Math.ceil(Math.max(a[0],b[0],c[0]))),miny=Math.max(0,Math.floor(Math.min(a[1],b[1],c[1]))),maxy=Math.min(height-1,Math.ceil(Math.max(a[1],b[1],c[1]))),tag=parts.indexOf(tri.surface.part);
    for(let y=miny;y<=maxy;y++)for(let x=minx;x<=maxx;x++){
      const u=((b[1]-c[1])*(x+.5-c[0])+(c[0]-b[0])*(y+.5-c[1]))/den,v=((c[1]-a[1])*(x+.5-c[0])+(a[0]-c[0])*(y+.5-c[1]))/den,w=1-u-v;if(u<-.000001||v<-.000001||w<-.000001)continue;
      const z=u*a[2]+v*b[2]+w*c[2],k=y*width+x;if(z>depth[k]+1e-7){depth[k]=z;tags[k]=tag;}
    }
  }
  let defs='';
  for(let tag=1;tag<parts.length;tag++){
    const pixels=Buffer.alloc(width*height);for(let k=0;k<tags.length;k++)if(tags[k]===tag)pixels[k]=255;
    const png=await sharp(pixels,{raw:{width,height,channels:1}}).png().toBuffer();
    defs+=`<mask id="part-${tag}" maskUnits="userSpaceOnUse" x="0" y="0" width="${model.size[0]}" height="${model.size[1]}"><image href="data:image/png;base64,${png.toString('base64')}" width="${model.size[0]}" height="${model.size[1]}"/></mask>`;
  }
  return {width,height,tags,parts,defs};
}
function regionPartProbes(points,visibility){
  const {width,height,tags}=visibility,center=points.reduce((a,b)=>a.map((v,i)=>v+b[i]/points.length),[0,0]),found=new Map();
  const minx=Math.max(0,Math.floor(Math.min(...points.map(p=>p[0]))*SCALE)),maxx=Math.min(width-1,Math.ceil(Math.max(...points.map(p=>p[0]))*SCALE)),miny=Math.max(0,Math.floor(Math.min(...points.map(p=>p[1]))*SCALE)),maxy=Math.min(height-1,Math.ceil(Math.max(...points.map(p=>p[1]))*SCALE));
  for(let y=miny;y<=maxy;y++)for(let x=minx;x<=maxx;x++){
    const tag=tags[y*width+x];if(!tag)continue;const point=[(x+.5)/SCALE,(y+.5)/SCALE];if(!inside(point,points))continue;
    // Coplanar wall/pier boundaries can pass exactly through a pixel centre.
    // Choose a sample inside the raster part, not its ambiguous shared edge.
    const k=y*width+x,interior=x>0&&y>0&&x+1<width&&y+1<height&&tags[k-1]===tag&&tags[k+1]===tag&&tags[k-width]===tag&&tags[k+width]===tag;
    const distance=dot(sub(point,center),sub(point,center)),old=found.get(tag);
    if(!old||(interior&&!old.interior)||(interior===old.interior&&distance<old.distance))found.set(tag,{point,distance,interior});
  }
  return [...found].map(([tag,{point}])=>({point,tag}));
}
function floorMaskEdges(model){
  if(!model.floor)return [];
  const project=([x,y,z])=>[(x-.18*z)*256+model.anchor[0],(y-.9*z)*256+model.anchor[1]];
  const blockers=model.surfaces.flatMap(s=>s.points.map((p,i)=>[project(p),project(s.points[(i+1)%s.points.length])]));
  const corners=[[0,0],[1,0],[1,1],[0,1]].map(([x,y])=>project([x,y,0])),edges=[];
  for(let i=0;i<4;i++){
    const a=corners[i],b=corners[(i+1)%4],d=sub(b,a),cuts=[0,1];
    for(const [c,f] of blockers){const e=sub(f,c),den=cross(d,e);if(Math.abs(den)<1e-9)continue;const v=sub(c,a),t=cross(v,e)/den,u=cross(v,d)/den;if(t>0&&t<1&&u>=0&&u<=1)cuts.push(t);}
    cuts.sort((a,b)=>a-b);
    for(let j=1;j<cuts.length;j++)if(cuts[j]-cuts[j-1]>1e-7){const hit=cast(model,lerp(a,b,(cuts[j-1]+cuts[j])/2));if(hit&&hit.t<1e-7)edges.push({a:lerp(a,b,cuts[j-1]),b:lerp(a,b,cuts[j])});}
  }
  return edges;
}
function wrapFloorFaces(model,faces){
  // A connected cell boundary is a cut through a slab, not a stone edge.
  // Paint both boundary fragments from the same FULL slab in periodic world
  // coordinates. Its bevels are then outside the cell and its UVs meet exactly.
  const x0=model.anchor[0],pitch=256,eps=.0001;
  const bounds=f=>({x0:Math.min(...f.points.map(p=>p[0])),x1:Math.max(...f.points.map(p=>p[0])),y0:Math.min(...f.points.map(p=>p[1])),y1:Math.max(...f.points.map(p=>p[1]))});
  const candidates=faces.filter(f=>f.part==='floor').map(f=>({f,b:bounds(f)}));
  const left=candidates.filter(({b})=>Math.abs(b.x0-x0)<eps);
  for(const [row,{f:a,b:ab}] of left.entries()){
    const match=candidates.find(({b})=>Math.abs(b.x1-x0-pitch)<eps&&Math.abs(b.y0-ab.y0)<eps&&Math.abs(b.y1-ab.y1)<eps);
    if(!match)throw Error(`${model.id}: missing paired floor fragment at y=${ab.y0}`);
    const {f:b,b:bb}=match,lo=bb.x0-pitch,hi=ab.x1;
    for(const [f,offset] of [[a,0],[b,pitch]]){
      f.points=[[lo+offset,ab.y0],[hi+offset,ab.y0],[hi+offset,ab.y1],[lo+offset,ab.y1]];
      f.materialId=a.materialId;
      f.bevelSeed=100+row;
    }
  }
}
async function prepareFaces(model,guide){
  // Open floor edges may be uninked in the source (notably lateral doors).
  // Close their MATERIAL masks using visible world boundaries, never by adding
  // strokes or fitting a silhouette to painted pixels.
  prepareModel(model);const lines=parseLines(guide),maskEdges=floorMaskEdges(model),regions=regionsFromLines([...parseLines(model.paintGuide||guide),...maskEdges]),faces=[],visibility=model.door||model.requirePartMasks?await visiblePartMasks(model):null;
  for(const points of regions){
    const samples=visibility?regionPartProbes(points,visibility):[{point:probe(points)}];
    for(const {point,tag} of samples){const h=classify(model,point);if(h){if(visibility&&visibility.parts[tag]!==h.part)throw Error(`${model.id}: visibility/material identity mismatch at ${point}: ${visibility.parts[tag]} / ${h.part}`);faces.push({points,probe:point,partMask:tag,...h});}}
  }
  // Offline review assemblies can assign one material identity per complete
  // stone in their wider coordinate frame. Normal cell exports keep defaults.
  if(model.resolveMaterials)model.resolveMaterials(faces);
  if(model.wrapFloorX)wrapFloorFaces(model,faces);
  // A concave corner's top and upper facade belong to the same physical stone.
  for(const f of faces.filter(f=>f.kind!=='top'&&/wall/.test(f.part)&&f.p[2]>=.94/6-1e-5)){
    const p=f.p.map((v,i)=>i===2?1.88/6:v-f.normal[i]*.0001),screen=[(p[0]-.18*p[2])*256+model.anchor[0],(p[1]-.9*p[2])*256+model.anchor[1]];
    const cap=faces.find(t=>t.kind==='top'&&inside(screen,t.points));if(cap)f.materialId=cap.materialId;
  }
  if(model.filterFaces) return {lines,visibility,faces:faces.filter(model.filterFaces)};
  return {lines,visibility,faces};
}
async function render(model,guide,materials){
  // A review may override the floor finish without changing active wall B.
  const floorFinish=model.floorFinish?{...finish,...model.floorFinish}:finish;
  const frame=model.outputFrame||[0,0,...model.size],canvas=frame.slice(2).map(v=>v*SCALE),anchor=model.anchor.map((v,i)=>(v-frame[i])*SCALE);
  const document=b=>`<svg xmlns="http://www.w3.org/2000/svg" width="${canvas[0]}" height="${canvas[1]}" viewBox="${frame.join(' ')}">${b}</svg>`;
  const {lines,visibility,faces}=model.renderData||await prepareFaces(model,guide);
  const profiles=materials.renderProfile;
  let defs='<defs>'+(visibility?.defs||'')+(model.clipPaint?`<clipPath id="connected-shape">${model.silhouette}</clipPath>`:''),paint='',bevels='',softPaint='',omittedFinishEdges=0;const used=new Set();
  for(let id=0;id<faces.length;id++){
    const f=faces[id],p=f.points,s=profiles[f.kind],clip=`f${id}`,key=`${f.kind}-${f.materialId}`;
    if(!textureCache.has(key)){const src=read('assets/dungeon/shared-materials/'+materials.entries[f.materialId].file);textureCache.set(key,(await sharp(src).modulate({brightness:s.brightness,saturation:s.saturation??.98}).blur(s.blur).png().toBuffer()).toString('base64'));}
    if(!used.has(key)){defs+=`<image id="t-${key}" href="data:image/png;base64,${textureCache.get(key)}" width="350" height="350" preserveAspectRatio="none"/>`;used.add(key);}
    defs+=`<clipPath id="${clip}">${polygon(p)}</clipPath>`;
    const minx=Math.min(...p.map(q=>q[0])),miny=Math.min(...p.map(q=>q[1])),maxx=Math.max(...p.map(q=>q[0])),maxy=Math.max(...p.map(q=>q[1]));
    const span=Math.max(maxx-minx,maxy-miny)*1.15,tx=minx-span*.065,ty=miny-span*.065;
    const mask=f.partMask?`mask="url(#part-${f.partMask})"`:'',bevelStart=bevels.length;
    let textureTransform=`translate(${tx} ${ty}) scale(${span/350})`;
    if(f.kind==='wood'){
      const owner=f.surface.materialOwner||{model,offset:[0,0]},materialModel=owner.model;
      const d=materialModel.door,local=materialModel.inverse(f.p.map((v,i)=>v-(owner.offset[i]||0))),y=Math.abs(local[1]-d.yMin)<Math.abs(local[1]-d.yMax)?d.yMin:d.yMax,z=Math.max(...d.profileXZ.map(p=>p[1]));
      const project=p=>{const [x,y,z]=materialModel.forward(p).map((v,i)=>v+(owner.offset[i]||0));return [(x-.18*z)*256+model.anchor[0],(y-.9*z)*256+model.anchor[1]];};
      const a=project([1/6,y,z]),u=sub(project([5/6,y,z]),a).map(v=>v/350),v=sub(project([1/6,y,0]),a).map(v=>v/350);
      textureTransform=`matrix(${u[0]} ${u[1]} ${v[0]} ${v[1]} ${a[0]} ${a[1]})`;
    }
    paint+=`<g clip-path="url(#${clip})" ${mask}>${polygon(p,`fill="${s.color}"`)}<use href="#t-${key}" transform="${textureTransform}" opacity="${s.opacity}"/></g>`;
    if(!['wood','metal'].includes(f.kind)){
      const soft=stoneFinish({face:f,id,profile:s,textureKey:key,textureTransform,mask,guideLines:lines,connected:model.clipPaint&&!model.wrapFloorX,spec:f.part==='floor'?floorFinish:finish});
      defs+=soft.defs;softPaint+=soft.paint;omittedFinishEdges+=soft.omittedEdges;
    }
    const highlight=f.kind==='floor'?'#76839b':f.kind==='top'?'#8694b2':f.kind==='wood'?'#bb8249':f.kind==='metal'?'#a1a6b4':'#52617e';
    // Arched profiles use continuous highlights across their tessellation.
    if(f.part==='arch'||f.part==='closed-door'){
      bevels+=`<g ${mask}>`+polygon(p,`fill="none" stroke="${highlight}" stroke-width="4.5" stroke-linejoin="round" opacity=".4" clip-path="url(#${clip})"`)+'</g>';
      continue;
    }
    // Only interior highlights vary. The exterior and mortar are never displaced.
    for(let i=0;i<p.length;i++){const a=p[i],b=p[(i+1)%p.length],d=sub(b,a),len=Math.hypot(...d);if(len<4)continue;
      const n=[-d[1]/len,d[0]/len],lit=n[0]+n[1]>0,inset=f.kind==='floor'?1.4:1.9,cut=Math.min(1.8,len*.08),u=d.map(v=>v/len),c=a.map((v,j)=>v+n[j]*inset+u[j]*cut),e=b.map((v,j)=>v+n[j]*inset-u[j]*cut),outer=[],inner=[],count=Math.max(3,Math.ceil(len/11));
      for(let j=0;j<=count;j++){const pt=lerp(c,e,j/count),r=.5+.5*Math.sin(((f.bevelSeed??id)+1)*13+i*7+j*2.7),width=(f.kind==='floor'?.65:1.25)*(.6+r);outer.push(pt);inner.push(pt.map((v,k)=>v+n[k]*width));}
      bevels+=polygon([...outer,...inner.reverse()],`fill="${lit?highlight:'#070e1c'}" opacity="${lit?(f.kind==='floor'?.3:.55):.42}" clip-path="url(#${clip})"`);
    }
    if(mask)bevels=bevels.slice(0,bevelStart)+`<g ${mask}>`+bevels.slice(bevelStart)+'</g>';
  }
  defs+='</defs>';
  const ink=body(guide).replaceAll('#ff00ff','#0c1220');
  // The next floor row owns the joint at the bottom of this periodic tile.
  // Include its existing ink so both halves survive the opaque cell framing.
  const tiledInk=ink+(model.repeatInkY?`<g transform="translate(0 ${model.repeatInkY})">${ink}</g>`:'');
  // Small accent is selected only in a sufficiently large lower facade face.
  let accent='';const eligible=faces.filter(f=>/wall|pillar/.test(f.part)&&f.kind==='north'&&f.p[2]<.94/6&&area(f.points)>250);
  for(const f of model.drawAccent===false?[]:model.stableStones?eligible.filter(f=>f.bevelSeed%7===0):eligible.slice(-1)){const ps=f.points,mid=ps.reduce((a,b)=>a.map((v,i)=>v+b[i]/ps.length),[0,0]),index=faces.indexOf(f);accent+=`<path d="M${mid[0]+3} ${mid[1]+5}l-4 -6 3 -4 -2 -3 m-1 7 -5 -2" stroke="#aa79de" stroke-width=".55" opacity=".8" fill="none" clip-path="url(#f${index})"/>`;}
  const artwork=paint+bevels+accent;
  const drawing=document(defs+(model.clipPaint?`<g clip-path="url(#connected-shape)">${artwork}</g>`:artwork)+tiledInk);
  // Independently projected model volume, not the extracted planar regions.
  const silhouette=document(model.silhouette+tiledInk);
  const expected=model.alphaMask||await sharp(Buffer.from(silhouette)).ensureAlpha().raw().toBuffer();
  let actual=await sharp(Buffer.from(drawing)).ensureAlpha().raw().toBuffer();
  let holes=0,excess=0;
  for(let i=3;i<expected.length;i+=4){if(expected[i]>250&&actual[i]<128)holes++;if(!model.alphaMask&&expected[i]===0&&actual[i]>128)excess++;}
  if(holes>8||excess>8)throw Object.assign(Error(`${model.id}: face coverage mismatch (${holes} holes, ${excess} excess)`),{diagnostic:{drawing,silhouette,model,faces,holes,excess}});
  // Fixed construction mask: permitted offline workflow. Never fit to artwork.
  for(let i=3;i<actual.length;i+=4)actual[i]=expected[i];
  // B is an appearance pass over the unchanged construction, including the
  // original outer strokes. Its mortar intentionally replaces straight inner ink.
  const baseline=await sharp(actual,{raw:{width:canvas[0],height:canvas[1],channels:4}}).png().toBuffer();
  const softened=softPaint+accent.replace(/url\(#f(\d+)\)/g,'url(#stone-$1)');
  const softDrawing=document(defs+`<image href="data:image/png;base64,${baseline.toString('base64')}" x="${frame[0]}" y="${frame[1]}" width="${frame[2]}" height="${frame[3]}"/>`+(model.clipPaint?`<g clip-path="url(#connected-shape)">${softened}</g>`:softened));
  actual=await sharp(Buffer.from(softDrawing)).ensureAlpha().raw().toBuffer();
  for(let i=3;i<actual.length;i+=4)actual[i]=expected[i];
  const png=await sharp(actual,{raw:{width:canvas[0],height:canvas[1],channels:4}}).png().toBuffer();
  const decoded=await sharp(png).ensureAlpha().raw().toBuffer();let alphaDiff=0;for(let i=3;i<expected.length;i+=4)if(expected[i]!==decoded[i])alphaDiff++;
  const overlay=await sharp(Buffer.from(document(tiledInk.replaceAll('#0c1220','#ff00ff')))).png().toBuffer();
  const composite=await sharp(png).composite([{input:overlay}]).png().toBuffer();
  const tuples=s=>parseLines(s).map(l=>[...l.a,...l.b,l.width]);
  const jointsEqual=JSON.stringify(tuples(ink))===JSON.stringify(tuples(guide));
  return {png,overlay:composite,report:{id:model.id,canvas,anchor,cellPitch:256*SCALE,guideSha256:hash(guide),segmentCount:lines.length,outputFrame:frame,repeatInkY:model.repeatInkY||0,constructionJointLayerMatchesGuide:jointsEqual,visibleStoneJoints:'Soft B inside unchanged construction; visible mortar need not follow straight guide strokes.',stoneFinish:finish.id,...(model.floorFinish?{floorFinish}:{}),omittedFinishEdges,alphaPixelsDifferentFromModel:alphaDiff,unpaintedInteriorPixels:holes,extraInteriorPixels:excess,faces:faces.map(f=>({points:f.points,kind:f.kind,part:f.part,materialId:f.materialId})),materials:[...new Set(faces.map(f=>f.materialId))]},recipe:document(faces.map(f=>polygon(f.points,`fill="#fff"`)).join('')+tiledInk)};
}
module.exports={ROOT,SCALE,read,hash,body,sub,dot,cross3,inside,polygon,svg,parseLines,regionsFromLines,probe,prepareModel,cast,prepareFaces,render};
