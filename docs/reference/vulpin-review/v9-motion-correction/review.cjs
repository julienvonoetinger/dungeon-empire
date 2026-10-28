// Editorial comparison only: original renders and packed sprite pixels unchanged.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),crypto=require('node:crypto');
const dir=__dirname,old=path.resolve(dir,'../v7-complete-budget'),roots=[old,dir],meta=roots.map(p=>JSON.parse(fs.readFileSync(path.join(p,'projects/balanced/manifest.json'))));
const cache=new Map();
async function sprite(version,d,state,t,scale=1.2){
 const c=meta[version].clips[d+'-'+state],phase=c.loop?(t%c.seconds)/c.seconds:Math.min(.999999,t/c.seconds),f=c.frames[Math.floor(phase*c.frames.length)],key=[version,f.sprite,scale].join(':');
 if(!cache.has(key))cache.set(key,await sharp(path.join(roots[version],'frames/balanced',f.sprite+'.png')).resize(Math.round(240*scale)).png().toBuffer());
 return cache.get(key);
}
function grid(root,clip){let s=`<clipPath id="g${clip}"><rect x="${clip*500+8}" y="75" width="484" height="360"/></clipPath><g clip-path="url(#g${clip})">`;for(let i=-9;i<=9;i++)for(const sign of [-1,1])s+=`<path d="M${root[0]-420},${root[1]+i*24-sign*210} l840,${sign*420}" stroke="#344257" fill="none"/>`;return s+'</g>'}
function base(title,sub){return `<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="450"><rect width="1000" height="450" fill="#101822"/><path d="M500 20v410" stroke="#64708b"/><g font-family="Arial" fill="#eee9f6"><text x="22" y="30" font-size="21">Avant · ${title}</text><text x="522" y="30" font-size="21">Après · ${title}</text><text x="22" y="56" font-size="14" fill="#abb8ca">${sub[0]}</text><text x="522" y="56" font-size="14" fill="#c6b2e6">${sub[1]}</text></g>`}
async function animate(file,state,sub){const raw=[],count=60,scale=1.2;for(let i=0;i<count;i++){const t=i/30,layers=[];let svg=base(state==='run'?'Course':'Chute et repos',sub);for(let v=0;v<2;v++){let root=[v*500+(state==='run'?125:250),state==='run'?190:290];svg+=grid(root,v);if(state==='run'){const c=meta[v].clips['se-run'],stride=v?c.strideCells:.256;root=[root[0]+t/c.seconds*stride*128*scale,root[1]+t/c.seconds*stride*64*scale]}
 layers.push({input:await sprite(v,'se',state,t,scale),left:Math.round(root[0]-120*scale),top:Math.round(root[1]-188*scale)})}
 const pixels=await sharp(Buffer.from(svg+'</svg>')).composite(layers).raw().toBuffer();raw.push(pixels)}
 await sharp(Buffer.concat(raw),{raw:{width:1000,height:450*count,channels:4,pageHeight:450}}).webp({quality:87,loop:0,delay:Array.from({length:count},(_,i)=>Math.round((i+1)*1000/30)-Math.round(i*1000/30))}).toFile(path.join(dir,file));
}
(async()=>{
 await animate('run-before-after.webp','run',['Cycle 0,60 s · foulée 0,256 case','Cycle 0,36 s · foulée 0,320 case · vitesse ×2,08']);
 await animate('fall-before-after.webp','death',['Bascule rigide · 13 images','Genoux, côté, relâchement · 19 images · durée 1,5 s']);
 let svg='<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="360"><rect width="1000" height="360" fill="#1b2737"/>',layers=[];
 for(const [i,d] of ['se','sw','nw','ne'].entries()){const root=[125+250*i,270];svg+=`<text x="${i*250+20}" y="35" fill="#eee9f6" font-family="Arial" font-size="18">${d.toUpperCase()} · pose finale</text><path d="M${root[0]-100} ${root[1]}l100 -50 100 50 -100 50Z" stroke="#53627a" fill="none"/>`;layers.push({input:await sprite(1,d,'dead',0,1),left:root[0]-120,top:root[1]-188})}
 await sharp(Buffer.from(svg+'</svg>')).composite(layers).png().toFile(path.join(dir,'corpse-four-views.png'));
 // Freeze unchanged action provenance, not just the generator's claimed scope.
 let unchanged=0;for(const d of ['se','sw','nw','ne'])for(const state of ['idle','walk','hurt','lock-door','lock-chest','loot'])for(const file of fs.readdirSync(path.join(old,'renders',d,state))){const a=fs.readFileSync(path.join(old,'renders',d,state,file)),b=fs.readFileSync(path.join(dir,'renders',d,state,file));if(!a.equals(b))throw Error('Unrelated action changed: '+d+'/'+state+'/'+file);unchanged++}
 fs.writeFileSync(path.join(dir,'provenance.json'),JSON.stringify({unchangedSourceImages:unchanged,changedActions:['run','death','dead'],originalRigSha256:crypto.createHash('sha256').update(fs.readFileSync(path.resolve(dir,'../v6-articulated-mannequin/vulpin-mannequin.blend'))).digest('hex'),oldApkUnchanged:true},null,2));
 console.log('Comparisons generated; unchanged sources verified:',unchanged);
})().catch(e=>{console.error(e);process.exitCode=1});
