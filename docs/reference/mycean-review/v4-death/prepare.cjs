// Whole-render uniform reduction only: no repainting, body assembly or mirroring.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname,root=path.resolve(dir,'../../../..'),views=['se','sw','nw','ne'];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const label=(s,x=14,y=23)=>`<text x="${x}" y="${y}" fill="#eee3c9" font-size="17" font-family="Segoe UI,Arial">${s}</text>`;
async function main(){
 const poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'))),size=320,n=10;
 const native=path.join(root,'assets/previews/mycean-death');fs.mkdirSync(native,{recursive:true});
 const records=[],buffers={},board=[];let bytes=0;
 for(let row=0;row<4;row++){
  const view=views[row],comps=[];buffers[view]=[];
  for(let i=0;i<n;i++){
   const file=path.join(dir,'masters',view,`death-${String(i).padStart(2,'0')}.png`),master=fs.readFileSync(file);
   const {data,info}=await sharp(master).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   if(info.width!==640||info.height!==640)throw Error('Master dimensions '+file);
   let x0=640,y0=640,x1=-1,y1=-1;
   for(let y=0;y<640;y++)for(let x=0;x<640;x++)if(data[(y*640+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
   if(x1<0||x0<2||y0<2||x1>637||y1>637)throw Error('Clipped/empty '+file);
   const png=await sharp(master).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();buffers[view].push(png);
   comps.push({input:png,left:(i%5)*size,top:Math.floor(i/5)*size});
   records.push({view,index:i,master_sha256:sha(master),sha256:sha(png),alpha_bounds:[x0,y0,x1,y1]});
   board.push({input:await sharp(master).resize(192,192).png().toBuffer(),left:i*196,top:row*222+28});
   board.push({input:svg(196,28,label(`${view.toUpperCase()} · ${i+1}`)),left:i*196,top:row*222});
  }
  if(new Set(records.filter(r=>r.view===view).map(r=>r.sha256)).size!==n)throw Error('Repeated poses');
  const sheet=path.join(native,`death-${view}.png`);
  await sharp({create:{width:1600,height:640,channels:4,background:'#00000000'}}).composite(comps).png().toFile(sheet);bytes+=fs.statSync(sheet).size;
 }
 const anchor=[160,(.5+.46*Math.cos(Math.PI/6)/3.25)*320];
 for(const view of views)if(poses.views[view].anchor_px.some((x,i)=>Math.abs(x/2-anchor[i])>.001))throw Error('Anchor mismatch');
 const reg={anchor,frame_size:size,hero_scale:poses.hero_scale,ortho_scale:3.25,durations_ms:poses.durations_ms,phases:poses.phases,loop:false};
 fs.writeFileSync(path.join(native,'registration.json'),JSON.stringify(reg,null,2)+'\n');
 let tres='[gd_resource type="SpriteFrames" load_steps=45 format=3]\n\n';
 views.forEach((v,j)=>tres+=`[ext_resource type="Texture2D" path="res://assets/previews/mycean-death/death-${v}.png" id="${j+1}"]\n`);
 views.forEach((v,j)=>{for(let i=0;i<n;i++)tres+=`\n[sub_resource type="AtlasTexture" id="${v}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${(i%5)*size}, ${Math.floor(i/5)*size}, ${size}, ${size})\nfilter_clip = true\n`;});
 tres+='\n[resource]\nanimations = ['+views.map(v=>'{"frames": ['+poses.durations_ms.map((ms,i)=>`{"duration": ${ms/100}, "texture": SubResource("${v}_${i}")}`).join(',\n')+`], "loop": false, "name": &"${v}", "speed": 10.0}`).join(',\n')+']\n';
 tres+=`metadata/ground_anchor = Vector2(${anchor.join(', ')})\nmetadata/hero_scale = ${poses.hero_scale}\n`;
 fs.writeFileSync(path.join(native,'frames.tres'),tres);
 const animated=[];
 for(let i=0;i<n;i++){
  const layers=[];for(let j=0;j<4;j++){
   layers.push({input:buffers[views[j]][i],left:(j%2)*352+16,top:Math.floor(j/2)*352+28});
   layers.push({input:svg(352,28,label(views[j].toUpperCase())),left:(j%2)*352,top:Math.floor(j/2)*352});
  }
  animated.push(await sharp({create:{width:704,height:704,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
 }
 for(const speed of [1,2]){
  const delays=poses.durations_ms.map((ms,i)=>ms*speed+(i===n-1?1200:0));
  const file=path.join(dir,speed===1?'death-preview.webp':'death-slow.webp');
  await sharp(Buffer.concat(animated),{raw:{width:704,height:704*n,channels:4,pageHeight:704}}).webp({lossless:true,loop:0,delay:delays}).toFile(file);
  const meta=await sharp(file,{animated:true}).metadata();if(meta.pages!==n||meta.delay.some((ms,i)=>ms!==delays[i]))throw Error('WebP timing');
 }
 await sharp({create:{width:1960,height:888,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'death-poses.png'));
 await sharp(animated[n-1],{raw:{width:704,height:704,channels:4}}).png().toFile(path.join(dir,'final-pose.png'));
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify({...reg,sheet_bytes:bytes,rgba_bytes:4*1600*640*4,frames:records},null,2)+'\n');
 fs.writeFileSync(path.join(root,'scenes/MyceanDeath.tscn'),`[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/paladin_action_preview.gd" id="1"]\n[ext_resource type="SpriteFrames" path="res://assets/previews/mycean-death/frames.tres" id="2"]\n\n[node name="MyceanDeath" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\nanimation_frames = ExtResource("2")\npreview_title = "Mycean · fall and death"\nphases = PackedStringArray(${poses.phases.map(s=>JSON.stringify(s)).join(', ')})\nframe_anchor = Vector2(${anchor.join(', ')})\nis_death = true\nstage_bounds = Rect2(-190, -195, 380, 315)\n`);
 fs.writeFileSync(path.join(native,'SOURCE.txt'),'Whole equipped Meshy Mycean rendered from approved v2. Knee-first forward collapse; staff released to the side. 10 held poses × four views,320px; no runtime3D. Reproduce via docs/reference/mycean-review/v4-death/README.txt. Uniform reduction only.\n');
 console.log(JSON.stringify({bytes,rgba:4*1600*640*4,duration:poses.durations_ms.reduce((a,b)=>a+b,0)}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
