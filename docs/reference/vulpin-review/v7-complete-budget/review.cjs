const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const dir=__dirname,source=JSON.parse(fs.readFileSync(path.join(dir,'source-manifest.json'))),profiles=['reference','balanced','compact'],meta=Object.fromEntries(profiles.map(p=>[p,JSON.parse(fs.readFileSync(path.join(dir,'projects',p,'manifest.json')))]));
const states=Object.keys(source.clips),directions=Object.keys(source.directions);
const cache=new Map();
async function sprite(p,clip,t,displayScale){
 const c=meta[p].clips[clip];let time=c.loop?t%c.seconds:Math.min(c.seconds-.00001,t);
 const f=c.frames[Math.min(c.frames.length-1,Math.floor(time/c.seconds*c.frames.length))];const key=[p,f.sprite,displayScale].join(':');
 if(!cache.has(key)){const target=Math.round(240*displayScale);cache.set(key,await sharp(path.join(dir,'frames',p,f.sprite+'.png')).resize(target,target).png().toBuffer())}return cache.get(key);
}
function panel(x,y,w,h,title,root,extra=''){
 let s=`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="8" fill="#1b2737" stroke="#344257"/><text x="${x+16}" y="${y+28}" fill="#ede8f5" font-family="Arial" font-size="18">${title}</text><text x="${x+16}" y="${y+50}" fill="#aebcd0" font-family="Arial" font-size="13">${extra}</text>`;
 s+=`<clipPath id="clip${x}_${y}"><rect x="${x+1}" y="${y+60}" width="${w-2}" height="${h-62}"/></clipPath><g clip-path="url(#clip${x}_${y})">`;
 for(let k=-3;k<=3;k++)for(let a=0;a<2;a++){const xx=root[0]+k*22,yy=root[1]+k*11;s+=`<path d="M${xx-55},${yy+(a?-27.5:27.5)} l110,${a?55:-55}" stroke="#38465a"/>`}
 return s+'</g>';
}
async function animate(file,width,height,count,dt,build){
 const raw=[];
 for(let i=0;i<count;i++){const {svg,layers}=await build(i*dt);raw.push(await sharp(Buffer.from(svg)).composite(layers).ensureAlpha().raw().toBuffer());if(i===0)await sharp(raw[0],{raw:{width,height,channels:4}}).png().toFile(path.join(dir,file+'.png'))}
 await sharp(Buffer.concat(raw),{raw:{width,height:height*count,channels:4,pageHeight:height}}).webp({quality:86,loop:0,delay:Array.from({length:count},(_,i)=>Math.round((i+1)*dt*1000)-Math.round(i*dt*1000))}).toFile(path.join(dir,file+'.webp'));
}
(async()=>{
 // Each state has its own timing; non-loop actions hold at the endpoint.
 await animate('all-actions',960,850,48,1/24,async t=>{
  let svg='<svg xmlns="http://www.w3.org/2000/svg" width="960" height="850"><rect width="100%" height="100%" fill="#101822"/><text x="20" y="31" fill="#ede8f5" font-family="Arial" font-size="22">Vulpin — toutes les actions du mannequin</text><text x="20" y="54" fill="#b7c5d7" font-family="Arial" font-size="14">Profil 128 · Vue sud-est · Agrandissement ×2 pour lire les gestes · Mains libres hors crochetage</text>';const layers=[];
  for(let i=0;i<states.length;i++){const name=states[i],x=12+i%3*316,y=68+Math.floor(i/3)*258,root=[x+156,y+222];svg+=panel(x,y,304,246,source.clips[name].label,root,meta.balanced.clips['se-'+name].frames.length+' images');layers.push({input:await sprite('balanced','se-'+name,t,1.5),left:root[0]-180,top:root[1]-282})}
  return {svg:svg+'</svg>',layers};
 });
 // Resolution and locomotion cadence compared at equal native .75 display size.
 await animate('size-comparison',960,640,48,1/30,async t=>{
  let svg='<svg xmlns="http://www.w3.org/2000/svg" width="960" height="640"><rect width="100%" height="100%" fill="#101822"/><text x="20" y="30" fill="#ede8f5" font-family="Arial" font-size="22">Même taille à l’écran — trois budgets</text>';const layers=[];
  for(let k=0;k<3;k++){const p=profiles[k];for(let j=0;j<3;j++){const state=['walk','run','lock-chest'][j],x=12+k*316,y=48+j*192,root=[x+153,y+172];svg+=panel(x,y,304,180,`${meta[p].density} / ${meta[p].clips['se-'+state].frames.length} images`,root,source.clips[state].label+(k===1?' · compromis proposé':''));layers.push({input:await sprite(p,'se-'+state,t,.75),left:root[0]-90,top:root[1]-141})}}
  return {svg:svg+'</svg>',layers};
 });
 // Isolate temporal sampling: same 128 density, three frame counts.
 const cadenceCache=new Map();
 await animate('cadence-comparison',960,480,64,1/40,async t=>{
  let svg='<svg xmlns="http://www.w3.org/2000/svg" width="960" height="480"><rect width="100%" height="100%" fill="#101822"/><text x="20" y="30" fill="#ede8f5" font-family="Arial" font-size="22">Cadence seule — résolution identique (128)</text>';const layers=[];
  for(let k=0;k<3;k++)for(let j=0;j<2;j++){
   const count=[12,16,24][k],state=['walk','run'][j],c=source.clips[state],idx=Math.floor((t%c.seconds)/c.seconds*count)*48/count,key=state+idx;
   if(!cadenceCache.has(key)){const base=await sharp(path.join(dir,`renders/se/${state}/${String(idx).padStart(2,'0')}.png`)).resize(224).png().toBuffer();const pad=await sharp(base).extend({top:8,bottom:8,left:8,right:8,background:'#00000000'}).png().toBuffer();const low=await sharp(pad).resize(192).png().toBuffer();cadenceCache.set(key,await sharp(low).resize(180).png().toBuffer())}
   const x=12+k*316,y=48+j*214,root=[x+153,y+192];svg+=panel(x,y,304,202,`${count} images`,root,c.label);layers.push({input:cadenceCache.get(key),left:root[0]-90,top:root[1]-141});
  }
  return {svg:svg+'</svg>',layers};
 });
 // Four facing directions, all states, with a common frame index per clip.
 for(const d of directions){
  let svg='<svg xmlns="http://www.w3.org/2000/svg" width="960" height="640"><rect width="100%" height="100%" fill="#101822"/>';const layers=[];
  for(let i=0;i<states.length;i++){const state=states[i],x=12+i%3*316,y=12+Math.floor(i/3)*208,root=[x+153,y+188];svg+=panel(x,y,304,196,source.clips[state].label,root,d);layers.push({input:await sprite('balanced',d+'-'+state,source.clips[state].seconds*.5,.85),left:Math.round(root[0]-102),top:Math.round(root[1]-159.8)})}
  await sharp(Buffer.from(svg+'</svg>')).composite(layers).png().toFile(path.join(dir,'states-'+d+'.png'));
 }
 console.log('Animated action and equal-size comparison boards plus all four facing contact sheets created.');
})().catch(e=>{console.error(e);process.exitCode=1});
