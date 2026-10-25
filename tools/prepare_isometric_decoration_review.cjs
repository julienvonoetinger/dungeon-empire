// Native-alpha damage art, projected offline onto the approved surface planes.
// This writes an appearance review, not the active dungeon catalogue.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const OUT='docs/reference/isometric-decoration-review/v1',S=4;
const save=(p,b)=>write(path.join(P.ROOT,OUT,p),b);
const json=(p,v)=>save(p,JSON.stringify(v,null,2)+'\n');
const IDS=['crack-short','crack-branch','chip-worn','crack-corrupt'];
const sourceId=id=>['crack-short','chip-worn'].includes(id)?id+'-v2':id;
const labels=['Fissure courte','Fracture ramifiée','Pierre ébréchée','Corruption discrète'];
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
  const centre=ground?[.47,.50,0]:h?[.50,P.T/2,.18]:[P.T/2,.50,.18];
  const angle=ground?[20,-20,25,-15][index]*Math.PI/180:0,c=Math.cos(angle),s=Math.sin(angle);
  const scale=(ground?.26:.235)/Math.max(box[2]-box[0]+1,box[3]-box[1]+1);
  const origin=[(box[0]+box[2])/2,(box[1]+box[3])/2];
  const toWorld=(x,y)=>{
    const u=(x-origin[0])*scale,v=(y-origin[1])*scale;
    return ground?[centre[0]+c*u-s*v,centre[1]+s*u+c*v,0]:h?[centre[0]+u,centre[1],centre[2]-v]:[centre[0],centre[1]-u,centre[2]-v];
  };
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
    let u,v;
    if(ground){const X=p[0]-centre[0],Y=p[1]-centre[1];u=c*X+s*Y;v=-s*X+c*Y;}
    else {u=h?p[0]-centre[0]:centre[1]-p[1];v=centre[2]-p[2];}
    const rgba=sample(im,origin[0]+u/scale,origin[1]+v/scale),k=(y*width+x)*4;
    for(let channel=0;channel<3;channel++)buf[k+channel]=Math.round(rgba[channel]);
    buf[k+3]=Math.round(255*rgba[3]);
  }
  const png=await sharp(buf,{raw:{width,height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
  const entry={id:id+'-'+surface,motif:id,surface,label:labels[index],frame,size:frame.slice(2),offset:frame.slice(0,2),file:OUT+'/sprites/'+id+'-'+surface+'.png',bytes:png.length,
    source:file,sourceSHA256:P.hash(file),sourceSolidBounds:box,worldPerSourcePixel:scale,centre,rotationInGroundPlaneDegrees:angle*180/Math.PI,alpha:'Native alpha preserved; geometric surface visibility and mortar occlusion only'};
  save('sprites/'+entry.id+'.png',png);return {...entry,png};
}
async function main(){
  const items=[];for(const [i,id] of IDS.entries())for(const surface of ['floor','wall-h','wall-v'])items.push(await prepare(id,surface,i));
  // Small separate review atlas, three orientations by four motifs. No active
  // architecture copy is baked into these transparent overlay sprites.
  const W=256,H=256,regions={},layers=[];
  for(const [i,item] of items.entries()) {
    const column=i%3,row=Math.floor(i/3),x=column*84+3,y=row*64+3;
    if(item.size[0]>78||item.size[1]>58)throw Error('Decal exceeded small review slot: '+item.id);
    layers.push({input:item.png,left:x,top:y});regions[item.id]=[x,y,...item.size];
  }
  const atlas=await sharp({create:{width:W,height:H,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toBuffer();
  save('atlas.png',atlas);
  json('prepared.json',{status:'appearance review, not active production kit',projection:P.camera,sourcePixelsPerCell:256,zoom:.75,
    atlas:{file:OUT+'/atlas.png',size:[W,H],bytes:atlas.length,rgbaBytes:W*H*4},
    geometrySHA256:P.hash('docs/reference/isometric-review/migration-v1/geometry.json'),
    sources:IDS.map(id=>({id,file:OUT+'/source/'+sourceId(id)+'.png',sha256:P.hash(OUT+'/source/'+sourceId(id)+'.png')})),
    entries:items.map(({png,...entry})=>({...entry,region:regions[entry.id]})),
    notes:['Four native-alpha ImageGen motifs reused on three exact planes.','Runtime places prepared regions, no perspective warp.','Mortar occlusion is baked, source pixels are neither recoloured nor threshold-extracted.','Sparse authored demonstration, not random gameplay placement or an art approval.']});
  console.log(JSON.stringify({sprites:items.length,atlas:[W,H],pngBytes:atlas.length,rgbaBytes:W*H*4}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
