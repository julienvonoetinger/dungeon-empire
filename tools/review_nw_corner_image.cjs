// Review-only compositing explicitly requested by the user. Never alters the
// generated asset, cuts its alpha, recolors it, or warps it into the guide.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const imagePath=process.argv[2]||'assets/dungeon/gloom-kit/proposals/nw-cell-wireframe-v1.png';
const tag=process.argv[3]||'v1';
if(!/^[a-z0-9-]+$/.test(tag))throw Error('Invalid review tag.');
const requestedCanvas=process.argv[4]?process.argv[4].split('x').map(Number):[1216,1408];
if(requestedCanvas.length!==2||requestedCanvas.some(n=>!Number.isInteger(n)||n<=0))throw Error('Requested canvas must be WIDTHxHEIGHT.');
const directory=path.join(root,'docs/reference/painted-corner-review');
const read=file=>fs.readFileSync(path.join(root,file));
const inner=svg=>svg.replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
const guide=read('docs/reference/wireframe-overlays/cells/w09_p00_e00.svg').toString();
const construction=read('docs/reference/painted-corner-review/nw-construction.svg').toString();
const uri=buffer=>'data:image/png;base64,'+buffer.toString('base64');
async function main(){
  const original=read(imagePath),metadata=await sharp(original).metadata();
  const {width:w,height:h}=metadata;
  // No silhouette fit. Match the WHOLE original canvas by one uniform scale,
  // keeping its (0,0) fixed. Extra fractional space stays at right/bottom.
  const scale=Math.min(w/304,h/352);
  const frame=body=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><g transform="scale(${scale})">${body}</g></svg>`;
  const overlay=await sharp(Buffer.from(frame(inner(guide)))).png().toBuffer();
  const expected=await sharp(Buffer.from(frame(inner(construction)))).png().toBuffer();
  const overlaid=await sharp(original).composite([{input:overlay}]).png().toBuffer();
  fs.writeFileSync(path.join(directory,`nw-${tag}-overlay.png`),overlaid);
  const actualRaw=await sharp(original).ensureAlpha().raw().toBuffer();
  const expectedRaw=await sharp(expected).ensureAlpha().raw().toBuffer();
  let intersection=0,union=0,actualArea=0,expectedArea=0,transparent=0,partial=0;
  const bbox={actual:[w,h,-1,-1],expected:[w,h,-1,-1]};
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    const i=(y*w+x)*4,alpha=actualRaw[i+3],a=alpha>=128,e=expectedRaw[i+3]>=128;
    if(alpha===0)transparent++;else if(alpha<255)partial++;
    if(a)actualArea++;if(e)expectedArea++;if(a&&e)intersection++;if(a||e)union++;
    for(const [key,on] of [['actual',a],['expected',e]])if(on){const b=bbox[key];b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
  }
  const report={image:imagePath,requestedCanvas,actualCanvas:[w,h],exactCanvas:w===requestedCanvas[0]&&h===requestedCanvas[1],
    hasAlpha:metadata.hasAlpha,fullyTransparentPixels:transparent,partiallyTransparentPixels:partial,
    guideScaleFrom304x352:scale,guideTranslation:[0,0],unusedCanvas:[w-304*scale,h-352*scale],
    anchor:[24*scale,88*scale],cellPitch:256*scale,alphaThreshold:128,alphaBounds:bbox,
    silhouetteIoU:intersection/union,actualArea,expectedArea,
    measurementLimit:'Alpha silhouette overlap does not establish correct internal masonry, color, local contour deviations, or artistic approval. No nonuniform scaling or best-fit translation was applied.',
    assetUnchanged:true};
  fs.writeFileSync(path.join(directory,`nw-${tag}-measurements.json`),JSON.stringify(report,null,2)+'\n');
  const panelWidth=600,panelHeight=700,gap=24,pad=28;
  const displayScale=Math.min(panelWidth/w,panelHeight/h),dw=w*displayScale,dh=h*displayScale;
  const image=(buffer,x)=>`<rect x="${x}" y="110" width="${dw}" height="${dh}" fill="url(#check)"/><image href="${uri(buffer)}" x="${x}" y="110" width="${dw}" height="${dh}"/>`;
  const sheet=`<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="880" viewBox="0 0 1280 880"><defs><pattern id="check" width="24" height="24" patternUnits="userSpaceOnUse"><rect width="24" height="24" fill="#111827"/><path d="M0 0H12V12H0Z M12 12H24V24H12Z" fill="#1b2435"/></pattern></defs><rect width="1280" height="880" fill="#0b101b"/><g font-family="Arial,sans-serif" fill="#edf2ff"><text x="28" y="35" font-size="23">Coin supérieur gauche — sprite généré et contrôle géométrique (${tag})</text><text x="28" y="66" font-size="15" fill="#aebbd1">Même position et échelle uniforme · aucune correction du sprite pour le faire coïncider</text><text x="28" y="97" font-size="17">Image générée</text><text x="652" y="97" font-size="17">Image + calque magenta</text>${image(original,pad)}${image(overlaid,pad+panelWidth+gap)}<text x="28" y="850" font-size="14" fill="#aebbd1">Canevas généré : ${w} × ${h} · chevauchement des silhouettes : ${(100*report.silhouetteIoU).toFixed(2)} % (ne valide pas les joints internes)</text></g></svg>`;
  await sharp(Buffer.from(sheet)).png().toFile(path.join(directory,`nw-${tag}-comparison.png`));
  console.log(JSON.stringify(report,null,2));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
