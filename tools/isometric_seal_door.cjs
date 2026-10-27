// Accepted Sceau interdit: exact reviewed geometry and paint, split for depth.
const sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const Texture=require('./isometric_seal_texture.cjs');
const {geometry,referenceFiles}=Texture;
function bounds(fs){const points=fs.flatMap(f=>f.points);return {min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};}
function frame(fs,padding=5){const points=fs.flatMap(f=>f.points.map(P.project));const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-padding),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+padding);return [...lo,hi[0]-lo[0],hi[1]-lo[1]];}
function pieces(m) {
  return [false,true].map(upper=>{
    const inside=p=>upper?p[2]>=P.H:p[2]<=P.H;
    const hit=(a,b)=>P.lerp(a,b,(P.H-a[2])/(b[2]-a[2]));
    const fs=m.faces.map(f=>{
      if(upper && f.kind==='junction')return {...f,points:[]};
      const points=[];f.points.forEach((a,i)=>{const b=f.points[(i+1)%f.points.length];if(inside(a))points.push(a);if(inside(a)!==inside(b))points.push(hit(a,b));});
      return {...f,points};
    }).filter(f=>f.points.length>=3);
    return {id:m.id+'-'+(upper?'arch':'leaf'),faces:fs,bounds:bounds(fs)};
  });
}
function alphaBounds(data,w,h,threshold=128){let x0=w,y0=h,x1=0,y1=0;for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(data[(y*w+x)*4+3]>threshold){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}return [x0,y0,x1-x0+1,y1-y0+1];}
async function paint(d,open=false){
  const m=geometry(d,open),f=frame(m.faces),{png,mesh}=await Texture.render(d,m,f);
  const rgba=await sharp(png).ensureAlpha().raw().toBuffer();
  const parts=pieces(m),buffers=[Buffer.alloc(rgba.length),Buffer.alloc(rgba.length)],owners=new Int8Array(f[2]*f[3]).fill(-1);
  for(let y=0;y<f[3];y++)for(let x=0;x<f[2];x++){
    const i=y*f[2]+x;if(!rgba[i*4+3])continue;
    let j=(y*4+2)*mesh.width+x*4+2;
    if(mesh.owner[j]<0){seek:for(let r=1;r<=16;r++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){
      if(Math.max(Math.abs(dx),Math.abs(dy))!==r)continue;
      const X=x*4+2+dx,Y=y*4+2+dy;if(X<0||Y<0||X>=mesh.width||Y>=mesh.height)continue;
      const q=Y*mesh.width+X;if(mesh.owner[q]>=0){j=q;break seek;}
    }}
    if(mesh.owner[j]<0)throw Error('No geometric owner for filtered seal pixel: '+d+' '+x+','+y);
    const owner=m.faces[mesh.owner[j]].kind==='junction'||mesh.xyz[j*3+2]<P.H-1e-8?0:1;
    owners[i]=owner;rgba.copy(buffers[owner],i*4,i*4,i*4+4);
  }
  let overlap=0;
  for(let y=0;y<f[3];y++)for(let x=0;x<f[2];x++){
    const i=y*f[2]+x,owner=owners[i];if(owner<0||rgba[i*4+3]!==255)continue;
    let adjacent=false;seek:for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++){
      const X=x+dx,Y=y+dy;if(X>=0&&Y>=0&&X<f[2]&&Y<f[3]&&owners[Y*f[2]+X]===1-owner){adjacent=true;break seek;}
    }
    if(adjacent){rgba.copy(buffers[1-owner],i*4,i*4,i*4+4);overlap++;}
  }
  for(let i=0;i<2;i++){
    const crop=alphaBounds(buffers[i],f[2],f[3],0),pad=3;
    const x=Math.max(0,crop[0]-pad),y=Math.max(0,crop[1]-pad),X=Math.min(f[2],crop[0]+crop[2]+pad),Y=Math.min(f[3],crop[1]+crop[3]+pad);
    parts[i].frame=[f[0]+x,f[1]+y,X-x,Y-y];
    // .8 source density still exceeds .75 gameplay pixels and preserves the
    // existing 8 MiB architecture page. Logical size/supports remain unchanged.
    parts[i].rasterScale=.8;
    if(i===0)parts[i].wallJunction={axis:['north','south'].includes(d)?'v':'h',span:Texture.span.slice()};
    parts[i].png=await sharp(buffers[i],{raw:{width:f[2],height:f[3],channels:4}}).extract({left:x,top:y,width:X-x,height:Y-y}).png().toBuffer();
    const edges=P.visibleEdges(m,P.camera).filter(e=>(i?Math.max(e.a[2],e.b[2])>=P.H:Math.min(e.a[2],e.b[2])<=P.H));
    // Guide is inspection only; support split never adds a visual horizontal seam.
    const lines=edges.map(e=>{const a=P.project(e.a).map((v,k)=>v-parts[i].frame[k]),b=P.project(e.b).map((v,k)=>v-parts[i].frame[k]);return `<path d="M${a}L${b}" fill="none" stroke="#f0f" stroke-width=".6"/>`}).join('');
    parts[i].guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${X-x}" height="${Y-y}">${lines}</svg>`;
    parts[i].report={...Texture.report,doorState:open?'open-frame':'closed',projection:P.camera,packedRasterScale:.8,split:'whole final pixels at wall height, 2px opaque colour overlap',overlap,sourceAlpha:'original generated RGBA retained; prepared alpha comes from accepted XYZ'};
  }
  return {parts,full:{png,frame:f,bounds:bounds(m.faces)},model:m};
}
async function doors(d,open=false){return (await paint(d,open)).parts;}
module.exports={doors,paint,geometry,referenceFiles};
