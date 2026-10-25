// Edge/corner crack proposal. Derived from the frozen v1 projector, SHA256 10b56c61ed89586bc7bbc8b22123b50b83ffd67e14769498e0f52e5ed9149e3c.
// This writes an appearance review, not the active dungeon catalogue.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const OUT='docs/reference/isometric-decoration-review/v2-edge-cracks',S=4;
const save=(p,b)=>write(path.join(P.ROOT,OUT,p),b);
const json=(p,v)=>save(p,JSON.stringify(v,null,2)+'\n');
const IDS=['corner-split','vertical-hairline','edge-fork'];
const sourceId=id=>id==='vertical-hairline'?'vertical-hairline-readable':id;
const labels=['Coin fendu','Cassure verticale','Fissure latérale'];
function sample(im,x,y) {
  const {data,info}=im;if(x<0||y<0||x>info.width-1||y>info.height-1)return [0,0,0,0];
  const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,r=[0,0,0,0];
  for(const [u,v,w] of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]) {
    const i=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[i+3]/255;
    r[3]+=a*w;for(let c=0;c<3;c++)r[c]+=data[i+c]*a*w;
  }
  if(r[3])for(let c=0;c<3;c++)r[c]/=r[3];return r;
}
function segmentDistance(q,a,b) {
  const u=[b[0]-a[0],b[1]-a[1]],d=u[0]*u[0]+u[1]*u[1];
  const t=d?Math.max(0,Math.min(1,((q[0]-a[0])*u[0]+(q[1]-a[1])*u[1])/d)):0;
  return Math.hypot(q[0]-a[0]-t*u[0],q[1]-a[1]-t*u[1]);
}
async function prepare(id,surface,index) {
  const file=OUT+'/source/'+sourceId(id)+'.png',im=await sharp(path.join(P.ROOT,file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const box=[im.info.width,im.info.height,-1,-1];
  // Threshold measures the solid motif for scale only; every native-alpha pixel
  // is still sampled, including its faint perimeter. Never extract a background.
  for(let y=0;y<im.info.height;y++)for(let x=0;x<im.info.width;x++)if(im.data[(y*im.info.width+x)*4+3]>=128) {
    box[0]=Math.min(box[0],x);box[1]=Math.min(box[1],y);box[2]=Math.max(box[2],x);box[3]=Math.max(box[3],y);
  }
  if(box[2]<0)throw Error('No solid subject in '+id);
  const ground=surface==='floor',h=surface==='wall-h';
  // Place native-alpha art against the edges of one actual central stone.
  // UV is a physical surface plane, never a screen-space stretch/rotation.
  const brick=ground?{left:.30,right:.64,top:1/3,bottom:2/3}:{left:1/3,right:2/3,top:0,bottom:P.H/2};
  const w=box[2]-box[0]+1,hh=box[3]-box[1]+1;
  const scale=(ground?(id==='edge-fork'?.18:id==='vertical-hairline'?.22:.15):(id==='edge-fork'?.15:id==='corner-split'?.095:.14))/(id==='edge-fork'?w:hh);
  let origin,target;
  if(id==='corner-split') {origin=[box[0]+w*.08,box[3]-hh*.08];target=[brick.left,brick.bottom];}
  else if(id==='vertical-hairline') {origin=[(box[0]+box[2])/2,box[1]+hh*.16];target=[(brick.left+brick.right)/2,brick.top];}
  else {origin=[box[2]-w*.12,(box[1]+box[3])/2];target=[brick.right,brick.top+(brick.bottom-brick.top)*.55];}
  const fromUV=(u,v)=>ground?[u,v,0]:h?[u,P.T/2,P.H-v]:[P.T/2,1-u,P.H-v];
  const centre=fromUV(...target),angle=0;
  const toWorld=(x,y)=>fromUV(target[0]+(x-origin[0])*scale,target[1]+(y-origin[1])*scale);
  const corners=[[0,0],[im.info.width,0],[im.info.width,im.info.height],[0,im.info.height]].map(p=>P.project(toWorld(...p)));
  const lo=[0,1].map(i=>Math.floor(Math.min(...corners.map(p=>p[i])))-2),hi=[0,1].map(i=>Math.ceil(Math.max(...corners.map(p=>p[i])))+2);
  const frame=[...lo,...hi.map((v,i)=>v-lo[i])],width=frame[2]*S,height=frame[3]*S,buf=Buffer.alloc(width*height*4);
  const model=P.models.find(m=>m.id===(ground?'floor':surface+'-0')),cast=P.caster(model),n=ground?[0,0,1]:h?[0,1,0]:[1,0,0];
  const joints=model.visibleEdges.filter(e=>e.kind==='joint').map(e=>[P.project(e.a),P.project(e.b)]);
  for(let y=0;y<height;y++)for(let x=0;x<width;x++) {
    const screen=[lo[0]+(x+.5)/S,lo[1]+(y+.5)/S],p=P.onPlane(screen,centre,n),hit=cast(screen);
    if(!hit||P.dot(P.sub(hit.p,p),P.sub(hit.p,p))>1e-8)continue;
    // Recessed mortar stays visible; damage sits on masonry, not over its gaps.
    if(!ground&&joints.some(([a,b])=>segmentDistance(screen,a,b)<.65))continue;
    const U=ground?p[0]:h?p[0]:1-p[1],V=ground?p[1]:P.H-p[2];
    // Only the chosen stone receives damage; never bridge the mortar or its neighbour.
    if(U<brick.left||U>brick.right||V<brick.top||V>brick.bottom)continue;
    const u=U-target[0],v=V-target[1];
    const rgba=sample(im,origin[0]+u/scale,origin[1]+v/scale),k=(y*width+x)*4;
    for(let channel=0;channel<3;channel++)buf[k+channel]=Math.round(rgba[channel]);
    buf[k+3]=Math.round(255*rgba[3]);
  }
  let png=await sharp(buf,{raw:{width,height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
  // Discard only exactly transparent padding after projection; preserve every
  // nonzero alpha pixel and retain two transparent filtering pixels per edge.
  const decoded=await sharp(png).ensureAlpha().raw().toBuffer(),extent=[frame[2],frame[3],-1,-1];
  for(let y=0;y<frame[3];y++)for(let x=0;x<frame[2];x++)if(decoded[(y*frame[2]+x)*4+3]>0) {
    extent[0]=Math.min(extent[0],x);extent[1]=Math.min(extent[1],y);extent[2]=Math.max(extent[2],x);extent[3]=Math.max(extent[3],y);
  }
  if(extent[2]<0)throw Error('Empty projected crack: '+id+' '+surface);
  const left=Math.max(0,extent[0]-2),top=Math.max(0,extent[1]-2);
  const cropWidth=Math.min(frame[2]-1,extent[2]+2)-left+1,cropHeight=Math.min(frame[3]-1,extent[3]+2)-top+1;
  png=await sharp(png).extract({left,top,width:cropWidth,height:cropHeight}).png().toBuffer();
  frame[0]+=left;frame[1]+=top;frame[2]=cropWidth;frame[3]=cropHeight;
  const entry={id:id+'-'+surface,motif:id,surface,label:labels[index],frame,size:frame.slice(2),offset:frame.slice(0,2),file:OUT+'/sprites/'+id+'-'+surface+'.png',bytes:png.length,
    source:file,sourceSHA256:P.hash(file),sourceSolidBounds:box,worldPerSourcePixel:scale,centre,targetStone:brick,sourceAnchor:origin,surfaceAnchor:target,rotationInGroundPlaneDegrees:angle*180/Math.PI,alpha:'Native alpha preserved; geometric surface visibility and mortar occlusion only'};
  save('sprites/'+entry.id+'.png',png);return {...entry,png};
}
async function main(){
  const items=[];for(const [i,id] of IDS.entries())for(const surface of ['floor','wall-h','wall-v'])items.push(await prepare(id,surface,i));
  // Small separate review atlas, three orientations by four motifs. No active
  // architecture copy is baked into these transparent overlay sprites.
  const W=256,H=256,regions={},layers=[];
  for(const [i,item] of items.entries()) {
    const column=i%3,row=Math.floor(i/3),x=column*84+3,y=row*80+3;
    if(item.size[0]>78||item.size[1]>74)throw Error('Decal exceeded small review slot: '+item.id);
    layers.push({input:item.png,left:x,top:y});regions[item.id]=[x,y,...item.size];
  }
  const atlas=await sharp({create:{width:W,height:H,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toBuffer();
  save('atlas.png',atlas);
  json('prepared.json',{status:'appearance review, not active production kit',projection:P.camera,sourcePixelsPerCell:256,zoom:.75,
    atlas:{file:OUT+'/atlas.png',size:[W,H],bytes:atlas.length,rgbaBytes:W*H*4},
    geometrySHA256:P.hash('docs/reference/isometric-review/migration-v1/geometry.json'),
    sources:IDS.map(id=>({id,file:OUT+'/source/'+sourceId(id)+'.png',sha256:P.hash(OUT+'/source/'+sourceId(id)+'.png')})),
    entries:items.map(({png,...entry})=>({...entry,region:regions[entry.id]})),
    notes:['Three different native-alpha ImageGen cracks anchored at physical stone edges/corners in three exact planes.','Runtime places prepared regions, no perspective warp.','Mortar occlusion is baked, source pixels are neither recoloured nor threshold-extracted.','Edge/corner placements are a new proposal. Production art, placement policy and frozen v1 references unchanged.']});
  console.log(JSON.stringify({sprites:items.length,atlas:[W,H],pngBytes:atlas.length,rgbaBytes:W*H*4}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
