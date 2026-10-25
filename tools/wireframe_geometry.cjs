// Shared offline hidden-line geometry. Camera and model are explicit inputs.
const add = (a,b) => a.map((v,i) => v+b[i]);
const sub = (a,b) => a.map((v,i) => v-b[i]);
const mul = (a,t) => a.map(v => v*t);
const dot = (a,b) => a.reduce((n,v,i) => n+v*b[i],0);
const cross = (a,b) => [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const lerp = (a,b,t) => add(a,mul(sub(b,a),t));
const fmt = n => +n.toFixed(6);
const key = p => p.map(fmt).join(',');
const project = (p, camera) => [dot(p,camera.x),dot(p,camera.y)];

function visibleEdges(model,camera) {
  const triangles=model.faces.flatMap(f=>f.points.slice(1,-1).map((p,i)=>{
    const a=f.points[0],b=p,d=f.points[i+2],e1=sub(b,a),e2=sub(d,a),h=cross(camera.eye,e2),det=dot(e1,h);
    const q=[a,b,d].map(p=>project(p,camera));
    return {a,e1,e2,h,det,box:[Math.min(...q.map(p=>p[0])),Math.min(...q.map(p=>p[1])),Math.max(...q.map(p=>p[0])),Math.max(...q.map(p=>p[1]))]};
  })).filter(t=>Math.abs(t.det)>1e-12);
  function hidden(p) {
    const xy=project(p,camera);
    for(const t of triangles) {
      if(xy[0]<t.box[0]-1e-9||xy[0]>t.box[2]+1e-9||xy[1]<t.box[1]-1e-9||xy[1]>t.box[3]+1e-9)continue;
      const inv=1/t.det,v0=sub(p,t.a),u=inv*dot(v0,t.h);
      if(u< -1e-9||u>1+1e-9)continue;
      const q=cross(v0,t.e1),v=inv*dot(camera.eye,q);
      if(v>=-1e-9&&u+v<=1+1e-9&&inv*dot(t.e2,q)>1e-7)return true;
    }
    return false;
  }
  const result=[],seen=new Set(),candidates=[...model.edges];
  // Silhouettes of the circular socket depend on the camera; they are not
  // arbitrary vertical divisions in the smooth cylindrical stone.
  for(const {a,b} of model.curvedStrips) {
    const n=a.length;
    const facing=a.map((p,i)=>dot(cross(sub(a[(i+1)%n],p),sub(b[i],p)),camera.eye));
    for(let i=0;i<n;i++)if(facing[i]*facing[(i+n-1)%n]<0)
      candidates.push({a:a[i],b:b[i],kind:'heart'});
  }
  for(const e of candidates) {
    const k=[key(e.a),key(e.b)].sort().join('|');
    if(seen.has(k))continue;seen.add(k);
    const samples=Math.max(16,Math.ceil(Math.hypot(...sub(e.b,e.a))*240));
    let start=0,old=hidden(lerp(e.a,e.b,.5/samples));
    const emit=(a,b)=>{if(b-a>1e-7)result.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
    for(let i=1;i<samples;i++) {
      const next=hidden(lerp(e.a,e.b,(i+.5)/samples));
      if(next===old)continue;
      let lo=(i-.5)/samples,hi=(i+.5)/samples;
      for(let j=0;j<22;j++) {const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid))===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)emit(start,cut);start=cut;old=next;
    }
    if(!old)emit(start,1);
  }
  return result;
}


module.exports={visibleEdges,project,add,sub,mul,dot,cross,lerp,key,fmt};
