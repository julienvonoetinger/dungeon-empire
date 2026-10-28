// Accepted Sceau interdit: exact reviewed geometry and paint, split for depth.
const sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const Texture=require('./isometric_seal_texture.cjs');
const {geometry,referenceFiles}=Texture;
function bounds(fs){const points=fs.flatMap(f=>f.points);return {min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};}
function frame(fs,padding=5){const points=fs.flatMap(f=>f.points.map(P.project));const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-padding),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+padding);return [...lo,hi[0]-lo[0],hi[1]-lo[1]];}
// Render supports, not changes to the approved geometry. A hollow frame cannot
// be one sortable volume: the actor must fit between its near and far jambs.
const CROWN_Z=.92;
const canonical={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
function clip(points,d,axis,value,greater){
 const out=[],coord=p=>canonical[d](p)[axis],inside=p=>greater?coord(p)>=value:coord(p)<=value;
 points.forEach((a,i)=>{const b=points[(i+1)%points.length];if(inside(a))out.push(a);if(inside(a)!==inside(b))out.push(P.lerp(a,b,(value-coord(a))/(coord(b)-coord(a))));});return out;
}
function pieces(m,d) {
 const specs=[['leaf','jamb-left',false,[[2,CROWN_Z,false],[0,.5,false]]],['arch','crown',false,[[2,CROWN_Z,true]]],['jamb-right','jamb-right',false,[[2,CROWN_Z,false],[0,.5,true]]],['panel','panel',true,[]]];
 return specs.flatMap(([suffix,role,wood,cuts])=>{
  const fs=m.faces.filter(f=>f.kind.startsWith('leaf')===wood).map(f=>({...f,points:cuts.reduce((ps,[axis,value,greater])=>clip(ps,d,axis,value,greater),f.points)})).filter(f=>f.points.length>=3);
  return fs.length?[{id:m.id+'-'+suffix,doorPart:role,faces:fs,bounds:bounds(fs)}]:[];
 });
}
function alphaBounds(data,w,h,threshold=128){let x0=w,y0=h,x1=0,y1=0;for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(data[(y*w+x)*4+3]>threshold){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}return [x0,y0,x1-x0+1,y1-y0+1];}
async function paint(d,open=false){
  const m=geometry(d,open),f=frame(m.faces),{png,mesh}=await Texture.render(d,m,f);
  const rgba=await sharp(png).ensureAlpha().raw().toBuffer();
  const parts=pieces(m,d),buffers=parts.map(()=>Buffer.alloc(rgba.length)),owners=new Int8Array(f[2]*f[3]).fill(-1);
  for(let y=0;y<f[3];y++)for(let x=0;x<f[2];x++){
    const i=y*f[2]+x;if(!rgba[i*4+3])continue;
    let j=(y*4+2)*mesh.width+x*4+2;
    if(mesh.owner[j]<0){seek:for(let r=1;r<=16;r++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){
      if(Math.max(Math.abs(dx),Math.abs(dy))!==r)continue;
      const X=x*4+2+dx,Y=y*4+2+dy;if(X<0||Y<0||X>=mesh.width||Y>=mesh.height)continue;
      const q=Y*mesh.width+X;if(mesh.owner[q]>=0){j=q;break seek;}
    }}
    if(mesh.owner[j]<0)throw Error('No geometric owner for filtered seal pixel: '+d+' '+x+','+y);
    const point=canonical[d](Array.from(mesh.xyz.subarray(j*3,j*3+3)));
    const owner=m.faces[mesh.owner[j]].kind.startsWith('leaf')?3:point[2]>=CROWN_Z?1:point[0]<.5?0:2;
    owners[i]=owner;rgba.copy(buffers[owner],i*4,i*4,i*4+4);
  }
  let overlap=0;
  for(let y=0;y<f[3];y++)for(let x=0;x<f[2];x++){
    const i=y*f[2]+x,owner=owners[i];if(owner<0||rgba[i*4+3]!==255)continue;
    const adjacent=new Set();for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++){
      const X=x+dx,Y=y+dy;if(X>=0&&Y>=0&&X<f[2]&&Y<f[3]){const other=owners[Y*f[2]+X];if(other>=0&&other!==owner)adjacent.add(other);}
    }
    for(const other of adjacent){rgba.copy(buffers[other],i*4,i*4,i*4+4);overlap++;}
  }
  parts[0].companions=parts.slice(2).map(p=>p.id);
  for(let i=0;i<parts.length;i++){
    const crop=alphaBounds(buffers[i],f[2],f[3],0),pad=3;
    const x=Math.max(0,crop[0]-pad),y=Math.max(0,crop[1]-pad),X=Math.min(f[2],crop[0]+crop[2]+pad),Y=Math.min(f[3],crop[1]+crop[3]+pad);
    parts[i].frame=[f[0]+x,f[1]+y,X-x,Y-y];
    // .8 source density still exceeds .75 gameplay pixels and preserves the
    // existing 8 MiB architecture page. Logical size/supports remain unchanged.
    parts[i].rasterScale=.8;
    if(i===0)parts[i].wallJunction={axis:['north','south'].includes(d)?'v':'h',span:Texture.span.slice()};
    parts[i].png=await sharp(buffers[i],{raw:{width:f[2],height:f[3],channels:4}}).extract({left:x,top:y,width:X-x,height:Y-y}).png().toBuffer();
    const edges=P.visibleEdges({...m,faces:parts[i].faces},P.camera);
    // Guide is inspection only; support split never adds a visual horizontal seam.
    const lines=edges.map(e=>{const a=P.project(e.a).map((v,k)=>v-parts[i].frame[k]),b=P.project(e.b).map((v,k)=>v-parts[i].frame[k]);return `<path d="M${a}L${b}" fill="none" stroke="#f0f" stroke-width=".6"/>`}).join('');
    parts[i].guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${X-x}" height="${Y-y}">${lines}</svg>`;
    parts[i].report={...Texture.report,doorState:open?'open-frame':'closed',projection:P.camera,packedRasterScale:.8,split:'independent left/right jambs, crown above .92, and closed panel; original final pixels with 2px opaque overlap',overlap,sourceAlpha:'original generated RGBA retained; prepared alpha comes from accepted XYZ'};
  }
  return {parts,full:{png,frame:f,bounds:bounds(m.faces)},model:m};
}
async function doors(d,open=false){return (await paint(d,open)).parts;}
module.exports={doors,paint,geometry,referenceFiles};
