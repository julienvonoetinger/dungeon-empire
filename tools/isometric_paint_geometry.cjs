// Offline projection helpers. Immutable migration-v1 is the geometric contract.
const fs=require('node:fs'),path=require('node:path');
const K=require('./isometric_kit_geometry.cjs'),G=require('./wireframe_geometry.cjs');
const source=JSON.parse(fs.readFileSync(path.join(K.ROOT,'docs/reference/isometric-review/migration-v1/geometry.json')));
const models=source.models;
const project=p=>G.project(p,K.camera).map(v=>v*K.PX);
const normal=ps=>{let n=G.cross(G.sub(ps[1],ps[0]),G.sub(ps[2],ps[0])),l=Math.hypot(...n);if(l<1e-10)return [0,0,0];n=n.map(v=>v/l);return G.dot(n,K.camera.eye)<0?n.map(v=>-v):n;};
const ground=([x,y])=>[(x+2*y)/K.PX,(-x+2*y)/K.PX,0];
function onPlane(screen,p,n) {
  const o=ground(screen),t=G.dot(n,G.sub(p,o))/G.dot(n,K.camera.eye);return G.add(o,G.mul(K.camera.eye,t));
}
function caster(model) {
  const tris=model.faces.flatMap((f,fi)=>f.points.slice(1,-1).map((b,i)=>{
    const a=f.points[0],c=f.points[i+2],e1=G.sub(b,a),e2=G.sub(c,a),h=G.cross(K.camera.eye,e2),det=G.dot(e1,h);
    const q=[a,b,c].map(project);return {f,fi,a,e1,e2,h,det,n:normal([a,b,c]),box:[0,1].flatMap(k=>[Math.min(...q.map(p=>p[k])),Math.max(...q.map(p=>p[k]))])};
  })).filter(t=>Math.abs(t.det)>1e-11);
  return screen=>{
    const o=ground(screen);let best=null;
    for(const t of tris) {
      if(screen[0]<t.box[0]-1e-6||screen[0]>t.box[1]+1e-6||screen[1]<t.box[2]-1e-6||screen[1]>t.box[3]+1e-6)continue;
      const d=G.sub(o,t.a),u=G.dot(d,t.h)/t.det;if(u< -1e-7||u>1+1e-7)continue;
      const q=G.cross(d,t.e1),v=G.dot(K.camera.eye,q)/t.det;if(v< -1e-7||u+v>1+1e-7)continue;
      const depth=G.dot(t.e2,q)/t.det;
      if(!best||depth>best.depth+1e-8)best={depth,p:G.add(o,G.mul(K.camera.eye,depth)),normal:t.n,face:t.f,index:t.fi};
    }
    return best;
  };
}
// Texture maps in world planes, not in the screen bounding rectangle.
function textureTransform(points3d,n) {
  let axes=n[2]>.7?[0,1]:Math.abs(n[0])>Math.abs(n[1])?[1,2]:[0,2];
  const [u,v]=axes,lo=[u,v].map(i=>Math.min(...points3d.map(p=>p[i]))),hi=[u,v].map(i=>Math.max(...points3d.map(p=>p[i])));
  const a=points3d[0].slice();a[u]=lo[0];a[v]=axes[1]===2?hi[1]:lo[1];
  const b=a.slice(),c=a.slice();b[u]=hi[0];c[v]=axes[1]===2?lo[1]:hi[1];
  const A=project(a),U=G.sub(project(b),A).map(x=>x/350),V=G.sub(project(c),A).map(x=>x/350);
  return `matrix(${U[0]} ${U[1]} ${V[0]} ${V[1]} ${A[0]} ${A[1]})`;
}
function raster(model,frame,scale=4) {
  const width=frame[2]*scale,height=frame[3]*scale,depth=new Float64Array(width*height).fill(-Infinity),owner=new Int32Array(width*height).fill(-1);
  const xyz=new Float64Array(width*height*3);
  model.faces.forEach((f,fi)=>f.points.slice(1,-1).forEach((_,j)=>{
    const ws=[f.points[0],f.points[j+1],f.points[j+2]],ps=ws.map(p=>project(p).map((v,i)=>(v-frame[i])*scale)),[a,b,c]=ps;
    const det=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);if(Math.abs(det)<1e-10)return;
    const lo=[0,1].map(i=>Math.max(0,Math.floor(Math.min(...ps.map(p=>p[i]))))),hi=[0,1].map(i=>Math.min([width,height][i]-1,Math.ceil(Math.max(...ps.map(p=>p[i])))));
    for(let y=lo[1];y<=hi[1];y++)for(let x=lo[0];x<=hi[0];x++) {
      const u=((b[1]-c[1])*(x+.5-c[0])+(c[0]-b[0])*(y+.5-c[1]))/det,v=((c[1]-a[1])*(x+.5-c[0])+(a[0]-c[0])*(y+.5-c[1]))/det,w=1-u-v;
      if(Math.min(u,v,w)<-1e-8)continue;
      const p=ws[0].map((a,i)=>a*u+ws[1][i]*v+ws[2][i]*w),d=G.dot(p,K.camera.eye),k=y*width+x;
      if(d>depth[k]+1e-9){depth[k]=d;owner[k]=fi;xyz.set(p,k*3);}
    }
  }));return {width,height,depth,owner,xyz};
}
module.exports={...G,...K,models,project,normal,ground,onPlane,caster,textureTransform,raster};
