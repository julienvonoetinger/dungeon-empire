// Package native Blender renders and explanatory geometry; no AI paint edits.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const dir=__dirname,m=JSON.parse(fs.readFileSync(path.join(dir,'rig.json'))),poses=JSON.parse(fs.readFileSync(path.join(dir,'pose-data.json')));
const directions=Object.keys(m.directions),labels={se:'Sud-est',sw:'Sud-ouest',nw:'Nord-ouest',ne:'Nord-est'},vectors={se:[1,0],sw:[0,1],nw:[-1,0],ne:[0,-1]};
const delays=Array.from({length:m.frames},(_,i)=>Math.round((i+1)*800/m.frames)-Math.round(i*800/m.frames));
function proj(x,y){return[(x-y)*.5*256*m.modelToCell,(x+y)*.25*256*m.modelToCell]}
function sceneSvg(i){
 let s=`<svg xmlns="http://www.w3.org/2000/svg" width="840" height="800"><rect width="100%" height="100%" fill="#111923"/><g font-family="Arial" fill="#eceaf3"><text x="24" y="29" font-size="23">Vulpin — mannequin articulé</text><text x="24" y="50" font-size="14" fill="#b4c0d0">Un squelette · Quatre vues · Appuis contrôlés · Aucune texture</text></g>`;
 directions.forEach((d,k)=>{
  const x=16+k%2*416,y=64+Math.floor(k/2)*356,cx=x+200,cy=y+292,step=m.strideModel/2,v=vectors[d],move=proj(v[0]*m.strideModel*i/m.frames,v[1]*m.strideModel*i/m.frames);
  s+=`<rect x="${x}" y="${y}" width="400" height="340" rx="10" fill="#1d2837" stroke="#39475c"/><text x="${x+15}" y="${y+28}" fill="#e9e6f1" font-size="18" font-family="Arial">${labels[d]}</text><clipPath id="p${k}"><rect x="${x+2}" y="${y+42}" width="396" height="280"/></clipPath><g clip-path="url(#p${k})" stroke="#3c4b5e" stroke-width="1">`;
  for(let a=-15;a<=15;a++)for(let axis=0;axis<2;axis++){
   const p=proj(axis?-4:a*step,axis?a*step:-4),q=proj(axis?4:a*step,axis?a*step:4);
   s+=`<path d="M${cx+(p[0]-move[0])*2},${cy+(p[1]-move[1])*2} L${cx+(q[0]-move[0])*2},${cy+(q[1]-move[1])*2}"/>`;
  }
  for(const side of ['L','R']){
   const p=poses[d][i].feet[side],contact=poses[d][i].contact[side],color=side==='L'?'#52c0df':'#dfa574';
   s+=`<ellipse cx="${x+40+p[0]*2}" cy="${y+12+p[1]*2}" rx="18" ry="9" stroke="${color}" stroke-width="2" fill="none" ${contact?'':'stroke-dasharray="3 4" opacity=".3"'}/>`;
  }
  s+=`</g><text x="${x+14}" y="${y+329}" fill="#69c7de" font-size="13" font-family="Arial">Gauche : ${poses[d][i].contact.L?'appui':'levé'}</text><text x="${x+232}" y="${y+329}" fill="#e6b78f" font-size="13" font-family="Arial">Droite : ${poses[d][i].contact.R?'appui':'levé'}</text>`;
 });
 return s+`<text x="24" y="790" fill="#b4c0d0" font-size="14" font-family="Arial">La grille défile à la vitesse du corps : un pied en appui reste sur le même point du sol.</text></svg>`;
}
(async()=>{
 fs.mkdirSync(path.join(dir,'frames'),{recursive:true});
 let clipped=0;
 for(const d of directions){
  fs.mkdirSync(path.join(dir,'frames',d),{recursive:true});const tiles=[];
  for(let i=0;i<m.frames;i++){
   const file=path.join(dir,`frames/${d}/${i}.png`);
   await sharp(path.join(dir,`renders/${d}/${String(i).padStart(2,'0')}.png`)).resize(160,160).png().toFile(file);
   const {data}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   for(let j=0;j<160;j++)for(const p of [j,j*160,j*160+159,159*160+j])if(data[p*4+3]>8)clipped++;
   tiles.push({input:file,left:i%6*160,top:Math.floor(i/6)*160});
  }
  await sharp({create:{width:960,height:640,channels:4,background:'#00000000'}}).composite(tiles).png().toFile(path.join(dir,`atlas-${d}.png`));
 }
 if(clipped)throw Error('Render clips at frame border: '+clipped);
 const animation=[];
 for(let i=0;i<m.frames;i++){
  const layers=[];
  for(let k=0;k<directions.length;k++)layers.push({input:await sharp(path.join(dir,`frames/${directions[k]}/${i}.png`)).resize(320,320).png().toBuffer(),left:56+k%2*416,top:76+Math.floor(k/2)*356});
  const image=await sharp(Buffer.from(sceneSvg(i))).composite(layers).ensureAlpha().raw().toBuffer();animation.push(image);
  if(i===0)await sharp(image,{raw:{width:840,height:800,channels:4}}).png().toFile(path.join(dir,'overview.png'));
 }
 for(const [file,mul] of [['four-directions.webp',1],['four-directions-slow.webp',2]])
  await sharp(Buffer.concat(animation),{raw:{width:840,height:800*m.frames,channels:4,pageHeight:800}}).webp({quality:90,loop:0,delay:delays.map(d=>d*mul)}).toFile(path.join(dir,file));
 // Overlay actual evaluated bone endpoints, not a reconstructed drawing.
 let wire='<svg xmlns="http://www.w3.org/2000/svg" width="840" height="800">';
 directions.forEach((d,k)=>{
  const x=56+k%2*416,y=76+Math.floor(k/2)*356;
  for(const [name,b] of Object.entries(poses[d][0].bones)){
   if(name==='root')continue;
   const color=name.endsWith('.L')?'#77d9ed':name.endsWith('.R')?'#f9ba81':'#ebebfa';
   wire+=`<path d="M${x+b.head[0]*2},${y+b.head[1]*2} L${x+b.tail[0]*2},${y+b.tail[1]*2}" stroke="#111827" stroke-width="5"/><path d="M${x+b.head[0]*2},${y+b.head[1]*2} L${x+b.tail[0]*2},${y+b.tail[1]*2}" stroke="${color}" stroke-width="2"/><circle cx="${x+b.head[0]*2}" cy="${y+b.head[1]*2}" r="3" fill="${color}" stroke="#182332"/>`;
  }
 });
 await sharp(path.join(dir,'overview.png')).composite([{input:Buffer.from(wire+'</svg>'),left:0,top:0}]).png().toFile(path.join(dir,'skeleton-overlay.png'));
 const anim=await sharp(path.join(dir,'four-directions.webp'),{animated:true}).metadata();
 if(anim.pages!==24||anim.delay.reduce((a,b)=>a+b,0)!==800)throw Error('Incorrect timing');
 fs.writeFileSync(path.join(dir,'media-validation.json'),JSON.stringify({directions:4,framesPerDirection:24,clippedBorderPixels:clipped,frameSize:160,atlasSize:[960,640],atlasRgbaTotalBytes:960*640*4*4,animationPages:anim.pages,animationDurationMs:800,preparation:'All renders uniformly resized3:1, unchanged common frame/root. Board grid and skeleton are explanatory geometry.',scope:'Review only. No production packing or memory optimization.'},null,2));
 console.log('96 unclipped sprites; four atlases; 24-frame800ms animation and actual-bone overlay.');
})().catch(e=>{console.error(e);process.exitCode=1});
