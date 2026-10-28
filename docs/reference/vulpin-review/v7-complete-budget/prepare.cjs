// Uniform resampling, transparent trim, stable anchors and lossless atlas packing.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname;
const configs={
 reference:{density:160,counts:{idle:24,walk:24,run:24,hurt:13,'lock-door':24,'lock-chest':24,loot:24,death:25,dead:1}},
 balanced:{density:128,counts:{idle:8,walk:16,run:16,hurt:7,'lock-door':12,'lock-chest':12,loot:12,death:13,dead:1}},
 compact:{density:96,counts:{idle:6,walk:12,run:12,hurt:7,'lock-door':8,'lock-chest':8,loot:8,death:13,dead:1}}
};
function shelves(items,width){
 const pages=[];let page={width,height:0,rows:[],items:[]};pages.push(page);
 for(const f of [...items].sort((a,b)=>b.h-a.h||b.w-a.w||a.id.localeCompare(b.id))){
  let row=page.rows.find(r=>r.height>=f.h+4&&r.x+f.w+4<=width);
  if(!row){if(page.height+f.h+4>1024){page={width,height:0,rows:[],items:[]};pages.push(page)}row={x:0,y:page.height,height:f.h+4};page.rows.push(row);page.height+=row.height}
  page.items.push({...f,x:row.x+2,y:row.y+2});row.x+=f.w+4;
 }
 for(const p of pages)p.height=Math.ceil(p.height/4)*4;
 return pages;
}
(async()=>{
 const m=JSON.parse(fs.readFileSync(path.join(dir,'source-manifest.json')));const reports={};let totalClip=0;
 fs.mkdirSync(path.join(dir,'frames'),{recursive:true});
 for(const [profile,config]of Object.entries(configs)){
  const scale=config.density/160,size=Math.round(240*scale),out=path.join(dir,'projects',profile),assets=path.join(out,'assets');fs.mkdirSync(assets,{recursive:true});fs.mkdirSync(path.join(dir,'frames',profile),{recursive:true});
  const manifest={profile,density:config.density,scale,canvas:size,root:[120*scale,188*scale],clips:{},sprites:{},pages:[],scope:'Untextured animation budget prototype; not production hero'};const sprites=[],hashes=new Map();let slots=0,dedup=0,untrimPixels=0,trimPixels=0;
  for(const d of Object.keys(m.directions))for(const [name,c] of Object.entries(m.clips)){
   const count=config.counts[name],sequence=[];
   for(let j=0;j<count;j++){
    const sourceName=name==='dead'?'death':name,source=m.clips[sourceName];
    const i=name==='dead'?source.source-1:source.loop?j*source.source/count:j*(source.source-1)/(count-1);
    if(!Number.isInteger(i))throw Error('Non-uniform sampling '+name+' '+i);
    const id=`${d}-${sourceName}-${i}`,fullFile=path.join(dir,'frames',profile,id+'.png');
    // Separate pipelines preserve the exact overscan before uniform reduction.
    const full=await sharp(path.join(dir,`renders/${d}/${sourceName}/${String(i).padStart(2,'0')}.png`)).resize(224,224).png().toBuffer();
    await sharp(full).extend({top:8,bottom:8,left:8,right:8,background:'#00000000'}).png().toBuffer().then(b=>sharp(b).resize(size,size).png().toFile(fullFile));
    const {data,info}=await sharp(fullFile).ensureAlpha().raw().toBuffer({resolveWithObject:true});let x0=size,y0=size,x1=-1,y1=-1;
    for(let y=0;y<size;y++)for(let x=0;x<size;x++)if(data[(y*size+x)*4+3]){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);if(x<2||y<2||x>=size-2||y>=size-2)totalClip++}
    if(x1<0)throw Error('Empty sprite '+id);const w=x1-x0+1,h=y1-y0+1;
    const crop=await sharp(fullFile).extract({left:x0,top:y0,width:w,height:h}).png().toBuffer();
    const hash=crypto.createHash('sha256').update(crop).update(JSON.stringify([x0,y0])).digest('hex');
    let key=hashes.get(hash);
    if(!key){key=id;hashes.set(hash,key);sprites.push({id:key,w,h,input:crop,left:x0,top:y0});trimPixels+=w*h;untrimPixels+=size*size}else dedup++;
    sequence.push({sprite:key,duration:c.seconds/count});slots++;
   }
   manifest.clips[d+'-'+name]={loop:c.loop,seconds:c.seconds,frames:sequence,label:c.label};
  }
  const plans=[512,1024].map(w=>shelves(sprites,w));plans.sort((a,b)=>a.reduce((s,p)=>s+p.width*p.height,0)-b.reduce((s,p)=>s+p.width*p.height,0));const pages=plans[0];let pngBytes=0,rgba=0;
  for(let k=0;k<pages.length;k++){
   const p=pages[k],filename=`atlas-${k}.png`,file=path.join(assets,filename);
   const pixels=Buffer.alloc(p.width*p.height*4);
   for(const f of p.items){const raw=await sharp(f.input).ensureAlpha().raw().toBuffer();for(let y=0;y<f.h;y++)raw.copy(pixels,((f.y+y)*p.width+f.x)*4,y*f.w*4,(y+1)*f.w*4)}
   await sharp(pixels,{raw:{width:p.width,height:p.height,channels:4}}).png({compressionLevel:9}).toFile(file);
   const pageBytes=fs.statSync(file).size;pngBytes+=pageBytes;rgba+=p.width*p.height*4;manifest.pages.push({file:filename,width:p.width,height:p.height,bytes:pageBytes});
   for(const f of p.items)manifest.sprites[f.id]={page:k,rect:[f.x,f.y,f.w,f.h],offset:[f.left-manifest.root[0],f.top-manifest.root[1]],crop:[f.left,f.top,f.w,f.h]};
   // Every packed region must reconstruct its source crop byte for byte.
   for(const f of p.items){const expected=await sharp(f.input).raw().toBuffer(),actual=await sharp(file).extract({left:f.x,top:f.y,width:f.w,height:f.h}).raw().toBuffer();if(!expected.equals(actual))throw Error('Packing altered pixels '+f.id)}
  }
  fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2));
  fs.writeFileSync(path.join(out,'project.godot'),`config_version=5\n[application]\nconfig/name="Vulpin budget ${profile}"\n[display]\nwindow/size/viewport_width=1100\nwindow/size/viewport_height=760\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nenvironment/defaults/default_clear_color=Color(0.055,0.075,0.11,1)\n`);
  reports[profile]={density:config.density,counts:config.counts,directions:4,animationClips:Object.keys(manifest.clips).length,frameSlots:slots,uniqueSprites:sprites.length,reusedSlots:dedup,pages:pages.length,pngBytes,rgbaBytes:rgba,untrimmedRgbaBytes:untrimPixels*4,trimmedContentBytes:trimPixels*4,packingVerified:true};
  console.log(profile,JSON.stringify(reports[profile]));
 }
 if(totalClip)throw Error('Overscan clipping: '+totalClip);
 fs.writeFileSync(path.join(dir,'budget-source.json'),JSON.stringify({profiles:reports,borderClips:totalClip,note:'PNG and raw RGBA only. Godot import and PCK measurements are separate. Same display size in each profile.'},null,2));
})().catch(e=>{console.error(e);process.exitCode=1});
