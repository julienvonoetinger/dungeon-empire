const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {chromium}=require('playwright');
const ROOT=path.resolve(__dirname,'../../../..'),base='file:///'+path.join(__dirname,'index.html').replaceAll('\\','/');
async function main(){
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const observations=[],errors=[];const page=await browser.newPage();page.on('pageerror',e=>errors.push(e.message));
 for(const [width,height]of [[844,390],[740,360],[1024,576]])for(const theme of ['obsidian','forge','grimoire']){
  await page.setViewportSize({width,height});await page.goto(base+`?capture&theme=${theme}&tool=spike`);await page.waitForFunction(()=>window.REVIEW_READY);await page.screenshot({path:path.join(__dirname,`captures/${width}-${theme}.png`)});
  const layout=await page.evaluate(()=>({buttons:[...document.querySelectorAll('#game button')].filter(b=>b.getClientRects().length).map(b=>{const r=b.getBoundingClientRect();return {label:b.getAttribute('aria-label')||b.textContent.trim(),x:r.x,y:r.y,w:r.width,h:r.height};}),width:innerWidth,height:innerHeight,overflow:document.documentElement.scrollWidth>innerWidth}));
  observations.push({width,height,theme,...layout,smallTargets:layout.buttons.filter(b=>b.w<47.9||b.h<47.9),outside:layout.buttons.filter(b=>b.x<-.1||b.y<-.1||b.x+b.w>width+.1||b.y+b.h>height+.1)});
 }
 await page.setViewportSize({width:844,height:390});await page.goto(base+'?capture&theme=obsidian');await page.waitForFunction(()=>window.REVIEW_READY);
 await page.getByRole('button',{name:'Pointes, 35 or',exact:true}).click();
 const snapshots=[];async function record(name){snapshots.push({name,...await page.evaluate(()=>window.REVIEW.state())});}
 async function cellClick(x,y){const p=await page.evaluate(([x,y])=>window.REVIEW.cellScreen({x,y}),[x,y]);await page.mouse.click(p.x,p.y);}
 await record('tool-selected');await cellClick(6,7);await cellClick(7,6);await cellClick(8,7);await record('three-placements');await page.screenshot({path:path.join(__dirname,'captures/844-obsidian-placed.png')});
 await page.locator('#undo').click();await record('undo-one');await cellClick(7,7);await record('occupied-no-charge');
 await page.locator('#reset').evaluate(b=>b.click());await page.getByRole('button',{name:'Pointes, 35 or',exact:true}).click();
 const start=await page.evaluate(()=>window.REVIEW.cellScreen({x:7,y:6}));await page.mouse.move(start.x,start.y);await page.mouse.down();await page.mouse.move(start.x+65,start.y+30,{steps:8});await page.mouse.up();await record('pan-no-placement');
 await page.locator('#recenter').click();const target=await page.evaluate(()=>window.REVIEW.cellScreen({x:6,y:7}));const b=await page.locator('[data-tool="spike"]').boundingBox();await page.mouse.move(b.x+b.width/2,b.y+b.height/2);await page.mouse.down();await page.mouse.move(target.x,target.y+52,{steps:12});await page.mouse.up();await record('drag-placement');
 await page.locator('#finish').click();await record('overview');await page.screenshot({path:path.join(__dirname,'captures/844-obsidian-overview.png')});await page.locator('#raid').click();await record('raid-boundary');
 await page.setViewportSize({width:1280,height:1000});await page.goto(base);await page.waitForFunction(()=>window.REVIEW_READY);await page.screenshot({path:path.join(__dirname,'captures/review-page.png'),fullPage:true});
 const baseline=JSON.parse(fs.readFileSync(path.join(__dirname,'baseline.json'),'utf8'));const unchanged=Object.entries(baseline).every(([p,h])=>crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,p))).digest('hex')===h);
 const findings={javascriptErrors:errors,productionFilesUnchanged:unchanged,observations,interactions:snapshots,limits:['Browser mockup only; no Godot implementation or phone validation.','Excavation only previews floor extensions; architecture joins are not rebuilt.','Raid display is static; no gameplay simulation.']};
 fs.writeFileSync(path.join(__dirname,'validation.json'),JSON.stringify(findings,null,2)+'\n');
 await browser.close();console.log(JSON.stringify({errors,productionFilesUnchanged:unchanged,layouts:observations.map(o=>({size:[o.width,o.height],theme:o.theme,small:o.smallTargets,outside:o.outside,overflow:o.overflow})),interactions:snapshots}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
