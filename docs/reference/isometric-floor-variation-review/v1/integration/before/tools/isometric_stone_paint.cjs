// Reuse approved mobile materials and rounded finish on isometric masks.
const sharp=require('sharp'),B=require('./prepare_mobile_reference.cjs'),R=require('./painted_material_renderer.cjs');
const P=require('./isometric_paint_geometry.cjs');
const inverse={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[1-y,x,z],west:([x,y,z])=>[y,1-x,z]};
const forward={south:inverse.south,north:inverse.north,east:inverse.west,west:inverse.east};
const FLOOR_GUARD=2,FLOOR_MARGIN=FLOOR_GUARD*Math.sqrt(5)/P.PX;
const poly=ps=>{const q=ps.map(P.project);if(q.reduce((s,a,i)=>s+a[0]*q[(i+1)%q.length][1]-a[1]*q[(i+1)%q.length][0],0)<0)q.reverse();return R.polygon(q,'fill="white"');};
const ink=es=>es.map(e=>{const a=P.project(e.a),b=P.project(e.b);return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="#ff00ff" stroke-width="${e.kind==='joint'||e.kind==='floor'?1:1.4}" stroke-linecap="round"/>`;}).join('');
function fromOldFace(f) {
  const ps=f.points.map(([X,Y])=>{
    const x=X/256,y=Y/256,n=f.normal,p=f.p;
    const z=n[2]?p[2]:n[1]?(p[1]-y)/.9:(p[0]-x)/.18;
    return [x+.18*z,y+.9*z,z];
  });
  return {...f,points:ps.map(P.project),textureTransform:P.textureTransform(ps,f.normal)};
}
function baseFaces(m) {
  if(m.id==='floor')return [-1,0,1].flatMap(dy=>B.floor().faces.map(f=>({...f,p:[f.p[0],f.p[1]+dy,f.p[2]],points:f.points.map(([x,y])=>[x,y+dy*P.PX])})))
    .filter(f=>Math.max(...f.points.map(p=>p[1]))>=-FLOOR_MARGIN*P.PX&&Math.min(...f.points.map(p=>p[1]))<=(1+FLOOR_MARGIN)*P.PX).map(fromOldFace);
  if(m.id==='pillar')return B.pillar().faces.map(fromOldFace);
  const a=m.id.split('-');return B.wall(a[1]==='h',+a[2]&1,+a[2]&2).faces.map(fromOldFace);
}
function complexFaces(m,edges) {
  const lines=edges.map(e=>({a:P.project(e.a),b:P.project(e.b)})),regions=R.regionsFromLines(lines),cast=P.caster(m),faces=[];
  for(const ps of regions) {
    const hit=cast(R.probe(ps));if(!hit)continue;
    const n=hit.normal,world=ps.map(p=>P.onPlane(p,hit.p,n));
    let kind=n[2]>.7?'top':Math.abs(n[0])>Math.abs(n[1])?'west':'north',part='wall',materialId='walls-planes';
    let textureTransform=P.textureTransform(world,n);
    if(m.id.startsWith('stair')) {if(n[2]>.7){kind='floor';materialId='floors-calm';}}
    if(hit.face.kind==='door') {
      kind='wood';part='wood';materialId='door-oak';
      const d=m.id.split('-')[1],local=inverse[d](hit.p),y=local[1];
      if(Math.abs(y-.4416666666666667)<1e-6||Math.abs(y-.5583333333333333)<1e-6) {
        materialId='approved-door-v2';
        const a=P.project(forward[d]([.24,y,P.H+.26])),u=P.sub(P.project(forward[d]([.76,y,P.H+.26])),a).map(v=>v/350),v=P.sub(P.project(forward[d]([.24,y,0])),a).map(v=>v/350);
        textureTransform=`matrix(${u[0]} ${u[1]} ${v[0]} ${v[1]} ${a[0]} ${a[1]})`;
      }
    }
    faces.push({points:ps,p:hit.p,normal:n,kind,part,materialId,bevelSeed:15+faces.length,textureTransform});
  }
  return faces;
}
async function paint(m,{faces=null,edges=m.visibleEdges,frame=m.frame}={}) {
  const materials=structuredClone(B.materials);
  materials.entries['approved-door-v2']={file:'../../../docs/reference/mobile-door-frame-review/painted-art-v2/source/door-face-fitted.png'};
  materials.renderProfile.wood={color:'#35251f',brightness:.82,saturation:.82,opacity:1,blur:.3};
  faces=faces||complexFaces(m,edges);
  const lines=edges.map(e=>({a:P.project(e.a),b:P.project(e.b),width:e.kind==='floor'||e.kind==='joint'?1:1.4}));
  // The visible guide stops at the logical cell. Crossing floor stones extend
  // beyond it, so testing their full edges against that clipped guide would
  // suppress their top/bottom bevels. Finish the COMPLETE periodic stones first;
  // keep the original visible guide and silhouette for the final cell crop.
  const finishLines=m.id==='floor'?B.linesFor(faces,1):lines;
  let silhouette=m.faces.map(f=>poly(f.points)).join('');
  if(m.id==='floor') {
    // A two-pixel copy of the periodic paint outside the diamond prevents
    // transparent sprite edges from being blended into internal floor seams.
    // This is sampling coverage, not a larger logical cell or new paving joint.
    const a=-FLOOR_MARGIN,b=1+FLOOR_MARGIN,points=[[a,a,0],[b,a,0],[b,b,0],[a,b,0]],screen=points.map(P.project);
    const lo=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-2),hi=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+2);
    frame=[...lo,...hi.map((v,i)=>v-lo[i])];silhouette=poly(points);
  }
  const guide=R.svg(frame.slice(2),ink(edges));
  const document=body=>`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]*4}" height="${frame[3]*4}" viewBox="${frame.join(' ')}">${body}</svg>`;
  const mask=await sharp(Buffer.from(document(silhouette+ink(edges)))).ensureAlpha().raw().toBuffer();
  const model={id:m.id,size:frame.slice(2),outputFrame:frame,anchor:[0,0],surfaces:[],floor:false,clipPaint:true,drawAccent:false,stableStones:true,floorFinish:materials.floorFinish,
    alphaMask:mask,silhouette,renderData:{faces,lines:finishLines,visibility:null}};
  const result=await R.render(model,guide,materials);
  if(m.id==='floor')Object.assign(result.report,{segmentCount:lines.length,finishSegmentCount:finishLines.length,finishGuide:'complete periodic stone boundaries before the logical-cell crop',filterGuardSourcePixels:FLOOR_GUARD,logicalBounds:m.bounds,alphaPolicy:'2px periodic colour coverage outside the diamond; logical geometry and guides unchanged'});
  return {id:m.id,frame,bounds:m.bounds,png:await sharp(result.png).resize(frame[2],frame[3]).png().toBuffer(),rawHigh:result.png,report:result.report};
}
async function architecture(m) {
  if(m.id==='floor'||m.id==='pillar'||m.id.startsWith('wall-'))return paint(m,{faces:baseFaces(m)});
  return paint(m);
}
async function doors(direction) {
  // Padding holds resampling tails and the internal filtering guard. XYZ
  // geometry and support bounds remain the frozen wireframe volumes.
  const pieces=P.models.filter(m=>m.id.startsWith('door-'+direction+'-')).map(m=>({...m,frame:[m.frame[0]-3,m.frame[1]-3,m.frame[2]+6,m.frame[3]+6]}));
  const points=pieces.flatMap(m=>m.faces.flatMap(f=>f.points)).map(P.project);
  const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-5),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+5),frame=[...lo,...hi.map((v,i)=>v-lo[i])];
  const model={id:'door-'+direction,faces:pieces.flatMap(m=>m.faces),visibleEdges:pieces.flatMap(m=>m.visibleEdges),frame};
  const full=await paint(model),mesh=P.raster(model,frame),raw=await sharp(full.png).ensureAlpha().raw().toBuffer(),result=[];
  const buffers=[Buffer.alloc(raw.length),Buffer.alloc(raw.length)],owners=new Int8Array(frame[2]*frame[3]).fill(-1);
  const within=(m,x,y)=>x+frame[0]>=m.frame[0]&&y+frame[1]>=m.frame[1]&&x+frame[0]<m.frame[0]+m.frame[2]&&y+frame[1]<m.frame[1]+m.frame[3];
  // Start with whole final pixels; no independent downsampling of split masks.
  for(let y=0;y<frame[3];y++)for(let x=0;x<frame[2];x++) {
    const i=(y*frame[2]+x)*4;if(!raw[i+3])continue;
    let k=(y*4+2)*mesh.width+x*4+2;
    if(mesh.owner[k]<0) {
      search:for(let r=1;r<=8;r++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++) {
        if(Math.max(Math.abs(dx),Math.abs(dy))!==r)continue;
        const X=x*4+2+dx,Y=y*4+2+dy;if(X<0||Y<0||X>=mesh.width||Y>=mesh.height)continue;
        const n=Y*mesh.width+X;if(mesh.owner[n]>=0){k=n;break search;}
      }
    }
    let owner=mesh.owner[k]>=0&&mesh.xyz[k*3+2]<P.H-1e-8?0:1;
    if(!within(pieces[owner],x,y))owner=1-owner;
    if(!within(pieces[owner],x,y))throw Error('Door pixel outside both saved frames: '+direction);
    owners[y*frame[2]+x]=owner;
    raw.copy(buffers[owner],i,i,i+4);
  }
  // Linear filtering at .75 zoom would make a disjoint cut translucent again.
  // Carry identical complete-door colour two source pixels across that INTERNAL
  // cut. Only opaque pixels can overlap; silhouette alpha is never enlarged.
  let guardPixels=0;
  for(let y=0;y<frame[3];y++)for(let x=0;x<frame[2];x++) {
    const k=y*frame[2]+x,i=k*4,owner=owners[k];if(owner<0||raw[i+3]!==255||!within(pieces[1-owner],x,y))continue;
    let neighbour=false;
    search:for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++) {
      const X=x+dx,Y=y+dy;if(X>=0&&Y>=0&&X<frame[2]&&Y<frame[3]&&owners[Y*frame[2]+X]===1-owner){neighbour=true;break search;}
    }
    if(neighbour){raw.copy(buffers[1-owner],i,i,i+4);guardPixels++;}
  }
  for(const [index,m] of pieces.entries()) {
    const png=await sharp(buffers[index],{raw:{width:frame[2],height:frame[3],channels:4}}).extract({left:m.frame[0]-frame[0],top:m.frame[1]-frame[1],width:m.frame[2],height:m.frame[3]}).png().toBuffer();
    result.push({id:m.id,frame:m.frame,bounds:m.bounds,png,report:{...full.report,split:'final pixel ownership with 2px opaque interior colour overlap for linear filtering',guardPixels}});
  }
  return result;
}
module.exports={architecture,doors,paint,ink,baseFaces};
