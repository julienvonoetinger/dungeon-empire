// Offline material/mask painting of the approved mesh, at fixed kit projection.
// Generated artwork supplies iron and flame only; it cannot move the structure.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),BASE='docs/reference/mobile-light-review',OUT=BASE+'/painted-v2',S=4,PX=256;
const read=p=>fs.readFileSync(path.join(ROOT,p)),hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const json=p=>JSON.parse(read(p).toString().replace(/^\uFEFF/,''));
const save=(p,data)=>write(path.join(ROOT,OUT,p),data);
const sub=(a,b)=>a.map((v,i)=>v-b[i]),dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const norm=a=>{const n=Math.hypot(...a);return a.map(v=>v/n);};
const project=([x,y,z])=>[(x-.18*z)*PX,(y-.9*z)*PX];
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const prop=f=>!['wall','joint'].includes(f.kind);
const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${body}</svg>`;
const text=(x,y,size,value,color='#e5edf7')=>`<text x="${x}" y="${y}" font-family="Segoe UI,Arial,sans-serif" font-size="${size}" fill="${color}">${value}</text>`;

async function pixels(p) {return sharp(read(p)).ensureAlpha().raw().toBuffer({resolveWithObject:true});}
function opaqueBounds(image) {
  const {data,info}=image,b=[info.width,info.height,-1,-1];
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>128){b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
  return b;
}
// Premultiplied bilinear sampling retains faint native flame alpha without halos
// from hidden RGB. Thresholds are used for measurements, never alpha extraction.
function sample(image,x,y) {
  const {data,info}=image;if(x<0||y<0||x>info.width-1||y>info.height-1)return [0,0,0,0];
  const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,r=[0,0,0,0];
  for(const [u,v,w] of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]){
    const k=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[k+3]/255;
    r[3]+=a*w;for(let c=0;c<3;c++)r[c]+=data[k+c]*a*w;
  }
  if(r[3]>1e-8)for(let c=0;c<3;c++)r[c]/=r[3];return r;
}

function raster(model,frame) {
  const width=frame[2]*S,height=frame[3]*S,depth=new Float64Array(width*height).fill(-Infinity);
  const surface=new Int32Array(width*height).fill(-1);
  for(let index=0;index<model.faces.length;index++){
    const face=model.faces[index];
    for(let j=1;j<face.points.length-1;j++){
      const p=[face.points[0],face.points[j],face.points[j+1]].map(q=>{const s=project(q);return [(s[0]-frame[0])*S,(s[1]-frame[1])*S,q[2]];});
      const [a,b,c]=p,den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);if(Math.abs(den)<1e-10)continue;
      const lo=[0,1].map(i=>Math.max(0,Math.floor(Math.min(...p.map(v=>v[i]))))),hi=[0,1].map(i=>Math.min([width,height][i]-1,Math.ceil(Math.max(...p.map(v=>v[i])))));
      for(let y=lo[1];y<=hi[1];y++)for(let x=lo[0];x<=hi[0];x++){
        const u=((b[1]-c[1])*(x+.5-c[0])+(c[0]-b[0])*(y+.5-c[1]))/den,v=((c[1]-a[1])*(x+.5-c[0])+(a[0]-c[0])*(y+.5-c[1]))/den,w=1-u-v;
        if(Math.min(u,v,w)<-1e-8)continue;
        const z=u*a[2]+v*b[2]+w*c[2],k=y*width+x;
        if(z>depth[k]+1e-9){depth[k]=z;surface[k]=index;}
      }
    }
  }
  return {width,height,depth,surface};
}

async function paint(model,metal,flame,flameBounds) {
  const centre=model.bowlCentre;
  // The flame occupies a vertical XZ plane through the cup. Both orientations
  // use that SAME world-facing flame and the same upward kit projection.
  const solidHeight=flameBounds[3]-flameBounds[1]+1,sourceBase=flameBounds[3]-solidHeight*.012;
  // Centre the rounded base, not the asymmetric tongues of the upper fire.
  let rootLeft=flame.info.width,rootRight=-1;
  for(let y=Math.ceil(flameBounds[3]-.08*solidHeight);y<=flameBounds[3];y++)for(let x=flameBounds[0];x<=flameBounds[2];x++){
    if(flame.data[(y*flame.info.width+x)*4+3]>128){rootLeft=Math.min(rootLeft,x);rootRight=Math.max(rootRight,x);}
  }
  const sourceCentre=(rootLeft+rootRight+1)/2;
  // Rounded fire starts inside the cavity; its lowest edge meets the front rim.
  // Uniformly reduce the complete source so its lower body fits the opening.
  const zBase=.20,solidWorldHeight=.215,worldPerPixel=.9*solidWorldHeight/solidHeight;
  // The redrawn source has a full rounded base. ONE image scale preserves its aspect
  // before the existing kit height shear. Never compress only the horizontal axis.
  const worldPerPixelX=worldPerPixel;
  const bowlPoints=model.faces.filter(f=>f.kind==='bowl').flatMap(f=>f.points);
  const rimZ=Math.max(...bowlPoints.map(p=>p[2]));
  const innerRadius=Math.min(...bowlPoints.filter(p=>Math.abs(p[2]-rimZ)<1e-8).map(p=>Math.hypot(p[0]-centre[0],p[1]-centre[1])));
  const solidWidth=flameBounds[2]-flameBounds[0]+1;
  const flamePoint=(x,y)=>[centre[0]+(x-sourceCentre)*worldPerPixelX,centre[1],zBase+(sourceBase-y)*worldPerPixel/.9];
  const flameCorners=[[0,0],[flame.info.width,0],[flame.info.width,flame.info.height],[0,flame.info.height]].map(p=>flamePoint(...p));
  const points=[...model.faces.filter(prop).flatMap(f=>f.points),...flameCorners].map(project);
  const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-3),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+3);
  const frame=[...lo,...hi.map((v,i)=>v-lo[i])],mesh=raster(model,frame);
  const {width,height,depth,surface}=mesh,body=Buffer.alloc(width*height*4),full=Buffer.alloc(body.length);
  const normals=model.faces.map(f=>{
    let n=norm(cross(sub(f.points[1],f.points[0]),sub(f.points[2],f.points[0])));
    if(dot(n,[.18,.9,1])<0)n=n.map(v=>-v);return n;
  });
  const local=p=>model.orientation==='horizontal'?[p[0]-.5,p[1]-1/12,p[2]]:[.5-p[1],p[0]-1/12,p[2]];
  const lightDirection=norm([-.4,.6,1]);
  const emitter=[centre[0],centre[1],.36];
  // Fine dark outlines are clipped INSIDE the exact structural silhouette.
  const lineBody=model.visibleEdges.filter(prop).map(e=>{
    const a=project(e.a).map((v,i)=>(v-lo[i])*S),b=project(e.b).map((v,i)=>(v-lo[i])*S);
    return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="white" stroke-width="${.72*S}" stroke-linecap="round"/>`;
  }).join('');
  const ink=await sharp(Buffer.from(svg(width,height,lineBody))).ensureAlpha().raw().toBuffer();
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const k=y*width+x,i=k*4,s=surface[k],screen=[lo[0]+(x+.5)/S,lo[1]+(y+.5)/S];
    if(s>=0&&prop(model.faces[s])){
      const z=depth[k],p=[screen[0]/PX+.18*z,screen[1]/PX+.9*z,z],q=local(p),n=normals[s];
      const tex=sample(metal,clamp((q[0]+.10)/.20)*(metal.info.width-1),clamp((q[2]-.02)/.27+(q[1]-.113)*.5)*(metal.info.height-1));
      const diffuse=.65+.42*Math.max(0,dot(n,lightDirection));
      const toward=sub(emitter,p),distance=Math.hypot(...toward),warm=Math.max(0,dot(n,norm(toward)))/(1+5*distance);
      for(let c=0;c<3;c++){
        const value=tex[c]*diffuse+[140,73,17][c]*warm;
        const dark=ink[i+3]/255*.78;
        body[i+c]=clamp(Math.round(value*(1-dark)+[9,14,24][c]*dark),0,255);
      }
      body[i+3]=255;
    }
    body.copy(full,i,i,i+4);
    const flameZ=(centre[1]-screen[1]/PX)/.9;
    const sy=sourceBase-(flameZ-zBase)*.9/worldPerPixel;
    const sx=sourceCentre+(screen[0]/PX+.18*flameZ-centre[0])/worldPerPixelX;
    if(flameZ>=depth[k]-1e-8){
      const fire=sample(flame,sx,sy),a=fire[3],old=full[i+3]/255,A=a+old*(1-a);
      if(A>0){for(let c=0;c<3;c++)full[i+c]=Math.round((fire[c]*a+full[i+c]*old*(1-a))/A);full[i+3]=Math.round(A*255);}
    }
  }
  const png=raw=>sharp(raw,{raw:{width,height,channels:4}}).resize(frame[2],frame[3],{kernel:'lanczos3'}).png().toBuffer();
  const bodyPNG=await png(body),fullPNG=await png(full),id='torch-'+model.orientation;
  save(`prepared/${id}.png`,fullPNG);save(`prepared/${id}-metal.png`,bodyPNG);
  // Colour guide for inspection: structural edges only, without hidden wall lines.
  const guideXML=lineBody.replaceAll('white','#ff35ee');
  const guide=await sharp(Buffer.from(svg(width,height,guideXML))).resize(frame[2],frame[3]).png().toBuffer();
  save(`prepared/${id}-guide.png`,guide);
  save(`prepared/${id}-overlay.png`,await sharp(bodyPNG).composite([{input:guide}]).png().toBuffer());
  return {id,orientation:model.orientation,file:`${OUT}/prepared/${id}.png`,size:frame.slice(2),offset:lo,
    bounds:{min:[0,1,2].map(i=>Math.min(...model.faces.filter(prop).flatMap(f=>f.points.map(p=>p[i])))),max:[0,1,2].map(i=>Math.max(...model.faces.filter(prop).flatMap(f=>f.points.map(p=>p[i]))))},
    emission:project(emitter),bytes:fullPNG.length,sha256:hash(fullPNG),metalSha256:hash(bodyPNG),
    flame:{nativeAlpha:true,verticalPlaneY:centre[1],baseZ:zBase,sourceBase,sourceCentre,worldPerPixel,worldPerPixelX,solidWorldHeight,
      aspectPreservedBeforeKitShear:true,aperture:{innerRadius,rimZ},solidWorldWidth:solidWidth*worldPerPixel},
    radius:190,energy:2.4,color:[1,.44,.12]};
}

async function boards(entries) {
  const panels=[];let labels='';
  for(let row=0;row<2;row++){
    const e=entries[row],top=80+row*450;
    labels+=text(28,top-15,21,row===0?'A — Mur horizontal':'B — Mur vertical');
    for(let c=0;c<3;c++){
      const suffix=['-metal','-overlay',''][c],file=`${OUT}/prepared/${e.id}${suffix}.png`;
      const resized=await sharp(read(file)).resize(e.size[0]*3,e.size[1]*3,{kernel:'nearest'}).png().toBuffer();
      const meta=await sharp(resized).metadata();
      panels.push({input:resized,left:30+c*300+Math.floor((270-meta.width)/2),top:top+Math.floor((370-meta.height)/2)});
      labels+=text(38+c*300,top+395,15,['Métal — pixels agrandis ×3','Guide superposé','Avec la flamme'][c],'#aab8cd');
    }
  }
  labels+=text(28,28,23,'Peinture sur la structure validée');
  save('structure-comparison.png',await sharp({create:{width:930,height:1000,channels:4,background:'#0b1019'}}).composite([...panels,{input:Buffer.from(svg(930,1000,labels)),left:0,top:0}]).png().toBuffer());
}
async function main(){
  const selection=json(BASE+'/wireframe-v1/selection.json'),geometryBytes=read(selection.geometry);
  if(hash(geometryBytes)!==selection.geometrySha256)throw Error('Approved geometry differs from frozen selection');
  const geometry=JSON.parse(geometryBytes),metal=await pixels(OUT+'/source/metal.png'),flame=await pixels(OUT+'/source/flame-v3.png');
  const flameBounds=opaqueBounds(flame),entries=[];
  for(const model of geometry.models)entries.push(await paint(model,metal,flame,flameBounds));
  save('prepared.json',JSON.stringify({status:'painted appearance proposal',geometry:selection.geometry,geometrySha256:selection.geometrySha256,
    flameSource:OUT+'/source/flame-v3.png',
    sourceHashes:{metal:hash(read(OUT+'/source/metal.png')),flame:hash(read(OUT+'/source/flame-v3.png'))},flameBounds,
    sourcePixelsPerCell:256,zoom:.75,entries},null,2)+'\n');
  await boards(entries);
  console.log(JSON.stringify(entries.map(e=>({id:e.id,size:e.size,bytes:e.bytes}))));
}
async function captureBoards(){
  const source=read(OUT+'/captures/with-local-light.png');
  save('game-view.png',await sharp(source).extract({left:300,top:90,width:670,height:530}).png().toBuffer());
  const layers=[];
  for(const [i,crop] of [{left:576,top:133,width:110,height:110},{left:330,top:370,width:110,height:150}].entries()){
    layers.push({input:await sharp(source).extract(crop).resize(crop.width*2,crop.height*2,{kernel:'nearest'}).png().toBuffer(),left:20+i*260,top:45});
  }
  const labels=text(20,28,17,'Mur horizontal — ×2')+text(280,28,17,'Mur vertical — ×2');
  save('attachment-details.png',await sharp({create:{width:520,height:365,channels:4,background:'#0b1019'}})
    .composite([...layers,{input:Buffer.from(svg(520,365,labels)),left:0,top:0}]).png().toBuffer());
  const previous=path.join(ROOT,OUT,'flame-base-review/before/attachment-details.png');
  if(fs.existsSync(previous)){
    const crop={left:20,top:45,width:220,height:220};
    const before=await sharp(previous).extract(crop).png().toBuffer();
    const after=await sharp(read(OUT+'/attachment-details.png')).extract(crop).png().toBuffer();
    const titles=text(20,30,18,'Avant — base en pointe')+text(260,30,18,'Après — base arrondie');
    save('flame-base-review/comparison.png',await sharp({create:{width:500,height:290,channels:4,background:'#0b1019'}})
      .composite([{input:before,left:20,top:50},{input:after,left:260,top:50},{input:Buffer.from(svg(500,290,titles)),left:0,top:0}]).png().toBuffer());
  }
}
(process.argv.includes('--boards')?captureBoards():main()).catch(error=>{console.error(error);process.exitCode=1;});
