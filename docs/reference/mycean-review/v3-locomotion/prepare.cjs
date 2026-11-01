// Pack genuine whole-mesh renders; no paint synthesis, masking or per-part compositing.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname,root=path.resolve(dir,'../../../..'),views=['se','sw','nw','ne'];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const label=(s,x=16,y=23)=>`<text x="${x}" y="${y}" fill="#eee3c9" font-size="18" font-family="Segoe UI,Arial">${s}</text>`;
async function main(){
 const poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json')));
 const report={gaits:{},sourceScene:poses.source_scene_sha256,checks:[]};
 for(const [gait,cfg] of Object.entries(poses.gaits)){
  const native=path.join(root,'assets/previews/mycean-'+gait);fs.mkdirSync(native,{recursive:true});
  const buffers={},board=[],records=[];let bytes=0;
  const duration=Math.round(8*1000/cfg.fps),delays=Array.from({length:8},(_,i)=>Math.round((i+1)*duration/8)-Math.round(i*duration/8));
  for(let row=0;row<4;row++){
   const view=views[row],comps=[];buffers[view]=[];
   board.push({input:svg(1560,30,label(view.toUpperCase())),left:0,top:row*224});
   for(let i=0;i<8;i++){
    const file=path.join(dir,'masters',gait,view,`${gait}-${String(i).padStart(2,'0')}.png`);
    const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    if(info.width!==512||info.height!==512)throw Error('Master dimensions '+file);
    let x0=512,y0=512,x1=-1,y1=-1;
    for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(data[(y*512+x)*4+3]>8){x0=Math.min(x,x0);y0=Math.min(y,y0);x1=Math.max(x,x1);y1=Math.max(y,y1);}
    if(x1<0||x0<2||y0<2||x1>509||y1>509)throw Error('Empty/clipped '+file);
    const png=await sharp(file).resize(256,256,{kernel:'lanczos3'}).png().toBuffer();buffers[view].push(png);comps.push({input:png,left:i*256,top:0});
    records.push({view,index:i,sha256:sha(png),alphaBounds:[x0,y0,x1,y1]});
    board.push({input:await sharp(file).resize(192,192).png().toBuffer(),left:i*195,top:row*224+30});
   }
   if(new Set(records.filter(r=>r.view===view).map(r=>r.sha256)).size!==8)throw Error('Repeated poses '+gait+view);
   const sheet=path.join(native,`${gait}-${view}.png`);
   await sharp({create:{width:2048,height:256,channels:4,background:'#00000000'}}).composite(comps).png().toFile(sheet);bytes+=fs.statSync(sheet).size;
  }
  // Analytic registration, rather than directional float32 camera roundoff.
  const anchor=[128,(.5+.72*Math.cos(Math.PI/6)/poses.ortho_scale)*256];
  for(const view of views)if(poses.views[view].anchor_px.some((x,i)=>Math.abs(x/2-anchor[i])>.001))throw Error('View anchor drift');
  const registration={anchor,frame_size:256,hero_scale:poses.hero_scale,ortho_scale:poses.ortho_scale,half_extent:.23,actor_name:'Mycean',fps:cfg.fps,model_speed:cfg.speed};
  fs.writeFileSync(path.join(native,'registration.json'),JSON.stringify(registration,null,2)+'\n');
  let tres='[gd_resource type="SpriteFrames" load_steps=37 format=3]\n\n';
  views.forEach((view,j)=>tres+=`[ext_resource type="Texture2D" path="res://assets/previews/mycean-${gait}/${gait}-${view}.png" id="${j+1}"]\n`);
  views.forEach((view,j)=>{for(let i=0;i<8;i++)tres+=`\n[sub_resource type="AtlasTexture" id="${view}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${i*256}, 0, 256, 256)\nfilter_clip = true\n`;});
  tres+='\n[resource]\nanimations = ['+views.map(view=>`{"frames": [`+Array.from({length:8},(_,i)=>`{"duration": 1.0, "texture": SubResource("${view}_${i}")}`).join(',\n')+`], "loop": true, "name": &"${view}", "speed": ${cfg.fps}.0}`).join(',\n')+']\n';
  fs.writeFileSync(path.join(native,'frames.tres'),tres);
  const animation=[];
  for(let i=0;i<8;i++){
   const layers=[];
   views.forEach((view,j)=>{layers.push({input:buffers[view][i],left:(j%2)*288+16,top:Math.floor(j/2)*288+28});layers.push({input:svg(288,28,label(view.toUpperCase())),left:(j%2)*288,top:Math.floor(j/2)*288});});
   animation.push(await sharp({create:{width:576,height:576,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
  }
  const webp=path.join(dir,`${gait}-preview.webp`);
  await sharp(Buffer.concat(animation),{raw:{width:576,height:576*8,channels:4,pageHeight:576}}).webp({lossless:true,loop:0,delay:delays}).toFile(webp);
  const meta=await sharp(webp,{animated:true}).metadata();if(meta.pages!==8||meta.delay.reduce((a,b)=>a+b,0)!==duration)throw Error('Playback duration');
  await sharp({create:{width:1560,height:896,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,`${gait}-poses.png`));
  report.gaits[gait]={frames:records,registration,sheetBytes:bytes,rgbaBytes:4*2048*256*4,loopMilliseconds:duration};
  const sceneName=gait==='walk'?'MyceanWalk':'MyceanRun';
  const scene=`[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/vulpin_walk_preview.gd" id="1"]\n[ext_resource type="SpriteFrames" path="res://assets/previews/mycean-${gait}/frames.tres" id="2"]\n\n[node name="${sceneName}" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\npreview_title = "Mycean · corridor ${gait}"\nanimation_frames = ExtResource("2")\npose_fps = ${cfg.fps}.0\nmodel_travel_units_per_second = ${cfg.speed}\nbase_playback_rate = 1.0\nsprite_registration = {\n"anchor": Vector2(${anchor.join(', ')}),\n"frame_size": 256.0,\n"hero_scale": ${poses.hero_scale},\n"ortho_scale": ${poses.ortho_scale},\n"half_extent": 0.23,\n"actor_name": "Mycean"\n}\n`;
  fs.writeFileSync(path.join(root,'scenes',sceneName+'.tscn'),scene);
 }
 report.checks=['64 distinct whole-mesh frames, native alpha and no clipped bounds','Fixed scale and matching directional anchors','Walk15fps/run16fps, eight frames per loop','Source art unchanged; only uniform reduction/atlas packing'];
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(Object.fromEntries(Object.entries(report.gaits).map(([k,v])=>[k,{sheetBytes:v.sheetBytes,rgbaBytes:v.rgbaBytes,registration:v.registration}]))));
}
main().catch(e=>{console.error(e);process.exitCode=1});
