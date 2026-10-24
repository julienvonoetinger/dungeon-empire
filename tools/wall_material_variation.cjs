// Offline wall appearance only. Coordinates and silhouettes are never changed.
const P=256,H=1.88/6,J=.94/6,EPS=.00015;
const dot=(a,b)=>a.reduce((n,v,i)=>n+v*b[i],0),ray=[.18,.9,1];
const project=(p,a)=>[(p[0]-.18*p[2])*P+a[0],(p[1]-.9*p[2])*P+a[1]];
function physical(f,anchor){return f.points.map(q=>{const o=[(q[0]-anchor[0])/P,(q[1]-anchor[1])/P,0],t=dot(f.normal,f.p.map((v,i)=>v-o[i]))/dot(f.normal,ray);return o.map((v,i)=>v+t*ray[i]);});}
function inside(q,ps){let odd=false;for(let i=0,j=ps.length-1;i<ps.length;j=i++){const a=ps[i],b=ps[j];if((a[1]>q[1])!==(b[1]>q[1])&&q[0]<(b[0]-a[0])*(q[1]-a[1])/(b[1]-a[1])+a[0])odd=!odd;}return odd;}
function capFor(f,caps,anchor){const p=f.p.map((v,i)=>i===2?H:v-f.normal[i]*.0001);return caps.find(t=>inside(project(p,anchor),t.points));}

function applyWallVariation(model,faces,phase,config){
  const m=config.materials;
  for(const f of faces){
    if(!/wall|pillar/.test(f.part))continue;
    const axis=/north|south/.test(f.part)?0:1,world=physical(f,model.anchor);
    const lo=Math.min(...world.map(p=>p[axis])),hi=Math.max(...world.map(p=>p[axis]));
    const other=1-axis,minOther=Math.min(...world.map(p=>p[other])),maxOther=Math.max(...world.map(p=>p[other]));
    // Every shared/cut/adjacent stone is style-independent, including guard paint.
    const common=lo<=EPS||hi>=1-EPS||minOther<-EPS||maxOther>1+EPS||f.part==='pillar';
    let id=m.quiet;
    if(!common){
      if(f.kind==='top'||f.p[2]>=J-1e-5)id=[m.calm,m.weathered,m.chip,m.d2][phase];
      else id=[[m.calm,m.quiet],[m.weathered,m.calm],[m.softchip,m.quiet],[m.quiet,m.scar]][phase][Number((lo+hi)/2>.5)];
    }
    f.materialId=id;f.wallVariation={phase,common};
  }
  const caps=faces.filter(f=>f.kind==='top'&&/wall/.test(f.part));
  const facades=faces.filter(f=>f.kind!=='top'&&/wall/.test(f.part)&&f.p[2]>=J-1e-5);
  for(const f of facades){const cap=capFor(f,caps,model.anchor);if(cap){f.materialId=cap.materialId;f.wallVariation=cap.wallVariation;}}
  if(phase===3)for(const cap of caps.filter(f=>f.materialId===m.d2)){
    const adjacent=facades.filter(f=>capFor(f,caps,model.anchor)===cap);if(!adjacent.length){cap.materialId=m.calm;continue;}
    const vertices=physical(cap,model.anchor),horizontal=/north|south/.test(cap.part);
    const xs=vertices.map(p=>p[0]),ys=vertices.map(p=>p[1]),h=vertices[0][2];
    const minX=Math.min(...xs),maxX=Math.max(...xs),minY=Math.min(...ys),maxY=Math.max(...ys);
    const low=Math.min(...adjacent.flatMap(f=>physical(f,model.anchor).map(p=>p[2])));
    const span=Math.max(maxX-minX+(horizontal?0:h-low),maxY-minY+(horizontal?h-low:0))*1.15;
    const origin=[minX-span*.065,minY-span*.065];
    for(const f of [cap,...adjacent]){
      const world=(u,v)=>f===cap?[u,v,h]:horizontal?[u,maxY,h-(v-maxY)]:[maxX,v,h-(u-maxX)];
      const a=project(world(...origin),model.anchor),u=project(world(origin[0]+span,origin[1]),model.anchor),v=project(world(origin[0],origin[1]+span),model.anchor);
      f.textureTransform='matrix('+[(u[0]-a[0])/350,(u[1]-a[1])/350,(v[0]-a[0])/350,(v[1]-a[1])/350,...a].map(n=>Number(n.toFixed(9))).join(' ')+')';
    }
  }
  model.drawAccent=false;model.wallVariationApplied=true;
}
module.exports={applyWallVariation};
