// Review presentation only. Preserve generated alpha; no silhouette cleanup.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'../../../..'),P=p=>path.join(ROOT,p);
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
async function inspect(file){
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const b=[info.width,info.height,-1,-1];let zero=0,partial=0;
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
  const a=data[(y*info.width+x)*4+3];if(!a)zero++;else if(a<255)partial++;
  // Only measure body size. Never use this threshold to alter the source.
  if(a>=128){b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
 }
 return {size:[info.width,info.height],body:b,zero,partial,sha256:hash(file)};
}
async function main(){
 const entries=[
  {name:'Coffre précédent — écarté',file:path.join(__dirname,'../v1/source/chest-closed-v2.png'),width:96},
  {name:'Coffre rituel — proposition',file:path.join(__dirname,'source/chest-ritual-v1.png'),width:96},
  {name:'Idole — référence existante',file:P('docs/reference/isometric-prop-review/v1/source/b-idole.png'),height:76},
 ];
 for(const e of entries)e.inspection=await inspect(e.file);
 async function panel(e,scale){
  const w=304,h=220,cx=w/2,cy=147,layers=[];
  const floor=await sharp(P('docs/reference/isometric-floor-variation-review/v1/integration/sprites/floor-b1.png')).resize({width:Math.round(270*.75*scale)}).png().toBuffer();
  const fm=await sharp(floor).metadata();
  // A larger virtual canvas allows a 2x crop without clipping any source art.
  const W=900,H=700,ox=300,oy=230;
  layers.push({input:floor,left:Math.round(ox+cx-fm.width/2),top:Math.round(oy+cy-fm.height/2)});
  const b=e.inspection.body,ratio=(e.width?e.width/(b[2]-b[0]+1):e.height/(b[3]-b[1]+1))*scale;
  const sprite=await sharp(e.file).resize({width:Math.round(e.inspection.size[0]*ratio)}).png().toBuffer(),sm=await sharp(sprite).metadata();
  const r=sm.width/e.inspection.size[0];
  layers.push({input:sprite,left:Math.round(ox+cx-(b[0]+b[2]+1)/2*r),top:Math.round(oy+cy+20*scale-(b[3]+1)*r)});
  return sharp({create:{width:W,height:H,channels:4,background:'#101722'}}).composite(layers).png().toBuffer().then(buf=>sharp(buf).extract({left:ox,top:oy,width:w,height:h}).png().toBuffer());
 }
 const W=960,H=650,layers=[];
 let svg='<rect width="960" height="650" fill="#0b1019"/><text x="24" y="34" font-size="25" fill="#edf1fa">Coffre rituel — une silhouette plus maléfique</text><text x="24" y="62" font-size="15" fill="#a5b0c7">Fer sombre · renforts en griffes · sceau violet</text>';
 for(let i=0;i<entries.length;i++){
  const x=16+i*316,e=entries[i];
  svg+=`<text x="${x+6}" y="104" font-size="17" fill="#edf1fa">${e.name}</text><text x="${x+6}" y="128" font-size="13" fill="#a5b0c7">Échelle proposée en jeu${i<2?' · corps 96 px de large':''}</text><text x="${x+6}" y="374" font-size="13" fill="#a5b0c7">Même vue agrandie ×2</text>`;
  layers.push({input:await panel(e,1),left:x,top:133});
  layers.push({input:await panel(e,2),left:x,top:382});
 }
 svg+='<text x="24" y="637" font-size="13" fill="#a5b0c7">Montage de revue, pas une capture Godot · Taille proposée · Apparence non intégrée</text>';
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" style="font-family:Arial,sans-serif">${svg}</svg>`)).composite(layers).png().toFile(path.join(__dirname,'mobile-comparison.png'));
 const e=entries[1],b=e.inspection.body,ratio=128/(b[2]-b[0]+1);
 // Provisional atlas-size raster, not a production asset or approved crop.
 await sharp(e.file).resize({width:Math.round(e.inspection.size[0]*ratio)}).png().toFile(path.join(__dirname,'chest-ritual-v1-scale-preview.png'));
 fs.writeFileSync(path.join(__dirname,'review.json'),JSON.stringify({date:'2026-10-25',status:'Appearance proposal; not approved or integrated',current:'source/chest-ritual-v1.png',entries,display:{cameraZoom:.75,chestBodyWidth:96,groundDiamond:[192,96]},policy:'Original pixels/alpha untouched. Uniform resize only. Alpha128 measures size, never masks pixels.',limitations:['Ground grid is exact 2:1; generated source geometry is not numerically calibrated.','Contact anchors are provisional. No added shadow, Godot capture or production changes.']},null,2)+'\n');
 console.log(JSON.stringify({board:path.join(__dirname,'mobile-comparison.png'),preview:path.join(__dirname,'chest-ritual-v1-scale-preview.png'),sources:entries.map(e=>e.inspection)}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
