// Crop generated component sheets and register four static poses, uniformly.
const fs=require('fs'),path=require('path'),sharp=require('sharp');const root=__dirname;
async function bounds(input){const{data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});let x0=info.width,y0=info.height,x1=-1,y1=-1;for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}return{x0,y0,x1,y1,w:x1-x0+1,h:y1-y0+1};}
async function cell(file,i){const m=await sharp(file).metadata(),s=m.width/2;if(m.width!==m.height||!m.hasAlpha)throw Error('Expected native-alpha square');return sharp(file).extract({left:i%2*s,top:Math.floor(i/2)*s,width:s,height:s}).png().toBuffer();}
(async()=>{const dirs=['se','sw','nw','ne'],heads={},dead=[];
 for(const[i,d]of dirs.entries()){
  const normal=await cell(path.join(root,'source/heads-original.png'),i),b=await bounds(normal),rect={left:b.x0-4,top:b.y0-4,width:b.w+8,height:b.h+8};
  await sharp(normal).extract(rect).png().toFile(path.join(root,'source/head-'+d+'.png'));
  const hurt=await cell(path.join(root,'source/heads-hurt-original.png'),i),nm=await sharp(normal).metadata();
  const resized=await sharp(hurt).resize(nm.width,nm.height).png().toBuffer();
  // The back views have no facial change: retain normal image exactly.
  await sharp(i<2?resized:normal).extract(rect).png().toFile(path.join(root,'source/head-hurt-'+d+'.png'));heads[d]=rect;
  const image=await cell(path.join(root,'source/dead-original.png'),i),paint=await bounds(image),guide=await bounds(path.resolve(root,'../v10-static-death/source',d+'-dead.png'));
  dead.push({d,image,paint,guide,cx:(guide.x0+guide.x1)/2,cy:(guide.y0+guide.y1)/2});
 }
 const desired=dead.map(x=>Math.max(x.guide.w,x.guide.h)/Math.max(x.paint.w,x.paint.h)).sort((a,b)=>a-b);let scale=(desired[1]+desired[2])/2;
 for(const x of dead)scale=Math.min(scale,(2*Math.min(x.cx,448-x.cx)-12)/x.paint.w,(2*Math.min(x.cy,448-x.cy)-12)/x.paint.h);
 for(const x of dead){const p=x.paint,w=Math.round(p.w*scale),h=Math.round(p.h*scale),art=await sharp(x.image).extract({left:p.x0,top:p.y0,width:p.w,height:p.h}).resize(w,h,{fit:'fill'}).png().toBuffer();const out=path.join(root,'renders',x.d,'dead');fs.mkdirSync(out,{recursive:true});await sharp({create:{width:448,height:448,channels:4,background:'#00000000'}}).composite([{input:art,left:Math.round(x.cx-w/2),top:Math.round(x.cy-h/2)}]).png().toFile(path.join(out,'00.png'));delete x.image;}
 fs.writeFileSync(path.join(root,'component-registration.json'),JSON.stringify({heads,dead,deadUniformScale:scale,note:'Rectangular crops, native alpha and uniform scaling only. Static corpse artwork follows the guide visually, not exact reconstructed 3D geometry.'},null,2));console.log('Heads and four fixed corpse sprites prepared.');
})().catch(e=>{console.error(e);process.exitCode=1});
