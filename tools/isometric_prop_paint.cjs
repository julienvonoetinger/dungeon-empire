// Reproject existing approved artwork offline. No new painting, runtime warp,
// or change to the frozen isometric rigid volumes.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const S=4,clamp=(x,a=0,b=1)=>Math.max(a,Math.min(b,x));
const smooth=x=>{x=clamp(x);return x*x*(3-2*x);};
const sources={
  metal:['docs/reference/mobile-light-review/painted-v2/source/metal.png','c9e04151256191cb15a3499e69672dda962bfae863612d73b026da74bf696f9a'],
  flame:['docs/reference/mobile-light-review/painted-v2/source/flame-v3.png','3b5c8257d207ebc385c2efb975a31318c9399f8ae8c028427f2c05290b1b6bd2'],
  heart:['docs/reference/mobile-heart-review/ritual-v3/source/a.png','c05bfe3218c1ae045218bff300d5c5d5589b4611043ab7ce168acc60399e2bc7'],
  cap:['docs/reference/pillar-cap-review/source/carved-top.png','f8610535c3246f4b4105a7821dab71c3f865d59276e9fe35753b87725556d422']
};
async function pixels(key) {
  const [p,hash]=sources[key];if(hash&&P.hash(p)!==hash)throw Error('Approved art changed: '+p);
  return sharp(fs.readFileSync(path.join(P.ROOT,p))).ensureAlpha().raw().toBuffer({resolveWithObject:true});
}
// Premultiplied bilinear alpha; measurements never replace the native alpha.
function sample(im,x,y) {
  const {data,info}=im;if(x<0||y<0||x>info.width-1||y>info.height-1)return [0,0,0,0];
  const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,r=[0,0,0,0];
  for(const [u,v,w] of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]) {
    const k=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[k+3]/255;
    r[3]+=a*w;for(let c=0;c<3;c++)r[c]+=data[k+c]*a*w;
  }
  if(r[3]>1e-8)for(let c=0;c<3;c++)r[c]/=r[3];return r;
}
function over(buf,i,col) {
  const a=col[3],old=buf[i+3]/255,A=a+old*(1-a);if(A<=0)return;
  for(let c=0;c<3;c++)buf[i+c]=Math.round((col[c]*a+buf[i+c]*old*(1-a))/A);buf[i+3]=Math.round(A*255);
}
const encoded=(buf,mesh,frame)=>sharp(buf,{raw:{width:mesh.width,height:mesh.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
async function strokes(m,frame,width=.72) {
  const body=m.visibleEdges.map(e=>{const a=P.project(e.a),b=P.project(e.b);return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="white" stroke-width="${width}" stroke-linecap="round"/>`;}).join('');
  return sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]*S}" height="${frame[3]*S}" viewBox="${frame.join(' ')}">${body}</svg>`)).ensureAlpha().raw().toBuffer();
}
async function torch(m) {
  const metal=await pixels('metal'),flame=await pixels('flame'),b=[flame.info.width,flame.info.height,-1,-1];
  for(let y=0;y<flame.info.height;y++)for(let x=0;x<flame.info.width;x++)if(flame.data[(y*flame.info.width+x)*4+3]>128) {
    b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);
  }
  const solidHeight=b[3]-b[1]+1,sourceBase=b[3]-.012*solidHeight,root=[flame.info.width,-1];
  for(let y=Math.ceil(b[3]-.08*solidHeight);y<=b[3];y++)for(let x=b[0];x<=b[2];x++)if(flame.data[(y*flame.info.width+x)*4+3]>128) {root[0]=Math.min(root[0],x);root[1]=Math.max(root[1],x);}
  const sourceCentre=(root[0]+root[1]+1)/2,vertical=-P.camera.y[2],scale=vertical*.215*P.PX/solidHeight;
  const horizontal=m.id.endsWith('horizontal'),centre=horizontal?[.5,P.T/2+.113,0]:[P.T/2+.113,.5,0];
  const base=P.project([centre[0],centre[1],.20]);
  const screen=m.faces.flatMap(f=>f.points).map(P.project);
  screen.push([base[0]-sourceCentre*scale,base[1]-sourceBase*scale],[base[0]+(flame.info.width-sourceCentre)*scale,base[1]+(flame.info.height-sourceBase)*scale]);
  const lo=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-3),hi=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+3),frame=[...lo,...hi.map((v,i)=>v-lo[i])];
  const mesh=P.raster(m,frame),body=Buffer.alloc(mesh.width*mesh.height*4),full=Buffer.alloc(body.length),ink=await strokes(m,frame),normals=m.faces.map(f=>P.normal(f.points));
  const light=[-.4,.6,1].map(v=>v/Math.hypot(-.4,.6,1)),emitter=[...centre.slice(0,2),.36];
  for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++) {
    const k=y*mesh.width+x,i=k*4,owner=mesh.owner[k],screen=[lo[0]+(x+.5)/S,lo[1]+(y+.5)/S];
    if(owner>=0) {
      const p=Array.from(mesh.xyz.slice(k*3,k*3+3)),q=horizontal?[p[0]-.5,p[1]-P.T/2,p[2]]:[.5-p[1],p[0]-P.T/2,p[2]],n=normals[owner];
      const tex=sample(metal,clamp((q[0]+.10)/.20)*(metal.info.width-1),clamp((q[2]-.02)/.27+(q[1]-.113)*.5)*(metal.info.height-1));
      const toward=P.sub(emitter,p),distance=Math.hypot(...toward),warm=Math.max(0,P.dot(n,toward.map(v=>v/Math.max(1e-6,distance))))/(1+5*distance),diffuse=.65+.42*Math.max(0,P.dot(n,light));
      for(let c=0;c<3;c++){const dark=ink[i+3]/255*.78;body[i+c]=clamp(Math.round((tex[c]*diffuse+[140,73,17][c]*warm)*(1-dark)+[9,14,24][c]*dark),0,255);}
      body[i+3]=255;
    }
    body.copy(full,i,i,i+4);
    // Billboard plane has constant x+y. It preserves a single SCREEN scale,
    // while its depth still lets the physical front cup rim hide the root.
    const sum=centre[0]+centre[1],diff=screen[0]*2/P.PX,z=(sum/4-screen[1]/P.PX)/vertical,p=[(sum+diff)/2,(sum-diff)/2,z];
    if(P.dot(p,P.camera.eye)>=mesh.depth[k]-1e-8)over(full,i,sample(flame,sourceCentre+(screen[0]-base[0])/scale,sourceBase+(screen[1]-base[1])/scale));
  }
  return {id:m.id,frame,bounds:m.bounds,png:await encoded(full,mesh,frame),metalPNG:await encoded(body,mesh,frame),light:{emission:P.project(emitter),emitter_world:emitter,radius:190,energy:2.4,color:[1,.44,.12]},
    adaptation:{sourceCentre,sourceBase,uniformScreenScale:scale,baseZ:.20,solidWorldHeight:.215,plane:'camera-facing vertical; constant x+y; metal depth occlusion'}};
}
async function cap(m,base) {
  const im=await pixels('cap'),frame=m.frame,mesh=P.raster(m,frame),raw=await sharp(base.rawHigh).ensureAlpha().raw().toBuffer(),out=Buffer.alloc(raw.length),q=P.PILLAR/2;
  for(let k=0;k<mesh.owner.length;k++)if(mesh.owner[k]>=0) {
    const [x,y,z]=mesh.xyz.slice(k*3,k*3+3);if(Math.abs(z-(P.H+.035))>1e-8)continue;
    const distance=Math.min(x+q,q-x,y+q,q-y)*P.PX;if(distance<=3)continue;
    const mix=smooth((distance-3)/3),tex=sample(im,(x+q)/(2*q)*(im.info.width-1),(y+q)/(2*q)*(im.info.height-1)),i=k*4;
    for(let c=0;c<3;c++)out[i+c]=Math.round(raw[i+c]*(1-mix)+tex[c]*mix);out[i+3]=255;
  }
  return {id:'pillar-top-carved',frame,bounds:m.bounds,png:await encoded(out,mesh,frame),adaptation:{source:sources.cap[0],sha256:P.hash(sources.cap[0]),preservedRimSourcePixels:3,blendSourcePixels:3}};
}
async function heart(m) {
  const im=await pixels('heart'),unit=im.info.width/289,tex=(x,y)=>sample(im,x*unit,y*unit),frame=[m.frame[0],m.frame[1]-20,m.frame[2],m.frame[3]+20],mesh=P.raster(m,frame),raw=Buffer.alloc(mesh.width*mesh.height*4),ink=await strokes(m,frame,.5);
  const normals=m.faces.map(f=>P.normal(f.points));
  for(let k=0;k<mesh.owner.length;k++)if(mesh.owner[k]>=0) {
    const p=Array.from(mesh.xyz.slice(k*3,k*3+3)),[x,y,z]=p,n=normals[mesh.owner[k]],i=k*4,top=n[2]>.7;let c;
    if(top&&z>.225) {
      // The four approved sculpted diamond caps share one local square plane.
      const cx=Math.sign(x)*.295,cy=Math.sign(y)*.295;
      c=tex(68.5+(x-cx)/.17*39,88+(y-cy)/.17*39);
    } else if(top&&z>.14) {
      // Reuse the unobscured lower ritual field, reflecting only its hidden
      // back half. The source vortex is never flattened into the stone top.
      c=tex(144.5+x/.325*71,166+Math.abs(y)/.325*62);
    } else if(top) {
      const edge=Math.max(Math.abs(x),Math.abs(y));
      c=tex(144.5+(Math.abs(x)>Math.abs(y)?y:x)/.40625*92,246+(edge-.325)/.08125*9);
    } else if(z>.15&&Math.abs(x)>.20&&Math.abs(y)>.20) {
      const u=Math.abs(n[0])>.5?y:x,centre=Math.sign(u)*.295;
      c=tex(68.5+(u-centre)/.15*38,103+(.23-z)/.08*17);
    } else {
      // Sample the stone fascia above the original painted contact shadow.
      // Rows 250..260 included shadow/transparent RGB and became an opaque
      // black band when mapped onto this rigid side reaching the ground.
      const u=Math.abs(n[0])>.5?y:x;c=tex(144.5+u/.40625*94,242+(1-clamp(z/.15))*10);
    }
    const shade=top?1:(Math.abs(n[0])>.5?.73:.88),dark=ink[i+3]/255*.48;
    for(let j=0;j<3;j++)raw[i+j]=clamp(Math.round(c[j]*shade*(1-dark)+[9,13,25][j]*dark),0,255);raw[i+3]=255;
  }
  const centre=P.project(m.orb.centre),sourceCentre=[144.5,88],scale=P.PX*m.orb.radius/54;
  for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++) {
    const k=y*mesh.width+x,sx=frame[0]+(x+.5)/S,sy=frame[1]+(y+.5)/S;
    const u=sourceCentre[0]+(sx-centre[0])/scale,v=sourceCentre[1]+(sy-centre[1])/scale;
    // The original glow is above the orb. At its sides the painting already
    // contains pedestal stones: exclude those with a tighter spatial window.
    const topGlow=1-smooth((v-35)/30),circle=1-smooth((Math.hypot(u-144.5,v-88)-54-12*topGlow)/(3+6*topGlow));
    const neck=(1-smooth((Math.abs(u-144.5)-7)/6))*smooth((v-125)/8)*(1-smooth((v-168)/6));
    const mask=Math.max(circle,neck);if(mask<=0)continue;
    const c=tex(u,v);c[3]*=mask;
    // Same constant-x+y billboard as the flame; support is still depth-tested.
    const z=-sy/(P.PX*-P.camera.y[2]),diff=sx*2/P.PX,p=[diff/2,-diff/2,z];
    if(P.dot(p,P.camera.eye)>=mesh.depth[k]-1e-8)over(raw,k*4,c);
  }
  return {id:m.id,frame,bounds:m.bounds,png:await encoded(raw,mesh,frame),vortex:{center:centre.map((v,i)=>v-frame[i]),radius:54*scale},adaptation:{source:sources.heart[0],sourceSha256:sources.heart[1],rigidGeometry:'frozen migration-v1',mapping:'Approved caps, lower ritual field and border mapped to rigid XYZ support. Hidden back field reflected. Original vortex retained as a camera-facing layer with spatial feather mask.',groundFasciaSourceRows:[242,252],groundContactZ:0,vortex:{sourceCentre,radius:54,uniformScale:scale},status:'reprojected appearance; not a new artwork approval'}};
}
module.exports={torch,heart,cap,sources};
