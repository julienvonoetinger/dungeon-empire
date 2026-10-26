// Disposable appearance review. Native alpha and uniform scale only;
// fitted supports, per-state art and Godot integration are separate work.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),BASE=path.join(ROOT,'docs/reference/trap-review/v1');
const revision=process.argv.includes('--v2')?'v2':'v1',DIR=revision==='v2'?path.join(BASE,'revised'):BASE;
const ids=['pointes','entrave','neant'],names=['Pointes','Entrave','Néant'];
const descriptions=['Dalle mécanique à pointes','Mâchoires de fer et déclencheur','Faille magique dans le sol'];
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function inspect(file){
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const bounds=[0,127].map(a=>{let x=info.width,y=info.height,X=-1,Y=-1;for(let j=0;j<info.height;j++)for(let i=0;i<info.width;i++)if(data[(j*info.width+i)*4+3]>a){x=Math.min(x,i);y=Math.min(y,j);X=Math.max(X,i);Y=Math.max(Y,j);}return {left:x,top:y,width:X-x+1,height:Y-y+1};});
 return {size:[info.width,info.height],crop:bounds[0],solid:bounds[1],sha256:hash(fs.readFileSync(file))};
}
async function view(e,scale){
 const W=Math.round(360*scale),H=Math.round(240*scale),cx=W/2,cy=H*.6;
 const layers=[],catalog=JSON.parse(fs.readFileSync(path.join(ROOT,'assets/dungeon/isometric-kit/catalog.json'))),floor=catalog.atlas.regions['floor-b2'];
 const floorPng=await sharp(path.join(ROOT,'docs/reference/isometric-review/painted-v1/sprites/floor-b2.png')).resize({width:Math.round(floor.size[0]*.75*scale)}).png().toBuffer();
 layers.push({input:floorPng,left:Math.round(cx+(floor.offset[0])*.75*scale),top:Math.round(cy+(floor.offset[1]-64)*.75*scale)});
 const {crop,solid}=e.inspection,ratio=96*scale/solid.width;
 const png=await sharp(e.file).extract(crop).resize({width:Math.max(1,Math.round(crop.width*ratio))}).png().toBuffer(),meta=await sharp(png).metadata(),actual=meta.width/crop.width;
 // Proposed contact placement for this review, not a reconstructed XYZ anchor.
 const left=Math.round(cx-(solid.left+solid.width/2-crop.left)*actual);
 const top=Math.round(cy+26*scale-(solid.top+solid.height-crop.top)*actual);
 layers.push({input:png,left,top});
 return sharp({create:{width:W,height:H,channels:4,background:'#0d1420'}}).composite(layers).png().toBuffer();
}
async function main(){
 const entries=[];fs.mkdirSync(path.join(DIR,'views'),{recursive:true});
 for(let i=0;i<ids.length;i++){
  const file=path.join(BASE,'source',ids[i]+'-'+revision+'.png');
  const e={id:ids[i],file,inspection:await inspect(file)};entries.push(e);
  fs.writeFileSync(path.join(DIR,'views',e.id+'-mobile.png'),await view(e,1));
  fs.writeFileSync(path.join(DIR,'views',e.id+'-detail.png'),await view(e,2.5));
 }
 const W=1200,H=710,layers=[];
 let labels='<rect width="1200" height="710" fill="#0b1019"/><text x="26" y="42" font-size="27" fill="#e4e8f2">Pièges du donjon — premières propositions</text><text x="26" y="73" font-size="17" fill="#a5afc4">Pierre bleue · fer sombre · corruption violette</text>';
 for(let i=0;i<entries.length;i++){
  const x=i*400;
  labels+=`<text x="${x+24}" y="116" font-size="23" fill="#e4e8f2">${names[i]}</text><text x="${x+24}" y="143" font-size="16" fill="#a5afc4">${descriptions[i]}</text>`;
  const e=entries[i],raw=await sharp(e.file).extract(e.inspection.crop).resize({width:350,height:270,fit:'inside'}).png().toBuffer(),meta=await sharp(raw).metadata();
  layers.push({input:raw,left:Math.round(x+200-meta.width/2),top:Math.round(160+(270-meta.height)/2)});
  labels+=`<text x="${x+24}" y="469" font-size="16" fill="#a5afc4">Sur les dalles · largeur proposée 96 px</text>`;
  layers.push({input:await view(e,1),left:x+20,top:470});
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="Segoe UI,Arial,sans-serif">${labels}</svg>`)).composite(layers).png().toFile(path.join(DIR,'comparison.png'));
 fs.writeFileSync(path.join(DIR,'validation.json'),JSON.stringify({kind:'Offline appearance montage; not Godot or calibrated geometry',entries,uniformResize:true,nativeAlphaPreserved:true,proposedWidth:96,gameCellDiamond:[192,96],productionUnchanged:true,remaining:['Appearance selection','Exact XYZ supports/contact and camera fit','Ready/triggered/spent states','Integration with existing charges and status rings']},null,2)+'\n');
 console.log('Prepared3 trap appearance views; production files unchanged.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
