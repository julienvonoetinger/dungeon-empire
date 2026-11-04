// Geometry review only: open stairwell cut into z=0, using the sanctuary camera.
const fs=require('node:fs'),path=require('node:path');
const P=require('./isometric_paint_geometry.cjs');
const out=path.join(P.ROOT,'assets/previews/sanctuary-stairwell-wireframe');
const review=path.join(P.ROOT,'docs/reference/invocation-magic/stairwell-wireframe');
const m={faces:[],edges:[],curvedStrips:[]};
const W=.5,N=9,RUN=.30,DROP=.11,L=N*RUN,DEPTH=(N-1)*DROP,END=L+1.15;
// Oblique to the camera: both ground-plane alignment and retaining cheeks read.
const ANGLE=20*Math.PI/180;
const world=(side,run,z)=>{
 const x=(side-run)/Math.SQRT2,y=(-side-run)/Math.SQRT2;
 return [x*Math.cos(ANGLE)-y*Math.sin(ANGLE),x*Math.sin(ANGLE)+y*Math.cos(ANGLE),z];
};
function face(points,kind){
 const ps=points.map(p=>world(...p));m.faces.push({points:ps,kind});
 ps.forEach((p,i)=>m.edges.push({a:p,b:ps[(i+1)%ps.length],kind}));
}
for(let i=0;i<N;i++){
 const a=i*RUN,b=(i+1)*RUN,z=-i*DROP;
 face([[-W,a,z],[W,a,z],[W,b,z],[-W,b,z]],'tread');
 if(i<N-1)face([[-W,b,z],[W,b,z],[W,b,z-DROP],[-W,b,z-DROP]],'riser');
}
// The landing continues under the mountain. No closing end-wall.
face([[-W,L,-DEPTH],[W,L,-DEPTH],[W,END,-DEPTH],[-W,END,-DEPTH]],'tunnel');
for(const x of [-W,W])face([[x,0,0],[x,END,0],[x,END,-DEPTH],[x,0,-DEPTH]],'side');
face([[-W,L,0],[W,L,0],[W,END,0],[-W,END,0]],'roof');
const opening=[world(-W,0,0),world(W,0,0),world(W,L,0),world(-W,L,0)];
const projected=opening.map(P.project);
const lo=[0,1].map(i=>Math.floor(Math.min(...projected.map(p=>p[i])))-4),hi=[0,1].map(i=>Math.ceil(Math.max(...projected.map(p=>p[i])))+4);
const frame=[...lo,...hi.map((v,i)=>v-lo[i])];
const xy=p=>p.map(v=>+v.toFixed(3)).join(',');
const visible=P.visibleEdges(m,P.camera);
// Faces are uniform clay volumes; all visible edges are solved in actual XYZ.
const fills={tread:'#334652',riser:'#25343f',side:'#26333e',tunnel:'#101a23',roof:'#26333d'};
const ordered=m.faces.slice().sort((a,b)=>{
 const d=f=>f.points.reduce((v,p)=>v+P.dot(p,P.camera.eye),0)/f.points.length;
 return d(a)-d(b);
});
const silhouette=projected.map(xy).join(' ');
const faces=ordered.map(f=>`<polygon points="${f.points.map(P.project).map(xy).join(' ')}" fill="${fills[f.kind]}"/>`).join('');
const lines=visible.map(e=>`<path d="M${xy(P.project(e.a))} L${xy(P.project(e.b))}" stroke="${e.kind==='tunnel'?'#57717e':'#b3cad5'}" stroke-width="1.7"/>`).join('');
const rim=`<path d="M${xy(projected[0])} L${xy(projected[1])} L${xy(projected[2])} L${xy(projected[3])} Z" fill="none" stroke="#dfbe80" stroke-width="2.2"/>`;
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]}" height="${frame[3]}" viewBox="${frame.join(' ')}"><defs><clipPath id="ground"><polygon points="${silhouette}"/></clipPath></defs><g clip-path="url(#ground)"><polygon points="${silhouette}" fill="#101a23"/>${faces}<g fill="none" stroke-linecap="round" stroke-linejoin="round">${lines}</g></g>${rim}</svg>\n`;
fs.mkdirSync(out,{recursive:true});fs.mkdirSync(review,{recursive:true});
fs.writeFileSync(path.join(out,'stairwell.svg'),svg);
const metadata={frame,mouth:[30,-218],opening:projected,treads:Array.from({length:N},(_,i)=>({run:i*RUN,depth:-i*DROP})),run:L,depth:DEPTH,tunnelEnd:END,width:W*2,headroom:DEPTH,closedEnd:false,camera:P.camera,pixelsPerCell:P.PX};
fs.writeFileSync(path.join(out,'geometry.json'),JSON.stringify(metadata,null,2)+'\n');
fs.writeFileSync(path.join(review,'geometry.json'),JSON.stringify({model:m,visibleEdges:visible,metadata},null,2)+'\n');
if(metadata.treads[0].depth!==0||metadata.closedEnd||metadata.treads.some((s,i)=>i&&s.depth>=metadata.treads[i-1].depth))throw Error('Invalid descent');
console.log(JSON.stringify(metadata));
