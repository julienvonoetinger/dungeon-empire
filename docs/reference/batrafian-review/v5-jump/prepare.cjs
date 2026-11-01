// Uniform whole-render reduction and packing. No body-part painting/compositing.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname,root=path.resolve(dir,'../../../..'),views=['se','sw','nw','ne'];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
async function main(){
 const poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'))),n=poses.durations_ms.length,size=256,cols=6;
 const native=path.join(root,'assets/previews/batrafian-jump');fs.mkdirSync(native,{recursive:true});
 const anchor=[128,(.5+poses.target_z*Math.cos(Math.PI/6)/poses.ortho_scale)*size];
 const registration={anchor,frame_size:size,hero_scale:poses.hero_scale,ortho_scale:poses.ortho_scale,
  durations_ms:poses.durations_ms,phases:poses.phases,loop:false,launch_time:poses.launch_time,
  land_time:poses.land_time,apex_height:poses.apex_height,altitude_baked:false,travel_cells:2};
 const records=[],buffers={},board=[];let bytes=0;
 for(let row=0;row<4;row++){
  const view=views[row],comps=[];buffers[view]=[];
  if(poses.views[view].anchor_px.some((v,i)=>Math.abs(v/2-anchor[i])>.001))throw Error('Directional anchor drift');
  for(let i=0;i<n;i++){
   const file=path.join(dir,'masters',view,`jump-${String(i).padStart(2,'0')}.png`),source=fs.readFileSync(file);
   const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   if(info.width!==512||info.height!==512)throw Error('Master size');
   let x0=512,y0=512,x1=-1,y1=-1;
   for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(data[(y*512+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
   if(x1<0||x0<2||y0<2||x1>509||y1>509)throw Error('Empty/clipped '+file);
   // Independent rig reload proves first/last geometry equal. Reuse the entire
   // first render at rest to avoid a denoiser-only flicker, and save one slot.
   const png=i===n-1?buffers[view][0]:await sharp(source).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();
   buffers[view].push(png);
   if(i<n-1)comps.push({input:png,left:(i%cols)*size,top:Math.floor(i/cols)*size});
   records.push({view,index:i,source_sha256:sha(source),sprite_sha256:sha(png),alphaBounds:[x0,y0,x1,y1]});
   board.push({input:await sharp(png).resize(160,160).png().toBuffer(),left:i*164,top:row*188+25});
  }
  if(new Set(records.filter(r=>r.view===view).map(r=>r.sprite_sha256)).size!==11)throw Error('Distinct poses');
  board.push({input:svg(1968,25,`<text x="12" y="20" fill="#eee" font-size="17" font-family="Arial">${view.toUpperCase()}</text>`),left:0,top:row*188});
  const sheet=path.join(native,`jump-${view}.png`);
  await sharp({create:{width:cols*size,height:2*size,channels:4,background:'#00000000'}}).composite(comps).png().toFile(sheet);bytes+=fs.statSync(sheet).size;
 }
 fs.writeFileSync(path.join(native,'registration.json'),JSON.stringify(registration,null,2)+'\n');
 let tres=`[gd_resource type="SpriteFrames" load_steps=${5+4*n} format=3]\n\n`;
 views.forEach((v,j)=>tres+=`[ext_resource type="Texture2D" path="res://assets/previews/batrafian-jump/jump-${v}.png" id="${j+1}"]\n`);
 views.forEach((v,j)=>{for(let i=0;i<n;i++){const slot=i===n-1?0:i;tres+=`\n[sub_resource type="AtlasTexture" id="${v}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${slot%cols*size}, ${Math.floor(slot/cols)*size}, 256, 256)\nfilter_clip = true\n`;}});
 tres+='\n[resource]\nanimations = ['+views.map(v=>'{"frames": ['+poses.durations_ms.map((ms,i)=>`{"duration": ${ms/100}, "texture": SubResource("${v}_${i}")}`).join(',\n')+`], "loop": false, "name": &"${v}", "speed": 10.0}`).join(',\n')+']\n';
 fs.writeFileSync(path.join(native,'frames.tres'),tres);
 fs.writeFileSync(path.join(root,'scenes/BatrafianJump.tscn'),`[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/batrafian_jump_preview.gd" id="1"]\n[ext_resource type="SpriteFrames" path="res://assets/previews/batrafian-jump/frames.tres" id="2"]\n\n[node name="BatrafianJump" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\nanimation_frames = ExtResource("2")\npreview_title = "Batrafian · trap jump"\nphases = PackedStringArray(${poses.phases.map(s=>JSON.stringify(s)).join(', ')})\nframe_anchor = Vector2(${anchor.join(', ')})\nreplay_caption = "Jump"\n`);
 fs.writeFileSync(path.join(native,'SOURCE.txt'),'Whole equipped Batrafian Meshy render.12held poses/4real views; identical rest reused. Altitude and ground travel are UNBAKED. Recipe: docs/reference/batrafian-review/v5-jump/README.txt\n');
 await sharp({create:{width:1968,height:752,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'jump-poses.png'));
 // Smooth vertical trajectory with held whole-character sprites. Review is
 // in place; the native scene additionally traverses two actual floor cells.
 const starts=poses.durations_ms.map((_,i)=>poses.durations_ms.slice(0,i).reduce((a,b)=>a+b,0));
 // Keep review sampling at20ms: WebP decoders can clamp10ms frames to100ms.
 // Native SpriteFrames retain every exact pose duration; only this preview
 // samples pose boundaries on the nearest following20ms tick.
 const times=Array.from({length:51},(_,i)=>i*20),raws=[];
 const delays=times.map((t,i)=>i===times.length-1?800:times[i+1]-t);
 for(const ms of times){
  const index=starts.findLastIndex(t=>t<=ms),u=Math.max(0,Math.min(1,(ms/1000-poses.launch_time)/(poses.land_time-poses.launch_time)));
  const h=4*poses.apex_height*u*(1-u),dz=h*size/poses.ortho_scale*Math.cos(Math.PI/6),layers=[];
  views.forEach((v,j)=>{
   const x=(j%2)*384,y=Math.floor(j/2)*384;
   const s=1-.25*h/poses.apex_height;
   layers.push({input:svg(384,384,`<text x="18" y="28" fill="#eee" font-family="Arial" font-size="20">${v.toUpperCase()}</text><ellipse cx="192" cy="295" rx="${30*s}" ry="${13*s}" fill="#050b11" fill-opacity="${.6-.3*h/poses.apex_height}"/><text x="192" y="365" text-anchor="middle" fill="#bbb5cd" font-family="Arial" font-size="16">${poses.phases[index]}</text>`),left:x,top:y});
   layers.push({input:buffers[v][index],left:x+64,top:y+Math.round(295-anchor[1]-dz)});
  });
  raws.push(await sharp({create:{width:768,height:768,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
 }
 for(const [name,factor]of [['jump-preview',1],['jump-slow',2]]){
  const out=path.join(dir,name+'.webp'),delay=delays.map((d,i)=>i===delays.length-1?d:d*factor);
  await sharp(Buffer.concat(raws),{raw:{width:768,height:768*raws.length,channels:4,pageHeight:768}}).webp({lossless:true,loop:0,delay}).toFile(out);
  const m=await sharp(out,{animated:true}).metadata();if(m.delay.reduce((a,b)=>a+b,0)!==1000*factor+800)throw Error('Review timing mismatch');
 }
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify({sheet_bytes:bytes,rgba_bytes:4*1536*512*4,atlas_size:[1536,512],...registration,frames:records},null,2)+'\n');
 console.log(JSON.stringify({sheet_bytes:bytes,rgba_bytes:4*1536*512*4,poses:n,unique_sprites:44,duration_ms:1000}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
