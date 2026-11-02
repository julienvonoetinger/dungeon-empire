// Bake four complete props in the kit camera. Only the ground coordinates and
// chest views turn. Upright objects never undergo a 2D quarter-turn.
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict"),sharp=require("sharp");
const P=require("../../../../tools/isometric_paint_geometry.cjs"),{facing,inward,items,turn}=require("./layout.cjs");
const root=P.ROOT,dir=__dirname,work=path.join(root,"artifacts/treasury-entrances");
const fits=require("../../../../tools/chest_direction_sources.json").items;
const cat=require("../../../../assets/dungeon/isometric-kit/catalog.json");
const ss=2, frame=[-245,-165,490,320], cache=new Map(), k=P.camera.eye[0]/P.camera.eye[2];
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v));
function rng(seed){return ()=>((seed=(Math.imul(seed,1664525)+1013904223)>>>0)/4294967296);}
async function cut(file,threshold){
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let x0=info.width,y0=info.height,x1=-1,y1=-1;
 for(let i=0;i<data.length;i+=4)if(data[i+3]>=threshold){
   const x=i/4%info.width,y=Math.floor(i/4/info.width);
   x0=Math.min(x,x0);y0=Math.min(y,y0);x1=Math.max(x,x1);y1=Math.max(y,y1);
 }
 assert(x1>x0);return sharp(data,{raw:info}).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).png().toBuffer();
}
async function painting(item,side){
 const isChest=["open","closed"].includes(item.type);
 const id=isChest?"prop-chest"+(item.type==="open"?"-open":"")+(side==="S"?"":"-"+facing[side]):item.type;
 const key=id+"-"+(item.width||item.scale);if(cache.has(key))return cache.get(key);
 let image,offset,shape;
 if(isChest){
   const entry=cat.atlas.regions[id],fit=fits.find(x=>x.id===id);
   assert.equal(entry.decoration.facing,facing[side]);
   image=await cut(path.join(root,fit.source),1);
   const width=Math.round((entry.size[0]-4)*item.scale*ss),height=Math.round((entry.size[1]-4)*item.scale*ss);
   image=await sharp(image).resize(width,height,{fit:"fill"}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   offset=entry.offset.map(v=>(v+2)*item.scale);shape={box:entry.bounds.max.map(v=>v*item.scale)};
 }else{
   const file=item.type==="bank"?path.join(dir,"source/coin-bank.png"):path.join(dir,"../v8-coffre-et-cuir/source",item.type==="tied"?"sac-lie.png":"sac-ouvert.png");
   const ink=await cut(file,24);
   image=await sharp(ink).resize(Math.round(item.width*ss)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   const h=image.info.height/ss,bank=item.type==="bank";
   offset=[-item.width/2,-h+item.width*(bank?.20:.13)];
   shape={radius:item.width/362,centreZ:bank?.02:h*.32/156.77,rz:bank?h*.73/156.77:h*.54/156.77};
 }
 const result={...image,id,offset,shape};cache.set(key,result);return result;
}
function depth(layer,gx,gy){
 const x=gx-layer.at[0],y=gy-layer.at[1],s=layer.shape;
 if(s.box)return clamp(Math.min((s.box[0]-x)/k,(s.box[1]-y)/k,s.box[2]),0,s.box[2]);
 const rr=s.radius**2,zz=s.rz**2,A=2*k*k/rr+1/zz,B=2*(k*(x+y)/rr-s.centreZ/zz),C=(x*x+y*y)/rr+s.centreZ**2/zz-1;
 return clamp((-B+Math.sqrt(Math.max(0,B*B-4*A*C)))/(2*A),0,s.centreZ+s.rz);
}
async function scatter(side){
 const rand=rng(729),coins=[],stamp=await sharp(path.join(root,fits.find(f=>f.id==="prop-chest-open").source))
   .extract({left:500,top:536,width:50,height:24}).ensureAlpha().raw().toBuffer();
 // Ground-plane paint: use a real small gold coin from the same game chest.
 for(let i=0;i<1040;i++){
   const u=rand()*1.56-.78,v=rand()*1.07-.36;
   const body=Math.max(0,1-(u/.77)**2-((v-.23)/.50)**2);
   if(rand()>.018+.98*body)continue;
   const xy=turn(side,u,v),p=P.project([...xy,0]),radius=5+rand()*2.4;
   coins.push({x:p[0],y:p[1],rx:radius,ry:radius*.50,light:.76+rand()*.23});
 }
 const w=frame[2]*ss,h=frame[3]*ss,raw=Buffer.alloc(w*h*4);
 for(const c of coins.sort((a,b)=>a.y-b.y)){
   for(let j=Math.max(0,Math.floor((c.y-c.ry-frame[1])*ss));j<Math.min(h,Math.ceil((c.y+c.ry-frame[1])*ss));j++)
    for(let i=Math.max(0,Math.floor((c.x-c.rx-frame[0])*ss));i<Math.min(w,Math.ceil((c.x+c.rx-frame[0])*ss));i++){
       const a=(frame[0]+(i+.5)/ss-c.x)/c.rx,b=(frame[1]+(j+.5)/ss-c.y)/c.ry,t=Math.hypot(a,b);
       if(t>=1)continue;const ix=clamp(Math.round((a+1)*24.5),0,49),iy=clamp(Math.round((b+1)*11.5),0,23),q=4*(iy*50+ix),o=4*(j*w+i);
       for(let z=0;z<3;z++)raw[o+z]=Math.round(stamp[q+z]*c.light*(1-.32*clamp((t-.82)/.18,0,1)));raw[o+3]=255;
    }
 }
 return raw;
}
async function bake(side){
 const layers=[];
 for(const item of items){
   const art=await painting(item,side),at=turn(side,item.u,item.v),p=P.project([...at,0]);
   layers.push({...art,at,type:item.type,left:Math.round((p[0]+art.offset[0]-frame[0])*ss),top:Math.round((p[1]+art.offset[1]-frame[1])*ss),visible:0,ink:0});
 }
 const raw=await scatter(side),w=frame[2]*ss,h=frame[3]*ss;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const gx=P.ground([frame[0]+(x+.5)/ss,frame[1]+(y+.5)/ss]);
   const hits=[];
   for(const l of layers){
     const xx=x-l.left,yy=y-l.top;if(xx<0||yy<0||xx>=l.info.width||yy>=l.info.height)continue;
     const i=4*(yy*l.info.width+xx),alpha=l.data[i+3]/255;if(alpha<.014)continue;
     hits.push({l,i,alpha,d:depth(l,gx[0],gx[1])});if(alpha>.55)l.ink++;
   }
   if(!hits.length)continue;hits.sort((a,b)=>a.d-b.d);
   const idx=4*(y*w+x);let al=raw[idx+3]/255,r=raw[idx]*al,g=raw[idx+1]*al,b=raw[idx+2]*al;
   for(const q of hits){const a=q.alpha,inv=1-a;r=q.l.data[q.i]*a+r*inv;g=q.l.data[q.i+1]*a+g*inv;b=q.l.data[q.i+2]*a+b*inv;al=a+al*inv;}
   if(hits.at(-1).alpha>.55)hits.at(-1).l.visible++;
   raw[idx]=Math.round(r/al);raw[idx+1]=Math.round(g/al);raw[idx+2]=Math.round(b/al);raw[idx+3]=Math.round(255*al);
 }
 const {data:buf}=await sharp(raw,{raw:{width:w,height:h,channels:4}}).resize(frame[2],frame[3]).raw().toBuffer({resolveWithObject:true});
 let l=frame[2],t=frame[3],r=-1,b=-1;
 for(let i=0;i<buf.length;i+=4){if(buf[i+3]<4){buf.fill(0,i,i+4);continue;}const x=i/4%frame[2],y=Math.floor(i/4/frame[2]);l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 l--;t--;r++;b++;assert(l>=0&&t>=0&&r<frame[2]&&b<frame[3]);
 const width=r-l+1,height=b-t+1;
 const png=await sharp(buf,{raw:{width:frame[2],height:frame[3],channels:4}}).extract({left:l,top:t,width,height}).png().toBuffer();
 fs.writeFileSync(path.join(work,side+".png"),png);
 const objects=layers.map(a=>({type:a.type,id:a.id,at:a.at,visibleRatio:+(a.visible/a.ink).toFixed(3)}));
 console.log(side,width,height,objects.map(o=>o.type+":"+o.visibleRatio).join(" "));
 return {side,width,height,pivot:[-frame[0]-l,-frame[1]-t],objects,png};
}
async function main(){
 fs.mkdirSync(work,{recursive:true});
 const views=[];for(const side of Object.keys(inward))views.push(await bake(side));
 const gap=6,stepX=Math.max(...views.map(v=>v.width))+2*gap,stepY=Math.max(...views.map(v=>v.height))+2*gap,tiles=[],regions={};
 views.forEach(({side,width,height,pivot,objects,png},i)=>{
    const x=i%2*stepX+gap,y=Math.floor(i/2)*stepY+gap;
    regions[side]={rect:[x,y,width,height],pivot,objects};tiles.push({input:png,left:x,top:y});
 });
 await sharp({create:{width:2*stepX,height:2*stepY,channels:4,background:"#00000000"}}).composite(tiles).png().toFile(path.join(dir,"reserve-atlas.png"));
 fs.writeFileSync(path.join(dir,"atlas.json"),JSON.stringify({file:"reserve-atlas.png",regions},null,2)+"\n");
}
main().catch(e=>{console.error(e);process.exitCode=1;});
