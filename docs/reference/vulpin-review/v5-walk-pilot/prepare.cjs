const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname,source=path.join(dir,'source/walk-guided.png');
// Ground roots estimated visually relative to each equal source cell. Translations
// preserve the original painting; no limb warp, mirroring or per-pose rescaling.
const roots=[[.663,.924],[.624,.924],[.586,.924],[.604,.924],[.704,.924],[.656,.924],[.636,.924],[.623,.924]];
(async()=>{
 const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const seen=new Uint8Array(info.width*info.height),parts=[];
 for(let p=0;p<seen.length;p++){
  if(seen[p]||data[p*4+3]<=8)continue;
  const queue=[p];seen[p]=1;let l=info.width,t=info.height,r=0,b=0;
  for(let q=0;q<queue.length;q++){
   const n=queue[q],x=n%info.width,y=Math.floor(n/info.width);l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);
   for(const [nx,ny] of [[x-1,y],[x+1,y],[x,y-1],[x,y+1]]){
    if(nx<0||ny<0||nx>=info.width||ny>=info.height)continue;
    const m=ny*info.width+nx;if(!seen[m]&&data[m*4+3]>8){seen[m]=1;queue.push(m)}
   }
  }
  if(queue.length>1000)parts.push({l,t,r,b});
 }
 if(parts.length!==8)throw Error('Expected eight complete silhouettes: '+JSON.stringify(parts));
 parts.sort((a,b)=>Math.floor((a.t+a.b)/info.height)-Math.floor((b.t+b.b)/info.height)||a.l-b.l);
 const scale=.255,frameSize=160,root=[80,134],frames=[],atlas=[];
 fs.mkdirSync(path.join(dir,'frames'),{recursive:true});
 for(let i=0;i<8;i++){
  const col=i%4,row=Math.floor(i/4),x0=Math.round(col*info.width/4),y0=Math.round(row*info.height/2),x1=Math.round((col+1)*info.width/4),y1=Math.round((row+1)*info.height/2);
  const {l,t,r,b}=parts[i];
  const crop={left:Math.max(0,l-4),top:Math.max(0,t-4)};crop.width=Math.min(info.width,r+5)-crop.left;crop.height=Math.min(info.height,b+5)-crop.top;
  const sourceRoot=[x0+roots[i][0]*(x1-x0),y0+roots[i][1]*(y1-y0)];
  const left=Math.round(root[0]+(crop.left-sourceRoot[0])*scale),top=Math.round(root[1]+(crop.top-sourceRoot[1])*scale),width=Math.round(crop.width*scale),height=Math.round(crop.height*scale);
  if(Math.min(left,top)<0||left+width>frameSize||top+height>frameSize)throw Error('Clipped frame '+i);
  const paint=await sharp(source).extract(crop).resize(width,height,{fit:'inside'}).png().toBuffer();
  const filename=`frames/walk-${i}.png`;
  await sharp({create:{width:frameSize,height:frameSize,channels:4,background:'#00000000'}}).composite([{input:paint,left,top}]).png().toFile(path.join(dir,filename));
  atlas.push({input:path.join(dir,filename),left:col*frameSize,top:row*frameSize});
  frames.push({index:i,file:filename,sourceCell:[x0,y0,x1-x0,y1-y0],crop,sourceRoot,root,scale,artBounds:[left,top,width,height]});
 }
 await sharp({create:{width:640,height:320,channels:4,background:'#00000000'}}).composite(atlas).png().toFile(path.join(dir,'walk-atlas.png'));
 const record={status:'One-direction walk pilot, not approved or runtime integrated',source:'source/walk-guided.png',source_sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),sourceSize:[info.width,info.height],tool:'Built-in ImageGen',prompt:'source/guided-prompt.txt',atlas:'walk-atlas.png',atlasSize:[640,320],frameSize,root,frames,cycleSeconds:.8,registration:'Visually estimated ground roots; translation and common uniform resize only. Not calibrated foot-contact motion.',limitations:['Generated gait does not exactly follow the guide; leg alternation and torso consistency still need art refinement.','No world-distance/stance-foot calibration or production animation integration.'],rgbaBytes:640*320*4};
 fs.writeFileSync(path.join(dir,'animation.json'),JSON.stringify(record,null,2)+'\n');
 fs.writeFileSync(path.join(dir,'animation-data.js'),'window.VULPIN_WALK='+JSON.stringify(record)+';\n');
 console.log(JSON.stringify({size:record.sourceSize,frames:frames.length,atlas:record.atlasSize,bytes:fs.statSync(path.join(dir,'walk-atlas.png')).size}));
})().catch(e=>{console.error(e);process.exitCode=1});
