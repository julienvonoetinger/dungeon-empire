const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const dir=__dirname,source=JSON.parse(fs.readFileSync(path.join(dir,'source-manifest.json'))),meta=JSON.parse(fs.readFileSync(path.join(dir,'projects/balanced/manifest.json'))),states=Object.keys(source.clips),dirs=Object.keys(source.directions),cache=new Map();
async function frame(d,state,t,scale=1){
 const c=meta.clips[d+'-'+state],time=c.loop?t%c.seconds:Math.min(t,c.seconds-.0001),f=c.frames[Math.min(c.frames.length-1,Math.floor(time/c.seconds*c.frames.length))],key=f.sprite+':'+scale;
 if(!cache.has(key))cache.set(key,await sharp(path.join(dir,'frames/balanced',f.sprite+'.png')).resize(Math.round(240*scale)).png().toBuffer());return cache.get(key);
}
function start(w,h,title,sub){return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="100%" height="100%" fill="#0c1420"/><g font-family="Arial"><text x="22" y="32" fill="#eee8fb" font-size="22">${title}</text><text x="22" y="56" fill="#9bacbf" font-size="14">${sub}</text></g>`}
function cell(x,y,w,h,title,sub){return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="9" fill="#1b2738" stroke="#3c475f"/><g font-family="Arial"><text x="${x+16}" y="${y+27}" fill="#eee8fb" font-size="17">${title}</text><text x="${x+16}" y="${y+48}" fill="#aab9cd" font-size="13">${sub}</text></g>`}
async function animate(name,w,h,count,dt,build){let raw=[];for(let i=0;i<count;i++){const a=await build(i*dt);const b=await sharp(Buffer.from(a.svg+'</svg>')).composite(a.layers).ensureAlpha().raw().toBuffer();raw.push(b);if(i===0)await sharp(b,{raw:{width:w,height:h,channels:4}}).png().toFile(path.join(dir,name+'.png'))}await sharp(Buffer.concat(raw),{raw:{width:w,height:h*count,channels:4,pageHeight:h}}).webp({quality:90,loop:0,delay:Math.round(dt*1000)}).toFile(path.join(dir,name+'.webp'));}
(async()=>{
 for(const d of dirs){let svg=start(1088,650,'Vulpin · corps peint par éléments',d.toUpperCase()+' · 8 états · vue agrandie · mort fixe, sans chute');const layers=[];
  for(let i=0;i<states.length;i++){const state=states[i],x=14+(i%4)*268,y=76+Math.floor(i/4)*280;svg+=cell(x,y,256,268,source.clips[state].label,meta.clips[d+'-'+state].frames.length+' images');layers.push({input:await frame(d,state,source.clips[state].seconds*.5,1.1),left:x-4,top:y+4});}
  await sharp(Buffer.from(svg+'</svg>')).composite(layers).png().toFile(path.join(dir,'states-'+d+'.png'));
 }
 await animate('all-actions',1088,650,100,.02,async t=>{let svg=start(1088,650,'Vulpin · sprites peints en mouvement','Profil 128 · sud-est · lecture à vitesse réelle · 0,36 s par cycle de course');const layers=[];for(let i=0;i<states.length;i++){const s=states[i],x=14+i%4*268,y=76+Math.floor(i/4)*280;svg+=cell(x,y,256,268,source.clips[s].label,s==='dead'?'Un sprite fixe':meta.clips['se-'+s].frames.length+' images');layers.push({input:await frame('se',s,t,1.1),left:x-4,top:y+4})}return{svg,layers}});
 await animate('four-directions',1088,570,80,.02,async t=>{let svg=start(1088,570,'Marche et course · quatre directions','Profil 128 · taille de jeu ×0,75 · aucune arme en main');const layers=[];for(let j=0;j<2;j++)for(let i=0;i<4;i++){const s=['walk','run'][j],d=dirs[i],x=14+i*268,y=76+j*242;svg+=cell(x,y,256,230,source.clips[s].label+' · '+d.toUpperCase(),source.clips[s].seconds.toFixed(2)+' s');layers.push({input:await frame(d,s,t,.75),left:x+38,top:y+42})}return{svg,layers}});
 console.log('Painted contact sheets and timed animated boards complete.');
})().catch(e=>{console.error(e);process.exitCode=1});

