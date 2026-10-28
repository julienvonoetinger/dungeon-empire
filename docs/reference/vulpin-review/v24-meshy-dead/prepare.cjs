const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto'), sharp = require('sharp');
const dir = __dirname, views = ['se','sw','nw','ne'];
const runtime = path.resolve(dir, '../../../../assets/previews/vulpin-death');
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const svg = (w,h,s) => Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${s}</svg>`);
const label = (s,x,y,size=15) => `<text x="${x}" y="${y}" fill="#e8e1ed" font-family="Segoe UI,Arial" font-size="${size}">${s}</text>`;
async function main() {
  const source = JSON.parse(fs.readFileSync(path.join(dir,'poses.json'),'utf8'));
  const canvas = source.canvas / 2, frames = [], layers = [], previews = {};
  fs.mkdirSync(runtime,{recursive:true});
  fs.mkdirSync(path.join(dir,'sprites'),{recursive:true});
  for (const view of views) {
    previews[view] = [];
    for (let i=0;i<source.frame_count;i++) {
      const master = path.join(dir,'masters',view,`fall-${String(i).padStart(2,'0')}.png`);
      const png = await sharp(master).resize(canvas,canvas).png().toBuffer();
      const raw = await sharp(png).ensureAlpha().raw().toBuffer();
      let left=canvas, top=canvas, right=-1, bottom=-1;
      for(let y=0;y<canvas;y++)for(let x=0;x<canvas;x++) if(raw[(y*canvas+x)*4+3]>0) {
        left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);
      }
      if(right<0 || left<2 || top<2 || right>canvas-3 || bottom>canvas-3) throw Error(`Empty/clipped ${view}/${i}`);
      const trim={left:left-1,top:top-1,width:right-left+3,height:bottom-top+3};
      frames.push({view,i,trim,png,cut:await sharp(png).extract(trim).png().toBuffer(),sha256:hash(png)});
      previews[view].push(png);
      fs.writeFileSync(path.join(dir,'sprites',`${view}-${i}.png`),png);
    }
  }
  // One trimmed atlas; the virtual canvas and anchor stay constant through
  // AtlasTexture margins. Padding avoids sampling a neighbouring pose.
  const width=1024, padding=2;
  let x=padding,y=padding,rowHeight=0;
  for(const f of frames) {
    if(x+f.trim.width+padding>width) {x=padding;y+=rowHeight+2*padding;rowHeight=0;}
    f.rect={x,y,width:f.trim.width,height:f.trim.height};
    layers.push({input:f.cut,left:x,top:y});
    x+=f.trim.width+2*padding;rowHeight=Math.max(rowHeight,f.trim.height);
  }
  const height=y+rowHeight+padding;
  await sharp({create:{width,height,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(runtime,'atlas.png'));
  let resource='[gd_resource type="SpriteFrames" load_steps=42 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/previews/vulpin-death/atlas.png" id="1"]\n';
  for(const f of frames) resource+=`\n[sub_resource type="AtlasTexture" id="${f.view}_${f.i}"]\natlas = ExtResource("1")\nregion = Rect2(${f.rect.x}, ${f.rect.y}, ${f.rect.width}, ${f.rect.height})\nmargin = Rect2(${f.trim.left}, ${f.trim.top}, ${canvas-f.trim.width}, ${canvas-f.trim.height})\nfilter_clip = true\n`;
  const animations=views.map(view=>`{"frames": [${frames.filter(f=>f.view===view).map(f=>`{"duration": ${source.durations_ms[f.i]/100}, "texture": SubResource("${view}_${f.i}")}`).join(',')}], "loop": false, "name": &"${view}", "speed": 10.0}`);
  for(const view of views)animations.push(`{"frames": [{"duration": 1.0, "texture": SubResource("${view}_9")}], "loop": false, "name": &"dead-${view}", "speed": 1.0}`);
  resource+='\n[resource]\nanimations = ['+animations.join(',\n')+']\n';
  const anchor=source.views.se.anchor_px.map(v=>v/2);
  resource+=`metadata/ground_anchor = Vector2(${anchor[0]}, ${anchor[1]})\nmetadata/hero_scale = 0.85\n`;
  fs.writeFileSync(path.join(runtime,'frames.tres'),resource);
  const board=[];
  for(let i=0;i<10;i++) {
    const bx=(i%5)*240,by=Math.floor(i/5)*268;
    board.push({input:svg(240,28,label(`${i+1}. ${source.poses[i].label}`,10,22)),left:bx,top:by});
    board.push({input:await sharp(previews.se[i]).resize(240,240).png().toBuffer(),left:bx,top:by+28});
  }
  await sharp({create:{width:1200,height:536,channels:4,background:'#202836'}}).composite(board).png().toFile(path.join(dir,'pose-board.png'));
  const movie=[];
  for(let i=0;i<10;i++) {
    const tiles=[];
    for(let j=0;j<4;j++) {
      tiles.push({input:previews[views[j]][i],left:(j%2)*384,top:Math.floor(j/2)*412+28});
      tiles.push({input:svg(384,28,label(views[j].toUpperCase(),16,23,18)),left:(j%2)*384,top:Math.floor(j/2)*412});
    }
    movie.push(await sharp({create:{width:768,height:824,channels:4,background:'#202836'}}).composite(tiles).raw().toBuffer());
  }
  const delays=source.durations_ms.map((n,i)=>i===9?n+1200:n);
  await sharp(Buffer.concat(movie),{raw:{width:768,height:8240,channels:4,pageHeight:824}}).webp({lossless:true,loop:0,delay:delays}).toFile(path.join(dir,'fall-preview.webp'));
  const sheets=JSON.parse(fs.readFileSync(path.join(dir,'previous-sprite-hashes.json'),'utf8').replace(/^\uFEFF/,''));
  // Historical evidence stores Windows absolute paths. Resolve its asset suffix
  // against this checkout so a moved repository still checks the same sprites.
  const previousPath = s => {
    const normalized=s.Path.replace(/\\/g,'/');
    const marker='/assets/previews/';
    const at=normalized.indexOf(marker);
    if(at<0)throw Error('Unrecognized previous sprite path: '+s.Path);
    return path.resolve(dir,'../../../..',normalized.slice(at+1));
  };
  if(sheets.some(s=>hash(fs.readFileSync(previousPath(s))).toUpperCase()!==s.Hash)) throw Error('Previous sprite changed');
  const glb=fs.readFileSync(path.join(dir,'../source/Meshy_AI_Character_output.glb'));
  if(hash(glb)!==source.source_sha256)throw Error('Source GLB changed');
  for(const view of views)if(new Set(frames.filter(f=>f.view===view).map(f=>f.sha256)).size!==10)throw Error('Duplicate fall pose');
  const manifest={canvas,anchor,heroScale:.85,durationsMs:source.durations_ms,totalSeconds:source.durations_ms.reduce((a,b)=>a+b,0)/1000,
    frames:frames.map(({view,i,trim,rect,sha256})=>({view,i,trim,rect,sha256})),
    atlas:{width,height,pngBytes:fs.statSync(path.join(runtime,'atlas.png')).size,rgbaBytes:width*height*4},
    previousSheetsUnchanged:sheets.length,sourceUnchanged:true,
    limits:'Posed preview, not gameplay integration or physical simulation. No facial rig or automatic self-intersection proof.'};
  fs.writeFileSync(path.join(runtime,'registration.json'),JSON.stringify(manifest,null,2)+'\n');
  fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log(JSON.stringify({frames:frames.length,...manifest.atlas,previousSheetsUnchanged:sheets.length}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
