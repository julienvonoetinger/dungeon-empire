// Offline finish B. Inputs are the existing face regions, never traced artwork.
const add=(a,b)=>a.map((v,i)=>v+b[i]),sub=(a,b)=>a.map((v,i)=>v-b[i]);
const mul=(a,t)=>a.map(v=>v*t),dot=(a,b)=>a[0]*b[0]+a[1]*b[1];
const cross=(a,b)=>a[0]*b[1]-a[1]*b[0],length=a=>Math.hypot(...a);
const unit=a=>length(a)>1e-9?mul(a,1/length(a)):[0,0];
const lerp=(a,b,t)=>add(a,mul(sub(b,a),t)),normal=a=>[-a[1],a[0]];
const xy=a=>a.map(v=>Number(v.toFixed(4))).join(',');
const random=n=>{const x=Math.sin(n*12.9898+78.233)*43758.5453;return x-Math.floor(x);};

function edgeInGuide(a,b,lines) {
  const d=sub(b,a),len=length(d),intervals=[];
  if(len<1e-8)return false;
  for(const line of lines) {
    if(Math.abs(cross(d,sub(line.a,a)))/len>.002||Math.abs(cross(d,sub(line.b,a)))/len>.002)continue;
    const ts=[line.a,line.b].map(p=>dot(sub(p,a),d)/(len*len)).sort((a,b)=>a-b);
    const lo=Math.max(0,ts[0]),hi=Math.min(1,ts[1]);if(hi>lo)intervals.push([lo,hi]);
  }
  let end=0,covered=0;
  for(const [lo,hi] of intervals.sort((a,b)=>a[0]-b[0])){covered+=Math.max(0,hi-Math.max(lo,end));end=Math.max(end,hi);}
  return covered>.999;
}

function insetPolygon(points,distance,visible=points.map(()=>true)) {
  return points.map((p,i)=>{
    const j=(i-1+points.length)%points.length;
    const a=normal(unit(sub(p,points[j]))),b=normal(unit(sub(points[(i+1)%points.length],p)));
    const da=visible[j]?distance:0,db=visible[i]?distance:0,den=cross(a,b);
    if(Math.abs(den)<1e-6)return add(p,mul(a,da));
    return add(p,[(da*b[1]-db*a[1])/den,(a[0]*db-b[0]*da)/den]);
  });
}

function roundedPaths(points,radius,unevenness,seed,visible=points.map(()=>true)) {
  const vertices=points.map((p,i)=>{
    const j=(i-1+points.length)%points.length,prev=points[j],next=points[(i+1)%points.length];
    const incoming=sub(p,prev),outgoing=sub(next,p);
    const convex=cross(incoming,outgoing)>0;
    // Open connection cuts are not stone ends: no corner rounding or inset there.
    const r=convex&&visible[j]&&visible[i]?Math.min(radius*(.8+random(seed+i)*.4),length(incoming)*.23,length(outgoing)*.23):0;
    return {p,enter:add(p,mul(unit(incoming),-r)),exit:add(p,mul(unit(outgoing),r)),r};
  });
  let d='M'+xy(vertices[0].exit),bevel='';
  for(let i=0;i<vertices.length;i++) {
    const a=vertices[i].exit,b=vertices[(i+1)%vertices.length].enter,edge=sub(b,a),n=normal(unit(edge));
    const segment='Q'+xy(add(lerp(a,b,.5),mul(n,visible[i]?unevenness:0)))+' '+xy(b);
    const v=vertices[(i+1)%vertices.length],corner=v.r?'Q'+xy(v.p)+' '+xy(v.exit):'L'+xy(v.exit);
    d+=segment+corner;
    if(visible[i])bevel+='M'+xy(a)+segment+corner;
  }
  return {d:d+'Z',bevel};
}

function stoneFinish({face,id,profile,textureKey,textureTransform,mask,guideLines,connected,spec}) {
  const p=face.points,xs=p.map(q=>q[0]),ys=p.map(q=>q[1]);
  const spanX=Math.max(...xs)-Math.min(...xs),spanY=Math.max(...ys)-Math.min(...ys),floor=face.kind==='floor';
  const amount=Math.min(1,Math.min(spanX,spanY)/spec.narrowFaceReference)*(floor?spec.floorFactor:1);
  const visible=p.map((a,i)=>!connected||edgeInGuide(a,p[(i+1)%p.length],guideLines));
  const seed=19+(face.bevelSeed??id)*3;
  const {d,bevel}=roundedPaths(insetPolygon(p,spec.inset*amount,visible),spec.radius*amount,spec.unevenness*amount,seed,visible);
  const highlight=floor?'#76839b':face.kind==='top'?'#8694b2':'#52617e';
  const defs=`<clipPath id="stone-${id}"><path d="${d}"/></clipPath><linearGradient id="soft-bevel-${id}" x1="0" y1="0" x2=".7" y2="1"><stop offset="0" stop-color="${highlight}" stop-opacity="${floor?.42:.75}"/><stop offset=".4" stop-color="${highlight}" stop-opacity=".16"/><stop offset=".62" stop-color="#070e1c" stop-opacity=".12"/><stop offset="1" stop-color="#070e1c" stop-opacity=".8"/></linearGradient>`;
  // All-visible faces use the closed path, exactly as the approved B proposal.
  const bevelPath=visible.every(Boolean)?d:bevel;
  const paint=`<g clip-path="url(#f${id})" ${mask}><rect x="${Math.min(...xs)}" y="${Math.min(...ys)}" width="${spanX}" height="${spanY}" fill="${spec.mortar}"/><g clip-path="url(#stone-${id})"><path d="${d}" fill="${profile.color}"/><use href="#t-${textureKey}" transform="${textureTransform}" opacity="${profile.opacity}"/><path d="${bevelPath}" fill="none" stroke="url(#soft-bevel-${id})" stroke-width="${spec.bevel*amount*2}" stroke-linejoin="round"/></g></g>`;
  return {defs,paint,omittedEdges:visible.filter(v=>!v).length};
}
module.exports={stoneFinish};
