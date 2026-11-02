// Uniform whole-render reduction and packing. No paint replacement or body compositing.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname,root=path.resolve(dir,'../../../..'),views=['se','sw','nw','ne'];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const label=(s,x=14,y=23)=>`<text x="${x}" y="${y}" fill="#eee3c9" font-size="17" font-family="Segoe UI,Arial">${s}</text>`;
async function main(){
 const raw=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'))),poses={...raw,actions:{attack:{size:raw.sprite_size,ortho:raw.ortho_scale,durations:raw.durations_ms,phases:raw.phases}},views:{attack:raw.views}},report={actions:{}};
 for(const [action,cfg]of Object.entries(poses.actions)){
  const native=path.join(root,'assets/previews/mycean-'+action);fs.mkdirSync(native,{recursive:true});
  const size=cfg.size,n=cfg.durations.length,unique=[...new Set(raw.source_indices)],records=[],buffers={},board=[];let bytes=0;
  for(let row=0;row<4;row++){
   const view=views[row],comps=[];buffers[view]=[];
   for(let i=0;i<n;i++){
    const sourceIndex=raw.source_indices[i];
    const file=path.join(dir,'masters',view,`${action}-${String(sourceIndex).padStart(2,'0')}.png`);
    const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    if(info.width!==size*2||info.height!==size*2)throw Error('Wrong master dimensions '+file);
    let x0=info.width,y0=info.height,x1=-1,y1=-1;
    for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
    if(x1<0||x0<2||y0<2||x1>info.width-3||y1>info.height-3)throw Error('Clipped/empty '+file);
    const rendered=await sharp(file).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();
    let png=rendered,endpointDelta=0;
    if(i===n-1){
     // Recovery references the same complete neutral master (source_index=0).
     // Verify the reduction before using the identical runtime image. Other
     // repeated held poses likewise reuse a registered whole-render atlas slot.
     const a=await sharp(buffers[view][0]).raw().toBuffer(),b=await sharp(rendered).raw().toBuffer();
     for(let j=0;j<a.length;j++)endpointDelta=Math.max(endpointDelta,Math.abs(a[j]-b[j]));
     if(endpointDelta>1)throw Error('Neutral endpoint drift '+view);
     png=buffers[view][0];
    }
    buffers[view].push(png);
    if(sourceIndex===i)comps.push({input:png,left:(unique.indexOf(i)%5)*size,top:Math.floor(unique.indexOf(i)/5)*size});records.push({view,index:i,source_index:sourceIndex,endpoint_max_channel_delta:endpointDelta,master_sha256:sha(fs.readFileSync(file)),rendered_sha256:sha(rendered),sha256:sha(png),alphaBounds:[x0,y0,x1,y1]});
    board.push({input:await sharp(file).resize(192,192).png().toBuffer(),left:i*196,top:row*222+28});
    board.push({input:svg(196,28,label(`${view.toUpperCase()} · ${i+1}`)),left:i*196,top:row*222});
   }
   if(new Set(records.filter(r=>r.view===view).map(r=>r.sha256)).size !== unique.length)throw Error('Repeated unexpected poses');
   if(!buffers[view][0].equals(buffers[view][n-1]))throw Error('Neutral recovery is not exact');
   const sheet=path.join(native,`${action}-${view}.png`);
   await sharp({create:{width:size*5,height:size*Math.ceil(unique.length/5),channels:4,background:'#00000000'}}).composite(comps).png().toFile(sheet);bytes+=fs.statSync(sheet).size;
  }
  const anchor=[size/2,(.5+.72*Math.cos(Math.PI/6)/cfg.ortho)*size];
  for(const view of views)if(poses.views[action][view].anchor_px.some((x,i)=>Math.abs(x/2-anchor[i])>.001))throw Error('Anchor mismatch');
  const reg={anchor,frame_size:size,hero_scale:poses.hero_scale,ortho_scale:cfg.ortho,durations_ms:cfg.durations,phases:cfg.phases,loop:false,release_ms:650,release_frame:5,flight_ms:320,views:Object.fromEntries(views.map(v=>[v,{emitters:raw.views[v].emitters.map(p=>p.map(c=>c/2))}]))};
  fs.writeFileSync(path.join(native,'registration.json'),JSON.stringify(reg,null,2)+'\n');
  let tres=`[gd_resource type="SpriteFrames" load_steps=${5+4*n} format=3]\n\n`;
  views.forEach((v,j)=>tres+=`[ext_resource type="Texture2D" path="res://assets/previews/mycean-${action}/${action}-${v}.png" id="${j+1}"]\n`);
  views.forEach((v,j)=>{for(let i=0;i<n;i++)tres+=`\n[sub_resource type="AtlasTexture" id="${v}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${(unique.indexOf(raw.source_indices[i])%5)*size}, ${Math.floor(unique.indexOf(raw.source_indices[i])/5)*size}, ${size}, ${size})\nfilter_clip = true\n`;});
  tres+='\n[resource]\nanimations = ['+views.map(v=>'{"frames": ['+cfg.durations.map((ms,i)=>`{"duration": ${ms/100}, "texture": SubResource("${v}_${i}")}`).join(',\n')+`], "loop": false, "name": &"${v}", "speed": 10.0}`).join(',\n')+']\n';
  tres+=`metadata/ground_anchor = Vector2(${anchor.join(', ')})\nmetadata/hero_scale = ${poses.hero_scale}\n`;
  fs.writeFileSync(path.join(native,'frames.tres'),tres);
  const animated=[];
  for(let i=0;i<n;i++){
   const layers=[];for(let j=0;j<4;j++){
    layers.push({input:buffers[views[j]][i],left:(j%2)*352+(352-size)/2,top:Math.floor(j/2)*352+28+(320-size)/2});
    layers.push({input:svg(352,28,label(views[j].toUpperCase())),left:(j%2)*352,top:Math.floor(j/2)*352});
   }
   animated.push(await sharp({create:{width:704,height:704,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
  }
  // Review loops include an obvious pause. Game resources remain non-looping.
  for(const rate of [1,2]){
   const pages=[],delays=[];
   for(let i=0;i<n;i++){
    const delay=cfg.durations[i]*rate+(i===n-1?1200:0);
    if(pages.length&&pages[pages.length-1].equals(animated[i]))delays[delays.length-1]+=delay;
    else {pages.push(animated[i]);delays.push(delay);}
   }
   const webp=path.join(dir,rate===1?'attack-preview.webp':'attack-slow.webp');
   await sharp(Buffer.concat(pages),{raw:{width:704,height:704*pages.length,channels:4,pageHeight:704}}).webp({lossless:true,loop:0,delay:delays}).toFile(webp);
   const meta=await sharp(webp,{animated:true}).metadata();
   if(meta.pages!==pages.length||meta.delay.some((ms,i)=>ms!==delays[i]))throw Error('WebP timing');
  }
  await sharp({create:{width:n*196,height:888,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,`${action}-poses.png`));
  report.actions[action]={...reg,sheet_bytes:bytes,unique_poses:unique.length,rgba_bytes:4*size*size*unique.length*4,frames:records};
  const name='MyceanCoreAttack';
  const sharedScript='scripts/mycean_attack_preview.gd';
  if(!fs.existsSync(path.join(root,sharedScript)))throw Error('Missing shared native preview script');
  fs.writeFileSync(path.join(root,'scenes',name+'.tscn'),`[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://${sharedScript}" id="1"]\n[ext_resource type="SpriteFrames" path="res://assets/previews/mycean-${action}/frames.tres" id="2"]\n\n[node name="${name}" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\nanimation_frames = ExtResource("2")\npreview_title = "Mycean · spore burst"\nphases = PackedStringArray(${cfg.phases.map(s=>JSON.stringify(s)).join(', ')})\nframe_anchor = Vector2(${anchor.join(', ')})\nreplay_caption = "Cast spore burst"\n`);
  fs.writeFileSync(path.join(native,'SOURCE.txt'),`Whole equipped Meshy Mycean rendered from approved v2. Backward wind-up and forward cast, retained corrected grip, fixed feet, measured cap emitter, exact neutral recovery. Reproduce via docs/reference/mycean-review/v8-spore-attack/README.txt. ${n} held poses × four views; no runtime 3D. Uniform reduction only.\n`);
 }
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(Object.fromEntries(Object.entries(report.actions).map(([k,v])=>[k,{bytes:v.sheet_bytes,rgba:v.rgba_bytes,duration:v.durations_ms.reduce((a,b)=>a+b,0)}]))));
}
main().catch(e=>{console.error(e);process.exitCode=1});
