// Selected concept artwork adapted offline to common wall supports.
// Source pixels are immutable. Godot only selects the resulting atlas regions.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const ROOT='docs/reference/isometric-wall-variation-review/v2-subvariants';
const OUT=ROOT+'/integration',S=4;
const read=p=>JSON.parse(fs.readFileSync(path.join(P.ROOT,p),'utf8').replace(/^\uFEFF/,''));
const save=(p,data)=>{const file=path.join(P.ROOT,OUT,p);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,data);};
const json=(p,data)=>save(p,JSON.stringify(data,null,2)+'\n');
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const smooth=v=>{v=clamp(v);return v*v*(3-2*v);};
// Calibrated source front/top planes in native image pixels. Relief uses the
// same source camera, rather than independently stretching each raised stone.
const designs={
 a1:{top:[0,.29,.44,.78,1],bottom:[0,.25,.63,1],origin:[155,275],u:[900,465],down:[0,280],back:[150,-72]},
 a2:{top:[0,.64,1],bottom:[0,.18,.44,.67,1],origin:[155,275],u:[900,465],down:[0,280],back:[150,-72]},
 a3:{top:[0,.23,.65,1],bottom:[0,.35,1],origin:[155,275],u:[900,465],down:[0,280],back:[150,-72]},
 c1:{top:[0,.33,.67,1],bottom:[0,.15,.50,.83,1],origin:[95,205],u:[970,515],down:[0,330],back:[155,-85],relief:[[.34,.66,.53,.97,.026]]},
 c2:{top:[0,.23,.46,.74,1],bottom:[0,.15,.51,.83,1],origin:[95,205],u:[1010,535],down:[0,330],back:[155,-85],relief:[[.24,.45,.53,.97,.024],[.52,.82,.03,.47,.020]]},
 c3:{top:[0,.33,.67,1],bottom:[0,.18,.70,1],origin:[95,205],u:[960,515],down:[0,320],back:[155,-85],relief:[[.34,.66,.53,.97,.016],[.19,.69,.03,.47,.033]]},
 f1:{top:[0,1/3,2/3,1],bottom:[0,1/6,.50,5/6,1],origin:[166,215],u:[890,505],down:[0,310],back:[155,-85]},
 f2:{top:[0,1/3,2/3,1],bottom:[0,1/6,.50,5/6,1],origin:[170,210],u:[885,530],down:[0,315],back:[150,-75]},
 f3:{top:[0,1/3,2/3,1],bottom:[0,1/6,.50,5/6,1],origin:[166,215],u:[890,505],down:[0,310],back:[155,-85]},
};
function sample(image,x,y){
 const {data,info}=image;x=clamp(x,0,info.width-1);y=clamp(y,0,info.height-1);
 const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,c=[0,0,0,0];
 for(const [u,v,w] of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]){
  const i=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[i+3]/255;
  c[3]+=a*w;for(let j=0;j<3;j++)c[j]+=data[i+j]*a*w;
 }
 if(c[3])for(let j=0;j<3;j++)c[j]/=c[3];return c;
}
function model(id,axis,bits){
 const d=designs[id],h=axis==='h',base=P.models.find(m=>m.id===`wall-${axis}-${bits}`),m=structuredClone(base);
 m.id=`wall-${axis}-${bits}-${id}`;m.variant=id;m.base=base.id;m.edges=[];
 const lo=bits&1?P.PILLAR/2:0,hi=bits&2?1-P.PILLAR/2:1,p=(u,v,z)=>h?[u,v,z]:[v,u,z];
 const edge=(a,b,kind='joint')=>m.edges.push({a:p(...a),b:p(...b),kind});
 // Base support is unchanged; new joint arrangements never move its endpoints.
 for(const v of [-P.T/2,P.T/2]){
  edge([lo,v,P.H/2],[hi,v,P.H/2]);
  for(const u of d.top.slice(1,-1))if(u>lo&&u<hi)edge([u,v,P.H/2],[u,v,P.H]);
  for(const u of d.bottom.slice(1,-1))if(u>lo&&u<hi)edge([u,v,0],[u,v,P.H/2]);
 }
 for(const u of d.top.slice(1,-1))if(u>lo&&u<hi)edge([u,-P.T/2,P.H],[u,P.T/2,P.H]);
 for(const e of base.visibleEdges.filter(e=>e.kind!=='joint'))m.edges.push(e);
 for(const [u0,u1,z0,z1,depth] of d.relief||[]){
  if(u0<lo+.025||u1>hi-.025)continue;
  const a=[[u0,P.T/2,z0*P.H],[u1,P.T/2,z0*P.H],[u1,P.T/2,z1*P.H],[u0,P.T/2,z1*P.H]];
  const inset=.018,b=[[u0+inset,P.T/2+depth,z0*P.H+inset],[u1-inset,P.T/2+depth,z0*P.H+inset],[u1-inset,P.T/2+depth,z1*P.H-inset],[u0+inset,P.T/2+depth,z1*P.H-inset]];
  m.faces.push({points:b.map(q=>p(...q)),kind:'relief'});
  for(let i=0;i<4;i++){
   const j=(i+1)%4;m.faces.push({points:[a[i],a[j],b[j],b[i]].map(q=>p(...q)),kind:'relief'});
   edge(a[i],a[j],'relief');edge(b[i],b[j],'relief');edge(a[i],b[i],'relief');
  }
 }
 m.visibleEdges=P.visibleEdges(m,P.camera);
 const points=m.faces.flatMap(f=>f.points),screen=points.map(P.project);
 const xylo=[0,1].map(i=>Math.floor(Math.min(...screen.map(q=>q[i])))-2),xyhi=[0,1].map(i=>Math.ceil(Math.max(...screen.map(q=>q[i])))+2);
 m.frame=[...xylo,...xyhi.map((n,i)=>n-xylo[i])];
 m.bounds={min:[0,1,2].map(i=>Math.min(...points.map(q=>q[i]))),max:[0,1,2].map(i=>Math.max(...points.map(q=>q[i])))};
 return m;
}
function guide(m){
 const body=m.visibleEdges.map(e=>{const [a,b]=[e.a,e.b].map(P.project);return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="#ff35ed" stroke-width="${e.kind==='joint'?.65:.9}"/>`;}).join('');
 return `<svg xmlns="http://www.w3.org/2000/svg" width="${m.frame[2]}" height="${m.frame[3]}" viewBox="${m.frame.join(' ')}">${body}</svg>`;
}
async function prepare(m,image,baseImage){
 const d=designs[m.variant],h=m.id.startsWith('wall-h'),mesh=P.raster(m,m.frame,S),buf=Buffer.alloc(mesh.width*mesh.height*4);
 const base=P.models.find(p=>p.id===m.base),lo=m.bounds.min[h?0:1],hi=m.bounds.max[h?0:1];
 for(let k=0;k<mesh.owner.length;k++)if(mesh.owner[k]>=0){
  const point=Array.from(mesh.xyz.slice(k*3,k*3+3)),[u,v,z]=h?point:[point[1],point[0],point[2]],screen=P.project(point);
  const fallback=sample(baseImage,screen[0]-base.frame[0]-.5,screen[1]-base.frame[1]-.5);
  const depth=(P.T/2-v)/P.T,Z=(P.H-z)/P.H;
  const tex=sample(image,d.origin[0]+d.u[0]*u+d.down[0]*Z+d.back[0]*depth,d.origin[1]+d.u[1]*u+d.down[1]*Z+d.back[1]*depth);
  // A common quiet terminal band preserves exact joins across art variants.
  // This is a surface-material transition, never a silhouette/alpha cutout.
  const distance=Math.min(u-lo,hi-u),mix=smooth((distance-.022)/.040)*clamp(tex[3]);
  const n=P.normal(m.faces[mesh.owner[k]].points),top=n[2]>.7,shade=h?1:top?.96:.84;
  for(let c=0;c<3;c++)buf[k*4+c]=Math.round(clamp(tex[c]*shade*mix+fallback[c]*(1-mix),0,255));
  buf[k*4+3]=255;
 }
 const png=await sharp(buf,{raw:{width:mesh.width,height:mesh.height,channels:4}}).resize(m.frame[2],m.frame[3]).png().toBuffer();
 const ornament=m.variant.startsWith('f');
 return {id:m.id,frame:m.frame,bounds:m.bounds,png,rasterScale:.75,wallVariant:{family:m.variant[0],variant:m.variant,axis:h?'h':'v',endProfile:+m.id.split('-')[2],base:m.base,ornament},approvedSource:ROOT+'/source/'+m.variant+'.png',adaptation:{sourcePlanes:d,commonTerminalBand:[.022,.062],mapping:'Source camera on shared XYZ wall support; C relief is physical. F optional surface layer includes its masonry backing.',rasterScale:.75}};
}
async function approvedWallVariants(){
 const selection=read(ROOT+'/selection.json');
 for(const [file,expected] of Object.entries(selection.reviewedFiles))if(P.hash(file)!==expected)throw Error('Selected wall art changed: '+file);
 const images={},bases={};
 for(const id of Object.keys(designs))images[id]=await sharp(path.join(P.ROOT,ROOT,'source',id+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 for(const axis of ['h','v'])for(let bits=0;bits<4;bits++)bases[`wall-${axis}-${bits}`]=await sharp(path.join(P.ROOT,'docs/reference/isometric-review/painted-v1/sprites',`wall-${axis}-${bits}.png`)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const items=[],models=[];
 for(const id of Object.keys(designs))for(const axis of ['h','v'])for(let bits=0;bits<4;bits++){
  const m=model(id,axis,bits),item=await prepare(m,images[id],bases[m.base]);
  items.push(item);models.push(m);save('sprites/'+item.id+'.png',item.png);
  const svg=guide(m);save('guides/'+item.id+'.svg',svg);
  save('overlays/'+item.id+'.png',await sharp(item.png).composite([{input:Buffer.from(svg)}]).png().toBuffer());
 }
 json('geometry.json',{camera:P.camera,baseGeometry:'docs/reference/isometric-review/migration-v1/geometry.json',baseSHA256:P.hash('docs/reference/isometric-review/migration-v1/geometry.json'),models});
 json('prepared.json',{status:'selected art adapted for production integration',sourceSelection:ROOT+'/selection.json',items:items.map(({png,...item})=>({...item,bytes:png.length,sha256:require('node:crypto').createHash('sha256').update(png).digest('hex')}))});
 return items;
}
module.exports={approvedWallVariants,designs,model,referenceFiles:[ROOT+'/selection.json',ROOT+'/generation.json',...Object.keys(designs).map(id=>ROOT+'/source/'+id+'.png')]};
if(require.main===module)approvedWallVariants().then(items=>console.log('Prepared '+items.length+' wall variants/layers.')).catch(e=>{console.error(e.stack);process.exitCode=1;});
