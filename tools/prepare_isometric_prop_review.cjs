// Presentation only: preserve native source alpha, resize uniformly, and place
// proposed props over real B paving with the exact shared 2:1 ground axes.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-prop-review/v1';
const abs=p=>path.resolve(ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const xml=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
async function inspect(file){
 const {data,info}=await sharp(abs(file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const bounds=[{x:info.width,y:info.height,X:-1,Y:-1},{x:info.width,y:info.height,X:-1,Y:-1}];
 let transparent=0;
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
  const a=data[(y*info.width+x)*4+3];if(!a){transparent++;continue;}
  for(let i=0;i<2;i++)if(a>(i?127:0)){const b=bounds[i];b.x=Math.min(b.x,x);b.X=Math.max(b.X,x);b.y=Math.min(b.y,y);b.Y=Math.max(b.Y,y);}
 }
 if(!transparent||bounds[1].X<0)throw Error('Missing native alpha or visible prop');
 const rect=b=>({left:b.x,top:b.y,width:b.X-b.x+1,height:b.Y-b.y+1});
 return {nativeSize:[info.width,info.height],crop:rect(bounds[0]),solidBounds:rect(bounds[1]),transparentPixels:transparent,sha256:hash(file)};
}
async function view(entry,width,height,scale,grid){
 const layers=[],cx=width/2,cy=height*.58;
 const floorPath='docs/reference/isometric-floor-variation-review/v1/integration/sprites/floor-b'+(entry.index%4+1)+'.png';
 const floor=await sharp(abs(floorPath)).resize({width:Math.round(270*.75*scale)}).png().toBuffer();
 const meta=await sharp(floor).metadata();
 layers.push({input:floor,left:Math.round(cx-meta.width/2),top:Math.round(cy-meta.height/2)});
 const {crop,solidBounds}=entry.inspection;
 const ratio=entry.gameHeight*scale/solidBounds.height;
 const sprite=await sharp(abs(entry.file)).extract(crop).resize({width:Math.max(1,Math.round(crop.width*ratio))}).png().toBuffer();
 const spriteMeta=await sharp(sprite).metadata(),actualRatio=spriteMeta.width/crop.width;
 // Provisional front contact: a small amount below the cell centre. This is
 // a review placement, not a fitted support volume or a production anchor.
 const contactY=cy+20*scale;
 const left=Math.round(cx-(solidBounds.left+solidBounds.width/2-crop.left)*actualRatio);
 const top=Math.round(contactY-(solidBounds.top+solidBounds.height-crop.top)*actualRatio);
 if(left<0||top<0||left+spriteMeta.width>width||top+spriteMeta.height>height)throw Error('Review canvas too small for '+entry.id+' '+JSON.stringify({width,height,left,top,sprite:[spriteMeta.width,spriteMeta.height],crop,solidBounds}));
 layers.push({input:sprite,left,top});
 if(grid){
  const project=(x,y)=>[cx+(x-y)*96*scale,cy+(x+y)*48*scale];
  const pts=[[-.5,-.5],[.5,-.5],[.5,.5],[-.5,.5]].map(p=>project(...p).join(',')).join(' ');
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><polygon points="${pts}" stroke="#dd61cb" stroke-opacity=".65" stroke-width="1" fill="none"/></svg>`;
  layers.push({input:Buffer.from(svg),left:0,top:0});
 }
 return sharp({create:{width,height,channels:4,background:'#101722'}}).composite(layers).png().toBuffer();
}
async function main(){
 const generation=read(OUT+'/generation.json'),baseline=read('docs/reference/isometric-floor-damage-review/v1/integration/validation.json').sha256;
 for(const [file,expected] of Object.entries(baseline))if(hash(file)!==expected)throw Error('Production file changed '+file);
 const entries=[];
 for(const [index,job] of generation.jobs.entries()){
  const e={...job,index,inspection:await inspect(job.file)};
  if(hash(job.generatedPath)!==e.inspection.sha256)throw Error('Original generated pixels changed');
  entries.push(e);
 }
 const W=1260,H=1100,layers=[];
 let svg=`<rect width="${W}" height="${H}" fill="#0b1019"/><text x="24" y="36" font-size="26" fill="#edf1fa">Décors maléfiques — six propositions</text><text x="24" y="64" font-size="16" fill="#a5b0c7">Repère au sol 2:1 · Même grille que le donjon · Sources à valider avant intégration</text>`;
 for(const e of entries){
  const x=e.index%3*420,y=Math.floor(e.index/3)*490+88;
  svg+=`<rect x="${x+12}" y="${y}" width="396" height="474" rx="12" fill="#101722" stroke="#29354b"/><text x="${x+26}" y="${y+31}" font-size="21" fill="#edf1fa">${xml(e.label)}</text><text x="${x+26}" y="${y+57}" font-size="14" fill="#a5b0c7">${xml(e.description)}</text><text x="${x+26}" y="${y+301}" font-size="14" fill="#a5b0c7">Taille proposée en jeu · ${e.gameHeight}px de haut</text>`;
  layers.push({input:await view(e,370,224,1.6,true),left:x+25,top:y+66});
  layers.push({input:await view(e,230,160,1,false),left:x+95,top:y+308});
 }
 svg+='<text x="24" y="1085" font-size="14" fill="#a5b0c7">Montage de revue, pas une capture Godot · Ancres, volumes, ombres et éclairage à préparer après sélection</text>';
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" style="font-family:Arial,sans-serif">${svg}</svg>`)).composite(layers).png().toFile(abs(OUT+'/comparison.png'));
 const mobile=[];let title='<rect width="1380" height="260" fill="#0b1019"/><text x="20" y="30" font-size="20" fill="#edf1fa">Décors sur les vraies dalles — tailles de jeu proposées</text>';
 for(const e of entries){const x=e.index*230;title+=`<text x="${x+10}" y="64" font-size="16" fill="#edf1fa">${xml(e.label)}</text>`;mobile.push({input:await view(e,230,165,1,false),left:x,top:77});}
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1380" height="260" style="font-family:Arial,sans-serif">${title}</svg>`)).composite(mobile).png().toFile(abs(OUT+'/mobile-scale.png'));
 const evidence={date:generation.date,status:'Appearance proposals only; no selection or integration',entries,unchangedActiveHashes:baseline,
  display:{groundProjection:'screen = .75 * 256 * ((x-y)/2,(x+y)/4)',gridDiamond:[192,96],largeScale:1.6,smallScale:1},
  sourcePolicy:'Preserve all original pixels and native alpha. Alpha128 measures subject height only; crop alpha-zero margins and resize uniformly. No stretching, recolouring or background removal.',
  limitations:['The guide validates the review ground grid, not exact source prop geometry. AI camera correspondence still needs fitted support verification.','Contact anchors are provisional; no baked or procedural shadow/light is added to these review montages.','Production atlas, scripts, scenes and camera unchanged; no Godot import/export, automated tests, commit or push.']};
 fs.writeFileSync(abs(OUT+'/validation.json'),JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify({variants:entries.length,unchangedActiveFiles:Object.keys(baseline).length,board:OUT+'/comparison.png',nativeSources:entries.map(e=>({id:e.id,size:e.inspection.nativeSize}))}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
