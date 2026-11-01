// Whole rendered sprites, uniform reduction/atlas packing; no painting or mirroring.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname,root=path.resolve(dir,'../../../..'),views=['se','sw','nw','ne'];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const label=s=>`<text x="14" y="23" fill="#eee3c9" font-size="17" font-family="Segoe UI,Arial">${s}</text>`;
async function main(){
 const p=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'))),size=320,n=12;
 const native=path.join(root,'assets/previews/batrafian-attack');fs.mkdirSync(native,{recursive:true});
 const anchor=p.views.se.anchor_px.map(x=>x/2),buffers={},records=[],projectiles={},board=[];let bytes=0;
 for(let row=0;row<4;row++){
  const view=views[row],comps=[];buffers[view]=[];
  if(p.views[view].anchor_px.some((x,i)=>Math.abs(x/2-anchor[i])>.001))throw Error('Anchor mismatch');
  for(let i=0;i<n;i++){
   const file=path.join(dir,'masters',view,`attack-${String(i).padStart(2,'0')}.png`),master=fs.readFileSync(file);
   const {data,info}=await sharp(master).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   if(info.width!==640||info.height!==640)throw Error('Master dimensions');
   let x0=640,y0=640,x1=-1,y1=-1;
   for(let y=0;y<640;y++)for(let x=0;x<640;x++)if(data[(y*640+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
   if(x1<0||x0<2||y0<2||x1>637||y1>637)throw Error('Clipped/empty '+file);
   const png=i===11?buffers[view][0]:await sharp(master).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();buffers[view].push(png);
   if(i!==11)comps.push({input:png,left:(i%6)*size,top:Math.floor(i/6)*size});
   records.push({view,index:i,master_sha256:sha(master),sha256:sha(png),alias:i===11?0:null,alpha_bounds:[x0,y0,x1,y1]});
   board.push({input:await sharp(png).resize(160,160).png().toBuffer(),left:i*164,top:row*190+28});
   board.push({input:svg(164,28,label(`${view.toUpperCase()} · ${i+1}`)),left:i*164,top:row*190});
  }
  const sheet=path.join(native,`attack-${view}.png`);
  await sharp({create:{width:1920,height:640,channels:4,background:'#00000000'}}).composite(comps).png().toFile(sheet);bytes+=fs.statSync(sheet).size;
  const arrow=await sharp(path.join(dir,'masters',view,'projectile.png')).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();
  const raw=await sharp(arrow).ensureAlpha().raw().toBuffer();let x0=320,y0=320,x1=-1,y1=-1;
  for(let y=0;y<320;y++)for(let x=0;x<320;x++)if(raw[(y*320+x)*4+3]>0){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
  if(x1<0)throw Error('Empty projectile');
  x0=Math.max(0,x0-2);y0=Math.max(0,y0-2);x1=Math.min(319,x1+2);y1=Math.min(319,y1+2);
  const dest=path.join(native,`arrow-${view}.png`),rect={left:x0,top:y0,width:x1-x0+1,height:y1-y0+1};
  await sharp(arrow).extract(rect).png().toFile(dest);bytes+=fs.statSync(dest).size;
  projectiles[view]={path:`res://assets/previews/batrafian-attack/arrow-${view}.png`,size:[rect.width,rect.height],
   anchor:[p.views[view].nock_px[0]/2-x0,p.views[view].nock_px[1]/2-y0],
   tip_offset:p.views[view].tip_px.map((x,i)=>(x-p.views[view].nock_px[i])/2),crop:rect,sha256:sha(fs.readFileSync(dest))};
 }
 const reg={anchor,frame_size:size,hero_scale:p.hero_scale,ortho_scale:p.ortho_scale,durations_ms:p.durations_ms,phases:p.phases,
  release_ms:p.release_ms,flight_ms:p.flight_ms,loop:false,views:Object.fromEntries(views.map(v=>[v,{
   nock:p.views[v].nock_px.map((x,i)=>(x/2-anchor[i])*p.hero_scale),tip:p.views[v].tip_px.map((x,i)=>(x/2-anchor[i])*p.hero_scale)}])),projectiles};
 fs.writeFileSync(path.join(native,'registration.json'),JSON.stringify(reg,null,2)+'\n');
 let tres='[gd_resource type="SpriteFrames" load_steps=49 format=3]\n\n';
 views.forEach((v,j)=>tres+=`[ext_resource type="Texture2D" path="res://assets/previews/batrafian-attack/attack-${v}.png" id="${j+1}"]\n`);
 views.forEach((v,j)=>{for(let i=0;i<11;i++)tres+=`\n[sub_resource type="AtlasTexture" id="${v}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${i%6*size}, ${Math.floor(i/6)*size}, ${size}, ${size})\nfilter_clip = true\n`;});
 tres+='\n[resource]\nanimations = ['+views.map(v=>'{"frames": ['+p.durations_ms.map((ms,i)=>`{"duration": ${ms/100}, "texture": SubResource("${v}_${i===11?0:i}")}`).join(',\n')+`], "loop": false, "name": &"${v}", "speed": 10.0}`).join(',\n')+']\n';
 tres+=`metadata/ground_anchor = Vector2(${anchor.join(', ')})\nmetadata/hero_scale = ${p.hero_scale}\n`;
 fs.writeFileSync(path.join(native,'frames.tres'),tres);
 const frames=[];
 for(let i=0;i<n;i++){
  const layers=[];for(let j=0;j<4;j++){
   layers.push({input:buffers[views[j]][i],left:j%2*352+16,top:Math.floor(j/2)*352+28});
   layers.push({input:svg(352,28,label(views[j].toUpperCase())),left:j%2*352,top:Math.floor(j/2)*352});
  }
  frames.push(await sharp({create:{width:704,height:704,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
 }
 for(const slow of [1,2]){
  const delay=p.durations_ms.map((x,i)=>x*slow+(i===11?800:0)),file=path.join(dir,slow===1?'attack-poses.webp':'attack-poses-slow.webp');
  await sharp(Buffer.concat(frames),{raw:{width:704,height:704*n,channels:4,pageHeight:704}}).webp({lossless:true,loop:0,delay}).toFile(file);
  const m=await sharp(file,{animated:true}).metadata();if(m.pages!==n||m.delay.some((d,i)=>d!==delay[i]))throw Error('WebP timing');
 }
 await sharp({create:{width:1968,height:760,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'attack-board.png'));
 await sharp(frames[6],{raw:{width:704,height:704,channels:4}}).png().toFile(path.join(dir,'drawn-bow.png'));
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify({...reg,total_png_bytes:bytes,atlas_rgba_bytes:4*1920*640*4,frames:records},null,2)+'\n');
 fs.writeFileSync(path.join(root,'scenes/BatrafianCoreAttack.tscn'),`[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/batrafian_attack_preview.gd" id="1"]\n[ext_resource type="SpriteFrames" path="res://assets/previews/batrafian-attack/frames.tres" id="2"]\n\n[node name="BatrafianCoreAttack" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\nanimation_frames = ExtResource("2")\npreview_title = "Batrafian · ranged Core attack"\nphases = PackedStringArray(${p.phases.map(x=>JSON.stringify(x)).join(', ')})\nframe_anchor = Vector2(${anchor.join(', ')})\nreplay_caption = "Shoot"\n`);
 fs.writeFileSync(path.join(native,'SOURCE.txt'),'Whole equipped Meshy Batrafian; original bow string locally deformed with shape key, supplied arrow separate after release.12held poses/fourviews,44unique320px body regions+4cropped projectile sprites. Reproduce via docs/reference/batrafian-review/v7-bow-attack/README.txt. No repaint/runtime3D.\n');
 console.log(JSON.stringify({bytes,atlas_rgba:4*1920*640*4,duration:1150,release:690,flight:260}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
