const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname,views=['se','sw','nw','ne'],labels=['Sud-est','Sud-ouest','Nord-ouest','Nord-est'];
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const svg=(w,h,s)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const text=(s,x,y,size=18)=>`<text x="${x}" y="${y}" fill="#e9e3d7" font-size="${size}" font-family="Segoe UI,Arial">${s}</text>`;
async function main(){
 const poses=JSON.parse(fs.readFileSync(path.join(dir,'poses.json'),'utf8'));
 const sprites=path.join(dir,'sprites');fs.mkdirSync(sprites,{recursive:true});
 const report={frames:[],sourceUnchanged:poses.source_unchanged,checks:[],animations:[],pixelArt:false};
 const manifest={frameSize:[256,256],fps:10,duration:.8,loop:true,filter:'linear',directions:{},source:poses.source_sha256,notes:'Eight held poses from the real Meshy mesh. Review only; not integrated into the game.'};
 const board=[];const allFrames={};let sheetBytes=0;
 for(let row=0;row<views.length;row++){
  const view=views[row],frameDir=path.join(sprites,view);fs.mkdirSync(frameDir,{recursive:true});
  const comps=[],buffers=[];allFrames[view]=[];
  board.push({input:svg(1736,36,text(labels[row],14,27,21)),left:0,top:row*264});
  for(let i=0;i<8;i++){
   const input=path.join(dir,'masters',view,`walk-${String(i).padStart(2,'0')}.png`);
   const raw=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   let minX=512,minY=512,maxX=-1,maxY=-1;
   for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(raw.data[(y*512+x)*4+3]>8){minX=Math.min(x,minX);maxX=Math.max(x,maxX);minY=Math.min(y,minY);maxY=Math.max(y,maxY);}
   if(minX<2||minY<2||maxX>509||maxY>509)throw Error('Clipped frame '+view+i);
   const png=await sharp(input).resize(256,256,{kernel:'lanczos3'}).png().toBuffer();
   fs.writeFileSync(path.join(frameDir,`walk-${String(i).padStart(2,'0')}.png`),png);
   allFrames[view].push(png);comps.push({input:png,left:i*256,top:0});
   buffers.push(await sharp(png).ensureAlpha().raw().toBuffer());
   report.frames.push({view,index:i,masterAlphaBounds:[minX,minY,maxX,maxY],bytes:png.length,sha256:hash(png)});
   const thumb=await sharp(input).resize(208,208).png().toBuffer();
   board.push({input:thumb,left:16+i*215,top:row*264+36});
   board.push({input:svg(208,20,text(String(i+1).padStart(2,'0'),96,16,13)),left:16+i*215,top:row*264+241});
  }
  if(new Set(report.frames.filter(f=>f.view===view).map(f=>f.sha256)).size!==8)throw Error('Duplicate pose '+view);
  const sheet=`walk-${view}.png`;
  await sharp({create:{width:2048,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(comps).png().toFile(path.join(sprites,sheet));
  sheetBytes+=fs.statSync(path.join(sprites,sheet)).size;
  manifest.directions[view]={sheet,frames:8,anchor:poses.views[view].anchor_px.map(v=>v/2)};
  const webpPath=path.join(dir,`walk-${view}.webp`);
  await sharp(Buffer.concat(buffers),{raw:{width:256,height:256*8,channels:4,pageHeight:256}}).webp({lossless:true,loop:0,delay:100}).toFile(webpPath);
  const m=await sharp(webpPath,{animated:true}).metadata();
  if(m.pages!==8||m.pageHeight!==256||m.delay.some(d=>d!==100))throw Error('Animation timing '+view);
  report.animations.push({view,pages:m.pages,delay:m.delay,bytes:fs.statSync(webpPath).size});
 }
 await sharp({create:{width:1736,height:1056,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'pose-board.png'));
 const combined=[];
 for(let i=0;i<8;i++){
  const layers=[];
  for(let j=0;j<4;j++){
   layers.push({input:allFrames[views[j]][i],left:(j%2)*288+16,top:Math.floor(j/2)*288+28});
   layers.push({input:svg(288,28,text(labels[j],18,23,17)),left:(j%2)*288,top:Math.floor(j/2)*288});
  }
  combined.push(await sharp({create:{width:576,height:576,channels:4,background:'#202836'}}).composite(layers).raw().toBuffer());
 }
 await sharp(Buffer.concat(combined),{raw:{width:576,height:576*8,channels:4,pageHeight:576}}).webp({lossless:true,loop:0,delay:100}).toFile(path.join(dir,'walk-preview.webp'));
 for(const p of poses.poses){
  if(!p.finite||p.mesh_min_z<-.00001)throw Error('Invalid geometry '+p.index);
  const supports=Object.keys(p.feet).filter(k=>p.feet[k].grounded);
  if(Math.min(...supports.map(k=>Math.abs(p.sole_min_z[k])))>.00001)throw Error('No contact '+p.index);
  for(const k of Object.keys(p.feet).filter(k=>!p.feet[k].grounded))if(p.sole_min_z[k]<.025)throw Error('Swing foot not raised '+p.index);
 }
 report.checks=['32 nonempty RGBA frames, no clipped alpha bounds','8 distinct poses per direction','Four animated WebP loops: 8 frames, 100ms per frame','Original GLB unchanged','Eight poses finite, at least one sampled sole at z0, raised swing foot','All images share a fixed camera, scale and root anchor'];
 report.sheetBytes=sheetBytes;report.uncompressedRGBABytes=4*2048*256*4;
 report.limits='No physical device, gameplay integration, motion retargeting or automatic self-intersection guarantee. Sole tests use rest-identified boot vertices. Artistic approval pending.';
 fs.writeFileSync(path.join(sprites,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({checks:report.checks,sheetBytes,uncompressedRGBABytes:report.uncompressedRGBABytes,sourceUnchanged:report.sourceUnchanged},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1});
