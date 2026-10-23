// Offline appearance proposal only. Never overwrites the runtime catalog or PNGs.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {ROOT,read,hash,render}=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const OUT='docs/reference/door-material-review-v2';
const source='assets/dungeon/shared-materials/proposals/door-oak-v2.png';
const guides=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json'));
const materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json'));
const woodProfile={color:'#393534',brightness:.8,saturation:.85,opacity:.96,blur:.3};
materials.entries['door-oak']={...materials.entries['door-oak'],file:'proposals/door-oak-v2.png',source,sha256:hash(read(source))};
materials.renderProfile.wood=woodProfile;
function write(file,b){fs.mkdirSync(path.dirname(path.join(ROOT,OUT,file)),{recursive:true});fs.writeFileSync(path.join(ROOT,OUT,file),b);}
function structuralSource(source){
  // Same source-derived union and visible lines as the connected kit exporter.
  const fills=[...source.matchAll(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)].map(m=>m[0]);
  fills.shift(); // ground belongs to the prepared common floor image
  const polygons=fills.flatMap(s=>s.startsWith('<polygon')?[s.match(/points="([^"]+)"/)[1].split(' ').map(p=>p.split(',').map(Number))]:s.match(/d="([^"]+)"/)[1].split('M').filter(Boolean).map(p=>p.replace(/Z$/,'').split('L').map(p=>p.split(',').map(Number))));
  const d=polygons.map(p=>{const a=p.reduce((s,q,i)=>s+q[0]*p[(i+1)%p.length][1]-q[1]*p[(i+1)%p.length][0],0);if(a<0)p.reverse();return 'M'+p.map(q=>q.join(',')).join('L')+'Z';}).join('');
  const lines=[...source.matchAll(/<line\b[^>]*\/>/g)].map(m=>m[0]).filter(l=>!l.includes('#8794a3')).map(l=>l.replace(/stroke="#[a-fA-F0-9]+"/,'stroke="#ff00ff"'));
  return {fill:`<path d="${d}" fill="#ffffff"/>`,guide:source.match(/^<svg[^>]*>/)[0]+'<g stroke-linecap="round" stroke-linejoin="round">'+lines.join('')+'</g></svg>'};
}
async function corridor(door){
  const manifest=JSON.parse(read('assets/dungeon/painted-connected/catalog.json'));
  const id=manifest.aliases['cells/w10_p00_e00'];
  const straight=read('assets/dungeon/painted-connected/'+manifest.entries[id].file);
  const floor=await sharp(read('assets/dungeon/painted-connected/floor.png')).resize(512,512).toBuffer();
  const side=await sharp(straight).resize({width:608}).toBuffer();
  const gate=await sharp(door).resize({width:608}).toBuffer();
  const layers=[];
  for(let row=0;row<3;row++)layers.push({input:floor,left:48,top:176+row*512});
  for(let row=0;row<3;row++)layers.push({input:row===1?gate:side,left:0,top:row*512+(row===1?-80:0)});
  // Crop away remote ends. Comparison retains the same neighbors and placement.
  return sharp({create:{width:608,height:1760,channels:4,background:'#080e18'}}).composite(layers).png().toBuffer().then(b=>sharp(b).extract({left:0,top:400,width:608,height:848}).png().toBuffer());
}
async function main(){
  const reports=[],images=[];
  for(const direction of ['north','east','south','west']){
    const id='doors/'+direction,entry=guides.entries[id],model=makeModel(id,entry);
    const src=read('assets/dungeon/wireframe-doors/'+direction+'.svg').toString(),prepared=structuralSource(src);
    model.floor=false;model.silhouette=prepared.fill;model.clipPaint=true;
    model.paintGuide=read('docs/reference/wireframe-overlays/'+entry.svg).toString();
    const result=await render(model,prepared.guide,materials);
    write(direction+'.png',result.png);write(direction+'-overlay.png',result.overlay);
    const {faces,...report}=result.report;reports.push(report);images.push({direction,sha256:hash(result.png),sourceGuideSha256:hash(src)});
  }
  const before=await corridor(read('assets/dungeon/painted-connected/doors/north.png'));
  const after=await corridor(read(OUT+'/north.png'));
  write('before.png',before);write('after.png',after);
  const bg=Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="1264" height="932"><rect width="100%" height="100%" fill="#0b111d"/><g fill="#dde4ef" font-family="Arial,sans-serif" font-size="24"><text x="24" y="38">Actuel</text><text x="656" y="38">Proposition · bois vieilli</text></g><text x="24" y="916" fill="#aebbd0" font-family="Arial,sans-serif" font-size="17">Mêmes géométrie, pierres, ferrures et dallage · aperçu hors Godot</text></svg>');
  const comparison=await sharp(bg).composite([{input:before,left:12,top:54},{input:after,left:644,top:54}]).png().toBuffer();
  write('comparison.png',comparison);
  write('recipe.json',JSON.stringify({status:'appearance_proposal_awaiting_user_review',generator:'tools/prepare_door_material_review.cjs',source,sourceSha256:hash(read(source)),woodProfile,unchanged:['geometry','projection','joints','wall materials','floor materials','iron material','Godot runtime catalog'],images,reports},null,2)+'\n');
  console.log(JSON.stringify({output:OUT,images:images.length,geometry:reports.map(r=>({id:r.id,constructionJointsMatch:r.constructionJointLayerMatchesGuide,alphaDifference:r.alphaPixelsDifferentFromModel}))},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
