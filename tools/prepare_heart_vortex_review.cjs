// Offline visual review. No source repainting, native UI or save writes.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {chromium}=require('playwright');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/heart-vortex-review/v1';
const abs=p=>path.join(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const rect=r=>({left:r[0],top:r[1],width:r[2],height:r[3]});
const write=(p,b)=>fs.writeFileSync(abs(OUT+'/'+p),b);
async function main(){
 const catalog=read('assets/dungeon/isometric-kit/catalog.json'),before=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json');
 const regions=catalog.atlas.regions,e=regions.heart,atlasPath='assets/dungeon/isometric-kit/atlas-256.png';
 for(const [id,old] of Object.entries(before.atlas.regions)){
  const now=structuredClone(regions[id]);if(id==='heart')delete now.vortex;
  if(JSON.stringify(now)!==JSON.stringify(old))throw Error('Unexpected region/metadata change: '+id);
 }
 for(const p of [atlasPath,'assets/dungeon/isometric-kit/chests/atlas-256.png','project.godot'])
  if(sha(p)!==sha(OUT+'/before/'+p))throw Error('Unexpected asset/project change: '+p);
 const godotSource=fs.readFileSync(abs('shaders/heart_vortex.gdshader'),'utf8');
 // Translate only stage declarations and built-ins; fragment body stays identical.
 const fragment='#version 300 es\nprecision highp float;\nconst float TAU=6.283185307179586;\nuniform sampler2D TEXTURE;\nuniform vec2 TEXTURE_PIXEL_SIZE;\nin vec2 UV;\nout vec4 COLOR;\n'+godotSource
  .replace(/shader_type[^;]+;/,'').replace(/render_mode[^;]+;/,'')
  .replace(/uniform ([^;=]+)\s*=\s*[^;]+;/g,'uniform $1;')
  .replace('varying vec4 vertex_tint;','in vec4 vertex_tint;')
  .replace(/void vertex\(\)\s*\{[^}]*\}/,'').replace('void fragment()','void main()');
 const vertex='#version 300 es\nprecision highp float;\nin vec2 position;\nuniform vec4 atlas_rect;\nout vec2 UV;\nout vec4 vertex_tint;\nvoid main(){gl_Position=vec4(position,0,1);UV=atlas_rect.xy+vec2((position.x+1.)*.5,(1.-position.y)*.5)*atlas_rect.zw;vertex_tint=vec4(1.);}';
 const atlas=await sharp(abs(atlasPath)).metadata(),anchor=[200,205],zoom=.75,layers=[];
 async function add(id,at){
  const r=regions[id],file=(r.atlas_path??'res://'+atlasPath).replace('res://','');
  const input=await sharp(abs(file)).extract(rect(r.region)).resize(Math.round(r.size[0]*zoom),Math.round(r.size[1]*zoom)).png().toBuffer();
  layers.push({input,left:Math.round(anchor[0]+(at[0]+r.offset[0])*zoom),top:Math.round(anchor[1]+(at[1]+r.offset[1])*zoom)});
 }
 for(const y of [-1,0])for(const x of [-1,0])await add('floor-b1',[128*(x-y),64*(x+y)]);
 for(const id of e.ground_effects)await add(id,[0,0]);
 const background=await sharp({create:{width:400,height:310,channels:4,background:'#080e18'}}).composite(layers).png().toBuffer();
 const options={entry:e,atlasSize:[atlas.width,atlas.height],vertex,fragment,image:'data:image/png;base64,'+fs.readFileSync(abs(atlasPath)).toString('base64'),background:'data:image/png;base64,'+background.toString('base64'),anchor,zoom};
 const html='<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Vortex du cœur</title><style>body{background:#080e18;color:#e8e1d5;font:16px system-ui;margin:24px}main{max-width:840px;margin:auto}h1{font-size:24px}section{display:flex;flex-wrap:wrap;gap:16px}canvas{max-width:100%;height:auto}button,input{min-height:44px}button{background:#252338;color:#eee;border:1px solid #81719a;border-radius:8px;padding:8px 16px}small{color:#abb1c5}#raw{display:none}</style><main><h1>Vortex du cœur</h1><p>Spirale en mouvement · socle et anneau stables</p><section><div><p>Échelle mobile</p><canvas id="scene" width="400" height="310"></canvas></div><div><p>Détail du cœur ×2</p><canvas id="detail" width="318" height="323"></canvas></div></section><button id="toggle">Pause</button> <label><input id="enabled" type="checkbox" checked> Animation</label><p><input id="phase" type="range" min="0" max="1" step=".001" value="0" style="width:100%"></p><small>Aperçu WebGL du même shader et des textures du jeu ; pas une capture Godot.</small><canvas id="raw"></canvas></main><script>const options='+JSON.stringify(options).replace(/</g,'\\u003c')+';\n'+fs.readFileSync(abs('tools/heart_vortex_review_browser.js'),'utf8')+'</script></html>';
 write('preview.html',html);
 const browser=await chromium.launch({executablePath:process.env.VORTEX_REVIEW_BROWSER??'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage({viewport:{width:900,height:660}});let report;
 try{
  await page.setContent(html);await page.waitForFunction(()=>window.reviewReady||window.reviewError);
  const error=await page.evaluate(()=>window.reviewError);if(error)throw Error(error);
  await page.evaluate(()=>window.vortexReview.stop());
  const png=async(phase,enabled=true,scene=false)=>Buffer.from((await page.evaluate(({phase,enabled,scene})=>{window.vortexReview.draw(phase,enabled);return window.vortexReview[scene?'scene':'raw']();},{phase,enabled,scene})).split(',')[1],'base64');
  const base=await png(0,false);write('disabled.png',base);
  const {data:reference,info}=await sharp(base).raw().toBuffer({resolveWithObject:true}),statistics=[];
  for(const phase of [0,.125,.25,.5,.75,1]){
   const buffer=await png(phase);write('phase-'+String(phase).replace('.','_')+'.png',buffer);
   const raw=await sharp(buffer).raw().toBuffer();let changed=0,outside=0,alpha=0,max=0;
   for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
    const k=(y*info.width+x)*4,p=[((x+.5)/info.width*e.size[0]-e.vortex.center[0])/e.vortex.radius,((y+.5)/info.height*e.size[1]-e.vortex.center[1])/e.vortex.radius],r=Math.hypot(...p);
    const allowed=(r>.06&&r<.82)||(r>.72&&r<1.4&&p[1]<.92);
    const delta=Math.max(...[0,1,2].map(c=>Math.abs(raw[k+c]-reference[k+c])));
    if(delta){changed++;if(!allowed)outside++;max=Math.max(max,delta);}if(raw[k+3]!==reference[k+3])alpha++;
   }
   statistics.push({phase,changedPixels:changed,outsideEffect:outside,alphaChanged:alpha,maxRGBDifference:max});
  }
  const frames=[],count=144;
  for(let i=0;i<count;i++)frames.push(await sharp(await png(i/count,true,true)).ensureAlpha().raw().toBuffer());
  await sharp(Buffer.concat(frames),{raw:{width:400,height:310*count,channels:4,pageHeight:310}}).gif({loop:0,delay:Array.from({length:count},(_,i)=>i%3===2?90:80),dither:.5,effort:3}).toFile(abs(OUT+'/vortex.gif'));
  await page.evaluate(()=>window.vortexReview.draw(.125));await page.screenshot({path:abs(OUT+'/preview.png')});
  report={date:'2026-10-25',shader:'shaders/heart_vortex.gdshader',shaderHash:sha('shaders/heart_vortex.gdshader'),kind:'Same fragment body executed in isolated headless WebGL2; not a Godot GPU capture',renderer:await page.evaluate(()=>window.vortexReview.renderer),statistics,unchangedAtlasPages:true,unchangedPreparedRegions:Object.keys(before.atlas.regions).length,textureMemoryDelta:0,extraSprites:0,cycleSeconds:12,gif:{frames:count,width:400,height:310},limits:['Godot state inventory is headless; WebGL preview does not validate Godot GPU lights/compositing.','No automated test suite, native UI control, phone profile or full raid run.']};
 }finally{await browser.close();}
 write('validation.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
