// Whole-render packing only. No painting or character-part compositing.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname,root=path.resolve(dir,'../../../..'),views=['se','sw','nw','ne'];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'))),cfg=poses.actions.attack;
 const n=cfg.durations.length,size=cfg.size,native=path.join(root,'assets/previews/paladin-attack');
 fs.mkdirSync(native,{recursive:true});
 const anchor=[size/2,(.5+cfg.target_z*Math.cos(Math.PI/6)/cfg.ortho)*size];
 const registration={anchor,frame_size:size,hero_scale:poses.hero_scale,ortho_scale:cfg.ortho,
   durations_ms:cfg.durations,phases:cfg.phases,loop:false,impact_frame:cfg.impact_frame,
   impact_ms:cfg.durations.slice(0,cfg.impact_frame).reduce((a,b)=>a+b,0),views:{}};
 const records=[],buffers={},board=[];let bytes=0;
 for(let row=0;row<4;row++){
  const view=views[row],comps=[];buffers[view]=[];
  const projection=poses.views.attack[view];
  if(projection.anchor_px.some((p,i)=>Math.abs(p/2-anchor[i])>.001))throw Error('Ground registration mismatch');
  const world=p=>p.map((v,i)=>(v/2-anchor[i])*poses.hero_scale);
  registration.views[view]={impact:world(projection.impact_px),ground:world(projection.ground_contact_px),
   top:projection.target_top_corners_px.map(world),bottom:projection.target_bottom_corners_px.map(world)};
  for(let i=0;i<n;i++){
   const file=path.join(dir,'masters/attack',view,`attack-${String(i).padStart(2,'0')}.png`);
   const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   if(info.width!==size*2||info.height!==size*2)throw Error('Unexpected master size');
   let x0=info.width,y0=info.height,x1=-1,y1=-1;
   for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
   if(x1<0||x0<2||y0<2||x1>info.width-3||y1>info.height-3)throw Error('Clipped or empty '+file);
   // The rig verifier proves identical end poses. Reuse the first whole image
   // for the last guard to avoid a denoiser-only flicker at the loop boundary.
   const png=i===n-1?buffers[view][0]:await sharp(file).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();
   buffers[view].push(png);
   if(i<n-1)comps.push({input:png,left:i*size,top:0});
   records.push({view,index:i,sha256:sha(png),alphaBounds:[x0,y0,x1,y1]});
   board.push({input:await sharp(png).resize(192).png().toBuffer(),left:i*196,top:row*196});
  }
  if(new Set(records.filter(r=>r.view===view).map(r=>r.sha256)).size!==n-1)throw Error('Duplicate action poses');
  const sheet=path.join(native,`attack-${view}.png`);
  await sharp({create:{width:size*(n-1),height:size,channels:4,background:'#00000000'}}).composite(comps).png().toFile(sheet);bytes+=fs.statSync(sheet).size;
 }
 fs.writeFileSync(path.join(native,'registration.json'),JSON.stringify(registration,null,2)+'\n');
 let tres=`[gd_resource type="SpriteFrames" load_steps=${5+4*n} format=3]\n\n`;
 views.forEach((v,j)=>tres+=`[ext_resource type="Texture2D" path="res://assets/previews/paladin-attack/attack-${v}.png" id="${j+1}"]\n`);
 views.forEach((v,j)=>{for(let i=0;i<n;i++)tres+=`\n[sub_resource type="AtlasTexture" id="${v}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${(i===n-1?0:i)*size}, 0, ${size}, ${size})\nfilter_clip = true\n`;});
 tres+='\n[resource]\nanimations = ['+views.map(v=>'{"frames": ['+cfg.durations.map((ms,i)=>`{"duration": ${ms/100}, "texture": SubResource("${v}_${i}")}`).join(',\n')+`], "loop": false, "name": &"${v}", "speed": 10.0}`).join(',\n')+']\n';
 tres+=`metadata/ground_anchor = Vector2(${anchor.join(', ')})\nmetadata/hero_scale = ${poses.hero_scale}\nmetadata/impact_time = ${registration.impact_ms/1000}\n`;
 fs.writeFileSync(path.join(native,'frames.tres'),tres);
 fs.writeFileSync(path.join(root,'scenes/PaladinAttack.tscn'),`[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/paladin_attack_preview.gd" id="1"]\n[ext_resource type="SpriteFrames" path="res://assets/previews/paladin-attack/frames.tres" id="2"]\n\n[node name="PaladinAttack" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\nanimation_frames = ExtResource("2")\npreview_title = "Paladin · hammer attack"\nphases = PackedStringArray(${cfg.phases.map(s=>JSON.stringify(s)).join(', ')})\nframe_anchor = Vector2(${anchor.join(', ')})\nreplay_caption = "Attack"\nstage_bounds = Rect2(-190, -240, 380, 345)\n`);
 fs.writeFileSync(path.join(native,'SOURCE.txt'),'Approved whole equipped Meshy Paladin, v3 rig. Ten held poses including identical guard endpoints, four real views. Offline Blender, no runtime 3D. Reproduce via docs/reference/lithide-review/v7-hammer-attack/README.txt.\n');
 const animated=[];
 for(let i=0;i<n;i++){
  const layers=views.map((v,j)=>({input:buffers[v][i],left:(j%2)*352+16,top:Math.floor(j/2)*352+16}));
  animated.push(await sharp({create:{width:704,height:704,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
 }
 for(const [name,multiplier]of [['attack-preview',1],['attack-slow',2]]){
  const delay=cfg.durations.map((ms,i)=>ms*multiplier+(i===n-1?1000:0));
  const file=path.join(dir,name+'.webp');
  await sharp(Buffer.concat(animated),{raw:{width:704,height:704*n,channels:4,pageHeight:704}}).webp({lossless:true,loop:0,delay}).toFile(file);
  const m=await sharp(file,{animated:true}).metadata();if(m.pages!==n||m.delay.reduce((a,b)=>a+b,0)!==delay.reduce((a,b)=>a+b,0))throw Error('Animation timing mismatch');
 }
 await sharp({create:{width:n*196,height:784,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'attack-poses.png'));
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify({sheet_bytes:bytes,rgba_bytes:4*size*size*(n-1)*4,...registration,frames:records},null,2)+'\n');
 console.log(JSON.stringify({bytes,rgba:4*size*size*(n-1)*4,duration:cfg.durations.reduce((a,b)=>a+b,0),anchor}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
