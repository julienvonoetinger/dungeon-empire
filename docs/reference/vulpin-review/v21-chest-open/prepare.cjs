const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname,views=['se','sw','nw','ne'],labels=['Sud-est','Sud-ouest','Nord-ouest','Nord-est'];
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const text=(s,x,y,size=18)=>`<text x="${x}" y="${y}" fill="#e9e3d7" font-size="${size}" font-family="Segoe UI,Arial">${s}</text>`;
async function main(){
 const poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'),'utf8'));
 const count=poses.frame_count,order=poses.playback_order,timing=poses.durations_ms;
 const sprites=path.join(dir,'sprites'),runtime=path.resolve(dir,'../../../../assets/previews/vulpin-chest-open');
 fs.mkdirSync(sprites,{recursive:true});fs.mkdirSync(runtime,{recursive:true});
 const report={frames:[],sourceUnchanged:poses.source_unchanged,checks:[],animations:[],pixelArt:false};
 const manifest={frameSize:[256,256],uniquePoses:count,fps:10,order,durationsMs:timing,duration:poses.duration_seconds,loop:false,filter:'linear',directions:{},source:poses.source_sha256};
 const board=[],allFrames={};let sheetBytes=0;
 const boardWidth=count*215+16;
 for(let row=0;row<views.length;row++){
  const view=views[row],frameDir=path.join(sprites,view);fs.mkdirSync(frameDir,{recursive:true});
  const comps=[];allFrames[view]=[];
  board.push({input:svg(boardWidth,36,text(labels[row],14,27,21)),left:0,top:row*264});
  for(let i=0;i<count;i++){
   const input=path.join(dir,'masters',view,`chest-open-${String(i).padStart(2,'0')}.png`);
   const raw=await sharp(input).ensureAlpha().raw().toBuffer();
   let minX=512,minY=512,maxX=-1,maxY=-1;
   for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(raw[(y*512+x)*4+3]>8){minX=Math.min(x,minX);maxX=Math.max(x,maxX);minY=Math.min(y,minY);maxY=Math.max(y,maxY);}
   if(maxX<0||minX<2||minY<2||maxX>509||maxY>509)throw Error('Empty/clipped frame '+view+i);
   const png=await sharp(input).resize(256,256,{kernel:'lanczos3'}).png().toBuffer();
   fs.writeFileSync(path.join(frameDir,`chest-open-${String(i).padStart(2,'0')}.png`),png);
   allFrames[view].push(png);comps.push({input:png,left:i*256,top:0});
   report.frames.push({view,index:i,masterAlphaBounds:[minX,minY,maxX,maxY],bytes:png.length,sha256:hash(png)});
   board.push({input:await sharp(input).resize(208,208).png().toBuffer(),left:8+i*215,top:row*264+36});
   board.push({input:svg(208,20,text(poses.poses[i].label,16,16,13)),left:8+i*215,top:row*264+241});
  }
  if(new Set(report.frames.filter(f=>f.view===view).map(f=>f.sha256)).size!==count)throw Error('Duplicate pose '+view);
  const sheet=`chest-open-${view}.png`;
  await sharp({create:{width:count*256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(comps).png().toFile(path.join(sprites,sheet));
  sheetBytes+=fs.statSync(path.join(sprites,sheet)).size;
  fs.copyFileSync(path.join(sprites,sheet),path.join(runtime,sheet));
  manifest.directions[view]={sheet,anchor:poses.views[view].anchor_px.map(v=>v/2)};
 }
 await sharp({create:{width:boardWidth,height:1056,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'pose-board.png'));
 // Preview one complete cycle with the same timing as the runtime resource.
 const previewOrder=order,previewTiming=timing;
 const combined=[];
 for(const pose of previewOrder){
  const layers=[];
  for(let j=0;j<4;j++){
   layers.push({input:allFrames[views[j]][pose],left:(j%2)*288+16,top:Math.floor(j/2)*288+28});
   layers.push({input:svg(288,28,text(labels[j],18,23,17)),left:(j%2)*288,top:Math.floor(j/2)*288});
  }
  combined.push(await sharp({create:{width:576,height:576,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
 }
 const preview=path.join(dir,'chest-open-preview.webp');
 await sharp(Buffer.concat(combined),{raw:{width:576,height:576*combined.length,channels:4,pageHeight:576}}).webp({lossless:true,loop:0,delay:previewTiming}).toFile(preview);
 const meta=await sharp(preview,{animated:true}).metadata();
 if(meta.delay.reduce((a,b)=>a+b,0)!==timing.reduce((a,b)=>a+b,0))throw Error('Preview timing');
 for(const p of poses.poses){
  if(p.max_reach_error>.001)throw Error('Unreachable wrist');
  if(!p.finite||p.mesh_min_z<-.00001)throw Error('Invalid geometry '+p.index);
  if(Math.min(...Object.values(p.sole_min_z).map(Math.abs))>.00001)throw Error('Missing sole contact '+p.index);
  if(Math.max(...Object.values(p.sole_min_z))>.02)throw Error('Unplanted foot '+p.index);
 }
 // The grounded stance stays fixed throughout this tool-free interaction.
 for(const p of poses.poses)for(const side of ['L','R'])for(const k of [0,1])if(Math.abs(p.feet[side].ankle[k]-poses.poses[0].feet[side].ankle[k])>1e-5)throw Error('Foot target slides');
 let frames=`[gd_resource type="SpriteFrames" load_steps=${1+views.length+views.length*count} format=3]\n\n`;
 views.forEach((view,j)=>{frames+=`[ext_resource type="Texture2D" path="res://assets/previews/vulpin-chest-open/chest-open-${view}.png" id="${j+1}"]\n`;});
 views.forEach((view,j)=>{for(let i=0;i<count;i++)frames+=`\n[sub_resource type="AtlasTexture" id="${view}_${i}"]\natlas = ExtResource("${j+1}")\nregion = Rect2(${i*256}, 0, 256, 256)\nfilter_clip = true\n`;});
 frames+='\n[resource]\nanimations = ['+views.map(view=>'{'+'"frames": ['+order.map((pose,i)=>`{"duration": ${timing[i]/100}, "texture": SubResource("${view}_${pose}")}`).join(',\n')+`], "loop": false, "name": &"${view}", "speed": 10.0}`).join(',\n')+']\n';
 fs.writeFileSync(path.join(runtime,'frames.tres'),frames);
 const registration={frameSize:[256,256],heroScale:.85,modelToGrid:poses.model_to_grid,chestState:'unlocked-ajar',contactFrame:2,gripHeight:.26,directions:{}};
 for(const view of views){
  const k=poses.model_to_grid;
  const map=([x,y,z])=>({se:[-y,-x,z],sw:[x,-y,z],nw:[y,x,z],ne:[-x,y,z]})[view].map(v=>v*k);
  const bounds=poses.poses.map(p=>{
   const points=[];for(const x of [p.bounds[0][0],p.bounds[1][0]])for(const y of [p.bounds[0][1],p.bounds[1][1]])for(const z of [p.bounds[0][2],p.bounds[1][2]])points.push(map([x,y+.2,z]));
   return {min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};
  });
  registration.directions[view]={anchor:poses.views[view].anchor_px.map(v=>v/2),grips:poses.views[view].grips_px.map(g=>Object.fromEntries(Object.entries(g).map(([s,p])=>[s,p.map(v=>v/2)]))),bounds};
 }
 fs.writeFileSync(path.join(runtime,'registration.json'),JSON.stringify(registration,null,2)+'\n');
 report.checks=['32 unique unclipped frames','One-shot 1.08 seconds, four directions','All requested wrist targets reachable without stretching','Planted feet and original GLB hash checked'];
 report.sheetBytes=sheetBytes;report.uncompressedRGBABytes=4*count*256*256*4;
 report.limits='No facial morphs, gameplay integration, device profile or automatic self-intersection guarantee. Artistic review pending.';
 fs.writeFileSync(path.join(sprites,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({checks:report.checks,sheetBytes,uncompressedRGBABytes:report.uncompressedRGBABytes},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1});
