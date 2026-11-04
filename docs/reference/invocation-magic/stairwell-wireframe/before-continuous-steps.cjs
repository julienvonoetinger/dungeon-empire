// Two grid cells: two unchanged dungeon stair flights, with a stone exit arch.
const fs=require('node:fs'),path=require('node:path');
const P=require('./isometric_paint_geometry.cjs');
const out=path.join(P.ROOT,'assets/previews/sanctuary-stairwell-wireframe');
const review=path.join(P.ROOT,'docs/reference/invocation-magic/stairwell-wireframe');
const source=P.models.find(m=>m.id==='stair-north');
const m={faces:[],edges:[],curvedStrips:[]},tops=[];
for(const [dy,dz] of [[.95,-.25],[.1933333333333334,-.5]]){
 const tr=p=>[p[0],p[1]+dy,p[2]+dz];
 m.faces.push(...source.faces.map(f=>({...f,kind:'tread',points:f.points.map(tr)})));
 m.edges.push(...source.edges.map(e=>({...e,a:tr(e.a),b:tr(e.b)})));
 for(const f of source.faces)if(f.points.every(p=>p[2]===f.points[0][2])&&f.points[0][2]>0)tops.push({run:2-Math.max(...f.points.map(p=>p[1]+dy)),depth:f.points[0][2]+dz});
}
function face(points,kind){
 m.faces.push({points,kind});points.forEach((p,i)=>m.edges.push({a:p,b:points[(i+1)%points.length],kind}));
}
const W0=1/12,W1=11/12;
function box(x,X,y,Y,z,Z,kind){
 const p=[[x,y,z],[X,y,z],[X,Y,z],[x,Y,z],[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]];
 for(const ids of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])face(ids.map(i=>p[i]),kind);
}
for(const [x,X] of [[0,W0],[W1,1]])box(x,X,.28,1.94,-.5,.07,'side');
face([[W0,1.8666666666666667,0],[W1,1.8666666666666667,0],[W1,2,0],[W0,2,0]],'tread');
face([[W0,0,-.5],[W1,0,-.5],[W1,.3533333333333334,-.5],[W0,.3533333333333334,-.5]],'tunnel');
box(0,.14,.08,.28,-.5,-.05,'arch');box(.86,1,.08,.28,-.5,-.05,'arch');
const arc=(r,a,y)=>[.5+r*Math.cos(a),y,-.05+r*Math.sin(a)];
for(let i=0;i<12;i++){
 const a=i*Math.PI/12,b=(i+1)*Math.PI/12;
 for(const y of [.08,.28])face([arc(.36,a,y),arc(.5,a,y),arc(.5,b,y),arc(.36,b,y)],'arch');
 for(const r of [.36,.5])face([arc(r,a,.08),arc(r,a,.28),arc(r,b,.28),arc(r,b,.08)],'arch');
}
const opening=[[W0,.07,0],[W1,.07,0],[W1,2,0],[W0,2,0]].map(P.project);
const cellCorners=[[0,0,0],[1,0,0],[1,2,0],[0,2,0]].map(P.project);
const all=m.faces.flatMap(f=>f.points).map(P.project).concat(cellCorners);
const lo=[0,1].map(i=>Math.floor(Math.min(...all.map(p=>p[i])))-4),hi=[0,1].map(i=>Math.ceil(Math.max(...all.map(p=>p[i])))+4);
const frame=[...lo,...hi.map((v,i)=>v-lo[i])];
const xy=p=>p.map(v=>+v.toFixed(4)).join(',');
const visible=P.visibleEdges(m,P.camera);
const fills={tread:'#334652',side:'#26333e',tunnel:'#101a23',arch:'#33414c'};
const ordered=m.faces.slice().sort((a,b)=>{
 const d=f=>f.points.reduce((v,p)=>v+P.dot(p,P.camera.eye),0)/f.points.length;
 return d(a)-d(b);
});
const silhouette=opening.map(xy).join(' ');
function half(points,above){
 const out=[];for(let i=0;i<points.length;i++){
  const a=points[i],b=points[(i+1)%points.length],ia=above?a[2]>=0:a[2]<=0,ib=above?b[2]>=0:b[2]<=0;
  if(ia)out.push(a);if(ia!==ib){const t=-a[2]/(b[2]-a[2]);out.push(a.map((v,j)=>v+t*(b[j]-v)));}
 }return out;
}
const faces=ordered.map(f=>[false,true].map(above=>{
 const points=half(f.points,above);if(points.length<3)return '';
 return `<polygon ${above?'':'clip-path="url(#ground)"'} points="${points.map(P.project).map(xy).join(' ')}" fill="${fills[f.kind]}"/>`;
}).join('')).join('');
const line=(a,b,under)=>`<path ${under?'clip-path="url(#ground)"':''} d="M${xy(P.project(a))} L${xy(P.project(b))}" stroke="#b3cad5" stroke-width="1.7"/>`;
const lines=visible.map(e=>{
 if(e.a[2]*e.b[2]>=0)return line(e.a,e.b,Math.max(e.a[2],e.b[2])<=0);
 const t=-e.a[2]/(e.b[2]-e.a[2]),p=e.a.map((v,i)=>v+t*(e.b[i]-v));
 return line(e.a,p,e.a[2]<0)+line(p,e.b,e.b[2]<0);
}).join('');
const entrance=[[.14,.281,-.5],[.86,.281,-.5],[.86,.281,-.05],...Array.from({length:13},(_,i)=>arc(.36,i*Math.PI/12,.281))];
const darkness=[false,true].map(above=>`<polygon ${above?'':'clip-path="url(#ground)"'} points="${half(entrance,above).map(P.project).map(xy).join(' ')}" fill="#10171e"/>`).join('');
const rim=`<polygon points="${cellCorners.map(xy).join(' ')}" fill="none" stroke="#dfbe80" stroke-width="2.2"/><path d="M${xy(P.project([0,1,0]))} L${xy(P.project([1,1,0]))}" stroke="#dfbe80" opacity=".55" stroke-dasharray="4 5" stroke-width="1.2"/>`;
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]}" height="${frame[3]}" viewBox="${frame.join(' ')}"><defs><clipPath id="ground"><polygon points="${silhouette}"/></clipPath></defs><polygon points="${silhouette}" fill="#101a23"/>${darkness}${faces}<g fill="none" stroke-linecap="round" stroke-linejoin="round">${lines}</g>${rim}</svg>\n`;
const cell=[-3,-5],origin=P.project([...cell,0]);tops.sort((a,b)=>b.depth-a.depth);
const metadata={frame,mouth:origin,cell,cells:[cell,[-3,-4]],cellCorners,opening,treads:tops,run:2,depth:.5,tunnelEnd:0,width:1,closedEnd:false,arch:{innerRadius:.36,outerRadius:.5,spring:-.05,base:-.5},sceneryOffsets:{Paroi8:[256,0],Eboulis13:[128,0]},camera:P.camera,pixelsPerCell:P.PX,source:'docs/reference/isometric-review/migration-v1/geometry.json#stair-north',translations:[[0,.95,-.25],[0,.1933333333333334,-.5]]};
const points=m.faces.flatMap(f=>f.points);
if(points.some(p=>p[0]<-1e-8||p[0]>1+1e-8||p[1]<0||p[1]>2+1e-8))throw Error('Entrance leaves its two cells');
if(tops.length!==10||tops[0].depth!==0)throw Error('Dungeon stair geometry changed');
fs.mkdirSync(out,{recursive:true});fs.mkdirSync(review,{recursive:true});
fs.writeFileSync(path.join(out,'stairwell.svg'),svg);
fs.writeFileSync(path.join(out,'geometry.json'),JSON.stringify(metadata,null,2)+'\n');
fs.writeFileSync(path.join(review,'geometry.json'),JSON.stringify({model:m,visibleEdges:visible,metadata},null,2)+'\n');
console.log('Two grid cells, ten dungeon treads, flush first tread, open stone arch.');
