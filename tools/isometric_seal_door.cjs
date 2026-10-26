// C — Sceau interdit. Paint on the approved XYZ model, never geometry from art.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const B=require('./prepare_mobile_reference.cjs');
const REVIEW='docs/reference/door-redesign/seal-v1';
const DIR=path.join(P.ROOT,REVIEW,'painted-v1');
const approval=JSON.parse(fs.readFileSync(path.join(DIR,'geometry-approval.json'),'utf8'));
for(const [name,hash] of Object.entries(approval.files))if(P.hash(REVIEW+'/'+name)!==hash)throw Error('Approved seal wireframe changed: '+name);
const reviewed=JSON.parse(fs.readFileSync(path.join(P.ROOT,REVIEW,'geometry.json'),'utf8'));
if(JSON.stringify(reviewed.camera)!==JSON.stringify(P.camera))throw Error('Seal door camera differs from the kit');
const originalFaces=reviewed.models.facade.faces.filter(f=>!['wall','wall-bevel','floor'].includes(f.kind));
// The user rejected the first runtime joins. Replace only the outer masonry
// below rail height with two flush full-width jamb blocks; retain upper/inner
// frame, leaf, horns and seals from the approved model, and the original source.
const faces=originalFaces.map(f=>{
  if(!['stone','stone-bevel'].includes(f.kind))return f;
  const points=[];
  f.points.forEach((a,i)=>{const b=f.points[(i+1)%f.points.length],A=a[2]>=P.H,B=b[2]>=P.H;if(A)points.push(a);if(A!==B)points.push(P.lerp(a,b,(P.H-a[2])/(b[2]-a[2])));});
  return {...f,points};
}).filter(f=>f.points.length>=3);
for(const [lo,hi] of [[-P.T/2,.17],[.83,1+P.T/2]]){
  const p=[[lo,.365,0],[hi,.365,0],[hi,.635,0],[lo,.635,0],[lo,.365,P.H],[hi,.365,P.H],[hi,.635,P.H],[lo,.635,P.H]];
  for(const ids of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])faces.push({points:ids.map(i=>p[i]),kind:'junction'});
}
const edges=faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind})));
const source={id:'seal',faces,edges,curvedStrips:[]};
const forward={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
const inverse={south:forward.south,north:forward.north,east:forward.west,west:forward.east};
const referenceFiles=[REVIEW+'/geometry.json',REVIEW+'/painted-v1/geometry-approval.json',REVIEW+'/painted-v1/face-source.png',REVIEW+'/painted-v1/face-guide.png',REVIEW+'/painted-v1/painting.json'];
function bounds(fs){const points=fs.flatMap(f=>f.points);return {min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};}
function frame(fs,padding=5){const points=fs.flatMap(f=>f.points.map(P.project));const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-padding),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+padding);return [...lo,hi[0]-lo[0],hi[1]-lo[1]];}
function geometry(d){if(!forward[d])throw Error('Unknown seal direction '+d);const tr=forward[d];return {...source,id:'door-'+d,faces:faces.map(f=>({...f,points:f.points.map(tr)})),edges:edges.map(e=>({...e,a:tr(e.a),b:tr(e.b)}))};}
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
let materialsPromise;
async function materials(){
  if(materialsPromise)return materialsPromise;
  materialsPromise=(async()=>{
    const provenance=JSON.parse(fs.readFileSync(path.join(DIR,'painting.json'),'utf8'));
    if(P.hash(REVIEW+'/painted-v1/face-source.png')!==provenance.sourceSha256)throw Error('Seal painting source changed');
    if(P.hash(REVIEW+'/painted-v1/face-guide.png')!==provenance.guideSha256)throw Error('Seal painting guide changed');
    const {data,info}=await sharp(path.join(DIR,'face-source.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    const guide=await sharp(path.join(DIR,'face-guide.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    const a=alphaBounds(data,info.width,info.height),b=alphaBounds(guide.data,guide.info.width,guide.info.height);
    const scale=Math.min(b[2]/a[2],b[3]/a[3]);
    const shift=[b[0]+b[2]/2-(a[0]+a[2]/2)*scale,b[1]+b[3]-(a[1]+a[3])*scale];
    const stone={};
    for(const kind of ['top','north','west']){
      const profile=B.materials.renderProfile[kind];
      stone[kind]=await sharp(path.join(P.ROOT,'assets/dungeon/shared-materials/walls-planes.png')).modulate({brightness:profile.brightness,saturation:profile.saturation??.98}).blur(profile.blur).resize(256,256).ensureAlpha().raw().toBuffer();
    }
    return {data,info,scale,shift,stone,fit:{sourceBounds:a,guideBounds:b,uniformScale:scale,translation:shift,aspectError:Math.abs(a[2]/a[3]-b[2]/b[3])}};
  })();return materialsPromise;
}
function sample(mat,u,v){
  const {data,info}=mat;let x=Math.max(0,Math.min(info.width-1,Math.round(u))),y=Math.max(0,Math.min(info.height-1,Math.round(v))),k=(y*info.width+x)*4;
  if(data[k+3]<180){
    // Colour bleed only, underneath the immutable model alpha; never trace art.
    seek:for(let r=1;r<=20;r++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){
      if(Math.max(Math.abs(dx),Math.abs(dy))!==r)continue;
      const X=x+dx,Y=y+dy;if(X<0||Y<0||X>=info.width||Y>=info.height)continue;
      const n=(Y*info.width+X)*4;if(data[n+3]>180){k=n;break seek;}
    }
  }
  return data[k+3]>100?[data[k],data[k+1],data[k+2]]:null;
}
async function paint(d){
  const mat=await materials(),m=geometry(d),f=frame(m.faces),mesh=P.raster(m,f,4),raw=Buffer.alloc(mesh.width*mesh.height*4);
  const normals=m.faces.map(face=>P.normal(face.points));
  const localNormals=source.faces.map(face=>P.normal(face.points));
  const paintInfo=m.faces.map(face=>{
    const n=P.normal(face.points),kind=n[2]>.7?'top':Math.abs(n[0])>Math.abs(n[1])?'west':'north';
    const axes=n[2]>.7?[0,1]:Math.abs(n[0])>Math.abs(n[1])?[1,2]:[0,2];
    const lo=axes.map(i=>Math.min(...face.points.map(p=>p[i]))),hi=axes.map(i=>Math.max(...face.points.map(p=>p[i])));
    const color=B.materials.renderProfile[kind].color.match(/[a-f\d]{2}/gi).map(v=>parseInt(v,16));
    return {kind,axes,lo,hi,color,screen:face.points.map(P.project)};
  });
  const inv=inverse[d];
  for(let k=0;k<mesh.owner.length;k++){
    const fi=mesh.owner[k];if(fi<0)continue;
    const world=Array.from(mesh.xyz.subarray(k*3,k*3+3)),p=inv(world),kind=m.faces[fi].kind,n=normals[fi],local=localNormals[fi];
    let rgb;
    if(!/^(leaf|metal|seal)/.test(kind)){
      const paint=paintInfo[fi],profile=B.materials.renderProfile[paint.kind],texture=mat.stone[paint.kind];
      const uv=paint.axes.map((axis,i)=>Math.max(0,Math.min(1,(world[axis]-paint.lo[i])/Math.max(.00001,paint.hi[i]-paint.lo[i]))));
      if(paint.axes[1]===2)uv[1]=1-uv[1];
      const j=(Math.round(uv[1]*255)*256+Math.round(uv[0]*255))*4;
      const recess=kind.startsWith('recess')?.78:kind.startsWith('inner')?.92:1;
      rgb=paint.color.map((c,i)=>(c*(1-profile.opacity)+texture[j+i]*profile.opacity)*recess);
      if(kind.endsWith('-bevel'))rgb=rgb.map(v=>v*(n[2]>.25?1.16:.88));
      // Broad restrained edge finish, like the kit's rounded stone treatment.
      if(!kind.endsWith('-bevel')){
        const s=P.project(world);let nearest=Infinity,lit=false;
        const polygon=paint.screen.slice();
        if(polygon.reduce((a,p,i)=>a+p[0]*polygon[(i+1)%polygon.length][1]-p[1]*polygon[(i+1)%polygon.length][0],0)<0)polygon.reverse();
        for(let i=0;i<polygon.length;i++){
          const a=polygon[i],b=polygon[(i+1)%polygon.length],dx=b[0]-a[0],dy=b[1]-a[1],len=Math.hypot(dx,dy);if(len<.01)continue;
          const dist=Math.abs(dx*(a[1]-s[1])-(a[0]-s[0])*dy)/len;
          if(dist<nearest){nearest=dist;lit=(-dy+dx)>0;}
        }
        const strength=Math.max(0,1-nearest/1.15)*.38;
        const target=lit?(paint.kind==='top'?[114,129,157]:[76,94,123]):[8,15,28];
        rgb=rgb.map((v,i)=>v*(1-strength)+target[i]*strength);
      }
    } else if(Math.abs(local[1])>.7){
      rgb=sample(mat,(512+(p[0]-.5)*820-mat.shift[0])/mat.scale,(890-p[2]*820-mat.shift[1])/mat.scale);
      if(rgb){const factor=kind.startsWith('seal')?1:(Math.abs(n[0])>.6?.64:.79);rgb=rgb.map(v=>v*factor);}
    }
    if(!rgb){
      const ix=((Math.floor((p[0]*1.3+p[1]) *256)%256)+256)%256,iy=((Math.floor((p[2]+p[1]*.3)*256)%256)+256)%256;
      const j=(iy*256+ix)*4;const tex=[mat.stone.top[j],mat.stone.top[j+1],mat.stone.top[j+2]];
      const top=n[2]>.55,base=kind.startsWith('leaf')?[39,25,44]:kind.startsWith('metal')?[72,81,101]:kind.startsWith('seal')?[114,37,168]:[59,73,102];
      const shade=top?1.08:Math.abs(n[0])>.6?.54:.68;
      rgb=base.map((v,i)=>(v*.65+tex[i]*.35)*shade);
    }
    raw.set(rgb.map(v=>Math.max(0,Math.min(255,Math.round(v)))),k*4);raw[k*4+3]=255;
  }
  const png=await sharp(raw,{raw:{width:mesh.width,height:mesh.height,channels:4}}).resize(f[2],f[3]).png().toBuffer();
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
    if(i===0)parts[i].wallJunction={axis:['north','south'].includes(d)?'v':'h',span:[.365,.635]};
    parts[i].png=await sharp(buffers[i],{raw:{width:f[2],height:f[3],channels:4}}).extract({left:x,top:y,width:X-x,height:Y-y}).png().toBuffer();
    const edges=P.visibleEdges(m,P.camera).filter(e=>(i?Math.max(e.a[2],e.b[2])>=P.H:Math.min(e.a[2],e.b[2])<=P.H));
    // Guide is inspection only; support split never adds a visual horizontal seam.
    const lines=edges.map(e=>{const a=P.project(e.a).map((v,k)=>v-parts[i].frame[k]),b=P.project(e.b).map((v,k)=>v-parts[i].frame[k]);return `<path d="M${a}L${b}" fill="none" stroke="#f0f" stroke-width=".6"/>`}).join('');
    parts[i].guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${X-x}" height="${Y-y}">${lines}</svg>`;
    parts[i].report={geometry:REVIEW+'/geometry.json',adaptation:'v2: outer jambs below wall height replaced by flush masonry blocks after user join/style rejection; upper/inner frame, leaf, horns and seals unchanged',stone:'existing walls-planes texture and B.materials render profiles; generated facade used only for wood/metal/seal',projection:P.camera,source:REVIEW+'/painted-v1/face-source.png',fit:mat.fit,packedRasterScale:.8,split:'whole final pixels at wall height, 2px opaque colour overlap',overlap,sourceAlpha:'generated alpha retained in original; prepared alpha derives exclusively from XYZ model'};
  }
  return {parts,full:{png,frame:f,bounds:bounds(m.faces)},model:m};
}
async function doors(d){return (await paint(d)).parts;}
module.exports={doors,paint,geometry,referenceFiles};
